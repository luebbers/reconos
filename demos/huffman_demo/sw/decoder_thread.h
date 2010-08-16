#ifndef DECODER_THREAD_H
#define DECODER_THREAD_H

struct DecoderArgs
{
	char * mq_recv;
	char * mq_send;
};

void * decoder_entry(void * data);

#endif
