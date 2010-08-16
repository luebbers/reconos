#ifndef __DISPLAY_H__
#define __DISPLAY_H__

#include "config.h"
#include "../framework/header/particle_filter.h"


/*! \file display.h 
 * \brief displays one or more particles in form of a rectangle on screen
 */



/**
  displays first k particles as rectangles to screen
  
  @param particles: pointer to the particle array
  @param k: show the first k particles
*/
void display_particles( particle * particles, int k);


/**
  displays best particle as rectangles to screen
  
  @param particles: pointer to the particle array
*/
void display_best_particle( particle * particles);

/**
 switches from one frame buffer to the other
 There are two framebuffer. One of both is in the working state, while the other is in the display state.
*/
void switch_framebuffer_on_screen( void );




#endif                          //__DISPLAY_H__
