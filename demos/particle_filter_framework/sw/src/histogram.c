#include <stdlib.h>
#include <stdio.h>
#include "../header/histogram.h"
#include "../header/bgr2hsv.h"
#include "../header/observation.h"
#include "../header/frame_size.h"



/**
   Calculates a cumulative histogram as defined above for a given array  of images
   
   @param image: image, where the hsv histogram bin numbers should be calculated
   @param x1: x-position of pixel in the upper left corner
   @param y1: y-position of pixel in the upper left corner
   @param x2: x-position of pixel in the right corner at the bottom
   @param y2: y-position of pixel in the right corner at the bottom
   @param histo: pointer to a histogram. An un-normalized HSV histogram will be calculated from \a HSV image
*/
void calc_histogram(int ** image, int x1, int y1, int x2, int y2, histogram * histo){
//void calc_histogram(int x1, int y1, int x2, int y2, histogram * histo){

  int i,j;
  histo->n = NS*NH + NV;

  // init histogram
  for (i=0; i<histo->n; i++){  
    histo->histo[i] = 0;
  }

  // if the points are not spanning a region, do not calculate
  if (x2 < x1 || y2 < y1){
      
       histo->n = -1;
       return;
  }
  
  
  // fill histogram
  for (i=x1; i<=x2; i++){
      for (j=y1; j<=y2; j++){
 
	   if (image[i][j] == -1){
          
	     image[i][j] = tft_get_hsv_pixel(i, j);
           }

           histo->histo[image[i][j]] ++;
           
           //histo->histo[tft_get_hsv_pixel(i, j)] ++;
           
      }
  }

  //print_histogram (histo);

  return;

}



/**
  normalizes a histogram
  
  @param histo: pointer to the histogram, which has to be normalized
*/
void normalize_histogram( histogram * histo){

     int i;
     int sum = 0;

     for (i=0; i<histo->n; i++){
        
       sum += histo->histo[i];
     }
     
     for (i=0; i<histo->n; i++){

       histo->histo[i] = ( histo->histo[i] * GRANULARITY ) / sum;
     }

}



/**
   prints histogram to screen
  
   @param histo: histogram, which should be printed
 */
void print_histogram (histogram * histo){

  int i,j;
 
   printf("\n-------------------------------------------------------------------------------------------------\n");
 
  for (i=0;i<NS;i++){

    diag_printf("| ");

    for (j=0; j<NH; j++){
       
        printf("%d\t| ", histo->histo[i*NS+j]);
       
       
    }
    
    printf("|||\t %d \t|", histo->histo[(NH*NS)+i]);
    printf("\n-------------------------------------------------------------------------------------------------\n");
  } 

  printf("\n");

}


