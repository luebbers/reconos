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
// Copyright (C) 2002, 2003 Gary Thomas
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
// Author(s):      Michal Pfeifer
// Original data:  PowerPC
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
#include <cyg/infra/diag.h>

#include <cyg/hal/hal_io.h>             // IO macros
#include <cyg/hal/hal_diag.h>
#include <cyg/hal/hal_misc.h>           // cyg_hal_is_break()                          
#include <cyg/hal/hal_intr.h>           // Interrupt macros
#include <cyg/hal/drv_api.h>

#if defined(CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS)
#include <cyg/hal/hal_stub.h>           // hal_output_gdb_string
#endif

//#include <cyg/hal/mb_regs.h>

#include "src/xuartns550.h"
#include <pkgconf/hal_microblaze_platform.h>

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
    XUartNs550 dev; //structure for uart16550 driver
} channel_data_t;


// initialize part of structure
static channel_data_t channels[] = {
     { 0, 1000, MON_UART16550_0_INTR },
};

static void cyg_hal_plf_serial_isr_handler(channel_data_t *chan, int event, int len);

//-----------------------------------------------------------------------------
static void
init_serial_channel(channel_data_t *chan)
{
#ifdef MON_UART16550_0
    XStatus stat;
    XUartNs550Format fmt;
    Xuint16 opt;
//	int *led;
//	led = 0x40200000;

//	(&chan->dev)->BaseAddress=0x40400000;

//   XUartNs550_SetBaud(XPAR_RS232_DTE_BASEADDR, XPAR_XUARTNS550_CLOCK_HZ, 9600);
//   XUartNs550_mSetLineControlReg(XPAR_RS232_DTE_BASEADDR, XUN_LCR_8_DATA_BITS);

    stat = XUartNs550_Initialize(&chan->dev, chan->dev_id);
    if (stat != XST_SUCCESS) {
//	*led = 0xfff;
        return;  // What else can be done?
    }

//	*led = *led + 0x2;
    // Configure the port
    fmt.BaudRate = CYGNUM_HAL_VIRTUAL_VECTOR_CONSOLE_CHANNEL_BAUD;
    fmt.DataBits = XUN_FORMAT_8_BITS;
    fmt.Parity = XUN_FORMAT_NO_PARITY;
    fmt.StopBits = XUN_FORMAT_1_STOP_BIT;
    stat = XUartNs550_SetDataFormat(&chan->dev, &fmt);
    if (stat != XST_SUCCESS) {
//	*led = *led + 0x4;
        return;  // What else can be done?
    }
    opt = XUN_OPTION_FIFOS_ENABLE | XUN_OPTION_RESET_TX_FIFO | XUN_OPTION_RESET_RX_FIFO;
    opt = 0;
    stat = XUartNs550_SetOptions(&chan->dev, opt);
    if (stat != XST_SUCCESS) {
//	*led = *led + 0x8;
      return;  // What else can be done?
    }
    XUartNs550_SetHandler(&chan->dev, cyg_hal_plf_serial_isr_handler, (void *)chan);
    XUartNs550_SetFifoThreshold(&chan->dev, XUN_FIFO_TRIGGER_01);
    chan->qlen = 0;  // No characters buffered
    chan->dev_ok = true;
//	*led = *led + 0x10;
#endif
}

cyg_uint8 XUartLite_RecvByte2()
{
	while (  ( XIo_In32(MON_UARTLITE_0_BASE + 0x8) & 0x01 ) != 0x01 );

	return (cyg_uint8)XIo_In32(MON_UARTLITE_0_BASE);
}

void XUartLite_SendByte2(char Data)
{
	while ((XIo_In32(MON_UARTLITE_0_BASE + 0x8) & 0x08) == 0x08);

	XIo_Out32(MON_UARTLITE_0_BASE + 0x4, Data);
}


static cyg_bool
cyg_hal_plf_serial_getc_nonblock(channel_data_t *chan, cyg_uint8 *ch)
{
#ifdef MON_UARTLITE_0

	*ch = XUartLite_RecvByte2();
	return true;
#else

    if (!chan->dev_ok) return false;
    if (chan->qlen == 0) {
        // See if any characters are now available
        chan->qp = chan->inq;
//        chan->qlen = XUartNs550_Recv(&chan->dev, chan->qp, sizeof(chan->inq));

    }
    if (chan->qlen) {
        *ch = *chan->qp++;
        chan->qlen--;
        return true;
    }
    return false;
#endif
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
#if 0
	int *uart_tx;
	int *uart_stat;

	uart_tx = MON_UARTLITE_0_BASE + 0x4;
	uart_stat = MON_UARTLITE_0_BASE + 0x8;

	unsigned retries = 10000;
	while (retries-- && (*uart_stat & (1<<3)))
		;

	/* Only attempt the iowrite if we didn't timeout */
	if(retries)
		*uart_tx = c & 0xff;


	if (!chan->dev_ok) { 
		return;
	}
#endif
#ifdef MON_UARTLITE_0
	XUartLite_SendByte2(c);
#endif

#ifdef MON_UART16550_0
    XUartNs550_Send(&chan->dev, &c, 1);
    // Wait for character to get out
    while (XUartNs550_IsSending(&chan->dev)) ;
#endif
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

	int *led;
	led = 0x81400000;
	*led = 0x40;

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

void
cyg_hal_plf_comms_init(void)
{
    static int initialized = 0;

    if (initialized)
        return;
    initialized = 1;

    cyg_hal_plf_serial_init();
}

// EOF hal_diag.c
