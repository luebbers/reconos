//==========================================================================
//
//        Lcd_support.c
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
// Contributors:  gthomas
//                Carlos Duclos 
// Date:          2005-05-26
// Description:   Simple LCD support
//####DESCRIPTIONEND####
#include <pkgconf/hal.h>

#include <cyg/infra/diag.h>
#include <cyg/hal/hal_io.h>       // IO macros
#include <cyg/hal/hal_if.h>       // Virtual vector support
#include <cyg/hal/hal_arch.h>     // Register state info
#include <cyg/hal/hal_intr.h>     // HAL interrupt macros

#include <cyg/hal/lcd_support.h>
#include <cyg/hal/hal_cache.h>

#include "xbasic_types.h"
#include "xtft.h"
#include "xtft_l.h"
//#include "xps2.h"
#include "xparameters.h"
#include <xparameters_translation.h>

#include <string.h>

#ifdef CYGPKG_ISOINFRA
# include <pkgconf/isoinfra.h>
# ifdef CYGINT_ISO_STDIO_FORMATTED_IO
#  include <stdio.h>  // sscanf
# endif /* CYGINT_ISO_STDIO_FORMATTED_IO */
#endif /* CYGPKG_ISOINFRA */

#ifndef FALSE
#define FALSE 0
#define TRUE  1
#endif

// Physical dimensions of LCD display
#define DISPLAY_WIDTH  XTFT_DISPLAY_WIDTH
#define DISPLAY_HEIGHT XTFT_DISPLAY_HEIGHT
#define DISPLAY_LINE_WIDTH XTFT_DISPLAY_BUFFER_WIDTH

// Logical layout
#define LCD_WIDTH  DISPLAY_WIDTH
#define LCD_HEIGHT DISPLAY_HEIGHT
#define LCD_DEPTH   16

#define RGB_RED(x)   (((x)&0xFF)<<16)
#define RGB_GREEN(x) (((x)&0xFF)<<8)
#define RGB_BLUE(x)  (((x)&0xFF)<<0)

// Physical screen info
//static int lcd_depth  = LCD_DEPTH;  // Should be 1, 2, or 4
static int lcd_height = LCD_HEIGHT;
static cyg_uint32 lcd_framebuffer;

// White on black
static int bg = RGB_RED(0x00) | RGB_GREEN(0x00) | RGB_BLUE(0x00);
#ifdef CYGSEM_VIRTEX4_LCD_COMM
static int fg = RGB_RED(0xFF) | RGB_GREEN(0xFF) | RGB_BLUE(0xFF);
#endif /* CYGSEM_VIRTEX4_LCD_COMM */

// Screen & keyboard access
static XTft tft;

// Compute the location for a pixel within the framebuffer
static cyg_uint32 *
lcd_fb(int row, int col)
{
    return (cyg_uint32 *)(lcd_framebuffer+(((row*DISPLAY_LINE_WIDTH)+col)*4));
}

// Nothing to do here, but leave the interface
void
lcd_on(bool enable)
{
}

// Initialize LCD hardware
void
lcd_init(int depth)
{
    XTft_Initialize(&tft, UPBHWR_VGA_0_DEVICE_ID);
    lcd_framebuffer = tft.FramebufferAddress;
    XTft_SetColor(&tft, 0x00FF0000, 0x00000088);  // Should be BLUE
    XTft_ClearScreen(&tft);
    lcd_on(true);
    lcd_clear();
}

// Get information about the frame buffer
int
lcd_getinfo(struct lcd_info *info)
{
    info->width = DISPLAY_WIDTH;
    info->height = DISPLAY_HEIGHT;
    info->bpp = 32;
    info->fb = (void*)lcd_framebuffer;
    info->rlen = DISPLAY_LINE_WIDTH * 4;
    info->type = FB_TRUE_COLOR0888;
    return 1; // Information valid
}

// Clear screen
void
lcd_clear(void)
{
    cyg_uint32 *fb_row0, *fb_rown;

    fb_row0 = lcd_fb(0, 0);
    fb_rown = lcd_fb(lcd_height, 0);
    while (fb_row0 != fb_rown) {
        *fb_row0++ = bg;
    }
#ifdef CYGSEM_VIRTEX4_LCD_COMM
    lcd_screen_clear();
#endif
}

// draw a test image
void lcd_test_image(struct lcd_info *info)
{
	int x,y;
	// assume 32 bpp
	for(y = 0; y < info->height; y++){
		for(x = 0; x < info->width; x++){
			int r = 0,g = 0,b = 0;
			int c = (((x/10) + (y/10)) % 2)*0x3F + (((x/80) + (y/80)) % 2)*0xC0;
			
			if(x < 0x100){
				if(y < 80)       r = 0xFF - x;
				else if(y < 160) g = 0xFF - x;
				else if(y < 240) b = 0xFF - x;
				else if(y < 320) r = g = b = x;
				else             r = g = b = c;
			}
			else{
				r = g = b = c;
			}
			lcd_set_pixel_rgb(info,x,y,r,g,b);
		}
	}
}


#ifdef CYGSEM_VIRTEX4_LCD_COMM

//
// Additional support for LCD/Keyboard as 'console' device
//

#include "banner.xpm"
#include "font.h"

// Virtual screen info
static int curX = 0;  // Last used position
static int curY = 0;
//static int width = LCD_WIDTH / (FONT_WIDTH*NIBBLES_PER_PIXEL);
//static int height = LCD_HEIGHT / (FONT_HEIGHT*SCREEN_SCALE);

#define SCREEN_PAN            20
#define SCREEN_WIDTH          80
#define SCREEN_HEIGHT         (LCD_HEIGHT/FONT_HEIGHT)
#define VISIBLE_SCREEN_WIDTH  (LCD_WIDTH/FONT_WIDTH)
#define VISIBLE_SCREEN_HEIGHT (LCD_HEIGHT/FONT_HEIGHT)
static char screen[SCREEN_HEIGHT][SCREEN_WIDTH];
static int screen_height = SCREEN_HEIGHT;
static int screen_width = SCREEN_WIDTH;
static int screen_pan = 0;

// Usable area on screen [logical pixel rows]
static int screen_start = 0;                       
static int screen_end = LCD_HEIGHT/FONT_HEIGHT;

static bool cursor_enable = true;

// Functions
static void lcd_drawc(cyg_int8 c, int x, int y);

// Note: val is a 16 bit, RGB555 value which must be mapped
// onto a 12 bit value.
#define RED(v)   ((v>>12) & 0x0F)
#define GREEN(v) ((v>>7) & 0x0F)
#define BLUE(v)  ((v>>1) & 0x0F)

static void
set_pixel(int row, int col, unsigned long val)
{
    unsigned long *pix = (unsigned long *)lcd_fb(row, col);
    *pix = val;
}

static int
_hexdigit(char c)
{
    if ((c >= '0') && (c <= '9')) {
        return c - '0';
    } else
    if ((c >= 'A') && (c <= 'F')) {
        return (c - 'A') + 0x0A;
    } else
    if ((c >= 'a') && (c <= 'f')) {
        return (c - 'a') + 0x0a;
    }

    return 0;
}

static int
_hex(char *cp)
{
    return (_hexdigit(*cp)<<4) | _hexdigit(*(cp+1));
}

static unsigned long
parse_color(char *cp)
{
    int red, green, blue;

    while (*cp && (*cp != 'c')) cp++;
    if (cp) {
        cp += 2;
        if (*cp == '#') {
            red = _hex(cp+1);
            green = _hex(cp+3);
            blue = _hex(cp+5);
            return RGB_RED(red) | RGB_GREEN(green) | RGB_BLUE(blue);
        } else {
            // Should be "None"
            return 0xFFFFFFFF;
        }
    } else {
        return 0xFFFFFFFF;
    }
}

#ifndef CYGINT_ISO_STDIO_FORMATTED_IO
static int
get_int(char **_cp)
{
    char *cp = *_cp;
    char c;
    int val = 0;
    
    while ((c = *cp++) && (c != ' ')) {
        if ((c >= '0') && (c <= '9')) {
            val = val * 10 + (c - '0');
        } else {
            return -1;
        }
    }
    *_cp = cp;
    return val;
}
#endif /* CYGINT_ISO_STDIO_FORMATTED_IO */

int
show_xpm(char *xpm[], int screen_pos)
{
    int i, row, col, offset;
    char *cp;
    int nrows, ncols, nclrs;
    unsigned long colors[256];  // Mapped by character index

    cp = xpm[0];
#ifdef CYGINT_ISO_STDIO_FORMATTED_IO
    if (sscanf(cp, "%d %d %d", &ncols, &nrows, &nclrs) != 3) {
#else
    if (((ncols = get_int(&cp)) < 0) ||
        ((nrows = get_int(&cp)) < 0) ||
        ((nclrs = get_int(&cp)) < 0)) {

#endif /* CYGINT_ISO_STDIO_FORMATTED_IO */
        diag_printf("Can't parse XPM data, sorry\n");
        return 0;
    }
    // printf("%d rows, %d cols, %d colors\n", nrows, ncols, nclrs);

    for (i = 0;  i < 256;  i++) {
        colors[i] = 0x0000;
    }
    for (i = 0;  i < nclrs;  i++) {
        cp = xpm[i+1];
        colors[(unsigned int)*cp] = parse_color(&cp[1]);
//        diag_printf("Color[%c] = %x\n", *cp, colors[(unsigned int)*cp]);
    }

    offset = screen_pos;
    for (row = 0;  row < nrows;  row++) {            
        cp = xpm[nclrs+1+row];        
        for (col = 0;  col < ncols;  col++) {
            set_pixel(row+offset, col, colors[(unsigned int)*cp++]);
        }
    }
    screen_start = (nrows + (FONT_HEIGHT-1))/FONT_HEIGHT;
    screen_end = LCD_HEIGHT/FONT_HEIGHT;
    return offset+nrows;
}

void
lcd_screen_clear(void)
{

    int row, col, pos;
    for (row = 0;  row < screen_height;  row++) {
        for (col = 0;  col < screen_width;  col++) {
            screen[row][col] = ' ';
        }
    }
    // Note: Row 0 seems to wrap incorrectly
    pos = 0;
    show_xpm(banner_xpm, pos);
    curX = 0;  curY = screen_start;
    if (cursor_enable) {
        lcd_drawc(CURSOR_ON, curX-screen_pan, curY);
    }
}

// Position cursor
void
lcd_moveto(int X, int Y)
{
    if (cursor_enable) {
        lcd_drawc(screen[curY][curX], curX-screen_pan, curY);
    }
    if (X < 0) X = 0;
    if (X >= screen_width) X = screen_width-1;
    curX = X;
    if (Y < screen_start) Y = screen_start;
    if (Y >= screen_height) Y = screen_height-1;
    curY = Y;
    if (cursor_enable) {
        lcd_drawc(CURSOR_ON, curX-screen_pan, curY);
    }
}

// Render a character at position (X,Y) with current background/foreground
static void
lcd_drawc(cyg_int8 c, int x, int y)
{
    cyg_uint8 bits;
    int l, p;
    int xoff, yoff;
    cyg_uint32 *fb;

    if ((x < 0) || (x >= VISIBLE_SCREEN_WIDTH) || 
        (y < 0) || (y >= screen_height)) return;  
    for (l = 0;  l < FONT_HEIGHT;  l++) {
        bits = font_table[c-FIRST_CHAR][l]; 
        yoff = y*FONT_HEIGHT + l;
        xoff = x*FONT_WIDTH;
        fb = lcd_fb(yoff, xoff);
        for (p = 0;  p < FONT_WIDTH;  p++) {
#ifdef FONT_LEFT_TO_RIGHT
            *fb++ = (bits & 0x80) ? fg : bg;
            bits <<= 1;
#else
            *fb++ = (bits & 0x01) ? fg : bg;
            bits >>= 1;
#endif /* FONT_LEFT_TO_RIGHT */
        }
    }
}

static void
lcd_refresh(void)
{
    int row, col;

    for (row = screen_start;  row < screen_height;  row++) {
        for (col = 0;  col < VISIBLE_SCREEN_WIDTH;  col++) {
            if ((col+screen_pan) < screen_width) {
                lcd_drawc(screen[row][col+screen_pan], col, row);
            } else {
                lcd_drawc(' ', col, row);
            }
        }
    }
    if (cursor_enable) {
        lcd_drawc(CURSOR_ON, curX-screen_pan, curY);
    }
}

static void
lcd_scroll(void)
{
    int col;
    cyg_uint8 *c1;
    cyg_uint32 *lc0, *lc1, *lcn;
    cyg_uint32 *fb_row0, *fb_row1, *fb_rown;

    // First scroll up the virtual screen
#if ((SCREEN_WIDTH%4) != 0)
#error Scroll code optimized for screen with multiple of 4 columns
#endif /* ((SCREEN_WIDTH%4) != 0) */
    lc0 = (cyg_uint32 *)&screen[0][0];
    lc1 = (cyg_uint32 *)&screen[1][0];
    lcn = (cyg_uint32 *)&screen[screen_height][0];
    while (lc1 != lcn) {
        *lc0++ = *lc1++;
    }
    c1 = &screen[screen_height-1][0];
    for (col = 0;  col < screen_width;  col++) {
        *c1++ = 0x20;
    }
    fb_row0 = lcd_fb(screen_start*FONT_HEIGHT, 0);
    fb_row1 = lcd_fb((screen_start+1)*FONT_HEIGHT, 0);
    fb_rown = lcd_fb(screen_end*FONT_HEIGHT, 0);
    while (fb_row1 != fb_rown) {
        *fb_row0++ = *fb_row1++;
    }
    // Erase bottom line
    for (col = 0;  col < screen_width;  col++) {
        lcd_drawc(' ', col, screen_end-1);
    }
}

// Draw one character at the current position
void
lcd_putc(cyg_int8 c)
{
    if (cursor_enable) {
        lcd_drawc(screen[curY][curX], curX-screen_pan, curY);
    }
    switch (c) {
    case '\r':
        curX = 0;
        break;
    case '\n':
        curY++;
        break;
    case '\b':
        curX--;
        if (curX < 0) {
            curY--;
            if (curY < 0) curY = 0;
            curX = screen_width-1;
        }
        break;
    default:
#if ((FIRST_CHAR != 0x00) || (LAST_CHAR != 0xFF))
        if (((cyg_uint8)c < FIRST_CHAR) || ((cyg_uint8)c > LAST_CHAR)) c = '.';
#endif /* ((FIRST_CHAR != 0x00) || (LAST_CHAR != 0xFF)) */
        screen[curY][curX] = c;
        lcd_drawc(c, curX-screen_pan, curY);
        curX++;
        if (curX == screen_width) {
            curY++;
            curX = 0;
        }
    } 
    if (curY >= screen_height) {
        lcd_scroll();
        curY = (screen_height-1);
    }
    if (cursor_enable) {
        lcd_drawc(CURSOR_ON, curX-screen_pan, curY);
    }
}

// Basic LCD 'printf()' support

#include <stdarg.h>

#define is_digit(c) ((c >= '0') && (c <= '9'))

static int
_cvt(unsigned long val, char *buf, long radix, char *digits)
{
    char temp[80];
    char *cp = temp;
    int length = 0;
    if (val == 0) {
        /* Special case */
        *cp++ = '0';
    } else {
        while (val) {
            *cp++ = digits[val % radix];
            val /= radix;
        }
    }
    while (cp != temp) {
        *buf++ = *--cp;
        length++;
    }
    *buf = '\0';
    return (length);
}

static int
lcd_vprintf(void (*putc)(cyg_int8), const char *fmt0, va_list ap)
{
    char c, sign, *cp;
    int left_prec, right_prec, zero_fill, length, pad, pad_on_right;
    char buf[32];
    long val;
    while ((c = *fmt0++)) {
        cp = buf;
        length = 0;
        if (c == '%') {
            c = *fmt0++;
            left_prec = right_prec = pad_on_right = 0;
            if (c == '-') {
                c = *fmt0++;
                pad_on_right++;
            }
            if (c == '0') {
                zero_fill = TRUE;
                c = *fmt0++;
            } else {
                zero_fill = FALSE;
            }
            while (is_digit(c)) {
                left_prec = (left_prec * 10) + (c - '0');
                c = *fmt0++;
            }
            if (c == '.') {
                c = *fmt0++;
                zero_fill++;
                while (is_digit(c)) {
                    right_prec = (right_prec * 10) + (c - '0');
                    c = *fmt0++;
                }
            } else {
                right_prec = left_prec;
            }
            sign = '\0';
            switch (c) {
            case 'd':
            case 'x':
            case 'X':
                val = va_arg(ap, long);
                switch (c) {
                case 'd':
                    if (val < 0) {
                        sign = '-';
                        val = -val;
                    }
                    length = _cvt(val, buf, 10, "0123456789");
                    break;
                case 'x':
                    length = _cvt(val, buf, 16, "0123456789abcdef");
                    break;
                case 'X':
                    length = _cvt(val, buf, 16, "0123456789ABCDEF");
                    break;
                }
                break;
            case 's':
                cp = va_arg(ap, char *);
                length = strlen(cp);
                break;
            case 'c':
                c = va_arg(ap, long /*char*/);
                (*putc)(c);
                continue;
            default:
                (*putc)('?');
            }
            pad = left_prec - length;
            if (sign != '\0') {
                pad--;
            }
            if (zero_fill) {
                c = '0';
                if (sign != '\0') {
                    (*putc)(sign);
                    sign = '\0';
                }
            } else {
                c = ' ';
            }
            if (!pad_on_right) {
                while (pad-- > 0) {
                    (*putc)(c);
                }
            }
            if (sign != '\0') {
                (*putc)(sign);
            }
            while (length-- > 0) {
                (*putc)(c = *cp++);
                if (c == '\n') {
                    (*putc)('\r');
                }
            }
            if (pad_on_right) {
                while (pad-- > 0) {
                    (*putc)(' ');
                }
            }
        } else {
            (*putc)(c);
            if (c == '\n') {
                (*putc)('\r');
            }
        }
    }

    // FIXME
    return 0;
}

int
_lcd_printf(char const *fmt, ...)
{
    int ret;
    va_list ap;

    va_start(ap, fmt);
    ret = lcd_vprintf(lcd_putc, fmt, ap);
    va_end(ap);
    return (ret);
}

void
lcd_setbg(int red, int green, int blue)
{
    bg = RGB_RED(red) | RGB_GREEN(green) | RGB_BLUE(blue);
}

void
lcd_setfg(int red, int green, int blue)
{
    fg = RGB_RED(red) | RGB_GREEN(green) | RGB_BLUE(blue);
}

#endif /* CYGSEM_VIRTEX4_LCD_COMM */
