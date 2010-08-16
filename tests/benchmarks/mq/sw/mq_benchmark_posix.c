///
/// \file mq_benchmark_posix.c
///
/// Benchmark for POSIX message queues used by hardware threads
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       24.11.2008
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//
// Major Changes:
//
// 24.11.2008   Enno Luebbers   File created.

#include <reconos/reconos.h>
#include <cyg/kernel/kapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <mqueue.h>
#include <sys/stat.h>           // for mode constants
#include <fcntl.h>
#include <cyg/infra/diag.h>
#include "xparameters.h"
#include <xcache_l.h>

#define MSG_SIZE_MAX (16*1024)
#define GET_TIME() XIo_DcrIn(XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1)
#define LOOPS 100   // average over this many iterations

// if you disable the cache, remember to unset UPBFUN_RECONOS_CACHE_BURST_RAM
// in the eCos configuration for better performance
#define USE_CACHE

// threads
pthread_t thread;
pthread_attr_t pattr;
rthread_attr_t rattr;

// message queues + attributes
struct mq_attr mbox0_attr, mbox1_attr;

// mail box for collecting times
cyg_mbox mbox_times;
cyg_handle_t mbox_times_handle;

reconos_res_t thread_resources[] = {
    {"/mbox0", PTHREAD_MQD_T},
    {"/mbox1", PTHREAD_MQD_T},
    {&mbox_times_handle, CYG_MBOX_HANDLE_T}
};

// HW->SW time
unsigned int times_hwsw[LOOPS];
// SW->HW time
unsigned int times_swhw[LOOPS];
// SW mq send time
unsigned int times_send_sw[LOOPS];
// HW mq send time
unsigned int times_send_hw[LOOPS];

unsigned int msg[MSG_SIZE_MAX / 4];
unsigned int buffer[MSG_SIZE_MAX / 4];

void randomize_msg(  )
{
    int i;
    for ( i = 0; i < MSG_SIZE_MAX / 4; i++ ) {
        msg[i] = rand(  );
    }
}

mqd_t create_mq( const char *name )
{
    mqd_t mq;
    struct mq_attr attr = {
        .mq_flags = 0,
        .mq_maxmsg = 10,
        .mq_msgsize = MSG_SIZE_MAX,
        .mq_curmsgs = 0
    };

    mq = mq_open( name, O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &attr );
    if ( mq == ( mqd_t ) - 1 ) {
        perror( "unable to create mq" );
        exit( 1 );
    }

    return mq;
}

// calculate difference between start and stop time
unsigned int calc_timediff( unsigned int start, unsigned int stop )
{

    if ( start <= stop ) {
        return ( stop - start );
    } else {
        return ( UINT_MAX - start + stop );
    }
}

// reads two timing values from a mailbox and returns the difference
unsigned int get_timediff_from_mbox( cyg_handle_t handle )
{

    unsigned int start, stop;

    start = ( unsigned int ) cyg_mbox_get( handle );
    stop = ( unsigned int ) cyg_mbox_get( handle );

    return calc_timediff( start, stop );
}

mqd_t mbox0, mbox1;

// calculate average of array
unsigned int avg( unsigned int *array, unsigned int loops ) {
    unsigned int i;
    unsigned int sum = 0;
    unsigned int oldsum;    // to detect overflows

    for (i = 0; i < LOOPS; i++) {
        oldsum = sum;
        sum += array[i];
        if (sum < oldsum) {
            printf("WARNING: overflow while calculating avg. stopping after %d iterations.\n", i);
            sum = oldsum;
            break;
        }
    }
    return sum / i;
}

// calculate max of array
unsigned int max( unsigned int *array, unsigned int loops ) {
    unsigned int i;
    unsigned int result = 0;

    for (i = 0; i < LOOPS; i++) {
        if (result < array[i]) {
            result = array[i];
        }
    }
    return result;
}

// calculate min of array
unsigned int min( unsigned int *array, unsigned int loops ) {
    unsigned int i;
    unsigned int result = (unsigned int)-1;

    for (i = 0; i < LOOPS; i++) {
        if (result > array[i]) {
            result = array[i];
        }
    }
    return result;
}


int main( int argc, char *argv[] )
{
    int retval = 0;
    int i, l, msgsize;
    unsigned int hw_starttime_recv, hw_stoptime_recv, hw_starttime_send,
        hw_stoptime_send;
    unsigned int sw_starttime_recv, sw_stoptime_recv, sw_starttime_send,
        sw_stoptime_send;

    struct sched_param sp = {
        .sched_priority = 20
    };

#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
    XCache_EnableDCache( 0xF8000000 );        // cache accesses to HW threads' burst RAM
//    XCache_EnableDCache( 0x80000000 );          // only cache external memory
#else
    printf( "data cache disabled\n" );
    XCache_DisableDCache(  );
#endif

    printf( "begin mq_benchmark\n" );
    randomize_msg(  );

    // create message queues
    mbox0 = create_mq( "/mbox0" );
    mbox1 = create_mq( "/mbox1" );

    // create mbox_times
    cyg_mbox_create( &mbox_times_handle, &mbox_times );

    // print attributes
    mq_getattr( mbox0, &mbox0_attr );
    mq_getattr( mbox1, &mbox1_attr );

    // create thread
    printf( "creating hw thread...\n" );
    rthread_attr_init( &rattr );
    rthread_attr_setslotnum( &rattr, 0 );
    rthread_attr_setresources( &rattr, thread_resources, 3 );
    pthread_attr_init( &pattr );
    pthread_attr_setschedparam( &pattr, &sp );

    rthread_create( &thread, &pattr, &rattr, ( void * ) 0 );

    cyg_thread_delay(10);   // wait a sec to allow HW thread to set up

    for ( msgsize = 4; msgsize <= MSG_SIZE_MAX; msgsize *= 2 ) {
        printf( "msgsize = %d, %d iterations\n", msgsize, LOOPS );

        for ( l = 0; l < LOOPS; l++) {

            sw_starttime_send = GET_TIME(  );
            //
            // SEND
            //
            retval = mq_send( mbox0, ( char * ) msg, msgsize, 10 );
            if ( retval < 0 ) {
                perror( "\nmq_send" );
                exit( 1 );
            }

            sw_stoptime_send = GET_TIME(  );
            sw_starttime_recv = GET_TIME(  );

            //
            // RECEIVE
            //
            retval =
                mq_receive( mbox1, ( char * ) buffer, MSG_SIZE_MAX, NULL );
            if ( retval != msgsize ) {
                perror( "\nmq_receive" );
                exit( 1 );
            }

            sw_stoptime_recv = GET_TIME(  );

            //
            // CHECK
            //
            for ( i = 0; i < msgsize / 4; i++ ) {
                if ( msg[i] != ~buffer[i] ) {  // the HW thread inverts the data
                    printf( "\nmsg and buffer do not match!\n" );
                    exit( 1 );
                }
            }

            //
            // GET HARDWARE TIMES
            //
            hw_starttime_recv =
                ( unsigned int ) cyg_mbox_get( mbox_times_handle );
            hw_stoptime_recv =
                ( unsigned int ) cyg_mbox_get( mbox_times_handle );
            hw_starttime_send =
                ( unsigned int ) cyg_mbox_get( mbox_times_handle );
            hw_stoptime_send =
                ( unsigned int ) cyg_mbox_get( mbox_times_handle );

            times_swhw[l] = calc_timediff( sw_starttime_send, hw_stoptime_recv );
            times_hwsw[l] = calc_timediff( hw_starttime_send, sw_stoptime_recv );
            times_send_hw[l] = calc_timediff( hw_starttime_send, hw_stoptime_send );
            times_send_sw[l] = calc_timediff( sw_starttime_send, sw_stoptime_send );
            
        }

        printf( "SW -> HW (mq): avg %d, min %d, max %d (cycles)\n"
                "HW -> SW (mq): avg %d, min %d, max %d (cycles)\n"
                "HW send  (mq): avg %d, min %d, max %d (cycles)\n"
                "SW send  (mq): avg %d, min %d, max %d (cycles)\n\n",
                avg(times_swhw, LOOPS), min(times_swhw, LOOPS), max(times_swhw, LOOPS),
                avg(times_hwsw, LOOPS), min(times_hwsw, LOOPS), max(times_hwsw, LOOPS),
                avg(times_send_hw, LOOPS), min(times_send_hw, LOOPS), max(times_send_hw, LOOPS),
                avg(times_send_sw, LOOPS), min(times_send_sw, LOOPS), max(times_send_sw, LOOPS)
             );

    }

    printf( "mq_benchmark done.\n" );

    return 0;
}
