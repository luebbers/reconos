#include <stdlib.h>
#include <stdio.h>
#include "../header/observation.h"
#include "../header/frame_size.h"



/**
  gets observations (histograms) for sampled particles and writes them into an array
  
  @param sampled_particles: pointer to array with sampled particles
  @param number_of_particles: number of particles
  @param observations: pointer to array of observations (histograms)
*/

void get_observations ( particle * sampled_particles, int number_of_particles, histogram * observations){

    int i,x1,x2,y1,y2;
    histogram * tmp = observations;
   
    // 1) read frame 
    read_frame();
    
    // 2) reset histogram box image
    reset_hsvImage();

    // 3) for every particle: calculate histogram
    for (i=0; i<number_of_particles; i++){

         // calculate start and end position of region
         x1 = (sampled_particles->x / PF_GRANULARITY)  - ((sampled_particles->s * (( sampled_particles->width - 1) / 2)) / PF_GRANULARITY);
         x2 = (sampled_particles->x / PF_GRANULARITY)  + ((sampled_particles->s * (( sampled_particles->width - 1) / 2)) / PF_GRANULARITY);
         
         y1 = (sampled_particles->y / PF_GRANULARITY)  - ((sampled_particles->s * (( sampled_particles->height - 1) / 2)) / PF_GRANULARITY);
	 y2 = (sampled_particles->y / PF_GRANULARITY)  + ((sampled_particles->s * (( sampled_particles->height - 1) / 2)) / PF_GRANULARITY);

         // correct positions, if needed
         if (x1<0) { x1 = 0; }
         if (y1<0) { y1 = 0; }
         if (x2>SIZE_X-1) { x2 = SIZE_X - 1; }
         if (y2>SIZE_Y-1) { y2 = SIZE_Y - 1;}
         
         // calculate histogram
         calc_histogram(hsvImage, x1, y1, x2, y2, tmp);
         //calc_histogram(x1, y1, x2, y2, tmp);
         
         //4) normalize histogram
         normalize_histogram (tmp);
         
         // next histogram
         tmp++;
         sampled_particles++;

     }
}




/**
  gets observations (histograms) for sampled particles and writes them into an array without receiving a new frame

  D E B U G   F U N C T I O N
  
  @param sampled_particles: pointer to array with sampled particles
  @param number_of_particles: number of particles
  @param observations: pointer to array of observations (histograms)
*/
void get_observations_without_new_frame ( particle * sampled_particles, int number_of_particles, histogram * observations){

    int i,x1,x2,y1,y2;
    histogram * tmp = observations;

 
    // 1) read frame 
    read_frame();
    
    // 2) create hsv image
    convert_bgr2hsv();

    // 3) for every particle: calculate histogram
    for (i=0; i<number_of_particles; i++){

         // calculate start and end position of region
         x1 = (sampled_particles->x / PF_GRANULARITY)  - ((sampled_particles->s * (( sampled_particles->width - 1) / 2)) / PF_GRANULARITY);
         x2 = (sampled_particles->x / PF_GRANULARITY)  + ((sampled_particles->s * (( sampled_particles->width - 1) / 2)) / PF_GRANULARITY);
         
         y1 = (sampled_particles->y / PF_GRANULARITY)  - ((sampled_particles->s * (( sampled_particles->height - 1) / 2)) / PF_GRANULARITY);
	 y2 = (sampled_particles->y / PF_GRANULARITY)  + ((sampled_particles->s * (( sampled_particles->height - 1) / 2)) / PF_GRANULARITY);

         // correct positions, if needed
         if (x1<0) { x1 = 0; }
         if (y1<0) { y1 = 0; }
         if (x2>SIZE_X-1) { x2 = SIZE_X - 1; }
         if (y2>SIZE_Y-1) { y2 = SIZE_Y - 1;}
         
         // calculate histogram
         calc_histogram(hsvImage, x1, y1, x2, y2, tmp);
         //calc_histogram(x1, y1, x2, y2, tmp);
         
         //4) normalize histogram
         normalize_histogram (tmp);
         
         // next histogram
         tmp++;
         sampled_particles++;

     }
}



/**
  get reference data to a specific particle
  
  @param ref_particle: pointer to reference particles
  @param ref_histogram: pointer to reference histogram
*/
void get_reference_data(particle * ref_particle, histogram * ref_histogram){

      // first frames are often not too good. So skip them
      // only needed, if webcam is used
      // read_frame(); read_frame(); read_frame(); read_frame();
      
      // get reference histogram
      get_observations (ref_particle, 1, ref_histogram);

}

