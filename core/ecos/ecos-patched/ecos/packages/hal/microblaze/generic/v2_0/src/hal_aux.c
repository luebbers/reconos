//=============================================================================
//
//      hal_aux.c
//
//      HAL auxiliary objects and code; per platform
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002, 2003 Gary Thomas
//
// eCos is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 or (at your option) any later version.
//
// eCos is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with eCos; if not, write to the Free Software Foundation, Inc.,
// 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
//
// As a special exception, if other files instantiate templates or use macros
// or inline functions from this file, or you compile this file and link it
// with other works to produce a work based on this file, this file does not
// by itself cause the resulting work to be covered by the GNU General Public
// License. However the source code for this file must still be made available
// in accordance with section (3) of the GNU General Public License.
//
// This exception does not invalidate any other reasons why a work based on
// this file might be covered by the GNU General Public License.
//
// Alternative licenses for eCos may be arranged by contacting Red Hat, Inc.
// at http://sources.redhat.com/ecos/ecos-license/
// -------------------------------------------
//####ECOSGPLCOPYRIGHTEND####
//=============================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):      Michal Pfeifer, Michal Simek - Microblaze customation
// Original data:  PowerPC
// Date:        1999-06-08
// Purpose:     HAL aux objects: startup tables.
// Description: Tables for per-platform initialization
//
//####DESCRIPTIONEND####
//
//=============================================================================

#include <pkgconf/hal.h>
//#include <pkgconf/io_pci.h>

#include <cyg/infra/cyg_type.h>
#include <cyg/hal/hal_mem.h>	/* HAL memory definitions */

#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <cyg/hal/mb_regs.h>           // Platform registers
#include <cyg/hal/hal_if.h>             // hal_if_init
#include <cyg/hal/hal_intr.h>           // interrupt definitions
//#include <cyg/hal/hal_cache.h>
#include <cyg/infra/cyg_ass.h>          // assertion macros
//#include <cyg/io/pci.h>
#include <cyg/hal/hal_io.h>             // I/O macros
#include <cyg/infra/diag.h>
#include CYGHWR_MEMORY_LAYOUT_H

#ifdef CYGPKG_REDBOOT
#include <redboot.h>
#endif

#include <cyg/hal/platform.h>	/* platform setting */

// The memory map is weakly defined, allowing the application to redefine
// it if necessary. The regions defined below are the minimum requirements.
CYGARC_MEMDESC_TABLE CYGBLD_ATTRIB_WEAK = {
	// Mapping for the Spartan3esk development boards
	CYGARC_MEMDESC_NOCACHE( 0x00000000, (XPAR_MICROBLAZE_0_DCACHE_BASEADDR - 1) ),		/* Uncached */
	CYGARC_MEMDESC_CACHE( XPAR_MICROBLAZE_0_DCACHE_BASEADDR, XPAR_MICROBLAZE_0_DCACHE_HIGHADDR ),			/* Cached region */
	CYGARC_MEMDESC_NOCACHE( XPAR_MICROBLAZE_0_DCACHE_HIGHADDR + 1, 0xFFFFFFFF),	/* Uncached */
	CYGARC_MEMDESC_TABLE_END
};

//--------------------------------------------------------------------------
// Platform init code.

void _s3esk_assert(char *file, int line)
{
	cyg_uint32 old;

	HAL_DISABLE_INTERRUPTS(old);
	diag_printf("Microblaze firmware failure - file: %s, line: %d\n", file, line);
	while (1) ;
}

void hal_platform_init(void)
{
	// Initialize I/O interfaces
	hal_if_init();
}

//
// Initialize serial ports - called during hal_if_init()
// Note: actual serial port support code is supported by the mb4a variant layer
//       Having this call here allows for additional platform specific additions
//
void cyg_hal_plf_comms_init(void)
{
    static int initialized = 0;

    if (initialized)
        return;
    initialized = 1;

    cyg_hal_plf_serial_init();
}

/* Reset system */
/* FIXME add printing message */
void _platform_reset(void)
{
	while (1) ;
}


//-----------------------------------------------------------------------------
// Xilinx Interrupt Controller
// We don't use the HAL completely, only the low-level functions

/* map intc structure to intc ip */
microblaze_intc_t *intc = (microblaze_intc_t *) (XPAR_XPS_INTC_0_BASEADDR);
//----------------------------------------------------------------------------
// Interrupt support
void hal_platform_IRQ_init(void)
{
	/* We need first to have a decent decoding routine! */
	intc->cie = 0xFFFFFFFF;
	intc->iar = 0xFFFFFFFF;
#ifndef CYGPKG_REDBOOT
	// This is a write-once bit, so if we are not planning to enable
	// interrupts at this time, we can safely delay this to a later time
	intc->mer = 0x3; /* enable intc */
#endif
}

void hal_interrupt_init(void)
{
}

/* FIXME need add to functions below */
static inline unsigned long vectorToMask(int vector,
		const char* defaultError, unsigned long defaultMask)
{
	if (vector >= CYGNUM_HAL_ISR_MIN && vector <= CYGNUM_HAL_ISR_MAX)
		return (1 << (vector-1));
        
	diag_printf( defaultError );
	return defaultMask;
}

//FIXME need optimalize - remove vectorToMask
void hal_interrupt_mask(int vector)
{
	unsigned long mask = 0;
	mask = vectorToMask(vector, "hal_interrupt_mask: default case", 0xFFFFFFFF);
	intc->cie = mask;
}

//FIXME need optimalize - remove vectorToMask
void hal_interrupt_unmask(int vector)
{
	unsigned long mask = 0;
	mask = vectorToMask(vector, "hal_interrupt_unmask: default case", ~intc->sie);
	intc->sie = mask;
}

//FIXME need optimalize - remove vectorToMask
void hal_interrupt_acknowledge(int vector)
{
	unsigned long mask = 0;
	mask = vectorToMask(vector, "hal_interrupt_acknowledge: default case", 0xFFFFFFFF);
	intc->iar = mask;
}

void hal_interrupt_configure(int vector, int level, int dir)
{
}

void hal_interrupt_set_level(int vector, int level)
{
}


//----------------------------------------------------------------------------
// Real-time clock support
/* Map timer structure to timer IP core */
microblaze_timer_t *tmr = (microblaze_timer_t *) (XPAR_XPS_TIMER_0_BASEADDR);

externC void hal_clock_initialize(cyg_uint32 period)
{
	cyg_uint32 StatusReg;
#ifdef CYGHWR_HAL_RTC_USE_AUTO_RESET
	if(period > 2)
		period -= 2;
#endif
	StatusReg = tmr->control; /* load status reg */
	if (StatusReg & TIMER_ENABLE)
	{
		StatusReg &= ~(TIMER_ENABLE); /* Is started and running - stop timer */
		tmr->control = StatusReg;
	}
	tmr->loadreg = period; /* set the Load register to period */
	tmr->control = TIMER_INTERRUPT | TIMER_RESET; /* reset the timer and the interrupt - set reset bit */

	/* set the control/status register to complete initialization by clearing the reset bit 
	 * which was just set and set enable bit */
#ifdef CYGHWR_HAL_RTC_USE_AUTO_RESET
	/* using reload mode */ 
	tmr->control = TIMER_ENABLE | TIMER_ENABLE_INTR | TIMER_RELOAD  | TIMER_DOWN_COUNT;
#else
	/* FIXME you have to reset timer alone - need test */
	tmr->control = TIMER_ENABLE | TIMER_ENABLE_INTR | TIMER_DOWN_COUNT;
#endif
}

/* we count down that's why we can subtract current timer value */
externC void hal_clock_read(cyg_uint32 *pvalue)
{
	cyg_uint32 start_val = tmr->loadreg;
	*pvalue = start_val - tmr->counter;
}

externC void hal_clock_reset(cyg_uint32 vector, cyg_uint32 period)
{
#ifdef CYGHWR_HAL_RTC_USE_AUTO_RESET
	cyg_uint32 StatusReg = tmr->control;
	if (!(StatusReg & TIMER_ENABLE))
		hal_clock_initialize(period);
	else {
		//StatusReg = ;
		tmr->control = TIMER_INTERRUPT; /* clean interrupt flag */
		tmr->control = TIMER_ENABLE | TIMER_ENABLE_INTR | TIMER_RELOAD | TIMER_DOWN_COUNT;
	}
#else
	hal_clock_initialize(period);
#endif
}

/* Delay for some number of useconds */
externC void hal_delay_us(cyg_uint32 us)
{
	cyg_uint32 old_dec, new_dec;
	long ticks;
	cyg_uint32 diff, max;

	cyg_uint32 StatusReg = tmr->control;
	if (!(StatusReg & TIMER_ENABLE)) {
		hal_clock_initialize(CYGNUM_HAL_RTC_PERIOD);
		old_dec = 0;
	} else
		hal_clock_read(&old_dec);
 
	// Note: the system constant CYGNUM_HAL_RTC_PERIOD corresponds to 10,000us
	// Scale the desired number of microseconds to be a number of decrementer ticks
	ticks = ((long long)us * CYGNUM_HAL_RTC_PERIOD) / 10000;

	max = tmr->loadreg;
	
	while (ticks > 0) {
		do {
			hal_clock_read(&new_dec);
		} while (old_dec == new_dec);

		if (old_dec > new_dec)
			diff = (max - old_dec + new_dec + 2);
		else
			diff = (new_dec - old_dec);

		old_dec = new_dec;
		ticks -= diff;
	}
}
// EOF hal_aux.c
