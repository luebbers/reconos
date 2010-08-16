#include "tree.h"
#include "codebook.h"
#include "codebook_flat.h"
#include "decoder.h"
#include "decoder_flat.h"
#include "canonical.h"
#include "util.h"

#include "decoder_thread.h"

#include <mqueue.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

#include <sys/types.h>
#include <assert.h>

void * decoder_entry(void * data){
	mqd_t mq_in, mq_out;
	struct mq_attr attr_in, attr_out;
	uint8_t codelen[128];
	int count;
	struct DecoderArgs * args;
	unsigned char *input_buffer;
	unsigned char *output_buffer;
	int len, input_idx, output_idx;
	
	struct Tree tree;
	struct Codebook cb;
	struct CodebookFlat cb_flat;
	struct DecoderFlat dec_flat;

	args = data;
	
	mq_in = my_mq_open(args->mq_recv);
	mq_out = my_mq_open(args->mq_send);
	
	mq_getattr(mq_in, &attr_in);
	mq_getattr(mq_out, &attr_out);
	
	len = my_mq_receive(mq_in, &count);
	assert(len == 4);
	
	len = my_mq_receive(mq_in, codelen);
	assert(len == 128);
	
	ctree_create(&tree, codelen);
	codebook_create(&cb, &tree);
	codebook_flat_create(&cb_flat, &cb);
	decoder_flat_init(&dec_flat, &cb_flat);

	input_buffer = malloc(attr_in.mq_msgsize);
	output_buffer = malloc(attr_out.mq_msgsize);
	input_idx = attr_in.mq_msgsize;
	output_idx = 0;
	len = attr_in.mq_msgsize;
	while(1){
		int sym;
		if(input_idx == len){
			if(len < attr_in.mq_msgsize) break;
			len = my_mq_receive(mq_in, input_buffer);
			input_idx = 0;
		}
		
		uint8_t tmp = input_buffer[input_idx++];
		decoder_flat_put_byte(&dec_flat,tmp);
		while((sym = decoder_flat_get_symbol(&dec_flat)) != DECODER_NEED_INPUT){
			tmp = sym;
			output_buffer[output_idx++] = tmp;
			if(output_idx == attr_out.mq_msgsize){
				fprintf(stderr,"sending...\n");
				my_mq_send(mq_out, output_buffer, attr_out.mq_msgsize);
				fprintf(stderr,"ok!\n");
				output_idx = 0;
			}
		}
	}
	
	fprintf(stderr,"last byte\n");
	my_mq_send(mq_out, output_buffer, output_idx);
	
	return NULL;
}
