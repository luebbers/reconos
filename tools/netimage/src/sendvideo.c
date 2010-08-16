///
/// \file sendvideo.c
///
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
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//

// INCLUDES ================================================================

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>                                                            // for 'basename()'

/* From OpenCV library */
#include "cv.h"
#include "cxcore.h"
#include "highgui.h"

#include "tcp_connection.h"
#include "netimage.h"
#include "debug.h"
#include "cvutil.h"


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
            "               [-p <port>] [-i <infile>] [-c [<id>]] <host>\n"
            "\n"
            "       -h                  display this help\n"
            "       -q                  be quiet (do not display video)\n"
            "       -o <outfile>        save video to <outfile> (NO EXTENSION!)\n"
            "       -f <fps>            frames per second to save (default: 25 or infile's)\n"
            "       -F <fourcc>         fourcc format to save in (default: MPEG-1)\n"
            "\n"
            "SOURCE OPTIONS:\n"
            "       -i <infile>         use <file> as video source\n"
            "       -c [<id>]           use camera with <id>, leave out for first available\n"
            "\n"
            "DESTINATION OPTIONS:\n"
            "       <host>              host to send to\n"
            "       -p <port>           send to port <port> (default: 6666)\n"
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
        c = getopt( argc, argv, "qo:f:F:i:c::p:h" );

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
    char *win_name = "Source Frame";
    char key = 0;
    tcp_connection *con;
    int frame_count = 0, result;

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
	
    gettimeofday(&last, NULL);
    
    // get video data and send/store it
    while ( ( frame = cvQueryFrame( video ) ) && ( char ) key != 'q'
            && !quit ) {
        result = tcp_send( con, frame->imageData, frame->imageSize );

        if ( result > 0 ) {
            if ( !quiet ) {
                cvNamedWindow( win_name, 1 );
                cvShowImage( win_name, frame );
                key = cvWaitKey( 5 );
            }
            if ( output )
                cvWriteFrame( writer, frame );
        } else {
            printf( "connection lost.\n" );
            break;
        }
        gettimeofday(&current, NULL);
        diff = (current.tv_sec - last.tv_sec) * 1000000;
        diff += (current.tv_usec - last.tv_usec);
	
        fprintf(stderr, "FPS: %.2f\r", 1000000.0 / diff);
	
        last.tv_sec = current.tv_sec;
        last.tv_usec = current.tv_usec;
    }

    // clean up
    cvDestroyWindow( win_name );
    cvReleaseCapture( &video );
    if ( output )
        cvReleaseVideoWriter( &writer );
    tcp_connection_destroy( con );

    return 0;
}
