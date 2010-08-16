/** @file
    definition of particle data
*/

#ifndef UF_PARTICLE_H
#define UF_PARTICLE_H


/******************************* Definitions *********************************/

//! Granularity for fixed point representation (potention of 2)
#define PF_GRANULARITY 16384 

//! Tolerance factor that at least one observation is still found as an object
//#define OBJECT_TOLERANCE 16 

//! defines, if particles should be sorted or not
//#define Q_SORT 1


/******************************* Structures **********************************/

/**
   A particle is an instantiation of the state variables of the system
   being monitored.  A collection of particles is essentially a
   discretization of the posterior probability of the system.
*/
typedef struct particle {

  //////////////////////////////////////////
  // DO NOT CHANGE                       //
  // weight w MUST be first element !!! //
  ///////////////////////////////////////
  //! particle weight (has to be part of a particle and has to be the first element)
  volatile int w; 
  
  ///////////////////////////////////
  // START OF USER SPECIFIC DATA ///
  /////////////////////////////////
  
  //! current x coordinate
  volatile int x;          
  //! current y coordinate
  volatile int y;    
  //! current scale factor
  volatile int s;        
  //! previous x coordinate
  volatile int xp;       
  //! previous y coordinate
  volatile int yp;        
  //! previous scale factor
  volatile int sp;       
  //! original x coordinate
  volatile int x0;    
  //! original y coordinate
  volatile int y0;   
  //! original width of bounding box of object selection
  volatile int width;        
  //! original height of bounding box of object selection
  volatile int height;      
  //! here a particle should be 64 bytes. When a block size is 2 * k, then only bursts are needed for hw sampling.
  volatile int dummy[5]; 

  /////////////////////////////////
  // END OF USER SPECIFIC DATA ///
  ///////////////////////////////
} particle;





#endif
