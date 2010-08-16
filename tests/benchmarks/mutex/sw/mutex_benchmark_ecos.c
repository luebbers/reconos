///
/// \file mutex_benchmark_ecos.c
///
/// Measures eCos mutex call performance using soft- and
/// hardware threads.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       12.02.2008
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//
// Threads:
//
//      hw_mutex:   waits a defined period, locks a mutex,
//                  waits again, and unlocks a mutex, in hardware
//      sw_mutex:   also waits a defined period, locks a mutex,
//                  waits again, and unlocks a mutex, in software
//
// Configurations:
//
//      Numbers in parenthesis denote thread priorities. Lower numbers mean
//      higher priorities.
//
//      Benchmark A: "mutex_lock_unlock"
//          
//          This benchmark measures the raw OS call time for mutex_lock() and
//          mutex_unlock(). 
//          Measurement starts right before the call, and ends after the
//          call returns.
//          All lock() measurements are of course done without anybody waiting
//          on the mutex(). The unlock() calls are done with the specified number
//          of other threads trying to lock the mutex().
//
//          A1:     sw_mutex(10) with nobody waiting for the mutex
//          A2:     sw_mutex(10) with one sw_mutex(11) waiting for the mutex
//          A3:     sw_mutex(10) with five sw_mutex(11) waiting for the mutex
//          A4:     hw_mutex(10) with nobody waiting for the mutex
//          A5:     hw_mutex(10) with one sw_mutex(11) waiting for the mutex
//          A6:     hw_mutex(10) with five sw_mutex(11) waiting for the mutex
//
//
//      Benchmark B: "mutex_delay"
//          
//          This benchmark measures the "mutex turnaround" time.
//          Measurement starts before the first thread unlocks the mutex,
//          and ends after the target thread returns from its mutex_lock()
//          call. 
//
//          B1:     sw_mutex(10) -> sw_mutex(5), no other threads
//          B2:     sw_mutex(10) -> sw_mutex(5), one more sw_mutex(11) waiting
//          B3:     sw_mutex(10) -> sw_mutex(5), five more sw_mutex(11) waiting
//          B4:     sw_mutex(10) -> hw_mutex(5), no other threads
//          B5:     sw_mutex(10) -> hw_mutex(5), one more sw_mutex(11) waiting
//          B6:     sw_mutex(10) -> hw_mutex(5), five more sw_mutex(11) waiting
//          B7:     hw_mutex(10) -> sw_mutex(5), no other threads
//          B8:     hw_mutex(10) -> sw_mutex(5), one more sw_mutex(11) waiting
//          B9:     hw_mutex(10) -> sw_mutex(5), five more sw_mutex(11) waiting
//          B10:    hw_mutex(10) -> hw_mutex(5), no other threads
//          B11:    hw_mutex(10) -> hw_mutex(5), one more sw_mutex(11) waiting
//          B12:    hw_mutex(10) -> hw_mutex(5), five more sw_mutex(11) waiting
//

#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include <math.h>
#include <xcache_l.h>


//
// Parameters settable by Makefile! TODO :)
//

// how often each benchmark is run
#ifndef RUNS
#define RUNS (10)
#endif

// how long the delays in the HW thread should be (in cycles increments)
#ifndef DELAY
#define DELAY (10000)
#endif

// verbosity of outputs
// WARNING: can influence measurements
#ifndef VERBOSE
#define VERBOSE (0)
#endif

// if DATA_DUMP is set, the raw values are dumped, otherwise just a summary
//#define DATA_DUMP

// if USE_CACHE is set, the data cache is enabled.
//#define USE_CACHE


//
// Macros
//
#define MIN(x, y) ( x < y ? x : y )
#define MAX(x, y) ( x > y ? x : y )

#define STACK_SIZE 8192
#define MAX_NUM_LOAD_THREADS 10                                                // number of additional SW threads trying to lock mutex (load)
#define HW_THREADS 2
#define SW_THREADS 2
#define MAX_NUM_THREADS (HW_THREADS+SW_THREADS+MAX_NUM_LOAD_THREADS)

#if VERBOSE > 0
#define dbg_printf(format, args...) printf (format , ##args)
#else
#define dbg_printf(format, args...)
#endif

//
// Type Definitions
//
struct benchmark {
    unsigned int ( *func ) (  );
    unsigned char name[80];
    unsigned int results[RUNS];
    unsigned int avg, min, max;
    float dev;                  // standard deviation
};

struct sw_thread_params {
    cyg_handle_t *mbox_handle;
    cyg_sem_t *sem_post;
    cyg_sem_t *sem_wait;
};


// 
// Globals
//

// OS resources
cyg_mutex_t mutex_test;
cyg_mbox mbox[2];               // mboxes to collect measurement data
cyg_handle_t mbox_handle[2];
cyg_sem_t sem_main2thread[2];
cyg_sem_t sem_thread2main[2];

// Thread objects and handles
reconos_hwthread hw_thread[HW_THREADS];
cyg_thread sw_thread[SW_THREADS];
cyg_thread sw_load_thread[MAX_NUM_LOAD_THREADS];

cyg_handle_t thread_handle[MAX_NUM_THREADS];

char thread_stack[MAX_NUM_THREADS][STACK_SIZE];

unsigned int timebase_read_offset = 0;  // subtract this from SW reads from timebase

// HW thread resource arrays
reconos_res_t thread_resources[HW_THREADS][4] = {
    {
     {&mutex_test, CYG_MUTEX_T},
     {&sem_thread2main[0], CYG_SEM_T},
     {&sem_main2thread[0], CYG_SEM_T},
     {&mbox_handle[0], CYG_MBOX_HANDLE_T}
     },
    {
     {&mutex_test, CYG_MUTEX_T},
     {&sem_thread2main[1], CYG_SEM_T},
     {&sem_main2thread[1], CYG_SEM_T},
     {&mbox_handle[1], CYG_MBOX_HANDLE_T}
     }
};


//- FUNCTIONS ----------------------------------------------------------------


//
// calculate statistics
//
void calc_stats( struct benchmark *bm )
{

    int i;
    unsigned int sum = 0;
    unsigned int diff = 0;
    unsigned int ssqd = 0;      // sum of squared difference

    bm->min = ( unsigned int ) -1;
    bm->max = 0;
    for ( i = 0; i < RUNS; i++ ) {
        bm->min = MIN( bm->min, bm->results[i] );
        bm->max = MAX( bm->max, bm->results[i] );
        // this works only if sum doesn't overflow!
        sum += bm->results[i];
    }
    bm->avg = sum / RUNS;
    // calculate std deviation in seperate loop
    // we could sum up the squared results in the first loop,
    // and then supbstract RUNS*avg from that, but the
    // sum of the squared results will get too big
    for ( i = 0; i < RUNS; i++ ) {
        diff = ( bm->results[i] - bm->avg );
        ssqd += diff * diff;
    }
    bm->dev = sqrt( ssqd / RUNS );

}


//
// calculate time difference between two timing values
//
unsigned int calc_timediff( unsigned int start, unsigned int stop )
{

    if ( start <= stop ) {
        return ( stop - start );
    } else {
        return ( UINT_MAX - start + stop );
    }
}


//
// read two timing values from two mailboxes (one each) and return the difference
//
unsigned int get_timediff_from_mboxes( cyg_handle_t handle1,
                                       cyg_handle_t handle2 )
{

    unsigned int start, stop;

    start = ( unsigned int ) cyg_mbox_get( handle1 );
    stop = ( unsigned int ) cyg_mbox_get( handle2 );

    return calc_timediff( start, stop );
}


//
// read two timing values from a mailbox and return the difference
//
unsigned int get_timediff_from_mbox( cyg_handle_t handle )
{

    unsigned int start, stop;

    start = ( unsigned int ) cyg_mbox_get( handle );
    stop = ( unsigned int ) cyg_mbox_get( handle );

    return calc_timediff( start, stop );
}


//
// calibrate timebase_read_offset
//
void calibrate(  )
{
    int loops = 10;             // do this ten times and take the average
    int i;
    unsigned int starttime, stoptime;

    for ( i = 0; i < loops; i++ ) {
        starttime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
        stoptime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );

        timebase_read_offset += calc_timediff( starttime, stoptime );
    }
    timebase_read_offset /= loops;
}


//- SW Threads ---------------------------------------------------------------

//
// measure thread
//
void sw_measure_entry( cyg_addrword_t data )
{
    unsigned int starttime_lock, stoptime_lock,
        starttime_unlock, stoptime_unlock;

    cyg_thread_info ti;
    cyg_thread_get_info( cyg_thread_self(  ),
                         cyg_thread_get_id( cyg_thread_self(  ) ), &ti );

    // unpack thread parameters
    struct sw_thread_params *p = ( struct sw_thread_params * ) data;

    dbg_printf( "( %10d )--> %s: entry\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );

    dbg_printf( "( %10d )--> %s: lock()\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );
    // read timebase
    starttime_lock = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    // lock mutex
    if ( !cyg_mutex_lock( &mutex_test ) ) {
        perror( "sw_thread_entry: cyg_mutex_lock failed" );
    }
    // read timebase
    stoptime_lock = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    dbg_printf( "( %10d )--> %s: post(0x%08X)\n",
                ( unsigned int ) cyg_current_time(  ), ti.name,
                ( unsigned int ) p->sem_post );
    // post semaphore
    cyg_semaphore_post( p->sem_post );
    dbg_printf( "( %10d )--> %s: wait()\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );
    // wait for semaphore
    cyg_semaphore_wait( p->sem_wait );
    dbg_printf( "( %10d )--> %s: unlock()\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );
    // read timebase
    starttime_unlock = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    // unlock mutex
    cyg_mutex_unlock( &mutex_test );
    // read timebase
    stoptime_unlock = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    // put measurements to mbox
    if ( p->mbox_handle != NULL ) {
        dbg_printf( "( %10d )--> %s: post results\n",
                    ( unsigned int ) cyg_current_time(  ), ti.name );
        cyg_mbox_put( *( p->mbox_handle ), ( void * ) starttime_lock );
        cyg_mbox_put( *( p->mbox_handle ), ( void * ) stoptime_lock );
        cyg_mbox_put( *( p->mbox_handle ), ( void * ) starttime_unlock );
        cyg_mbox_put( *( p->mbox_handle ), ( void * ) stoptime_unlock );
    }
    // exit thread
    dbg_printf( "( %10d )--> %s: exit()\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );
    cyg_thread_exit(  );

}

//
// dummy lock/unlock thread to generate load
//
void sw_load_entry( cyg_addrword_t data )
{

    cyg_thread_info ti;
    cyg_thread_get_info( cyg_thread_self(  ),
                         cyg_thread_get_id( cyg_thread_self(  ) ), &ti );

    dbg_printf( "( %10d )--> %s: entry\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );

    dbg_printf( "( %10d )--> %s: lock()\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );
    // lock mutex
    if ( !cyg_mutex_lock( &mutex_test ) ) {
        perror( "sw_thread_entry: cyg_mutex_lock failed" );
    }
    dbg_printf( "( %10d )--> %s: unlock()\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );
    // unlock mutex
    cyg_mutex_unlock( &mutex_test );
    // exit thread
    dbg_printf( "( %10d )--> %s: exit()\n",
                ( unsigned int ) cyg_current_time(  ), ti.name );
    cyg_thread_exit(  );

}


//- Tests --------------------------------------------------------------------

//
// set up generic 'A' test
//
// thread 0 is the measurement stack
// threads 1 to MAX_NUM_LOAD_THREADS are the load threads
//
// writes results into '*result_lock' and '*result_unlock'
//
void run_A( int use_hw, int num_load_threads, unsigned int *result_lock,
            unsigned int *result_unlock )
{
    struct sw_thread_params measure_p = {
        .mbox_handle = &mbox_handle[0],
        .sem_post = &sem_thread2main[0],
        .sem_wait = &sem_main2thread[0]
    };
    int i;

    // create measurement thread
    if ( use_hw )
        reconos_hwthread_create( 10,                                           // priority
                                 ( cyg_addrword_t ) DELAY,                     // entry data
                                 "hw_measure",                                 // thread name
                                 thread_stack[0],                              // stack
                                 STACK_SIZE,                                   // stack size
                                 &thread_handle[0],                            // thread handle
                                 &hw_thread[0],                                // thread object
                                 UPBHWR_OSIF_0_BASEADDR,
                                 UPBHWR_OSIF_0_INTR + 1,
                                 thread_resources[0],
                                 4, 0xFFFFFFFF, 0xFFFFFFFF );
    else {
        cyg_thread_create( 10,                                                 // priority
                           sw_measure_entry,                                   // entry point
                           ( cyg_addrword_t ) & measure_p,                     // entry data
                           "sw_measure",                                       // thread name
                           thread_stack[0],                                    // stack
                           STACK_SIZE,                                         // stack size
                           &thread_handle[0],                                  // thread handle
                           &sw_thread[0]                                       // thread object
             );
    }

    // create load threads
    for ( i = 0; i < num_load_threads; i++ )
        cyg_thread_create( 11,                                                 // priority
                           sw_load_entry,                                      // entry point
                           ( cyg_addrword_t ) 0,                               // entry data
                           "sw_load",                                          // thread name
                           thread_stack[i + 1],                                // stack
                           STACK_SIZE,                                         // stack size
                           &thread_handle[i + 1],                              // thread handle
                           &sw_load_thread[i]                                  // thread object
             );

    // run measurement thread
    cyg_thread_resume( thread_handle[0] );

    // wait for semaphor from measurement thread
    cyg_semaphore_wait( &sem_thread2main[0] );

    // resume load threads
    for ( i = 0; i < num_load_threads; i++ )
        cyg_thread_resume( thread_handle[i + 1] );

    // wait a bit to let the load threads execute
    cyg_thread_delay( 5 );

    // post semaphore to measurement thread
    cyg_semaphore_post( &sem_main2thread[0] );

    // wait for measurement data
    *result_lock = get_timediff_from_mbox( mbox_handle[0] );                   // mutex_lock()
    *result_unlock = get_timediff_from_mbox( mbox_handle[0] );                 // mutex_unlock()

    // wait for all threads to finish
    cyg_thread_delay( 5 );

    // destroy all threads
    if ( use_hw )
        while ( !reconos_hwthread_delete( thread_handle[0] ) ) {
            printf
                ( "# unable to delete 'hw_measure' thread, retrying...\n" );
            cyg_thread_delay( 1 );
    } else
        while ( !cyg_thread_delete( thread_handle[0] ) ) {
            printf
                ( "# unable to delete 'sw_measure' thread, retrying...\n" );
            cyg_thread_delay( 1 );
        }
    for ( i = 0; i < num_load_threads; i++ )
        while ( !cyg_thread_delete( thread_handle[i + 1] ) ) {
            printf
                ( "# unable to delete 'sw_load' thread %i, retrying...\n",
                  i );
            cyg_thread_delay( 1 );
        }
}


//
// helper functions to get lock and unlock values in seperate calls
// FIXME: inefficient, could be done in half the test runs
//
unsigned int _run_A( int use_hw, int num_load_threads, int lock )
{
    static unsigned int result_lock;
    static unsigned int result_unlock;

    run_A( use_hw, num_load_threads, &result_lock, &result_unlock );
    if ( lock ) {
        return result_lock;
    } else {
        return result_unlock;
    }
}


//
// set up generic 'B' test
//
// threads 0 and 1 are the measurement threads
// threads 2 to MAX_NUM_LOAD_THREADS+1 are the load threads
//
// use_hw_0 and use_hw_1 define whether the measurement threads
// are hw or sw threads
//
// writes results into '*result_lock' and '*result_unlock'
//
unsigned int run_B( int use_hw_0, int use_hw_1, int num_load_threads )
{
    struct sw_thread_params measure_p[2] = {
        {
         .mbox_handle = &mbox_handle[0],
         .sem_post = &sem_thread2main[0],
         .sem_wait = &sem_main2thread[0]
         },
        {
         .mbox_handle = &mbox_handle[1],
         .sem_post = &sem_thread2main[1],
         .sem_wait = &sem_main2thread[1]
         }
    };

    int i;
    unsigned int result, dummy;

    // create measurement thread 0
    if ( use_hw_0 )
        reconos_hwthread_create( 10,                                           // priority
                                 ( cyg_addrword_t ) DELAY,                     // entry data
                                 "hw_measure_0",                               // thread name
                                 thread_stack[0],                              // stack
                                 STACK_SIZE,                                   // stack size
                                 &thread_handle[0],                            // thread handle
                                 &hw_thread[0],                                // thread object
                                 UPBHWR_OSIF_0_BASEADDR,
                                 UPBHWR_OSIF_0_INTR + 1,
                                 thread_resources[0],
                                 4, 0xFFFFFFFF, 0xFFFFFFFF );
    else {
        cyg_thread_create( 10,                                                 // priority
                           sw_measure_entry,                                   // entry point
                           ( cyg_addrword_t ) & measure_p[0],                  // entry data
                           "sw_measure_0",                                     // thread name
                           thread_stack[0],                                    // stack
                           STACK_SIZE,                                         // stack size
                           &thread_handle[0],                                  // thread handle
                           &sw_thread[0]                                       // thread object
             );
    }
    // create measurement thread 1
    if ( use_hw_1 )
        reconos_hwthread_create( 5,                                            // priority
                                 ( cyg_addrword_t ) DELAY,                     // entry data
                                 "hw_measure_1",                               // thread name
                                 thread_stack[1],                              // stack
                                 STACK_SIZE,                                   // stack size
                                 &thread_handle[1],                            // thread handle
                                 &hw_thread[1],                                // thread object
                                 UPBHWR_OSIF_1_BASEADDR,
                                 UPBHWR_OSIF_1_INTR + 1,
                                 thread_resources[1],
                                 4, 0xFFFFFFFF, 0xFFFFFFFF );
    else {
        cyg_thread_create( 5,                                                  // priority
                           sw_measure_entry,                                   // entry point
                           ( cyg_addrword_t ) & measure_p[1],                  // entry data
                           "sw_measure_1",                                     // thread name
                           thread_stack[1],                                    // stack
                           STACK_SIZE,                                         // stack size
                           &thread_handle[1],                                  // thread handle
                           &sw_thread[1]                                       // thread object
             );
    }

    // create load threads
    for ( i = 0; i < num_load_threads; i++ )
        cyg_thread_create( 11,                                                 // priority
                           sw_load_entry,                                      // entry point
                           ( cyg_addrword_t ) 0,                               // entry data
                           "sw_load",                                          // thread name
                           thread_stack[i + 2],                                // stack
                           STACK_SIZE,                                         // stack size
                           &thread_handle[i + 2],                              // thread handle
                           &sw_load_thread[i]                                  // thread object
             );

    dbg_printf( "( %10d )--> main: resume thread 0\n",
                ( unsigned int ) cyg_current_time(  ) );
    // run measurement thread 0
    cyg_thread_resume( thread_handle[0] );

    dbg_printf( "( %10d )--> main: wait (on 0x%08X)\n",
                ( unsigned int ) cyg_current_time(  ),
                ( unsigned int ) &sem_thread2main[0] );
    // wait for semaphor from measurement thread
    cyg_semaphore_wait( &sem_thread2main[0] );

    dbg_printf( "( %10d )--> main: resume thread 1\n",
                ( unsigned int ) cyg_current_time(  ) );
    // resume measurement thread 1
    cyg_thread_resume( thread_handle[1] );

    // wait a bit to let thread 1 execute
    cyg_thread_delay( 5 );

    dbg_printf( "( %10d )--> main: resume load threads\n",
                ( unsigned int ) cyg_current_time(  ) );
    // resume load threads
    for ( i = 0; i < num_load_threads; i++ )
        cyg_thread_resume( thread_handle[i + 2] );

    // wait a bit to let the load threads execute
    cyg_thread_delay( 5 );

    dbg_printf( "( %10d )--> main: post\n",
                ( unsigned int ) cyg_current_time(  ) );
    // post semaphore to measurement thread
    cyg_semaphore_post( &sem_main2thread[0] );

    // process rest of resources
    // wait/post for thread 1's semaphore
    dbg_printf( "( %10d )--> main: wait\n",
                ( unsigned int ) cyg_current_time(  ) );
    cyg_semaphore_wait( &sem_thread2main[1] );
    dbg_printf( "( %10d )--> main: post\n",
                ( unsigned int ) cyg_current_time(  ) );
    cyg_semaphore_post( &sem_main2thread[1] );

    // wait for measurement data
    dummy = get_timediff_from_mbox( mbox_handle[0] );                          // mutex_lock() thread 0
    dummy = ( unsigned int ) cyg_mbox_get( mbox_handle[1] );                   // mutex_lock start time from thread 1
    result = get_timediff_from_mboxes( mbox_handle[0], mbox_handle[1] );
    // time from mutex_unlock to lock
    dummy = ( unsigned int ) cyg_mbox_get( mbox_handle[0] );                   // mutex_unlock stop time from thread 0
    dummy = get_timediff_from_mbox( mbox_handle[1] );                          // mutex_unlock() thread 1

    // wait for all threads to finish
    cyg_thread_delay( 5 );

    dbg_printf( "( %10d )--> main: destroying all threads\n",
                ( unsigned int ) cyg_current_time(  ) );
    // destroy all threads
    if ( use_hw_0 )
        while ( !reconos_hwthread_delete( thread_handle[0] ) ) {
            printf
                ( "# unable to delete 'hw_measure' thread 0, retrying...\n" );
            cyg_thread_delay( 1 );
    } else
        while ( !cyg_thread_delete( thread_handle[0] ) ) {
            printf
                ( "# unable to delete 'sw_measure' thread 0, retrying...\n" );
            cyg_thread_delay( 1 );
        }
    if ( use_hw_1 )
        while ( !reconos_hwthread_delete( thread_handle[1] ) ) {
            printf
                ( "# unable to delete 'hw_measure' thread 1, retrying...\n" );
            cyg_thread_delay( 1 );
    } else
        while ( !cyg_thread_delete( thread_handle[1] ) ) {
            printf
                ( "# unable to delete 'sw_measure' thread 1, retrying...\n" );
            cyg_thread_delay( 1 );
        }
    for ( i = 0; i < num_load_threads; i++ )
        while ( !cyg_thread_delete( thread_handle[i + 2] ) ) {
            printf
                ( "# unable to delete 'sw_load' thread %i, retrying...\n",
                  i );
            cyg_thread_delay( 1 );
        }

    return result;
}


//
// instantiate tests A1 through A6
//
unsigned int run_A1_lock(  )
{
    return _run_A( 0, 0, 1 );
}
unsigned int run_A1_unlock(  )
{
    return _run_A( 0, 0, 0 );
}
unsigned int run_A2_lock(  )
{
    return _run_A( 0, 1, 1 );
}
unsigned int run_A2_unlock(  )
{
    return _run_A( 0, 1, 0 );
}
unsigned int run_A3_lock(  )
{
    return _run_A( 0, 5, 1 );
}
unsigned int run_A3_unlock(  )
{
    return _run_A( 0, 5, 0 );
}
unsigned int run_A3a_lock(  )
{
    return _run_A( 0, 10, 1 );
}
unsigned int run_A3a_unlock(  )
{
    return _run_A( 0, 10, 0 );
}
unsigned int run_A4_lock(  )
{
    return _run_A( 1, 0, 1 );
}
unsigned int run_A4_unlock(  )
{
    return _run_A( 1, 0, 0 );
}
unsigned int run_A5_lock(  )
{
    return _run_A( 1, 1, 1 );
}
unsigned int run_A5_unlock(  )
{
    return _run_A( 1, 1, 0 );
}
unsigned int run_A6_lock(  )
{
    return _run_A( 1, 5, 1 );
}
unsigned int run_A6_unlock(  )
{
    return _run_A( 1, 5, 0 );
}


//
// instantiate tests B1 through B12
//
unsigned int run_B1(  )
{
    return run_B( 0, 0, 0 );
}
unsigned int run_B2(  )
{
    return run_B( 0, 0, 1 );
}
unsigned int run_B3(  )
{
    return run_B( 0, 0, 5 );
}
unsigned int run_B4(  )
{
    return run_B( 0, 1, 0 );
}
unsigned int run_B5(  )
{
    return run_B( 0, 1, 1 );
}
unsigned int run_B6(  )
{
    return run_B( 0, 1, 5 );
}
unsigned int run_B7(  )
{
    return run_B( 1, 0, 0 );
}
unsigned int run_B8(  )
{
    return run_B( 1, 0, 1 );
}
unsigned int run_B9(  )
{
    return run_B( 1, 0, 5 );
}
unsigned int run_B10(  )
{
    return run_B( 1, 1, 0 );
}
unsigned int run_B11(  )
{
    return run_B( 1, 1, 1 );
}
unsigned int run_B12(  )
{
    return run_B( 1, 1, 5 );
}


//
// Benchmark suite definition
// This has to be global, otherwise it'll blow main()'s stack
//
struct benchmark benchmarks[] = {
    {run_A1_lock, "A1_sw_lock_no_load"},
    {run_A1_unlock, "A1_sw_unlock_no_load"},
    {run_A2_lock, "A2_sw_lock_1_load"},
    {run_A2_unlock, "A2_sw_unlock_1_load"},
    {run_A3_lock, "A3_sw_lock_5_load"},
    {run_A3_unlock, "A3_sw_unlock_5_load"},
    {run_A3a_lock, "A3a_sw_lock_10_load"},
    {run_A3a_unlock, "A3a_sw_unlock_10_load"},
    {run_A4_lock, "A4_hw_lock_no_load"},
    {run_A4_unlock, "A4_hw_unlock_no_load"},
    {run_A5_lock, "A5_hw_lock_1_load"},
    {run_A5_unlock, "A5_hw_unlock_1_load"},
    {run_A6_lock, "A6_hw_lock_5_load"},
    {run_A6_unlock, "A6_hw_unlock_5_load"},
    {run_B1, "B1_sw_to_sw_no_load"},
    {run_B2, "B2_sw_to_sw_1_load"},
    {run_B3, "B3_sw_to_sw_5_load"},
    {run_B4, "B4_sw_to_hw_no_load"},
    {run_B5, "B5_sw_to_hw_1_load"},
    {run_B6, "B6_sw_to_hw_5_load"},
    {run_B7, "B7_hw_to_sw_no_load"},
    {run_B8, "B8_hw_to_sw_1_load"},
    {run_B9, "B9_hw_to_sw_5_load"},
    {run_B10, "B10_hw_to_hw_no_load"},
    {run_B11, "B11_hw_to_hw_1_load"},
    {run_B12, "B12_hw_to_hw_5_load"},
};
int num_benchmarks = sizeof( benchmarks ) / sizeof( struct benchmark );


//
// Main
//
int main( int argc, char *argv[] )
{
    int i, n;
#ifdef USE_CACHE
    char suffix[] = "_cache";
#else
    char suffix[] = "_nocache";
#endif

    // TODO: Experiment with different delay settings for the threads.

#ifdef USE_CACHE
    XCache_EnableDCache( 0xF0000000 );
#else
    XCache_DisableDCache(  );
#endif

    printf( "# begin mutex_benchmark_ecos\n" );

    // initialize semaphore
    cyg_mutex_init( &mutex_test );

    // initialize result mailboxes
    cyg_mbox_create( &mbox_handle[0], &mbox[0] );
    cyg_mbox_create( &mbox_handle[1], &mbox[1] );

    // initialize communication semaphores
    for ( i = 0; i < 2; i++ ) {
        cyg_semaphore_init( &sem_main2thread[i], 0 );
        cyg_semaphore_init( &sem_thread2main[i], 0 );
    }

    // calibrate timbase reads from sw (IGNORED!)
    //calibrate( );
    //printf("# SW timing overhead: %d cycles\n", timebase_read_offset);

    // run benchmarks
    for ( i = 0; i < num_benchmarks; i++ ) {
        printf( "# running benchmark '%s%s', %d iterations\n",
                benchmarks[i].name, suffix, RUNS );
        fflush( stdout );
        for ( n = 0; n < RUNS; n++ ) {

            benchmarks[i].results[n] = benchmarks[i].func(  );
        }
    }

    // dump results
    for ( i = 0; i < num_benchmarks; i++ ) {
        calc_stats( &benchmarks[i] );
        printf( "#--------------------------------------\n" );
        printf( "# %s%s\n", benchmarks[i].name, suffix );
        printf( "# min: %10d, max: %10d, avg: %10d, dev: %8.2f\n",
                benchmarks[i].min, benchmarks[i].max, benchmarks[i].avg,
                benchmarks[i].dev );
#ifdef DATA_DUMP
        printf( "#  run,     cycles\n" );
        for ( n = 0; n < RUNS; n++ ) {
            printf( "%6d, %10d\n", n, benchmarks[i].results[n] );
        }
#endif
    }

    printf( "#--------------------------------------\n" );
    printf( "# mutex_benchmark_ecos done.\n" );
    fflush( stdout );

    return 0;
}
