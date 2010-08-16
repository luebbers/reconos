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
#include <reconos/reconos.h>
#include "common.h"

// semaphores
sem_t sem_a, sem_b;

// thread resources
reconos_res_t thread_resources[2] =
        {
                {&sem_a, PTHREAD_SEM_T},
                {&sem_b, PTHREAD_SEM_T}
        };

int main( int argc, char *argv[] )
{
	int retval, i = 1, k;

	printf("begin semaphore_test_posix\n");

	// do not share semaphores, initial value = 0
	sem_init(&sem_a, 0, 0);
	sem_init(&sem_b, 0, 0);

	printf("creating hw thread... ");
	
	POSIX_HWT_CREATE(0, 0, thread_resources);
	printf("ok\n");
	
	// loop 10 times
	for (k = 0; k < 10; k++) {
		retval = sem_post(&sem_a);
		printf("post semaphore A (retval = %d)\n",retval);

		printf("wait for semaphore B\n");
		retval = sem_wait(&sem_b);
		printf("semaphore B aquired (retval = %d)\n", retval);
		i++;
	}

	printf("semaphore_test_posix done.\n");
	
	return 0;
}

