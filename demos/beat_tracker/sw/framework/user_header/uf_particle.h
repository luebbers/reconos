/** @file
    definition of particle data
*/

#ifndef UF_PARTICLE_H
#define UF_PARTICLE_H
#include "../../header/config.h"


/******************************* Definitions *********************************/

//! Granularity for fixed point representation (potention of 2)
#define PF_GRANULARITY 16384 

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
	//! last likelihood value (not normalized)
	volatile int likelihood;	
  
	///////////////////////////////////
	// START OF USER SPECIFIC DATA ///
	/////////////////////////////////

	//! next beat position
	volatile unsigned long int next_beat;  

	//! last beat position
	volatile unsigned long int last_beat;  

	//! tempo
	volatile unsigned int tempo;

	//! initial phase (true or false)
	volatile unsigned int initial_phase;

	//! interval min
	volatile unsigned long int interval_min;

	//! interval max
	volatile unsigned long int interval_max;

	/////////////////////////////////
	// END OF USER SPECIFIC DATA ///
	///////////////////////////////
} particle;





#endif
