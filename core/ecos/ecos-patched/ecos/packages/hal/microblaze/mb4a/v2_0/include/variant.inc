#ifndef CYGONCE_HAL_VARIANT_INC
#define CYGONCE_HAL_VARIANT_INC
##=============================================================================
##
##	variant.inc
##
##	mb4a family assembler header file
##
##=============================================================================
#####ECOSGPLCOPYRIGHTBEGIN####
## -------------------------------------------
## This file is part of eCos, the Embedded Configurable Operating System.
## Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
## Copyright (C) 2002 Gary Thomas
##
## eCos is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 or (at your option) any later version.
##
## eCos is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with eCos; if not, write to the Free Software Foundation, Inc.,
## 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
##
## As a special exception, if other files instantiate templates or use macros
## or inline functions from this file, or you compile this file and link it
## with other works to produce a work based on this file, this file does not
## by itself cause the resulting work to be covered by the GNU General Public
## License. However the source code for this file must still be made available
## in accordance with section (3) of the GNU General Public License.
##
## This exception does not invalidate any other reasons why a work based on
## this file might be covered by the GNU General Public License.
##
## Alternative licenses for eCos may be arranged by contacting Red Hat, Inc.
## at http://sources.redhat.com/ecos/ecos-license/
## -------------------------------------------
#####ECOSGPLCOPYRIGHTEND####
##=============================================================================
#######DESCRIPTIONBEGIN####
##
## Author(s):      Michal Pfeifer
## Original data:  PowerPC
## Contributors: 
## Date:	2000-02-04
## Purpose:	mb4a family definitions.
## Description:	This file contains various definitions and macros that are
##              useful for writing assembly code for the mb4a CPU family.
## Usage:
##		#include <cyg/hal/variant.inc>
##		...
##		
##
######DESCRIPTIONEND####
##
##=============================================================================

#include <pkgconf/hal.h>
	
#include <cyg/hal/arch.inc>
#include <cyg/hal/platform.inc>

##-----------------------------------------------------------------------------
## mb4a defined vectors

	.macro hal_call_extra_vectors
	.endm

        .macro hal_extra_vectors
        .endm

##-----------------------------------------------------------------------------
## mb4a CPU initialization
# clearing MSR register

#ifdef MON_CPU_MSR_INSTR
	.macro hal_cpu_init
		msrclr	r0, 0	# MSR = 0
		nop
	.endm
#else
	.macro hal_cpu_init
		addi	r3, r0, 0
		mts	rmsr, r3
		nop
	.endm
#endif

##-----------------------------------------------------------------------------
## mb4a monitor initialization

#ifndef CYGPKG_HAL_MB_MON_DEFINED

#if     defined(CYG_HAL_STARTUP_ROM) ||                 \
        (       defined(CYG_HAL_STARTUP_RAM) &&         \
                !defined(CYGSEM_HAL_USE_ROM_MONITOR))

        .macro  hal_mon_init
        # Initialize the VSR table. This happens whether the
        # vectors were copied to RAM or not.

        # First fill with exception handlers
        addi    r3, r0, cyg_hal_default_exception_vsr
        addi    r4, r0, hal_vsr_table
        addi    r5, r0, CYGNUM_HAL_VSR_COUNT
		
1:      swi		r3, r4, 0
		addi	r4, r4, 4
        addi    r5, r5, -1
        bnei    r5, 1b

        # Then fill in the special vectors
        addi    r3, r0, cyg_hal_default_interrupt_vsr
        addi    r4, r0, hal_vsr_table
        swi     r3, r4, CYGNUM_HAL_VECTOR_INTERRUPT * 4
        .endm

#elif defined(CYG_HAL_STARTUP_RAM) && defined(CYGSEM_HAL_USE_ROM_MONITOR)

        # Initialize the VSR table entries
        # We only take control of the interrupt vectors,
        # the rest are left to the ROM for now...

        .macro  hal_mon_init
        addi    r3, r0, cyg_hal_default_interrupt_vsr
        addi    r4, r0, hal_vsr_table
        swi     r3, r4, CYGNUM_HAL_VECTOR_INTERRUPT * 4
        .endm


#else

        .macro  hal_mon_init

        .endm

#endif


#define CYGPKG_HAL_MB_MON_DEFINED

#endif // CYGPKG_HAL_MB_MON_DEFINED

##-----------------------------------------------------------------------------
## mb4a exception state handling

        .macro	hal_variant_save regs
			# read regs and store them
#ifdef CYGHWR_HAL_MICROBLAZE_FPU
			mfs   r3, rfsr
			swi   r3, \regs, CYGARC_MBREG_FSR
#endif
#ifdef CYGHWR_HAL_MICROBLAZE_HWEXCEPTION
			mfs   r3, rear
			mfs   r4, resr
			swi   r3, \regs, CYGARC_MBREG_EAR
			swi   r4, \regs, CYGARC_MBREG_ESR
#endif
        .endm

        .macro	hal_variant_load regs
			# load regs
#ifdef CYGHWR_HAL_MICROBLAZE_FPU
			lwi   r3, \regs, CYGARC_MBREG_FSR
			mts   r3, rfsr
#endif
#ifdef CYGHWR_HAL_MICROBLAZE_HWEXCEPTION
			// ESR and EAR can't be written
#endif
        .endm

##-----------------------------------------------------------------------------
## Indicate that the ISR tables are defined in variant.S

#define CYG_HAL_MB_ISR_TABLES_DEFINED

#------------------------------------------------------------------------------
#endif // ifndef CYGONCE_HAL_VARIANT_INC
# end of variant.inc
