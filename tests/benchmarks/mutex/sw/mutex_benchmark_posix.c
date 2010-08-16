///
/// \file mutex_benchmark_posix.c
///
/// Measures eCos mutex call performance using soft- and
/// hardware threads.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       19.03.2008
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

//#include <cyg/infra/diag.h>
//#include <cyg/infra/cyg_type.h>
//#include <cyg/kernel/kapi.h>
#include <stdio.h>
#include <stdlib.h>
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

// NICE: adjust process priority
#define NICE -19

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
    mqd_t *mbox;
    sem_t *sem_post;
    sem_t *sem_wait;
};


// 
// Globals
//

// OS resources
pthread_mutex_t mutex_test;
mqd_t mbox[2];               // mboxes to collect measurement data
struct mq_attr mbox_attr[2];
sem_t sem_main2thread[2];
sem_t sem_thread2main[2];

// Thread objects and handles
rthread_t hw_thread[HW_THREADS];
rthread_attr_t hw_thread_attr[HW_THREADS];
pthread_t sw_thread[SW_THREADS];
pthread_attr_t sw_thread_attr[SW_THREADS];
pthread_t sw_load_thread[MAX_NUM_LOAD_THREADS];
pthread_attr_t sw_load_thread_attr[MAX_NUM_LOAD_THREADS];

unsigned int timebase_read_offset = 0;  // subtract this from SW reads from timebase
int timebase_fd;

// HW thread resource arrays
reconos_res_t thread_resources[HW_THREADS][4] = {
    {
     {&mutex_test, PTHREAD_MUTEX_T},
     {&sem_thread2main[0], PTHREAD_SEM_T},
     {&sem_main2thread[0], PTHREAD_SEM_T},
     {&mbox[0], PTHREAD_MQD_T}
     },
    {
     {&mutex_test, PTHREAD_MUTEX_T},
     {&sem_thread2main[1], PTHREAD_SEM_T},
     {&sem_main2thread[1], PTHREAD_SEM_T},
     {&mbox[1], PTHREAD_MQD_T}
     }
};


//- FUNCTIONS ----------------------------------------------------------------

int init_timebase() {
    timebase_fd = open("/dev/timebase", O_RDWR);
    if (timebase_fd < 0) {
        perror("error while opening timebase device");
        return -1;
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
    int loops = 100;     // do this 100 times and take the average
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
// measure thread
//
void *sw_measure_entry( void *data )
{
    unsigned int starttime_lock, stoptime_lock,
        starttime_unlock, stoptime_unlock;

/*    struct sched_param sp_self;
    int policy = SCHED_FIFO;
    pthread_getschedparam(pthread_self(), &policy, &sp_self);
    fprintf(stderr, "measure() priority: %d\n", sp_self.sched_priority);*/

    // unpack thread parameters
    struct sw_thread_params *p = ( struct sw_thread_params * ) data;

    // read timebase
    starttime_lock = get_timebase();
    // lock mutex
    if ( pthread_mutex_lock( &mutex_test ) != 0 ) {
        perror( "sw_thread_entry: pthread_mutex_lock failed" );
    }
    // read timebase
    stoptime_lock = get_timebase();
    // post semaphore
    sem_post( p->sem_post );
    // wait for semaphore
    sem_wait( p->sem_wait );
    // read timebase
    starttime_unlock = get_timebase();
    // unlock mutex
    pthread_mutex_unlock( &mutex_test );
    // read timebase
    stoptime_unlock = get_timebase();
    // put measurements to mbox
    if ( p->mbox != NULL ) {
        mq_send( *p->mbox, &starttime_lock, sizeof(starttime_lock), 0 );
        mq_send( *p->mbox, &stoptime_lock, sizeof(stoptime_lock), 0 );
        mq_send( *p->mbox, &starttime_unlock, sizeof(starttime_unlock), 0 );
        mq_send( *p->mbox, &stoptime_unlock, sizeof(stoptime_unlock), 0 );
    }
    // exit thread
    pthread_exit( NULL );

}

//
// dummy lock/unlock thread to generate load
//
void *sw_load_entry( void *data )
{
/*    struct sched_param sp_self;
    int policy = SCHED_FIFO;
    pthread_getschedparam(pthread_self(), &policy, &sp_self);
    fprintf(stderr, "load() priority: %d\n", sp_self.sched_priority);*/

    // lock mutex
    if ( pthread_mutex_lock( &mutex_test ) != 0 ) {
        perror( "sw_load_entry: pthread_mutex_lock failed" );
    }
    // unlock mutex
    pthread_mutex_unlock( &mutex_test );
    // exit thread
    pthread_exit( NULL );

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
    struct sched_param sp = { .sched_priority = 11 };  // highest priority (in POSIX, higher number means higher priority)
    struct sched_param sp_load = { .sched_priority = 10 };  // lower priority (but higher than main())
    struct sw_thread_params measure_p = {
        .mbox = &mbox[0],
        .sem_post = &sem_thread2main[0],
        .sem_wait = &sem_main2thread[0]
    };
    int i;

/*    struct sched_param sp_self;
    int policy = SCHED_FIFO;
    pthread_getschedparam(pthread_self(), &policy, &sp_self);
    fprintf(stderr, "main() priority: %d\n", sp_self.sched_priority);*/

    // create measurement thread
    if ( use_hw ) {
        rthread_attr_init(&hw_thread_attr[0]);
//        rthread_attr_setschedparam(&hw_thread_attr[0], &sp);
        rthread_attr_setstacksize(&hw_thread_attr[0], STACK_SIZE);
        rthread_attr_setresources(&hw_thread_attr[0], thread_resources[0], 4);
        rthread_attr_setslotnum(&hw_thread_attr[0], 0);
        rthread_create(&hw_thread[0],
                &hw_thread_attr[0], (void*)DELAY);
        pthread_setschedparam(hw_thread[0], SCHED_FIFO, &sp);   

    } else {
        pthread_attr_init(&sw_thread_attr[0]);
        pthread_attr_setschedparam(&sw_thread_attr[0], &sp);
        pthread_create(&sw_thread[0],
                &sw_thread_attr[0],
                sw_measure_entry, (void*)&measure_p);
        pthread_setschedparam(sw_thread[0], SCHED_FIFO, &sp);   

    }

    // wait for semaphor from measurement thread
    sem_wait( &sem_thread2main[0] );

    // create load threads
    for ( i = 0; i < num_load_threads; i++ ) {
        pthread_attr_init(&sw_load_thread_attr[i]);
//        pthread_attr_setschedparam(&sw_load_thread_attr[i], &sp_load);
        pthread_create(&sw_load_thread[i],
                &sw_load_thread_attr[i],
                sw_load_entry, NULL);
        pthread_setschedparam(sw_load_thread[i], SCHED_FIFO, &sp_load);   

    }

    // wait a bit to let the load threads execute
    pthread_delay( 5 );

    // post semaphore to measurement thread
    sem_post( &sem_main2thread[0] );

    // wait for measurement data
    *result_lock = get_timediff_from_mbox( mbox[0] );                   // mutex_lock()
    *result_unlock = get_timediff_from_mbox( mbox[0] );                 // mutex_unlock()

    // wait for all threads to finish
    pthread_delay( 5 );

    // destroy all threads
    if ( use_hw )
        rthread_join( hw_thread[0], NULL );
    else
        pthread_join( sw_thread[0], NULL );
    for ( i = 0; i < num_load_threads; i++ )
        pthread_join( sw_load_thread[i], NULL );

    // compensate for SW timebase read delay (estimated)
    if ( !use_hw ) {
        *result_lock -= timebase_read_offset;
        *result_unlock -= timebase_read_offset;
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
         .mbox= &mbox[0],
         .sem_post = &sem_thread2main[0],
         .sem_wait = &sem_main2thread[0]
         },
        {
         .mbox= &mbox[1],
         .sem_post = &sem_thread2main[1],
         .sem_wait = &sem_main2thread[1]
         }
    };
    struct sched_param sp_low = { .sched_priority = 5 };
    struct sched_param sp_high = { .sched_priority = 10 };
    struct sched_param sp_load = { .sched_priority = 4 };

    int i, retval;
    unsigned int result, dummy;

    // create measurement thread 0
    if ( use_hw_0 ) {
        rthread_attr_init(&hw_thread_attr[0]);
//        rthread_attr_setschedparam(&hw_thread_attr[0], &sp_low);
        rthread_attr_setstacksize(&hw_thread_attr[0], STACK_SIZE);
        rthread_attr_setresources(&hw_thread_attr[0], thread_resources[0], 4);
        rthread_attr_setslotnum(&hw_thread_attr[0], 0);
        rthread_create(&hw_thread[0],
                &hw_thread_attr[0], (void*)DELAY);
        pthread_setschedparam(hw_thread[0], SCHED_FIFO, &sp_low);   
    } else {
        pthread_attr_init(&sw_thread_attr[0]);
//        pthread_attr_setschedparam(&sw_thread_attr[0], &sp_low);
        pthread_create(&sw_thread[0],
                &sw_thread_attr[0],
                sw_measure_entry, (void*)&measure_p[0]);
        pthread_setschedparam(sw_thread[0], SCHED_FIFO, &sp_low);   
    }

    // wait for semaphor from measurement thread
    sem_wait( &sem_thread2main[0] );
    
    // create measurement thread 1
    if ( use_hw_1 ) {
        rthread_attr_init(&hw_thread_attr[1]);
//        rthread_attr_setschedparam(&hw_thread_attr[1], &sp_high);
        rthread_attr_setstacksize(&hw_thread_attr[1], STACK_SIZE);
        rthread_attr_setresources(&hw_thread_attr[1], thread_resources[1], 4);
        rthread_attr_setslotnum(&hw_thread_attr[1], 1);
        rthread_create(&hw_thread[1],
                &hw_thread_attr[1], (void*)DELAY);
        pthread_setschedparam(hw_thread[1], SCHED_FIFO, &sp_high);   
    } else {
        pthread_attr_init(&sw_thread_attr[1]);
//        pthread_attr_setschedparam(&sw_thread_attr[1], &sp_high);
        pthread_create(&sw_thread[1],
                &sw_thread_attr[1],
                sw_measure_entry, (void*)&measure_p[1]);
        pthread_setschedparam(sw_thread[1], SCHED_FIFO, &sp_high);   
    }

    // wait a bit to let thread 1 execute
    pthread_delay( 5 );

    // create load threads
    for ( i = 0; i < num_load_threads; i++ ) {
        pthread_attr_init(&sw_load_thread_attr[i]);
//        pthread_attr_setschedparam(&sw_load_thread_attr[i], &sp_load);
        pthread_create(&sw_load_thread[i],
                &sw_load_thread_attr[i],
                sw_load_entry, NULL);
        pthread_setschedparam(sw_load_thread[i], SCHED_FIFO, &sp_load);   
    }

    // wait a bit to let the load threads execute
    pthread_delay( 5 );

    // post semaphore to measurement thread
    sem_post( &sem_main2thread[0] );

    // process rest of resources
    // wait/post for thread 1's semaphore
    sem_wait( &sem_thread2main[1] );
    sem_post( &sem_main2thread[1] );

    // wait for measurement data
    dummy = get_timediff_from_mbox( mbox[0] );                          // mutex_lock() thread 0
    retval = mq_receive(mbox[1], &dummy, sizeof( dummy ), 0);           // mutex_lock start time from thread 1
    result = get_timediff_from_mboxes( mbox[0], mbox[1] );              // time from mutex_unlock to lock
    retval = mq_receive(mbox[0], &dummy, sizeof( dummy ), 0);           // mutex_unlock stop time from thread 0
    dummy = get_timediff_from_mbox( mbox[1] );                          // mutex_unlock() thread 1

    // wait for all threads to finish
    if ( use_hw_0 )
        rthread_join( hw_thread[0], NULL );
    else
        pthread_join( sw_thread[0], NULL );
    if ( use_hw_1 )
        rthread_join( hw_thread[1], NULL );
    else
        pthread_join( sw_thread[1], NULL );
    for ( i = 0; i < num_load_threads; i++ )
        pthread_join( sw_load_thread[i], NULL );

    // compensate for timebase read costs (estimated)
    if ( !use_hw_0 )
        result -= timebase_read_offset/2;
    if ( !use_hw_1 )
        result -= timebase_read_offset/2;

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
    int i, n, retval;
    char suffix[] = "_cache";

    // TODO: Experiment with different delay settings for the threads.

    printf( "# begin mutex_benchmark_posix\n" );

    // set priority
    if (nice(NICE) == 0) {
        printf("# nice: %d, current priority: %d\n", 
                NICE, getpriority(PRIO_PROCESS, 0));
    } else {
        perror("could not nice process");
    }

    // initialize timebase
    if (init_timebase() != 0) return -1;

    // initialize mutex
    pthread_mutex_init( &mutex_test, NULL );

    // unlink result mailboxes, if they exist
    retval = mq_unlink("/mbox0");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mbox[0]");
    }
    retval = mq_unlink("/mbox1");
    if (retval != 0 && errno != ENOENT) {    // we don't care if it doesn't exist
        perror("unable to unlink mbox[1]");
    }

    // initialize result mailboxes
    mbox_attr[0].mq_flags   = mbox_attr[1].mq_flags   = 0;
    mbox_attr[0].mq_maxmsg  = mbox_attr[1].mq_maxmsg  = 10;
    mbox_attr[0].mq_msgsize = mbox_attr[1].mq_msgsize = 4;
    mbox_attr[0].mq_curmsgs = mbox_attr[1].mq_curmsgs = 0;

    mbox[0] = mq_open("/mbox0",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mbox_attr[0]);
    if (mbox[0] == (mqd_t)-1) {
        perror("unable to create mbox[0]");
    }
    mbox[1] = mq_open("/mbox1",
            O_RDWR | O_CREAT, S_IRWXU | S_IRWXG,
            &mbox_attr[1]);
    if (mbox[1] == (mqd_t)-1) {
        perror("unable to create mbox1");
    }

    // initialize communication semaphores
    for ( i = 0; i < 2; i++ ) {
        if ( sem_init( &sem_main2thread[i], 0, 0 ) == -1 )
            perror("unable to initialize main2thread semaphore");
        if ( sem_init( &sem_thread2main[i], 0, 0 ) == -1 )
            perror("unable to initialize thread2main semaphore");
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
    printf( "# mutex_benchmark_posix done.\n" );
    fflush( stdout );

    return 0;
}
