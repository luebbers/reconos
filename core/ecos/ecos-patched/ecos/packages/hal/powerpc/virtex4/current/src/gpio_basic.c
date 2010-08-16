//=============================================================================
//
//      gpio_basic.c
//
//      VIRTEX4 gpio support
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
// Date:        2005-05-24
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
#include <xparameters_translation.h>

#include <cyg/hal/gpio_basic.h>


//---------------------------------------------------------
// This code controls only ONE instance of a GPIO device.
// This means that you need to connect ALL switches and
// LEDs to the same GPIO peripheral.
//
// They'd better call this module "button_and_led_manager" 
//---------------------------------------------------------

static Xboolean gpio_initialized = XFALSE;
static XGpio gpio_manager_device;

// hard-coded addresses are ugly. Now defined in xparameters_translation.h
//#define GPIO_MANAGER_ADDRESS     0x90000000

/*
 * Low level routines
 */
 
static int toggle_bit_on( cyg_uint32 bit_number ) 
{
    volatile cyg_uint32 * bit_register = (volatile cyg_uint32 *)GPIO_MANAGER_ADDRESS;
    cyg_uint32 temporal = 0;
    
    temporal = *bit_register;
    temporal = temporal | bit_number;
    *bit_register = temporal;
    
    return 0;
}

static int toggle_bit_off( cyg_uint32 bit_number )
{
    volatile cyg_uint32 * bit_register = (volatile cyg_uint32 *)GPIO_MANAGER_ADDRESS;
    cyg_uint32 temporal = 0, mask = 0;
    
    temporal = *bit_register;
    mask = ~bit_number;
    temporal = temporal & mask;
    *bit_register = temporal;
    
    return 0;
}

static int get_status( cyg_uint32 * status )
{
    volatile cyg_uint32 * gpio_register = (volatile cyg_uint32 *)GPIO_MANAGER_ADDRESS;
    cyg_uint32 temporal = 0;

    temporal = *gpio_register;
    *status = temporal;

    return 0;
}


/*
 * Simple abstraction to simplify the exported interface
 */
 
static int sw_init()
{
    XStatus status = 0;

    status = XGpio_Initialize( &gpio_manager_device, UPBHWR_GPIO_0_DEVICE_ID );
    if( status != XST_SUCCESS )
    {
        diag_printf( "Could not initialze sw led manager\n" );
        return -1;
    }

    return 0;
}

static int hw_init()
{
#if defined(CYGHWR_HAL_VIRTEX_BOARD_ML403)
    XGpio_SetDataDirection( &gpio_manager_device, 1, 0xFFFFFE00 );      // lower nine bits are outpus
#elif defined(CYGHWR_HAL_VIRTEX_BOARD_XUP)
    XGpio_SetDataDirection( &gpio_manager_device, 1, 0xFFFFFFF0 );      // lower four bits are outputs
#else
#error Unsupported board.
#endif

#if defined(UPBHWR_VIRTEX4_GPIOINTR)
    // turn on the global interrupts by default
    XGpio_InterruptGlobalEnable(&gpio_manager_device);
#endif
    
    return 0;
}



/*
 * Exported Interface
 */

#if defined(UPBHWR_VIRTEX4_GPIOINTR)
void enable_interrupt_gpio( cyg_uint32 mask )
{
    XGpio_InterruptEnable(&gpio_manager_device, mask);
}


void disable_interrupt_gpio( cyg_uint32 mask )
{
    XGpio_InterruptDisable(&gpio_manager_device, mask);
}


void clear_interrupt_gpio( cyg_uint32 mask )
{
    XGpio_InterruptClear(&gpio_manager_device, mask);
}
#endif

 
void init_gpio_manager()
{
    int result = 0;

    if( gpio_initialized == XTRUE )
        return;

    result = sw_init();
    if( result < 0 )
        return -1;
    result = hw_init();
    if( result < 0 )
        return -1;

    gpio_initialized = XTRUE;

    return;
}

int get_status_gpio( cyg_uint32 * status )
{
    int result = 0;
    
    result = get_status( status );
    
    return result;
}

int turn_on_bit( cyg_uint32 bit )
{
    int result = 0;
    
    result = toggle_bit_on( bit );
    
    return result;
}

int turn_off_bit( cyg_uint32 bit )
{
    int result = 0;
    
    result = toggle_bit_off( bit );

    return result;
}
