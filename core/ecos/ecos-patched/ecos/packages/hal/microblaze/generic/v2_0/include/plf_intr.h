#ifndef CYGONCE_HAL_PLF_INTR_H
#define CYGONCE_HAL_PLF_INTR_H

//==========================================================================
//
//      plf_intr.h
//
//      Generic platform specific interrupt definitions
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
// Date:         2000-06-13
// Purpose:      Define platform specific interrupt support
//
// Usage:
//              #include <cyg/hal/plf_intr.h>
//              ...
//
//
//####DESCRIPTIONEND####
//
//==========================================================================

#include <pkgconf/hal.h>

#include <cyg/infra/cyg_type.h>

//----------------------------------------------------------------------------
// Platform specific interrupt mapping - interrupt vectors
#define CYGHWR_HAL_INTERRUPT_LAYOUT_DEFINED

/* maximum number of interrupt */
#define CYGNUM_HAL_ISR_MAX		MON_INTC_NUM_INTR

//Real-time clock
#ifndef CYGNUM_HAL_INTERRUPT_RTC
#define CYGNUM_HAL_INTERRUPT_RTC	MON_TIMER_INTR
#endif // CYGNUM_HAL_INTERRUPT_RTC

// Platform specific interrupt handling - using EPIC
#define CYGHWR_HAL_INTERRUPT_CONTROLLER_ACCESS_DEFINED
externC void hal_interrupt_init(void);
externC void hal_interrupt_mask(int);
externC void hal_interrupt_unmask(int);
externC void hal_interrupt_acknowledge(int);
externC void hal_interrupt_configure(int, int, int);
externC void hal_interrupt_set_level(int, int);

#define HAL_PLF_INTERRUPT_INIT()				hal_interrupt_init()
#define HAL_INTERRUPT_MASK( _vector_ )				hal_interrupt_mask( _vector_ )
#define HAL_INTERRUPT_UNMASK( _vector_ )			hal_interrupt_unmask( _vector_ )
#define HAL_INTERRUPT_ACKNOWLEDGE( _vector_ )			hal_interrupt_acknowledge( _vector_ )
#define HAL_INTERRUPT_CONFIGURE( _vector_, _level_, _up_ )	hal_interrupt_configure( _vector_, _level_, _up_ )
#define HAL_INTERRUPT_SET_LEVEL( _vector_, _level_ )		hal_interrupt_set_level( _vector_, _level_ )

//-----------------------------------------------------------------------------
// Symbols used by assembly code
#define CYGARC_PLATFORM_DEFS

//----------------------------------------------------------------------------
/* Reseting board */

externC void _platform_reset(void);
#define HAL_PLATFORM_RESET() _platform_reset()
#define HAL_PLATFORM_RESET_ENTRY 0x00000000

//--------------------------------------------------------------------------
#endif // ifndef CYGONCE_HAL_PLF_INTR_H
// End of plf_intr.h
