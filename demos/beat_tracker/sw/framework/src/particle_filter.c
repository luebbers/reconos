#include "../header/particle_filter.h"
#include <stdlib.h>
#include <stdio.h>

#define DEBUG 1

/**
creates the particle array, resources and communication threads

@param number_of_particles: number of particles
@param particle_block_size: size of a particle block
*/
void create_particle_filter (unsigned int number_of_particles, unsigned int particle_block_size){

   int i;

   // set variables
   N = number_of_particles;
   block_size = particle_block_size;
 
   // particles
   volatile int * mem_p = malloc((N * sizeof(particle)) + 8 + 256); // 8 bytes extra
   volatile int * src_p = (volatile int*)(((int)mem_p / 8 + 1) * 8);

   // indexes
   volatile int * mem_i = malloc((N * sizeof(particle)) + 8 + 256); // 8 bytes extra
   volatile int * src_i = (volatile int*)(((int)mem_i / 8 + 1) * 8);

   // observations
   volatile int * mem_o = malloc((N * sizeof(observation)) + 8 + 256 ); // 8 bytes extra
   volatile int * src_o = (volatile int*)(((int)mem_o / 8 + 1) * 8);

   // reference data
   volatile int * mem_r = malloc(sizeof(observation) + 8 + 256 ); // 8 bytes extra
   volatile int * src_r = (volatile int*)(((int)mem_r / 8 + 1) * 8);


   // Resampling function U
   volatile int * mem_U; 
   volatile int * src_U;

   number_of_blocks = N / block_size;

   if (N % block_size > 0) number_of_blocks++;

   mem_U = (int*) malloc((number_of_blocks *(sizeof(int))) + 8 + 256 ); // 8 bytes extra
   src_U =  (volatile int*)(((int)mem_U / 8 + 1) * 8);
   
   particles    = (particle *   ) src_p;
   indexes      = (index_type * ) src_i;
   ref_data     = (observation *) src_r;
   observations = (observation *) src_o;
   U            = (int *        ) src_U;
   

   /*
   particles    = (particle *   ) 0x80000000;
   observations = (observation *) 0x80002000;
   indexes      = (index_type * ) 0x8000D000;
   ref_data     = (reference_data_type *) 0x8000E000;
   U            = (int *        ) 0x8000F000;
   

   number_of_blocks = N / block_size;
   if (N % block_size > 0) number_of_blocks++;
   */
   
   #ifndef ONLYPC
   // create message box variables
   mb_sampling        = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   mb_importance   = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   mb_resampling      = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   mb_sampling_done   = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   mb_importance_done = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   mb_resampling_done = (cyg_mbox *) malloc (sizeof(cyg_mbox));

   // create message box handles
   mb_sampling_handle      = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
   mb_importance_handle = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));;
   mb_resampling_handle    = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
   mb_sampling_done_handle   = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
   mb_importance_done_handle = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
   mb_resampling_done_handle = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));

   // create message boxes
   cyg_mbox_create( mb_sampling_handle,        mb_sampling);
   cyg_mbox_create( mb_importance_handle,      mb_importance );
   cyg_mbox_create( mb_resampling_handle,      mb_resampling );
   cyg_mbox_create( mb_sampling_done_handle,   mb_sampling_done );
   cyg_mbox_create( mb_importance_done_handle, mb_importance_done );
   cyg_mbox_create( mb_resampling_done_handle, mb_resampling_done ); 

   // create message box variable for time measurement
   hw_mb_sampling_measurement      = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   hw_mb_observation_measurement   = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   hw_mb_importance_measurement    = (cyg_mbox *) malloc (sizeof(cyg_mbox));
   hw_mb_resampling_measurement    = (cyg_mbox *) malloc (sizeof(cyg_mbox));

   // create message box handles for time measurements 
   hw_mb_sampling_measurement_handle      = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
   hw_mb_observation_measurement_handle   = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
   hw_mb_importance_measurement_handle    = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
   hw_mb_resampling_measurement_handle    = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));

   // create message boxes for time measurements
   cyg_mbox_create( hw_mb_sampling_measurement_handle,    hw_mb_sampling_measurement);
   cyg_mbox_create( hw_mb_observation_measurement_handle, hw_mb_observation_measurement);
   cyg_mbox_create( hw_mb_importance_measurement_handle,  hw_mb_importance_measurement);
   cyg_mbox_create( hw_mb_resampling_measurement_handle,  hw_mb_resampling_measurement);

   // create pre threads
   create_preSampling_thread();
   create_preResampling_thread();
   #endif

   // set inital indexes
   for (i=0; i<N; i++)
   {

       indexes[i].index = i;
       indexes[i].replication = 1;   
   }
}



/**
   sets observations_input

   @param input: new observation_input address
*/
void set_observations_input(void * input){


	observations_input = input;
}



/**
   init reference data

   @param ref: pointer to reference data
*/
void init_reference_data(observation * ref){


	memcpy(ref_data, ref, (sizeof(observation))); 

}


/**
	prints particle to screen (debug)

	@param p: particle
	@param i: index
*/
void print_particle(particle * p, int i){

	/*printf("\n\nparticle[%d].next_beat \t\t= %d", i, p->next_beat);
	printf("\n\nparticle[%d].last_beat \t\t= %d", i, p->last_beat);
	printf("\nparticle[%d].tempo \t= %d", i, p->tempo);
	printf("\nparticle[%d].w \t\t= %d", i, p->w);
	printf("\nparticle[%d].likelihood = %d", i, p->likelihood);*/
}


/**
   starts particle filter by getting all particles sampled.

*/
void start_particle_filter(){

   int message, message_delivered, done;
  
   //printf("\nStarte Particle Filter\n");

   // get first measurement
   get_new_measurement();

   #ifndef ONLYPC
   // send messages to sampling hw/sw message box
   for (message=1; message<=number_of_blocks; message++){

           
	   message_delivered = FALSE;
	   while (message_delivered == FALSE){
      
	      done = cyg_mbox_tryput( mb_sampling_handle[0], ( void * ) message );

	      if (done > 0){
	          //printf("\n[Sampling Switch] Nachricht %d an Sampling weitergeleitet", message);
                  message_delivered = TRUE;   
             }
	      
	  }
      }
    #else
	int i;
	int iteration = 0;
	
	while (42){

		iteration++;
		//printf("\n--------------------------------");	
		//printf("\n--  I T E R A T I O N   %d  --", iteration);	
		//printf("\n--------------------------------");		

		// (1) [SAMPLING]: sample particles
		for (i=0; i<N; i++) prediction(&particles[i]);
		//printf("\n(1) sampling");

		// (2) receive new measurement
		get_new_measurement();
		if (end_of_particle_filter==TRUE) return;
		//printf("\n(2) get new measurement");

		// (3) observation:
		for (i=0; i<N; i++) extract_observation(&particles[i], &observations[i]);
		//printf("\n(3) observation");

		// (4) [IMPORTANCE]: weight particle according to likelihood
		for (i=0; i<N; i++) particles[i].w = likelihood (&particles[i], &observations[i], ref_data);
		//printf("\n(4) importance");

		// (5) iteration done: estimate, output, etc.
		iteration_done(particles, observations, ref_data, N);
		//printf("\n(5) iteration done");

		if (iteration%1000 == 999){
		     // (6) [RESAMPLING]: resample particle according to weights
		     resampling_pc();
		     //printf("\n(6) resampling");

		     // (7) presampling
		     prepare_sampling();
		     //printf("\n(7) prepare sampling\n");
		}
	}


    #endif

   // printf("\nParticle Filter gestartet\n");

   

}




/**
   define compare function for particles after their weights (needed for qsort)

   return 0, if both particle weights are egual, 1, if first particle weight is higher, -1, else
*/
int compare (const void *Arg1, const void *Arg2){
        
    particle * i;
    particle * j;
    
    i = (particle *) Arg1; 
    j = (particle *) Arg2;
    
    if (i->w == j->w) return  0;
    else if (i->w > j->w) return -1;
    else return  1;

}


/**
 sorts particles regarding to their weight (descending)

 @return pointer of particle array
*/
particle * sort_particles_after_weight(){

    // use qsort
    qsort(particles, N, sizeof(particle), &compare);

#ifdef DEBUG

    printf("\nmax. likelihood: %d\t min. likelihood: %d",(int)particles[0].w, (int)particles[N-1].w);

#endif

    // return array
    return particles;
}

