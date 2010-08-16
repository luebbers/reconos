///
/// \file camgrab.c
///
/// Test program to capture video from a connected camera.
/// 
/// Part of the ReconOS netimage tools to send and receive image
/// data to and from a ReconOS board. 
/// 
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       10.09.2007
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

/* From OpenCV library */
#include "cv.h"
#include "cxcore.h"
#include "highgui.h"

#include "cvutil.h"

// FUNCTION DEFINITIONS ====================================================

////////////////////////////////////////////////////////////////////////////
// MAIN ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///
/// Main program.
///
int main( int argc, char *argv[] )
{

    CvCapture *video;
    IplImage *frame;
    char *win_name = "Captured Frame";
    char key = 0;

    video = cvCreateCameraCapture( -1 );
//    video = cvCreateFileCapture( argv[1] ); 
    if ( !video ) {
        fprintf( stderr, "unable to capture source\n" );
        exit( 1 );
    } else {
        printf( "capture source opened.\n" );
    }

    printCaptureProperties( video );

    printf( "Press 'q' to quit.\n" );

    while ( ( frame = cvQueryFrame( video ) ) && ( char ) key != 'q' ) {
        cvNamedWindow( win_name, 1 );
        cvShowImage( win_name, frame );
        key = cvWaitKey( 5 );
    }

    cvDestroyWindow( win_name );
    cvReleaseCapture( &video );

    return 0;
}
