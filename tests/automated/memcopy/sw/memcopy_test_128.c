///
/// \file dcr_test.c
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       13.11.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#include <stdio.h>
#include <pthread.h>
#include <mqueue.h>
#include <sys/stat.h>   // for mode constants
#include <fcntl.h>
#include <cyg/infra/diag.h>
#include <cyg/hal/hal_cache.h>
#include "common.h"

#define MEMSIZE 128

volatile int mem[MEMSIZE/2+16];
int args[3];

mqd_t mbox;     // mbox0: main->thread, mbox1: thread->main
struct mq_attr mbox_attr;

reconos_res_t thread_resources[] =
        {
                {&mbox, PTHREAD_MQD_T},
        };

int main( int argc, char *argv[] )
{
	int i;
	//int s, msg, retval;
	volatile int * src = (volatile int*)(((int)mem/16 + 1)*16 + 4); // align to 8 + 4 bytes
	volatile int * dst = src + MEMSIZE/4;
	
	HAL_DCACHE_DISABLE();
	
	args[0] = (int)src;
	args[1] = (int)dst;
	args[2] = (int)MEMSIZE;
	
	printf("begin memcopy_test_posix\n");
	/*
	printf("args = 0x%08X\n",(unsigned int)args);
	
	for(i = 0; i < 3; i++){
		printf("args[%d] = 0x%08X\n",i,args[i]);
	}
	*/
	for(i = 0; i < MEMSIZE/4; i++){
		src[i] = i + 1;
		dst[i] = 0;
	}
	/*
	// set message queue attributes to non-blocking, 10 messages with 4 bytes each
	mbox_attr.mq_flags = 0;
	mbox_attr.mq_maxmsg = 10000;
	mbox_attr.mq_msgsize = 4;
	mbox_attr.mq_curmsgs = 0;
	// create mailboxes
	mbox = mq_open("/mbox", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mbox_attr);
	if (mbox == (mqd_t)-1) {
		perror("unable to create mbox");
	}
	*/
	// create hardware thread
	printf("creating hw thread... ");
	POSIX_HWT_CREATE(0,(unsigned int)args,thread_resources);
	printf("ok\n");

	cyg_thread_delay(100);

	/*
	retval = mq_receive(mbox, (char*)&msg, 4, NULL);
	printf("init_data: 0x%08X (retval %d)\n", msg, retval);

	i = 0; s = (unsigned int)src;
	while(1){
		retval = mq_receive(mbox, (char*)&msg, 4, NULL);
		if(msg == 0x0112358D) break; 

		switch(i){
			case 0: printf("SRC"); break;
			case 1: printf("DST"); break;
			case 2: printf("SIZE"); break;
		}

		printf(": 0x%08X (retval %d)", msg, retval);
		if(i == 0){
			int d = (unsigned int)msg - s;
			if(d == 4) printf(" SINGLE");
			else if(d == 128) printf(" *** BURST ***");
			else printf(" chunk size = %u bytes", d);
			s = msg;
		}
		printf("\n");

		i = (i + 1) % 3;
	}
	
	for(i = 0; i < MEMSIZE/4; i++){
		printf("dst[0x%08X] = %d\n", i, dst[i]);
	}
	*/
	for(i = 0; i < MEMSIZE/4; i++){
		if(src[i] != dst[i]){
			printf("memcopy failed.\n");
			printf("error: destination[%d] = %d, should be %d\n",i,dst[i],src[i]);
			return 1;
		}
	}
	
	printf("memcopy ok. (%d bytes copied correctly)\n",MEMSIZE);
	
	printf("memcopy_test_posix done.\n");
	
	return 0;
}

