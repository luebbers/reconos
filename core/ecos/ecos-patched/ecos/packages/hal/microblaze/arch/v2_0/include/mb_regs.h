#ifndef CYGONCE_HAL_MB_REGS_H
#define CYGONCE_HAL_MB_REGS_H

//==========================================================================
//
//      mb_regs.h
//
//      MicroBlaze CPU definitions
//
//==========================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
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
// Date:         1999-02-19
// Purpose:      Provide PPC register definitions
// Description:  Provide PPC register definitions
//               The short difinitions (sans CYGARC_REG_) are exported only
//               if CYGARC_HAL_COMMON_EXPORT_CPU_MACROS is defined.
// Usage:
//               #include <cyg/hal/ppc_regs.h>
//               ...
//              
//
//####DESCRIPTIONEND####
//
//==========================================================================

#include <pkgconf/hal.h>

#include <cyg/hal/var_regs.h>

//--------------------------------------------------------------------------
// SPR access macros.
#define CYGARC_MTSPR(_spr_, _v_) \
    asm volatile ("mts "_spr_", %0;" :: "r" (_v_));
#define CYGARC_MFSPR(_spr_, _v_) \
    asm volatile ("mfs %0, "_spr_";" : "=r" (_v_));

//--------------------------------------------------------------------------
// Generic MicroBlaze Family Definitions
//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
// Some GPRs
// Position in GPR wihout R0 (R0 has always value 0)
#define	CYGARC_GPR_SP		0				// R1 - stack pointer
#define	CYGARC_GPR_RSPA		1				// R2 - small data area pointer - for read only
#define	CYGARC_GPR_RWSPA	12				// R13 - small data area pointer - for read-write
#define	CYGARC_GPR_IRA		13				// R14 - return address for interrupt
#define	CYGARC_GPR_LR		14				// R15 - return address for sub-routine (link register)
#define	CYGARC_GPR_TRA		15				// R16 - return address for trap
#define	CYGARC_GPR_EXA		16				// R17 - return address for exceptions
#define	CYGARC_GPR_ASM		17				// R18 - reserved for assembler


//--------------------------------------------------------------------------
// Some SPRs
#define CYGARC_REG_PC	"rpc"
#define CYGARC_REG_MSR	"rmsr"

#ifdef CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
	#define RPC      	CYGARC_REG_PC
	#define RMSR        	CYGARC_REG_MSR
#endif

//--------------------------------------------------------------------------
// MSR bits
#define CYGARC_REG_MSR_BE       0x00000001   // buslock enable
#define CYGARC_REG_MSR_IE       0x00000002   // interrupt enable
#define CYGARC_REG_MSR_C        0x00000004   // arithmetic carry
#define CYGARC_REG_MSR_BIP      0x00000008   // brake in progress
#define CYGARC_REG_MSR_FSL      0x00000010   // FSL error
#define CYGARC_REG_MSR_ICE      0x00000020   // instruction cach enable
#define CYGARC_REG_MSR_DZ       0x00000040   // division by zero
#define CYGARC_REG_MSR_DCE      0x00000080   // data cache enable
#define CYGARC_REG_MSR_EE       0x00000100   // exception enable
#define CYGARC_REG_MSR_EIP      0x00000200   // exception in progress
#define CYGARC_REG_MSR_CC       0x80000000   // arithmetic carry copy

#ifdef CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
	#define MSR_BE         CYGARC_REG_MSR_BE 
	#define MSR_IE         CYGARC_REG_MSR_IE 
	#define MSR_C          CYGARC_REG_MSR_C 
	#define MSR_BIP        CYGARC_REG_MSR_BIP 
	#define MSR_FSL        CYGARC_REG_MSR_FSL 
	#define MSR_ICE        CYGARC_REG_MSR_ICE
	#define MSR_DZ         CYGARC_REG_MSR_DZ 
	#define MSR_DCE        CYGARC_REG_MSR_DCE 
	#define MSR_EE         CYGARC_REG_MSR_EE
	#define MSR_EIP        CYGARC_REG_MSR_EIP 
	#define MSR_CC         CYGARC_REG_MSR_CC 
#endif // ifdef CYGARC_HAL_COMMON_EXPORT_CPU_MACROS

//-----------------------------------------------------------------------------
#endif // ifdef CYGONCE_HAL_MB_REGS_H
// End of mb_regs.h
