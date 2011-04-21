///
/// \file sort_ecos_st_hw.c
/// Sorting application. eCos-based, single-threaded, hardware-accelerated
/// version.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
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
#include <time.h>
//#include <xcache_l.h>
#include <cyg/hal/hal_cache.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "config.h"
#include "merge.h"
#include "data.h"
#include "timing.h"
#include <cyg/hal/icap.h>

#define printf diag_printf

#include <config_1_hw_task_0_black_box_partial.bit.h>
#include <config_2_hw_task_0_sort8k_partial.bit.h>
#include <config_3_hw_task_0_sort8kinv_partial.bit.h>

// bitstreams and circuits
// sort8k
reconos_bitstream_t sort8k_bitstream_0 = {
    .slot_num = 0,
    .data     = config_2_hw_task_0_sort8k_partial_bit,
    .size     = CONFIG_2_HW_TASK_0_SORT8K_PARTIAL_BIT_SIZE,
    .filename = "config_2_hw_task_0_sort8k_partial.bit"
};
reconos_circuit_t sort8k_circuit = {
    .name     = "Sort8k",
    .bitstreams = {&sort8k_bitstream_0},
    .num_bitstreams = 1,
    .signature = 0x11111111
};

// sort8kinv
reconos_bitstream_t sort8kinv_bitstream_0 = {
    .slot_num = 0,
    .data     = config_3_hw_task_0_sort8kinv_partial_bit,
    .size     = CONFIG_3_HW_TASK_0_SORT8KINV_PARTIAL_BIT_SIZE,
    .filename = "config_3_hw_task_0_sort8kinv_partial.bit"
};
reconos_circuit_t sort8kinv_circuit = {
    .name     = "Sort8kinv",
    .bitstreams = {&sort8kinv_bitstream_0}, 
    .num_bitstreams = 1,
    .signature = 0x22222222
};


unsigned int buf_a[SIZE] __attribute__ ( ( aligned( 32 ) ) );   // align sort buffers to cache lines
unsigned int buf_b[SIZE];       // buffer for merging
unsigned int *data;

cyg_mbox mb_start, mb_done;
cyg_handle_t mb_start_handle, mb_done_handle;

cyg_thread hwthread_sorter;
rthread_attr_t hwthread_sorter_attr;
cyg_handle_t hwthread_sorter_handle;
char hwthread_sorter_stack[STACK_SIZE];
reconos_res_t hwthread_sorter_resources[2] =
	{ {&mb_start_handle, CYG_MBOX_HANDLE_T},
	{&mb_done_handle, CYG_MBOX_HANDLE_T}
};


cyg_mbox mb_start_inv, mb_done_inv;
cyg_handle_t mb_start_inv_handle, mb_done_inv_handle;

cyg_thread hwthread_sorter_inv;
rthread_attr_t hwthread_sorter_inv_attr;
cyg_handle_t hwthread_sorter_inv_handle;
char hwthread_sorter_inv_stack[STACK_SIZE];
reconos_res_t hwthread_sorter_inv_resources[2] =
	{ {&mb_start_inv_handle, CYG_MBOX_HANDLE_T},
	{&mb_done_inv_handle, CYG_MBOX_HANDLE_T}
};


void sort8k(int reverse, cyg_handle_t mb_start_handle, cyg_handle_t mb_done_handle)
{

    unsigned int i, start_count = 0, done_count = 0;
    timing_t t_start = 0, t_stop = 0, //t_gen = 0, 
           t_sort = 0, t_merge = 0, t_check = 0, t_tmp;
    
    //----------------------------------
    //-- GENERATE DATA
    //----------------------------------
    /*printf( "Generating data..." );
    t_start = gettime(  );
    //generate_data( data, SIZE );
    if (reverse==false)
         generate_data_dec( data, SIZE );
    else
         generate_data_inc( data, SIZE );
    t_stop = gettime(  );
    t_gen = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );
    */

    if (reverse==false)
    {
       if ( check_data( data, SIZE ) != 0 )
           printf( "CHECK FAILED!\n" );
       else
           printf( "check successful.\n" );
    } else 
    {
       if ( check_data_inv( data, SIZE ) != 0 )
           printf( "CHECK FAILED!\n" );
       else
           printf( "check successful.\n" );
    }

#ifdef USE_CACHE
    // flush cache contents - the hardware can only read from main memory
    // TODO: storing could be more efficient
    printf( "Flushing cache..." );
    //XCache_EnableDCache( 0x80000000 );
    HAL_DCACHE_FLUSH( data, SIZE );
    printf( "done\n" );
#endif

    printf( "Sorting data..." );
    if (reverse==true) 
        printf( "inverse..." );
    i = 0;
    while ( done_count < SIZE / N ) {
        t_start = gettime(  );
        // if we have something to distribute,
        // put as many as possile into the start mailbox
        while ( start_count < SIZE / N ) {
            if ( cyg_mbox_tryput( mb_start_handle, ( void * ) &data[i] ) == true ) {
                //printf ("-");
                start_count++;
                i += N;
            } else {                                                           // mailbox full
                break;
            }
        }
        t_stop = gettime(  );
        t_sort += calc_timediff_ms( t_start, t_stop );
        // see whether anybody's done
        t_start = gettime(  );
        if ( ( t_tmp = ( timing_t ) cyg_mbox_get( mb_done_handle ) ) != 0 ) {
            done_count++;
            //printf ("+");
        } else {
            printf( "cyg_mbox_get returned NULL!\n" );
        }
        t_stop = gettime(  );
        t_sort += calc_timediff_ms( t_start, t_stop );
    }
    printf( "done\n" );

#ifdef USE_CACHE
    // invalidate cache contents
    printf( "Invalidating cache..." );
    HAL_DCACHE_INVALIDATE_ALL();
    printf( "done\n" );
#endif


    //----------------------------------
    //-- MERGE DATA
    //----------------------------------
    printf( "Merging data..." );
    t_start = gettime(  );
    if (reverse==false)
         data = recursive_merge( data, buf_b, SIZE, N, simple_merge );
    else
         data = recursive_merge( data, buf_b, SIZE, N, simple_merge_inv );
    t_stop = gettime(  );
    t_merge = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

    //----------------------------------
    //-- CHECK DATA
    //----------------------------------
    printf( "Checking sorted data..." );
    t_start = gettime(  );
    if (reverse==false)
    {
       if ( check_data( data, SIZE ) != 0 )
           printf( "CHECK FAILED!\n" );
       else
           printf( "check successful.\n" );
    } else 
    {
       if ( check_data_inv( data, SIZE ) != 0 )
           printf( "CHECK FAILED!\n" );
       else
           printf( "check successful.\n" );
    }
    t_stop = gettime(  );
    t_check = calc_timediff_ms( t_start, t_stop );

    printf( "\nRunning times (size: %d words):\n"
            //"\tGenerate data: %d ms\n"
            "\tSort data    : %d ms\n"
            "\tMerge data   : %d ms\n"
            "\tCheck data   : %d ms\n"
            "\nTotal computation time (sort & merge): %d ms\n",
            SIZE, //t_gen, 
            t_sort, t_merge, t_check, t_sort + t_merge );

}


int main( int argc, char *argv[] )
{
    int i;

    printf( "-------------------------------------------------------\n"
            "ReconOS hardware multithreading case study (sort)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            "eCos, single-threaded hardware version (" __FILE__ ")\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
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

    data = buf_a;

    printf( "initializing ICAP interface..." );
    icap_init();
    printf( "done\n" );

    //----------------------------------
    //-- SORT DATA
    //----------------------------------
    // create mail boxes for 'start' and 'complete' messages
    cyg_mbox_create( &mb_start_handle, &mb_start );
    cyg_mbox_create( &mb_done_handle, &mb_done );

    // create mail boxes for 'start' and 'complete' messages
    cyg_mbox_create( &mb_start_inv_handle, &mb_start_inv );
    cyg_mbox_create( &mb_done_inv_handle, &mb_done_inv );

    printf( "Generating data..." );
    generate_data_dec( data, SIZE );
    printf( "done\n" );

    i = 0;
    while (42){
            //----------------------------------
	    //-- SORT DATA 
	    //----------------------------------
	    // create sorting hardware thread
	    rthread_attr_init(&hwthread_sorter_attr);
	    //rthread_attr_setslotnum(&hwthread_sorter_attr, 0);
	    rthread_attr_setcircuit(&hwthread_sorter_attr, &sort8k_circuit);
	    rthread_attr_setresources(&hwthread_sorter_attr, hwthread_sorter_resources, 2);
	    reconos_hwthread_create( 16,                                               // priority
		                     &hwthread_sorter_attr,                             // hardware thread attributes
		                     0,                                                // entry data (not needed)
		                     "MT_HW_SORT",                                     // thread name
		                     hwthread_sorter_stack,                            // stack
		                     STACK_SIZE,                                       // stack size
		                     &hwthread_sorter_handle,                          // thread handle
		                     &hwthread_sorter                                  // thread object
		 );
	    cyg_thread_resume( hwthread_sorter_handle );

	    printf("\n########## Sort8k: %d. RUN ##############\n", i+1);
	    sort8k(false, mb_start_handle, mb_done_handle); 

	    // terminate thread
	    reconos_delegate_thread_destructor((cyg_addrword_t) &hwthread_sorter_attr);

	    //----------------------------------
	    //-- SORT DATA INV
	    //----------------------------------
	    // create sorting hardware thread
	    rthread_attr_init(&hwthread_sorter_inv_attr);
	    rthread_attr_setcircuit(&hwthread_sorter_inv_attr, &sort8kinv_circuit);
	    rthread_attr_setresources(&hwthread_sorter_inv_attr, hwthread_sorter_inv_resources, 2);
	    reconos_hwthread_create( 16,                                               // priority
		                     &hwthread_sorter_inv_attr,                        // hardware thread attributes
		                     0,                                                // entry data (not needed)
		                     "MT_HW_SORT_INV",                                 // thread name
		                     hwthread_sorter_inv_stack,                        // stack
		                     STACK_SIZE,                                       // stack size
		                     &hwthread_sorter_inv_handle,                      // thread handle
		                     &hwthread_sorter_inv                              // thread object
		 );
	    cyg_thread_resume( hwthread_sorter_inv_handle );

            // if I do not delay here: I get sorting errors (probably due to timing errors in first read burst) - 10 
            // in config.h (128*N) does not work. But (64*N) works fine. Maybe due to timing constraints. design has onl 93 MHz instead of 100 MHz
            cyg_thread_delay(10); //(8);

	    printf("\n########## Sort8kinv: %d. RUN ##############\n", i+1);
            sort8k(true, mb_start_inv_handle, mb_done_inv_handle); 

	    // terminate thread
	    reconos_delegate_thread_destructor((cyg_addrword_t) &hwthread_sorter_inv_attr);

	    i++;
    }

    return 0;

}
