///
/// \file sort_ecos_mt_hw.c
/// Sorting application. eCos-based, multi-threaded, hardware-accelerated
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
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "config.h"
#include "sort8k.h"
#include "merge.h"
#include "data.h"
#include "timing.h"


#define printf diag_printf

unsigned int buf_a[SIZE] __attribute__ ( ( aligned( 32 ) ) );   // align sort buffers to cache lines
unsigned int buf_b[SIZE];       // buffer for merging
unsigned int *data;

cyg_mbox mb_start, mb_done;
cyg_handle_t mb_start_handle, mb_done_handle;

// software threads
cyg_thread thread_sorter[MT_SW_NUM_THREADS];
cyg_handle_t thread_sorter_handle[MT_SW_NUM_THREADS];
char thread_sorter_stack[MT_SW_NUM_THREADS][STACK_SIZE];

// hardware thread
reconos_hwthread hwthread_sorter;
cyg_handle_t hwthread_sorter_handle;
char hwthread_sorter_stack[STACK_SIZE];
reconos_res_t hwthread_sorter_resources[2] =
    { {&mb_start_handle, CYG_MBOX_HANDLE_T},
{&mb_done_handle, CYG_MBOX_HANDLE_T}
};

int main( int argc, char *argv[] )
{

    unsigned int i, start_count = 0, done_count = 0;
    timing_t t_start = 0, t_stop = 0, t_gen = 0, t_sort = 0, t_merge =
        0, t_check = 0, t_tmp;

    printf( "-------------------------------------------------------\n"
            "ReconOS hardware multithreading case study (sort)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            "eCos, multi-threaded hardware version (" __FILE__ ")\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
    XCache_EnableDCache( 0x80000000 );
#else
    printf( "data cache disabled\n" );
    XCache_DisableDCache(  );
#endif

    data = buf_a;

    //----------------------------------
    //-- GENERATE DATA
    //----------------------------------
    printf( "Generating data..." );
    t_start = gettime(  );
    generate_data( data, SIZE );
    t_stop = gettime(  );
    t_gen = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

#ifdef USE_CACHE
    // flush cache contents - the hardware can only read from main memory
    // TODO: storing could be more efficient
    printf( "Flushing cache..." );
    XCache_EnableDCache( 0x80000000 );
    printf( "done\n" );
#endif

    //----------------------------------
    //-- SORT DATA
    //----------------------------------
    // create mail boxes for 'start' and 'complete' messages
    cyg_mbox_create( &mb_start_handle, &mb_start );
    cyg_mbox_create( &mb_done_handle, &mb_done );

    // create sorting sowftware threads
    for ( i = 0; i < MT_HW_NUM_SW_THREADS; i++ ) {
        cyg_thread_create( 16,                                                 // priority
                           sort8k_entry,                                       // entry point
                           ( cyg_addrword_t ) i,                               // entry data
                           "MT_SW_SORT",                                       // thread name
                           thread_sorter_stack[i],                             // stack
                           STACK_SIZE,                                         // stack size
                           &thread_sorter_handle[i],                           // thread handle
                           &thread_sorter[i]                                   // thread object
             );
        cyg_thread_resume( thread_sorter_handle[i] );
    }

    // create sorting hardware thread
    reconos_hwthread_create( 16,                                               // priority
                             0,                                                // entry data (not needed)
                             "MT_HW_SORT",                                     // thread name
                             hwthread_sorter_stack,                            // stack
                             STACK_SIZE,                                       // stack size
                             &hwthread_sorter_handle,                          // thread handle
                             &hwthread_sorter,                                 // thread object
                             0,
                             XPAR_OPB_INTC_0_OSIF_0_INTERRUPT_INTR+1,
        //                     ( void * ) XPAR_PLB_RECONOS_SLOT_0_BASEADDR,      // base address
        //                     XPAR_OPB_INTC_0_PLB_RECONOS_SLOT_0_INTERRUPT_INTR + 1,     // interrupt
                             hwthread_sorter_resources,                        // resource array
                             2,                                                 // number of resources
                             0xFFFFFFFF, 0xFFFFFFFF
         );
    cyg_thread_resume( hwthread_sorter_handle );

    printf( "Sorting data..." );
    i = 0;
    while ( done_count < SIZE / N ) {
        t_start = gettime(  );
        // if we have something to distribute,
        // put as many as possile into the start mailbox
        while ( start_count < SIZE / N ) {
            if ( cyg_mbox_tryput( mb_start_handle, ( void * ) &data[i] ) ==
                 true ) {
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
        } else {
            printf( "cyg_mbox_get returned NULL!\n" );
        }
        t_stop = gettime(  );
        t_sort += calc_timediff_ms( t_start, t_stop );
    }
    printf( "done\n" );


#ifdef USE_CACHE
    // flush cache contents
    // TODO: invalidating would suffice
    printf( "Flushing cache..." );
    XCache_EnableDCache( 0x80000000 );
    printf( "done\n" );
#endif


    //----------------------------------
    //-- MERGE DATA
    //----------------------------------
    printf( "Merging data..." );
    t_start = gettime(  );
    data = recursive_merge( data, buf_b, SIZE, N, simple_merge );
    t_stop = gettime(  );
    t_merge = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

    //----------------------------------
    //-- CHECK DATA
    //----------------------------------
    printf( "Checking sorted data..." );
    t_start = gettime(  );
    if ( check_data( data, SIZE ) != 0 )
        printf( "CHECK FAILED!\n" );
    else
        printf( "check successful.\n" );
    t_stop = gettime(  );
    t_check = calc_timediff_ms( t_start, t_stop );

    printf( "\nRunning times (size: %d words):\n"
            "\tGenerate data: %d ms\n"
            "\tSort data    : %d ms\n"
            "\tMerge data   : %d ms\n"
            "\tCheck data   : %d ms\n"
            "\nTotal computation time (sort & merge): %d ms\n",
            SIZE, t_gen, t_sort, t_merge, t_check, t_sort + t_merge );


    return 0;

}
