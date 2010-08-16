/***************************************************************************
 * buffers.h: Various image buffers and support functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * 18.04.2007	Enno Luebbers	Added semaphore management to buffer
 * *************************************************************************/
#ifndef BUFFERS_H
#define BUFFERS_H

#include <stdlib.h>
#include <cyg/kernel/kapi.h>


struct byte_buffer
{
	size_t width;
	size_t height;
	cyg_sem_t rdy_sem;				///< ready to be overwritten
	cyg_sem_t new_sem;				///< contains new data
	unsigned char * data;
};

///
/// Creates a new buffer, including the semaphores
///
/// \param	w	width of image
/// \param	h	height of image
///
/// \returns	0, if unable to allocate image memory, != 0 otherwise
///
int byte_buffer_init(struct byte_buffer * bb, int w, int h);
void byte_buffer_dispose(struct byte_buffer * bb);
int byte_buffer_read(struct byte_buffer * bb, int sock_fd);
void byte_buffer_fill(struct byte_buffer * bb, unsigned char value);
void byte_buffer_display32(struct byte_buffer * bb, unsigned char * fb32, size_t rlen, int channel);

#define BB_PIXEL(bb,x,y) ((bb).data[(x) + (y)*(bb).width])

struct composit_buffer
{
	size_t width;
	size_t height;
	size_t channel_count;
	struct byte_buffer * channels;
};

struct composit_buffer * composit_buffer_create(int w, int h, int channels);
void composit_buffer_free(struct composit_buffer * cb);
int composit_buffer_init(struct composit_buffer * cb, int w, int h, int channels);
void composit_buffer_dispose(struct composit_buffer * cb);
void composit_buffer_copy_line_from(struct composit_buffer * cb, int line, void * buffer);
void composit_buffer_display(struct composit_buffer * cb, unsigned char * fb32, size_t rlen);
void composit_buffer_display32(struct composit_buffer * cb, unsigned char * fb32, size_t rlen);

#endif // BUFFERS_H

