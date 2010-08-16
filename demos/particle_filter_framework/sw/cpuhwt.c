#include "kapi_cpuhwt.h"
#include "framework/user_header/uf_particle.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define IMPORTANCE 1

#define DUMMIES 17

#define NH 10
#define NS 10
#define NV 10

//! low thresholds on saturation value for histogramming
#define S_THRESH_2 25
//! low thresholds on V-value for histogramming
#define V_THRESH_2 50

/**
   An HSV histogram represented by NH * NS + NV bins.  Pixels with saturation
   and value greater than S_THRESH and V_THRESH fill the first NH * NS bins.
   Other, "colorless" pixels fill the last NV value-only bins.
*/
typedef struct histogram {
  //! histogram array
  int histo[(NS*NH) + NV];  
  //! length of histogram array
  int n;
  int dummy[DUMMIES];             
} histogram;

typedef histogram observation;

#define PF_GRANULARITY 16384

#ifdef IMPORTANCE
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

  for( i = 0; i < h1->n; i++ )
  {    
     sum += sqrt( hist1[i] * hist2[i] );
  }
  return sum;
}

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


/**
  calculates likelihood between observation data and reference data
   
  @param o: observation data
  @param reference_data: pointer to reference data 
  @return likelihood value
*/
int likelihood (observation * o, observation * reference_data)
{
    int comp;
    //int i;
    int likelihood = 1;
    // 1) compare histogram with reference histogram
    comp = histogram_comp( o, (histogram *) reference_data);
    
    // 2) calcualte likelihood
    // changed to test look up table
    comp = sqrt(comp);
    if (comp > 128) comp = 128;
    if (comp < 0)   comp = 0;
    likelihood = likelihood_values[comp];

//#define DEBUG 1
#ifdef DEBUG
    xil_printf ("\r\n- likelihood: %d", likelihood);
#endif    

    return likelihood;    
}

#else


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

volatile void * current_framebuffer;
int SIZE_X;
int SIZE_Y;
int ** hsvImage = 0;


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

  vd = sdvd_values[v];
  if( s < S_THRESH_2  ||  v < V_THRESH_2 )
  {
    //xil_printf("%d", (NH * NS + vd));
    return NH * NS + vd;
  }

  hd = hd_values[h];
  sd = sdvd_values[s];
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
  unsigned int value = ((unsigned int*)current_framebuffer)[x + y*1024];
  
  h = value % 256;
  value /= 256;
  s = value % 256;
  value /= 256;
  v = value % 256;

  /*unsigned char * p = (unsigned char*) &value;
  h = p[3];  s = p[2]; v = p[1];*/

  return histo_bin_2(h, s, v);
}



/**
   Calculates a cumulative histogram as defined above for a given array  of images
   
   @param image: image, where the hsv histogram bin numbers should be calculated
   @param x1: x-position of pixel in the upper left corner
   @param y1: y-position of pixel in the upper left corner
   @param x2: x-position of pixel in the right corner at the bottom
   @param y2: y-position of pixel in the right corner at the bottom
   @param histo: pointer to a histogram. An un-normalized HSV histogram will be calculated from \a HSV image
*/
void calc_histogram(int ** image, int x1, int y1, int x2, int y2, histogram * histo)
{
//void calc_histogram(int x1, int y1, int x2, int y2, histogram * histo){

  int i,j;
  histo->n = NS*NH + NV;

  // init histogram
  for (i=0; i<histo->n; i++)
  {  
    histo->histo[i] = 0;
  }

  // if the points are not spanning a region, do not calculate
  if (x2 < x1 || y2 < y1)
  {      
       histo->n = -1;
       return;
  }
  
  // fill histogram
  for (i=x1; i<=x2; i++)
  {
      for (j=y1; j<=y2; j++)
      {
	   /*if (image[i][j] == -1)
           {          
	     image[i][j] = tft_get_hsv_pixel(i, j);
           }
           histo->histo[image[i][j]] ++;*/        
           histo->histo[tft_get_hsv_pixel(i, j)] ++;
      }
  }

  //print_histogram (histo);
  return;
}


/**
  normalizes a histogram  
  @param histo: pointer to the histogram, which has to be normalized
*/
void normalize_histogram( histogram * histo)
{
     int i;
     int sum = 0;

     for (i=0; i<histo->n; i++)
     {        
       sum += histo->histo[i];
     }
     
     for (i=0; i<histo->n; i++)
     {
       histo->histo[i] = ( histo->histo[i] * PF_GRANULARITY ) / sum;
     }
}



/**
    extract observation to corresponding particle

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    @param p: particle, where the observation is needed
    @param o: observation to corresponding particle
*/
void extract_observation(particle * p, observation * o){

 
      // i) calculate start and end position of region
         int x1 = (p->x - (p->s * (( p->width - 1) / 2))) / PF_GRANULARITY;
         int x2 = (p->x + (p->s * (( p->width - 1) / 2))) / PF_GRANULARITY;
         
         int y1 = (p->y - (p->s * (( p->height - 1) / 2))) / PF_GRANULARITY;
	 int y2 = (p->y + (p->s * (( p->height - 1) / 2))) / PF_GRANULARITY;

         // correct positions, if needed
         if (x1<0) { x1 = 0; }
         if (y1<0) { y1 = 0; }
         if (x2>SIZE_X-1) { x2 = SIZE_X - 1; }
         if (y2>SIZE_Y-1) { y2 = SIZE_Y - 1;}  

         //xil_printf("\nSend message: x1 = %d, y1 = %d, x2 = %d, y2 = %d (fb: %d, o: %d)",
          //         x1, y1, x2, y2, (int)tft_editing.fb, (int)o);
         /*int i;
         o->n = 110;
         for (i=0; i<110;i++) o->histo[i] = 0;*/
 
      // ii) calculate histogram
         calc_histogram(hsvImage, x1, y1, x2, y2, o);

         //int sum = 0;
         //int sum2 = (x2-x1)*(y2-y1);
         //for (i=0; i<110; i++) sum += o->histo[i];
         //xil_printf("\nSum of histogram values: %d\n", sum);
         
         //debug
         //print_histogram ((histogram*)o);
         
      // iii) normalize histogram
         // CHANGE CHANGE CHANGE
	 normalize_histogram (o);
        // END OF CHANGE CHANGE CHANGE
}

#endif




#ifdef IMPORTANCE


//! struct definition with all informations needed by the hw importance
typedef struct information_struct_i_2
{
  volatile particle * particles;
  volatile int number_of_particles;
  volatile int particle_size;
  volatile int block_size;
  volatile int observation_size;
  volatile observation * observations;
  volatile observation * ref_data;

} information_struct_i_2;

#else


//! struct definition with all informations needed by the hw importance
typedef struct information_struct_o_2
{
  volatile particle * particles;
  volatile int number_of_particles;
  volatile int particle_size;
  volatile int block_size;
  volatile int observation_size;
  volatile observation * observations;
  volatile void ** input;
  volatile int parameter_size;
  volatile int * parameter;

} information_struct_o_2;

#endif


/**
   stage waits for message i to weight the i-th particle block according to the user function. 
   Then it send the message i to the next stage.
*/
void stage_entry()
{
    Xuint32 mb_start_handle_2 = 0x0;
    Xuint32 mb_stop_handle_2  = 0x1;
    //Xuint32 hw_mb_measurement_handle_2  = 0x2;

#ifdef IMPORTANCE
    unsigned char * information_struct_i_2_handle = (unsigned char*) getInitData();
    //(unsigned char*)0x01C00000;
    xil_printf("\ninformation struct importance address (CPU-HWT-Thread): %d\r\n", information_struct_i_2_handle);
    information_struct_i_2 * information_i_2 = (information_struct_i_2 *) information_struct_i_2_handle;
    particle * particles_2 = (particle *) information_i_2[0].particles;
    observation * observations_2 = (observation *)  information_i_2[0].observations;
    observation * ref_data_2 = (observation *) information_i_2[0].ref_data;
    volatile int block_size_2 = information_i_2[0].block_size;
    volatile int N_2 = information_i_2[0].number_of_particles;
    //xil_printf("\nparticle size (CPU-HWT-Thread): %d\r\n", information_i_2[0].particle_size);
#else
    unsigned char * information_struct_o_2_handle = (unsigned char*) getInitData();
    //(unsigned char*)0x01C00000;
    xil_printf("\n--- information struct observation address (CPU-HWT-Thread): %X\r\n", (unsigned int)information_struct_o_2_handle);
    information_struct_o_2 * information_o_2 = (information_struct_o_2 *) information_struct_o_2_handle;
    particle * particles_2 = (particle *) information_o_2[0].particles;
    observation * observations_2 = (observation *)  information_o_2[0].observations;
    volatile int block_size_2 = information_o_2[0].block_size;
    volatile int N_2 = information_o_2[0].number_of_particles;
    current_framebuffer = *(information_o_2[0].input);
    SIZE_X = information_o_2[0].parameter[0];
    SIZE_Y = information_o_2[0].parameter[1];
#endif   

    // unsigned int thread_number = (unsigned int) data;
    int from, to;
    int done;
    int i;
    int new_message = FALSE;
    int message = 1;
    int message_to_delivere = FALSE;
    //int num_received_messages = 0;   

    while (42) {

      //xil_printf("\nwait for message (CPU-HWT-Thread)\r\n");
      // 1) if there is no message to delivered, check for new message
      while (message_to_delivere == FALSE && new_message == FALSE)
      {
            //xil_printf("\ntry to receive message (CPU-HWT-Thread)\r\n");
            message = (int) cyg_mbox_get( mb_start_handle_2 );
            //xil_printf("\nreceived message %d (CPU-HWT-Thread)\r\n", message);
            if (message > 0 && message <= (N_2/block_size_2))
            {
	          new_message = TRUE;
            }
      }

      // 2) if a new message has arrived, sample the particles
      /*num_received_messages++;
      if ((num_received_messages%100)==0)
      {
           xil_printf("\n100 messages received (CPU-HWT-Thread)\r\n");
      }*/
            
      new_message = FALSE;
      from = (message - 1) * block_size_2;
      to   = from + block_size_2 - 1;
      if ((N_2 - 1) < to)
	       to = N_2 - 1; 

      XCache_EnableDCache( 0xF0000000 );
      //XCache_EnableICache( 0xF0000000 );
 
#ifndef IMPORTANCE
      current_framebuffer = *(information_o_2[0].input);
#endif

      for (i=from; i<=to; i++)
      {
#ifdef IMPORTANCE
             particles_2[i].w = likelihood (&observations_2[i], ref_data_2);
#else
             extract_observation(&particles_2[i], &observations_2[i]);
#endif
      }

      //xil_printf("\ncalculated likelihood (CPU-HWT-Thread)\r\n");

      message_to_delivere = TRUE;

      XCache_EnableDCache( 0xF0000000 );
      //XCache_EnableICache( 0xF0000000 );

      // 3) if a message should be delivered, deliver it
      while ( message_to_delivere){

           //done = (int) cyg_mbox_tryput( mb_importance_done_handle_2,  message );
           done = (int) cyg_mbox_put( mb_stop_handle_2,  (void *)message );
           if (done > 0)
           {
              //xil_printf("\nsent message (CPU-HWT-Thread)\r\n");
              message_to_delivere = FALSE;
           }
      } 
   }
}


/**
  main function for the cpu-hw-thread
*/
int main(void)
{
    INIT;
    xil_printf("\n####################################### CPU-HWT starting... #######################################\r\n");  
 
    ////XCache_EnableICache( 0x80000000 );
    ////XCache_EnableDCache( 0x80000000 );
    ////XCache_EnableICache( 0xF0000000 );

    XCache_EnableICache( 0xF0000000 );
    XCache_EnableDCache( 0xF0000000 );

    //start thread
    stage_entry();
}

