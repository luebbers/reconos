#ifndef ENCODER_THREAD_H
#define ENCODER_THREAD_H

struct EncoderArgs
{
	char * mq_send;
	char * mq_recv;
	char * mq_histogram_send;
	char * mq_histogram_recv;
};

void * encoder_entry(void * data);

#endif

