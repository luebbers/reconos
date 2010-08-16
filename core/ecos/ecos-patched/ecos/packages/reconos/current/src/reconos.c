///
/// \file reconos.c
///
/// This file contains the delegate thread code and API functions for
/// thread management used by ReconOS/eCos.
///
/// \author     Andreas Agne    <agne@upb.de>
/// \date       28.03.2008
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
// Major Changes:
//
// 28.03.2008   Andreas Agne    File adapted from hw_thread.c
// 09.10.2008   Andreas Agne    Added POSIX message queue handling
// 30.10.2008   Enno Luebbers   Moved delegate thread code to delegate.c
// 28.01.2009   Enno Luebbers   Added support for partial reconfiguration

#include <reconos/reconos.h>

#include <cyg/infra/cyg_type.h>		// for types and __externC
#include <cyg/kernel/kapi.h>
#include <stdlib.h>
#include <stdio.h>
#include <cyg/infra/diag.h>
#include <string.h>

#ifdef UPBFUN_RECONOS_POSIX
#include <cyg/posix/types.h>
#include <cyg/posix/pthread.h>
#endif

#ifdef UPBFUN_RECONOS_PARTIAL
#include <reconos/hw_sched.h>
#endif

// DCR base addresses
#ifdef XPAR_OSIF_0_DCR_BASEADDR
static unsigned int OSIF_DCR_BASEADDR[] = {
    XPAR_OSIF_0_DCR_BASEADDR
#ifdef XPAR_OSIF_1_DCR_BASEADDR
    ,  XPAR_OSIF_1_DCR_BASEADDR
#ifdef XPAR_OSIF_2_DCR_BASEADDR
    ,  XPAR_OSIF_2_DCR_BASEADDR
#ifdef XPAR_OSIF_3_DCR_BASEADDR
    ,  XPAR_OSIF_3_DCR_BASEADDR
#ifdef XPAR_OSIF_4_DCR_BASEADDR
    ,  XPAR_OSIF_4_DCR_BASEADDR
#ifdef XPAR_OSIF_5_DCR_BASEADDR
    ,  XPAR_OSIF_5_DCR_BASEADDR
#ifdef XPAR_OSIF_6_DCR_BASEADDR
    ,  XPAR_OSIF_6_DCR_BASEADDR
#ifdef XPAR_OSIF_7_DCR_BASEADDR
    ,  XPAR_OSIF_7_DCR_BASEADDR
#ifdef XPAR_OSIF_8_DCR_BASEADDR
#error max 7 slots supported. Change this file to support more
#endif // XPAR_OSIF_8_DCR_BASEADDR
#endif // XPAR_OSIF_7_DCR_BASEADDR
#endif // XPAR_OSIF_6_DCR_BASEADDR
#endif // XPAR_OSIF_5_DCR_BASEADDR
#endif // XPAR_OSIF_4_DCR_BASEADDR
#endif // XPAR_OSIF_3_DCR_BASEADDR
#endif // XPAR_OSIF_2_DCR_BASEADDR
#endif // XPAR_OSIF_1_DCR_BASEADDR
};
#define LOOKUP_SLOT_BASEADDR(x) (OSIF_DCR_BASEADDR[x])
#else
#error no slots present in xparameters. Did you generate the BSP?
#endif // XPAR_OSIF_0_DCR_BASEADDR

// PLB base addresses
static unsigned int OSIF_PLB_BASEADDR[] = {
#ifdef XPAR_OSIF_0_BASEADDR
	XPAR_OSIF_0_BASEADDR
#else
	0
#endif

#ifdef XPAR_OSIF_1_BASEADDR
	,  XPAR_OSIF_1_BASEADDR
#else
	, 0
#endif

#ifdef XPAR_OSIF_2_BASEADDR
	,  XPAR_OSIF_2_BASEADDR
#else
	, 0
#endif

#ifdef XPAR_OSIF_3_BASEADDR
	,  XPAR_OSIF_3_BASEADDR
#else
	, 0
#endif

#ifdef XPAR_OSIF_4_BASEADDR
	,  XPAR_OSIF_4_BASEADDR
#else
	, 0
#endif

#ifdef XPAR_OSIF_5_BASEADDR
	,  XPAR_OSIF_5_BASEADDR
#else
	, 0
#endif

#ifdef XPAR_OSIF_6_BASEADDR
	,  XPAR_OSIF_6_BASEADDR
#else
	, 0
#endif

#ifdef XPAR_OSIF_7_BASEADDR
	,  XPAR_OSIF_7_BASEADDR
#else
	, 0
#endif

#ifdef XPAR_OSIF_8_BASEADDR
#error max 7 slots supported. Change this file to support more
#endif // XPAR_OSIF_1_PLB_BASEADDR
};
#define LOOKUP_PLB_BASEADDR(x) (OSIF_PLB_BASEADDR[x])


// interrupt numbers
#ifdef UPBHWR_OSIF_0_INTR
static unsigned int OSIF_INTERRUPT[] = {
    UPBHWR_OSIF_0_INTR
#ifdef UPBHWR_OSIF_1_INTR
    ,  UPBHWR_OSIF_1_INTR
#ifdef UPBHWR_OSIF_2_INTR
    ,  UPBHWR_OSIF_2_INTR
#ifdef UPBHWR_OSIF_3_INTR
    ,  UPBHWR_OSIF_3_INTR
#ifdef UPBHWR_OSIF_4_INTR
    ,  UPBHWR_OSIF_4_INTR
#ifdef UPBHWR_OSIF_5_INTR
    ,  UPBHWR_OSIF_5_INTR
#ifdef UPBHWR_OSIF_6_INTR
    ,  UPBHWR_OSIF_6_INTR
#ifdef UPBHWR_OSIF_7_INTR
    ,  UPBHWR_OSIF_7_INTR
#endif // UPBHWR_OSIF_7_INTR
#endif // UPBHWR_OSIF_6_INTR
#endif // UPBHWR_OSIF_5_INTR
#endif // UPBHWR_OSIF_4_INTR
#endif // UPBHWR_OSIF_3_INTR
#endif // UPBHWR_OSIF_2_INTR
#endif // UPBHWR_OSIF_1_INTR
};
#define LOOKUP_SLOT_IRQ(x) (OSIF_INTERRUPT[x])
#endif // UPBHWR_OSIF_0_INTR

#define NUM_SLOTS (sizeof OSIF_INTERRUPT / sizeof OSIF_INTERRUPT[0])


// for the thread destructors
extern void osif_set_busmacro(reconos_slot_t *s, int value);


reconos_slot_t reconos_slots[NUM_SLOTS];
#ifdef UPBFUN_RECONOS_PARTIAL
extern cyg_mutex_t reconos_hwsched_mutex;
extern cyg_cond_t  reconos_hwsched_condvar;
extern cyg_sem_t   reconos_hwsched_semaphore;
#endif


// FUNCTION PROTOTYPES======================================================

// FIXME: should this be moved to a header file?
void reconos_delegate_thread(cyg_addrword_t data); // defined in delegate.c

// FUNCTIONS ===============================================================

// ISR for ReconOS interrupt
cyg_uint32 reconos_interrupt_isr (cyg_vector_t vector, cyg_addrword_t data)
{
	cyg_interrupt_mask (vector);
	cyg_interrupt_acknowledge (vector);
	((reconos_slot_t*)data)->interrupt_count++;
	return (CYG_ISR_HANDLED | CYG_ISR_CALL_DSR);
}

// DSR for ReconOS interrupt
void reconos_interrupt_dsr (cyg_vector_t vector, cyg_ucount32 count, cyg_addrword_t data)
{
        reconos_slot_t *slot = (reconos_slot_t*)data;
	CYG_ASSERT(slot, "slot == NULL");
	rthread_attr_t *hwt  = slot->thread;
	CYG_ASSERT(hwt, "hwt == NULL");
    	cyg_semaphore_post(&(hwt->delegate_semaphore));
	cyg_interrupt_unmask (vector);
}



#ifdef CYGPKG_KERNEL_THREADS_DESTRUCTORS
void reconos_delegate_thread_destructor(cyg_addrword_t data)
{
    rthread_attr_t *hwt = (rthread_attr_t*)data;
#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("destroying thread @ 0x%08X\n", (uint32)hwt);
#endif

#ifdef UPBFUN_RECONOS_PARTIAL
    if (!cyg_mutex_lock(&reconos_hwsched_mutex)) {
        CYG_FAIL("mutex lock failed, aborting thread\n");
    } else {
        if (hwt->flags & RTHREAD_ATTR_IS_DYNAMIC) {
            // lock osif mutex
            if (!cyg_mutex_lock(&(hwt->slot->mutex))) {
                CYG_FAIL("osif mutex lock failed, aborting thread\n");
            };
           // disable bus macros
#ifdef UPBDBG_RECONOS_DEBUG
            diag_printf("diabling bus macros on thread @0x%08X\n", (uint32)hwt);
#endif
            osif_set_busmacro(hwt->slot, 0);
            cyg_mutex_unlock(&(hwt->slot->mutex));
#ifdef UPBDBG_RECONOS_DEBUG
            diag_printf("setting slot %d state to FREE\n", hwt->slot->num);
#endif
            hwt->slot->state = FREE;
            hwt->slot->thread = NULL;
            hwt->slot = NULL;
        } else {
            hwt->slot->state = READY;
        }
        // unregister hw thread
        reconos_unregister_hwthread( hwt );
        cyg_semaphore_post(&reconos_hwsched_semaphore);
        cyg_mutex_unlock(&reconos_hwsched_mutex);
    }
#endif

    cyg_semaphore_destroy (&(hwt->delegate_semaphore));
}
#else
#error We need kernel destructors!
#endif


void rthread_attr_dump(rthread_attr_t * hwt){
        diag_printf("--------------------------------------");
        diag_printf("self = 0x%08X\n", (uint32)hwt);
	diag_printf("init_data = 0x%08X\n", hwt->init_data);
	diag_printf("delegate_semaphore = 0x%08X\n", *(uint32*)&hwt->delegate_semaphore);
        if (hwt->slot) {
            diag_printf("slot num = %d\n", hwt->slot->num);
            diag_printf("slot = 0x%08X\n", (uint32)(hwt->slot));
            diag_printf("slot->thread = 0x%08X\n", (uint32)(hwt->slot->thread));
        } else {
            diag_printf("not associated with a slot\n");
        }
	diag_printf("resources = 0x%08X\n", (uint32)hwt->resources);
	diag_printf("resource_count = 0x%08X\n", hwt->resource_count);
	diag_printf("fifo_read_index = 0x%08X\n", hwt->fifo_read_index);
	diag_printf("fifo_write_index = 0x%08X\n", hwt->fifo_write_index);
        diag_printf("flags = 0x%08X\n", hwt->flags);
        diag_printf("next = 0x%08X\n", (uint32)hwt->next);
}


#ifndef EINVAL
#define EINVAL (-1)
#endif


///
/// Initialize slot
///
/// Sets up interrupt handlers and data structures for a slot
///
void reconos_init_slot(unsigned char i) {
    CYG_REPORT_FUNCTION();
    CYG_ASSERT(i < NUM_SLOTS, "i >= NUM_SLOTS");

#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("initializing slot %d:\n"
            "\tdcr base   = 0x%08X\n"
            "\tplb base   = 0x%08X\n"
            "\tirq_vector = %d\n",
            i, 
            LOOKUP_SLOT_BASEADDR(i),
            LOOKUP_PLB_BASEADDR(i),
            LOOKUP_SLOT_IRQ(i) + 1 );
#endif

    reconos_slots[i].num              = i;
    reconos_slots[i].dcr_base_addr    = LOOKUP_SLOT_BASEADDR(i); 
    reconos_slots[i].plb_base_addr    = LOOKUP_PLB_BASEADDR(i);
    reconos_slots[i].interrupt_vector = LOOKUP_SLOT_IRQ(i) + 1;
    reconos_slots[i].state            = FREE;
    reconos_slots[i].thread           = NULL;
#ifdef UBFUN_RECONOS_PARTIAL
//    reconos_slots[i].circuit          = NULL;
#endif
    reconos_slots[i].interrupt_count  = 0;

#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("\t mutex...");
    cyg_mutex_init( &(reconos_slots[i].mutex) );
    diag_printf("done (0x%08X)\n", (uint32)(&(reconos_slots[i].mutex)));
#endif

    cyg_interrupt_create( reconos_slots[i].interrupt_vector,
            0,
            (cyg_addrword_t)&reconos_slots[i],
            &reconos_interrupt_isr,
            &reconos_interrupt_dsr,
            &(reconos_slots[i].interrupt_handle),
            &(reconos_slots[i].interrupt)
            );

    cyg_interrupt_attach(reconos_slots[i].interrupt_handle);
    // enable interrupt
    cyg_interrupt_unmask(reconos_slots[i].interrupt_vector);
    CYG_REPORT_RETURN();
}

///
/// Delete slot
///
/// Unregisters interrupt handler for a slot
///
void reconos_delete_slot(unsigned char i) {
    CYG_ASSERT(i < NUM_SLOTS, "i >= NUM_SLOTS");

    cyg_interrupt_mask(reconos_slots[i].interrupt_vector);
    cyg_interrupt_detach(reconos_slots[i].interrupt_handle);
    cyg_interrupt_delete(reconos_slots[i].interrupt_handle);
}

    
///
/// Initialize slots
///
/// Initializes all slots and the scheduler
///
void reconos_init_slots(void) {
    int i;

    for (i = 0; i < NUM_SLOTS; i++) {
        reconos_init_slot(i);
    }

#ifdef UPBFUN_RECONOS_PARTIAL
    reconos_hwsched_init();
#endif
}

///
/// Delete slots
///
/// Unregisters all slots
///
void reconos_delete_slots(void) {
    int i;

    for (i = 0; i < NUM_SLOTS; i++) {
        reconos_delete_slot(i);
    }

#ifdef UPBFUN_RECONOS_PARTIAL
    reconos_hwsched_destroy();
#endif
}



void reconos_hwthread_create(
		cyg_addrword_t sched_info,
		rthread_attr_t * hwt,
		cyg_addrword_t init_data,
		char* name,
		void* stack_base,
		cyg_ucount32 stack_size,
		cyg_handle_t* handle,
		cyg_thread* thread)
{
	hwt->init_data = init_data;
	
	cyg_thread_create(
			sched_info,
			reconos_delegate_thread,
			(cyg_addrword_t)hwt,
			name,
			stack_base,
			stack_size,
			handle,
			thread);	
		

	// set up delegate semaphore
	cyg_semaphore_init (&(hwt->delegate_semaphore), 0);

#ifdef UPBFUN_RECONOS_PARTIAL
        // insert thread in list of HW threads
        reconos_register_hwthread( hwt );
#endif

}

void * reconos_delegate_thread_posix(void * arg)
{
	reconos_delegate_thread((cyg_addrword_t)arg);
	return NULL;
}

#ifdef UPBFUN_RECONOS_POSIX
int rthread_create(pthread_t *thread, const pthread_attr_t * attr, rthread_attr_t * hwt, void *arg)
{	
/*	cyg_interrupt_create( hwt->interrupt_vector,
			      0,
			      (cyg_addrword_t)hwt,
			      &reconos_interrupt_isr,
			      &reconos_interrupt_dsr,
			      &(hwt->interrupt_handle),
			      &(hwt->interrupt)
			    );
	
	cyg_interrupt_attach(hwt->interrupt_handle);
*/	
	// set up delegate semaphore
	cyg_semaphore_init (&(hwt->delegate_semaphore), 0);
/*	
	// enable interrupt
	cyg_interrupt_unmask(hwt->interrupt_vector);
*/	
	hwt->init_data = (cyg_addrword_t)arg;
	hwt->flags |= RTHREAD_ATTR_IS_POSIX;
#ifdef UPBFUN_RECONOS_PARTIAL
        // insert thread in list of HW threads
        reconos_register_hwthread( hwt );
#endif
	int error = pthread_create(thread, attr, reconos_delegate_thread_posix, hwt);
	if(error) return error;
	return 0;
}
#endif

int rthread_attr_init(rthread_attr_t * attr)
{
	CYG_ASSERT(attr, "attr == NULL");
	attr->resources         = NULL;
	attr->resource_count    = 0;
	attr->fifo_read_index   = 0xFFFFFFFF;
	attr->fifo_write_index  = 0xFFFFFFFF;
	attr->flags             = 0;
        attr->slot       = NULL;
        attr->state_buf  = NULL;
        attr->state_size = 0;
#ifdef UPBFUN_RECONOS_PARTIAL
        attr->circuit    = NULL;
#endif
        return 0;
}

int rthread_attr_setstatesize(rthread_attr_t *attr, cyg_uint32 state_size)
{
	CYG_ASSERT(attr, "attr == NULL");
        if (state_size > 16384) {
		return EINVAL;
	} else {
            if (attr->state_buf != NULL) {
                free(attr->state_buf);
                attr->state_buf = NULL;
                attr->state_size = 0;
            }
            if (state_size == 0) {
                return 0;
            }
            attr->state_buf = malloc(state_size);
            if (attr->state_buf == NULL) {
                return ENOMEM;
            } else {
                attr->state_size = state_size;
                return 0;
            }
	}
}

int rthread_attr_getstatesize(rthread_attr_t *attr, cyg_uint32 *state_size)
{
	CYG_ASSERT(attr, "attr == NULL");
        if (state_size == NULL) {
            return EINVAL;
        } else {
            *state_size = attr->state_size;
            return 0;
	}
}


int rthread_attr_setbaseaddr(rthread_attr_t *attr, uint32 baseaddr)
{
	CYG_ASSERT(attr, "attr == NULL");
	// check if baseaddr has at most 10 bits
	if (baseaddr & 0xFFFFFC00) {
		return EINVAL;
	} else {
		attr->slot->dcr_base_addr = baseaddr;
		return 0;
	}
}

int rthread_attr_getbaseaddr(const rthread_attr_t *attr, uint32 *baseaddr)
{
	CYG_ASSERT(attr, "attr == NULL");
	if (baseaddr == NULL) {
		return EINVAL;
	} else {
		*baseaddr = attr->slot->dcr_base_addr;
	}
	return 0;
}
        
int rthread_attr_setintrvector(rthread_attr_t *attr, cyg_vector_t intrvector)
{
	CYG_ASSERT(attr, "attr == NULL");
	attr->slot->interrupt_vector = intrvector;
	return 0;
}

int rthread_attr_getintrvector(const rthread_attr_t *attr, cyg_vector_t *intrvector)
{
	CYG_ASSERT(attr, "attr == NULL");
	if (intrvector == NULL) {
		return EINVAL;
	} else {
		*intrvector = attr->slot->interrupt_vector;
	}
	return 0;
}

// also sets fiforead and write resnums and numresources
int rthread_attr_setresources(rthread_attr_t *attr, reconos_res_t *resources, uint32 numresources)
{
	uint32 i;
	
	CYG_ASSERT(attr, "attr == NULL");
	if (resources == NULL) {
		return EINVAL;
	} else {
		attr->resources = resources;
		attr->resource_count = numresources;
		// set read/write HW FIFO handles
		for (i = 0; i < numresources; i++) {
			switch (attr->resources[i].type) {
				case RECONOS_HWMBOX_READ_T:
					attr->fifo_read_index = i;
					break;
				case RECONOS_HWMBOX_WRITE_T:
					attr->fifo_write_index = i;
					break;
			}
		}
	}
	return 0;
}

int rthread_attr_getresources(const rthread_attr_t *attr, reconos_res_t **resources)
{
	CYG_ASSERT(attr, "attr == NULL");
	if (resources == NULL) {
		return EINVAL;
	} else {
		*resources = attr->resources;
	}
	return 0;
}

int rthread_attr_getnumresources(const rthread_attr_t *attr, uint32 *numresources)
{
	CYG_ASSERT(attr, "attr == NULL");
	if (numresources == NULL) {
		return EINVAL;
	} else {
		*numresources = attr->resource_count;
	}
	return 0;
}

///
/// Set slot number for static designs
///
/// Only used in static designs (i.e. all thread circuits are preconfigured in
/// the initial bitstream). Make sure that this is executed without
/// any hardware threads running (modifies reconos_slots without
/// synchronization).
///
int rthread_attr_setslotnum(rthread_attr_t *attr, int slot_num)
{
        CYG_ASSERT(attr, "attr == NULL");
        if (slot_num >= NUM_SLOTS) {
            return EINVAL;
        } else {
            attr->slot = &reconos_slots[slot_num];
            reconos_slots[slot_num].thread = attr;
            reconos_slots[slot_num].state = READY;
        }
	attr->flags &= ~RTHREAD_ATTR_IS_DYNAMIC;
	return 0;
}

int rthread_attr_getslotnum(const rthread_attr_t *attr, int *slot_num)
{
        CYG_ASSERT(attr, "attr == NULL");
        if (slot_num == NULL) {
            return EINVAL;
        } else if (attr->slot == NULL) {
            return EINVAL;
        } else {
            *slot_num = attr->slot->num;
        }
	return 0;
}

#ifdef UPBFUN_RECONOS_PARTIAL
int rthread_attr_setcircuit(rthread_attr_t *attr, reconos_circuit_t* circuit) {
    CYG_ASSERT(attr, "attr == NULL");
    if (circuit == NULL) {
        return EINVAL;
    } else {
        attr->circuit = circuit;
        attr->flags |= RTHREAD_ATTR_IS_DYNAMIC;
    }
    return 0;
}

int rthread_attr_getcircuit(const rthread_attr_t *attr, reconos_circuit_t** circuit) {
    CYG_ASSERT(attr, "attr == NULL");
    if (circuit == NULL) {
        return EINVAL;
    } else {
        *circuit = attr->circuit;
    }
    return 0;
}
#endif
