#ifndef __OBSERVATION_H__
#define __OBSERVATION_H__

#include "config.h"
#include "../framework/header/particle_filter.h"
#include "bgr2hsv.h"
#include "histogram.h"
#include "ethernet.h"

/*! \file observation.h 
 * \brief gets observations for all sampled particles
 */



/**
  gets observations (histograms) for sampled particles and writes them into an array
  
  @param sampled_particles: pointer to array with sampled particles
  @param number_of_particles: number of particles
  @param observations: pointer to array of observations (histograms)
*/
void get_observations(particle * sampled_particles, int number_of_particles, histogram * observations);


/**
  gets observations (histograms) for sampled particles and writes them into an array without receiving a new frame
  
  @param sampled_particles: pointer to array with sampled particles
  @param number_of_particles: number of particles
  @param observations: pointer to array of observations (histograms)
*/
void get_observations_without_new_frame ( particle * sampled_particles, int number_of_particles, histogram * observations);


/**
  get reference data to a specific partice
  
  @param ref_particle: pointer to reference particles
  @param ref_histogram: pointer to reference histogram
*/
void get_reference_data(particle * ref_particle, histogram * ref_histogram);





#endif                          //__OBSERVATION_H__
