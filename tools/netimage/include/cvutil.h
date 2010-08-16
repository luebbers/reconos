///
///
/// \file cvutil.h
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

#ifndef __CVUTIL_H__
#define __CVUTIL_H__

// INCLUDES ================================================================

/* from OpenCV */
#include "highgui.h"

// FUNCTION PROTOTYPES =====================================================

///
/// Prints the properties of a CvCapture structure.
///
/// \param      capture      the CvCapture structure to examine
///
void printCaptureProperties( CvCapture *capture );

///
/// Converts a string containing a FOURCC code to an integer.
///
/// \param    a      string to convert
///
/// \returns   the corresponding integer
///
int atofourcc(char *a);

#endif
