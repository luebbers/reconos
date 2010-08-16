#include "histogram.h"
#include "package_merge.h"
#include "codebook.h"
#include "encoder.h"
#include "canonical.h"
#include "util.h"

#include "encoder_thread.h"
#include <mqueue.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

#include <sys/types.h>
#include <assert.h>

void * encoder_entry(void * data)
{
	struct EncoderArgs * args;
	mqd_t mq_in, mq_out, mq_histogram_in, mq_histogram_out;
	struct mq_attr in_attr, out_attr, histogram_in_attr, histogram_out_attr;
	int total, len, i;
	unsigned char * buffer;
	unsigned char * text = NULL;
	
	struct Histogram32 h32;
	unsigned char codelen[128];
	struct Codebook cb;
	struct Encoder enc;
	struct Tree tree;
	
	args = data;
	
	mq_in = my_mq_open(args->mq_recv);
	mq_out = my_mq_open(args->mq_send);
	
	mq_getattr(mq_in,&in_attr);
	mq_getattr(mq_out,&out_attr);
	
	buffer = malloc(in_attr.mq_msgsize);
	
	total = 0;
	do {
		len = my_mq_receive(mq_in,buffer);
		total += len;
		text = realloc(text, total);
		memcpy(text + total - len, buffer, len);
		
	} while(len == in_attr.mq_msgsize);
	
	printf("received %d bytes of input\n", total);
	
	
	
	//histogram32_init(&h32);
	//histogram32_add(&h32, text, total);
	mq_histogram_in = my_mq_open(args->mq_histogram_recv);
	mq_histogram_out = my_mq_open(args->mq_histogram_send);
	mq_getattr(mq_histogram_in, &histogram_in_attr);
	mq_getattr(mq_histogram_out, &histogram_out_attr);
	
	buffer = realloc(buffer, histogram_out_attr.mq_msgsize);
	for(i = 0; i <= total; i += histogram_in_attr.mq_msgsize){
		len = total - i;
		if(len > histogram_in_attr.mq_msgsize){
			len = histogram_in_attr.mq_msgsize;
		}
		my_mq_send(mq_histogram_out, buffer + i, len);
	}
	len = my_mq_receive(mq_histogram_in, &h32);
	assert(len == sizeof h32);
	
	package_merge(&h32, 16, codelen);
	ctree_create(&tree, codelen);
	codebook_create(&cb, &tree);
	encoder_init(&enc, &cb);
	
	my_mq_send(mq_out, &total, 4);
	my_mq_send(mq_out, codelen, 128);
	
	len = 0;
	buffer = realloc(buffer, out_attr.mq_msgsize);
	for(i = 0; i < total; i++){
		int c;
		encoder_put_symbol(&enc, text[i]);
		while((c = encoder_get_byte(&enc)) != ENCODER_NEED_INPUT){
			uint8_t tmp = c;
			buffer[len++] = tmp;
			if(len == out_attr.mq_msgsize){
				my_mq_send(mq_out, buffer, len);
			}
		}
	}
	
	i = encoder_get_last_byte(&enc);
	if(i != ENCODER_NEED_INPUT){
		uint8_t tmp = i;
		buffer[len++] = tmp;
		my_mq_send(mq_out, buffer, len);
	}
	
	return NULL;
}

