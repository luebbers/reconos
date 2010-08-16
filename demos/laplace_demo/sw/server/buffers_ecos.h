/***************************************************************************
 * buffer_ecos.h: Header file for image processing threads
 *             
 * Declares info structures and thread entry functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * 04.04.2007	Enno Luebbers	changed thread to info structure
 * *************************************************************************/
#ifndef BUFFERS_ECOS_H
#define BUFFERS_ECOS_H

#include <cyg/kernel/kapi.h>
#include "buffers.h"

#define BUFFER_THREAD_STACK_SIZE (1024*1024)

//
// image processing chain thread context
//
struct buffer_thread_info
{
	unsigned int num_buffers;		///< number of buffers (e.g. 2 for double buffering)
	struct byte_buffer * src;		///< pointer to source image buffers
	struct byte_buffer * dst;		///< pointer to target image buffers
	cyg_addrword_t data;			///< misc thread data
	
/*	cyg_sem_t * rdy0;			// semaphore "ready for new data" to prev thread
	cyg_sem_t * rdy1;			// semaphore "ready for new data" to next thread
	cyg_sem_t * new0;			// semaphore "new data available" to prev thread
	cyg_sem_t * new1;			// semaphore "new data available" to next thread	
*/
};

int buffer_thread_info_init(
								struct buffer_thread_info * bti, 
								unsigned int num_buffers, 
								struct byte_buffer *src,
								struct byte_buffer *dst/*, 
								cyg_sem_t *rdy0, 
								cyg_sem_t *rdy1, 
								cyg_sem_t *new0, 
								cyg_sem_t *new1*/
							);
		
void entry_buffer_recv(cyg_addrword_t p_buffer_thread);
void entry_buffer_laplace(cyg_addrword_t p_buffer_thread);
void entry_buffer_display(cyg_addrword_t p_buffer_thread);

#endif

