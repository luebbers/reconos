#ifndef _LCD_SUPPORT_H_
#define _LCD_SUPPORT_H_
//==========================================================================
//
//        lcd_support.h
//
//        Xilinx VIRTEX4 - LCD support routines
//
//==========================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2003, 2004, 2005 Mind n.v.
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
//==========================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):     gthomas
// Contributors:  gthomas,aagne
// Date:          2001-09-29
// Description:   Simple LCD support
//####DESCRIPTIONEND####

struct lcd_info {
    short height, width;  // Pixels
    short bpp;            // Depth (bits/pixel)
    short type;
    short rlen;           // Length of one raster line in bytes
    void  *fb;            // Frame buffer
};

// Frame buffer types - used by MicroWindows
#define FB_TRUE_COLOR0888 0x03
#define FB_TRUE_RGB555 0x02  

// Exported functions
void lcd_init(int depth);
void lcd_clear(void);
int  lcd_getinfo(struct lcd_info *info);
void lcd_on(bool enable);
void lcd_test_image(struct lcd_info *info);

// draw a single pixel
static inline void lcd_set_pixel_rgb(struct lcd_info *info, int x, int y,
	unsigned int r, unsigned int g, unsigned int b)
{
	r = r & 0xFF;
	g = g & 0xFF;
	b = b & 0xFF;
	((unsigned int*)info->fb)[x + y*info->rlen/4] = b | (g << 8) | (r << 16);
}

#ifdef CYGSEM_VIRTEX4_LCD_COMM 
void lcd_moveto(int X, int Y);
void lcd_putc(cyg_int8 c);
int  lcd_printf(char const *fmt, ...);
void lcd_setbg(int red, int green, int blue);
void lcd_setfg(int red, int green, int blue);
int show_xpm(char **xpm, int screen_pos);
void lcd_screen_clear(void);
#endif /* CYGSEM_VIRTEX4_LCD_COMM */

#endif //  _LCD_SUPPORT_H_
