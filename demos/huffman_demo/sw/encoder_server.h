#ifndef ENCODER_SERVER_H
#define ENCODER_SERVER_H

#ifdef USE_ECOS
#include <network.h>
#endif

#include <netinet/in.h>

struct EncoderArgs
{
	uint16_t port;
};

void * encoder_entry(void * data);

#endif
