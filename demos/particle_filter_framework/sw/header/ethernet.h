#ifndef __ETHERNET_H__
#define __ETHERNET_H__

#include "config.h"
#include "../framework/header/particle_filter.h"
#include "frame_size.h"
#include "bgr2hsv.h"

/*! \file ethernet.h 
 * \brief uses ethernet to establish a connection and to receive frames
 */


//! struct containing bounding box information for particles of one frame
typedef struct particle_data
{
       //! x-position of upper left corner of bounding box
       volatile unsigned int x1; 
       //! y-position of upper left corner of bounding box
       volatile unsigned int y1;
       //! x-position of lower right corner of bounding box
       volatile unsigned int x2; 
       //! y-position of lower right corner of bounding box
       volatile unsigned int y2; 
       //! equals '1': if this particle information is the state estimation, '0' else
       volatile unsigned int best_particle;
} particle_data;

//! semaphores
cyg_sem_t *sem_read_new_frame_start, *sem_read_new_frame_stop;


/**
  writes next frame to specific ram

*/
void read_frame( void );

/** 
   resets the framebuffer
*/
void reset_the_framebuffer();


#ifndef NO_ETHERNET
/**
  creates a server socket and waits for incomming connection.

  @param port: listen port for new data/frames
  @return returns a valid file descriptor on success. returns -1 on error.
*/
int accept_connection(int port);


/**
   establishes connection to ethernet

   @param port: port number for videotransfer
   @param region: pointer to input region array
   @return returns '0' if connection is established, else '1'
*/
int establish_connection(int port, int * region);


/**
   sends particles back to pc

  @param particle_array: array of particle, which have to be send back
  @param array_size: size of particle array
*/
void send_particles_back(particle * particle_array, int array_size );


/**
   sends best particle back to pc

  @param particle_array: array of particle, which have to be send back
  @param array_size: size of particle array
*/
void send_best_particle_back(particle * particle_array, int array_size );


#endif

#endif                          //__ETHERNET_H__
