#include "../header/particle_filter.h"
#include <stdlib.h>
#include "../../header/tft_screen.h"



/**
   inits particle array according to information, which are stored in the information array.. Here: The user selected a object with (x0, y0) as centric position. The width and height are defined as well. The information is stored in the information array.

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  @param information: pointer to information array containing initialization information
  @param size: size of information array

*/
void init_particles (int * information, int size){
   
   int i;
   int x0 = information[0];
   int y0 = information[1];
   int width = information[2];
   int height = information[3];

   for (i=0; i<N; i++){
       
         particles[i].w = PF_GRANULARITY / N;
         particles[i].x = x0 * PF_GRANULARITY;
         particles[i].y = y0 * PF_GRANULARITY;
         particles[i].s = 1 * PF_GRANULARITY;
         particles[i].xp = x0 * PF_GRANULARITY;
         particles[i].yp = y0 * PF_GRANULARITY;
         particles[i].sp = 1 * PF_GRANULARITY;
         particles[i].x0 = x0 * PF_GRANULARITY;
         particles[i].y0 = y0 * PF_GRANULARITY;
         particles[i].width = width;
         particles[i].height = height;
         particles[i].dummy[0] = 1;
         particles[i].dummy[1] = 2;
         particles[i].dummy[2] = 3;
         particles[i].dummy[3] = 4;
         particles[i].dummy[4] = 5;
    }

   
   for (i=((1*N)/5); i<((2*N)/5); i++){
        particles[i].x += (rand() / (RAND_MAX / 3000));
   }

   for (i=((2*N)/5); i<((3*N)/5); i++){
        particles[i].x -= (rand() / (RAND_MAX / 3000));
   }

   for (i=((3*N)/5); i<((4*N)/5); i++){
        particles[i].y -= (rand() / (RAND_MAX / 2000));
   }

   for (i=((4*N)/5); i<N; i++){
        particles[i].y += (rand() / (RAND_MAX / 2000));
   }

    //for (i=0; i<N; i++){
    //    diag_printf("\nparticle[%d].x = %d (old: %d)", i, particles[i].x, particles[i].xp);
   //}  
   
   // set observations input address
   set_observations_input(tft_editing.fb);

}
