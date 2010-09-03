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

cyg_mutex_t mutex;

reconos_res_t thread_resources[2] =
        {
                {&mutex, CYG_MUTEX_T},
        };

int main( int argc, char *argv[] )
{
	int i;
	HAL_DCACHE_ENABLE();

	printf("begin mutex_test_ecos\n");

	cyg_mutex_init(&mutex);
	cyg_mutex_lock(&mutex);

	printf("creating hw thread... ");
	
	cyg_thread_resume(ECOS_HWT_CREATE(0,0,thread_resources));
	printf("ok\n");
	
	for(i = 0; i < 10; i++){
		unsigned long ticks = cyg_current_time();
		//printf("current time = %ld ticks\n",ticks); // XXX remove
		cyg_mutex_unlock(&mutex);
		while(cyg_current_time() - ticks < 10); // wait for 0.1 seconds
		cyg_mutex_lock(&mutex);
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
	
	printf("mutex_test_ecos done.\n");
	
	return 0;
}

