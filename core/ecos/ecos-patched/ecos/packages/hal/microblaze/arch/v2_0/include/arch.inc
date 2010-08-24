##=============================================================================
##
##	arch.inc
##
##	MicroBlaze architecture assembler header file
##
##=============================================================================
#####ECOSGPLCOPYRIGHTBEGIN####
## -------------------------------------------
## This file is part of eCos, the Embedded Configurable Operating System.
## Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
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
## Date:	1997-10-16
## Purpose:	MicroBlaze definitions.
## Description:	This file contains various definitions and macros that are
##              useful for writing assembly code for the MicroBlaze
##              It also includes the variant assembly header file.
## Usage:
##		#include <cyg/hal/arch.inc>
##
######DESCRIPTIONEND####
##
##=============================================================================

#include <cyg/hal/variant.inc>

#------------------------------------------------------------------------------
# Some useful coding macros

#define FUNC_START(name)	\
	.type	name,@function;	\
	.globl	name;		\
name:

#define FUNC_END(name)		\
	/* nothing for now */

##-----------------------------------------------------------------------------
## CPU specific macros. These provide a common assembler interface to
## operations that may have CPU specific implementations on different
## variants of the architecture.		

#ifdef MON_CPU_MSR_INSTR
# Enable interrupts
.macro hal_cpu_int_enable
	msrset	r0, 0x2
	nop
.endm

# Disable interrupts
.macro hal_cpu_int_disable
	msrclr	r0, 0x2
	nop
.endm

#else

# Enable interrupts
.macro hal_cpu_int_enable
	mfs 	r4, rmsr
	ori	r4, r4, 0x2
	mts	rmsr, r4
	nop
.endm


# Disable interrupts
.macro hal_cpu_int_disable
	mfs 	r4, rmsr
	andi	r4, r4, 0x2
	mts	rmsr, r4
	nop
#endm

#endif

# Merge the interrupt enable state of the status register in \sr with the current sr.
.macro	hal_cpu_int_merge sr
	mfs	r4, rmsr
	andni	r4, r4, 0x0002
	andi	\sr, \sr, 0x0002
	or	r4, r4, \sr
	mts	rmsr, r4
	nop
.endm

#------------------------------------------------------------------------------
# end of arch.inc
