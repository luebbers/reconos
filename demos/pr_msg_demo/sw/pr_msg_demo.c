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
#include <cyg/hal/hal_cache.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include <cyg/hal/icap.h>
//#include "timing.h"


#include <config_1_hw_task_0_thread_1_partial.bit.h>
#include <config_2_hw_task_0_thread_2_partial.bit.h>
#include <config_3_hw_task_0_thread_3_partial.bit.h>
#include <config_4_hw_task_0_thread_4_partial.bit.h>
#include <config_1_hw_task_1_thread_1_partial.bit.h>
#include <config_2_hw_task_1_thread_2_partial.bit.h>
#include <config_3_hw_task_1_thread_3_partial.bit.h>
#include <config_4_hw_task_1_thread_4_partial.bit.h>

//#include <network.h>


#define printf diag_printf
#define STACK_SIZE 8192
#define NUM_THREADS 4
#define REPEATS 0

//#define USE_CACHE     // FIXME: Caching doesn't work...

volatile int counter[2] __attribute__ ( ( aligned( 32 ) ) );

// hardware threads
cyg_thread thread[NUM_THREADS];
rthread_attr_t attr[NUM_THREADS];
cyg_handle_t handle[NUM_THREADS];
char stack[NUM_THREADS][STACK_SIZE] __attribute__ ( ( aligned( 32 ) ) );

// mailboxes
cyg_mbox mb_pipe[NUM_THREADS+1], mb_notify[NUM_THREADS];
cyg_handle_t mb_pipe_handle[NUM_THREADS+1], mb_notify_handle[NUM_THREADS];

// resources
reconos_res_t resources[NUM_THREADS][3] = {
		{
				{&mb_pipe_handle[0], CYG_MBOX_HANDLE_T},        // MB_IN
				{&mb_pipe_handle[1], CYG_MBOX_HANDLE_T},        // MB_OUT
				{&mb_notify_handle[0], CYG_MBOX_HANDLE_T}       // MB_NOTIFY
		},
		{
				{&mb_pipe_handle[1], CYG_MBOX_HANDLE_T},        // MB_IN
				{&mb_pipe_handle[2], CYG_MBOX_HANDLE_T},        // MB_OUT
				{&mb_notify_handle[1], CYG_MBOX_HANDLE_T}       // MB_NOTIFY
		},
		{
				{&mb_pipe_handle[2], CYG_MBOX_HANDLE_T},        // MB_IN
				{&mb_pipe_handle[3], CYG_MBOX_HANDLE_T},        // MB_OUT
				{&mb_notify_handle[2], CYG_MBOX_HANDLE_T}       // MB_NOTIFY
		},
		{
				{&mb_pipe_handle[3], CYG_MBOX_HANDLE_T},        // MB_IN
				{&mb_pipe_handle[4], CYG_MBOX_HANDLE_T},        // MB_OUT
				{&mb_notify_handle[3], CYG_MBOX_HANDLE_T}       // MB_NOTIFY
		}
};


// bitstreams and circuits
reconos_bitstream_t slot_0_thread_1_bit = {
    .slot_num = 0,
    .data     = config_1_hw_task_0_thread_1_partial_bit,
    .size     = CONFIG_1_HW_TASK_0_THREAD_1_PARTIAL_BIT_SIZE,
    .filename = "config_1_hw_task_0_thread_1_partial_bit"
};
reconos_bitstream_t slot_0_thread_2_bit = {
    .slot_num = 0,
    .data     = config_2_hw_task_0_thread_2_partial_bit,
    .size     = CONFIG_2_HW_TASK_0_THREAD_2_PARTIAL_BIT_SIZE,
    .filename = "config_2_hw_task_0_thread_2_partial_bit"
};
reconos_bitstream_t slot_0_thread_3_bit = {
    .slot_num = 0,
    .data     = config_3_hw_task_0_thread_3_partial_bit,
    .size     = CONFIG_3_HW_TASK_0_THREAD_3_PARTIAL_BIT_SIZE,
    .filename = "config_3_hw_task_0_thread_3_partial_bit"
};
reconos_bitstream_t slot_0_thread_4_bit = {
    .slot_num = 0,
    .data     = config_4_hw_task_0_thread_4_partial_bit,
    .size     = CONFIG_4_HW_TASK_0_THREAD_4_PARTIAL_BIT_SIZE,
    .filename = "config_4_hw_task_0_thread_4_partial_bit"
};
reconos_bitstream_t slot_1_thread_1_bit = {
    .slot_num = 1,
    .data     = config_1_hw_task_1_thread_1_partial_bit,
    .size     = CONFIG_1_HW_TASK_1_THREAD_1_PARTIAL_BIT_SIZE,
    .filename = "config_1_hw_task_1_thread_1_partial_bit"
};
reconos_bitstream_t slot_1_thread_2_bit = {
    .slot_num = 1,
    .data     = config_2_hw_task_1_thread_2_partial_bit,
    .size     = CONFIG_2_HW_TASK_1_THREAD_2_PARTIAL_BIT_SIZE,
    .filename = "config_2_hw_task_1_thread_2_partial_bit"
};
reconos_bitstream_t slot_1_thread_3_bit = {
    .slot_num = 1,
    .data     = config_3_hw_task_1_thread_3_partial_bit,
    .size     = CONFIG_3_HW_TASK_1_THREAD_3_PARTIAL_BIT_SIZE,
    .filename = "config_3_hw_task_1_thread_3_partial_bit"
};
reconos_bitstream_t slot_1_thread_4_bit = {
    .slot_num = 1,
    .data     = config_4_hw_task_1_thread_4_partial_bit,
    .size     = CONFIG_4_HW_TASK_1_THREAD_4_PARTIAL_BIT_SIZE,
    .filename = "config_4_hw_task_1_thread_4_partial_bit"
};

reconos_circuit_t thread_1_circuit = {
    .name     = "THREAD_1",
    .bitstreams = {&slot_0_thread_1_bit, &slot_1_thread_1_bit},
    .num_bitstreams = 2,
    .signature = 0x40000000
};
reconos_circuit_t thread_2_circuit = {
    .name     = "THREAD_2",
    .bitstreams = {&slot_0_thread_2_bit, &slot_1_thread_2_bit},
    .num_bitstreams = 2,
    .signature = 0x20000000
};
reconos_circuit_t thread_3_circuit = {
    .name     = "THREAD_3",
    .bitstreams = {&slot_0_thread_3_bit, &slot_1_thread_3_bit},
    .num_bitstreams = 2,
    .signature = 0x10000000
};
reconos_circuit_t thread_4_circuit = {
    .name     = "THREAD_4",
    .bitstreams = {&slot_0_thread_4_bit, &slot_1_thread_4_bit},
    .num_bitstreams = 2,
    .signature = 0x08000000
};

// convenience array storing pointers to the circuits
// makes thread instantiation easier
reconos_circuit_t *thread_circuit[NUM_THREADS] = {
	&thread_1_circuit,
	&thread_2_circuit,
	&thread_3_circuit,
	&thread_4_circuit
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

    unsigned int i = 0;
    uint32 notifications[NUM_THREADS];
    uint32 result;
/*    timing_t t_start = 0, t_stop = 0, t_gen = 0, t_sort = 0, t_merge =
        0, t_check = 0, t_tmp;*/

    printf( "-------------------------------------------------------\n"
            "ReconOS partial reconfiguration case study (pr_msg_demo)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            __FILE__ ", compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
//    XCache_EnableDCache( 0x80000000 );
    HAL_DCACHE_ENABLE();
#else
    printf( "data cache disabled\n" );
//    XCache_DisableDCache(  );
    HAL_DCACHE_DISABLE();
#endif

    printf( "initializing ICAP interface..." );
    icap_init();
    printf( "done\n" );
/*
    printf( "initializing slots..." );
    reconos_init_slots();
    printf( "done\n" );
*/

    printf( "initializing mailboxes..." );
    for (i = 0; i < NUM_THREADS+1; i++) {
    	cyg_mbox_create( &mb_pipe_handle[i], &mb_pipe[i] );
    }
    for (i = 0; i < NUM_THREADS; i++) {
    	cyg_mbox_create( &mb_notify_handle[i], &mb_notify[i] );
    }
    printf( "done\n" );


    //----------------------------------
    //-- MAIN LOOP
    //----------------------------------
    while (1) {

        for (i = 0; i < NUM_THREADS; i++) {
            // create hardware thread
            rthread_attr_init(&attr[i]);
            rthread_attr_setcircuit(&attr[i], thread_circuit[i]);
            rthread_attr_setresources(&attr[i], resources[i], 3);
            reconos_hwthread_create( 15,                                              // priority
                                     &attr[i],                                        // hardware thread attributes
                                     (cyg_addrword_t) REPEATS,                        // entry data (number of repeats)
                                     thread_circuit[i]->name,                         // thread name
                                     stack[i],                                        // stack
                                     STACK_SIZE,                                      // stack size
                                     &handle[i],                                      // thread handle
                                     &thread[i]                                       // thread object
                 );

            // run hardware thread
            cyg_thread_resume( handle[i] );
        }

        // put data into first mailbox (this should kick thread_1 into action)
        cyg_mbox_put(mb_pipe_handle[0], (void*) 0);

        // wait for result in last mailbox and print it
        result = (uint32)cyg_mbox_get(mb_pipe_handle[NUM_THREADS]);
        // TODO: check result for correctness
        printf ( "received result: 0x%08X\n", result );

        // retrieve notification messages
        for (i = 0; i < NUM_THREADS; i++) {
        	notifications[i] = (uint32)cyg_mbox_get(mb_notify_handle[i]);
        	printf ("received message from thread %d: 0x%08X\n", i, notifications[i]);
                // subtract message from result
                result -= notifications[i];
        }
        
        if (result != 0) {
            printf( "\t\t\t\t\t-> Test FAILED (difference: 0x%08X)\n", result );
        } else {
            printf( "\t\t\t\t\t-> Test PASSED\n");
        }

        // wait for all HW threads (delegates) to exit
        // TODO: this should be replaced with code checking
        //       wether the threads are still running
        delay_countdown(10); // sleep for 10 seconds

        for (i = 0; i < NUM_THREADS; i++) {
                // delete thread structures
        	cyg_thread_delete( handle[i] );
        }

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
