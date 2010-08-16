#include <stdlib.h>
#include <stdio.h>
#include <cyg/infra/diag.h>
#include "../header/bgr2hsv.h"
#include "../header/tft_screen.h"
#include "../header/frame_size.h"
#include <unistd.h>

/*
  Calculates the histogram bin into which an HSV entry falls
  
  @author: Rob Hess, State University Oregon
  @param h Hue
  @param s Saturation
  @param v Value
  
  @return Returns the bin index corresponding to the HSV color defined by
    \a h, \a s, and \a v.
*/
int histo_bin( int h, int s, int v ){

  int hd, sd, vd;

  /* if S or V is less than its threshold, return a "colorless" bin */  
  vd = MIN( (int)((v * NV) / V_MAX), NV-1 );
  if( s < S_THRESH  ||  v < V_THRESH )
    return NH * NS + vd;
  
  /* otherwise determine "colorful" bin */
  hd = MIN( (int)((h * NH) / H_MAX), NH-1 );
  sd = MIN( (int)((s * NS) / S_MAX), NS-1 );
  return sd * NH + hd;
} 


  int hd_values[256] = {
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
     2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
     3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
     4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
     5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
     6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 
     7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
     8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9};
	  
  int sdvd_values[256] = {
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
     1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,	  
     2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
     3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 
     4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
     5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 
     6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 
     7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 
     8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9};




/*
  Calculates the histogram bin into which an HSV entry falls
  
  @author: Rob Hess, State University Oregon
  @param h Hue
  @param s Saturation
  @param v Value
  
  @return Returns the bin index corresponding to the HSV color defined by
    \a h, \a s, and \a v.
*/
int histo_bin_2( int h, int s, int v ){

  int hd, sd, vd;

   /*
  //diag_printf("\n(%d, %d, %d) => ", h, s, v);

  // if S or V is less than its threshold, return a "colorless" bin
  //vd = MIN( (int)((v * NV) / V_MAX_2), NV-1 );
  if      (  0 <= v && v <=  25) vd = 0;
  else if ( 26 <= v && v <=  50) vd = 1;
  else if ( 51 <= v && v <=  76) vd = 2;
  else if ( 77 <= v && v <= 101) vd = 3;
  else if (102 <= v && v <= 127) vd = 4;
  else if (128 <= v && v <= 152) vd = 5;
  else if (153 <= v && v <= 178) vd = 6;
  else if (179 <= v && v <= 203) vd = 7;
  else if (204 <= v && v <= 229) vd = 8;
  else                           vd = 9;*/
  vd = sdvd_values[v];
  if( s < S_THRESH_2  ||  v < V_THRESH_2 ){
    //diag_printf("%d", (NH * NS + vd));
    return NH * NS + vd;
  }
  
  /*// otherwise determine "colorful" bin 
  if      (  0 <= s && s <=  25) sd = 0;
  else if ( 26 <= s && s <=  50) sd = 1;
  else if ( 51 <= s && s <=  76) sd = 2;
  else if ( 77 <= s && s <= 101) sd = 3;
  else if (102 <= s && s <= 127) sd = 4;
  else if (128 <= s && s <= 152) sd = 5;
  else if (153 <= s && s <= 178) sd = 6;
  else if (179 <= s && s <= 203) sd = 7;
  else if (204 <= s && s <= 229) sd = 8;
  else                           sd = 9;

  if      (  0 <= h && h <=  17) hd = 0;
  else if ( 18 <= h && h <=  35) hd = 1;
  else if ( 36 <= h && h <=  53) hd = 2;
  else if ( 54 <= h && h <=  71) hd = 3;
  else if ( 72 <= h && h <=  89) hd = 4;
  else if ( 90 <= h && h <= 107) hd = 5;
  else if (108 <= h && h <= 125) hd = 6;
  else if (126 <= h && h <= 143) hd = 7;
  else if (144 <= h && h <= 161) hd = 8;
  else                           hd = 9;*/
  hd = hd_values[h];
  sd = sdvd_values[s];
  //diag_printf("hd = %d, sd = %d, vd = %d => %d", hd, sd, vd, (sd * NH + hd));
  //hd = MIN( (int)((h * NH) / H_MAX_2), NH-1 );
  //sd = MIN( (int)((s * NS) / S_MAX_2), NS-1 );
  return sd * NH + hd;
} 



/** 
 * get histogram box value of the pixel (x, y)
 *
 * @param x: x-position of pixel
 * @param y: y-position of pixel
 * @return hsv value of the pixel
 */

int tft_get_hsv_pixel(int x, int y)
{
	
  int h,s,v;
  cyg_uint32 value = ((cyg_uint32*)tft_editing.fb)[x + y*tft_editing.rlen/4];

  
  h = value % 256;
  value /= 256;
  s = value % 256;
  value /= 256;
  v = value % 256;
  
  //uint8_t * p = (uint8_t*) &value;
  //h = p[3];  s = p[2]; v = p[1];

  //if (h>180) printf("\nError: h-value is bigger than 180. The value is %d", h);

  return histo_bin_2(h, s, v);

/*
  //uint8_t * p = (uint8_t*) &value;
  //b = p[3];  g = p[2]; r = p[1];

  int b,g,r;
  cyg_uint32 value;

  
  b = value % 256;
  value /= 256;
  g = value % 256;
  value/= 256;
  r = value % 256;
  
  return convert_hsv_value(b, g, r);
*/
}



/**
 * convertes bgr image to a hsv image
 */
void convert_bgr2hsv(void){

   int x,y;

   for (x=0; x<SIZE_X; x++)
       for (y=0; y<SIZE_Y; y++)
	    hsvImage[x][y] = tft_get_hsv_pixel( x, y);
}



/**
 * resets histogram box value image 
 */
void reset_hsvImage(void){

   int x,y;

   for (x=0; x<SIZE_X; x++)
       for (y=0; y<SIZE_Y; y++)
	    hsvImage[x][y] = -1;

}



/**
 * converts a single RGB value to a HSV histogramm value
 *
 * @param b: blue component
 * @param g: green component
 * @param r: red component
 */
int convert_hsv_value(int b, int g, int r){
   
    hsv_value ret;
    int maximum, minimum;
    int difference;
    int bin;

    // calculate max, min, b, g, r - values
    maximum = MAX (b, MAX(g, r));
    minimum = MIN (b, MIN(g, r));

    difference = maximum - minimum;

    // calculate h component
    if (maximum == minimum){
             ret.h = 0;
    } else {
      if (r == maximum){

             ret.h = 360 + ((g-b)*60 / difference);

      } else {
        
	 if (g == maximum){
 
             ret.h = 480 + ((b-r)*60 / difference);
         
         } else {
         
             ret.h = 600 + ((r-g)*60 / difference);
 
         }
      }   
    }

    while (360 <= ret.h){
      ret.h -= 360;
    }


    // calculate s component
    if (maximum == 0){

        ret.s = 0;

    } else {

      ret.s =((100 * difference) / maximum);
   
    }


    // calculate v component
    ret.v = ((100 * maximum) / MAX_COLOR_VALUE);

#ifdef DEBUG
#ifdef DEBUG_BGR2HSV
    printf("\n(%d,%d,%d) in BGR = (%d, %d, %d) in HSV", b, g, r, ret.h/GRANULARITY, ret.s/GRANULARITY, ret.v/GRANULARITY);
#endif
#endif
   
    bin = histo_bin(ret.h, ret.s, ret.v);
    
    return bin;
}



/**
 * converts a single RGB value to a HSV histogramm value
 *
 * @param b: blue component
 * @param g: green component
 * @param r: red component
 */
/*
int convert_hsv_value_try(int b, int g, int r){
   
    int hd, sd, vd;
    int h, s, v;
    int maximum, minimum;
    int difference;
    int tmp;

    maximum = MAX (b, MAX(g, r));
    minimum = MIN (b, MIN(g, r));

    difference = maximum - minimum;
    tmp = 6 * difference;

    // calculate s value
    if (maximum == 0){

       s = 0;

    } else {

      s = maximum - minimum;
      s *= NS;
      s /= maximum;
    }

    // calculate v value
    v = maximum * NV;
    v /= MAX_COLOR_VALUE;

    // calculate correct histogram bin
    vd = MIN( v, NV-1 );
    sd = MIN( s, NS-1 );

    // if S or V is less than its threshold, return a "colorless" bin
    if( s < S_THRESH_1  ||  v < V_THRESH_1 ) // X_THRESH_1 = X_THRESH / 10
         return NH * NS + vd;

    //TODO: delete next line
    maximum = minimum;

    // calculate h value;    
    if (maximum == minimum){
             h = 0;
    } else {
      if (r == maximum){

             h = 30 * difference;
             h += 5 * (g - b);
             h /= tmp;

      } else {
        
	 if (g == maximum){
 
             h = 40 * difference;
             h += 5 * (b - r);
             h /= tmp;
         
         } else {
         
             h = 50 * difference;
             h += 5 * (r - g);
             h /= tmp; 
         }
      }   
    }

    hd = MIN( h, NH-1 );
   
    // otherwise determine "colorful" bin
    return sd * NH + hd;
}
*/



/**
 * converts a single RGB value to a HSV value
 *
 * @param b: blue component
 * @param g: green component
 * @param r: red component
 */
/*
  hsv_value convert_hsv_value_float(int b, int g, int r){
   
    hsv_value ret;
    int maximum, minimum;
    //int max_value, min_value;
    int difference;
    //int difference2;

    float h,s,v;
    float float_difference;
    float float_b, float_g, float_r;
  
    float_b = (1.0 * b) / MAX_COLOR_VALUE;
    float_g = (1.0 * g) / MAX_COLOR_VALUE;
    float_r = (1.0 * r) / MAX_COLOR_VALUE;

    float float_max_value;
   

    // calculate max, min, b, g, r - values
    maximum = MAX (b, MAX(g, r));
    minimum = MIN (b, MIN(g, r));

    float_max_value = ((1.0 * maximum) / MAX_COLOR_VALUE);

    //max_value = (maximum * GRANULARITY) / MAX_COLOR_VALUE;
    //min_value = (minimum * GRANULARITY) / MAX_COLOR_VALUE;
    difference = maximum - minimum;
    //difference2 = max_value - min_value;

    float_difference = (1.0 * difference) / MAX_COLOR_VALUE;


    // calculate h component

    if (maximum == minimum){
             h = 0.0;
    } else {
      if (r == maximum){

             h = 360.0 + (((float_g - float_b) * 60.0) / float_difference);

      } else {
        
	 if (g == maximum){
 
             h = 480.0 + (((float_b - float_r) * 60.0) / float_difference);

                  
         } else {
         
             h = 600.0 + (((float_r - float_g) * 60.0) / float_difference);
 
         }
      }   
    }

      
    while (360.0 <= h){
        h -= 360.0;
    }


    // calculate s component
    if (maximum == 0){

        s = 0.0;

    } else {

        s = ((100.0 * difference) / maximum);
   
    }


    // calculate v component
    v = 100.0 * float_max_value;

#ifdef DEBUG
#ifdef DEBUG_BGR2HSV
    printf("\n(%d,%d,%d) in BGR = (%d, %d, %d) in HSV", b, g, r, ret.h/GRANULARITY, ret.s/GRANULARITY, ret.v/GRANULARITY);
#endif
#endif
   
    
    ret.h = (int) (h);
    ret.s = (int) (s);
    ret.v = (int) (v);

    return ret;
}
*/
