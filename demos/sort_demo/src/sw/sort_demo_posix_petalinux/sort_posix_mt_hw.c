///
/// \file sort_posix_mt_hw.c
/// Sorting application. POSIX-based, multi-threaded, hardware-accelerated
/// version.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       21.03.2008
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2008.
//

/*#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>*/
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <reconos.h>
#include <resources.h>
#include <pthread.h>
#include <mqueue.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <limits.h>
#include <unistd.h>
#include "config.h"
#include "sort8k.h"
#include "merge.h"
#include "data.h"
#include "timing.h"
#include <unistd.h>     // for nice()
#include <sys/resource.h> // for getpriority()
#include <errno.h>

#define NICE -19

/*unsigned int buf_a[SIZE] __attribute__ ( ( aligned( 32 ) ) );   // align sort buffers to cache lines
unsigned int buf_b[SIZE];       // buffer for merging*/
unsigned int *buf_a;
unsigned int *buf_b;
unsigned int *data;

mqd_t mb_start, mb_done, mb_starthw, mb_donehw;
struct mq_attr mb_start_attr, mb_done_attr, mb_starthw_attr, mb_donehw_attr;

// software threads
pthread_t thread_sorter[MT_SW_NUM_THREADS];
pthread_attr_t thread_sorter_attr[MT_SW_NUM_THREADS];
pthread_t thread_transfer;
pthread_attr_t thread_transfer_attr;

// hardware thread
rthread_t hwthread_sorter;
rthread_attr_t hwthread_sorter_attr;
reconos_res_t hwthread_sorter_resources[2] =
    { {&mb_starthw, PTHREAD_MQD_T},
{&mb_donehw, PTHREAD_MQD_T}
};


#define printf(fmt, args...) fprintf(stderr, fmt, ##args)

//
// transfer thread
//
void *transfer_entry_posix( void *data ) {

    volatile unsigned int *src;
    volatile unsigned int *hwbuf = (unsigned int *)0x30000000;  // urgs, hardcoded? FIXME
    volatile unsigned int *x, *y;
    unsigned int dummy;
    int retval, i;
    static int j = 0;

    while (1) {

        // wait for mb_start
        retval = mq_receive( mb_start, (void*)&src, sizeof(src), NULL );
        if (retval != sizeof(src)) {
            perror("unable to receive mb_start");
        }

//        fprintf(stderr, "#");

        // copy data
        x = src;
        y = hwbuf;
        for (i = 0; i < N; i++) {
            *y++ = *x++;
        }

        // send mb_starthw
        retval = mq_send( mb_starthw, (void*)&hwbuf, sizeof(hwbuf), 0 );
        if (retval != 0) {
            perror("unable to send mb_starthw");
        }

        // wait for mb_donehw
        retval = mq_receive( mb_donehw, (void*)&dummy, sizeof(dummy), NULL );
        if (retval != sizeof(dummy)) {
            perror("unable to receive mb_donehw");
        }

        // copy data
        x = hwbuf;
        y = src;
        for (i = 0; i < N; i++) {
            *y++ = *x++;
        }

        // send mb_done
        retval = mq_send( mb_done, (void*)&dummy, sizeof(dummy), 0 );
        if (retval != 0) {
            perror("unable to send mb_done");
        }

    }

}




int main( int argc, char *argv[] )
{

    unsigned int i, start_count = 0, done_count = 0, dummy;
    timing_t t_start = 0, t_stop = 0, t_gen = 0, t_sort = 0, t_merge =
        0, t_check = 0;
    unsigned int *addr;
    int retval;

    struct sched_param sp = { .sched_priority = 10 };
    struct sched_param sp_hi = { .sched_priority = 20 };

    printf( "-------------------------------------------------------\n"
            "ReconOS hardware multithreading case study (sort)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            "Linux, multi-threaded hardware version (" __FILE__ ")\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

    // set priority
    if (nice(NICE) == 0) {
        printf("# nice: %d, current priority: %d\n",
                NICE, getpriority(PRIO_PROCESS, 0));
    } else {
        perror("could not nice process");
    }

    init_timebase();


    buf_a = malloc(SIZE*sizeof(unsigned int));
    buf_b = malloc(SIZE*sizeof(unsigned int));
    
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

    //----------------------------------
    //-- SORT DATA
    //----------------------------------
    // create mail boxes for 'start' and 'complete' messages
    mb_start_attr.mq_flags   = mb_done_attr.mq_flags    = mb_starthw_attr.mq_flags   = mb_donehw_attr.mq_flags   = 0;
    mb_start_attr.mq_maxmsg  = mb_done_attr.mq_maxmsg   = mb_starthw_attr.mq_maxmsg  = mb_donehw_attr.mq_maxmsg  = 10;
    mb_start_attr.mq_msgsize = mb_done_attr.mq_msgsize  = mb_starthw_attr.mq_msgsize = mb_donehw_attr.mq_msgsize = 4;
    mb_start_attr.mq_curmsgs = mb_done_attr.mq_curmsgs  = mb_starthw_attr.mq_curmsgs = mb_donehw_attr.mq_curmsgs = 0;

    // unlink mailboxes, if they exist
    retval = mq_unlink("/mb_start");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mb_start");
    }
    retval = mq_unlink("/mb_done");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mb_done");
    }
    retval = mq_unlink("/mb_starthw");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mb_starthw");
    }
    retval = mq_unlink("/mb_donehw");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mb_donehw");
    }

    // open/create mailboxes
    mb_start = mq_open("/mb_start",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mb_start_attr);
    if (mb_start == (mqd_t)-1) {
        perror("unable to create mb_start");
    }
    mb_done = mq_open("/mb_done",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mb_done_attr);
    if (mb_done == (mqd_t)-1) {
        perror("unable to create mb_done");
    }
    mb_starthw = mq_open("/mb_starthw",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mb_starthw_attr);
    if (mb_starthw == (mqd_t)-1) {
        perror("unable to create mb_starthw");
    }
    mb_donehw = mq_open("/mb_donehw",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mb_donehw_attr);
    if (mb_donehw == (mqd_t)-1) {
        perror("unable to create mb_donehw");
    }

    // create sorting sowftware threads
    for ( i = 0; i < MT_HW_NUM_SW_THREADS; i++ ) {
        pthread_attr_init(&thread_sorter_attr[i]);
        pthread_create(&thread_sorter[i],
                &thread_sorter_attr[i],
                sort8k_entry_posix, (void*)i);
        pthread_setschedparam(thread_sorter[i], SCHED_RR, &sp);
    }

    // create HW sorter thread
    rthread_attr_init(&hwthread_sorter_attr);
    rthread_attr_setstacksize(&hwthread_sorter_attr, STACK_SIZE);
    rthread_attr_setresources(&hwthread_sorter_attr, hwthread_sorter_resources, 2);
    rthread_attr_setslotnum(&hwthread_sorter_attr, 0);
    rthread_create(&hwthread_sorter, &hwthread_sorter_attr, (void*)0);
    pthread_setschedparam(hwthread_sorter, SCHED_RR, &sp_hi);

    // create mem transfer thread
    pthread_attr_init(&thread_transfer_attr);
    pthread_create(&thread_transfer,
            &thread_transfer_attr,
            transfer_entry_posix, (void*)0);
    pthread_setschedparam(thread_transfer, SCHED_RR, &sp_hi);


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
        if ( mq_receive( mb_done, &dummy, sizeof(dummy), 0 ) == sizeof(dummy) ) {
            done_count++;
        } else {
            perror( "while receiving from mq_done" );
            break;
        }
        t_stop = gettime(  );
        t_sort += calc_timediff_ms( t_start, t_stop );
    }
    printf( "done\n" );


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
