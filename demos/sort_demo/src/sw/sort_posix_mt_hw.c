///
/// \file sort_ecos_mt_hw.c
/// Sorting application. eCos/POSIX-based, multi-threaded, hardware-accelerated
/// version.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       17.04.2008
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
#include <pthread.h>
#include <mqueue.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <limits.h>
#include <unistd.h>
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

mqd_t mb_start, mb_done;
struct mq_attr mb_start_attr, mb_done_attr;

// software threads
pthread_t thread_sorter[MT_SW_NUM_THREADS];
pthread_attr_t thread_sorter_attr[MT_SW_NUM_THREADS];

// hardware thread
pthread_t hwthread_sorter;
pthread_attr_t hwthread_sorter_attr;
rthread_attr_t hwthread_sorter_hwattr;
char hwthread_sorter_stack[STACK_SIZE];
reconos_res_t hwthread_sorter_resources[2] =
    { {&mb_start, PTHREAD_MQD_T},
{&mb_done, PTHREAD_MQD_T}
};

int main( int argc, char *argv[] )
{

    unsigned int i, start_count = 0, done_count = 0;
    timing_t t_start = 0, t_stop = 0, t_gen = 0, t_sort = 0, t_merge =
        0, t_check = 0;
    unsigned int *addr;
    unsigned int dummy;
    int retval;

    printf( "-------------------------------------------------------\n"
            "ReconOS hardware multithreading case study (sort)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            "eCos/POSIX, multi-threaded hardware version (" __FILE__ ")\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
    //XCache_EnableDCache( 0x80000000 );
	HAL_DCACHE_ENABLE();
#else
    printf( "data cache disabled\n" );
    //XCache_DisableDCache(  );
	HAL_DCACHE_DISABLE();
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
    //XCache_EnableDCache( 0x80000000 );
	HAL_DCACHE_ENABLE();
    printf( "done\n" );
#endif

    //----------------------------------
    //-- SORT DATA
    //----------------------------------
    // create mail boxes for 'start' and 'complete' messages
    mb_start_attr.mq_flags   = mb_done_attr.mq_flags   = 0;
    mb_start_attr.mq_maxmsg  = mb_done_attr.mq_maxmsg  = 10;
    mb_start_attr.mq_msgsize = mb_done_attr.mq_msgsize = 4;
    mb_start_attr.mq_curmsgs = mb_done_attr.mq_curmsgs = 0;

    // unlink mailboxes, if they exist
    retval = mq_unlink("/mb_start");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        diag_printf("unable to unlink mb_start");
    }
    retval = mq_unlink("/mb_done");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        diag_printf("unable to unlink mb_done");
    }

    // open/create mailboxes
    mb_start = mq_open("/mb_start",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mb_start_attr);
    if (mb_start == (mqd_t)-1) {
        diag_printf("unable to create mb_start");
    }
    mb_done = mq_open("/mb_done",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mb_done_attr);
    if (mb_done == (mqd_t)-1) {
        diag_printf("unable to create mb_done");
    }

    // create sorting sowftware threads
    for ( i = 0; i < MT_HW_NUM_SW_THREADS; i++ ) {
        pthread_attr_init(&thread_sorter_attr[i]);
        pthread_create(&thread_sorter[i],
                &thread_sorter_attr[i],
                sort8k_entry_posix, (void*)i);
    }

    // create sorting hardware thread
    pthread_attr_init(&hwthread_sorter_attr);
    pthread_attr_setstacksize(&hwthread_sorter_attr, STACK_SIZE);
    rthread_attr_init(&hwthread_sorter_hwattr);
    rthread_attr_setslotnum(&hwthread_sorter_hwattr, 0);
    rthread_attr_setresources(&hwthread_sorter_hwattr, hwthread_sorter_resources, 2);
    rthread_create(&hwthread_sorter, &hwthread_sorter_attr, &hwthread_sorter_hwattr, (void*)0);

    printf( "Sorting data..." );
    i = 0;

    t_start = gettime(  );

    // put 9 messages into mb_start
    while ( start_count < 9 ) {
        addr = &data[i];
        if ( mq_send( mb_start, ( void * ) &addr, sizeof(addr), 0 ) == 0 ) {
            start_count++;
            i += N;
        } else {                                                          
            perror("while sending to mq_send");
            break;
        }
    }

    t_stop = gettime(  );
    t_sort += calc_timediff_ms( t_start, t_stop );

    while ( done_count < SIZE / N ) {
        t_start = gettime(  );
        // if we have something to distribute,
        // put one into the start mailbox
        if ( start_count < SIZE / N ) {
            addr = &data[i];
            if ( mq_send( mb_start, ( void * ) &addr, sizeof(addr), 0 ) == 0 ) {
                start_count++;
                i += N;
            } else {                                                          
                perror("while sending to mq_send");
                break;
            }
        }
        // see whether anybody's done
        if ( mq_receive( mb_done, (void*)&dummy, sizeof(dummy), 0 ) == sizeof(dummy) ) {
            done_count++;
        } else {
            perror( "while receiving from mq_done" );
            break;
        }
        t_stop = gettime(  );
        t_sort += calc_timediff_ms( t_start, t_stop );
    }
    printf( "done\n" );

#ifdef USE_CACHE
    // flush cache contents
    // TODO: invalidating would suffice
    printf( "Flushing cache..." );
    //XCache_EnableDCache( 0x80000000 );
	HAL_DCACHE_ENABLE();
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
