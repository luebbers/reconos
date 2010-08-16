#ifndef CYGONCE_HAL_PLF_INC
#define CYGONCE_HAL_PLF_INC
##=============================================================================
##
##	plf.inc
##
##	PPC40x family assembler header file
##
##=============================================================================
#####ECOSGPLCOPYRIGHTBEGIN####
## -------------------------------------------
## This file is part of eCos, the Embedded Configurable Operating System.
## Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
## Copyright (C) 2002, 2003, 2004, 2005 Mind n.v.
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
## Author(s): 	jskov
## Contributors:jskov, gthomas, cduclos
## Date:	2000-08-27
## Purpose:	PPC40x family definitions.
## Description:	This file contains various definitions and macros that are
##              useful for writing assembly code for the PPC40x CPU family.
##              Changed the names of some things from ML300 to VIRTEX4
## Usage:
##		#include <cyg/hal/plf.inc>
##		...
##		
##
######DESCRIPTIONEND####
##
##=============================================================================

#define CYGPKG_HAL_POWERPC_INTC_DEFINED
        # decode the interrupt
        # the interrupt vector will be 0x500 or 0x10x0
        # 0x0500 = external, must be decoded via EXISR
        # 0x10X0 = timer, X is the timer type
        # r3 used as scratch
        .macro  hal_intc_decode dreg,state
        lwz     \dreg,CYGARC_PPCREG_VECTOR(\state) # retrieve vector number,
        extrwi. \dreg,\dreg,1,19                # isolate bit 19
        beq     0f                              # timer interrupt = 1
        lwz     \dreg,CYGARC_PPCREG_VECTOR(\state) # retrieve vector number,
        extrwi  \dreg,\dreg,2,26                # isolate bits 26-27
        addi    \dreg,\dreg,CYGNUM_HAL_INTERRUPT_VAR_TIMER # FIXME
        b       1f
0:      lwi     r3,_VIRTEX4_INTC
        lwz     \dreg,_VIRTEX4_INTC_ISR(r3)
	lwz	r3,_VIRTEX4_INTC_IER(r3)
	and	r3,\dreg,r3
	cntlzw	r3,r3
	li	\dreg,31
	sub	\dreg,\dreg,r3
        addi    \dreg,\dreg,CYGNUM_HAL_INTERRUPT_first
1:      stw     \dreg,CYGARC_PPCREG_VECTOR(\state) # update vector in state frame.
        slwi    \dreg,\dreg,2                   # convert to byte offset.
        .endm                              

#endif // CYGONCE_HAL_PLF_INC
