#ifndef __HSV2BGR_H__
#define __HSV2BGR_H__

#include "config.h"


/*! \file hsv2bgr.h 
 * \brief convertes created hsv image back to a bgr image and displays it to screen. This shows, if the bgr->hsv conversion was correct. (So this is only for debug)
 */

//! bgr value
typedef struct bgr_value {
  //! blue component
  int b;
  //! green component
  int g;
  //! red component
  int r;
} bgr_value; 


/**
 * convertes hsv image to a bgr image and shows it on screen
 */
void convert_hsv2bgr(void);



/**
 * converts a single HSV value to a BGR value
 *
 * @param h: hue component
 * @param s: saturation component
 * @param v: value component
 */
bgr_value convert_bgr_value(int h, int s, int v);







#endif                          //__HSV2BGR_H__
