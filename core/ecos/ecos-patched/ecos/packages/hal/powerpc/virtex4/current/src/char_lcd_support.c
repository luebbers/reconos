//=============================================================================
//
//      char_lcd_support.c
//
//      VIRTEX4 2x16 char lcd support routines
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 2004 eCosCentric Limited
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
// -------------------------------------------
//####ECOSGPLCOPYRIGHTEND####
//=============================================================================
//####DESCRIPTIONBEGIN####
//
// Author(s):   Carlos Duclos 
// Date:        2005-05-23
//####DESCRIPTIONEND####
//=============================================================================

// Never used in Redboot
#ifndef CYGPKG_REDBOOT

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
#include <cyg/hal/char_lcd_support.h>


#include "xbasic_types.h"
#include "xgpio.h"
#include "xgpio_l.h"
#include "xparameters.h"
#include <xparameters_translation.h>

static XGpio char_lcd_device;
static cyg_uint8 current_row = 0;
static cyg_uint8 current_column = 0;
static int char_lcd_lock_until_free();

// hard-coded? Ugh! now defined in xparameters_translation.h
//#define CHAR_LCD_ADDRESS    0x90002000
#define COLUMN_NUMBER       16
#define ROW_NUMBER          2

/*
 * Time definitions
 */
 
#define FIRST_INIT          4100        /* first init sequence:  4.1 msec */
#define SECOND_INIT         100        /* second init sequence: 100 usec */
#define EXEC_TIME           80          /* normal execution time */

enum LCD_BITS { LCD_ENABLE = 0x40, LCD_RS = 0x20, LCD_RW = 0x10 };

/*
 * Graphic's memory routines
 */

static int position2address( cyg_uint8 * address )
{
    cyg_uint8 temporal_address = 0x00;
    
    temporal_address = (current_row * 0x40) + current_column;
    *address = temporal_address;
    
    return 0;
}

/*
 * Helper function
 * (Resolution: 30 ns)
 * Use it as lcd_delay( XX ) with XX number of us to wait
 */
 
static void lcd_delay( unsigned int delay )
{
    CYGACC_CALL_IF_DELAY_US(delay);
}

/*
 * If the row is greater than ROW_NUMBER, it will be converted using modulo-ROW_NUMBER
 */

static int row_increase()
{
    current_row++;
    current_row = current_row % ROW_NUMBER;

    return 0;
}

/*
 * If the column is greater than COLUMN_NUMBER, it will be converted using modulo-COLUMN_NUMBER
 */

static int column_increase()
{
    current_column++;
    if( current_column == COLUMN_NUMBER )
        row_increase();
    current_column = current_column % COLUMN_NUMBER;

    return 0;
}

/*
 * Low Level routines: R/W
 */
 
static int write_nibble( cyg_uint8 nibble )
{
    volatile cyg_uint32 * lcd_register = (volatile cyg_uint32 *)CHAR_LCD_ADDRESS;
    volatile cyg_uint32 temporal;
    
    *lcd_register = nibble;
    lcd_delay( 50 );
    *lcd_register = nibble | LCD_ENABLE;
    lcd_delay( 50 );
    *lcd_register = nibble;
    lcd_delay( 50 );
    
    return 0;
} 

static int write_byte( cyg_uint8 buffer )
{
    write_nibble( ((buffer>>4)&0x0F)|LCD_RS );
    write_nibble( (buffer&0x0F)|LCD_RS );

    return 0;
}

static int write_command( cyg_uint8 buffer )
{
    write_nibble( (buffer>>4)&0x0F );
    write_nibble( buffer&0x0F );

    return 0;
}

static int display_configure()
{
    int i;
    for (i = 0; i < 2; i++) {
        write_nibble( 0x00 ); 
        lcd_delay( FIRST_INIT );
        write_nibble( 0x03 );
        lcd_delay( FIRST_INIT );
        write_nibble( 0x03 );
        lcd_delay( SECOND_INIT );
        write_nibble( 0x03 );
        lcd_delay( FIRST_INIT );
        write_nibble( 0x02 );
        lcd_delay( SECOND_INIT );
        write_command( 0x28 );    
        lcd_delay( EXEC_TIME );
    }

    return 0;
}

/*
 * Simple abstraction to simplify the exported interface
 */
 
static int sw_init()
{
    XStatus status = 0;

    status = XGpio_Initialize( &char_lcd_device, UPBHWR_GPIO_CHAR_LCD_0_DEVICE_ID );
    if( status != XST_SUCCESS )
        return -1;

    return 0;
}

static int hw_init()
{
    XGpio_SetDataDirection( &char_lcd_device, 1, 0xFFFFFF80 );
    display_configure();
    
    return 0;
}

 
/*
 * Useful functions
 */
 
static int char_lcd_is_busy()
{
    return 0;
}

static int char_lcd_lock_until_free()
{
    int busy = 0;
    
    while( 1 )
    {
        busy = char_lcd_is_busy();
        if( !busy )
            break;
    }
    return 0;
}

/*
 * Exported interface
 */
 
void init_char_lcd()
{
    int result = 0;

    result = sw_init();
    if( result < 0 )
    {
        diag_printf( "Could not initialze sw char lcd\n" );
        return;
    }
    result = hw_init();
    if( result < 0 )
    {
        diag_printf( "Could not initialze hw char lcd\n" );
        return;
    }

    return;
}

int write_char_lcd( unsigned char * buffer, unsigned int length )
{
    volatile cyg_uint8 data = 0;
    int i = 0, result = 0;
    
    if( buffer == NULL )
        return -1;

    for( i = 0; i < length; i++ )
    {
        data = buffer[ i ];
        result = write_byte( data );
        if( result < 0 )
            return -1;
        else
            column_increase();
    }
        
    return 0;
}

int get_current_position( unsigned char * row, unsigned char * column )
{
    if( row == NULL )
        return -1;
    if( column == NULL )
        return -1;
    
    *row = current_row;
    *column = current_column;

    return 0;
}

int get_current_memory_position( unsigned char * address )
{
    if( address == NULL )
        return -1;
    position2address( address );
    
    return 0;
}

#endif // CYGPKG_REDBOOT
