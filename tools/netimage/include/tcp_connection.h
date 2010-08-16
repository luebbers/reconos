///
/// \file tcp_connection.h
///
/// Convenience functions for creating TCP/IP connections.
/// 
/// Provides functions for listening for TCP connections and connecting
/// to remote servers, as well as transferring of arbitrarily sized data.
///
/// Written for the ReconOS netimage tools to send and receive image
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

#ifndef __TCP_CONNECTION_H__
#define __TCP_CONNECTION_H__


// INCLUDES ================================================================

#include <sys/types.h> 
#include <netinet/in.h>


// CONSTANTS ===============================================================

#define INIT_BLOCKSIZE 1024	///< standard blocksize


// MACROS ==================================================================

#ifndef MIN
/// minimum function
#define MIN(x,y) (x < y ? x : y)
#endif


// TYPE DEFINITIONS ========================================================

/// TCP/IP server structure
typedef struct {
	int sockfd;					///< local socket file descriptor
    struct sockaddr_in addr;	///< local address
} tcp_server;

/// TCP/IP connection structure
typedef struct {
	int sockfd;///< remote socket file descriptor
    struct sockaddr_in addr;		///< remote address
    unsigned int blocksize; ///< block size to transfer with one send()
} tcp_connection;


// FUNCTION PROTOTYPES =====================================================

///
/// Creates a TCP/IP server by binding to a socket and listening. The 
/// returned data structure can be used to 'tcp_accept' incoming
/// connections.
///
/// \param      port            the TCP port to bind to
/// \param      backlog         how many simultaneous connection attempts
///                             to allow
///
/// \returns    a pointer to a 'tcp_server' struct reperesenting the 
///             server
/// 
tcp_server *tcp_server_create( unsigned int port, unsigned int backlog );

///
/// Creates a TCP/IP connection by accepting an incoming connection.
/// If there are no incoming connections (and the server wasn't created
/// with a O_NONBLOCK flag), tcp_accept waits until a client connects.
/// To multiplex, use 'select()'.
/// The returned data structure can be used to 'tcp_send' and
/// 'tcp_receive' data.
///
/// \param      server          the server socket to accept connections on
///
/// \returns    a pointer to a 'tcp_connection' struct reperesenting the 
///             connection
/// 
tcp_connection *tcp_accept( tcp_server *server );

///
/// Creates a TCP/IP connection by connecting to a remote host.
/// The returned data structure can be used to 'tcp_send' and
/// 'tcp_receive' data.
///
/// \param      address         the host name or IP address of the remote
///                             host
/// \param      port            the remote port number
///
/// \returns    a pointer to a 'tcp_connection' struct reperesenting the 
///             connection
/// 
tcp_connection *tcp_connection_create( const char* address, unsigned int port );

///
/// Sends data over a tcp_connection.
///
/// \param      con             the (already established) connection
/// \param      buf             pointer to the data to send
/// \param      len             amount of data to send (in bytes)          
///
/// \returns    number of sent bytes, or '0' if connection was lost, or
///             '-1' on error.
/// 
int tcp_send( tcp_connection *con, unsigned char *buf, size_t len );

///
/// Receives data over a tcp_connection. Will block until data has been read.
///
/// \param      con             the (already established) connection
/// \param      buf             pointer to a (large enough) buffer for
///                             storing the received data
/// \param      len             amount of data to receive (in bytes)
///
/// \returns    number of received bytes, or '0' if connection was lost, or
///             '-1' on error.
/// 
int tcp_receive( tcp_connection *con, unsigned char *buf, size_t len );

///
/// Closes a TCP connection and frees the associated data structure.
///
/// \param      con             the connection to be destroyed
/// 
void tcp_connection_destroy( tcp_connection *con );

///
/// Closes a TCP listening socket and frees the associated data structure.
///
/// \param      s             the server to be destroyed
/// 
void tcp_server_destroy( tcp_server *s );

///
/// Retreives the fully qualified domain name (FQDN) of a internet host
/// address given as a 'struct sockaddr_in', if available. If the hostname
/// cannot be retrieved, the numeric IP address is returned instead.
///
/// This code is adapted from openssh's "canonhost.c".
///
/// \param      from            pointer to the sockaddr_in structure
/// \param      name            pointer to a buffer where the name will
///                             will be stored
/// \param      namelen         size of name buffer
///
/// \returns    pointer to the 'name' string on success, NULL on error.
/// 
const char *sockaddr2hostname(struct sockaddr_in *from, char *name, size_t namelen);


#endif
