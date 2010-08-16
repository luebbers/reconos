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
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "common.h"

cyg_sem_t sem_a, sem_b;

reconos_res_t thread_resources[2] =
        {
                {&sem_a, CYG_SEM_T},
                {&sem_b, CYG_SEM_T}
        };

int main( int argc, char *argv[] )
{
	int retval, i = 1, k;

	printf("begin semaphore_test_ecos\n");

	
	cyg_semaphore_init(&sem_a, 0);
	cyg_semaphore_init(&sem_b, 0);

	cyg_thread_resume(ECOS_HWT_CREATE(0,0xaffe1234,thread_resources));
	
	printf("ok\n");
	
	// loop 10 times
	for (k = 0; k < 10; k++) {
		printf("post semaphore A\n");
		cyg_semaphore_post(&sem_a);
		//cyg_thread_delay(100000);
		printf("wait for semaphore B\n");
		retval = cyg_semaphore_wait(&sem_b);
		printf("semaphore B aquired (retval = %d)\n", retval);
		i++;
	}

	printf("semaphore_test_ecos done.\n");
	
	return 0;
}

