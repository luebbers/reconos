##=============================================================================
##
##      virtex4.S
##
##      VIRTEX4 board hardware setup
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
## Author(s):   gthomas
## Contributors:hmt, Jan Olbrechts
## Date:        2002-07-22
## Purpose:     ML300 board hardware setup
## Description: This file contains any code needed to initialize the
##              hardware on a TAMS ML300 (PowerPC 405GPr) board.
##
######DESCRIPTIONEND####
##
##=============================================================================

#include <pkgconf/hal.h>
#include <cyg/hal/arch.inc>		/* register symbols et al */
#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS        
#include <cyg/hal/ppc_regs.h>		/* on-chip resource layout, special */

#------------------------------------------------------------------------------

// No useable LEDs
#define LED(x)                          
	
#------------------------------------------------------------------------------       
                
FUNC_START( hal_hardware_init )
        li      r3,0x00000000         // Make sure nothing is cacheable
        mticcr  r3
        mtdccr  r3
        // Force data caches to be totally clean
        lwi     r3,0
        lwi     r4,0x8000
10:     dcbf    0,r3
        dccci   0,r3
        addi    r3,r3,16
        cmpw    r3,r4
        bne     10b
        lwi     r3,0x80000000         // DRAM cached - instructions only
        iccci   0,r3
        mticcr  r3
#ifdef MNDHWR_VIRTEX4_DATACACHE
        lwi     r3,0x80000000
        mtdccr  r3
#endif
	blr
FUNC_END( hal_hardware_init )

        .globl  _hang
_hang:   nop
        b       _hang
        blr
        
#ifdef CYG_HAL_STARTUP_ROMRAM
        .section .boot0,"ax"
        .global _boot0

_boot0: 
        lwi     r0,_start
        mtlr    r0
        blr

        .section .boot,"ax"
        .global _boot

_boot:  
        b       _boot0
#endif        

#------------------------------------------------------------------------------
# end of virtex4.S
