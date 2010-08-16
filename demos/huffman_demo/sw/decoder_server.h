#ifndef DECODER_SERVER_H
#define DECODER_SERVER_H

#ifdef USE_ECOS
#include <network.h>
#endif

#include <netinet/in.h>

struct DecoderArgs
{
	uint16_t port;
};

void * decoder_entry(void * data);

#endif

