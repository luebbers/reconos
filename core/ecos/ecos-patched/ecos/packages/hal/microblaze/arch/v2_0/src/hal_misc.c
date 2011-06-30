//==========================================================================
//
//      hal_misc.c
//
//      HAL miscellaneous functions
//
//==========================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002 Gary Thomas
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
//==========================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):      Michal Pfeifer
// Original data:  PowerPC
// Contributors: 
// Date:         1999-02-20
// Purpose:      HAL miscellaneous functions
// Description:  This file contains miscellaneous functions provided by the
//               HAL.
//
//####DESCRIPTIONEND####
//
//===========================================================================

#include <pkgconf/hal.h>

#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <cyg/hal/mb_regs.h>           // SPR definitions

#include <cyg/infra/cyg_type.h>
#include <cyg/infra/cyg_trac.h>         // tracing macros
#include <cyg/infra/cyg_ass.h>          // assertion macros
#include <cyg/infra/diag.h>             // diag_printf

#include <cyg/hal/hal_arch.h>           // HAL header
#include <cyg/hal/hal_cache.h>          // HAL cache
#if defined(CYGFUN_HAL_COMMON_KERNEL_SUPPORT) && \
    defined(CYGPKG_HAL_EXCEPTIONS)
# include <cyg/hal/hal_intr.h>           // HAL interrupts/exceptions
#endif
//#include <cyg/hal/hal_mem.h>            // HAL memory handling

//---------------------------------------------------------------------------
// Functions used during initialization.

#ifdef CYGSEM_HAL_STOP_CONSTRUCTORS_ON_FLAG
cyg_bool cyg_hal_stop_constructors;
#endif

typedef void (*pfunc) (void);
extern pfunc __CTOR_LIST__[];
extern pfunc __CTOR_END__[];

void cyg_hal_invoke_constructors (void)
{
#ifdef CYGSEM_HAL_STOP_CONSTRUCTORS_ON_FLAG
	static pfunc *p = &__CTOR_END__[-1];

	cyg_hal_stop_constructors = 0;
	for (; p >= __CTOR_LIST__; p--) {
		(*p) ();
		if (cyg_hal_stop_constructors) {
		--p;
		break;
		}
	}
#else
	pfunc *p;

	for (p = &__CTOR_END__[-1]; p >= __CTOR_LIST__; p--)
		(*p) ();
#endif
}

// Override any __eabi the compiler might generate. We don't want
// constructors to be called twice.
//void __eabi (void) {}

//---------------------------------------------------------------------------
// First level C exception handler.

externC void __handle_exception (void);

externC HAL_SavedRegisters *_hal_registers;

externC void* volatile __mem_fault_handler;

void cyg_hal_exception_handler(HAL_SavedRegisters *regs, cyg_uint32 vector)
{
#ifdef CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS
	// If we caught an exception inside the stubs, see if we were expecting it
	// and if so jump to the saved address
	if (__mem_fault_handler) {
		regs->pc = (CYG_ADDRWORD)__mem_fault_handler;
		return; // Caught an exception inside stubs
	}

	// Set the pointer to the registers of the current exception
	// context. At entry the GDB stub will expand the
	// HAL_SavedRegisters structure into a (bigger) register array.
	_hal_registers = regs;

	__handle_exception();

#elif defined(CYGFUN_HAL_COMMON_KERNEL_SUPPORT) && \
	defined(CYGPKG_HAL_EXCEPTIONS)

	cyg_hal_deliver_exception( vector, (CYG_ADDRWORD)regs );

#else

	CYG_FAIL("Exception!!!");

#endif

	return;
}

//---------------------------------------------------------------------------
// Default ISRs

#ifndef CYGSEM_HAL_VIRTUAL_VECTOR_SUPPORT
externC cyg_uint32 hal_default_isr(CYG_ADDRWORD vector, CYG_ADDRWORD data)
{
	diag_printf("Interrupt: %d\n", vector);

	CYG_FAIL("Spurious Interrupt!!!");
	return 0;
}
#else
externC cyg_uint32 hal_arch_default_isr(CYG_ADDRWORD vector, CYG_ADDRWORD data)
{
    return 0;
}
#endif


//---------------------------------------------------------------------------
// Idle thread action

externC bool hal_variant_idle_thread_action(cyg_uint32);

void hal_idle_thread_action( cyg_uint32 count )
{
	// Execute variant idle thread action, while allowing it to control
	// whether to run any of the architecture action code.
	if (!hal_variant_idle_thread_action(count))
		return;
}

//---------------------------------------------------------------------------
// Use MMU resources to map memory regions.  
// This relies that the platform HAL providing an
//          externC cyg_memdesc_t cyg_hal_mem_map[];
// as detailed in hal_cache.h, and the variant HAL providing the
// MMU mapping/clear functions.
/*
externC void
hal_MMU_init (void)
{
    int id = 0;
    int i  = 0;

    cyg_hal_clear_MMU ();

    while (cyg_hal_mem_map[i].size) {
        id = cyg_hal_map_memory (id, 
                                 cyg_hal_mem_map[i].virtual_addr,
                                 cyg_hal_mem_map[i].physical_addr,
                                 cyg_hal_mem_map[i].size,
                                 cyg_hal_mem_map[i].flags);
        i++;
    }
}
*/
//---------------------------------------------------------------------------
// Initial cache enabling
// Specific behavior for each platform configured via plf_cache.h

externC void hal_enable_caches(void)
{
#ifndef CYG_HAL_STARTUP_RAM
	// Invalidate caches and unlock them
	HAL_DCACHE_INVALIDATE_ALL();
	HAL_ICACHE_INVALIDATE_ALL();
#endif

#ifdef CYGSEM_HAL_ENABLE_ICACHE_ON_STARTUP
//#ifdef HAL_ICACHE_UNLOCK_ALL
//    HAL_ICACHE_UNLOCK_ALL();
//#endif
	HAL_ICACHE_ENABLE();
#endif

#ifdef CYGSEM_HAL_ENABLE_DCACHE_ON_STARTUP
//#ifdef HAL_DCACHE_UNLOCK_ALL
//    HAL_DCACHE_UNLOCK_ALL();
//#endif
	HAL_DCACHE_ENABLE();
//#ifdef HAL_DCACHE_WRITE_MODE
//#ifdef CYGSEM_HAL_DCACHE_STARTUP_MODE_COPYBACK
//    HAL_DCACHE_WRITE_MODE(HAL_DCACHE_WRITEBACK_MODE);
//#else
//    HAL_DCACHE_WRITE_MODE(HAL_DCACHE_WRITETHRU_MODE);
//#endif
//#endif
#endif
}

//---------------------------------------------------------------------------
//A jump via a null pointer causes the CPU to end up here.
externC void hal_null_call(void)
{
	CYG_FAIL("Call via NULL-pointer!");
	for(;;);
}

/*------------------------------------------------------------------------*/
/* Determine the index of the ls bit of the supplied mask.                */

externC cyg_uint32 hal_lsbit_index(cyg_uint32 mask)
{
	cyg_uint32 n = mask;

	static const signed char tab[64] =
	{ -1, 0, 1, 12, 2, 6, 0, 13, 3, 0, 7, 0, 0, 0, 0, 14, 10,
	4, 0, 0, 8, 0, 0, 25, 0, 0, 0, 0, 0, 21, 27 , 15, 31, 11,
	5, 0, 0, 0, 0, 0, 9, 0, 0, 24, 0, 0 , 20, 26, 30, 0, 0, 0,
	0, 23, 0, 19, 29, 0, 22, 18, 28, 17, 16, 0
	};

	n &= ~(n-1UL);
	n = (n<<16)-n;
	n = (n<<6)+n;
	n = (n<<4)+n;

	return tab[n>>26];
}

/*------------------------------------------------------------------------*/
/* Determine the index of the ms bit of the supplied mask.                */

externC cyg_uint32 hal_msbit_index(cyg_uint32 mask)
{
	cyg_uint32 x = mask;
	cyg_uint32 w;

	/* Phase 1: make word with all ones from that one to the right */
	x |= x >> 16;
	x |= x >> 8;
	x |= x >> 4;
	x |= x >> 2;
	x |= x >> 1;

	/* Phase 2: calculate number of "1" bits in the word        */
	w = (x & 0x55555555) + ((x >> 1) & 0x55555555);
	w = (w & 0x33333333) + ((w >> 2) & 0x33333333);
	w = w + (w >> 4);
	w = (w & 0x000F000F) + ((w >> 8) & 0x000F000F);
	return (cyg_uint32)((w + (w >> 16)) & 0xFF) - 1;
}

//---------------------------------------------------------------------------
// End of hal_misc.c
