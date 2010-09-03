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

#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <cyg/hal/hal_cache.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "common.h"

cyg_mutex_t mutex_a, mutex_b;
cyg_cond_t condvar_a, condvar_b;

cyg_thread swthread;
cyg_handle_t thread_handle2;
char thread_stack2[STACK_SIZE];

reconos_res_t thread_resources[] = {
	{&mutex_a, CYG_MUTEX_T},
	{&condvar_a, CYG_COND_T},
	{&mutex_b, CYG_MUTEX_T},
	{&condvar_b, CYG_COND_T}
};

void wait_on_condvar(cyg_addrword_t arg){
	while(1){
		cyg_mutex_lock(&mutex_b);
		cyg_cond_wait(&condvar_b);
		//printf("pthread_cond_wait(&condvar_b, &mutex_b) => 0x%X\n",err);
		printf("condition b\n");
		cyg_mutex_unlock(&mutex_b);
	}
}

int main( int argc, char *argv[] )
{
	int i;
	HAL_DCACHE_ENABLE();

	printf("begin condvar_test_ecos\n");

	cyg_mutex_init(&mutex_a);
	cyg_mutex_init(&mutex_b);
	cyg_cond_init(&condvar_a, &mutex_a);
	cyg_cond_init(&condvar_b, &mutex_b);
	
	// create software thread
	cyg_thread_create(10, wait_on_condvar, 0, "wait condvar", thread_stack2, STACK_SIZE, &thread_handle2, &swthread);
	cyg_thread_resume(thread_handle2);
	
	printf("creating hw thread... ");
	cyg_thread_resume(ECOS_HWT_CREATE(0,0,thread_resources));
	
	printf("ok\n");
	
	cyg_thread_delay(50); // give the other sw thread some time to run...
	
	for(i = 0; i < 10; i++){
		cyg_mutex_lock(&mutex_a);
		printf("signaling condition a\n");
		cyg_cond_signal(&condvar_a);
		cyg_mutex_unlock(&mutex_a);
		cyg_thread_delay(50);
	}
	
	printf("condvar_test_ecos done.\n");
	
	return 0;
}

