#ifndef __TFT_SCREEN_H__
#define __TFT_SCREEN_H__

#include "config.h"
#ifndef NO_VGA_FRAMEBUFFER
#include <cyg/hal/lcd_support.h>
#endif

/*! \file tft_screen.h 
 * \brief offers variables and functions need to use the tft screen
 */

#ifdef NO_VGA_FRAMEBUFFER
//! information for a framebuffer
typedef struct lcd_info {
    //! height and width of monitor resolution (max 640x480)
    short height, width;  // Pixels
    //!  Depth (bits per pixel)
    short bpp; 
    //! type
    short type;
    //! length of one raster line in bytes
    short rlen;           
    //! frame buffer
    void  *fb; 
} lcd_info;
#endif

//! framebuffer info structure for editing
struct lcd_info tft_editing;

//! framebuffer info structure for loading a new frame
struct lcd_info tft_loading;

//! space needed by one framebuffer
unsigned int framebuffer_space; 


/**
   sets a pixel (x, y) in a specific RGB value

   @param x: x coordinate of pixel
   @param y: y coordinate of pixel
   @param r: red component of pixel
   @param g: green component of pixel
   @param b: blue component of pixel
 */
void tft_set_pixel(int x, int y, unsigned int r, unsigned int g, unsigned int b);


/**
  resets framebuffer to start address
*/
void reset_framebuffer(void);


/**
 initializes vga display. Two framebuffers are used. One framebuffer will contain the working process, while the other will be displayed. After the working process is over, the first framebuffer will be displayed, while the other framebuffer will be in the working process (get new frame->particle filter->display particles)
*/
void tft_init(void);



/**
 switches from one frame buffer to the other
 There are two framebuffer. One of both is in the working state, while the other is in the display state.
*/
void switch_framebuffer( void );


#ifdef HWMEASURE
/**
 resets from one frame buffer to the other. There are 50 framebuffer.
*/
void reset_framebuffer( void );


/**
 changes from one frame buffer to the other. There are 50 framebuffer.
*/
void change_framebuffer( void );
#endif


#endif                          //__TFT_SCREEN_H__
