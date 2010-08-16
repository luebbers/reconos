#ifndef __HISTOGRAM_H__
#define __HISTOGRAM_H__

#include "config.h"
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>

/*! \file histogram.h 
 * \brief calculates a hsitogram from a hsv image in a specified region
 */


//! pane data (corresponding to a particle)
typedef struct pane_data{
   //! x-position of upper left corner 
   int x1;
   //! x-position of upper left corner
   int y1;
   //! y-position of lower right corner
   int x2;
   //! y-position of lower right corner
   int y2;
   //! pointer to histogram
   histogram * o;
   //! pointer to framebuffer
   void      * fb;
   //! number of block
   int block;
   //! block size
   int block_size;
} pane_data;



//! message boxes for histogram
cyg_mbox *mb_histogram, *mb_histogram_done;

//! handles for histogram message boxes
cyg_handle_t *mb_histogram_handle, *mb_histogram_done_handle;



/**
   Calculates a cumulative histogram as defined above for a given array  of images
   
   @param image: image, where the hsv histogram bin numbers should be calculated
   @param x1: x-position of pixel in the upper left corner
   @param y1: y-position of pixel in the upper left corner
   @param x2: x-position of pixel in the right corner at the bottom
   @param y2: y-position of pixel in the right corner at the bottom
   @param histo: pointer to a histogram. An un-normalized HSV histogram will be calculated from \a HSV image
*/
void calc_histogram(int ** image, int x1, int y1, int x2, int y2, histogram * histo);
//void calc_histogram(int x1, int y1, int x2, int y2, histogram * histo);


/**
  normalizes a histogram
  
  @param histo: pointer to the histogram, which has to be normalized

*/
void normalize_histogram( histogram * histo );


/**
   prints histogram to screen
  
   @param histo: histogram, which should be printed
 */
void print_histogram (histogram * histo);



#endif                          //__HISTOGRAM_H__
