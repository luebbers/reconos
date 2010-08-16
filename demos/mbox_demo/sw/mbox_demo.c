///
/// \file mbox_demo.c
/// Hardware mailbox demo and benchmark application.
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

#include "xparameters.h"


#define printf diag_printf
#define USE_CACHE 1
#define USE_HW_FIFO 1
// number of words to transfer
#define SIZE (8192/4)
#define STACK_SIZE 8192

#define NUM_LOAD_THREADS 10
#define LOAD_LEN 1024

unsigned int src[SIZE] __attribute__ ( ( aligned( 32 ) ) );   // align buffers to cache lines
unsigned int dst[SIZE] __attribute__ ( ( aligned( 32 ) ) );  

cyg_mbox mb_readtime, mb_writetime, mb_puttime, mb_gettime;
cyg_sem_t sem_start;
cyg_handle_t mb_readtime_handle, mb_writetime_handle, mb_puttime_handle, mb_gettime_handle;

#ifndef USE_HW_FIFO
cyg_mbox mb_transfer;
cyg_handle_t mb_transfer_handle;
#endif

// hardware threads
// thread A (producer)
cyg_thread hw_threadA;
rthread_attr_t hw_threadA_attr;
cyg_handle_t hw_threadA_handle;
char hw_threadA_stack[STACK_SIZE];
reconos_res_t hw_threadA_resources[4] =
{ 
	{&sem_start, CYG_SEM_T},	// start semaphore
#ifdef USE_HW_FIFO
	{0, RECONOS_HWMBOX_WRITE_T},	// transfer mailbox
#else
	{&mb_transfer_handle, CYG_MBOX_HANDLE_T},	// transfer mailbox
#endif
	{&mb_readtime_handle, CYG_MBOX_HANDLE_T},	// readtime mailbox
	{&mb_puttime_handle, CYG_MBOX_HANDLE_T}	// puttime mailbox
};
// thread B (consumer)
cyg_thread hw_threadB;
rthread_attr_t hw_threadB_attr;
cyg_handle_t hw_threadB_handle;
char hw_threadB_stack[STACK_SIZE];
reconos_res_t hw_threadB_resources[3] =
{
#ifdef USE_HW_FIFO
	{0, RECONOS_HWMBOX_READ_T},	// transfer mailbox
#else
	{&mb_transfer_handle, CYG_MBOX_HANDLE_T},	// transfer mailbox
#endif
	{&mb_gettime_handle, CYG_MBOX_HANDLE_T},	// gettime mailbox
	{&mb_writetime_handle, CYG_MBOX_HANDLE_T}	// writetime mailbox
};


// software threads (to generate load)
cyg_thread sw_thread;
cyg_handle_t sw_thread_handle;
char sw_thread_stack[STACK_SIZE];
volatile char memcopy_buf[2][8192];

void sw_thread_entry(cyg_addrword_t data) {
    int i;
    volatile int *src = (int *)memcopy_buf[0], *dst = (int *)memcopy_buf[1];
    unsigned int start, stop;


    start = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );

#ifdef USE_CACHE
//        printf( "Flushing cache..." );
//        XCache_EnableDCache( 0x80000000 );
//        printf( "done\n" );
#endif

        for ( i = 0; i < 8192/4; i++) {
            *dst++ = *src++;
    }

#ifdef USE_CACHE
//        printf( "Flushing cache..." );
//        XCache_EnableDCache( 0x80000000 );
//        printf( "done\n" );
#endif

    stop = XIo_DcrIn( XPAR_DCR_TIMEBASE_0_DCR_BASEADDR + 1 );
    cyg_mbox_put( mb_readtime_handle, ( void * ) start );
    cyg_mbox_put( mb_readtime_handle, ( void * ) stop );

    cyg_thread_exit(); 
}





void generate_data( unsigned int *data, size_t n ) {

	unsigned int i;

	for (i = 0; i < n; i++) {
		data[i] = i+1;
	}

}


int check_data( unsigned int *src, unsigned int *dst, size_t n ) {

	unsigned int i;

	for (i = 0; i < n; i++) {
		if (src[i] != dst[i]) {
			return 1;
		}
	}
	return 0;

}


void print_data( unsigned int *data, size_t n ) {

	unsigned int i;

	for (i = 0; i < n; i++) {
		if (i % 8 == 0) printf("\n");
		printf("0x%08X ", data[i]);
	}

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
unsigned int get_timediff_from_mbox(cyg_handle_t handle) {

	unsigned int start, stop;

	start = (unsigned int)cyg_mbox_get( handle );
	stop = (unsigned int)cyg_mbox_get( handle );

	return calc_timediff(start, stop);
}


int main( int argc, char *argv[] )
{

    unsigned int readtime, writetime, puttime, gettime, copytime;

    printf( "-------------------------------------------------------\n"
            "ReconOS hardware mailbox case study (mbox_demo)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            __FILE__ ", compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
    XCache_EnableDCache( 0x80000000 );
#else
    printf( "data cache disabled\n" );
    XCache_DisableDCache(  );
#endif

    //----------------------------------
    //-- GENERATE DATA
    //----------------------------------
    printf( "Generating data..." );
//    t_start = gettime(  );
    generate_data( src, SIZE );
//    t_stop = gettime(  );
//    t_gen = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

#ifdef USE_CACHE
    // flush cache contents - the hardware can only read from main memory
    // TODO: storing could be more efficient
    printf( "Flushing cache..." );
    XCache_EnableDCache( 0x80000000 );
    printf( "done\n" );
#endif

    //----------------------------------
    //-- TRANSFER DATA
    //----------------------------------
    // create mail boxes
    cyg_mbox_create( &mb_readtime_handle, &mb_readtime );
    cyg_mbox_create( &mb_writetime_handle, &mb_writetime );
    cyg_mbox_create( &mb_gettime_handle, &mb_gettime );
    cyg_mbox_create( &mb_puttime_handle, &mb_puttime );
#ifndef USE_HW_FIFO
    cyg_mbox_create( &mb_transfer_handle, &mb_transfer );
#endif

    // create start semaphore
    cyg_semaphore_init( &sem_start, 0 );

    // create hardware threads
    rthread_attr_init(&hw_threadA_attr);
    rthread_attr_setslotnum(&hw_threadA_attr, 0);
    rthread_attr_setresources(&hw_threadA_attr, hw_threadA_resources, 4);
    rthread_attr_dump(&hw_threadA_attr);
    reconos_hwthread_create( 16,                                               // priority
                             &hw_threadA_attr,
                             (cyg_addrword_t)src,                                       // entry data (memory location)
                             "HW_THREAD_A",                                     // thread name
                             hw_threadA_stack,                            // stack
                             STACK_SIZE,                                       // stack size
                             &hw_threadA_handle,                          // thread handle
                             &hw_threadA                                 // thread object
         );

    rthread_attr_init(&hw_threadB_attr);
    rthread_attr_setslotnum(&hw_threadB_attr, 1);
    rthread_attr_setresources(&hw_threadB_attr, hw_threadB_resources, 4);
    rthread_attr_dump(&hw_threadB_attr);
    reconos_hwthread_create( 16,                                               // priority
                             &hw_threadB_attr,
                             (cyg_addrword_t)dst,                                       // entry data (memory location)
                             "HW_THREAD_B",                                     // thread name
                             hw_threadB_stack,                            // stack
                             STACK_SIZE,                                       // stack size
                             &hw_threadB_handle,                          // thread handle
                             &hw_threadB                                 // thread object
         );
    cyg_thread_resume( hw_threadA_handle );

//    }

    cyg_thread_resume( hw_threadB_handle );

    cyg_thread_delay(100);

    printf( "Transferring data..." );
    // send start signal to thread A
    cyg_semaphore_post( &sem_start );




    // get timing values from mailboxes
    readtime = get_timediff_from_mbox( mb_readtime_handle );
    writetime = get_timediff_from_mbox( mb_writetime_handle );
    puttime = get_timediff_from_mbox( mb_puttime_handle );
    gettime = get_timediff_from_mbox( mb_gettime_handle );

    printf( "done\n" );


#ifdef USE_CACHE
    // flush cache contents
    // TODO: invalidating would suffice
    printf( "Flushing cache..." );
    XCache_EnableDCache( 0x80000000 );
    printf( "done\n" );
#endif


    //----------------------------------
    //-- CHECK DATA
    //----------------------------------
    printf( "Checking transferred data..." );
//    t_start = gettime(  );
    if ( check_data( src, dst, SIZE ) != 0 ) {
        printf( "CHECK FAILED!\n" );
	print_data(dst, SIZE);
	printf("\n");
    }
    else
        printf( "check successful.\n" );
//    t_stop = gettime(  );
//    t_check = calc_timediff_ms( t_start, t_stop );

/*    printf( "\nRunning times (size: %d words):\n"
            "\tGenerate data: %d ms\n"
            "\tSort data    : %d ms\n"
            "\tMerge data   : %d ms\n"
            "\tCheck data   : %d ms\n"
            "\nTotal computation time (sort & merge): %d ms\n",
            SIZE, t_gen, t_sort, t_merge, t_check, t_sort + t_merge );*/

        //run SW memcopy test
        cyg_thread_create(
                16,              // cyg_addrword_t sched_info,
                sw_thread_entry, // cyg_thread_entry_t* entry,
                0,            // cyg_addrword_t entry_data,
                "load_thread",   // char* name,
                sw_thread_stack, // void* stack_base,
                STACK_SIZE,      // cyg_ucount32 stack_size,
                &sw_thread_handle, // cyg_handle_t* handle,
                &sw_thread    // cyg_thread* thread
                );

        cyg_thread_resume( sw_thread_handle );

        copytime = get_timediff_from_mbox( mb_readtime_handle );

    printf("\nHardware timing: (size: %d words):\n"
           "\tBurst read from main memory: %10d cycles (%6d kBytes/s)\n"
           "\tBurst write to main memory : %10d cycles (%6d kBytes/s)\n"
           "\tHardware FIFO write        : %10d cycles (%6d kBytes/s)\n"
           "\tHardware FIFO read         : %10d cycles (%6d kBytes/s)\n"
           "\tSoftware memcopy           : %10d cycles (%6d kBytes/s)\n",
	   SIZE, 
           readtime,  819200000 / readtime,
           writetime, 819200000 / writetime, 
           puttime,   819200000 / puttime, 
           gettime,   819200000 / gettime, 
           copytime,  819200000 / copytime
           ); 


    return 0;

}
