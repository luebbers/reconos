///
/// \file ecap_net.c
///
/// Low-level routines for partial reconfiguration via network.
/// This is a kind of hack. :) It sends the filename of the required
/// partial bitstream via TCP to a host PC, which then reconfigures it
/// via JTAG. ECAP as in external configuration access port...
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       16.06.2009
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
// Major Changes:
//
// 16.06.2009   Enno Luebbers   File created.
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <network.h>
#include <reconos/reconos.h>
#include <unistd.h>

static int 					conn_s;	// connection socket
static struct sockaddr_in 	servaddr;

#define _string(s) #s
#define string(s) _string(s)

#define PORT 42424
#define ADDRESS "192.168.42.1"



// ==== HELPER FUNCTIONS ===============================================
ssize_t Readline(int sockd, void *vptr, size_t maxlen) {
    ssize_t n, rc;
    char    c, *buffer;

    buffer = vptr;

    for ( n = 1; n < maxlen; n++ ) {
	
	if ( (rc = read(sockd, &c, 1)) == 1 ) {
	    *buffer++ = c;
	    if ( c == '\n' )
		break;
	}
	else if ( rc == 0 ) {
	    if ( n == 1 )
		return 0;
	    else
		break;
	}
	else {
	    if ( errno == EINTR )
		continue;
	    return -1;
	}
    }

    *buffer = 0;
    return n;
}


/*  Write a line to a socket  */

ssize_t Writeline(int sockd, const void *vptr, size_t n) {
    size_t      nleft;
    ssize_t     nwritten;
    const char *buffer;

    buffer = vptr;
    nleft  = n;

    while ( nleft > 0 ) {
	if ( (nwritten = write(sockd, buffer, nleft)) <= 0 ) {
	    if ( errno == EINTR )
		nwritten = 0;
	    else
		return -1;
	}
	nleft  -= nwritten;
	buffer += nwritten;
    }

    return n;
}







///
/// Initialize the external "ICAP"
///
void ecap_init(void){

    char *address;
    unsigned int port;

    address = string(UPBFUN_RECONOS_ECAP_HOST);
    port = UPBFUN_RECONOS_ECAP_PORT;

    if ((conn_s = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        CYG_FAIL("unable to create socket");
    }
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(port);

    if (inet_aton(address, &servaddr.sin_addr) <= 0) {
        CYG_FAIL("invalid remote IP address");
    }

    if (connect(conn_s, (struct sockaddr *) &servaddr, sizeof(servaddr)) < 0) {
        CYG_FAIL("can't connect()");
    }
		
}

///
/// Load a bitstream via the external "ICAP"
///
/// @param bitstream pointer to the bitstream struct
///
void ecap_load(reconos_bitstream_t *bitstream) {
	
	char recv_buf[80];
	ssize_t send_len, recv_len;
	
	send_len = Writeline(conn_s, bitstream->filename, strlen(bitstream->filename));
	CYG_ASSERT(send_len = strlen(bitstream->filename), "Error while writing to ECAP");
	recv_len = Readline(conn_s, recv_buf, 80);

#ifdef UPBDBG_RECONOS_DEBUG
	diag_printf("\t\tECAP says: %s", recv_buf);
#endif        

        if ( recv_buf[0] != 'O' || recv_buf[1] != 'K' ) {
            CYG_FAIL("ecap reconfiguration failed");
        }
		
}
