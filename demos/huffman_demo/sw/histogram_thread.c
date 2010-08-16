#include "histogram.h"
#include "histogram_thread.h"
#include "util.h"

#include <stdlib.h>


void * histogram_entry(void * data)
{
	struct Histogram32 h32;
	struct HistogramArgs * args;
	int len;
	unsigned char * buffer;
	mqd_t mq_in, mq_out;
	struct mq_attr attr_in, attr_out;
	
	args = data;
	
	mq_in = my_mq_open(args->mq_recv);
	mq_out = my_mq_open(args->mq_send);
	
	mq_getattr(mq_in, &attr_in);
	mq_getattr(mq_out, &attr_out);
	
	histogram32_init(&h32);
	
	buffer = malloc(attr_in.mq_msgsize);
	
	do {
		len = my_mq_receive(mq_in, buffer);
		histogram32_add(&h32, buffer, len);
		
	} while (len == attr_in.mq_msgsize);
	
	my_mq_send(mq_out, &h32, sizeof h32);
	
	return NULL;
}

