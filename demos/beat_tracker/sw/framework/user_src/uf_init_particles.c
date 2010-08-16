#include "../header/particle_filter.h"
#include "../../header/config.h"
#include <math.h>
#include <stdlib.h>




/**
   inits particle array according to information, which are stored in the information array.. 

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  @param information: pointer to information array containing initialization information
  @param size: size of information array

*/
void init_particles (int * information, int size){
   
	
	int k;

	// init measurement
	volatile int * mem_m = malloc((MEASUREMENT_BUFFER * sizeof( char)) + 8); // 8 bytes extra
	volatile int * src_m = (volatile int*)(((int)mem_m / 8 + 1) * 8);
	measurement = (char*) src_m;
	for (k=0; k<MEASUREMENT_BUFFER; k++) measurement[k] = (char)0;

	// init output
	output = (char*) malloc(MEASUREMENT_BUFFER * sizeof( char));
	for (k=0; k<MEASUREMENT_BUFFER; k++) output[k] = (char)0;

	// initial beats (positions)
	initial_beats = (volatile long int*)(malloc(sizeof(volatile long int)*NUM_INITIAL_BEATS));
	for (k=0; k<NUM_INITIAL_BEATS; k++)
	{
		initial_beats[k] = -1; 
	}
	initial_phase = TRUE;

	// event initialization
	event_found	= FALSE;
	event_salience	= 0;
	event_position	= 0;
	last_event_found = FALSE;
	last_best_particle_ind = 0;
	beat_counter = 0;
	low_volume_counter = 0;

	max_amplitude = 0;
	//last_beat = 0;
	interval_min = 0;
	interval_max = MEASUREMENT_BUFFER-1;
	end_of_particle_filter = FALSE;
	current_position = 0; // in audio file
	//best_particle_remember = 0;
	sample_rate = 44100;
	bytespersecond = 88200;

	int i;

	// init tempo
	for (i=0;         i<(N/4);     i++) particles[i].tempo = bytespersecond/2;
	for (i=(N/4);     i<((2*N)/4); i++) particles[i].tempo = bytespersecond/4;
	for (i=((2*N)/4); i<((3*N)/4); i++) particles[i].tempo = bytespersecond/3;
	for (i=((3*N)/4); i<N;         i++) particles[i].tempo = bytespersecond/5;

	// change the initial tempos a little bit
	int noise;
	for (i=1; i<N; i++){
		
		noise		 =  (rand() / (RAND_MAX / NOISE_FACTOR));
		noise		-= (NOISE_FACTOR/2);
		particles[i].tempo += noise;
	}

	// set observations input
	observations_input = (void *) measurement;


	// init other values
	for (i=0; i<N; i++){
		// start position
		particles[i].next_beat	= (rand() / (RAND_MAX / (bytespersecond/4)));
		particles[i].last_beat	= 0;
		// initial weight
		particles[i].w		= 100;
		// old likelihood value
		particles[i].likelihood	= 100;
		particles[i].interval_min = interval_min;
		particles[i].interval_max = interval_max;
		particles[i].initial_phase = initial_phase;		
		//particles[i].successfull_beat	= FALSE;
		//particles[i].last_event_time	= 0;

		// observations
		observations[i].no_tracking_needed = TRUE;
		observations[i].old_likelihood = 100;
		for (k=0; k<OBSERVATION_LENGTH;k++)
		{
			observations[i].fft[k].re = 0;
			observations[i].fft[k].im = 0;
		}
	}

   
}
