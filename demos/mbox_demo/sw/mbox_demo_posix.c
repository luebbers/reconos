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

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <reconos/reconos.h>
#include <xcache_l.h>
#include <pthread.h>
#include <mqueue.h>
#include <semaphore.h>
#include <sys/stat.h>
#include <fcntl.h>

//#define USE_CACHE 1
#define USE_HW_FIFO 1
// number of words to transfer
#define SIZE (8192/4)
#define STACK_SIZE 8192


unsigned int src[SIZE] __attribute__ ( ( aligned( 32 ) ) );   // align buffers to cache lines
unsigned int dst[SIZE] __attribute__ ( ( aligned( 32 ) ) );  

mqd_t mb_readtime, mb_writetime, mb_puttime, mb_gettime;
struct mq_attr mb_readtime_attr, mb_writetime_attr, mb_puttime_attr, mb_gettime_attr;
sem_t sem_start;

#ifndef USE_HW_FIFO
mqd_t mb_transfer;
struct mq_attr mb_transfer_attr;
#endif

// hardware threads
// thread A (producer)
rthread_t hw_threadA;
rthread_attr_t hw_threadA_attr;
reconos_res_t hw_threadA_resources[4] =
{ 
	{&sem_start, PTHREAD_SEM_T},	// start semaphore
#ifdef USE_HW_FIFO
	{0, RECONOS_HWMBOX_WRITE_T},	// transfer mailbox
#else
	{&mb_transfer, PTHREAD_MQD_T},	// transfer mailbox
#endif
	{&mb_readtime, PTHREAD_MQD_T},	// readtime mailbox
	{&mb_puttime, PTHREAD_MQD_T}	// puttime mailbox
};
// thread B (consumer)
rthread_t hw_threadB;
rthread_attr_t hw_threadB_attr;
reconos_res_t hw_threadB_resources[3] =
{
#ifdef USE_HW_FIFO
	{0, RECONOS_HWMBOX_READ_T},	// transfer mailbox
#else
	{&mb_transfer, PTHREAD_MQD_T},	// transfer mailbox
#endif
	{&mb_gettime, PTHREAD_MQD_T},	// gettime mailbox
	{&mb_writetime, PTHREAD_MQD_T}	// writetime mailbox
};


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
unsigned int get_timediff_from_mbox(mqd_t mbox) {

	unsigned int start, stop;
        int retval;

        retval = mq_receive(mbox, (char*)&start, sizeof(start), 0);
        if (retval < 0) {
            perror("while receiving start value from mbox");
        }
        retval = mq_receive(mbox, (char*)&stop, sizeof(stop), 0);
        if (retval < 0) {
            perror("while receiving stop value from mbox");
        }

	return calc_timediff(start, stop);
}


int main( int argc, char *argv[] )
{

    unsigned int readtime, writetime, puttime, gettime;

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
    mb_readtime_attr.mq_flags   = mb_writetime_attr.mq_flags   = mb_puttime_attr.mq_flags   = mb_gettime_attr.mq_flags = 0;
    mb_readtime_attr.mq_maxmsg  = mb_writetime_attr.mq_maxmsg  = mb_puttime_attr.mq_maxmsg  = mb_gettime_attr.mq_maxmsg = 10;
    mb_readtime_attr.mq_msgsize = mb_writetime_attr.mq_msgsize = mb_puttime_attr.mq_msgsize = mb_gettime_attr.mq_msgsize = 4;
    mb_readtime_attr.mq_curmsgs = mb_writetime_attr.mq_curmsgs = mb_puttime_attr.mq_curmsgs = mb_gettime_attr.mq_curmsgs = 0;

    mb_readtime = mq_open("/readtime", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mb_readtime_attr);
    if (mb_readtime == (mqd_t)-1) {
        perror("unable to create mb_readtime");
    }
    mb_writetime = mq_open("/writetime", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mb_writetime_attr);
    if (mb_writetime == (mqd_t)-1) {
        perror("unable to create mb_writetime");
    }
    mb_puttime = mq_open("/puttime", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mb_puttime_attr);
    if (mb_puttime == (mqd_t)-1) {
        perror("unable to create mb_puttime");
    }
    mb_gettime = mq_open("/gettime", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mb_gettime_attr);
    if (mb_gettime == (mqd_t)-1) {
        perror("unable to create mb_gettime");
    }

#ifndef USE_HW_FIFO
    mb_transfer_attr.mq_flags   = 0;
    mb_transfer_attr.mq_maxmsg  = 10;
    mb_transfer_attr.mq_msgsize = 4;
    mb_transfer_attr.mq_curmsgs = 0;
    mb_transfer = mq_open("/transfer", O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, &mb_transfer_attr);
    if (mb_transfer == (mqd_t)-1) {
        perror("unable to create mb_transfer");
    }
#endif

    // create start semaphore
    if (sem_init(&sem_start, 0, 0) == -1) {
        perror("unable to initialize sem_start");
    }

    // create hardware threads
    rthread_attr_init(&hw_threadA_attr);
    rthread_attr_setstacksize(&hw_threadA_attr, 8192);
    rthread_attr_setresources(&hw_threadA_attr, hw_threadA_resources, 4);
    rthread_attr_setslotnum(&hw_threadA_attr, 0);
    rthread_attr_init(&hw_threadB_attr);
    rthread_attr_setstacksize(&hw_threadB_attr, 8192);
    rthread_attr_setresources(&hw_threadB_attr, hw_threadB_resources, 3);
    rthread_attr_setslotnum(&hw_threadB_attr, 1);

    rthread_create(&hw_threadA, &hw_threadA_attr, (void *)src);

    printf( "Transferring data..." );
    // send start signal to thread A
    sem_post( &sem_start );

    rthread_create(&hw_threadB, &hw_threadB_attr, (void *)dst);

    // get timing values from mailboxes
    readtime = get_timediff_from_mbox( mb_readtime );
    writetime = get_timediff_from_mbox( mb_writetime );
    puttime = get_timediff_from_mbox( mb_puttime );
    gettime = get_timediff_from_mbox( mb_gettime );

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

    printf("\nHardware timing: (size: %d words):\n"
           "\tBurst read from main memory: %d cycles\n"
           "\tBurst write to main memory : %d cycles\n"
           "\tHardware FIFO write        : %d cycles\n"
           "\tHardware FIFO read         : %d cycles\n",
	   SIZE, readtime, writetime, puttime, gettime); 


    return 0;

}
