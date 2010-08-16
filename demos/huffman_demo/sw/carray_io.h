#ifndef CARRAY_IO_H
#define CARRAY_IO_H

struct CArrayIOArgs
{
	char * mq_send; // to encoder
	char * mq_recv; // from decoder
	unsigned char * data;
	int len;
};

void * carray_io(void * data);

#endif

