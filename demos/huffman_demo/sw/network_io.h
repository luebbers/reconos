#ifndef NETWORK_IO_H
#define NETWORK_IO_H

struct NetworkIOArgs
{
	char * mq_send;
	char * mq_recv;
	int port;
};

void * encoder_network_io(void * data);
void * decoder_network_io(void * data);

#endif

