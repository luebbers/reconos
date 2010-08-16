#include "../header/particle_filter.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
//#include "../../header/histogram.h"
//#include "../../header/bgr2hsv.h"


//! distribution parameter
#define LAMBDA 16

//! squeeze factor defines the squeezing of the histogram comparison values for the likelihood function
//#define SQUEEZE_FACTOR 1 // good 2

//#define DEBUG 1

/*
  Computes squared distance metric based on the Battacharyya similarity
  coefficient between histograms.
  
  @param h1 first histogram; should be normalized
  @param h2 second histogram; should be normalized
  
  @return Returns a squared distance based on the Battacharyya similarity
    coefficient between \a h1 and \a h2
*/
int histogram_comp ( histogram* h1, histogram* h2 )
{
  int* hist1, * hist2;
  int i;
  int sum = 0;

  hist1 = h1->histo;
  hist2 = h2->histo;

   // According the the Battacharyya similarity coefficient, 
   // D^2 = \sum_1^n{ \sqrt{ h_1(i) * h_2(i) } } }    // h_1/2(i) are integers here

  for( i = 0; i < h1->n; i++ ){
    
     sum += sqrt( hist1[i] * hist2[i] );
  }
  return sum;
}



/**
  calculates likelihood between observation data and reference data
   
  @param o: observation data
  @param reference_data: pointer to reference data 
  @return likelihood value
*/



/*
  Computes squared distance metric based on the Battacharyya similarity
  coefficient between histograms.
  
  @param h1 first histogram; should be normalized
  @param h2 second histogram; should be normalized
  
  @return Returns a squared distance based on the Battacharyya similarity
    coefficient between \a h1 and \a h2
*/
/*
float histogram_comp ( observation* h1, observation* h2 )
{
  int* hist1, * hist2;
  float sum = 0.0, sum2 = 0.0;
  int i, n;
  float value1, value2, inv_sum1, inv_sum2;

  n = h1->n;
  hist1 = h1->histo;
  hist2 = h2->histo;


  // compute sum of all bins and multiply each bin by the sum's inverse
  for( i = 0; i < n; i++ ){
    sum  += hist1[i];
    sum2 += hist2[i];
  }
  inv_sum1 = 1.0 / sum;
  inv_sum2 = 1.0 / sum2;
  sum = 0.0;
   // According the the Battacharyya similarity coefficient,
   // D = \sqrt{ 1 - \sum_1^n{ \sqrt{ h_1(i) * h_2(i) } } }
  for( i = 0; i < n; i++ ){
    
     value1 =  (float) 1.0 * hist1[i];
     value1 *= inv_sum1;
     
     value2 =  (float) 1.0 * hist2[i];
     value2 *= inv_sum2;

     sum += sqrt( value1 * value2 );

  }
  return 1.0 - sum;
}
*/

int likelihood_values[129] = {
         1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
         2, 2, 2, 2, 3, 3, 3, 4, 4, 4,
         5, 5, 6, 6, 7, 8, 8, 9, 10, 11,
         12, 13, 14, 15, 17, 18, 20, 21, 23, 25,
         28, 30, 33, 35, 39, 42, 46, 50, 54, 59,
         64, 70, 76, 82, 90, 97, 106, 115, 125, 136,
         148, 161, 175, 190, 207, 225, 244, 265, 289, 314,
         341, 371, 403, 438, 476, 518, 563, 611, 665, 722,
         785, 854, 928, 1008, 1096, 1191, 1295, 1408, 1530, 1663,
         1808, 1965, 2135, 2321, 2523, 2742, 2980, 3240, 3521, 3827,
         4160, 4521, 4914, 5341, 5806, 6310, 6859, 7455, 8103, 8807,
         9572, 10404, 11308, 12291, 13359, 14520, 15782, 17154, 18644, 20265,
         22026, 23940, 26021, 28282, 30740, 33411, 36315, 39471, 42901 };




int likelihood (observation * o, observation * reference_data){


    
    int comp;
    //int i;
    int likelihood = 1;
    //histogram * observation_histogram = (histogram *) malloc (sizeof(histogram));

    // 1) calcualte histogram
    //calc_histogram(o->x, o->y, (o->x + o->width), (o->y + o->height), observation_histogram);
    //calc_histogram(hsvImage, o->x, o->y, (o->x + o->width), (o->y + o->height), observation_histogram);

    // 2) normalize histogram
    //normalize_histogram (observation_histogram);

    // 3) compare histogram with reference histogram
    comp = histogram_comp( o, (histogram *) reference_data);
    //free(observation_histogram);
    

    /*if (comp > 40960){

         comp = 40960;
    }

    comp /= 2048;

    if (comp > 15) comp = 15;

    
    //likelihood = 3**comp;
    for (i=0; i<comp; i++){
    
         likelihood *= 3; 
    }
    */
    
    // 4) calcualte likelihood
    // changed to test look up table
    comp = sqrt(comp);
    if (comp > 128) comp = 128;
    if (comp < 0)   comp = 0;
    //likelihood = exp(((float) (1.0 * comp))/12);
    likelihood = likelihood_values[comp];

//#define DEBUG 1
#ifdef DEBUG
    printf ("\nlikelihood: %d", likelihood);
#endif    

    return likelihood;
    
}




/**
  calculates likelihood between observation data and reference data
   
  @param o: observation data
  @param reference_data: pointer to reference data 
  @return likelihood value
*/

/*
int likelihood (observation * o, observation * reference_data){

    float comp2;
    int comp;

    comp2 = (float) histogram_comp( (histogram *) o, (histogram *) reference_data);

    // squeeze range for better results
    //comp /= SQUEEZE_FACTOR;

    // current version
    //comp2 = (float) comp;
    //comp2 /= PF_GRANULARITY;


    comp2 = exp( -LAMBDA * comp2 );

    //comp2 *= PF_GRANULARITY;

    //comp = ((int) comp2); 

    comp = (PF_GRANULARITY * comp2);

#ifdef DEBUG
    printf ("\nlikelihood: %d", comp);
#endif    

    return comp;
}
*/
