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
//
// Major changes
// 23.06.2006	Enno Luebbers		File created
// 03.08.2006	Enno Luebbers		Added constants for shared memory
// 					initialization (PLB busmaster)
// 03.04.2007	Enno Luebbers		Added kernel API function prototypes
// 22.06.2007	Enno Luebbers		Added generic resource management
// 23.01.2008    Enno Luebbers           ported to Linux
//

#ifndef __RECONOS_H__
#define __RECONOS_H__

#include <resources.h>		// include support for OS resources,
					// like semaphores, mutexes, etc.
#include <pthread.h>

// common data types
typedef unsigned char uint8;
typedef unsigned int uint32;		// on 32-bit architectures

typedef struct osif_task2os_t {
	 uint32 command;
	 uint32 data;
         uint32 datax;
} osif_task2os_t;
 
typedef struct osif_os2task_t {
	 uint32 command;
	 uint32 data;
         uint32 cmdnew;
} osif_os2task_t;

///
/// ReconOS HW Thread C wrapper struct
///
typedef struct reconos_hwthread {
    reconos_res_t   *resources;   /// array of OS resources used by thread
    uint32          numResources; /// number of resources in *resources
    uint32          fifoRead_resNum; /// local resource number for read hardware FIFO
    uint32          fifoWrite_resNum; /// local resource number for write hardware FIFO
    uint32          slot_num;   /// which slot this thread is running on
    uint32          init_data;  /// initial data for thread initialization
} reconos_hwthread;


typedef struct rthread_attr_t {
    pthread_attr_t pattr;       // holds the attributes relevant to pthreads
    reconos_hwthread hwt;       // holds the hwthread relevant properties
} rthread_attr_t;

typedef pthread_t rthread_t;    // they are handled identically

// common constants
// task2os commands
#define OSIF_CMD_SEM_POST       0x00000000
#define OSIF_CMD_SEM_WAIT       0x81000000
#define OSIF_CMD_GET_INIT_DATA  0x40000000
#define OSIF_CMD_MUTEX_LOCK     0x82000000
#define OSIF_CMD_MUTEX_TRYLOCK  0x83000000
#define OSIF_CMD_MUTEX_UNLOCK   0x02000000
#define OSIF_CMD_MUTEX_RELEASE  0x03000000
#define OSIF_CMD_COND_SIGNAL    0x04000000
#define OSIF_CMD_COND_BROADCAST 0x05000000
#define OSIF_CMD_COND_WAIT      0x84000000
#define OSIF_CMD_MBOX_GET       0x85000000
#define OSIF_CMD_MBOX_TRYGET    0x86000000
#define OSIF_CMD_MBOX_PUT       0x87000000
#define OSIF_CMD_MBOX_TRYPUT    0x88000000
#define OSIF_CMD_THREAD_EXIT    0xF0000000

// os2task commands
#define OSIF_CMDNEW            0xFFFFFFFF
#define OSIF_CMD_UNBLOCK       0x00000000
#define OSIF_CMD_SET_INIT_DATA 0x01000000
#define OSIF_CMD_RESET         0x02000000
#define OSIF_CMD_BUSMACRO      0x03000000
#define OSIF_CMD_SET_FIFO_READ_HANDLE	0x04000000
#define OSIF_CMD_SET_FIFO_WRITE_HANDLE	0x05000000


// data constants
#define OSIF_DATA_BUSMACRO_ENABLE  0x00000001
#define OSIF_DATA_BUSMACRO_DISABLE 0x00000000




// C WRAPPER FUNCTIONS //////////////////////////////////////////////////////
//----------------------------------------------------------------
// rthread_create()
// POSIX-like variant of reconos_hwthread_create().
// Used in conjunction with the POSIX compatibility package of
// eCos.
// Most code taken from compat/posix/current/src/pthread.cxx and
// adapted for creation of ReconOS threads.
//----------------------------------------------------------------
int rthread_create ( rthread_t *thread,
                             rthread_attr_t *attr,
                             //void *(*start_routine) (void *),
                             void *arg);

// ATTRIBUTE FUNCTIONS ////////////////////////////////////////////////
int rthread_attr_init(rthread_attr_t *attr); 
int rthread_attr_destroy(rthread_attr_t *attr); 
int rthread_attr_setdetachstate(rthread_attr_t *attr,
                                int detachstate); 
int rthread_attr_getdetachstate(const rthread_attr_t *attr,
	                        int *detachstate); 
int rthread_attr_setstackaddr(rthread_attr_t *attr,
                              void *stackaddr); 
int rthread_attr_getstackaddr(const rthread_attr_t *attr,
	                      void **stackaddr); 
int rthread_attr_setstacksize(rthread_attr_t *attr,
                              size_t stacksize); 
int rthread_attr_getstacksize(const rthread_attr_t *attr,
	                      size_t *stacksize); 

// also sets fiforead and write resnums and numresources
int rthread_attr_setresources(rthread_attr_t *attr,
                              reconos_res_t *resources,
                              uint32 numresources);
int rthread_attr_getresources(const rthread_attr_t *attr,
                              reconos_res_t **resources);
int rthread_attr_getnumresources(const rthread_attr_t *attr,
                                 uint32 *numresources);
int rthread_attr_setslotnum(rthread_attr_t *attr, int slot_num);
int rthread_attr_getslotnum(const rthread_attr_t *attr,
                            int *slot_num);
int rthread_join(rthread_t thread, void **value_ptr);
int rthread_attr_setschedparam(const rthread_attr_t *attr, struct     sched_param *param);

#endif // __RECONOS_H__
