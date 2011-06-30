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
//
// Alternative licenses for eCos may be arranged by contacting Red Hat, Inc.
// at http://sources.redhat.com/ecos/ecos-license/
// -------------------------------------------
//####ECOSGPLCOPYRIGHTEND####
//=============================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):   hmt
// Contributors:hmt, gthomas
// Date:        1999-06-08
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

#if defined(CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS)
#include <cyg/hal/hal_stub.h>           // hal_output_gdb_string
#endif

#include "xbasic_types.h"
#include "xparameters.h"
#include <xparameters_translation.h>
#include "xuartns550.h"
#include "xstatus.h"

// REMOVEME
void inline led( unsigned int l ) {

    volatile unsigned int *ledptr = (unsigned int*) 0x81440000;

    // set as outputs
    *(ledptr+1) = 0x00000000;

    *ledptr = l;
}


//=============================================================================
// Serial driver
//=============================================================================

//-----------------------------------------------------------------------------
typedef struct {
    cyg_int32  dev_id;
    cyg_int32  msec_timeout;
    int        isr_vector;
    bool       dev_ok;
    int        int_state;
    int        *ctrlc;
    unsigned char inq[16];
    unsigned char *qp;
    int            qlen;
    XUartNs550 dev;
} channel_data_t;

static channel_data_t channels[] = {
    { UPBHWR_UART16550_0_DEVICE_ID, 1000, CYGNUM_HAL_INTERRUPT_UART0},
};

static void cyg_hal_plf_serial_isr_handler(channel_data_t *chan, int event, int len);

//-----------------------------------------------------------------------------
static void
init_serial_channel(channel_data_t *chan)
{
    XStatus stat;
    XUartNs550Format fmt;
    Xuint16 opt;
   
    stat = XUartNs550_Initialize(&chan->dev, chan->dev_id);
    
    if (stat != XST_SUCCESS) {
        return;  // What else can be done?
    }

    // Configure the port
    fmt.BaudRate = CYGNUM_HAL_VIRTUAL_VECTOR_CONSOLE_CHANNEL_BAUD;
    fmt.DataBits = XUN_FORMAT_8_BITS;
    fmt.Parity = XUN_FORMAT_NO_PARITY;
    fmt.StopBits = XUN_FORMAT_1_STOP_BIT;
    stat = XUartNs550_SetDataFormat(&chan->dev, &fmt);
    if (stat != XST_SUCCESS) {
        return;  // What else can be done?
    }

    opt = XUN_OPTION_FIFOS_ENABLE | XUN_OPTION_RESET_TX_FIFO | XUN_OPTION_RESET_RX_FIFO;
    opt = 0;
    stat = XUartNs550_SetOptions(&chan->dev, opt);

    if (stat != XST_SUCCESS) {
        return;  // What else can be done?
    }

    XUartNs550_SetHandler(&chan->dev, cyg_hal_plf_serial_isr_handler, chan);
    XUartNs550_SetFifoThreshold(&chan->dev, XUN_FIFO_TRIGGER_01);
    chan->qlen = 0;  // No characters buffered
    chan->dev_ok = true;
}

static cyg_bool
cyg_hal_plf_serial_getc_nonblock(channel_data_t *chan, cyg_uint8 *ch)
{
    if (!chan->dev_ok) return false;
    if (chan->qlen == 0) {
        // See if any characters are now available
        chan->qp = chan->inq;
        chan->qlen = XUartNs550_Recv(&chan->dev, chan->qp, sizeof(chan->inq));
    }
    if (chan->qlen) {
        *ch = *chan->qp++;
        chan->qlen--;
        return true;
    }
    return false;
}

cyg_uint8
cyg_hal_plf_serial_getc(channel_data_t *chan)
{
    cyg_uint8 ch;

    while(!cyg_hal_plf_serial_getc_nonblock(chan, &ch));
    return ch;
}


void
cyg_hal_plf_serial_putc(channel_data_t *chan, cyg_uint8 c)
{
    if (!chan->dev_ok) return;
    XUartNs550_Send(&chan->dev, &c, 1);
    // Wait for character to get out
    while (XUartNs550_IsSending(&chan->dev)) ;
}

static void
cyg_hal_plf_serial_write(channel_data_t *chan, cyg_uint8* buf, 
                         cyg_uint32 len)
{
    while(len-- > 0)
        cyg_hal_plf_serial_putc(chan, *buf++);
}

static void
cyg_hal_plf_serial_read(channel_data_t *chan, cyg_uint8* buf, cyg_uint32 len)
{
    while(len-- > 0)
        *buf++ = cyg_hal_plf_serial_getc(chan);
}

cyg_bool
cyg_hal_plf_serial_getc_timeout(channel_data_t *chan, cyg_uint8* ch)
{
    int delay_count;
    cyg_bool res;

    delay_count = chan->msec_timeout * 10; // delay in .1 ms steps
    for(;;) {
        res = cyg_hal_plf_serial_getc_nonblock(chan, ch);
        if (res || 0 == delay_count--)
            break;
        CYGACC_CALL_IF_DELAY_US(100);
    }
    return res;
}

static int
cyg_hal_plf_serial_control(channel_data_t *chan, __comm_control_cmd_t func, ...)
{
    Xuint16 opt;
    int ret = 0;

    led(1);

    if (!chan->dev_ok) return ret;

    switch (func) {
    case __COMMCTL_IRQ_ENABLE:
        opt = XUartNs550_GetOptions(&chan->dev) | XUN_OPTION_DATA_INTR;
        XUartNs550_SetOptions(&chan->dev, opt);
        HAL_INTERRUPT_UNMASK(chan->isr_vector);
        chan->int_state = 1;
        break;
    case __COMMCTL_IRQ_DISABLE:
        ret = chan->int_state;
        chan->int_state = 0;
        opt = XUartNs550_GetOptions(&chan->dev) & ~XUN_OPTION_DATA_INTR;
        XUartNs550_SetOptions(&chan->dev, opt);
        HAL_INTERRUPT_MASK(chan->isr_vector);        
        break;
    case __COMMCTL_DBG_ISR_VECTOR:
        ret = chan->isr_vector;
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

static int
cyg_hal_plf_serial_isr(channel_data_t *chan, int *ctrlc, 
                       CYG_ADDRWORD vector, CYG_ADDRWORD data)
{
    chan->ctrlc = ctrlc;
    XUartNs550_InterruptHandler(&chan->dev);
    HAL_INTERRUPT_ACKNOWLEDGE(chan->isr_vector);
    return CYG_ISR_HANDLED;
}

static void
cyg_hal_plf_serial_isr_handler(channel_data_t *chan,
                               int event, int len)
{
    int res;
    char ch;

    *chan->ctrlc = 0;
    switch (event) {
    case XUN_EVENT_RECV_ERROR:
    case XUN_EVENT_RECV_TIMEOUT:
    case XUN_EVENT_MODEM:
        diag_printf("%s.%d - chan: %p, event: %d\n", __FUNCTION__, __LINE__, chan, event);
        break;
    case XUN_EVENT_RECV_DATA:
        res = XUartNs550_Recv(&chan->dev, &ch, 1);
        if (cyg_hal_is_break(&ch , 1))
            *chan->ctrlc = 1;
        break;
    case XUN_EVENT_SENT_DATA:
        return;
    default:
    	break;
    }
}                               

void
cyg_hal_plf_serial_init(void)
{
    hal_virtual_comm_table_t* comm;
    int cur = CYGACC_CALL_IF_SET_CONSOLE_COMM(CYGNUM_CALL_IF_SET_COMM_ID_QUERY_CURRENT);

    // Disable interrupts.
    HAL_INTERRUPT_MASK(channels[0].isr_vector);

    // Init channels
    init_serial_channel(&channels[0]);

    // Setup procs in the vector table

    // Set channel 0
    CYGACC_CALL_IF_SET_CONSOLE_COMM(0);
    comm = CYGACC_CALL_IF_CONSOLE_PROCS();
    CYGACC_COMM_IF_CH_DATA_SET(*comm, &channels[0]);
    CYGACC_COMM_IF_WRITE_SET(*comm, cyg_hal_plf_serial_write);
    CYGACC_COMM_IF_READ_SET(*comm, cyg_hal_plf_serial_read);
    CYGACC_COMM_IF_PUTC_SET(*comm, cyg_hal_plf_serial_putc);
    CYGACC_COMM_IF_GETC_SET(*comm, cyg_hal_plf_serial_getc);
    CYGACC_COMM_IF_CONTROL_SET(*comm, cyg_hal_plf_serial_control);
    CYGACC_COMM_IF_DBG_ISR_SET(*comm, cyg_hal_plf_serial_isr);
    CYGACC_COMM_IF_GETC_TIMEOUT_SET(*comm, cyg_hal_plf_serial_getc_timeout);
    
    // Restore original console
    CYGACC_CALL_IF_SET_CONSOLE_COMM(cur);
}

// EOF hal_diag.c
