///
/// \file burstlen_test.c
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       27.06.2008
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
#include <xcache_l.h>
#include "common.h"

#ifndef MEMSIZE
#define MEMSIZE 1024
#endif

#ifndef BURSTLEN
#define BURSTLEN 16     // in 64-bit data beats
#endif

#ifndef STEP
#define STEP BURSTLEN*8
#endif

volatile int mem[MEMSIZE/2] __attribute__ ( ( aligned( 128 ) ) ); // align to maximum burst boundaries
int args[4];

int main( int argc, char *argv[] )
{
	int i, step;
	volatile int * src = mem;
	
	volatile int * dst = src + MEMSIZE/4;

	XCache_DisableDCache();
	
	args[0] = (int)src;         // source address
	args[1] = (int)dst;         // destination address
	args[2] = (int)MEMSIZE;     // size of src mem in bytes
        args[3] = (int)BURSTLEN;    // burst length to use (in DWORDS)
        args[4] = (int)STEP;        // offset between two bursts in bytes
	
	printf("begin burstlen_test_posix\n");
        
        // check parameters
        if (MEMSIZE % STEP != 0) {
            printf("error: MEMSIZE (%d) not divisible by STEP (%d).\n", MEMSIZE, STEP);
            return 1;
        }
        if (STEP < BURSTLEN*8) {
            printf("error: STEP (%d) smaller than BURSTLEN*8 (%d).\n", STEP, BURSTLEN*8);
            return 1;
        }
	
	for(i = 0; i < MEMSIZE/4; i++){
		src[i] = i + 1;
		dst[i] = 0;
	}

	// create hardware thread
	printf("creating hw thread... ");
        posix_hwt_create(0,(unsigned int)args,NULL,0);
	printf("ok\n");

	cyg_thread_delay(100);

        step = 0;
	for(i = 0; i < MEMSIZE/4; i++){
            if (step < BURSTLEN*2) {    // i and step count words, not bytes
		if(src[i] != dst[i]){
			printf("memcopy failed.\n");
			printf("error: destination[%d] = %d, should be %d\n",i,dst[i],src[i]);
			return 1;
		}
            } else {
                if (dst[i] != 0) {
                    printf("memcopy failed.\n");
                    printf("error: destination[%d] = %d, should be %d\n",i,dst[i],0);
                    return 1;
                }
            }
            step++;
            if (step >= STEP/4) {
                step = 0;
            }
/*
            printf("src[%d] = 0x%08X        dst[%d] = 0x%08X\n", 
                        i,      src[i],         i,      dst[i]);
i*/
	}

	printf("memcopy ok. (%d bytes copied correctly)\n", BURSTLEN*8 * (MEMSIZE/STEP));
	printf("burstlen_test_posix done.\n");
	
	return 0;
}

