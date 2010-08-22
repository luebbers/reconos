///
/// \file hw_thread.c
///
/// ReconOS hardware thread implementation file
///
/// Contains function definitions
///
/// \author     Enno Luebbers <enno.luebbers@uni-paderborn.de>
/// \date       08.08.2006
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//
// Major changes
// 08.08.2006	Enno Luebbers       File created
// 20.03.2006	Enno Luebbers       added semaphore array to structure
// 28.03.2007	Enno Luebbers       added to eCos repository
// 02.04.2007	Enno luebbers       extended to C++, inherits from Cyg_Thread
// 22.06.2007	Enno Luebbers       Added generic resource management
// 11.07.2007   Enno Luebbers       added mutex commands
// 27.07.2007   Enno Luebbers       added condition variable commands
// 16.10.2007   Enno Luebbers       added hardware mailbox support
// 27.11.2007	Enno Luebbers       added routines for DCR OSIF
//                                  communications
// 20.12.2007   Enno Luebbers       added POSIX compatibility routines
// 21.01.2008   Enno Luebbers       ported to Linux
// 22.08.2010   Andreas Agne        Added virtual memory related functions
//
#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <pthread.h>
#include <mqueue.h>
#include <semaphore.h>
#include <errno.h>

#include <reconos.h>
#include <resources.h>

// CONSTANTS AND MACROS ///////////////////////////////////////////////////

// Macros for OSIF bus communications
#define OSIF_READ(hwt, reg)            XIo_DcrIn(hwt->dcrBaseAddr + reg)
#define OSIF_WRITE(hwt, reg, value)    XIo_DcrOut(hwt->dcrBaseAddr + reg, value)
#define OSIF_REG_COMMAND       0
#define OSIF_REG_DATA          1
#define OSIF_REG_DONE          2
#define OSIF_REG_DATAX         2

// debugging constants
#define HWTHREAD_DEBUG 1
#define HWTHREAD_ENABLE_ASSERTIONS 1

#ifdef HWTHREAD_ENABLE_ASSERTIONS
// debugging, print error on failed assertions
#define HWTHREAD_ASSERT(x,y) if (! (x)) fprintf(stderr, "ASSERT failed: %s\n", y)
#define HWTHREAD_FAIL(x) fprintf(stderr, "FAIL: %s\n", x)
#else
// no debugging, do nothing
#define HWTHREAD_ASSERT(x,y)
#define HWTHREAD_FAIL(x)
#endif


// slv_osif2bus_command & slv_osif2bus_flags & slv_osif2bus_saved_state_enc & slv_osif2bus_saved_step_enc & "000000"
// constant C_OSIF_CMD_WIDTH       : natural := 8;
// constant C_OSIF_FLAGS_WIDTH     : natural := 8;   -- flags (such as ready to yield)
// constant C_OSIF_STATE_ENC_WIDTH : natural := 8;   -- max 256 state
// constant C_OSIF_STEP_ENC_WIDTH : natural := 2;   -- max 4 steps

#define OSIF_COMMAND_MASK 0xFF000000
#define OSIF_FLAGS_MASK   0x00FF0000
#define OSIF_STATE_MASK   0x0000FF00
#define OSIF_STEP_MASK    0x000000C0

//static reconos_tlb_t default_tlb;
//volatile unsigned int _flush_mem[1024*4];
#define FLUSH_MEM_SIZE 16*1024*1024
volatile unsigned int _flush_mem[FLUSH_MEM_SIZE];
// PROTOTYPES //////////////////////////////////////////////////////////////


// FUNCTION DEFINITIONS ////////////////////////////////////////////////////

static void flush_dcache(){
	int i;
	for(i = 0; i < FLUSH_MEM_SIZE; i += 8){
		_flush_mem[i]++;
	}
}

static void set_os2task(osif_os2task_t *buf, uint32 command, uint32 data) {
	buf->command = command;
	buf->data = data;
	buf->cmdnew = 0xFFFFFFFF;
}

/*
unsigned long getpgd(void){
	unsigned long result;
	int fd, retval;
	
	fd = open("/dev/getpgd", O_RDONLY);
	if(fd < 0){
		perror("open /dev/getpgd");
		return 0;
	}

	retval = read(fd, &result, 4);
	if(retval != 4){
		perror("read /dev/getpgd");
		close(fd);
		return 0;
	}

	close(fd);
	return result - 0xC0000000; // kernel space -> physical addr
}
*/

//----------------------------------------------------------------------
// Delegate Thread
//----------------------------------------------------------------------

void *reconos_delegateThread (void *data) {

	reconos_hwthread *hwt = data;
	osif_task2os_t request;
	osif_os2task_t response;
	uint32 retval;
	off_t off;
	int fd,i;
	mqd_t *q;
	unsigned long pgd;

	fd = hwt->osif_fd;

	// reset osif
#ifdef HWTHREAD_DEBUG
	fprintf(stderr, "resetting osif in slot %d\n", hwt->slot_num);
#endif
	set_os2task(&response, OSIF_CMD_RESET, (uint32)0);
	if (write(fd, &response, sizeof(response)) != sizeof(response)) {
		perror("error while writing data to OSIF");
	}

	// pass initialization data to hardware thread
#ifdef HWTHREAD_DEBUG
	fprintf(stderr, "initializing hardware in slot %d with data 0x%08X\n", hwt->slot_num, (uint32)(hwt->init_data));
#endif
	set_os2task(&response, OSIF_CMD_SET_INIT_DATA, (uint32)(hwt->init_data));
	if (write(fd, &response, sizeof(response)) != sizeof(response)) {
		perror("error while writing data to OSIF");
	}

	// enable bus macros
	set_os2task(&response, OSIF_CMD_BUSMACRO, OSIF_DATA_BUSMACRO_ENABLE);
	if (write(fd, &response, sizeof(response)) != sizeof(response)) {
		perror("error while writing data to OSIF");
	}

	// write local FIFO handles
	set_os2task(&response,
	            OSIF_CMD_SET_FIFO_READ_HANDLE,
	            hwt->fifoRead_resNum);
	if (write(fd, &response, sizeof(response)) != sizeof(response)) {
		perror("error while writing data to OSIF");
	}
	set_os2task(&response,
	            OSIF_CMD_SET_FIFO_WRITE_HANDLE,
	            hwt->fifoWrite_resNum);
	if (write(fd, &response, sizeof(response)) != sizeof(response)) {
		perror("error while writing data to OSIF");
	}


	// set pgd
	//pgd = getpgd();
	//if(pgd){
	set_os2task(&response, OSIF_CMD_MMU_SETPGD, 0);
	if (write(fd, &response, sizeof(response)) != sizeof(response)) {
		perror("error while writing data to OSIF");
	}
	//}

	tlb_init(hwt);
	//tlb_setid(hwt->tlb,pgd);
	
	// unblock hardware
	set_os2task(&response, OSIF_CMD_UNBLOCK, 0x00000000);
	if (write(fd, &response, sizeof(response)) != sizeof(response)) {
		perror("error while writing data to OSIF");
	}

	//
	// main thread loop
	//
	for (;;) {

		off = lseek(fd, 0, SEEK_SET);
		if(off == (off_t)-1){
			perror("lseek: error while reading data from OSIF\n");
		}
		// read command and data (this blocks until there is new data
		if (read(fd, &request, sizeof(request)) != sizeof(request)) {
			perror("error while reading data from OSIF");
		}


#ifdef HWTHREAD_DEBUG
		printf("**task in slot %d:**\n  cmd: 0x%08X, data: 0x%08X, datax: 0x%08X\n", hwt->slot_num, request.command, request.data, request.datax);
#endif

		request.command = request.command & OSIF_COMMAND_MASK;
		
		switch (request.command) {
			//---------------
			// reconos_semaphore_post()
			//---------------
		case OSIF_CMD_SEM_POST:
			//		  	printf("Incoming semaphore post request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Semaphore post operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_SEM_T:
				sem_post((sem_t*) hwt->resources[request.data].ptr);
				break;
			default:
				HWTHREAD_FAIL ("Semaphore operation requested on invalid resource type!" );
			}
			//			printf("executed.\n");
			break;

			//---------------
			// reconos_semaphore_wait()
			// This is a blocking call
			//---------------
		case OSIF_CMD_SEM_WAIT:
			//			printf("Incoming semaphore wait request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Semaphore wait operation requested on non-existing resource!" );
			switch(hwt->resources[request.data].type) {
			case PTHREAD_SEM_T:
				sem_wait((sem_t*) hwt->resources[request.data].ptr);
				break;
			default:
				HWTHREAD_FAIL ( "Semaphore operation requested on invalid resource type!" );
			}
			//			printf("executed.\n");

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, 0x00000001);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_mutex_lock()
			// This is a blocking call
			//---------------
		case OSIF_CMD_MUTEX_LOCK:
			//			printf("Incoming mutex lock request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mutex lock operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_MUTEX_T:
				retval = !pthread_mutex_lock((pthread_mutex_t*) hwt->resources[request.data].ptr);
				break;
			default:
				HWTHREAD_FAIL ("Mutex lock operation requested on invalid resource type!" );
			}
			//			printf("executed. Returned 0x%08X.\n", retval);

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_mutex_trylock()
			// This looks to the HW thread like a blocking call,
			// so that we can pass a return value.
			//---------------
		case OSIF_CMD_MUTEX_TRYLOCK:
			//			printf("Incoming mutex trylock request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mutex trylock operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_MUTEX_T:
				retval = !pthread_mutex_trylock((pthread_mutex_t*) hwt->resources[request.data].ptr);
				break;
			default:
				HWTHREAD_FAIL( "Mutex trylock operation requested on invalid resource type!" );
			}
			//			printf("executed. Returned 0x%08X.\n", retval);

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_mutex_unlock()
			//---------------
		case OSIF_CMD_MUTEX_UNLOCK:
			//			printf("Incoming mutex unlock request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mutex unlock operation requested on non-existing resource!" );

			switch (hwt->resources[request.data].type) {
			case PTHREAD_MUTEX_T:
				pthread_mutex_unlock((pthread_mutex_t*) hwt->resources[request.data].ptr);
				break;
			default:
				HWTHREAD_FAIL( "Mutex unlock operation requested on invalid resource type!" );
			}
			//			printf("executed.\n");
			break;

			//---------------
			// reconos_mutex_release()
			//---------------
		case OSIF_CMD_MUTEX_RELEASE:
			//			printf("Incoming mutex release request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mutex release operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_MUTEX_T:
				HWTHREAD_FAIL( "POSIX Mutexes do not support 'release'." );
				break;
			default:
				HWTHREAD_FAIL( "Mutex release operation requested on invalid resource type!" );
			}
			//			printf("executed.\n");
			break;

			//---------------
			// reconos_cond_wait()
			// This is a blocking call
			//---------------
		case OSIF_CMD_COND_WAIT:
			//			printf("Incoming condvar wait request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Condvar wait operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_COND_T:
				// FIXME: We currently assume that the mutex associated with this condvar is
				//        stored in the preceeding resource. This is dangerous.
				if (hwt->resources[request.data-1].type != PTHREAD_MUTEX_T) {
					HWTHREAD_FAIL( "Mutex must precede CondVar." );
				}
				retval = !pthread_cond_wait((pthread_cond_t*) hwt->resources[request.data].ptr,
				                            (pthread_mutex_t*) hwt->resources[request.data-1].ptr);
				break;
			default:
				HWTHREAD_FAIL( "Condvar wait operation requested on invalid resource type!" );
			}
			//			printf("executed. Returned 0x%08X.\n", retval);

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_cond_signal()
			//---------------
		case OSIF_CMD_COND_SIGNAL:
			//			printf("Incoming condvar signal request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Condvar signal operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_COND_T:
				pthread_cond_signal((pthread_cond_t*) hwt->resources[request.data].ptr);
				break;
			default:
				HWTHREAD_FAIL( "Condvar signal operation requested on invalid resource type!" );
			}
			//			printf("executed.\n");
			break;

			//---------------
			// reconos_cond_broadcast()
			//---------------
		case OSIF_CMD_COND_BROADCAST:
			//			printf("Incoming condvar broadcast request...");
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Condvar broadcast operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_COND_T:
				pthread_cond_broadcast((pthread_cond_t*) hwt->resources[request.data].ptr);
				break;
			default:
				HWTHREAD_FAIL( "Condvar broadcast operation requested on invalid resource type!" );
			}
			//			printf("executed.\n");
			break;

			//---------------
			// reconos_mbox_get()
			// This is a blocking call
			//---------------
		case OSIF_CMD_MBOX_GET:
#ifdef HWTHREAD_DEBUG
			printf("Incoming mbox get request...");
#endif
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mailbox get operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_MQD_T:
				// FIXME: Currently, we only support sending of single words (32 bits)
				// set queue to be blocking
				q = (mqd_t*)hwt->resources[request.data].ptr;
				struct mq_attr oldattr, newattr;
				mq_getattr(*q, &oldattr);
				newattr = oldattr;
				newattr.mq_flags = newattr.mq_flags & ~O_NONBLOCK;
				mq_setattr(*q, &newattr, NULL);
				if (mq_receive(*q, (char*) &retval, 4, 0) != sizeof(retval)) {
					retval = 0;     // signal error
				}
				// restore old queue attributes
				mq_setattr(*q, &oldattr, NULL);
				break;
			default:
				HWTHREAD_FAIL( "Mailbox get operation requested on invalid resource type!" );
			}
#ifdef HWTHREAD_DEBUG
			printf("executed. Returned 0x%08X.\n", retval);
#endif

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_mbox_tryget()
			// This looks to the HW thread like a blocking call,
			// so that we can pass a return value.
			//---------------
		case OSIF_CMD_MBOX_TRYGET:
#ifdef HWTHREAD_DEBUG
			printf("Incoming mbox tryget request...");
#endif
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mailbox tryget operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_MQD_T:
				// FIXME: Currently, we only support sending of single words (32 bits)
				// set queue to be non-blocking
				q = (mqd_t*)hwt->resources[request.data].ptr;
				struct mq_attr oldattr, newattr;
				mq_getattr(*q, &oldattr);
				newattr = oldattr;
				newattr.mq_flags = newattr.mq_flags | O_NONBLOCK;
				mq_setattr(*q, &newattr, NULL);
				if (mq_receive(*q, (char*) &retval, 4, 0) != sizeof(retval)) {
					retval = 0;     // signal error
				}
				// restore old queue attributes
				mq_setattr(*q, &oldattr, NULL);
				break;
			default:
				HWTHREAD_FAIL( "Mailbox tryget operation requested on invalid resource type!" );
			}
#ifdef HWTHREAD_DEBUG
			printf("executed. Returned 0x%08X.\n", retval);
#endif

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_mbox_put()
			// This is a blocking call
			//---------------
		case OSIF_CMD_MBOX_PUT:
#ifdef HWTHREAD_DEBUG
			printf("Incoming mbox put request...");
#endif
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mailbox put operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_MQD_T:
				// FIXME: Currently, we only support sending of single words (32 bits)
				// set queue to be blocking
				q = (mqd_t*)hwt->resources[request.data].ptr;
				struct mq_attr oldattr, newattr;
				mq_getattr(*q, &oldattr);
				newattr = oldattr;
				newattr.mq_flags = newattr.mq_flags & ~O_NONBLOCK;
				mq_setattr(*q, &newattr, NULL);
				if (mq_send(*q, (char*) &request.datax, 4, 0) < 0) {
					retval = 0;     // signal error
				} else {
					retval = 1;
				}

				// restore old queue attributes
				mq_setattr(*q, &oldattr, NULL);
				break;
			default:
				HWTHREAD_FAIL( "Mailbox put operation requested on invalid resource type!" );
			}
#ifdef HWTHREAD_DEBUG
			printf("executed. Returned 0x%08X.\n", retval);
#endif

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_mbox_tryput()
			// This looks to the HW thread like a blocking call,
			// so that we can pass a return value.
			//---------------
		case OSIF_CMD_MBOX_TRYPUT:
#ifdef HWTHREAD_DEBUG
			printf("Incoming mbox tryput request...");
#endif
			HWTHREAD_ASSERT (request.data < hwt->numResources,
			                 "Mailbox tryput operation requested on non-existing resource!" );
			switch (hwt->resources[request.data].type) {
			case PTHREAD_MQD_T:
				// FIXME: Currently, we only support sending of single words (32 bits)
				// set queue to be non-blocking
				q = (mqd_t*)hwt->resources[request.data].ptr;
				struct mq_attr oldattr, newattr;
				mq_getattr(*q, &oldattr);
				newattr = oldattr;
				newattr.mq_flags = newattr.mq_flags | O_NONBLOCK;
				mq_setattr(*q, &newattr, NULL);
				if (mq_send(*q, (char*) &request.datax, 4, 0) < 0) {
					retval = 0;     // signal error
				} else {
					retval = 1;
				}
				// restore old queue attributes
				mq_setattr(*q, &oldattr, NULL);
				break;
			default:
				HWTHREAD_FAIL( "Mailbox tryput operation requested on invalid resource type!" );
			}
#ifdef HWTHREAD_DEBUG
			printf("executed. Returned 0x%08X.\n", retval);
#endif

			// unblock hardware
			set_os2task(&response, OSIF_CMD_UNBLOCK, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing data to OSIF");
			}
			break;

			//---------------
			// reconos_thread_exit()
			//---------------
		case OSIF_CMD_THREAD_EXIT:
#ifdef HWTHREAD_DEBUG
			printf("Incoming request to terminate thread...\n");
#endif

			// Reset HW thread
			set_os2task(&response, OSIF_CMD_RESET, 0);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing reset to OSIF");
			}

			// close osif device
			retval = close(fd);
			if (retval < 0) {
				perror("error while closing slot device");
			}

			pthread_exit((void*)request.data);
			break;

		case OSIF_CMD_MMU_FAULT:
#ifdef HWTHREAD_DEBUG
			fprintf(stderr,"Incoming MMU page fault @ 0x%08X...\n", (unsigned int)request.data);
#endif
			retval = *(unsigned int*)request.data; // Zeiger ist ok!
			
			flush_dcache();
			
			hwt->page_faults++;
			

			// repeat PT-walk
			set_os2task(&response, OSIF_CMD_MMU_REPEAT, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing reset to OSIF");
			}
			
			break;

		case OSIF_CMD_MMU_ACCESS_VIOLATION:
#ifdef HWTHREAD_DEBUG
			fprintf(stderr,"Incoming MMU access violation @ 0x%08X...\n", (unsigned int)request.data);
#endif
			*(unsigned int*)request.data = 0;
			
			// if we survived so far, the page is now writable...

			flush_dcache();
			
			hwt->page_faults++;
			

			// repeat... 
			set_os2task(&response, OSIF_CMD_MMU_REPEAT, retval);
			if (write(fd, &response, sizeof(response)) != sizeof(response)) {
				perror("error while writing reset to OSIF");
			}
			
			break;


		default:
			HWTHREAD_FAIL("Delegate thread received unknown command from HW thread");
	
		}

#ifdef HWTHREAD_DEBUG
		printf("<< delegate processing done for task in slot %d\n", hwt->slot_num);
#endif

	}

}

///
/// Creates a pthread with our delegate as entry point
///
int rthread_create( rthread_t *thread,
                    rthread_attr_t *attr,
                    void *arg)
{
	char devname[80];  // FIXME: constant?
	// set init_data from arg
	attr->hwt.init_data = (uint32)arg;
	
	// open slot
	sprintf(devname, "/dev/osif%d", attr->hwt.slot_num);
#ifdef HWTHREAD_DEBUG
	fprintf(stderr, "opening slot %d (%s)\n", attr->hwt.slot_num, devname);
#endif
	attr->hwt.osif_fd = open(devname, O_RDWR);
	if (attr->hwt.osif_fd < 0) {
		fprintf(stderr, "opening slot %d (%s)\n", attr->hwt.slot_num, devname);		
		perror("error while opening slot device");
		return -1;
	}
	
	// create pthread
	return pthread_create(
	               (pthread_t *)thread,
	               (pthread_attr_t *)attr,
	               reconos_delegateThread,
	               &attr->hwt);
}


//
// attribute set/get methods
//
int rthread_attr_init(rthread_attr_t *attr) {
	int retval;

	retval = pthread_attr_init((pthread_attr_t*)attr);

	attr->hwt.resources = NULL;
	attr->hwt.numResources = 0;
	attr->hwt.fifoRead_resNum = 0xFFFFFFFF;
	attr->hwt.fifoWrite_resNum = 0xFFFFFFFF;

	attr->hwt.slot_num = 0;
	attr->hwt.init_data = 0;

	return retval;
}

int rthread_attr_setdetachstate(rthread_attr_t *attr,
                                int detachstate) {
	return pthread_attr_setdetachstate((pthread_attr_t*)attr, detachstate);
}

int rthread_attr_getdetachstate(const rthread_attr_t *attr,
                                int *detachstate) {
	return pthread_attr_getdetachstate((pthread_attr_t*)attr, detachstate);
}
/*
int rthread_attr_setstackaddr(rthread_attr_t *attr,
                              void *stackaddr) {
	return pthread_attr_setstackaddr((pthread_attr_t*)attr, stackaddr);
}

int rthread_attr_getstackaddr(const rthread_attr_t *attr,
                              void **stackaddr) {
	return pthread_attr_getstackaddr((pthread_attr_t*)attr, stackaddr);
}
*/
int rthread_attr_setstacksize(rthread_attr_t *attr,
                              size_t stacksize) {
	return pthread_attr_setstacksize((pthread_attr_t*)attr, stacksize);
}

int rthread_attr_getstacksize(const rthread_attr_t *attr,
                              size_t *stacksize) {
	return pthread_attr_getstacksize((pthread_attr_t*)attr, stacksize);
}


// also sets fiforead and write resnums and numresources
int rthread_attr_setresources(rthread_attr_t *attr,
                              reconos_res_t *resources,
                              uint32 numresources) {
	uint32 i;

	HWTHREAD_ASSERT(attr, "attr == NULL");
	if (resources == NULL) {
		return EINVAL;
	} else {
		// store pointer to resources array (do not copy!)
		attr->hwt.resources = resources;
		// set read/write HW FIFO handles
		for (i = 0; i < numresources; i++) {
			// set fifoRead_resNum and fifoRead_resNum to last encountered
			// appropriate resource
			switch (attr->hwt.resources[i].type) {
			case RECONOS_HWMBOX_READ_T:
				attr->hwt.fifoRead_resNum = i;
				break;
			case RECONOS_HWMBOX_WRITE_T:
				attr->hwt.fifoRead_resNum = i;
				break;
			}
		}
		attr->hwt.numResources = numresources;
		return 0;
	}
}

int rthread_attr_getresources(const rthread_attr_t *attr,
                              reconos_res_t **resources) {
	HWTHREAD_ASSERT(attr, "attr == NULL");
	if (resources == NULL) {
		return EINVAL;
	} else {
		*resources = attr->hwt.resources;
	}
	return 0;
}

int rthread_attr_getnumresources(const rthread_attr_t *attr,
                                 uint32 *numresources) {
	HWTHREAD_ASSERT(attr, "attr == NULL");
	if (numresources == NULL) {
		return EINVAL;
	} else {
		*numresources = attr->hwt.numResources;
	}
	return 0;
}

int rthread_attr_destroy (rthread_attr_t *attr) {
	HWTHREAD_ASSERT(attr, "attr == NULL");
	free(attr->hwt.resources);
	return pthread_attr_destroy((pthread_attr_t*)attr);
}

int rthread_attr_setslotnum(rthread_attr_t *attr, int slot_num) {
	if (slot_num < 0) {
		return EINVAL;
	} else {
		attr->hwt.slot_num = slot_num;
	}
	return 0;
}

int rthread_attr_getslotnum(const rthread_attr_t *attr, int *slot_num) {
	if (slot_num == NULL) {
		return EINVAL;
	} else {
		*slot_num = attr->hwt.slot_num;
	}
	return 0;
}

//int rthread_attr_settlb(rthread_attr_t *attr, reconos_tlb_t *tlb) {
//	HWTHREAD_ASSERT(attr, "attr == NULL");
//	attr->tlb = tlb;
//}

//int rthread_attr_gettlb(rthread_attr_t *attr, reconos_tlb_t **tlb) {
//	HWTHREAD_ASSERT(attr, "attr == NULL");
//	*tlb = attr->tlb;
//	return 0;
//}


int rthread_join(rthread_t thread, void **value_ptr) {
	return pthread_join( (pthread_t)thread, value_ptr);
}

int rthread_attr_setschedparam(const rthread_attr_t *attr, struct sched_param *param) {
	return pthread_attr_setschedparam((pthread_attr_t *)attr, param);
}

