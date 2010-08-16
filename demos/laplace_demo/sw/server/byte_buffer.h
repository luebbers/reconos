/***************************************************************************
 * byte_buffer.h: Image buffer struct and support functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created

 * *************************************************************************/
#ifndef BYTE_BUFFER_H
#define BYTE_BUFFER_H

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
struct byte_buffer * byte_buffer_create(int w, int h);
void byte_buffer_free(struct byte_buffer * bb);

#endif // BYTE_BUFFER_H

