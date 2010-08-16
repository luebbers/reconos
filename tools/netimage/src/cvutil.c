///
/// \file cvutil.c
///
/// Utility functions for use with the OpenCV library.
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

#include <assert.h>

#include "cvutil.h"


// FUNCTION DEFINITIONS ====================================================

//
// Prints the properties of a CvCapture structure.
//
void printCaptureProperties( CvCapture * capture )
{

    assert( capture != NULL );

    printf( "Capture properties of CvCapture at 0x%08X:\n"
            "CV_CAP_PROP_POS_MSEC     : %f\n"
            "CV_CAP_PROP_POS_FRAMES   : %f\n"
            "CV_CAP_PROP_POS_AVI_RATIO: %f\n"
            "CV_CAP_PROP_FRAME_WIDTH  : %f\n"
            "CV_CAP_PROP_FRAME_HEIGHT : %f\n"
            "CV_CAP_PROP_FPS          : %f\n"
            "CV_CAP_PROP_FOURCC       : %f\n"
            "CV_CAP_PROP_FRAME_COUNT  : %f\n",
            ( unsigned int ) capture,
            cvGetCaptureProperty( capture, CV_CAP_PROP_POS_MSEC ),
            cvGetCaptureProperty( capture, CV_CAP_PROP_POS_FRAMES ),
            cvGetCaptureProperty( capture, CV_CAP_PROP_POS_AVI_RATIO ),
            cvGetCaptureProperty( capture, CV_CAP_PROP_FRAME_WIDTH ),
            cvGetCaptureProperty( capture, CV_CAP_PROP_FRAME_HEIGHT ),
            cvGetCaptureProperty( capture, CV_CAP_PROP_FPS ),
            cvGetCaptureProperty( capture, CV_CAP_PROP_FOURCC ),
            cvGetCaptureProperty( capture, CV_CAP_PROP_FRAME_COUNT ) );
}

//
// Converts a string containing a FOURCC code to an integer.
//
int atofourcc( char *a )
{
    return CV_FOURCC( a[0], a[1], a[2], a[3] );
}
