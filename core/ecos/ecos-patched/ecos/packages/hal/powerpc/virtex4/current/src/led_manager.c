//=============================================================================
//
//      led_manager.c
//
//      VIRTEX4 led support
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 2004 eCosCentric Limited
// Copyright (C) 2005 Mind n.v.
// Copyright (C) 2007 ReconOS
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
// -------------------------------------------
//####ECOSGPLCOPYRIGHTEND####
//=============================================================================
//####DESCRIPTIONBEGIN####
//
// Author(s):   Carlos Duclos 
// Date:        2005-05-23
//####DESCRIPTIONEND####
//=============================================================================

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

#include "xbasic_types.h"
#include "xgpio.h"
#include "xgpio_l.h"
#include "xparameters.h"

#include <cyg/hal/led_manager.h>
#include <cyg/hal/gpio_basic.h>

/*
 * All low level work is done in gpio_manager
 */

/*
 * Exported interface
 */
 
void init_led_manager()
{
    int i;

    init_gpio_manager();
    // turn off all LEDs
    turn_off_led(ALL_LEDS);
    return;
}

int get_status_led_manager( cyg_uint32 * status )
{
    int result = 0;
    
    result = get_status_gpio( status );
    
    return result;
}

int turn_on_led( cyg_uint32 led )
{
    int result = 0;

#if defined(CYGHWR_HAL_VIRTEX_BOARD_ML403)    
    result = turn_on_bit( led );
#elif defined(CYGHWR_HAL_VIRTEX_BOARD_XUP)
    result = turn_off_bit( led );     // XUP LEDs are low-active
#endif
    
    return result;
}

int turn_off_led( cyg_uint32 led )
{
    int result = 0;
    
#if defined(CYGHWR_HAL_VIRTEX_BOARD_ML403)    
    result = turn_off_bit( led );
#elif defined(CYGHWR_HAL_VIRTEX_BOARD_XUP)
    result = turn_on_bit( led );     // XUP LEDs are low-active
#endif

    return result;
}
