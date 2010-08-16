//=============================================================================
//
//      hal_diag.c
//
//      HAL diagnostic I/O code
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002, 2003, 2004, 2005 Mind n.v.
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
// Author(s):   hmt
// Contributors:hmt, gthomas, 
//              cduclos
// Date:        2005-05-26
//              1999-06-08
// Purpose:     HAL diagnostic output
// Description: Implementations of HAL diagnostic I/O support.
//
//####DESCRIPTIONEND####
//
//=============================================================================

#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <pkgconf/hal.h>

#include <cyg/infra/cyg_type.h>         // base types
#include <cyg/infra/cyg_trac.h>         // tracing macros
#include <cyg/infra/cyg_ass.h>          // assertion macros

#include <cyg/hal/hal_io.h>             // IO macros
#include <cyg/hal/hal_diag.h>
#include <cyg/hal/hal_intr.h>           // Interrupt macros
#include <cyg/hal/drv_api.h>
#include <cyg/hal/lcd_support.h>
#include <cyg/hal/simple_keyboard.h>

#if defined(CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS)
#include <cyg/hal/hal_stub.h>           // hal_output_gdb_string
#endif

#include "xbasic_types.h"
#include "xparameters.h"
#include "xtft.h"
#ifdef MNDHWR_VIRTEX4_PS21
#include "xps2.h"
#endif
#include "xstatus.h"

//=============================================================================
// Console driver
//=============================================================================

//-----------------------------------------------------------------------------
typedef struct {
    cyg_int32  msec_timeout;
    bool       dev_ok;
    int        int_state;
    int        *ctrlc;
} channel_data_t;

static channel_data_t channels[] = {
    { 1000 }
};

//-----------------------------------------------------------------------------
static void
init_lcd_channel(channel_data_t *chan)
{
    lcd_init( 0 );
    init_simple_keyboard();
    chan->dev_ok = true;
}

static cyg_bool
cyg_hal_plf_lcd_getc_nonblock(channel_data_t *chan, cyg_uint8 *ch)
{
    int status = 0;
    
    status = read_simple_keyboard( ch );
    if( status < 0 )
        return false;
        
    return true;
}

cyg_uint8
cyg_hal_plf_lcd_getc(channel_data_t *chan)
{
    cyg_uint8 ch;

    while(!cyg_hal_plf_lcd_getc_nonblock(chan, &ch));
    return ch;
}

void
cyg_hal_plf_lcd_putc(channel_data_t *chan, cyg_uint8 c)
{
    if (!chan->dev_ok) 
        return;
    lcd_putc(c);
}

static void
cyg_hal_plf_lcd_write(channel_data_t *chan, cyg_uint8* buf, 
                         cyg_uint32 len)
{
    while(len-- > 0)
        cyg_hal_plf_lcd_putc(chan, *buf++);
}

static void
cyg_hal_plf_lcd_read(channel_data_t *chan, cyg_uint8* buf, cyg_uint32 len)
{
    while(len-- > 0)
        *buf++ = cyg_hal_plf_lcd_getc(chan);
}

cyg_bool
cyg_hal_plf_lcd_getc_timeout(channel_data_t *chan, cyg_uint8* ch)
{
    int delay_count;
    cyg_bool res;

    delay_count = chan->msec_timeout * 10; // delay in .1 ms steps
    for(;;) {
        res = cyg_hal_plf_lcd_getc_nonblock(chan, ch);
        if (res || 0 == delay_count--)
            break;
        CYGACC_CALL_IF_DELAY_US(100);
    }
    return res;
}

static int
cyg_hal_plf_lcd_control(channel_data_t *chan, __comm_control_cmd_t func, ...)
{
    Xuint16 opt;
    int ret = 0;

    if (!chan->dev_ok) return ret;

    switch (func) {
    case __COMMCTL_IRQ_ENABLE:
        break;
    case __COMMCTL_IRQ_DISABLE:
        break;
    case __COMMCTL_DBG_ISR_VECTOR:
        break;
    case __COMMCTL_SET_TIMEOUT:
    {
        va_list ap;

        va_start(ap, func);

        ret = chan->msec_timeout;
        chan->msec_timeout = va_arg(ap, cyg_uint32);

        va_end(ap);
    }        
    default:
        break;
    }
    return ret;
}

void
cyg_hal_plf_lcd_init()
{
    hal_virtual_comm_table_t* comm;
    int cur = CYGACC_CALL_IF_SET_CONSOLE_COMM(CYGNUM_CALL_IF_SET_COMM_ID_QUERY_CURRENT);

    // Disable interrupts.
    disable_interrupt_simple_keyboard();

    // Init channels
    init_lcd_channel(&channels[0]);

    // Setup procs in the vector table

    // Set channel 0
    CYGACC_CALL_IF_SET_CONSOLE_COMM(0);
    comm = CYGACC_CALL_IF_CONSOLE_PROCS();
    CYGACC_COMM_IF_CH_DATA_SET(*comm, &channels[0]);
    CYGACC_COMM_IF_WRITE_SET(*comm, cyg_hal_plf_lcd_write);
    CYGACC_COMM_IF_READ_SET(*comm, cyg_hal_plf_lcd_read);
    CYGACC_COMM_IF_PUTC_SET(*comm, cyg_hal_plf_lcd_putc);
    CYGACC_COMM_IF_GETC_SET(*comm, cyg_hal_plf_lcd_getc);
    CYGACC_COMM_IF_CONTROL_SET(*comm, cyg_hal_plf_lcd_control);
    CYGACC_COMM_IF_GETC_TIMEOUT_SET(*comm, cyg_hal_plf_lcd_getc_timeout);

    // Restore original console
    CYGACC_CALL_IF_SET_CONSOLE_COMM(cur);
}

