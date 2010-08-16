/** @file
    header file for using the particle filter framework
*/

#ifndef PARTICLE_FILTER_H
#define PARTICLES_FILTER_H

//! defines stack size for sw threads
//#define STACK_SIZE 16384
//#define STACK_SIZE 32768
//#define STACK_SIZE 65536

#define STACK_SIZE 262144

//! defines if the cache is used
//#define USE_CACHE 1

#include "communication.h"
#include "../user_header/uf_particle.h"
#include "../user_header/uf_observation.h"



/**
creates the particle array, resources and communication threads

@param number_of_particles: number of particles
@param particle_block_size: size of a particle block
*/
void create_particle_filter (unsigned int number_of_particles, unsigned int particle_block_size);



/**
  inits particle array according to information, which are stored in the information array

  @param information: pointer to information array
  @param size: size of information array
*/
void init_particles (int * information, int size);


#ifndef ONLYPC
/**
   starts particle filter by getting all particles sampled.

*/
void start_particle_filter(void);



/**
   creates sample SW threads

   @param number_of_threads: number of threads for sampling step
*/
void set_sample_sw (unsigned int number_of_threads);



/**
   creates sample HW threads

   @param number_of_threads: number of threads for sampling step
   @param reconos_slots: pointer to array including the slot numbers, where the sampling hw threads are connected to
   @param parameter: pointer to a array filled with parameter (size <= 128 byte)
   @param number_of_parameter: number of parameter in parameter array
*/
void set_sample_hw (unsigned int number_of_threads, unsigned int * reconos_slots, int * parameter, unsigned int number_of_parameter);
#endif



/**
  predicts the new state after a transition model for a given particle (user function)
  
  @param p a particle to be predicted
  @return Returns a new particle sampled based on <EM>p</EM>'s transition model
*/
void prediction( particle * p);





#ifndef ONLYPC
/**
   creates observation SW threads

   @param number_of_threads: number of threads for observation step
*/
void set_observe_sw (unsigned int number_of_threads);


/**
   creates observation HW threads

   @param number_of_threads: number of threads for observation step
   @param reconos_slots: pointer to array including the slot numbers, where the observation hw threads are connected to
   @param parameter: pointer to a array filled with parameter (size <= 128 byte)
   @param number_of_parameter: number of parameter in parameter array
*/
void set_observe_hw (unsigned int number_of_threads, unsigned int * reconos_slots, int * parameter, unsigned int number_of_parameter);
#endif


#ifndef ONLYPC
/**
   creates importance SW threads

   @param number_of_threads: number of threads for importance step
*/
void set_importance_sw (unsigned int number_of_threads);


/**
   creates importance HW threads

   @param number_of_threads: number of threads for importance step
   @param reconos_slots: pointer to array including the slot numbers, where the importance hw threads are connected to
*/
void set_importance_hw (unsigned int number_of_threads, unsigned int * reconos_slots);
#endif

#ifndef ONLYPC
/**
  changes HW/SW Design. Use Functions sample_sw/hw, importance_sw/hw, resample_sw/hw
*/
void change_hw_sw_design(void);
#endif


/**
    extracts observation to corresponding particle

    @param p: particle, where the observation is needed
    @param o: obersation to corresponding particle
*/
void extract_observation(particle * p, observation * o);



/**
    get new measurement
*/
void get_new_measurement(void);



/**
   init reference data

   @param ref: pointer to reference data
*/
void init_reference_data(observation * ref);



/**
   user function called before resampling starts. No particles are processed in the filter steps.
   In this function the state can be estimated (using the particles p), a new reference data can
   be set (observations may be usefull) and the filter can be repartitioned using the 
   set_..._hw/sw functions.

   @param p: pointer to particle array
   @param o: pointer to observation array
   @param ref: pointer to reference data
   @param number: number of particles / observations
*/
void iteration_done(particle * p, observation * o, observation * ref, int number);



/**
  calculates likelihood between observation data and reference data (user functio)
  
  @param p: particle data   
  @param o: observation data
  @param reference_data: pointer to reference data 
  @return likelihood value
*/
int likelihood (particle * p, observation * o, observation * reference_data);


#ifdef ONLYPC
/**
   resamples all particles (PC VERSION)
*/
void resampling_pc(void);

#else
/**
   creates resample SW thread

   @param number_of_threads: number of hw threads for resampling thread
*/
void set_resample_sw (int number_of_threads);



/**
   creates resample HW thread

  @param number_of_threads: number of hw threads for resampling thread
  @param reconos_slots: reconos slots, where the resampling hw threads are connected to
*/
void set_resample_hw ( unsigned int number_of_threads, unsigned int *  reconos_slots  );
#endif



/**
 sorts particles regarding to their weight (descending)

 @return pointer of particle array
*/
particle * sort_particles_after_weight( void );



/**
   sets observations_input

   @param input: new observation_input address
*/
void set_observations_input(void * input);


//! end of particle filter
int end_of_particle_filter;


//! observation array
observation * observations;


//! reference data
observation * ref_data;


//! particle array
particle * particles;

//! index of every particle gives the replication factor
index_type * indexes;

//! number of particles
int N;

//! Resampling Function U
int * U;

//! number of particle blocks with size = SIZE
int number_of_blocks;

//! particle block size
int block_size;

//! input signal for observations
void * observations_input;

#endif
