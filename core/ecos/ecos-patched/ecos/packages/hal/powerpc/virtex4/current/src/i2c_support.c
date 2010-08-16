//=============================================================================
//
//      i2c_support.c
//
//      VIRTEX4 i2c support routines
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
// Date:        2005-05-02
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
#include <cyg/io/i2c.h>
#include <cyg/hal/i2c_support.h>

#include "xbasic_types.h"
#include "xiic.h"
#include "xiic_l.h"
#include "xparameters.h"
#include <xparameters_translation.h>

static void virtex4_i2c_bus_init(struct cyg_i2c_bus*);
static cyg_uint32 virtex4_i2c_bus_tx(const cyg_i2c_device*, cyg_bool, const cyg_uint8*, cyg_uint32, cyg_bool);
static cyg_uint32 virtex4_i2c_bus_rx(const cyg_i2c_device*, cyg_bool, cyg_uint8*, cyg_uint32, cyg_bool, cyg_bool);
static void virtex4_i2c_bus_stop(const cyg_i2c_device*);

// The i2c bus, even when by default is initialized as a device!!!
static XIic virtex4_i2c_bus_controller;
static bool virtex4_i2c_bus_controller_initialized = false;
static bool virtex4_i2c_bus_controller_started = false;
static cyg_handle_t interrupt_handler;
static cyg_interrupt interrupt;


// Main bus definition
CYG_I2C_BUS( virtex4_i2c_bus, virtex4_i2c_bus_init, virtex4_i2c_bus_tx, virtex4_i2c_bus_rx, virtex4_i2c_bus_stop, &virtex4_i2c_bus_controller );

void virtex4_i2c_init()
{
}

int virtex4_i2c_get_bus_pointer( void ** bus )
{
    *bus = &virtex4_i2c_bus;
    return 0;
}

/*
 * Worker functions
 */

static void 
virtex4_i2c_bus_send_handler(void *CallBackRef, int ByteCount)
{
    diag_printf( "Calling send_handler!\n" );
}

static void 
virtex4_i2c_bus_receive_handler(void *CallBackRef, int ByteCount)
{
    diag_printf( "Calling receive_handler!\n" );
}

static void 
virtex4_i2c_bus_status_handler(void *CallBackRef, XStatus StatusEvent)
{
    diag_printf( "Calling status_handler!\n" );
}

static void 
virtex4_i2c_bus_dsr(cyg_vector_t vector, cyg_ucount32 count, cyg_addrword_t data)
{
    struct cyg_i2c_bus * bus = (struct cyg_i2c_bus*)data;

    diag_printf( "virtex4_i2c_bus_dsr\n" );
    XIic_InterruptHandler(bus->i2c_extra);
    cyg_drv_interrupt_acknowledge(CYGNUM_HAL_INTERRUPT_I2C);
    cyg_drv_interrupt_unmask(CYGNUM_HAL_INTERRUPT_I2C);
}
 
static int
virtex4_i2c_bus_isr(cyg_vector_t vector, cyg_addrword_t data, HAL_SavedRegisters *regs)
{
    cyg_drv_interrupt_mask(CYGNUM_HAL_INTERRUPT_I2C);
    diag_printf( "virtex4_i2c_bus_isr\n" );
    return CYG_ISR_CALL_DSR;  // Run the DSR
}

static void virtex4_i2c_bus_init(struct cyg_i2c_bus* bus)
{
    XStatus stat = 0;
    
    if( virtex4_i2c_bus_controller_initialized )
        return;

    stat = XIic_Initialize(bus->i2c_extra, UPBHWR_IIC_0_DEVICE_ID);
    if( stat != XST_SUCCESS ) {
        return;  // What else can be done?
    } else {
        virtex4_i2c_bus_controller_initialized = true;
    }
    // handler routines
    XIic_SetRecvHandler(bus->i2c_extra, bus->i2c_extra, virtex4_i2c_bus_receive_handler);
    XIic_SetSendHandler(bus->i2c_extra, bus->i2c_extra, virtex4_i2c_bus_send_handler);
    XIic_SetStatusHandler(bus->i2c_extra, bus->i2c_extra, virtex4_i2c_bus_status_handler);

    // Interruption handling routines
    cyg_drv_interrupt_create(CYGNUM_HAL_INTERRUPT_I2C,
                             0,  // Highest //CYGARC_SIU_PRIORITY_HIGH,
                             (cyg_addrword_t)bus, //  Data passed to ISR
                             (cyg_ISR_t *)virtex4_i2c_bus_isr,
                             (cyg_DSR_t *)virtex4_i2c_bus_dsr,
                             &interrupt_handler,
                             &interrupt);
    cyg_drv_interrupt_attach(interrupt_handler);
}

static cyg_uint32 virtex4_i2c_bus_tx(const cyg_i2c_device* dev, cyg_bool flag0, const cyg_uint8* buffer, cyg_uint32 count, cyg_bool flag1)
{
    XStatus stat;
    unsigned total;
    int i = 0;
    
    if( !virtex4_i2c_bus_controller_initialized )
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_tx): bus not initialized! \n" );
        return 0;
    }
    if(( buffer == NULL ) || ( count == 0 ))
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_tx): Trying to use a NULL buffer as data to send, or count == 0! \n" );
        return 0;
    }
    if( !virtex4_i2c_bus_controller_started )
    {
        stat = XIic_Start(dev->i2c_bus->i2c_extra);
        if( stat != XST_SUCCESS ) // This cannot happen in this version of hardware (the function always return success)!!!!!!!!!
        {
            diag_printf( "i2c_support.c(virtex4_i2c_bus_tx): Could not start the bus! \n" );
            return 0;
        }
        virtex4_i2c_bus_controller_started = true;
    }
    stat = XIic_SetAddress(dev->i2c_bus->i2c_extra, XII_ADDR_TO_SEND_TYPE, (int)dev->i2c_address);
    if( stat != XST_SUCCESS )
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_tx): Could not set %u as slave address! \n", dev->i2c_address );
        return 0;
    }
    stat = XIic_MasterSend(dev->i2c_bus->i2c_extra, buffer, count);
//    total = XIic_Send(((XIic *)dev->i2c_bus->i2c_extra)->BaseAddress, (Xuint8)dev->i2c_address, buffer, count);

    if( stat != XST_SUCCESS )
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_tx): Could not send data! \n" );
        return 0;
    } //else
        //for( i = 0; i < total; i++ )
          //  diag_printf( "Transmitted data: buffer[ %d ] = %u \n", i, buffer[ i ] );
//    printf( "Transmitted %u bytes of %u requested \n", total, count );
 
    return count;
}

static cyg_uint32 virtex4_i2c_bus_rx(const cyg_i2c_device* dev, cyg_bool flag0, cyg_uint8* buffer, cyg_uint32 count, cyg_bool flag1, cyg_bool flag2)
{
    XStatus stat;
    unsigned  total;
    int i = 0;

    if( !virtex4_i2c_bus_controller_initialized )
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_rx): bus not initialized! \n" );
        return 0;
    }
    if(( buffer == NULL ) || ( count == 0 ))
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_rx): Trying to use a NULL buffer as data to receive, or count == 0! \n" );
        return 0;
    }
    if( !virtex4_i2c_bus_controller_started )
    {
        stat = XIic_Start(dev->i2c_bus->i2c_extra);
        if( stat != XST_SUCCESS ) // This cannot happen in this version of hardware (the function always return success)!!!!!!!!!
        {
            diag_printf( "i2c_support.c(virtex4_i2c_bus_rx): Could not start the bus! \n" );
            return 0;
        }
        virtex4_i2c_bus_controller_started = true;
    }
    stat = XIic_SetAddress(dev->i2c_bus->i2c_extra, XII_ADDR_TO_SEND_TYPE, (int)dev->i2c_address);
    if( stat != XST_SUCCESS )
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_rx): Could not set %u as slave address! \n", dev->i2c_address );
        return 0;
    }
    stat = XIic_MasterRecv(dev->i2c_bus->i2c_extra, buffer, count);
//    total = XIic_Recv( ((XIic *)dev->i2c_bus->i2c_extra)->BaseAddress, (Xuint8)dev->i2c_address, buffer, count);
    if( stat != XST_SUCCESS )
    {
        diag_printf( "i2c_support.c(virtex4_i2c_bus_rx): Could not receive data! \n" );
        return 0;
    } else
        for( i = 0; i < count; i++ )
          diag_printf( "Received data: buffer[ %d ] = %u \n", i, buffer[ i ] );
//    printf( "Received %u bytes of %u requested \n", total, count );
    
    return count;
}

static void virtex4_i2c_bus_stop(const cyg_i2c_device* dev)
{
    XStatus stat;
    if( !virtex4_i2c_bus_controller_initialized )
        return;
    if( virtex4_i2c_bus_controller_started )
    {
        stat = XIic_Stop(dev->i2c_bus->i2c_extra);
        if( stat != XST_SUCCESS ) // This cannot happen in this version of hardware (the function always return success)!!!!!!!!!
            return;
        virtex4_i2c_bus_controller_started = false;
    }

    return;
}

 
