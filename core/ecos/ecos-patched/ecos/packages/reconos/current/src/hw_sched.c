///
/// \file hw_sched.c
///
/// Hardware scheduling thread / routine
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       11.03.2009
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
// 11.03.2009   Enno Luebbers   File created.

#include <reconos/reconos.h>

#include <cyg/infra/cyg_type.h>		// for types and __externC
#include <cyg/kernel/kapi.h>
#include <stdlib.h>
#include <stdio.h>
#include <cyg/infra/diag.h>

#include <reconos/hw_sched.h>
#include <reconos/osif_comm.h>
#include <cyg/hal/icap.h>


// GLOBAL VARIABLES=========================================================
cyg_mutex_t reconos_hwsched_mutex;
cyg_cond_t  reconos_hwsched_condvar;
cyg_sem_t   reconos_hwsched_semaphore;
rthread_attr_t *reconos_hwthread_list = NULL;
unsigned int num_global_yield_requests = 0;

#define RECONOS_HWSCHED_STACK_SIZE 8192
unsigned char reconos_hwsched_stack[RECONOS_HWSCHED_STACK_SIZE];
cyg_handle_t  reconos_hwsched_thread_handle;
cyg_thread    reconos_hwsched_thread;

extern reconos_slot_t reconos_slots[NUM_OSIFS];

//-----------------------------------------
// HW thread list maintenance functions
//-----------------------------------------
void reconos_register_hwthread( rthread_attr_t *t ) {
    rthread_attr_t *tmp = reconos_hwthread_list;

    // if this is the first thread to register
    if (reconos_hwthread_list == NULL) {
        // put it at the top
        reconos_hwthread_list = t;
    } else {    // otherwise
        // find tail of list
        while( tmp->next != NULL ) {
            tmp = tmp->next;
        }
        // append t
        tmp->next = t;
    }
    t->next = NULL;
}

void reconos_unregister_hwthread( rthread_attr_t *t ) {
    rthread_attr_t *tmp = reconos_hwthread_list, *prev = tmp;

    CYG_ASSERT(reconos_hwthread_list != NULL, "hw thread list is NULL");
    // find t in list
    while (tmp != t && tmp->next != NULL) {
        prev = tmp;
        tmp = tmp->next;
    }
    CYG_ASSERT(tmp == t, "HW thread not found in list");
    // remove t from list
    if (tmp == reconos_hwthread_list) {     // first element in list
        reconos_hwthread_list = tmp->next;
    } else  {
        prev->next = tmp->next;
    }
    tmp->next = NULL;
}

void dump_all_hwthreads( void ) {
    rthread_attr_t *t = reconos_hwthread_list;

    while ( t != NULL ) {
        rthread_attr_dump( t );
        t = t->next;
    }
}




///
/// Find a free slot
///
/// returns a free slot which t_r can be reconfigured into
///

reconos_slot_t *find_free_slot(rthread_attr_t *t) {
    uint8 possible_slots[NUM_OSIFS];
    reconos_bitstream_t *possible_bitstreams[NUM_OSIFS];
    uint8 num_possible_slots = 0;
    int i, j;

    CYG_ASSERT( t->flags & RTHREAD_ATTR_IS_DYNAMIC, "trying to reconfigure a static thread" );
    CYG_ASSERT( t->circuit->num_bitstreams > 0, "no bitstreams available for thread" );

    for (i = 0; i < NUM_OSIFS; i++) {
        for (j = 0; j < t->circuit->num_bitstreams; j++) {
            if (t->circuit->bitstreams[j]->slot_num == i) {
                possible_slots[num_possible_slots] = i;
                possible_bitstreams[num_possible_slots++] = 
                    t->circuit->bitstreams[j];
            }
        }
    }

    for (i = 0; i < num_possible_slots; i++) {
        // either free or not-executing slots are okay
        j = possible_slots[i];
        if (reconos_slots[j].state == FREE ) {
//            || reconos_slots[j].state == READY) {
           return &reconos_slots[j];
        }
    }
    return NULL;
}

//-----------------------------------------
// send a yield request to all threads
// NOTE: this must be synchronized (non-reentrant)
//-----------------------------------------
void push_yield_request( void ) {
    int i;

    // only set flags if this is the first request
    if (! num_global_yield_requests++ ) {
        for ( i = 0; i < NUM_OSIFS; i++ ) {
            if ( reconos_slots[i].thread && ( reconos_slots[i].thread->flags & RTHREAD_ATTR_IS_DYNAMIC ) != 0 ) {
                osif_request_yield( reconos_slots[i].thread->slot );
            }
        }
    }
}



//-----------------------------------------
// clears a pending yield request to all threads
// NOTE: this must be synchronized (non-reentrant)
//-----------------------------------------
void pop_yield_request( void ) {
    int i;

    if (num_global_yield_requests ) {
        // only clear flags isf there are no more pending yield requests
        if (! --num_global_yield_requests) {
            for ( i = 0; i < NUM_OSIFS; i++ ) {
                if ( reconos_slots[i].thread && ( reconos_slots[i].thread->flags & RTHREAD_ATTR_IS_DYNAMIC ) != 0 ) {
                    osif_clear_yield( reconos_slots[i].thread->slot );
                }
            }
        }
    }
}

///
/// Get bitstream of a thread for a specific slot
///
reconos_bitstream_t *get_bit_for_slot( rthread_attr_t *t, reconos_slot_t *s ) {
    
    int i;

    CYG_ASSERT(t != NULL, "thread is NULL");
    CYG_ASSERT(s != NULL, "slot is NULL");
    CYG_ASSERT(t->flags & RTHREAD_ATTR_IS_DYNAMIC, "thread is not dynamic" );

    for ( i = 0; i < t->circuit->num_bitstreams; i++ ) {
        if ( t->circuit->bitstreams[i]->slot_num == s->num ) {
            return t->circuit->bitstreams[i];
        }
    }
    return NULL;
}

//-----------------------------------------
// eCos HW scheduling thread
//-----------------------------------------
void reconos_hw_scheduler(cyg_addrword_t data) {

    cyg_bool_t retval;
    rthread_attr_t *t_r;            // thread to reconfigure
    rthread_attr_t *t_y;            // yielding thread
    reconos_slot_t *s_f;            // free slot
    reconos_bitstream_t *t_r_bit;   // bitstream for t_r in s_f
#ifdef UPBFUN_RECONOS_CHECK_HWTHREAD_SIGNATURE
    uint32 signature;               // hardware thread signature
    volatile int z;                 // counter to delay DCR access
#endif

#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("hw_sched: created\n");
#endif

    // loop forever
    for (;;) {  
        // wait for signal (reschedule request)
        retval = cyg_semaphore_wait( &reconos_hwsched_semaphore );
        CYG_ASSERT(retval, "cyg_semaphore_wait returned false");

#ifdef UPBDBG_RECONOS_DEBUG
        diag_printf("hw_sched: wakeup\n");
#endif

        // lock scheduling mutex
        if (!cyg_mutex_lock(&reconos_hwsched_mutex)) {
            CYG_FAIL("mutex lock failed, aborting thread\n");
        } else {

            // find thread t_r that wants to run (FIXME: no priorities or
            // queuing!)
            t_r = reconos_hwthread_list;
            while ( t_r != NULL && ((t_r->flags & RTHREAD_ATTR_RECONFIGURE) == 0) ) {
                t_r = t_r->next;
            }
            if (t_r == NULL) {
                // no hw threads to reconfigure, nothing to do
#ifdef UPBDBG_RECONOS_DEBUG
                diag_printf("hw_sched: no threads to reconfigure\n");
#endif
                // clear all yield requests!
                while (num_global_yield_requests) {
                    pop_yield_request();
                }
            } else {
#ifdef UPBDBG_RECONOS_DEBUG
                diag_printf("hw_sched: found thread @ 0x%08X to reconfigure\n", (uint32)t_r);
#endif

                CYG_ASSERT( t_r->flags & RTHREAD_ATTR_IS_DYNAMIC, "trying to load a static thread" );

                // find free slot s_f
                s_f = find_free_slot( t_r );

                if ( s_f == NULL ) { // no free slot
                    // try to find thread that yields in a slot we have a
                    // bitstream for
#ifdef UPBDBG_RECONOS_DEBUG
                    diag_printf("hw_sched: no free slots\n");
#endif
                    t_y = reconos_hwthread_list;
                    while ( t_y != NULL &&
                            ( ( (t_y->flags & RTHREAD_ATTR_YIELDS ) == 0) || ( get_bit_for_slot( t_r, t_y->slot ) == NULL ) )
                          ) {
                        t_y = t_y->next;
                    }
                    if (t_y == NULL) {  // no yielding thread
#ifdef UPBDBG_RECONOS_DEBUG
                        diag_printf("hw_sched: no yielding threads, sending yield requests to slots\n");
#endif
                        // ask all slots to yield 
                        // FIXME: this will also ask slots that t_r possibly
                        // doesn't have a bitstream for
                        push_yield_request();
                    } else { // if found
                        CYG_ASSERT( t_y->flags & RTHREAD_ATTR_IS_DYNAMIC, "trying to replace a static thread" );
                        CYG_ASSERT( t_y->slot, "trying to replace a not-resident thread" );
#ifdef UPBDBG_RECONOS_DEBUG
                        diag_printf("hw_sched: found yielding thread @ 0x%08X in slot %d\n", (uint32)t_y, t_y->slot->num);
#endif
                        // use t_y's slot as s_f
                        s_f = t_y->slot;
                        // clear yield flag of t_y
                        t_y->flags = t_y->flags & ~RTHREAD_ATTR_YIELDS;
                        // remove t_y from s_f
                        s_f->thread = NULL;
                        t_y->slot = NULL;
                        s_f->state = FREE;
                    }
                } else {
#ifdef UPBDBG_RECONOS_DEBUG
                    diag_printf("hw_sched: found free slot %d\n", s_f->num);
#endif
                }

                if ( s_f != NULL) {     // if we found a free slot
                    // one way or the other

                    // get bitstream for t_r in s_f
                    t_r_bit = get_bit_for_slot( t_r, s_f );

                    CYG_ASSERT( t_r_bit, "no bitstream" );
                    CYG_ASSERT( s_f->state == FREE || s_f->thread->flags & RTHREAD_ATTR_IS_DYNAMIC, "slot not free or present thread is static" );

#ifdef UPBDBG_RECONOS_DEBUG
                    diag_printf("hw_sched: configuring thread @ 0x%08X into slot %d using bitstream '%s'\n", (uint32)t_r, s_f->num, t_r_bit->filename);
#endif

                    // configure t_r into s_f
                    // NOTE: we don't need to synchronize this with the
                    // slot's mutex, since the slot is yielding and will
                    // not perform any hardware operations while the
                    // scheduling mutex is locked
                    // disable bus macros (just in case)
                    osif_set_busmacro(s_f, OSIF_DATA_BUSMACRO_DISABLE);
#ifdef UPBHWR_VIRTEX4_ICAP
                    icap_load( t_r_bit->data, t_r_bit->size );
#endif
#ifdef UPBFUN_RECONOS_ECAP_NET
					ecap_load( t_r_bit );
#endif
#ifdef UPBFUN_RECONOS_CHECK_HWTHREAD_SIGNATURE
					// reset thread, enable busmacros, reset again (to 
					// retrieve signature), read signature, and disable
					// busmacros
					osif_reset( s_f );
                    cyg_thread_delay(1);
					osif_set_busmacro(s_f, OSIF_DATA_BUSMACRO_ENABLE);
                    // cyg_thread_delay(1);
					osif_reset( s_f );
                    cyg_thread_delay(1);
					osif_read_hwthread_signature(s_f, &signature);
                    // cyg_thread_delay(1);
                    // osif_set_busmacro(s_f, OSIF_DATA_BUSMACRO_DISABLE);
                    // cyg_thread_delay(1);
#ifdef UPBDBG_RECONOS_DEBUG
					diag_printf("hw_sched: read signature: 0x%08X, expected: 0x%08X.\n", signature, t_r->circuit->signature);
#endif
					// check whether the signatures match
					CYG_ASSERT(signature == t_r->circuit->signature, "hwthread signatures don't match");
#endif
                    // assign thread to slot and set slot state to READY
                    s_f->thread = t_r;
                    t_r->slot = s_f;
                    s_f->state = READY;
                    // clear t_r's RECONFIGURE bit
                    t_r->flags = t_r->flags & ~RTHREAD_ATTR_RECONFIGURE;
                    // wake any threads waiting for a scheduling change
                    cyg_cond_broadcast( &reconos_hwsched_condvar );
                    // clear one yield request
                    pop_yield_request();
                }
            }

#ifdef UPBDBG_RECONOS_DEBUG
            diag_printf("hw_sched: done\n");
#endif
            // unlock scheduling mutex
            cyg_mutex_unlock(&reconos_hwsched_mutex);

        }   // if (mutex_lock)

    } // for (;;)
}    



// init
void reconos_hwsched_init() {
    reconos_hwthread_list = NULL;
    num_global_yield_requests = 0;

    cyg_mutex_init(&reconos_hwsched_mutex);
    cyg_cond_init(&reconos_hwsched_condvar, &reconos_hwsched_mutex);

    cyg_thread_create( 0, 
                       reconos_hw_scheduler, 
                       (cyg_addrword_t)NULL, 
                       "RECONOS_HW_SCHEDULER", 
                       reconos_hwsched_stack,
                       RECONOS_HWSCHED_STACK_SIZE,
                       &reconos_hwsched_thread_handle,
                       &reconos_hwsched_thread
                    );

    cyg_thread_resume( reconos_hwsched_thread_handle );
};

// exit
void reconos_hwsched_destroy() {

    cyg_thread_kill( reconos_hwsched_thread_handle );

    cyg_cond_destroy(&reconos_hwsched_condvar);
    cyg_mutex_destroy(&reconos_hwsched_mutex);

}
