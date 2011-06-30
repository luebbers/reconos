#ifndef CYGONCE_HAL_VAR_REGS_H
#define CYGONCE_HAL_VAR_REGS_H

//==========================================================================
//
//      var_regs.h
//
//      MicroBlaze 4.00a variant CPU definitions
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
// Date:         2000-02-04
// Purpose:      Provide mb4a register definitions
// Description:  Provide mb4a register definitions
//               The short difinitions (sans CYGARC_REG_) are exported only
//               if CYGARC_HAL_COMMON_EXPORT_CPU_MACROS is defined.
// Usage:        Included via the acrhitecture register header:
//               #include <cyg/hal/ppc_regs.h>
//               ...
//              
//
//####DESCRIPTIONEND####
//
//==========================================================================

#include <cyg/hal/plf_regs.h>  // Get any platform specifics




//--------------------------------------------------------------------------
// Additional seved registers for this variant
#ifdef CYGHWR_HAL_MICROBLAZE_FPU			  					// FPU
	#define	CYGARC_VAR_SAVEDREGS_FPU	cyg_uint32   fsr;		// Floating Point Status Reg
	#define CYGARC_VAR_THREAD_INIT_CONTEXT_FPU	(_regs_)->fsr = 0;
	#define CYGARC_VAR_CONTEXT_SIZE_FPU	1
	#define HAL_GET_GDB_REGISTERS_FPU	_regval_[34] = (_regs_)->fsr; 
	#define HAL_SET_GDB_REGISTERS_FPU	(_regs_)->fsr = _regval_[66]; 
	#define HAL_DEFINE_REGS_OFFSETS_FPU								\
	DEFINE(CYGARC_MBREG_FSR, offsetof(HAL_SavedRegisters, fsr));
	#define HAL_DEFINE_REGS_NAMES_FPU	, FSR
#else
	#define	CYGARC_VAR_SAVEDREGS_FPU
	#define CYGARC_VAR_THREAD_INIT_CONTEXT_FPU
	#define CYGARC_VAR_CONTEXT_SIZE_FPU	0
	#define HAL_GET_GDB_REGISTERS_FPU	_regval_[66] = 0; 
	#define HAL_SET_GDB_REGISTERS_FPU 
	#define HAL_DEFINE_REGS_OFFSETS_FPU									
	#define HAL_DEFINE_REGS_NAMES_FPU
#endif 
  
#ifdef CYGHWR_HAL_MICROBLAZE_HWEXCEPTION_REGS	  				// HW exceptions
	#define CYGARC_VAR_SAVEDREGS_HWEXCEPTION			\
		cyg_uint32   ear;	/* Exception Address Reg */			\
		cyg_uint32   esr;	/* Exception Status Reg */
	#define CYGARC_VAR_THREAD_INIT_CONTEXT_HWEXCEPTION	\
	    (_regs_)->ear = 0;	/* EAR = 0      */   				\
		(_regs_)->esr = 0;	/* ESR = 0      */   	
	#define CYGARC_VAR_CONTEXT_SIZE_HWEXCEPTION	2
	#define HAL_GET_GDB_REGISTERS_HWEXCEPTION			\
		_regval_[35] = (_regs_)->ear; 					\
		_regval_[36] = (_regs_)->esr;
	#define HAL_SET_GDB_REGISTERS_HWEXCEPTION			\
		(_regs_)->ear = _regval_[35]; 					\
		(_regs_)->esr = _regval_[36];
	#define HAL_DEFINE_REGS_OFFSETS_HWEXCEPTION									\
		DEFINE(CYGARC_MBREG_EAR, offsetof(HAL_SavedRegisters, ear));			\
		DEFINE(CYGARC_MBREG_ESR, offsetof(HAL_SavedRegisters, esr));
	#define HAL_DEFINE_REGS_NAMES_HWEXCEPTION	, EAR, ESR
#else
	#define CYGARC_VAR_SAVEDREGS_HWEXCEPTION
	#define CYGARC_VAR_THREAD_INIT_CONTEXT_HWEXCEPTION
	#define CYGARC_VAR_CONTEXT_SIZE_HWEXCEPTION	0
	#define HAL_GET_GDB_REGISTERS_HWEXCEPTION			\
	_regval_[35] = 0; 									\
	_regval_[36] = 0;
	#define HAL_SET_GDB_REGISTERS_HWEXCEPTION
	#define HAL_DEFINE_REGS_OFFSETS_HWEXCEPTION									
	#define HAL_DEFINE_REGS_NAMES_HWEXCEPTION
#endif

//HAL saved registers
#define CYGARC_VAR_ADDITIONAL_SAVEDREGS				\
	CYGARC_VAR_SAVEDREGS_FPU						\
	CYGARC_VAR_SAVEDREGS_HWEXCEPTION

//HAL thread context init for additional registers
#define CYGARC_VAR_ADDITIONAL_THREAD_INIT_CONTEXT	\
	CYGARC_VAR_THREAD_INIT_CONTEXT_FPU				\
	CYGARC_VAR_THREAD_INIT_CONTEXT_HWEXCEPTION

//additional context size
#define CYGARC_VAR_ADDITIONAL_CONTEXT_SIZE			\
	CYGARC_VAR_CONTEXT_SIZE_FPU +					\
	CYGARC_VAR_CONTEXT_SIZE_HWEXCEPTION

#define HAL_GET_ADDITIONAL_GDB_REGISTERS			\
	HAL_GET_GDB_REGISTERS_FPU						\
	HAL_GET_GDB_REGISTERS_HWEXCEPTION

#define HAL_SET_ADDITIONAL_GDB_REGISTERS			\
	HAL_SET_GDB_REGISTERS_FPU						\
	HAL_SET_GDB_REGISTERS_HWEXCEPTION

#define HAL_DEFINE_ADDITIONAL_REGS_OFFSETS			\
	HAL_DEFINE_REGS_OFFSETS_FPU						\
	HAL_DEFINE_REGS_OFFSETS_HWEXCEPTION
	
#define HAL_DEFINE_ADDITIONAL_REGS_NAMES			\
	HAL_DEFINE_REGS_NAMES_FPU						\
	HAL_DEFINE_REGS_NAMES_HWEXCEPTION
	
	
	
//--------------------------------------------------------------------------
// Variant dependent SPRs
#ifdef CYGHWR_HAL_MICROBLAZE_HWEXCEPTION
	#define CYGARC_REG_EAR	"rear"
	#define CYGARC_REG_ESR	"resr"
#endif
#ifdef CYGHWR_HAL_MICROBLAZE_FPU
	#define CYGARC_REG_FSR	"rfsr"
#endif

#ifdef CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
	#ifdef CYGHWR_HAL_MICROBLAZE_HWEXCEPTION_REGS
		#define EAR        	CYGARC_REG_EAR
		#define ESR       	CYGARC_REG_ESR
	#endif
	#ifdef CYGHWR_HAL_MICROBLAZE_FPU
		#define FSR       	CYGARC_REG_FSR
	#endif
#endif



//--------------------------------------------------------------------------
// ESR
#define ESR_ESS		0x00000FE0	// Exception Specific Status
#define ESR_EC		0x0000001F	// Exception Cause
// ESS
#define ESR_WAE		0x00000800	// Word Access Exception
#define ESR_SAE		0x00000400	// Store Access Exception
#define ESR_SDR		0x000003E0	// Source/Destination Register
// EC
#define ESR_UDA		0x00000001	// Unaligned data access exception
#define ESR_IOP		0x00000002	// Illegal op-code exception
#define ESR_IBE		0x00000003	// Instruction bus error exception
#define ESR_DBE		0x00000004	// Data bus error exception
#define ESR_DZ		0x00000005	// Divide by zero exception
#define ESR_FPU		0x00000006	// Floating point unit exception


//--------------------------------------------------------------------------
// FSR
#define FSR_DOP		0x00000001	// Denormalized operand error
#define FSR_UNF		0x00000002	// Underflow
#define FSR_OVF		0x00000004	// Overflow
#define FSR_DZ		0x00000008	// Divide-by-zero
#define FSR_IO		0x00000010	// Invalid operation

//-----------------------------------------------------------------------------
#endif // ifdef CYGONCE_HAL_VAR_REGS_H
// End of var_regs.h
