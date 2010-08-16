#include "decoder_server.h"
#include "encoder_server.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <sys/types.h>

#include <pthread.h>
#include <mqueue.h>

#define ENCODER_PORT 4443
#define DECODER_PORT 4444
#define STACK_SIZE (1024*1024*2)

static pthread_t decoder_thread, encoder_thread;
static pthread_attr_t decoder_attr, encoder_attr;

int main(void)
{
	struct DecoderArgs decoder_args;
	struct EncoderArgs encoder_args;
	int error;

#ifdef USE_ECOS
	init_all_network_interfaces();
#endif

	decoder_args.port = DECODER_PORT;
	encoder_args.port = ENCODER_PORT;
	
	pthread_attr_init(&decoder_attr);
	pthread_attr_init(&encoder_attr);
#ifdef USE_ECOS
	pthread_attr_setstacksize(&decoder_attr, STACK_SIZE);
	pthread_attr_setstacksize(&encoder_attr, STACK_SIZE);
	
	pthread_attr_getstacksize(&decoder_attr,&error);
	pthread_attr_getstacksize(&encoder_attr,&error);
#endif

	error = pthread_create(
			&decoder_thread,
			&decoder_attr,
			decoder_entry,
			&decoder_args);
	
	if(error){
		perror("pthread_create: decoder");
		exit(1);
	}
	
	error = pthread_create(
			&encoder_thread,
			&encoder_attr,
			encoder_entry,
			&encoder_args);
	
	
	if(error){
		perror("pthread_create: encoder");
		exit(1);
	}
	
#ifdef USE_ECOS	
	pthread_attr_getstacksize(&decoder_attr,&error);
	pthread_attr_getstacksize(&encoder_attr,&error);
#endif

	pthread_join(decoder_thread, NULL);
	pthread_join(encoder_thread, NULL);
	
	return 0;
}


