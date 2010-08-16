#include <stdlib.h>
#include <stdio.h>
#include "../header/display.h"
#include "../header/tft_screen.h"
#include "../header/frame_size.h"



/**
  draws a point (x, y) to screen
  
  @param x: x coordinate of the point
  @param y: y coordinate of the point
  @param best_particle: is the selected particle the best particle?
*/
inline void draw_pixel(int x, int y, int best_particle){
   
  if (x < 0 || y < 0 || x > SIZE_X-1 || y > SIZE_Y-1) return;

  if (best_particle == 1)
          // draw best particle in red
          tft_set_pixel (x, y, 255, 0, 0);
   else  
          // draw other particles in blue
          tft_set_pixel (x, y, 0, 0, 255);
}




/**
  draws a single line to screen from (x1, y1) to (x2, y2)
  
  @param x_line: 1, if line is parallel to x-axis, 0, if line is parallel to y-axis
  @param a: start value 
  @param b: end value 
  @param pos: fixed x or y value (depends if it is parallel to x- or y-axis)
  @param best_particle: is the selected particle the best particle?
*/
void draw_line (int x_line, int a, int b, int pos, int best_particle){

  int i;

  if (b<a) return;
            
  for (i=a; i<=b; i++){

    if (x_line == 1)
         draw_pixel(i, pos, best_particle);
    else
         draw_pixel(pos, i, best_particle);
  }
}




/**
  displays one particle to screen
  
  @param particle: pointer to the particle
  @param best_particle: is the selected particle the best particle?
*/
void display_particle (particle * p, int best_particle){

   // calculate start and end position of region
   int x1 = (p->x / PF_GRANULARITY)  - ((p->s * (( p->width - 1) / 2)) / PF_GRANULARITY);
   int x2 = (p->x / PF_GRANULARITY)  + ((p->s * (( p->width - 1) / 2)) / PF_GRANULARITY);
         
   int y1 = (p->y / PF_GRANULARITY)  - ((p->s * (( p->height - 1) / 2)) / PF_GRANULARITY);
   int y2 = (p->y / PF_GRANULARITY)  + ((p->s * (( p->height - 1) / 2)) / PF_GRANULARITY);

     // correction
   if (x1 < 0) x1 = 0;
   if (x2 > SIZE_X-1) x2 = SIZE_X-1;
   if (y1 < 0) y1 = 0;
   if (y2 > SIZE_Y-1) y2 = SIZE_Y-1;
   
   // draw rectangle with 4 lines
   draw_line (1, x1, x2, y1, best_particle);
   draw_line (1, x1, x2, y2, best_particle);
   draw_line (0, y1, y2, x1, best_particle);
   draw_line (0, y1, y2, x2, best_particle);


}



/**
  displays first k particles as rectangles to screen
  
  @param particles: pointer to the particle array
  @param k: show the first k particles
*/
void display_particles( particle * particles, int k){


     int i;
   
     if (k<1) return;

     // for every particle
     for (i = 0; i<k; i++){
 
              //display particle
              //if((i%10) == 0) 
              display_particle(particles, 0);
	      //if (i==10) display_particle(particles, 0);  
              

              // get next particle
              particles++;   
  
     }
}



/**
  displays best particle as rectangles to screen
  
  @param particles: pointer to the particle array
*/
void display_best_particle( particle * particles){

     int i;

     //int high_value = 0;
     //int position = 0;
     //particle * p = particles;

     particle medium;
     medium.x = 0;
     medium.y = 0;
     medium.s = 0;
     medium.width = particles[0].width;
     medium.height = particles[0].height;

     // calculate medium
     for(i=0; i<N; i++){

         medium.x += particles[i].x;
         medium.y += particles[i].y;
         medium.s += particles[i].s;
     }

     medium.x /= N;
     medium.y /= N;
     medium.s /= N;
   
     // for every particle
     /*for (i = 0; i<N; i++){
 
              //update highest value
               if (p->w > high_value){
              
		   // if currently highest value save value and position
		   high_value = p->w;
                   position = i;
               }

              // get next particle
              p++;  
      }*/

     // display best particle
     //display_particle(&particles[position], 1); 

     // display medium particle
    display_particle(&medium, 1); 

    //printf("\n%d, %d, %d, %d, %d", medium.x/PF_GRANULARITY, medium.y/PF_GRANULARITY, medium.s, medium.width, medium.height);

}



/**
 switches from one frame buffer to the other
 There are two framebuffer. One of both is in the working state, while the other is in the display state.
*/
void switch_framebuffer_on_screen(){

     // switch framebuffer, after all particles are drawn
     switch_framebuffer();

}
