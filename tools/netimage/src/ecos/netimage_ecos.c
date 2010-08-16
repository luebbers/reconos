///
/// \file netimage_ecos.c
///
/// \author     Enno Luebbers <luebbers@reconos.de>
/// \date       06.08.2010
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

#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <network.h>
#include <cyg/hal/lcd_support.h>
#include <reconos/reconos.h>
#include <unistd.h>

#define DEFAULT_LISTEN_PORT 6666

struct ImageParams
{
	int nChannels;	         ///< number of channels
	int depth;		///< image depth per channel
	int width;		///< image width
	int height;		///< image height
};

static struct lcd_info tft_info;        ///< framebuffer info structure

// initialize vga display
static void tft_init(void)
{
	//*((uint32_t*)0x50000004) = 3; // initiate self destruction
	lcd_init(24);
	lcd_clear();
	lcd_getinfo(&tft_info);
	diag_printf("TFT framebuffer: width : %d\n", tft_info.width);
	diag_printf("                 height: %d\n", tft_info.height);
	diag_printf("                 bpp   : %d\n", tft_info.bpp);
	diag_printf("                 type  : %d\n", tft_info.type);
	diag_printf("                 rlen  : %d\n", tft_info.rlen);
}

// draw a single pixel
static inline void tft_set_pixel(int x, int y, unsigned int r, unsigned int g, unsigned int b)
{
	r = r & 0xFF;
	g = g & 0xFF;
	b = b & 0xFF;
	((uint32_t*)tft_info.fb)[x + y*tft_info.rlen/4] = b | (g << 8) | (r << 16);
}

// draw a test image
static void tft_test_image(void)
{
	int x,y;
	// assume 32 bpp
	for(y = 0; y < tft_info.height; y++){
		for(x = 0; x < tft_info.width; x++){
			int r = 0,g = 0,b = 0;
			int c = (((x/10) + (y/10)) % 2)*0x3F + (((x/80) + (y/80)) % 2)*0xC0;
			
			if(x < 0x100){
				if(y < 80)       r = 0xFF - x;
				else if(y < 160) g = 0xFF - x;
				else if(y < 240) b = 0xFF - x;
				else if(y < 320) r = g = b = x;
				else             r = g = b = c;
			}
			else{
				r = g = b = c;
			}
			tft_set_pixel(x,y,r,g,b);
		}
	}
}

// creates a server socket and waits for incomming connection.
// returns a valid file descriptor on success. returns -1 on error.
int accept_connection(void)
{
	struct sockaddr_in local_addr;
	struct sockaddr_in remote_addr;
	
	bzero(&local_addr,0);
	bzero(&remote_addr,0);
	
	int sockfd = socket( AF_INET, SOCK_STREAM, 0 );
	if(sockfd < 0){
		diag_printf("socket creation failed\n");
		return -1; 
	}
	
	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = INADDR_ANY;
	local_addr.sin_port = htons(DEFAULT_LISTEN_PORT);
	
	int result = bind(sockfd, (struct sockaddr *) &local_addr, sizeof local_addr);
	if(result < 0){
		diag_printf("bind socket failed\n");
		return -1;
	}
	
	listen(sockfd,0);
	
	socklen_t addrlen;
	int fd = accept(sockfd, (struct sockaddr *) &remote_addr, &addrlen);
	if(fd < 0){
		diag_printf("accept failed\n");
		return -1;
	}
	
	return fd;
}

// read 'len' bytes from 'sockfd' into 'buf'. block until all data is read
// or an read error occurs. Returns 1 on success, 0 otherwise.
int tcp_read(int fd, void *buf, size_t len)
{
	uint8_t * p = buf;
	while(len != 0){
		int result = read(fd, p, len);
		if(result == -1) return 0;
		
		p += result;
		len -= result;
	}
	return 1;
}


// receives image stream header information. returns 1 on success,
// 1 on error
int recv_header(int fd, struct ImageParams * ip)
{
	if(!tcp_read(fd, ip, sizeof *ip)) return 0;
	
	ip->nChannels = ntohl(ip->nChannels);
	ip->depth = ntohl(ip->depth);		///< image depth per channel
	ip->width = ntohl(ip->width);		///< image width
	ip->height = ntohl(ip->height);		///< image height
	
	return 1;
}

int main(void)
{
	static struct ImageParams imageParams;
	
	// *** init display ******************************************************
	tft_init();
	tft_test_image();
	
	// *** init network interfaces *******************************************
	init_all_network_interfaces();
	if(!eth0_up){
		diag_printf("failed to initialize eth0\naborting\n");
		return 1;
	}
	else{
		diag_printf(" eth0 up\n");
	}
	
	diag_printf("\n\n");
	diag_printf("########################################\n");
	diag_printf("#        Netimage receiver Demo        #\n");
	diag_printf("########################################\n");
	diag_printf("\n\n");
	
	// *** tcp/ip connect ****************************************************
	diag_printf("waiting for connection...\n");
	int fd = accept_connection();
	if(fd < 0){
		diag_printf("connection failed\naborting\n");
		return 1;
	}
	diag_printf("connection established\n");
	
	if(!recv_header(fd, &imageParams)){
		diag_printf("failed reading image parameters (header)\n");
		return 1;
	}
	
	diag_printf("\n");
	diag_printf("Image stream header:  width = %d\n", imageParams.width);
	diag_printf("                     height = %d\n", imageParams.height);
	diag_printf("                        bpc = %d\n", imageParams.depth);
	diag_printf("                   channels = %d\n", imageParams.nChannels);
	
	while(1){
		// current pixel coordinates
		int x,y;
		// number of bytes between the end of a line in the framebuffer
		// and the beginning of the next line.
		int step = tft_info.rlen/4 - imageParams.width;
		// buffer for incomming pixel data
		uint8_t line[4096];
		// frame buffer pointer
		uint32_t * fb_pos = tft_info.fb;
		
		for(y = 0; y < imageParams.height; y++){
			// read a line into the buffer
			tcp_read(fd, line, imageParams.depth/8*imageParams.nChannels*imageParams.width);
			// current position
			uint8_t * p = line;
			
			for(x = 0; x < imageParams.width; x++){
				// write pixel to framebuffer
				*fb_pos = p[0] | (p[1] << 8) | (p[2] << 16);
				// next pixel
				p += 3;
				fb_pos++;
			}
			// next line
			fb_pos += step;
		}
	}
	
	return 0; // never
}

