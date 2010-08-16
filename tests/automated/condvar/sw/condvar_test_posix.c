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

// conditional variables
pthread_mutex_t mutex_a, mutex_b;
pthread_cond_t condvar_a, condvar_b;

// additional software thread
pthread_t swthread;

// thread resources
reconos_res_t thread_resources[4] = {
		{&mutex_a, PTHREAD_MUTEX_T},
		{&condvar_a, PTHREAD_COND_T},
		{&mutex_b, PTHREAD_MUTEX_T},
		{&condvar_b, PTHREAD_COND_T}
};


void * wait_on_condvar(void * arg){
	while(1){
		pthread_mutex_lock(&mutex_b);
		pthread_cond_wait(&condvar_b, &mutex_b);
		//printf("pthread_cond_wait(&condvar_b, &mutex_b) => 0x%X\n",err);
		printf("condition b\n");
		pthread_mutex_unlock(&mutex_b);
	}
}

int main( int argc, char *argv[] )
{
	int i;
	XCache_EnableDCache(0xF0000000);
	
	printf("begin condvar_test_posix\n");
	
	
	// initialize mutexes with default attributes
	pthread_mutex_init(&mutex_a, NULL);
	pthread_mutex_init(&mutex_b, NULL);
	pthread_cond_init(&condvar_a, NULL);
	pthread_cond_init(&condvar_b, NULL);
	
	// create software thread
	pthread_create(&swthread,NULL,wait_on_condvar,NULL);
	
	
	// create hardware thread
	printf("creating hw thread... ");
	POSIX_HWT_CREATE(0,0,thread_resources);
	
	printf("ok\n");
	
	cyg_thread_delay(50); // give the second sw thread some time to run...
	
	for(i = 0; i < 10; i++){
		pthread_mutex_lock(&mutex_a);
		printf("signaling condition a\n");
		pthread_cond_signal(&condvar_a);
		pthread_mutex_unlock(&mutex_a);
		cyg_thread_delay(50);
	}
	
	
	printf("condvar_test_posix done.\n");
	
	return 0;
}

