///
/// \file netimage.c
///
/// Utility functions for transferring OpenCV images across a TCP/IP
/// connection.
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

#include "netimage.h"
#include "debug.h"


// FUNCTION DEFINITIONS ====================================================

//
// Transmits parts of an IplImage header across a tcp_connection.
//
// The transmitted info consists of image resolution, depth, and
// number of channels.
//
int netimage_send_header( tcp_connection * con, IplImage * img )
{

    image_params p;
    int result;

    DEBUG_ENTRY( "netimage_send_header()" )
        assert( con != NULL );
    assert( img != NULL );

    p.nChannels = htonl(img->nChannels);
    p.depth = htonl(img->depth);
    p.width = htonl(img->width);
    p.height = htonl(img->height);

    result = tcp_send( con, &p, sizeof( p ) );

    DEBUG_EXIT( "netimage_send_header()" )

        return result;
}


//
// Receives parts of an IplImage header across a tcp_connection.
//
// The transmitted info consists of image resolution, depth, and
// number of channels.
//
int netimage_recv_header( tcp_connection * con, image_params * params,
                          size_t len )
{

    int result;

    DEBUG_ENTRY( "netimage_recv_header()" )
        assert( con != NULL );
    assert( params != NULL );
    assert( len == sizeof( image_params ) );

    result = tcp_receive( con, ( unsigned char * ) params, len );

    params->nChannels = ntohl(params->nChannels);
    params->depth     = ntohl(params->depth);
    params->width     = ntohl(params->width);
    params->height    = ntohl(params->height);

    DEBUG_EXIT( "netimage_recv_header()" )

        return result;

}


//
// Allocate a new IplImage from received header information
//
// Uses cvCreateImage(). The image needs to be deallocated after use
// via cvReleaseImage().
//
IplImage *netimage_CreateImageFromHeader( image_params * params )
{

    IplImage *result;

    DEBUG_ENTRY( "netimage_CreateImageFromHeader()" )
        assert( params != NULL );

    result = cvCreateImage( cvSize( params->width, params->height ),
                            params->depth, params->nChannels );

    DEBUG_EXIT( "netimage_CreateImageFromHeader()" )

        return result;

}
