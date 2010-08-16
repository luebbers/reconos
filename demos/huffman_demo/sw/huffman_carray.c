#include "text.h"
#include "carray_io.h"
#include "encoder_thread.h"
#include "decoder_thread.h"
#include "histogram_thread.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <mqueue.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>


#define BLOCK_SIZE (4*1024)
#define ENCODER_PORT 4443
#define DECODER_PORT 4444
#define STACK_SIZE (1024*1024*2)

static pthread_t encoder_thread;
static pthread_t carray_thread;
static pthread_t decoder_thread;
static pthread_t histogram_thread;

static mqd_t mq_create(const char * name, int msgsize)
{
	struct mq_attr default_mq_attr;
	default_mq_attr.mq_flags = 0;
	default_mq_attr.mq_maxmsg = 4;
	default_mq_attr.mq_msgsize = msgsize;
	default_mq_attr.mq_curmsgs = 0;
	mqd_t result;
	
	mq_unlink(name);
	result = mq_open(name, O_CREAT|O_RDWR, S_IRWXU, &default_mq_attr);
	if(result == (mqd_t)(-1)){
		perror("mq_open (create)");
		fprintf(stderr, "mq name = %s\n", name);
		exit(1);
	}
	
	return result;
}


static void mkthread(pthread_t * thread, void *(*entry)(void*), void * data)
{
	pthread_attr_t attr;
	int error;
	
	pthread_attr_init(&attr);
#ifdef USE_ECOS
	pthread_attr_setstacksize(&attr, STACK_SIZE);
#endif
	error = pthread_create(thread, &attr, entry, data);
	
	if(error){
		perror("pthread_create");
		exit(1);
	}
}


int main(void) {

	struct CArrayIOArgs carray_args;
	struct EncoderArgs encoder_args;
	struct DecoderArgs decoder_args;
	struct HistogramArgs histogram_args;

	// Create mqs for the encoding process
	carray_args.mq_recv = "/decoder_out";
	carray_args.mq_send = "/encoder_in";
	carray_args.data = (unsigned char*)text;
	carray_args.len = text_len;
	
	encoder_args.mq_recv = "/encoder_in";
	encoder_args.mq_send = "/enc2dec";
	encoder_args.mq_histogram_send = "/histogram_in";
	encoder_args.mq_histogram_recv = "/histogram_out";
	
	histogram_args.mq_recv = "/histogram_in";
	histogram_args.mq_send = "/histogram_out";
	
	
	mq_create(encoder_args.mq_send, BLOCK_SIZE);
	mq_create(encoder_args.mq_recv, BLOCK_SIZE);
	mq_create(encoder_args.mq_histogram_send, BLOCK_SIZE);
	mq_create(encoder_args.mq_histogram_recv, BLOCK_SIZE);
	
	// Create mqs for the encoding process
	decoder_args.mq_recv = "/enc2dec";
	decoder_args.mq_send = "/decoder_out";
	
	mq_create(decoder_args.mq_send, BLOCK_SIZE);
	//mq_create(decoder_args.mq_recv, BLOCK_SIZE);

	// Create and join the threads
	mkthread(&encoder_thread, encoder_entry, &encoder_args);
	mkthread(&decoder_thread, decoder_entry, &decoder_args);
	mkthread(&carray_thread, carray_io, &carray_args);
	mkthread(&histogram_thread, histogram_entry, &histogram_args);


	pthread_join(encoder_thread, NULL);
	pthread_join(carray_thread, NULL);
	pthread_join(decoder_thread, NULL);
	pthread_join(histogram_thread, NULL);
	
	return 0;
}


