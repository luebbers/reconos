///
/// \file pr_demo.c
///
/// Demonstration application for partial reconfiguration
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       27.01.2009
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//
// Major Changes:
//
// 27.01.2009   Enno Luebbers   File created.

#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include <cyg/hal/icap.h>
#include "timing.h"


#include <prm0_add_routed_partial.bit.h>
#include <prm0_sub_routed_partial.bit.h>
#include <prm1_add_routed_partial.bit.h>
#include <prm1_sub_routed_partial.bit.h>

//#include <network.h>


#define printf diag_printf
#define STACK_SIZE 8192
#define NUM_ADD_THREADS 4
#define NUM_SUB_THREADS 4

//#define USE_CACHE     // FIXME: Caching doesn't work...

volatile int counter[2] __attribute__ ( ( aligned( 32 ) ) );

// hardware threads
cyg_thread add_thread[NUM_ADD_THREADS], sub_thread[NUM_SUB_THREADS];
rthread_attr_t add_attr[NUM_ADD_THREADS], sub_attr[NUM_SUB_THREADS];
cyg_handle_t add_handle[NUM_ADD_THREADS], sub_handle[NUM_SUB_THREADS];
char add_stack[NUM_ADD_THREADS][STACK_SIZE] __attribute__ ( ( aligned( 32 ) ) );
char sub_stack[NUM_SUB_THREADS][STACK_SIZE] __attribute__ ( ( aligned( 32 ) ) );

// bitstreams and circuits
// add
reconos_bitstream_t add_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_add_routed_partial_bit,
    .size     = PRM0_ADD_ROUTED_PARTIAL_BIT_SIZE
};
reconos_bitstream_t add_bitstream_1 = {
    .slot_num = 1,
    .data     = prm1_add_routed_partial_bit,
    .size     = PRM1_ADD_ROUTED_PARTIAL_BIT_SIZE
};
reconos_circuit_t add_circuit = {
    .name     = "ADD",
    .bitstreams = {&add_bitstream_0, &add_bitstream_1},
    .num_bitstreams = 2,
	.signature = 0xABCDEF00
};

// sub
reconos_bitstream_t sub_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_sub_routed_partial_bit,
    .size     = PRM0_SUB_ROUTED_PARTIAL_BIT_SIZE
};
reconos_bitstream_t sub_bitstream_1 = {
    .slot_num = 1,
    .data     = prm1_sub_routed_partial_bit,
    .size     = PRM1_SUB_ROUTED_PARTIAL_BIT_SIZE
};
reconos_circuit_t sub_circuit = {
    .name     = "SUB",
    .bitstreams = {&sub_bitstream_0, &sub_bitstream_1}, 
    .num_bitstreams = 2,
	.signature = 0x12345678
};



void delay_countdown(unsigned int secs) {
    int i;

    for (i = 0; i < secs; i++) {
        diag_printf("\r%3d...", secs-i);
        cyg_thread_delay(100);  // sleep for 1 second
    }
    diag_printf("\n");
}



int main( int argc, char *argv[] )
{

    unsigned int i = 0;//, start_count = 0, done_count = 0;
    int old_counter_add = counter[0];
    int old_counter_sub = counter[1];
/*    timing_t t_start = 0, t_stop = 0, t_gen = 0, t_sort = 0, t_merge =
        0, t_check = 0, t_tmp;*/

    printf( "-------------------------------------------------------\n"
            "ReconOS partial reconfiguration case study (pr_demo)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            __FILE__ ", compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
    XCache_EnableDCache( 0x80000000 );
#else
    printf( "data cache disabled\n" );
    XCache_DisableDCache(  );
#endif


    printf( "initializing ICAP interface..." );
    icap_init();
    printf( "done\n" );
/*
    printf( "initializing slots..." );
    reconos_init_slots();
    printf( "done\n" );
*/

    printf("sub bitstream at %08X\nadd bitstream at %08X\n",
            (unsigned int)prm0_sub_routed_partial_bit, (unsigned int)prm0_add_routed_partial_bit);

#ifdef USE_CACHE
    // flush cache contents
    printf( "Flushing cache..." );
    XCache_FlushDCacheLine( (unsigned int)counter );
    printf( "done\n" );
#endif

    //----------------------------------
    //-- MAIN LOOP
    //----------------------------------
    while (1) {

        for (i = 0; i < NUM_ADD_THREADS; i++) {
            // create hardware thread
            rthread_attr_init(&add_attr[i]);
    //        rthread_attr_setslotnum(&add_attr, 0);  // this fixes the hardware thread to slot 0
            rthread_attr_setcircuit(&add_attr[i], &add_circuit);
            reconos_hwthread_create( 15,                                               // priority
                                     &add_attr[i],                                        // hardware thread attributes
                                     (cyg_addrword_t)&counter[0],                      // entry data (address of counter)
                                     "ADD",                                            // thread name
                                     add_stack[i],                                        // stack
                                     STACK_SIZE,                                       // stack size
                                     &add_handle[i],                                      // thread handle
                                     &add_thread[i]                                       // thread object
                 );

            // run hardware thread
            cyg_thread_resume( add_handle[i] );
        }

        for (i = 0; i < NUM_SUB_THREADS; i++) {
            // create hardware thread
            rthread_attr_init(&sub_attr[i]);
    //        rthread_attr_setslotnum(&sub_attr, 0);  // this fixes the hardware thread to slot 0
            rthread_attr_setcircuit(&sub_attr[i], &sub_circuit);
            reconos_hwthread_create( 15,                                               // priority
                                     &sub_attr[i],                                        // hardware thread attributes
                                     (cyg_addrword_t)&counter[1],                      // entry data (address of counter)
                                     "SUB",                                            // thread name
                                     sub_stack[i],                                        // stack
                                     STACK_SIZE,                                       // stack size
                                     &sub_handle[i],                                      // thread handle
                                     &sub_thread[i]                                       // thread object
                 );

            // run hardware thread
            cyg_thread_resume( sub_handle[i] );
        }

        delay_countdown(5); // sleep for 5 seconds
        for (i = 0; i < NUM_ADD_THREADS; i++) {
            cyg_thread_delete(add_handle[i]);
        }
        for (i = 0; i < NUM_SUB_THREADS; i++) {
            cyg_thread_delete(sub_handle[i]);
        }

#ifdef USE_CACHE
    // flush cache contents
    printf( "Invalidating cache..." );
    XCache_InvalidateDCacheLine( (unsigned int)counter );
    printf( "done\n" );
#endif
        
        printf("Counter values are: %d, %d\n", counter[0], counter[1]);
        if (old_counter_add == counter[0]) {
            printf("=> add thread has not executed.\n");
        } else {
            printf("=> add thread has executed %d times.\n", counter[0] - old_counter_add);
        }
        old_counter_add = counter[0];
        if (old_counter_sub == counter[1]) {
            printf("=> sub thread has not executed.\n");
        } else {
            printf("=> sub thread has executed %d times.\n", old_counter_sub - counter[1]);
        }
        old_counter_sub = counter[1];

        delay_countdown(5); // sleep for 10 seconds
        i++;
    }


    /*    t_start = gettime(  );
        t_stop = gettime(  );
        t_check = calc_timediff_ms( t_start, t_stop );

        printf( "\nRunning times (size: %d words):\n"
                "\tGenerate data: %d ms\n"
                "\tSort data    : %d ms\n"
                "\tMerge data   : %d ms\n"
                "\tCheck data   : %d ms\n"
                "\nTotal computation time (sort & merge): %d ms\n",
                SIZE, t_gen, t_sort, t_merge, t_check, t_sort + t_merge );
    */

    return 0;

}
