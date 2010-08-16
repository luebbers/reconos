///
/// \file semaphore_benchmark_ecos.c
///
/// Measures eCos semaphore call performance using soft- and
/// hardware threads.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       11.02.2008
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//
// Threads:
//
//      hw_poster:  posts a semaphore
//      hw_waiter:  waits for a semaphore
//      sw_poster:  posts a semaphore
//      sw_waiter:  waits for a semaphore
//
// Configurations:
//
//      Numbers in parenthesis denote thread priorities. Lower numbers mean
//      higher priorities.
//
//      Benchmark A: "semaphore_post"
//          
//          This benchmark measures the raw OS call time for sem_post().
//          Measurement starts right before the call, and ends after the
//          call returns.
//
//          A1:     sw_post(10) with nobody waiting for the semaphore
//          A2:     sw_post(10) with 1 lower priority thread(15) waiting for the semaphore
//          A3:     hw_post(10) with nobody waiting for the semaphore
//          A4:     hw_post(10) with 1 lower priority thread(15) waiting for the semaphore
//
//
//      Benchmark B: "semaphore_delay"
//          
//          This benchmark measures the "semaphore turnaround" time.
//          Measurement starts before the poster thread posts the semaphore,
//          and ends after the waiter thread returns from its sem_wait()
//          call. This is akin to A2 and A4, since the waiter thread is always
//          waiting before the poster thread posts. However, the waiter thread
//          here has a higher piority so that it immediately gets the semaphore.
//
//          B1:     sw_post(10) -> sw_wait(5)
//          B2:     sw_post(10) -> hw_wait(5)
//          B3:     hw_post(10) -> sw_wait(5)
//          B4:     hw_post(10) -> hw_wait(5)
//
// There are never more than two threads involved in a benchmark.
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


// 
// Globals
//

// OS resources
cyg_sem_t sem_test;
cyg_mbox mbox_poster, mbox_waiter;      // mboxes to collect measurement data
cyg_handle_t mbox_poster_handle, mbox_waiter_handle;

// Thread objects and handles
reconos_hwthread hw_poster;
reconos_hwthread hw_waiter;
cyg_thread sw_poster;
cyg_thread sw_waiter;
cyg_handle_t hw_poster_handle;
cyg_handle_t hw_waiter_handle;
cyg_handle_t sw_poster_handle;
cyg_handle_t sw_waiter_handle;

char poster_stack[STACK_SIZE] __attribute__ ( ( aligned( 4 ) ) );       // at most two threads running
char waiter_stack[STACK_SIZE] __attribute__ ( ( aligned( 4 ) ) );

unsigned int timebase_read_offset = 0;      // subtract this from SW reads from timebase

// HW thread resource arrays
reconos_res_t poster_resources[2] = {
    {&sem_test, CYG_SEM_T},
    {&mbox_poster_handle, CYG_MBOX_HANDLE_T}
};
reconos_res_t waiter_resources[2] = {
    {&sem_test, CYG_SEM_T},
    {&mbox_waiter_handle, CYG_MBOX_HANDLE_T}
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
void calibrate( )
{
    int loops = 10;     // do this ten times and take the average
    int i;
    unsigned int starttime, stoptime;

    for (i = 0; i < loops; i++) {
        starttime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
        stoptime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );

        timebase_read_offset += calc_timediff(starttime, stoptime);
    }
    timebase_read_offset /= loops;
}


//- SW Threads ---------------------------------------------------------------

//
// semaphore post
//
void sw_poster_entry( cyg_addrword_t data )
{
    unsigned int starttime, stoptime;

    // wait
    cyg_thread_delay( ( unsigned int ) data );
    // read timebase
    starttime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    // post semaphore
    cyg_semaphore_post( &sem_test );
    // read timebase
    stoptime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    // wait
    cyg_thread_delay( ( unsigned int ) data );
    // put measurements to mbox
    cyg_mbox_put( mbox_poster_handle, ( void * ) starttime );
    cyg_mbox_put( mbox_poster_handle, ( void * ) stoptime );
    // exit thread
    cyg_thread_exit(  );
}


//
// semaphore wait
//
void sw_waiter_entry( cyg_addrword_t data )
{
    unsigned int starttime, stoptime;

    // wait
    cyg_thread_delay( ( unsigned int ) data );
    // read timebase
    starttime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    // wait for semaphore
    cyg_semaphore_wait( &sem_test );
    // read timebase
    stoptime = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    // wait
    cyg_thread_delay( ( unsigned int ) data );
    // put measurements to mbox
    cyg_mbox_put( mbox_waiter_handle, ( void * ) starttime );
    cyg_mbox_put( mbox_waiter_handle, ( void * ) stoptime );
    // exit thread
    cyg_thread_exit(  );
}


//- Tests --------------------------------------------------------------------

//
// SW thread posts while nobody is waiting for the semaphore
//
unsigned int run_A1(  )
{
    unsigned int result;

    // create SW thread
    cyg_thread_create( 10,                                                     // priority
                       sw_poster_entry,                                        // entry point
                       ( cyg_addrword_t ) 1,                                   // entry data
                       "sw_poster",                                            // thread name
                       poster_stack,                                           // stack
                       STACK_SIZE,                                             // stack size
                       &sw_poster_handle,                                      // thread handle
                       &sw_poster                                              // thread object
         );
    // run SW thread
    cyg_thread_resume( sw_poster_handle );
    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster_handle );
    // wait for semaphore (to clear it)
    cyg_semaphore_wait( &sem_test );
    // destroy SW thread
    while ( !cyg_thread_delete( sw_poster_handle ) ) {
        printf( "# unable to delete 'sw_poster' thread, retrying...\n" );
        cyg_thread_delay( 1 );
    }
    return result - timebase_read_offset;
}


//
// sw thread posts while a lower priority thread is waiting for the semaphore
//
unsigned int run_A2(  )
{
    unsigned int result;

    // create SW thread
    cyg_thread_create( 10,                                                     // priority
                       sw_poster_entry,                                        // entry point
                       ( cyg_addrword_t ) 1,                                   // entry data
                       "sw_poster",                                            // thread name
                       poster_stack,                                           // stack
                       STACK_SIZE,                                             // stack size
                       &sw_poster_handle,                                      // thread handle
                       &sw_poster                                              // thread object
         );
    // run SW thread
    cyg_thread_resume( sw_poster_handle );
    // wait for semaphore, this gets executed before sw_poster, which waits.
    cyg_semaphore_wait( &sem_test );
    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster_handle );
    // destroy SW thread
    while ( !cyg_thread_delete( sw_poster_handle ) ) {
        printf( "# unable to delete 'sw_poster' thread, retrying...\n" );
        cyg_thread_delay( 1 );
    }
    return result - timebase_read_offset;
}


//
// hw thread posts while nobody is waiting for the semaphore
//
unsigned int run_A3(  )
{
    unsigned int result;

    // create HW thread
    reconos_hwthread_create( 10,                                               // priority
                             ( cyg_addrword_t ) 1000000,                       // entry data
                             "hw_poster",                                      // thread name
                             poster_stack,                                     // stack
                             STACK_SIZE,                                       // stack size
                             &hw_poster_handle,                                // thread handle
                             &hw_poster,                                       // thread object
                             UPBHWR_OSIF_0_BASEADDR,
                             UPBHWR_OSIF_0_INTR + 1,
                             poster_resources, 2, 0xFFFFFFFF, 0xFFFFFFFF );
    // run HW thread
    cyg_thread_resume( hw_poster_handle );
    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster_handle );
    // wait for semaphore (to clear it)
    cyg_semaphore_wait( &sem_test );
    // destroy HW thread
    while ( !reconos_hwthread_delete( hw_poster_handle ) ) {
        printf( "# unable to delete 'hw_poster' thread, retrying...\n" );
        cyg_thread_delay( 1 );
    }
    return result;
}


//
// hw thread posts while a lower priority thread is waiting for the semaphore
//
unsigned int run_A4(  )
{
    unsigned int result;

    // create HW thread
    reconos_hwthread_create( 10,                                               // priority
                             ( cyg_addrword_t ) 1000000,                       // entry data
                             "hw_poster",                                      // thread name
                             poster_stack,                                     // stack
                             STACK_SIZE,                                       // stack size
                             &hw_poster_handle,                                // thread handle
                             &hw_poster,                                       // thread object
                             UPBHWR_OSIF_0_BASEADDR,
                             UPBHWR_OSIF_0_INTR + 1,
                             poster_resources, 2, 0xFFFFFFFF, 0xFFFFFFFF );
    // run HW thread
    cyg_thread_resume( hw_poster_handle );
    // wait for semaphore, this gets executed before sw_poster, which waits.
    cyg_semaphore_wait( &sem_test );
    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster_handle );
    // destroy HW thread
    while ( !reconos_hwthread_delete( hw_poster_handle ) ) {
        printf( "# unable to delete 'hw_poster' thread, retrying...\n" );
        cyg_thread_delay( 1 );
    }
    return result;
}


//
// generic benchmark code for all "B" tests
// called by run_Bx() further down
//
unsigned int run_B( int poster_hw, int waiter_hw )
{
    unsigned int result, dummy;

    // create threads
    if ( poster_hw )
        reconos_hwthread_create( 10,                                           // priority
                                 ( cyg_addrword_t ) 2000000,                   // entry data
                                 "hw_poster",                                  // thread name
                                 poster_stack,                                 // stack
                                 STACK_SIZE,                                   // stack size
                                 &hw_poster_handle,                            // thread handle
                                 &hw_poster,                                   // thread object
                                 UPBHWR_OSIF_0_BASEADDR,
                                 UPBHWR_OSIF_0_INTR + 1,
                                 poster_resources,
                                 2, 0xFFFFFFFF, 0xFFFFFFFF );
    else
        cyg_thread_create( 10,                                                 // priority
                           sw_poster_entry,                                    // entry point
                           ( cyg_addrword_t ) 4,                               // entry data
                           "sw_poster",                                        // thread name
                           poster_stack,                                       // stack
                           STACK_SIZE,                                         // stack size
                           &sw_poster_handle,                                  // thread handle
                           &sw_poster                                          // thread object
             );

    if ( waiter_hw )
        reconos_hwthread_create( 5,                                            // priority
                                 ( cyg_addrword_t ) 1000000,                   // entry data
                                 "hw_waiter",                                  // thread name
                                 waiter_stack,                                 // stack
                                 STACK_SIZE,                                   // stack size
                                 &hw_waiter_handle,                            // thread handle
                                 &hw_waiter,                                   // thread object
                                 UPBHWR_OSIF_1_BASEADDR,
                                 UPBHWR_OSIF_1_INTR + 1,
                                 waiter_resources,
                                 2, 0xFFFFFFFF, 0xFFFFFFFF );
    else
        cyg_thread_create( 5,                                                  // priority
                           sw_waiter_entry,                                    // entry point
                           ( cyg_addrword_t ) 1,                               // entry data
                           "sw_waiter",                                        // thread name
                           waiter_stack,                                       // stack
                           STACK_SIZE,                                         // stack size
                           &sw_waiter_handle,                                  // thread handle
                           &sw_waiter                                          // thread object
             );

    // run threads
    if ( waiter_hw )
        cyg_thread_resume( hw_waiter_handle );
    else
        cyg_thread_resume( sw_waiter_handle );
    if ( poster_hw )
        cyg_thread_resume( hw_poster_handle );
    else
        cyg_thread_resume( sw_poster_handle );

    // wait for measurement data
    dummy = ( unsigned int ) cyg_mbox_get( mbox_waiter_handle );               // discard first waiter measurement
    result =
        get_timediff_from_mboxes( mbox_poster_handle, mbox_waiter_handle );
    dummy = ( unsigned int ) cyg_mbox_get( mbox_poster_handle );               // discard second poster measurement
    //
    // destroy SW threads
    if ( poster_hw )
        while ( !reconos_hwthread_delete( hw_poster_handle ) ) {
            printf
                ( "# unable to delete 'hw_poster' thread, retrying...\n" );
            cyg_thread_delay( 1 );
    } else
        while ( !cyg_thread_delete( sw_poster_handle ) ) {
            printf
                ( "# unable to delete 'sw_poster' thread, retrying...\n" );
            cyg_thread_delay( 1 );
        }
    if ( waiter_hw )
        while ( !reconos_hwthread_delete( hw_waiter_handle ) ) {
            printf
                ( "# unable to delete 'hw_waiter' thread, retrying...\n" );
            cyg_thread_delay( 1 );
    } else
        while ( !cyg_thread_delete( sw_waiter_handle ) ) {
            printf
                ( "# unable to delete 'sw_waiter' thread, retrying...\n" );
            cyg_thread_delay( 1 );
        }
    return result;
}


//
// all combination of 'B' tests
//
//                                post_hw  wait_hw
unsigned int run_B1(  ) { return run_B( 0, 0 ); }
unsigned int run_B2(  ) { return run_B( 0, 1 ); }
unsigned int run_B3(  ) { return run_B( 1, 0 ); }
unsigned int run_B4(  ) { return run_B( 1, 1 ); }


//
// Benchmark suite definition
// This has to be global, otherwise it'll blow main()'s stack
//
struct benchmark benchmarks[] = {
    {run_A1, "A1_sw_posts_nobody_waits"},
    {run_A2, "A2_sw_posts_loprio_waits"},
    {run_A3, "A3_hw_posts_nobody_waits"},
    {run_A4, "A4_hw_posts_loprio_waits"},
    {run_B1, "B1_sw_posts_sw_waits"},
    {run_B2, "B2_sw_posts_hw_waits"},
    {run_B3, "B3_hw_posts_sw_waits"},
    {run_B4, "B4_hw_posts_hw_waits"}
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

    printf( "# begin semaphore_benchmark_ecos\n" );

    // initialize semaphore
    cyg_semaphore_init( &sem_test, 0 );

    // initialize result mailboxes
    cyg_mbox_create( &mbox_poster_handle, &mbox_poster );
    cyg_mbox_create( &mbox_waiter_handle, &mbox_waiter );

    // calibrate timbase reads from sw
    calibrate( );
    printf("# SW timing overhead: %d cycles\n", timebase_read_offset);

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
    printf( "# semaphore_benchmark_ecos done.\n" );
    fflush( stdout );

    return 0;
}

