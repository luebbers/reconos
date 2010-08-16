//=============================================================================
//
//      virtex4_kbd.c
//
//      Keyboard driver
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2005 Mind n.v.
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
//=============================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):   Carlos Duclos 
// Contributors:
// Date:        2005-05-26
// Purpose:     Complete keyboard driver
// Description: PS/2 keyboard driver
//
//####DESCRIPTIONEND####
//
//=============================================================================

#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <pkgconf/hal.h>
#include <pkgconf/devs_kbd_virtex4.h>
#include <cyg/infra/cyg_type.h>         // base types
#include <cyg/infra/cyg_trac.h>         // tracing macros
#include <cyg/infra/cyg_ass.h>          // assertion macros
#include <cyg/kernel/kapi.h>
#include <cyg/hal/hal_io.h>
#include <cyg/hal/hal_arch.h>
#include <cyg/hal/drv_api.h>
#include <cyg/hal/hal_intr.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/infra/cyg_ass.h>
#include <cyg/fileio/fileio.h>
#include <cyg/io/devtab.h>
#include <cyg/hal/charmap.h>

#include "xbasic_types.h"
#include "xparameters.h"
#include <xparameters_translation.h>
#include "xps2.h"
#include "xstatus.h"

#include <xps2_l.h>

#define WAITING_KEYCODE 0
#define WAITING_KEYUP 1
#define WAITING_ECHO_SCANCODE 2
#define LED_OFF 0
#define LED_ON 1
#define BUFFER_SIZE 64

typedef struct {
    cyg_uint8 pool[ BUFFER_SIZE ];
    cyg_uint8 * pointer;
    cyg_uint32 total;
} keyboard_buffer;

typedef struct {
    keyboard_buffer incoming_characters;
    bool initialized;
    bool started;
    cyg_int32 irq;
    cyg_int32 state;
    XPs2 device;
    cyg_interrupt interrupt;
    cyg_handle_t interrupt_handle;
} keyboard_device;

static keyboard_device keyboard;

enum special_keys_states { NO_SPECIAL_KEY = 0, SHIFT_PRESSED, CTRL_PRESSED, ALT_PRESSED, CAPS_LOCK_PRESSED, NUM_LOCK_PRESSED };
enum special_keys_desc { ALT = 17, SHIFT = 18, CTRL = 20, CAPS_LOCK = 88, NUM_LOCK = 119, SCROLL_LOCK = 126 };
enum keyboard_commands { LEDS = 0xED, KBD_ACK = 0xFA };

// Functions implemented
static Cyg_ErrNo keyboard_write( cyg_io_handle_t handle, void * buffer, cyg_uint32 * length );
static Cyg_ErrNo keyboard_read( cyg_io_handle_t handle, void * buffer, cyg_uint32 * length );
static bool      keyboard_init( struct cyg_devtab_entry * table );
static Cyg_ErrNo keyboard_lookup( struct cyg_devtab_entry ** table, struct cyg_devtab_entry * start, const char * name );

CHAR_DEVIO_TABLE(keyboard_handlers, keyboard_write, keyboard_read, NULL, NULL, NULL ); 
CHAR_DEVTAB_ENTRY(keyboard_entry, CYGDAT_DEVS_KBD_VIRTEX4_NAME, NULL, &keyboard_handlers, keyboard_init, keyboard_lookup, &keyboard );

static int keyboard_isr( cyg_vector_t vector, cyg_addrword_t data )
{
    keyboard_device * k = (keyboard_device *)data;

    cyg_drv_interrupt_mask( k->irq );

    return (CYG_ISR_HANDLED|CYG_ISR_CALL_DSR);
}

static void keyboard_dsr( cyg_vector_t vector, cyg_ucount32 count, cyg_addrword_t data )
{
    keyboard_device * k = (keyboard_device *)data;
    cyg_ucount32 pending_characters = 0;
    cyg_int32 i = 0;
    cyg_uint8 received = 0;
    
    // Get characters!
    for( i = k->incoming_characters.total; (pending_characters < count) && (i < BUFFER_SIZE); pending_characters++, i++ )
    {
        received = XPs2_RecvByte( k->device.BaseAddress );
        k->incoming_characters.pool[ i ] = received;
    }
        
    // Return to normal life
    cyg_drv_interrupt_acknowledge( k->irq );
    cyg_drv_interrupt_unmask( k->irq );
}

static bool keyboard_init( struct cyg_devtab_entry * table )
{
    XStatus stat = XST_FAILURE;
    keyboard_device * k = (keyboard_device *)table->priv;
    
    stat = XPs2_Initialize(&k->device, XPAR_PS2_DUAL_REF_0_DEVICE_ID_1 );
    if( stat != XST_SUCCESS )
    {
        diag_printf( "Cannot initialize ps2 keyboard! \n" );
        k->initialized = false;
        k->started = false;
        return false;  // What else can be done?
    }
    k->incoming_characters.total = 0;
    k->incoming_characters.pointer = k->incoming_characters.pool;
    k->initialized = true;
    k->started = false;
    k->state = WAITING_KEYCODE;

    return true;
}

static Cyg_ErrNo keyboard_read( cyg_io_handle_t handle, void * buffer, cyg_uint32 * length )
{
    cyg_devtab_entry_t * p    = (cyg_devtab_entry_t *) handle;
    keyboard_device * k = (keyboard_device *)p->priv;
    cyg_uint8 s = 0, t = 0;
    cyg_uint32 i = 0;

    if( k->started == false )
        return ENODEV;

    cyg_scheduler_lock();    
    if( k->incoming_characters.total == 0 )
    {
        *buffer = '\0';
        *length = 0;
        cyg_scheduler_unlock();
        return ENOERR;
    }
    for( i = 0; i < *length; i++ )
    {
        s = *k->incoming_characters.pointer++;
        if( k->state == WAITING_KEYCODE )
        {
            // Convert this from code to key
            t = charmap[ s ];
            if( t == ALT )
            {
                k->incoming_characters.total--;
                continue;
            } else if( t == SHIFT )
            {
                k->incoming_characters.total--;
                continue;
            } else if( t == CTRL )
            {
                k->incoming_characters.total--;
                continue;
            } 
            k->state = WAITING_KEYUP;
            buffer[ i ] = t;
            k->incoming_characters.total--;
        } else if( k->state == WAITING_KEYUP )
        {
            k->incoming_characters.total--;
            k->state = WAITING_ECHO_SCANCODE;
            continue;
        } else if( k->state == WAITING_ECHO_SCANCODE )
        {
            k->incoming_characters.total--;
            k->state = WAITING_KEYCODE;
            continue;
        }
    }
    cyg_scheduler_unlock();
    
    return ENOERR;
}

static Cyg_ErrNo keyboard_write( cyg_io_handle_t handle, void * buffer, cyg_uint32 * length );
{
    return ENOERR;
}

/*
 * Make keyboard "Online"
 */

static Cyg_ErrNo keyboard_lookup( struct cyg_devtab_entry ** table, struct cyg_devtab_entry * start, const char * name )
{
    keyboad_device * k = (keyboard_device *)(*table)->priv;
    
    // Set up to handle interrupts
    if( k->started )
        return ENOERR;

    cyg_drv_interrupt_create( k->irq, 0, (cyg_addrword_t)k, (cyg_ISR_t *)keyboard_isr, (cyg_DSR_t *)keyboard_dsr, &k->interrupt_handle, &k->interrupt );
    cyg_drv_interrupt_attach( k->interrupt_handle );
    cyg_drv_interrupt_acknowledge( k->irq );
    cyg_drv_interrupt_unmask( k->irq );
    XPs2_EnableInterrupt( k->device );
    k->started = true;

    return ENOERR;
}
