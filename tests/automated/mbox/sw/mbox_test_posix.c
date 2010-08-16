/*
 * dcr_test_posix.c: demonstrate message queues between POSIX threads
 *
 * (c) 2008 Enno Luebbers <enno.luebbers@upb.de>
 *
 * Thanks to mij@bitchx.it for his UNIX programming examples
 * (http://mij.oltrelinux.com/devel/unixprg/)
 */


#include <stdio.h>
#include <pthread.h>
#include <mqueue.h>
#include <sys/stat.h>   // for mode constants
#include <fcntl.h>
#include <cyg/infra/diag.h>
#include "common.h"

// message queues + attributes
mqd_t mbox0, mbox1;     // mbox0: main->thread, mbox1: thread->main
struct mq_attr mbox0_attr, mbox1_attr;

reconos_res_t thread_resources[2] =
        {
//                {&mbox0, PTHREAD_MQD_T},
//                {&mbox1, PTHREAD_MQD_T}
                {"/mbox0", PTHREAD_MQD_T},
                {"/mbox1", PTHREAD_MQD_T}
        };


int main(int argc, char*argv[]) {
	printf("begin mbox_test_posix\n");
	// i is the value that is put into the mailbox. do not use 0,
	// since this signifies an error.
	int retval = 0, i = 1, j = 0;
	int k;

	// set message queue attributes to non-blocking, 10 messages with 4 bytes each
	mbox0_attr.mq_flags = 0;
	mbox0_attr.mq_maxmsg = 10;
	mbox0_attr.mq_msgsize = 4;
	mbox0_attr.mq_curmsgs = 0;
	mbox1_attr.mq_flags = 0;
	mbox1_attr.mq_maxmsg = 10;
	mbox1_attr.mq_msgsize = 4;
	mbox1_attr.mq_curmsgs = 0;

	// create mailboxes
	mbox0 = mq_open("/mbox0", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mbox0_attr);
	if (mbox0 == (mqd_t)-1) {
		perror("unable to create mbox0");
	}
	mbox1 = mq_open("/mbox1", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mbox1_attr);
	if (mbox1 == (mqd_t)-1) {
		perror("unable to create mbox1");
	}

	// print attributes
	mq_getattr(mbox0, &mbox0_attr);
	mq_getattr(mbox1, &mbox1_attr);

	// create thread
	printf("creating hw thread... ");
	POSIX_HWT_CREATE(0,0,thread_resources);
	printf("ok\n");

	// loop 10 times
	for (k = 0; k < 10; k++) {
		// send a message to mbox0
		retval = mq_send( mbox0, (char*)&i, 4, 10);
		printf("sent: %d (retval %d)\n", i, retval);
		if (retval < 0) {
			perror("main(): error sending");
		}

		// receive a message from mbox1
		retval = mq_receive( mbox1, (char*)&j, 4, NULL);
		printf("recvd: %d (retval %d)\n", j, retval);
		if (retval < 0) {
			perror("main(): error receiving");
		}

		i++;
	}

	printf("mbox_test_posix done.\n");
	
	return 0;
}

