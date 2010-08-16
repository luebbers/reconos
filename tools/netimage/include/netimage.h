///
/// \file netimage.h
///
/// Utility functions for transferring OpenCV images across a TCP/IP
/// connection
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

#ifndef __NETIMAGE_H__
#define __NETIMAGE_H__

// INCLUDES ================================================================

/* From OpenCV library */
#include "cv.h"
#include "cxcore.h"

#include "tcp_connection.h"
#include <stdint.h>


// TYPE DEFINITIONS ========================================================

/// image parameters
typedef struct {
	uint32_t nChannels;	///< number of channels
	uint32_t depth;		///< image depth per channel
	uint32_t width;		///< image width
	uint32_t height;		///< image height
} image_params;


// FUNCTION PROTOTYPES =====================================================

///
/// Transmits parts of an IplImage header across a tcp_connection.
///
/// The transmitted info consists of image resolution, depth, and
/// number of channels.
///
/// \param      con             connection to transfer info over
/// \param      img             image to extract header from
///
/// \returns   return value of tcp_send (<= 0 on error/EOF, number of
///            transferred bytes otherwise)
///
int netimage_send_header(tcp_connection *con, IplImage *img); 

///
/// Receives parts of an IplImage header across a tcp_connection.
///
/// The transmitted info consists of image resolution, depth, and
/// number of channels.
///
/// \param      con             connection to receive info over
/// \param      params          parameter structure to store header
///                             info in
/// \param      len             size of parameter structure
///
/// \returns   return value of tcp_recv (<= 0 on error/EOF, number of
///            transferred bytes otherwise)
///
int netimage_recv_header(tcp_connection *con, image_params *params, size_t len);

///
/// Allocate a new IplImage from received header information
///
/// Uses cvCreateImage(). The image needs to be deallocated after use
/// via cvReleaseImage().
///
/// \param      params          parameter structure with header info
///
/// \returns    pointer to newly allocated image, NULL on error
///
IplImage *netimage_CreateImageFromHeader(image_params *params);


#endif //__NETIMAGE_H__
