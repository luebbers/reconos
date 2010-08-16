//=============================================================================
//
//      simple_keyboard.c
//
//      Simple keyboard code
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
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
// Purpose:     Simple keyboard to be used with Redboot
// Description: Simple keyboard to be used with Redboot. The differences between this driver and 
//              the complete driver are:
//              * lack of interrupts
//              * there is no write() to play with keyboard leds
//              * no keymaps
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
#include <cyg/hal/drv_api.h>

#if defined(CYGDBG_HAL_DEBUG_GDB_INCLUDE_STUBS)
#include <cyg/hal/hal_stub.h>           // hal_output_gdb_string
#endif

#include "xbasic_types.h"
#include "xparameters.h"
#include <xparameters_translation.h>
#include "xps2.h"
#include "xstatus.h"

#define WAITING_KEYCODE 0
#define WAITING_KEYUP 1
#define WAITING_ECHO_SCANCODE 2
#define LED_OFF 0
#define LED_ON 1
#define BUFFER_SIZE     32

typedef struct {
    unsigned char pool[ BUFFER_SIZE ];
    unsigned char * pointer;
    unsigned int total;
} keyboard_buffer;

static XPs2 keyboard_device;
static keyboard_buffer incoming_characters;

enum special_keys_states { NO_SPECIAL_KEY = 0, SHIFT_PRESSED, CTRL_PRESSED, ALT_PRESSED, CAPS_LOCK_PRESSED, NUM_LOCK_PRESSED };
enum special_keys_desc { ALT = 17, SHIFT = 18, CTRL = 20, CAPS_LOCK = 88, NUM_LOCK = 119, SCROLL_LOCK = 126 };
enum keyboard_commands { LEDS = 0xED, KBD_ACK = 0xFA };

static cyg_uint8
k2a( cyg_uint8 scancode )
{
    cyg_uint8 ascii = 0xFF;
    static unsigned char special_key = NO_SPECIAL_KEY;

    switch( scancode ) {
    case 0:
        break;
    case 1:
            break;
    case 2:
            break;
    case 3:
            break;
    case 4:
            break;
    case 5:
            break;
    case 6:
            break;
    case 7:
            break;
    case 8:
            break;
    case 9:
            break;
    case 10:
            break;
    case 11:
            break;
    case 12:
            break;
    case 13:
            break;
    case 14:
            break;
    case 15:
            break;
    case 16:
            break;
    case 17:
            ascii = ALT;
            special_key = ALT_PRESSED;
            break;
    case 18:
            ascii = SHIFT;
            special_key = SHIFT_PRESSED;
            break;
    case 19:
            break;
    case 20:
            ascii = CTRL;
            special_key = CTRL_PRESSED;
            break;
    case 21:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'q';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'Q';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
    case 22:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '1';
                    break;
                case SHIFT_PRESSED:
                    ascii = '!';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 23:
            break;
        case 24:
            break;
        case 25:
            break;
        case 26:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'z';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'Z';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 27:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 's';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'S';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 28:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'a';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'A';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 29:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'w';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'W';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 30:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '2';
                    break;
                case SHIFT_PRESSED:
                    ascii = '@';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 31:
            break;
        case 32:
            break;
        case 33:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'c';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'C';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 34:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'x';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'X';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 35:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'd';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'D';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 36:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'e';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'E';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 37:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '4';
                    break;
                case SHIFT_PRESSED:
                    ascii = '$';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 38:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '3';
                    break;
                case SHIFT_PRESSED:
                    ascii = '#';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 39:
            break;
        case 40:
            break;
        case 41:
            ascii = ' ';
            break;
        case 42:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'v';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'V';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
    case 43:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'f';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'F';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
    case 44:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 't';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'T';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
    case 45:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'r';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'R';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
    case 46:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '5';
                    break;
                case SHIFT_PRESSED:
                    ascii = '%';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
    case 47:
            break;
    case 48:
            break;
    case 49:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'n';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'N';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 50:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'b';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'B';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 51:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'h';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'H';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 52:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'g';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'G';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 53:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'y';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'Y';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 54:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '6';
                    break;
                case SHIFT_PRESSED:
                    ascii = '^';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 55:
            break;
        case 56:
            break;
        case 57:
            break;
        case 58:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'm';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'M';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 59:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'j';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'J';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 60:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'u';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'U';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 61:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '7';
                    break;
                case SHIFT_PRESSED:
                    ascii = '&';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 62:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '8';
                    break;
                case SHIFT_PRESSED:
                    ascii = '*';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 63:
            break;
        case 64:
            break;
        case 65:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = ',';
                    break;
                case SHIFT_PRESSED:
                    ascii = '<';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 66:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'k';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'K';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 67:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'i';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'I';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 68:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'o';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'O';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 69:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '0';
                    break;
                case SHIFT_PRESSED:
                    ascii = ')';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 70:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '9';
                    break;
                case SHIFT_PRESSED:
                    ascii = '(';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 71:
            break;
        case 72:
            break;
        case 73:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '.';
                    break;
                case SHIFT_PRESSED:
                    ascii = '>';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 74:
            break;
        case 75:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'l';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'L';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 76:
            break;
        case 77:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = 'p';
                    break;
                case SHIFT_PRESSED:
                    ascii = 'P';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 78:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '-';
                    break;
                case SHIFT_PRESSED:
                    ascii = '_';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 79:
            break;
        case 80:
            break;
        case 81:
            break;
        case 82:
            break;
        case 83:
            break;
        case 84:
            break;
        case 85:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '=';
                    break;
                case SHIFT_PRESSED:
                    ascii = '+';
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
            }
            break;
        case 86:
            break;
        case 87:
            break;
        case 88:
            ascii = 88;
            break;
        case 89:
            //ascii = SHIFT_PRESSED;
            //special_key = SHIFT_PRESSED;
            break;
        case 90:
            ascii = '\r';
            break;
        case 91:
            break;
        case 92:
            break;
        case 93:
            break;
        case 94:
            break;
        case 95:
            break;
        case 96:
            break;
        case 97:
            break;
        case 98:
            break;
        case 99:
            break;
        case 102:
            special_key = NO_SPECIAL_KEY;
            ascii = '\b';
            break;
        case 105:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '1';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '1';
                    break;
            }
            break;
        case 107:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '4';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '4';
                    break;
            }
            break;
        case 108:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '7';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '7';
                    break;
            }
            break;
        case 112:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '0';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '0';
                    break;
            }
            break;
        case 114:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '2';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '2';
                    break;
            }
            break;
        case 115:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '5';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '5';
                    break;
            }
            break;
        case 116:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '6';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '6';
                    break;
            }
            break;
        case 117:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '8';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '8';
                    break;
            }
            break;
        case 119:
            //ascii = 119;
            //special_key = NUM_LOCK;
            break;
        case 122:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '3';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '3';
                    break;
            }
            break;
        case 125:
            switch( special_key )
            {
                case NO_SPECIAL_KEY:
                    ascii = '9';
                    break;
                case SHIFT_PRESSED:
                    break;
                case CTRL_PRESSED:
                    break;
                case ALT_PRESSED:
                    break;
                case NUM_LOCK_PRESSED:
                    ascii = '9';
                    break;
            }
            break;
        case 126:
            //ascii = 126;
            //special_key = SCROLL_LOCK;
            break;
        case 0xF0:
            if( special_key != NO_SPECIAL_KEY )
                switch( special_key )
                {
                    case SHIFT:
                    case ALT:
                    case CTRL:
                        special_key = NO_SPECIAL_KEY;
                        break;
                    default:
                        break;
                }
            break;
    default:
        break;
    }

    return ascii;
}

// Get characters from keyboard
static void get_incoming_characters()
{
    incoming_characters.pointer = incoming_characters.pool;
    incoming_characters.total = XPs2_Recv(&keyboard_device, incoming_characters.pointer, sizeof(incoming_characters.pool));
}

/*
 * Exported interface
 */
 
void init_simple_keyboard()
{
    XStatus stat;
    stat = XPs2_Initialize(&keyboard_device, UPBHWR_PS2_0_DEVICE_ID );
    if (stat != XST_SUCCESS) {
        diag_printf( "Cannot initialize ps2 keyboard! \n" );
        return;  // What else can be done?
    }
    incoming_characters.total = 0;
    incoming_characters.pointer = incoming_characters.pool;
}

int read_simple_keyboard( cyg_uint8 * character )
{
    cyg_uint8 s = 0, t = 0;
    static int state = WAITING_KEYCODE;

    if( incoming_characters.total == 0 )
        get_incoming_characters();
    if( incoming_characters.total > 0 )
    {
        s = *incoming_characters.pointer++;
        if( state == WAITING_KEYCODE )
        {
            t = k2a( s );
            //diag_printf( "s = %u, t = %u \n", s, t );
            if(t == 0xFF) 
            {
                incoming_characters.total--;
                return -1;
            } else if( t == ALT )
            {
                incoming_characters.total--;
                return -1;
            } else if( t == SHIFT )
            {
                incoming_characters.total--;
                return -1;
            } else if( t == CTRL )
            {
                incoming_characters.total--;
                return -1;
            } 
            state = WAITING_KEYUP;
            *character = t;
            incoming_characters.total--;
            return 0;
        } else if( state == WAITING_KEYUP )
        {
            incoming_characters.total--;
            state = WAITING_ECHO_SCANCODE;
            return -1;
        } else if( state == WAITING_ECHO_SCANCODE )
        {
            incoming_characters.total--;
            state = WAITING_KEYCODE;
            return -1;
        }
    }

    return -1;
}

/*
 * No interrupts, so these functions are provided only for compatibility
 */

void disable_interrupt_simple_keyboard()
{
}

void enable_interrupt_simple_keyboard()
{
}
