///
/// \file  sendvideo.c
/// Send, display and save video streams from a file or a camera.
/// 
/// This tool is able to open either a video file or other video source
/// (such as a camera), capture video data from it, and stream it over
/// a TCP/IP connection. It can open all video formats and video sources
/// that are supported by the OpenCV library it is linked against.
///
/// The image data is streamed "as is". Before the stream starts, the
/// size, bit depth, and number of channels of the video stream is
/// transmitted. This tool is supposed to be used either with the
/// 'recvvideo' tool or a eCos/ReconOS thread. See the ReconOS wiki
/// (http://www.reconos.de) for more details.
///
/// Part of the ReconOS netimage tools to send and receive image
/// data to and from a ReconOS board. 
/// 
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       12.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group 
//
// (C) Copyright University of Paderborn 2007. Permission to copy,
// use, modify, sell and distribute this software is granted provided
// this copyright notice appears in all copies. This software is
// provided "as is" without express or implied warranty, and with no
// claim as to its suitability for any purpose.
//
// -------------------------------------------------------------------------
// Major Changes:
// 
// 12.09.2007   Enno Luebbers   File created
// 

// INCLUDES ================================================================

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>                                                            // for 'basename()'

// header for application
#include "../../sw/header/config.h"
// header for number of particles
//#include "../../sw/framework/header/particle_filter.h"

/* From OpenCV library */
#include "cv.h"
#include "cxcore.h"
#include "highgui.h"

#include "tcp_connection.h"
#include "netimage.h"
#include "debug.h"
#include "cvutil.h"


/* default basename and extension of exported frames */
#define EXPORT_BASE "./frames/frame_"
#define EXPORT_EXTN ".png"


typedef struct params {
  CvPoint loc1[1];
  CvPoint loc2[1];
  IplImage* objects[1];
  char* win_name;
  IplImage* orig_img;
  IplImage* cur_img;
  int n;
} params;


#define TRUE  1
#define FALSE 0

typedef struct particle_data {
  volatile unsigned int x1;
  volatile unsigned int y1;
  volatile unsigned int x2;
  volatile unsigned int y2;
  volatile unsigned int best_particle;
} particle_data;




/***************************** Function Prototypes ***************************/

void mouse( int, int, int, int, void* );



// CONSTANTS ===============================================================

#define MAX_HOSTNAMELEN 256		///< maximum length of hostname string
#define MAX_FILENAMELEN 256		///< maximum length of filenames

#define SOURCE_NONE 0		///< no source specified
#define SOURCE_FILE 1		///< use video file as source
#define SOURCE_CAM  2		///< use camera as source


// GLOBAL VARIABLES ========================================================

// options
char host[MAX_HOSTNAMELEN] = "localhost";       ///< hostname to connect to
int port = 6666;                ///< port to connect to
int quiet = 0;                  ///< suppress output?
int output = 0;                 ///< write video stream to file?
char fourcc[5] = "PIM1";        ///< video format to write (default MPEG-1)
double fps = 25.0;              ///< fps to write to the video file
char infilename[MAX_FILENAMELEN];       ///< input stream file name
char outfilename[MAX_FILENAMELEN];      ///< output video file name
int camera = -1;                ///< camera number to use, '-1' for first available
int source = SOURCE_NONE;       ///< capture source to use
volatile int quit = 0;          ///< quit flag (set by signal handler)
int max_frames = 5000;         ///< max frames, can be set by parameter

particle_data * particles_data;
int number_of_frames = 0;
int number_of_particles = 100;

// Bounding Box of particle ist defined by two points (upper left corner, lower right corner)
CvPoint loc1, loc2;


// FUNCTION DEFINITIONS ====================================================

///
/// Handles signals. Prints a note and sets the quit flag.
///
/// \param      sig             received signal
/*
void sig_handler( int sig )
{

    fprintf( stderr, "Received signal %d, exiting.\n", sig );
    quit = 1;
}
*/


///
/// Prints the program usage.
///
/// \param      basename        the name of this program's executable
/// 
void usage( char *basename )
{
    printf( "%s: send, display and save video streams.\n"
            "(c) 2007 Enno Luebbers (luebbers@reconos.de)\n"
            "Computer Engineering Group, University of Paderborn\n\n"
            "USAGE:\n"
            "       %s [-q] [-h] [-o <outfile>] [-f <fps>] [-F <fourcc>]\n"
            "               [-p <port>] [-i <infile>][-m <number_of_frames>] [-c [<id>]] <host>\n"
            "\n"
            "       -h                     display this help\n"
            "       -q                     be quiet (do not display video)\n"
            "       -o <outfile>           save video to <outfile> (NO EXTENSION!)\n"
            "       -f <fps>               frames per second to save (default: 25 or infile's)\n"
            "       -F <fourcc>            fourcc format to save in (default: MPEG-1)\n"
            "       -m <number_of_frames>  number of frames to track\n"
            "\n"
            "SOURCE OPTIONS:\n"
            "       -i <infile>            use <file> as video source\n"
            "       -c [<id>]              use camera with <id>, leave out for first available\n"
            "\n"
            "DESTINATION OPTIONS:\n"
            "       <host>                 host to send to\n"
            "       -p <port>              send to port <port> (default: 6666)\n"
            "\n", basename, basename );
}


///
/// Parses command line arguments using getopt() and sets the global
/// option variables.
///
/// \param      argc            number of command line arguments
/// \param      argv            pointer to array of command line argument
///                             strings
///
void parse_args( int argc, char *argv[] )
{

    int c;


    while ( 1 ) {
        c = getopt( argc, argv, "qo:f:F:i:c::p:m:h" );

        if ( c == -1 )
            break;

        switch ( c ) {
        case 'q':
            quiet = 1;
            break;

        case 'o':
            output = 1;
            strncpy( outfilename, optarg, MAX_FILENAMELEN - 4 );
            break;

        case 'F':
            strncpy( fourcc, optarg, 4 );
            break;

        case 'f':
            fps = atof( optarg );
            break;

        case 'p':
            port = atoi( optarg );
            break;

        case 'm':
            max_frames = atoi( optarg );
            break;

        case 'i':
            source = SOURCE_FILE;
            strncpy( infilename, optarg, MAX_FILENAMELEN );
            break;

        case 'c':
            source = SOURCE_CAM;
            if ( optarg )
                camera = atoi( optarg );
            break;

        case '?':
        case 'h':
        default:
            usage( basename( argv[0] ) );
            exit( 1 );
            break;
        }
    }

    // we need exactly one argument (the host name)
    if ( optind >= argc ) {
        fprintf( stderr, "no target host specified.\n" );
        usage( basename( argv[0] ) );
        exit( 1 );
    }

    if ( optind < argc - 1 ) {
        fprintf( stderr, "too many arguments.\n" );
        usage( basename( argv[0] ) );
        exit( 1 );
    }

    strncpy( host, argv[optind], MAX_HOSTNAMELEN );

    // set default source (camera)
    if ( source == SOURCE_NONE ) {
        printf( "No source specified, using first available camera.\n"
                "Try '%s -h' for available options.\n",
                basename( argv[0] ) );
        source = SOURCE_CAM;
    }
}


/*
  Exports a frame whose name and format are determined by EXPORT_BASE and
  EXPORT_EXTN, defined above.

  @param frame frame to be exported
  @param i frame number
*/
int export_frame( IplImage* frame, int i )
{
  char name[ strlen(EXPORT_BASE) + strlen(EXPORT_EXTN) + 4 ];
  char num[5];

  snprintf( num, 5, "%04d", i );
  strcpy( name, EXPORT_BASE );
  strcat( name, num );
  strcat( name, EXPORT_EXTN );
  return cvSaveImage( name, frame );
}





/**
  Converts a BGR image to HSV colorspace
  
  @param bgr: image to be converted
  
  @param hsv: pointer to converted image
*/
IplImage*  bgr2hsv( IplImage* bgr,  IplImage* hsv)
{

  //hsv = cvCreateImage( cvGetSize(bgr), IPL_DEPTH_8U, 3 );
  cvCvtColor( bgr, hsv, CV_BGR2HSV );
  
  return hsv;
}




////////////////////////////////////////////////////////////////////////////
// MAIN ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///
/// Main program.
///
int main( int argc, char *argv[] )
{

    CvCapture *video;
    CvVideoWriter *writer;
    IplImage *frame;
    IplImage *hsv;
    char *win_name = "Source Frame";
    char key = 0;
    tcp_connection *con;
    int frame_count = 0, result;
    int i;
    max_frames = 5000;
    unsigned char *byte_stream;
 
    // register signal handler for SIGINT und SIGPIPE
    // the latter occurs if the server terminates the connection
    /*
    DEBUG_PRINT( DEBUG_NOTE, "registering signal" )
        if ( signal( SIGINT, sig_handler ) == SIG_ERR ||
             signal( SIGPIPE, sig_handler ) == SIG_ERR ) {
        fprintf( stderr, "failed to register signal handler.\n" );
        exit( 1 );
    }
    */
    parse_args( argc, argv );

    // open the capture source
    switch ( source ) {
    case SOURCE_FILE:
        video = cvCreateFileCapture( infilename );
        break;
    case SOURCE_CAM:
        video = cvCreateCameraCapture( camera );
        break;
    default:
        fprintf( stderr, "strange source\n" );
        exit( 1 );
    }

    if ( !video ) {
        fprintf( stderr, "unable to capture source\n" );
        exit( 1 );
    }
    // connect to remote host
    con = tcp_connection_create( host, port );
    if ( !con ) {
        fprintf( stderr, "unable to connect to %s, port %d\n", host,
                 port );
        exit( 1 );
    }
    printf( "Connected to %s, port %d.\n", host, port );

    frame = cvQueryFrame( video );
    if ( !frame ) {
        fprintf( stderr, "unable to capture video.\n" );
        exit( 1 );
    }
    number_of_frames++;

    if ( netimage_send_header( con, frame ) <= 0 ) {
        fprintf( stderr, "unable to send header information.\n" );
        exit( 1 );
    }

    printf
        ( "Sending image stream (%d x %d, depth %u, %d channels (size: %d bytes)).\n"
          "Press 'q' to abort.\n", frame->width, frame->height,
          frame->depth, frame->nChannels, frame->imageSize );

    // open capture file, if desired
    if ( output ) {

        strncat( outfilename, ".mpg", MAX_FILENAMELEN );

        writer =
            cvCreateVideoWriter( outfilename, atofourcc( fourcc ), fps,
                                 cvSize( frame->width, frame->height ),
                                 frame->nChannels > 1 ? 1 : 0 );
        if ( writer == NULL ) {
            fprintf( stderr, "unable to create output file '%s'\n",
                     outfilename );
/*             exit (1);*/
        } else
            printf( "Writing to output file '%s'.\n", outfilename );
    }

    // for fps measurement
    struct timeval current, last;
    unsigned int diff;	// time difference in usecs
    int x0 = 0, y0 = 0, width = 0, height = 0;
	
    gettimeofday(&last, NULL);
    
    // show first frame for region selection   
    //frame = cvQueryFrame( video );
    //cvNamedWindow( win_name, 1 );
    //cvShowImage( win_name, frame );
    //if (output)
    //   cvWriteFrame( writer, frame );

    // get input region   
    char* win_name2 = "First frame";
    params p;
    CvRect* r;
    int x1, y1, x2, y2;
    int region[4];

  /* use mouse callback to allow user to define object regions */
  /*p.win_name = win_name2;
  p.orig_img = cvClone( frame );
  p.cur_img = NULL;
  p.n = 0;

  cvNamedWindow( win_name2, 1 );
  cvShowImage( win_name2, frame );
  cvSetMouseCallback( win_name2, &mouse, &p );
  printf("\nSelect Object and press [ENTER] !\n");
  cvWaitKey( 0 );

  cvDestroyWindow( win_name2 );
  cvReleaseImage( &p.orig_img );
  if( p.cur_img )
      cvReleaseImage( &(p.cur_img) );*/

  /* extract regions defined by user; store as an array of rectangles */
  if( p.n > 0 ){
      p.loc1[0].x = 0;
      p.loc1[0].y = 0;
      p.loc2[0].x = 0;
      p.loc2[0].y = 0;

      r = malloc(  sizeof( CvRect ) );
      x1 = MIN( p.loc1[0].x, p.loc2[0].x );
      x2 = MAX( p.loc1[0].x, p.loc2[0].x );
      y1 = MIN( p.loc1[0].y, p.loc2[0].y );
      y2 = MAX( p.loc1[0].y, p.loc2[0].y );
      width = x2 - x1;
      height = y2 - y1;

      /* ensure odd width and height */
      width = ( width % 2 )? width : width+1;
      height = ( height % 2 )? height : height+1;
      r[0] = cvRect( x1, y1, width, height );
      x0 = x1 + width/2;
      y0 = y1 + height/2;

      region[0] = x0;
      region[1] = y0;
      region[2] = width;
      region[3] = height;
   }


    //printf("\nx = %d\ny = %d\nwidth = %d\nheight = %d\n\n\n", x0, y0, width, height);

    // 1) convert bgr frame to hsv frame
    hsv = cvCreateImage( cvGetSize(frame), IPL_DEPTH_8U, 3 );
    bgr2hsv(frame, hsv);  
    result = tcp_send( con, hsv->imageData, hsv->imageSize);
    int counter = 1;
    //result = tcp_send( con, frame->imageData, frame->imageSize );

    result = tcp_send( con, (char *) region, 4 * sizeof(int));

    // confirm input with enter
    //printf("\nPress [ENTER]\n");
    //cvWaitKey( 0 );

    // TODO: send first frame + region data 
    //result = tcp_send( con, frame->imageData, frame->imageSize);
  
    number_of_particles = 100;

    // create particles data array
    particles_data = (particle_data *) malloc ((number_of_particles+1) * sizeof(particle_data));

    // quiet mode: no video output
    if (quiet){

         cvDestroyWindow( win_name );
    }

    // 1) send other frames
    // get video data and send/store it
#ifdef STORE_VIDEO
    //while ( ( frame = cvQueryFrame( video ) ) && ( char ) key != 'q' && !quit && number_of_frames <= 221 ) {
    while ( ( frame = cvQueryFrame( video ) ) && ( char ) key != 'q' && counter < max_frames) {
#else
    while ( ( frame = cvQueryFrame( video ) ) && ( char ) key != 'q' && counter < max_frames) {
#endif
        
        // 1) convert bgr frame to hsv frame
        bgr2hsv(frame, hsv); 
        result = tcp_send( con, hsv->imageData, hsv->imageSize );
        //fprintf(stderr, "\n///////////////////      number of frames %d     //////////////////////////////////////", number_of_frames);
        counter ++;
        //result = tcp_send( con, frame->imageData, frame->imageSize );

        if ( result > 0 ) {
            if ( !quiet ) {
                cvNamedWindow( win_name, 1 );

#ifdef NO_VGA_FRAMEBUFFER
#ifndef STORE_VIDEO          
	  if (number_of_frames > 2){
#else
 	  if (number_of_frames > 2 && number_of_frames % MAX_FRAMES == 0){
#endif
            // receive tcp package with particle data and display them in video
            // 1) receive tcp package with particles data
            //printf("\nreceive particles...");
            result = tcp_receive( con, (unsigned char*)particles_data, ((number_of_particles+1) * sizeof(particle_data)));
 
            if ( result > 0 ) {

               // 2) draw particles data         
               for (i=0; i<number_of_particles+1; i++){
         
	         // set OpenCV location points for bounding boxes
	         loc1.x = ntohl(particles_data[i].x1);
                 loc1.y = ntohl(particles_data[i].y1);
                 loc2.x = ntohl(particles_data[i].x2);
                 loc2.y = ntohl(particles_data[i].y2);
                 particles_data[i].best_particle = ntohl(particles_data[i].best_particle);

                 if (particles_data[i].best_particle > 0 ) particles_data[i].best_particle = TRUE;
                 
                 if (loc1.x <640 && loc2.x < 640 && loc1.y < 480 && loc2.y < 480)
                   // draw bounding box (red for best particle, blue else)
                   if (particles_data[i].best_particle == FALSE){
                 
                     cvRectangle( frame, loc1, loc2, CV_RGB(0,0,255), 1, 8, 0 ); 
                    } else {
                 
                      cvRectangle( frame, loc1, loc2, CV_RGB(255,0,0), 1, 8, 0 );   
                   }
	       }
             }
	   }        
#endif
                if (!quiet){
                  cvShowImage( win_name, frame );
                  //export_frame( frame, number_of_frames);
                  key = cvWaitKey( 2 );
                }
            }
            if ( output )
                cvWriteFrame( writer, frame );
        } else {
            printf( "connection lost.\n" );
            break;
        }
        //gettimeofday(&current, NULL);
        //diff = (current.tv_sec - last.tv_sec) * 1000000;
        //diff += (current.tv_usec - last.tv_usec);
	
        //fprintf(stderr, "FPS: %.2f\r", 1000000.0 / diff);
	
        //last.tv_sec = current.tv_sec;
        //last.tv_usec = current.tv_usec;
        number_of_frames++;
    }


/*
#ifdef STORE_VIDEO   
    cvReleaseCapture( &video );

    // 2) receive particle data and display particle data as Bounding Boxes
    switch ( source ) {
    case SOURCE_FILE:
        video = cvCreateFileCapture( infilename );
        break;
    case SOURCE_CAM:
        fprintf( stderr, "This part is only possible if video is stored into a file\n" );
        exit( 1 );
    default:
        fprintf( stderr, "strange source\n" );
        exit( 1 );
    }


    particles_data = malloc ((number_of_particles+1) * sizeof(particle_data));

    // get frames
    while ( ( frame = cvQueryFrame( video ) ) && ( char ) key != 'q' && !quit && number_of_frames <= 221 ) {


         // 1) receive tcp package with particles data
         // TODO
         result = tcp_receive( con, (char *)particles_data, ((number_of_particles+1) * sizeof(particle_data)));
 
         if ( result > 0 ) {

            // 2) draw particles data         
            for (i=0; i<number_of_particles+1; i++){
         
	         // set OpenCV location points for bounding boxes
	         loc1.x = particles_data[i].x1;
                 loc1.y = particles_data[i].y1;
                 loc2.x = particles_data[i].x2;
                 loc2.y = particles_data[i].y2;
                 
                 // draw bounding box (red for best particle, blue else)
                 if (particles_data[i].best_particle == TRUE){
                 
                    cvRectangle( frame, loc1, loc2, CV_RGB(255,0,0), 1, 8, 0 ); 
                 } else {
                 
                    cvRectangle( frame, loc1, loc2, CV_RGB(0,0,255), 1, 8, 0 );   
                 }
	    }
         }

         // display video frame
         if (!quiet){
              cvNamedWindow( win_name, 1 );
              cvShowImage( win_name, frame );
              key = cvWaitKey( 2 );
         }
         number_of_frames++;
    }
#endif
*/
    // clean up
    if (!quiet){

         cvDestroyWindow( win_name );
    }
    cvReleaseCapture( &video );
    if ( output )
        cvReleaseVideoWriter( &writer );
    tcp_connection_destroy( con );

    return 0;
}




/*
  Mouse callback function that allows user to specify the initial object
  regions.  Parameters are as specified in OpenCV documentation.
*/
void mouse( int event, int x, int y, int flags, void* param )
{
  params* p = (params*)param;
  CvPoint* loc;
  int n;
  IplImage* tmp;
  static int pressed = 0;
  
  /* on left button press, remember first corner of rectangle around object */
  if( event == CV_EVENT_LBUTTONDOWN )
    {
      n = p->n;
      if( n == 1 )
	return;
      loc = p->loc1;
      loc[n].x = x;
      loc[n].y = y;
      pressed = 1;
    }

  /* on left button up, finalize the rectangle and draw it in black */
  else if( event == CV_EVENT_LBUTTONUP )
    {
      n = p->n;
      if( n == 1 )
	return;
      loc = p->loc2;
      loc[n].x = x;
      loc[n].y = y;
      cvReleaseImage( &(p->cur_img) );
      p->cur_img = NULL;
      cvRectangle( p->orig_img, p->loc1[n], loc[n], CV_RGB(0,0,0), 1, 8, 0 );
      cvShowImage( p->win_name, p->orig_img );
      pressed = 0;
      p->n++;
    }

  /* on mouse move with left button down, draw rectangle as defined in white */
  else if( event == CV_EVENT_MOUSEMOVE  &&  flags & CV_EVENT_FLAG_LBUTTON )
    {
      n = p->n;
      if( n == 1 )
	return;
      tmp = cvClone( p->orig_img );
      loc = p->loc1;
      cvRectangle( tmp, loc[n], cvPoint(x, y), CV_RGB(255,255,255), 1, 8, 0 );
      cvShowImage( p->win_name, tmp );
      if( p->cur_img )
	cvReleaseImage( &(p->cur_img) );
      p->cur_img = tmp;
    }
}
