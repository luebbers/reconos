#ifndef __BGR2HSV_H__
#define __BGR2HSV_H__

#include "config.h"


/*! \file bgr2hsv.h 
 * \brief convertes bgr image to a hsv image
 */


/** 
 * get histogram box value of the pixel (x, y)
 *
 * @param x: x-position of pixel
 * @param y: y-position of pixel
 * @return hsv value of the pixel
 */
int tft_get_hsv_pixel(int x, int y);



/**
 * convertes bgr image to a hsv image
 */
void convert_bgr2hsv(void);



/**
 * converts a single RGB value to a HSV value
 *
 * @param b: blue component
 * @param g: green component
 * @param r: red component
 */
int convert_hsv_value(int b, int g, int r);



/**
 * resets histogram box value image 
 */
void reset_hsvImage(void);



//! array containing all HSV Histogram values, which are calculated so far.
int ** hsvImage;




#endif                          //__BGR2HSV_H__
