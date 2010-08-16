///
/// \file reconos.h
///
/// ReconOS main header file
///
/// Contains type definitions and general constants.
///
/// \author     Enno Luebbers <enno.luebbers@uni-paderborn.de>
/// \date       23.06.2006
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
#ifndef __RECONOS_H__
#define __RECONOS_H__



#include <pkgconf/reconos.h>
#include <reconos/resources.h>		// include support for OS resources,

#include <cyg/kernel/kapi.h>	// for eCos datatypes
#include <xparameters.h>
#include <xio_dcr.h>

#ifdef UPBFUN_RECONOS_POSIX
#include <pthread.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

// common data types
typedef unsigned char uint8;
typedef unsigned int uint32;		// on 32-bit architectures

#if defined(UPBHWR_OSIF_7_INTR)
#define NUM_OSIFS 8
#elif defined(UPBHWR_OSIF_6_INTR)
#define NUM_OSIFS 7
#elif defined(UPBHWR_OSIF_5_INTR)
#define NUM_OSIFS 6
#elif defined(UPBHWR_OSIF_4_INTR)
#define NUM_OSIFS 5
#elif defined(UPBHWR_OSIF_3_INTR)
#define NUM_OSIFS 4
#elif defined(UPBHWR_OSIF_2_INTR)
#define NUM_OSIFS 3
#elif defined(UPBHWR_OSIF_1_INTR)
#define NUM_OSIFS 2
#elif defined(UPBHWR_OSIF_0_INTR)
#define NUM_OSIFS 1
#else
#define NUM_OSIFS 0
#endif 

#define RTHREAD_ATTR_IS_POSIX    0x00000001
#define RTHREAD_ATTR_IS_DYNAMIC  0x00000002
#define RTHREAD_ATTR_YIELDS      0x00000004
#define RTHREAD_ATTR_RECONFIGURE 0x00000008

// os2task commands
#define OSIF_CMDNEW            0xFFFFFFFF
#define OSIF_CMD_UNBLOCK       0x00000000
#define OSIF_CMD_SET_INIT_DATA 0x01000000
#define OSIF_CMD_RESET         0x02000000
#define OSIF_CMD_BUSMACRO      0x03000000
#define OSIF_CMD_SET_FIFO_READ_HANDLE	0x04000000
#define OSIF_CMD_SET_FIFO_WRITE_HANDLE	0x05000000
#define OSIF_CMD_SET_RESUME_STATE      0x06000000
#define OSIF_CMD_CLEAR_RESUME_STATE    0x07000000
#define OSIF_CMD_REQUEST_YIELD         0x08000000
#define OSIF_CMD_CLEAR_YIELD           0x09000000

// osif flags
#define OSIF_FLAGS_YIELD 0x80 

// data constants
#define OSIF_DATA_BUSMACRO_ENABLE  0x00000001
#define OSIF_DATA_BUSMACRO_DISABLE 0x00000000


#ifdef UPBFUN_RECONOS_PARTIAL


///
/// Bitstream data structure
///
/// Holds information about a particular bitstream
///
typedef struct reconos_bitstream {
    unsigned char   slot_num;   // slot number this bitstream was
                                // synthesized for
    unsigned char   *data;      // bitstream data
    size_t          size;       // bitstream length in bytes
	unsigned char *filename;	// filename (for ecap)
} reconos_bitstream_t;


///
/// Circuit data structure
///
/// Encapsulates multiple bitstreams for the same circuit,
/// e.g., synthesized for different locations
///
typedef struct reconos_circuit {
    unsigned char *name;        // descriptive name
    unsigned char   num_bitstreams; // number of bitstreams
#ifdef UPBFUN_RECONOS_CHECK_HWTHREAD_SIGNATURE
	uint32           signature;			// hardware thread signature, for debugging
#endif
    reconos_bitstream_t *bitstreams[];   // array of available bitstreams,
                                // e.g. one for each slot
} reconos_circuit_t;
#endif // RECONOS_PARTIAL


/// Slot state
typedef enum slot_state {
    FREE,
    READY,
    RUNNING
} slot_state_t;

// forward declaration
struct rthread_attr;
typedef struct rthread_attr rthread_attr_t;

///
/// Slot data structure
///
/// Holds low-level hardware information as well as
/// the current slot state and pointers to running
/// threads and loaded circuits
///
typedef struct reconos_slot {
    unsigned char   num;        // this slot's number
    uint32          dcr_base_addr;      // osif dcr base address
    uint32          plb_base_addr;
    cyg_interrupt   interrupt;          // osif interrupt
    cyg_handle_t    interrupt_handle;   // osif interrupt handle
    cyg_vector_t    interrupt_vector;   // osif interrupt vector
    uint32          interrupt_count;
    cyg_mutex_t     mutex;             // osif slot mutex (to "atomize" accesses)
    slot_state_t    state;      // current slot state
    rthread_attr_t  *thread;     // current thread
} reconos_slot_t;


typedef struct osif_task2os_command {
        uint8 code;                     // the command code (8 bit)
        uint8 flags;                    // the command flags (8 bit)
        uint8 saved_state_enc;          // the encoded state of the thread's OS sync FSM (8 bit)
        unsigned saved_step_enc :2;     // the encoded step of the current command (2 bit)
        unsigned reserved       :6;     // padding to the end of the word
} osif_task2os_command_t;


typedef struct osif_task2os {
        osif_task2os_command_t command;
	uint32 data;
	uint32 datax;
} osif_task2os_t;



// ReconOS hardware thread attributes
struct rthread_attr {
	cyg_addrword_t   init_data;          // initialization data passed to thread
        reconos_slot_t   *slot;	
	cyg_sem_t        delegate_semaphore; // semaphore to post on interrupt
	reconos_res_t   *resources;          // array of resource pointers used by the thread
	uint32           resource_count;     // length of resource array
	uint32           fifo_read_index;
	uint32           fifo_write_index;
	uint32           flags;
        osif_task2os_command_t saved_command;
        rthread_attr_t   *next;              // for maintaining a list of all hw threads
        uint8            *state_buf;         // for saving local memory during thread suspension
        uint32           state_size;         // how much state to save upon suspending the thread
#ifdef UPBFUN_RECONOS_PARTIAL
        reconos_circuit_t *circuit;
#endif
};


void reconos_hwthread_create(
	cyg_addrword_t sched_info,
	rthread_attr_t * attr,     // here is the difference to cyg_thread_create:
				  // since supplying an entry point for the delegate thread
				  // makes no sense (it is fixed in the reconos implementation), we
				  // pass a pointer to the rthread_attr_t struct instead.
	cyg_addrword_t init_data,
	char* name,
	void* stack_base,
	cyg_ucount32 stack_size,
	cyg_handle_t* handle,
	cyg_thread* thread
);

#ifdef UPBFUN_RECONOS_POSIX
int rthread_create(pthread_t *thread,
	const pthread_attr_t * attr,
	rthread_attr_t * hw_attr,
	void *arg);
#endif

void reconos_init_slots(void);
void reconos_delete_slots(void);

int rthread_attr_init(rthread_attr_t * attr);
int rthread_attr_setstatesize(rthread_attr_t *attr, cyg_uint32 state_size);
int rthread_attr_getstatesize(rthread_attr_t *attr, cyg_uint32 *state_size);
int rthread_attr_setbaseaddr(rthread_attr_t *attr, cyg_uint32 baseaddr);
int rthread_attr_getbaseaddr(const rthread_attr_t *attr, cyg_uint32 *baseaddr);
int rthread_attr_setintrvector(rthread_attr_t *attr, cyg_vector_t intrvector);
int rthread_attr_getintrvector(const rthread_attr_t *attr, cyg_vector_t *intrvector);

// also sets fiforead and write resnums and numresources
int rthread_attr_setresources(rthread_attr_t *attr, reconos_res_t * res, unsigned int res_count);
int rthread_attr_getresources(const rthread_attr_t *attr, reconos_res_t **resources);
int rthread_attr_getnumresources(const rthread_attr_t *attr, cyg_uint32 *numresources);
int rthread_attr_setslotnum(rthread_attr_t *attr, int slot_num);
int rthread_attr_getslotnum(const rthread_attr_t *attr, int *slot_num);
#ifdef UPBFUN_RECONOS_PARTIAL
int rthread_attr_setcircuit(rthread_attr_t *attr, reconos_circuit_t* circuit);
int rthread_attr_getcircuit(const rthread_attr_t *attr, reconos_circuit_t** circuit);
reconos_bitstream_t *get_bit_for_slot( rthread_attr_t *t, reconos_slot_t *s );
#endif

void rthread_attr_dump(rthread_attr_t * hwt);

#ifdef __cplusplus
} // extern "C"
#endif


#endif // __RECONOS_H__
