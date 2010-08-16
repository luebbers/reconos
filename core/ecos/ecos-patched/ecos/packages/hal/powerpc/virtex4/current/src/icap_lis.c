///
/// \file icap.c
///
/// Low-level routines for partial reconfiguration via LIS' XPS ICAP
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       10.09.2009
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

#include <cyg/hal/icap.h>
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_ass.h>
#include <cyg/infra/cyg_trac.h>
#include <cyg/kernel/kapi.h>
#include <xio_dcr.h>

#define HWICAP_BASEADDR             XPAR_ICAPCTRL_0_DCR_BASEADDR
#define ICAP_BURST_SIZE 128

static cyg_mutex_t icap_mutex;
static cyg_sem_t icap_done;


///
/// Holds interrupt information
///
typedef struct icap_done_interrupt_t {
    //uint32          dcr_base_addr;      // icap_done dcr base address
    //uint32          plb_base_addr;
    cyg_interrupt   interrupt;          // icap_done interrupt
    cyg_handle_t    interrupt_handle;   // icap_done interrupt handle
    cyg_vector_t    interrupt_vector;   // icap_done interrupt vector
    cyg_ucount32    interrupt_count;
    //cyg_mutex_t     mutex;             // icap_done mutex (to "atomize" accesses)
} icap_done_interrupt_t;

static icap_done_interrupt_t icap_done_interrupt;


///
/// ICAP done interrupt handler (ISR and DSR)
///
cyg_uint32 icap_done_isr(cyg_vector_t vector, cyg_addrword_t data) {
    cyg_interrupt_mask(vector);
    cyg_interrupt_acknowledge(vector);
    diag_printf("\nicap_done_isr call");
    return (CYG_ISR_HANDLED | CYG_ISR_CALL_DSR);
}

void icap_done_dsr(cyg_vector_t vector, cyg_ucount32 count, cyg_addrword_t data) {
    cyg_semaphore_post(&icap_done);
    diag_printf("\nicap_done_dsr call");
    cyg_interrupt_unmask(vector);
}


///
/// Sets up interrupt handlers and data structures
///
void create_icap_done_interrupt(void) {
    CYG_REPORT_FUNCTION();
    icap_done_interrupt.interrupt_vector = XPAR_XPS_INTC_0_ICAPCTRL_0_DONE_INT_INTR + 1;
    icap_done_interrupt.interrupt_count  = 0;

    cyg_interrupt_create( icap_done_interrupt.interrupt_vector,
            0,
            (cyg_addrword_t)&icap_done_interrupt,
            &icap_done_isr,
            &icap_done_dsr,
            &icap_done_interrupt.interrupt_handle,
            &icap_done_interrupt.interrupt
            );

    cyg_interrupt_attach(icap_done_interrupt.interrupt_handle);
    // enable interrupt
    cyg_interrupt_unmask(icap_done_interrupt.interrupt_vector);
    CYG_REPORT_RETURN();
}


///
/// Initialize the ICAP
///
void icap_init(void){
    CYG_REPORT_FUNCTION();
    create_icap_done_interrupt();
    cyg_mutex_init(&icap_mutex);
    cyg_semaphore_init(&icap_done, 0);
    CYG_REPORT_RETURN();
}

///
/// Load a bitstream via ICAP
///
/// @param bitstream pointer to the bitstream array
/// @param length    length of bitstream in bytes
///
void icap_load(unsigned char * bitstream, size_t length){

        CYG_REPORT_FUNCTION();

        if (!cyg_mutex_lock(&icap_mutex)) {
            CYG_FAIL("mutex lock failed, aborting thread\n");
        } else {
            CYG_ASSERT((0x003FFFFF & (cyg_uint32)bitstream) == 0x00000000, "bitstream address must be aligned to 4M boundary");
            if (length % ICAP_BURST_SIZE == 0)
                XIo_DcrOut(XPAR_ICAPCTRL_0_DCR_BASEADDR, (0xFFC00000 & (cyg_uint32)bitstream) | (0x0000FFFF & (length/ICAP_BURST_SIZE)));
            else
                // fill last burst with 0
                memset((void*)((int)bitstream+(int)length), 0, ICAP_BURST_SIZE-(length % ICAP_BURST_SIZE));
                XIo_DcrOut(XPAR_ICAPCTRL_0_DCR_BASEADDR, (0xFFC00000 & (cyg_uint32)bitstream) | (0x0000FFFF & ((length+ICAP_BURST_SIZE)/ICAP_BURST_SIZE)));
            //XIo_DcrOut(XPAR_ICAPCTRL_0_DCR_BASEADDR, (0xFFC00000 & (cyg_uint32)bitstream) | (0x0000FFFF & (length/sizeof(cyg_uint32))));
            // wait for completion
            cyg_semaphore_wait(&icap_done);
            cyg_mutex_unlock(&icap_mutex);
        }

        CYG_REPORT_RETURN();
}

