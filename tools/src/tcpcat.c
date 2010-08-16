///
/// \file tcpcat.c
///
/// The tcpcat tool reads data from stdin and sends it to the remote host.
/// Data received from the remote host is written to stdout
/// This is a very rudimentary replacement for netcat. Since netcat handles
/// sending and receiving of data in a single thread, race conditions may occur.
/// This program is intended to solve that problem.
///
///
/// \author     Andreas Agne    <agne@upb.de>
/// \date       28.10.2008
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
// 28.10.2008   Andreas Agne    file created


#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <netdb.h>

// send and receive buffer sizes. the buffers themselves are allocated on the stack
#define SEND_BUFFER_SIZE (1024)
#define RECV_BUFFER_SIZE (1024)


/*
 * entry point for the sending thread
 */
void * send_entry(void * data)
{
	int sock = (int)data;
	unsigned char buffer[SEND_BUFFER_SIZE];
	int len;
	
	while(1){
		// read as much as possible (or until buffer full) from stdin
		len = fread(buffer, 1, SEND_BUFFER_SIZE, stdin);
		if(len == 0){
			// end of input -> shut down local end of connection
			shutdown(sock, SHUT_WR);
			return NULL;
		}
		
		// send data to remote host
		len = send(sock, buffer, len, 0);
		if(len == -1){
			perror("send");
			return NULL;
		}
	}
}


/*
 * entry point for the receiving thread
 */
void * recv_entry(void * data)
{
	int sock = (int)data;
	unsigned char buffer[RECV_BUFFER_SIZE];
	int len;
	
	while(1){
		// receive data from remote host
		len = recv(sock, buffer, RECV_BUFFER_SIZE, 0);
		if(len <= 0){
			fflush(stdout);
			if(len == -1){
				perror("recv");
			}
			return NULL;
		}
		
		// write to stdout
		len = fwrite(buffer, len, 1, stdout);
		if(len == -1){
			perror("fwrite");
			return NULL;
		}
	}
}


/*
 * display a short usage message and exit
 */
static void exit_usage(const char * name)
{
	fprintf(stderr,"usage: %s <host> <port>\n", name);
	fprintf(stderr,"\tforward stdin to remote host and write received data to stdout.\n");
	exit(1);
}

static pthread_t recv_thread, send_thread;

int main(int argc, char ** argv)
{
	int local_socket;
	struct hostent *he;
	int result;
	struct sockaddr_in local_addr, remote_addr;
	void * dontcare;
	
	// check arguments
	if(argc != 3){
		exit_usage(argv[0]);
	}
	
	// resolve hostname
	he = gethostbyname(argv[1]);
	if (!he) {
		fprintf(stderr,"Invalid host: %s\n", argv[1]);
		exit(1);
	}
	memcpy(&remote_addr.sin_addr, he->h_addr, he->h_length);
	
	// set up local tcp socket
	memset(&local_addr, 0, sizeof(local_addr));
	remote_addr.sin_family      = AF_INET;
	//remote_addr.sin_addr.s_addr = inet_addr(argv[1]);
	remote_addr.sin_port        = htons(atoi(argv[2]));
	
	local_socket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (local_socket == -1){
		perror("socket");
		exit(1);
	}
	
	// connect to peer
	result = connect(local_socket, (struct sockaddr*)&remote_addr, sizeof remote_addr);
	if(result == -1){
		perror("connect");
	}
	
	// create and run receiving and sending threads
	pthread_create(&recv_thread, NULL, recv_entry, (void*)local_socket);
	pthread_create(&send_thread, NULL, send_entry, (void*)local_socket);
	
	// wait for the threads to finish and exit
	pthread_join(recv_thread, &dontcare);
	pthread_join(send_thread, &dontcare);
	
	return 0;
}

