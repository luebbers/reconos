///
/// \file profile_timer.c
///
/// Profiling timer routines
///
/// \author     Andreas Agne <agne@upb.de>
/// \date       09.05.2008
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

#include <pkgconf/hal.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/hal/hal_mem.h>            // HAL memory definitions
#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <cyg/hal/ppc_regs.h>           // Platform registers
#include <cyg/hal/hal_if.h>             // hal_if_init
#include <cyg/hal/hal_intr.h>           // interrupt definitions
#include <cyg/infra/cyg_ass.h>          // assertion macros
#include <cyg/hal/hal_io.h>             // I/O macros
#include <cyg/infra/diag.h>
#include <cyg/hal/i2c_support.h>        // i2c support routines

#include <cyg/profile/profile.h>

// Can't rely on Cyg_Interrupt class being defined.
#define Cyg_InterruptHANDLED 1


// Periodic timer ISR.
static cyg_uint32 fit_isr(CYG_ADDRWORD vector, CYG_ADDRWORD data, HAL_SavedRegisters *regs)
{
	HAL_INTERRUPT_ACKNOWLEDGE(vector);
	
	__profile_hit(regs->pc);
	
	return Cyg_InterruptHANDLED;
}

int hal_enable_profile_timer(int resolution)
{
	// Attach pit isr.
	HAL_INTERRUPT_ATTACH (CYGNUM_HAL_INTERRUPT_FIT, &fit_isr, 0, 0);
	//HAL_INTERRUPT_SET_LEVEL (CYGNUM_HAL_INTERRUPT_SIU_PIT, PIT_IRQ_LEVEL);
	HAL_INTERRUPT_UNMASK (CYGNUM_HAL_INTERRUPT_FIT);
	
	return 6216; // XXX FIXME: there is currently no way to determine the resolution (not found in xparameters.h)
	             // other than looking it up in the EDK settings
}


