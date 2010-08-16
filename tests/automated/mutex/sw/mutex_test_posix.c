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
#include <semaphore.h>
#include <sys/stat.h>   // for mode constants
#include <fcntl.h>
#include <cyg/infra/diag.h>
#include <xcache_l.h>
#include "common.h"

// mutex
pthread_mutex_t mutex;

// thread resources
reconos_res_t thread_resources[1] =
        {
                {&mutex, PTHREAD_MUTEX_T},
        };

int main( int argc, char *argv[] )
{
	int i;
	XCache_EnableDCache(0xF0000000);
	
	printf("begin mutex_test_posix\n");

	
	// initialize mutex with default attributes
	pthread_mutex_init(&mutex, NULL);
	pthread_mutex_lock(&mutex);
	
	printf("creating hw thread... ");
	POSIX_HWT_CREATE(0,0,thread_resources);
	
	printf("ok\n");
	cyg_thread_delay(50);

	for(i = 0; i < 10; i++){
		unsigned long ticks = cyg_current_time();
		//printf("current time = %ld ticks\n",ticks); // XXX remove
		pthread_mutex_unlock(&mutex);
		while(cyg_current_time() - ticks < 10); // wait for 0.1 seconds
		pthread_mutex_lock(&mutex);
		ticks = cyg_current_time() - ticks;
		//printf("delta t = %ld ticks\n", ticks); // XXX remove
		
		printf("mutex lock and release by hwthread: ");
		if(ticks > 20 && ticks < 40){
			printf("success\n");
		}
		else if(ticks <= 20){
			printf("too early\n"); // should not happen
		}
		else {
			printf("too late\n"); // should not happen
		}
		cyg_thread_delay(50);
	}
	
	printf("mutex_test_posix done.\n");
	
	return 0;
}

