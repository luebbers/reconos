#include "../header/particle_filter.h"
#include "../../header/config.h"
#include "../../header/frame_size.h"
#include "../../header/bgr2hsv.h"
#include "../../header/histogram.h"
#include "../../header/tft_screen.h"
#include <stdlib.h>
#include <stdio.h>
#include <xcache_l.h>



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

         //diag_printf("\nSend message: x1 = %d, y1 = %d, x2 = %d, y2 = %d (fb: %d, o: %d)",
          //         x1, y1, x2, y2, (int)tft_editing.fb, (int)o);
         /*int i;
         o->n = 110;
         for (i=0; i<110;i++) o->histo[i] = 0;*/


         ////////////////////////////////////////////////////////
         //  TEST   TEST   TEST
         ////////////////////////////////////////////////////////
         /*x1 = 0;
         y1 = 0;
         x2 = 40;
         y2 = 0;
         int ret1[40];
         int h = 0; int s = 0; int v = 0;
         int ret2 = 0;
         for (i=0; i<40; i++){
              h = (rand() / (RAND_MAX / 180));
              s = (rand() / (RAND_MAX / 256));
              v = (rand() / (RAND_MAX / 256));
              ret1[i] = h + (s*256) + (v*256*256);
              ret2 = histo_bin_2(h,s,v);
              diag_printf("\n%d) [h=%d, s=%d, v=%d] = %d => Histogram value: %d", i, h, s, v, ret1[i], ret2);
         }*/
         /////////////////////////////////////////////////////////
         //  END TEST   END TEST   END TEST
         ////////////////////////////////////////////////////////
 
         
         #ifdef USE_CACHE  
           XCache_EnableDCache( 0xF0000000 );
         #endif

      // ii) calculate histogram
         calc_histogram(hsvImage, x1, y1, x2, y2, o);

         //int sum = 0;
         //int sum2 = (x2-x1)*(y2-y1);
         //for (i=0; i<110; i++) sum += o->histo[i];
         //diag_printf("\nSum of histogram values: %d\n", sum);
         
         //debug
         //print_histogram ((histogram*)o);
         
      // iii) normalize histogram
         // CHANGE CHANGE CHANGE
	 normalize_histogram (o);
        // END OF CHANGE CHANGE CHANGE

         #ifdef USE_CACHE  
           //XCache_EnableDCache( 0xF0000000 );
         #endif

         //debug
         //print_histogram ((histogram*)o);

}
