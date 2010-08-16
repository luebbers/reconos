/***************************************************************************
 * buffers.c: Image buffer support functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * 18.04.2007	Enno Luebbers	Added semaphore management to buffer
 * *************************************************************************/
#include "buffers.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

int byte_buffer_init(struct byte_buffer * bb, int w, int h) {
	bb->width = w;
	bb->height = h;
	cyg_semaphore_init(&bb->rdy_sem, 1);
	cyg_semaphore_init(&bb->new_sem, 0);
	bb->data = malloc(w*h);
	return bb->data != NULL;
}

void byte_buffer_dispose(struct byte_buffer * bb){
	free(bb->data);
	bb->data = NULL;
	bb->width = bb->height = 0;
}

int byte_buffer_read(struct byte_buffer * bb, int sock_fd){
	size_t bytes_read = 0;
	while(bytes_read < bb->width*bb->height){
		int result = recv(sock_fd,bb->data + bytes_read,bb->width*bb->height - bytes_read,0);
		//diag_printf("read %d bytes\n",result);
		if(result == -1 || result == 0) return bytes_read;
		bytes_read += result;
	}
	return bytes_read;
}

void byte_buffer_fill(struct byte_buffer * bb, unsigned char value){
	size_t x,y;
	for(y = 0; y < bb->height; y++){
		unsigned char * l = bb->data + y*bb->width;
		for(x = 0; x < bb->width; x++){
			l[x] = value;
		}
	}
}

struct composit_buffer * composit_buffer_create(int w, int h, int channels){
	struct composit_buffer * cb = malloc(sizeof *cb);
	if(!cb) return NULL;
	if(!composit_buffer_init(cb,w,h,channels)){
		free(cb);
		return NULL;
	}
	return cb;
}

void composit_buffer_free(struct composit_buffer * cb){
	composit_buffer_dispose(cb);
	free(cb);
}

int composit_buffer_init(struct composit_buffer * cb, int w, int h, int channels){
	size_t i,j;
	
	cb->width = w;
	cb->height = h;
	cb->channel_count = channels;
	
	cb->channels = malloc(channels*sizeof*cb->channels);
	if(!cb->channels) return 0;
	
	for(i = 0; i < cb->channel_count; i++){
		if(!byte_buffer_init(cb->channels + i,w,h)){
			for(j = 0; j < i; j++){
				byte_buffer_dispose(cb->channels + j);
				return 0;
			}
		}
	}
	
	return 1;
}

void composit_buffer_dispose(struct composit_buffer * cb){
	size_t i;
	for(i = 0; i < cb->channel_count; i++){
		byte_buffer_dispose(cb->channels + i);
	}
	free(cb->channels);
	cb->channels = NULL;
	cb->width = cb->height = cb->channel_count = 0;
}

void composit_buffer_copy_line_from(struct composit_buffer * cb, int line, void * buffer){
	unsigned char * p = buffer;
	size_t x,c;
	for(x = 0; x < cb->width; x++){
		for(c = 0; c < cb->channel_count; c++){
			BB_PIXEL(cb->channels[c],x,line) = *p;
			p++;
		}
	}
}

void composit_buffer_display(struct composit_buffer * cb, unsigned char * fb32, size_t rlen){
	size_t x,y,c;
	for(y = 0; y < cb->height; y++){
		unsigned char * dst_line = fb32 + rlen*y;
		unsigned int src_line_offset = y*cb->width;
		for(x = 0; x < cb->width; x++){
			unsigned char * p = dst_line + x*4;
			unsigned int src_offset = src_line_offset + x;
			for(c = 0; c < cb->channel_count; c++){
				p[c] = cb->channels[c].data[src_offset];
			}
		}
	}
}

void composit_buffer_display32(struct composit_buffer * cb, unsigned char * fb32, size_t rlen){
	size_t x,y;
	const unsigned char * c0 = cb->channels[0].data;
	const unsigned char * c1 = cb->channels[1].data;
	const unsigned char * c2 = cb->channels[2].data;
	const unsigned char * c3 = cb->channels[3].data;
	for(y = 0; y < cb->height; y++){
		unsigned char * dst_line = fb32 + rlen*y;
		unsigned int src_line_offset = y*cb->width;
		for(x = 0; x < cb->width; x++){
			unsigned char * p = dst_line + x*4;
			unsigned int src_offset = src_line_offset + x;
			p[0] = c0[src_offset];
			p[1] = c1[src_offset];
			p[2] = c2[src_offset];
			p[3] = c3[src_offset];
		}
	}
}

static void byte_buffer_display32_gray(struct byte_buffer * bb, unsigned char * fb32, size_t rlen){
	size_t x,y;
	const unsigned char * c = bb->data;
	
	for(y = 0; y < bb->height; y++){
		unsigned char * dst_line = fb32 + rlen*y;
		unsigned int src_line_offset = y*bb->width;
		for(x = 0; x < bb->width; x++){
			unsigned int * p = (unsigned int*)(dst_line + x*4);
			unsigned int src_offset = src_line_offset + x;
			int g = c[src_offset];
			g = (g | (g << 8) | (g << 16) | (g << 24));
			*p = g;
		}
	}
}

void byte_buffer_display32(struct byte_buffer * bb, unsigned char * fb32, size_t rlen, int channel){
	size_t x,y;
	const unsigned char * c = bb->data;
	
	if(channel < 0) byte_buffer_display32_gray(bb,fb32,rlen);
	
	for(y = 0; y < bb->height; y++){
		unsigned char * dst_line = fb32 + rlen*y;
		unsigned int src_line_offset = y*bb->width;
		for(x = 0; x < bb->width; x++){
			unsigned char * p = dst_line + x*4;
			unsigned int src_offset = src_line_offset + x;
			p[channel] = c[src_offset];
		}
	}
}

