#include "carray_io.h"
#include "util.h"
#include <mqueue.h>
#include <stdlib.h>
#include <stdio.h>

void * carray_io(void * data) {
	struct CArrayIOArgs * args;
	struct mq_attr attr_in, attr_out;
	unsigned char *buffer;
	mqd_t mq_in, mq_out;
	int i, ok, len;
	
	args = data;
	mq_in = my_mq_open(args->mq_recv);
	mq_out = my_mq_open(args->mq_send);
	
	mq_getattr(mq_in, &attr_in);
	mq_getattr(mq_out, &attr_out);
	
	for(i = 0; i < args->len; i += attr_out.mq_msgsize){
		int l = args->len - i;
		
		if(l > attr_out.mq_msgsize) l = attr_out.mq_msgsize;
		my_mq_send(mq_out, args->data + i, l);
	}
	
	buffer = malloc(attr_in.mq_msgsize);
	i = 0;
	ok = 1;
	do{
		int j;
		len = my_mq_receive(mq_in, buffer);
		for(j = 0; j < len; j++){
			if(buffer[j] != args->data[i + j]){
				fprintf(stderr,"Data mismatch at byte %d: expected 0x%02X, received 0x%02X\n",
						i + j, args->data[i + j], buffer[j]);
				ok = 0;
			}
			//else { fprintf(stderr,"byte %d ok\n", i + j); }
		} 
		i += len;
		
	} while(len == attr_in.mq_msgsize);
	
	if(ok){
		fprintf(stderr, "processed %d bytes of input.\n", args->len);
	}
	
	return NULL;
}

