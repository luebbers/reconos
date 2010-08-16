///
/// \file recvvideo.c
///
/// Receive, display and save video streams from a network connection.
/// 
/// This tool is able to receive video data over a TCP/IP connection,
/// display and store it.
///
/// The image data is streamed "as is". Before the stream starts, the
/// size, bit depth, and number of channels of the video stream is
/// transmitted. This tool is supposed to be used either with the
/// 'sendvideo' tool or a eCos/ReconOS thread. See the ReconOS wiki
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
#include <unistd.h>                                                            // for 'getopt()'
#include <signal.h>
#include <libgen.h>                                                            // for 'basename()'

/* From OpenCV library */
#include "cv.h"
#include "cxcore.h"
#include "highgui.h"

#include "debug.h"
#include "tcp_connection.h"
#include "netimage.h"
#include "cvutil.h"

// CONSTANTS ===============================================================

#define MAX_FILENAMELEN 256	///< maximum length of filenames

volatile int quit = 0;			///< quit flag, set by signal handler

// options
int repeat = 0;                 ///< whether to wait for new connections after a transfer
int port = 6666;                ///< post to listen on
int quiet = 0;                  ///< quiet mode (no video display)
int output = 0;                 ///< output received video to a file?
char fourcc[5] = "PIM1";        ///< output video file format default to MPEG-1
double fps = 25.0;              ///< output video file frame rate
char filename[MAX_FILENAMELEN]; ///< output filename
char filename_count[MAX_FILENAMELEN];   ///< temp buffer for output filename


// FUNCTION DEFINITIONS ====================================================

///
/// Handles signals. Prints a note and sets the quit flag.
///
/// \param      sig             received signal
/// 
void sig_handler( int sig )
{

    fprintf( stderr, "Received signal %d, exiting.\n", sig );
    quit = 1;
}


///
/// Prints the program usage.
///
/// \param      basename        the name of this program's executable
/// 
void usage( char *basename )
{
    printf( "%s: receive, display and save video streams.\n"
            "(c) 2007 Enno Luebbers (luebbers@reconos.de)\n"
            "Computer Engineering Group, University of Paderborn\n\n"
            "USAGE:\n"
            "       %s [-r] [-h] [-q] [-o <outfile>] [-f <fps] [-F <fourcc>]\n"
            "               [-p <port>]\n"
            "\n"
            "       -h                  display this help\n"
            "       -r                  repeatedly listen for connections\n"
            "       -q                  be quiet (do not display video)\n"
            "       -o <outfile>        save video to <outfile> (NO EXTENSION!)\n"
            "       -f <fps>            frames per second to save (default: 25)\n"
            "       -F <fourcc>         fourcc format to save in (default: MPEG-1)\n"
            "       -p <port>           listen on port <port> (default 6666)\n"
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
int parse_args( int argc, char *argv[] )
{

    int c;


    while ( 1 ) {
        c = getopt( argc, argv, "ro:qp:f:F:h" );

        if ( c == -1 )
            break;

        switch ( c ) {
        case 'r':
            repeat = 1;
            break;

        case 'q':
            quiet = 1;
            break;

        case 'o':
            output = 1;
            strncpy( filename, optarg, MAX_FILENAMELEN - 4 );
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

        case '?':
        case 'h':
        default:
            usage( basename( argv[0] ) );
            exit( 1 );
            break;
        }
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
    char *win_name = "Received Frame";
    char key = 0;
    tcp_server *server;
    tcp_connection *con;
    int result, frame_count = 0, freeze = 0, con_count = 0;
    char hostname[256];
    image_params params;
    fd_set fds;
    char buf[30];

    // register signal handlers for SIGINT (CTRL+C)
    DEBUG_PRINT( DEBUG_NOTE, "registering signal" )
        if ( signal( SIGINT, sig_handler ) == SIG_ERR ) {
        fprintf( stderr, "failed to register signal handler.\n" );
        exit( 1 );
    }
    // parse command line arguments and set options
    parse_args( argc, argv );

    // start listening
    DEBUG_PRINT( DEBUG_NOTE, "creating server" );
    server = tcp_server_create( port, 2 );
    if ( !server ) {
        fprintf( stderr, "unable to open socket\n" );
        exit( 1 );
    }
    do {
        // use select() to trigger an accept call, so that
        // the signal handler can still intercept a SIGINT
        printf
            ( "Waiting for connection on port %d. Press CTRL+C to quit.\n",
              port );
        fflush( stdout );
        FD_ZERO( &fds );
        FD_SET( server->sockfd, &fds );

        if ( select( server->sockfd + 1, &fds, NULL, NULL, NULL ) > 0 ) {

            con = tcp_accept( server );
            if ( !con ) {
                fprintf( stderr,
                         "unable to accept incoming connection.\n" );
                exit( 1 );
            }
            con_count++;
            printf( "Incoming connection from %s.\n",
                    sockaddr2hostname( &con->addr, hostname,
                                       sizeof( hostname ) ) );

            // receive image header
            if ( netimage_recv_header( con, &params, sizeof( params ) ) <=
                 0 ) {
                fprintf( stderr, "unable to receive image parameters.\n" );
                tcp_connection_destroy( con );
/*                 tcp_server_destroy(server);
                 exit( 1 ); */
                break;
            }
            // Allocate image
            if ( ( frame =
                   netimage_CreateImageFromHeader( &params ) ) == NULL ) {
                fprintf( stderr, "unable to allocate image.\n" );
                tcp_connection_destroy( con );
/*                 tcp_server_destroy(server);
                 exit (1);*/
                break;
            }

            printf
                ( "Receiving image stream (%d x %d, depth %u, %d channels (size: %d bytes)).\n",
                  frame->width, frame->height, frame->depth,
                  frame->nChannels, frame->imageSize );

            if ( !quiet )
                printf( "Press 'q' to abort, 'f' to freeze.\n" );

            // open video file to save received data, if required
            if ( output ) {

                if ( repeat )
                    snprintf( filename_count, MAX_FILENAMELEN,
                              "%s_%03d.mpg", filename, con_count );
                else
                    snprintf( filename_count, MAX_FILENAMELEN, "%s.mpg",
                              filename, con_count );

                writer =
                    cvCreateVideoWriter( filename_count,
                                         atofourcc( fourcc ), fps,
                                         cvSize( params.width,
                                                 params.height ),
                                         params.nChannels > 1 ? 1 : 0 );
                if ( writer == NULL ) {
                    fprintf( stderr, "unable to create output file.\n" );
                    tcp_connection_destroy( con );
                    cvReleaseImage( &frame );
/*                        tcp_server_destroy(server);
                        exit (1);*/
                    break;
                }
                printf( "Writing to output file '%s'.\n", filename_count );
            }
            // receive and display image data (frame by frame)
            key = 0;
            result = 1;
            freeze = 0;
            while ( ( char ) key != 'q' && result > 0 ) {
                result =
                    tcp_receive( con, frame->imageData, frame->imageSize );
                if ( result > 0 ) {
                    // display video
                    if ( !quiet ) {
                        cvNamedWindow( win_name, 1 );
                        if ( key == 'f' )
                            freeze = !freeze;
                        if ( !freeze )
                            cvShowImage( win_name, frame );
                        key = cvWaitKey( 5 );
                    }
                    // write video to file
                    if ( output )
                        cvWriteFrame( writer, frame );
                }
            }

            // clean up
            cvReleaseImage( &frame );
            tcp_connection_destroy( con );
            if ( output )
                cvReleaseVideoWriter( &writer );
        }                                                                      // if select
    } while ( !quit && repeat );

    // clean up
    cvDestroyWindow( win_name );
    DEBUG_PRINT( DEBUG_NOTE, "destroying server" )
        tcp_server_destroy( server );

    return 0;
}
