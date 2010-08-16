///
/// \file semaphore_benchmark_posix.c
///
/// Measures eCos semaphore call performance using soft- and
/// hardware threads. POSIX version
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       18.03.2008
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

/*#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>*/
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <reconos.h>
#include <resources.h>
#include <math.h>
#include <pthread.h>
#include <mqueue.h>
#include <semaphore.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <limits.h>
#include <errno.h>
#include <unistd.h>     // for nice()
#include <sys/resource.h> // for getpriority()

//
// Parameters settable by Makefile! TODO :)
//

// how often each benchmark is run
#ifndef RUNS
#define RUNS (10)
#endif

// if DATA_DUMP is set, the raw values are dumped, otherwise just a summary
//#define DATA_DUMP

// NICE: nice value to set on startup
#define NICE -19


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
sem_t sem_test;
sem_t sem_start;        // used to signal start of tests
sem_t sem_ready;        // used to signal that waiter thread is ready
mqd_t mbox_poster, mbox_waiter;      // mboxes to collect measurement data
struct mq_attr mbox_poster_attr, mbox_waiter_attr;

// Thread objects and attributes
rthread_t hw_poster;
rthread_attr_t hw_poster_attr;
rthread_t hw_waiter;
rthread_attr_t hw_waiter_attr;
pthread_t sw_poster;
pthread_attr_t sw_poster_attr;
pthread_t sw_waiter;
pthread_attr_t sw_waiter_attr;
pthread_t sw_load;
pthread_attr_t sw_load_attr;

unsigned int timebase_read_offset = 0;      // subtract this from SW reads from timebase

// HW thread resource arrays
reconos_res_t poster_resources[3] = {
    {&sem_test, PTHREAD_SEM_T},
    {&mbox_poster, PTHREAD_MQD_T},
    {&sem_start, PTHREAD_SEM_T}
};
reconos_res_t waiter_resources[3] = {
    {&sem_test, PTHREAD_SEM_T},
    {&mbox_waiter, PTHREAD_MQD_T},
    {&sem_ready, PTHREAD_SEM_T}
};


int timebase_fd;


//- FUNCTIONS ----------------------------------------------------------------


int init_timebase() {
    timebase_fd = open("/dev/timebase", O_RDWR);
    if (timebase_fd < 0) {
        perror("error while opening timebase device");
        return (void*)-1;
    }
    return 0;
}

void close_timebase() {
    close(timebase_fd);
}

inline unsigned int get_timebase() {

    unsigned int buf;

    if (read(timebase_fd, &buf, sizeof(buf)) != sizeof(buf)) {
        perror("error while reading data from timebase");
    }

    return buf;

}


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
unsigned int get_timediff_from_mboxes( mqd_t mbox1,
                                       mqd_t mbox2 )
{

    unsigned int start, stop;
    int retval;

    retval = mq_receive(mbox1, (char*)&start, sizeof(start), 0);
    if (retval < 0) {
        perror("while receiving start value from mbox");
    }
    retval = mq_receive(mbox2, (char*)&stop, sizeof(stop), 0);
    if (retval < 0) {
        perror("while receiving stop value from mbox");
    }

    return calc_timediff( start, stop );
}


// reads two timing values from a mailbox and returns the difference
unsigned int get_timediff_from_mbox(mqd_t mbox) {

	return get_timediff_from_mboxes(mbox, mbox);
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
        starttime = get_timebase();
        stoptime = get_timebase();

        timebase_read_offset += calc_timediff(starttime, stoptime);
    }
    timebase_read_offset /= loops;
}


//
// wait for 'ticks' * 10 milliseconds
// meant to emulate eCos' cyg_tread_delay()
//
int pthread_delay( unsigned int ticks) {
    const unsigned int ticks_per_sec = 100;
    struct timespec ts = { 
        .tv_sec = ticks / ticks_per_sec, 
        .tv_nsec = (ticks % ticks_per_sec) * 10000000
    };
    return nanosleep(&ts, NULL);
}


//- SW Threads ---------------------------------------------------------------

//
// semaphore post
//
void *sw_poster_entry( void *data )
{
    unsigned int starttime, stoptime;

    // wait
    //pthread_delay ( ( unsigned int ) data );
    sem_wait( &sem_start );
    // read timebase
    starttime = get_timebase();
    // post semaphore
    sem_post( &sem_test );
    // read timebase
    stoptime = get_timebase(); 
    // wait
//    pthread_delay( ( unsigned int ) data );
    // put measurements to mbox
    mq_send( mbox_poster, &starttime, sizeof(starttime), 0 );
    mq_send( mbox_poster, &stoptime, sizeof(starttime), 0 );
    // exit thread
    pthread_exit( NULL );
}


//
// semaphore wait
//
void *sw_waiter_entry( void *data )
{
    unsigned int starttime, stoptime;

    // wait
    //pthread_delay( ( unsigned int ) data );
    // post ready semaphore
    sem_post( &sem_ready );
    // read timebase
    starttime = get_timebase();
    // wait for semaphore
    sem_wait( &sem_test );
    // read timebase
    stoptime = get_timebase();
    // wait
//    pthread_delay( ( unsigned int ) data );
    // put measurements to mbox
    mq_send( mbox_waiter, &starttime, sizeof(starttime), 0 );
    mq_send( mbox_waiter, &stoptime, sizeof(starttime), 0 );
    // exit thread
    pthread_exit( NULL );
}


//
// load thread (only waits for semaphore)
//
void *sw_load_entry( void *data )
{
    // wait for semaphore, this gets executed before sw_poster, which waits for sem_start
    sem_wait( &sem_test );
    // exit thread
    pthread_exit( NULL );
}

//- Tests --------------------------------------------------------------------

//
// SW thread posts while nobody is waiting for the semaphore
//
unsigned int run_A1(  )
{
    unsigned int result;
    struct sched_param sp = { .sched_priority = 10 };

    // create SW thread
    pthread_attr_init(&sw_poster_attr);
//    pthread_attr_setschedparam(&sw_poster_attr, &sp);
    pthread_create(&sw_poster,
                   &sw_poster_attr,
                   sw_poster_entry, (void*)1);
    pthread_setschedparam(sw_poster, SCHED_FIFO, &sp);

    // start test
    sem_post( &sem_start );

    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster );
    // wait for semaphore (to clear it)
    sem_wait( &sem_test );
    // wait for SW thread termination
    pthread_join(sw_poster, NULL);
    return result - timebase_read_offset;
}


//
// sw thread posts while a lower priority thread is waiting for the semaphore
//
unsigned int run_A2(  )
{
    unsigned int result;
    struct sched_param sp = { .sched_priority = 10 };
    struct sched_param sp_load = { .sched_priority = 5 };

    // create SW thread
    pthread_attr_init(&sw_poster_attr);
    pthread_attr_setschedparam(&sw_poster_attr, &sp);
    pthread_create(&sw_poster,
                   &sw_poster_attr,
                   sw_poster_entry, (void*)1);
    pthread_setschedparam(sw_poster, SCHED_FIFO, &sp);
    
    // create SW load thread, which waits for sem_test
    pthread_attr_init(&sw_load_attr);
//    pthread_attr_setschedparam(&sw_load_attr, &sp_load);
    pthread_create(&sw_load,
                   &sw_load_attr,
                   sw_load_entry, NULL);
    pthread_setschedparam(sw_load, SCHED_FIFO, &sp_load);

    // start test
    sem_post( &sem_start );
    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster );
    // wait for SW thread termination
    pthread_join(sw_poster, NULL);
    pthread_join(sw_load, NULL);
    return result - timebase_read_offset;
}


//
// hw thread posts while nobody is waiting for the semaphore
//
unsigned int run_A3(  )
{
    unsigned int result;
    struct sched_param sp = { .sched_priority = 10 };

    // create HW thread
    rthread_attr_init(&hw_poster_attr);
//    rthread_attr_setschedparam(&hw_poster_attr, &sp);
    rthread_attr_setstacksize(&hw_poster_attr, STACK_SIZE);
    rthread_attr_setresources(&hw_poster_attr, poster_resources, 3);
    rthread_attr_setslotnum(&hw_poster_attr, 0);
    rthread_create(&hw_poster,
                   &hw_poster_attr, (void*)1000000);
    pthread_setschedparam(hw_poster, SCHED_FIFO, &sp);
    // start test
    sem_post( &sem_start );
    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster );
    // wait for semaphore (to clear it)
    sem_wait( &sem_test );
    // wait for hw tread termination
    rthread_join(hw_poster, NULL);

    return result;
}


//
// hw thread posts while a lower priority thread is waiting for the semaphore
//
unsigned int run_A4(  )
{
    unsigned int result;
    struct sched_param sp = { .sched_priority = 10 };
    struct sched_param sp_load = { .sched_priority = 5 };

    // create HW thread
    rthread_attr_init(&hw_poster_attr);
//    rthread_attr_setschedparam(&hw_poster_attr, &sp);
    rthread_attr_setstacksize(&hw_poster_attr, STACK_SIZE);
    rthread_attr_setresources(&hw_poster_attr, poster_resources, 3);
    rthread_attr_setslotnum(&hw_poster_attr, 0);
    rthread_create(&hw_poster,
                   &hw_poster_attr, (void*)1000000);
    pthread_setschedparam(hw_poster, SCHED_FIFO, &sp);

    // create SW load thread, which waits for sem_test
    pthread_attr_init(&sw_load_attr);
//    pthread_attr_setschedparam(&sw_load_attr, &sp);
    pthread_create(&sw_load,
                   &sw_load_attr,
                   sw_load_entry, NULL);
    pthread_setschedparam(sw_load, SCHED_FIFO, &sp_load);
    
    // start test
    sem_post( &sem_start );
    // wait for measurement data
    result = get_timediff_from_mbox( mbox_poster );
    // wait for HW thread termination
    rthread_join(hw_poster, NULL);
    pthread_join(sw_load, NULL);
    return result;
}


//
// generic benchmark code for all "B" tests
// called by run_Bx() further down
//
unsigned int run_B( int poster_hw, int waiter_hw )
{
    unsigned int result, dummy;
    int retval;
    struct sched_param sp_poster = { .sched_priority = 5 };
    struct sched_param sp_waiter = { .sched_priority = 10 };

    // create threads
    if ( waiter_hw ) {
        rthread_attr_init(&hw_waiter_attr);
//        rthread_attr_setschedparam(&hw_waiter_attr, &sp_waiter);
        rthread_attr_setstacksize(&hw_waiter_attr, STACK_SIZE);
        rthread_attr_setresources(&hw_waiter_attr, waiter_resources, 3);
        rthread_attr_setslotnum(&hw_waiter_attr, 1);
        rthread_create(&hw_waiter,
                &hw_waiter_attr, (void*)1000000);
        pthread_setschedparam(hw_waiter, SCHED_FIFO, &sp_waiter);
    } else {
        pthread_attr_init(&sw_waiter_attr);
//        pthread_attr_setschedparam(&sw_waiter_attr, &sp_waiter);
        pthread_create(&sw_waiter,
                &sw_waiter_attr,
                sw_waiter_entry, (void*)1);
        pthread_setschedparam(sw_waiter, SCHED_FIFO, &sp_waiter);
    }
    if ( poster_hw ) {
        rthread_attr_init(&hw_poster_attr);
//        rthread_attr_setschedparam(&hw_poster_attr, &sp_poster);
        rthread_attr_setstacksize(&hw_poster_attr, STACK_SIZE);
        rthread_attr_setresources(&hw_poster_attr, poster_resources, 3);
        rthread_attr_setslotnum(&hw_poster_attr, 0);
        rthread_create(&hw_poster,
                &hw_poster_attr, (void*)2000000);
        pthread_setschedparam(hw_poster, SCHED_FIFO, &sp_poster);
    } else {
        pthread_attr_init(&sw_poster_attr);
//        pthread_attr_setschedparam(&sw_poster_attr, &sp_poster);
        pthread_create(&sw_poster,
                &sw_poster_attr,
                sw_poster_entry, (void*)4);
        pthread_setschedparam(sw_poster, SCHED_FIFO, &sp_poster);
    }


    // wait a little for waiter threads to execute their sem_wait calls
    sem_wait( &sem_ready );
    pthread_delay(5);

    // start test
    sem_post( &sem_start );

    // wait for measurement data
    // discard first waiter measurement
    retval = mq_receive(mbox_waiter, (char*)&dummy, sizeof(dummy), 0);
    if (retval < 0) {
        perror("while receiving value from mbox");
    }
    result = get_timediff_from_mboxes( mbox_poster, mbox_waiter );
    // discard second poster measurement
    retval = mq_receive(mbox_poster, (char*)&dummy, sizeof(dummy), 0);
    if (retval < 0) {
        perror("while receiving value from mbox");
    }
    
    // wait for thread termination
    if ( poster_hw )
        rthread_join(hw_poster, NULL);
    else
        pthread_join(sw_poster, NULL);

    if ( waiter_hw )
        rthread_join(hw_waiter, NULL);
    else
        pthread_join(sw_waiter, NULL);

    // approximate sw measurement error
    if ( !poster_hw )
        result -= timebase_read_offset/2;
    if ( !waiter_hw )
        result -= timebase_read_offset/2;

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
    int i, n, retval;
    char suffix[] = "_cache";

    // TODO: Experiment with different delay settings for the threads.

    printf( "# begin semaphore_benchmark_posix\n" );

    // set priority
    if (nice(NICE) == 0) {
        printf("# nice: %d, current priority: %d\n", 
                NICE, getpriority(PRIO_PROCESS, 0));
    } else {
        perror("could not nice process");
    }

    // initialize timebase
    if (init_timebase() != 0) return -1;

    // initialize semaphores
    if ( sem_init( &sem_test, 0, 0 ) == -1 )
        perror("unable to initialize test semaphore");
    if ( sem_init( &sem_start, 0, 0) == -1 )
        perror("unable to initialize start semaphore");
    if ( sem_init( &sem_ready, 0, 0) == -1 ) 
        perror("unable to initialize ready semaphore");

    // unlink result mailboxes, if they exist
    retval = mq_unlink("/mbox_poster");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mbox_poster");
    }
    retval = mq_unlink("/mbox_waiter");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mbox_waiter");
    }

    // initialize result mailboxes
    mbox_poster_attr.mq_flags   = mbox_waiter_attr.mq_flags    = 0;
    mbox_poster_attr.mq_maxmsg  = mbox_waiter_attr.mq_maxmsg   = 10;
    mbox_poster_attr.mq_msgsize = mbox_waiter_attr.mq_msgsize  = 4;
    mbox_poster_attr.mq_curmsgs = mbox_waiter_attr.mq_curmsgs  = 0;

    mbox_poster = mq_open("/mbox_poster", 
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, 
            &mbox_poster_attr);
    if (mbox_poster == (mqd_t)-1) {
        perror("unable to create mbox_poster");
    }
    mbox_waiter = mq_open("/mbox_waiter", 
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, 
            &mbox_waiter_attr);
    if (mbox_waiter == (mqd_t)-1) {
        perror("unable to create mbox_waiter");
    }


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
    printf( "# semaphore_benchmark_posix done.\n" );
    fflush( stdout );

    return 0;
}

