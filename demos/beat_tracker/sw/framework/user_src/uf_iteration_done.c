#include "../header/particle_filter.h"
#ifndef ONLYPC
#include <xcache_l.h>
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#endif
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "../header/timing.h"
#include "../../header/ethernet.h"
#include "../../header/fft.h"
#include "../../header/config.h"




/**
	returns best particle according to weight

	@param p: reference to particle array
	@param number: number of particles
	@return best particle index
*/
int get_best_particle(particle * p, int number)
{

	// exception handling
	if (p==NULL) return 0;
	
	int i;
	//particle * best_particle = p;
	int ind = 0;
	long int max_weight = 0;
	// find maximum over all
	for (i=0; i<N; i++)
	{

		// exchange best particle, if its weight is higher than currently best
		if (particles[i].w > max_weight)
		{

			//best_particle = &particles[i];
			ind = i;
			max_weight = particles[i].w;
		}	
		
		
	}
	
	// return best particle
	return ind;//best_particle;
}



/**
	checks if particle estimates a beat inside the current interval

	@param p: reference to particle
	@return: TRUE, if particle estimates a beat inside the current interval, else FALSE

*/
int particle_beat_inside_interval(particle * p)
{

	if ((interval_min <= p->next_beat) && (p->next_beat < interval_max))
	{
		return TRUE;
	}
	else
	{
		return FALSE;
	}
}



/**
	inserts a beat sound into the input audio sound

	@param array: byte array for inserting the noise sound
*/
void insert_concrete_event (char * array)
{

	int i, j, total_beat_length = 0;
	#define SIZE 21
	// define beat in 'size' segments with individual length and amplitude
	int beat_length_array[SIZE] = { 48,  48,  48,  48,  48,  48,  48,  48,  48,  48,  48, 
		48,  48,  48,  48,  48,  48,  48,  48,  48,  48};

	int16 beat_sound_array[SIZE] =  {  5,  20,   5, 124, -128,   5,  20,   5, 124, -128,   5,  
		20,   5, 124, -128,   5,  20,   5, 124, -128,  5};

	// calculate total beat length
	for (i=0; i<SIZE; i++)
	{
		beat_length_array[i] /= 6;
		total_beat_length += 2*beat_length_array[i];
	}
	
	// calculate position to insert beat sound (this is 'total_beat_length' bytes long)
	// beat position
	int position = (int)(event_position - interval_min);
	if (position%2==1)
	{
		position--;
	}
	position = MAX(position, 0);
	position = MIN(position,(MEASUREMENT_BUFFER-total_beat_length));

	for (i=0; i<SIZE; i++)
	{

			for(j=0; j<beat_length_array[i]; j++)
			{
				
				array[position] = (signed char)0;
				position++;
				array[position] = (signed char)beat_sound_array[i];
				position++;
			}		
	}
	last_beat = current_position + position;
	//printf("\n(%d)################# Do an Event at position: %ld #####################",
	//	beat_counter ,(interval_min + position - total_beat_length));
}





/**
	inserts a beat sound into the input audio sound

	@param p: particle which needs to be inserted
	@param array: byte array containing the audio sound
*/
void insert_beat (particle * p, char * array)
{

	int i, j, total_beat_length = 0;
	#define SIZE 21

	// define beat in 'size' segments with individual length and amplitude
	int beat_length_array[SIZE] = { 48,  48,  48,  48,  48,  48,  48,  48,  48,  48,  48, 
		48,  48,  48,  48,  48,  48,  48,  48,  48,  48};

	int16 beat_sound_array[SIZE] =  {  5,  20,   5, 124, -128,   5,  20,   5, 124, -128,   5,  
		20,   5, 124, -128,   5,  20,   5, 124, -128,  5};

	// calculate total beat length
	for (i=0; i<SIZE; i++)
	{
		beat_length_array[i] /= 6;
		total_beat_length += 2*beat_length_array[i];
	}
	
	// calculate position to insert beat sound (this is 'total_beat_length' bytes long)
	// beat position
	long int current_beat_position = p->next_beat;
	//if (p->successfull_beat) current_beat_position = event_position;
	int position = MIN((int)(current_beat_position - interval_min), 
		//(interval_max - (MEASUREMENT_BUFFER/2) - 1 - total_beat_length - interval_min));
		((MEASUREMENT_BUFFER - 1) - total_beat_length));
	if (position%2==1)
	{
		position--;
	}
	position = MAX(position, 0);
	position = MIN(position,(MEASUREMENT_BUFFER-total_beat_length));
	// try
	//position = 0;
	//position = MIN(position,((MEASUREMENT_BUFFER/2)-total_beat_length));

	int beat_difference = current_position + position - last_beat;
	if (beat_difference > ((4*p->tempo)/5))
	{
		//printf("\nposition = %d", position);

		for (i=0; i<SIZE; i++)
		{

			for(j=0; j<beat_length_array[i]; j++)
			{			
				array[position] = (signed char)0;
				position++;
				array[position] = (signed char)beat_sound_array[i];
				position++;
			}		
		}
		last_beat = current_position + position;
		//printf("\n(%d) ################# Do a Beat at position: %ld #####################",
		//	beat_counter, (interval_min + position - total_beat_length));
	}
}






/**
	inserts a beat sound into the input audio sound

	@param array: byte array containing the audio sound
*/
void insert_event (char * array)
	{

	int i, j, total_beat_length = 0;
	#define SIZE3 21
	// define beat in 'size' segments with individual length and amplitude
	int beat_length_array[SIZE3] = { 48,  48,  48,  48,  48,  48,  48,  48,  48,  48,  48,  48,  
		48,  48,  48,  48,  48,  48,  48,  48,  48};
	int16 beat_sound_array[SIZE3] =  {  5,  20,   5, 124, -128,   5,  20,   5, 124, -128,   5,  20,   
		5, 124, -128,   5,  20,   5, 124, -128,  5};
	for (i=0; i<SIZE3; i++)
	{
		beat_length_array[i] /= 6;
	}
	for (i=0; i<SIZE3; i++)
	{
		total_beat_length += 2*beat_length_array[i];
	}
	
	int position = 0; 

	for (i=0; i<SIZE3; i++)
	{

		for(j=0; j<beat_length_array[i]; j++)
		{
			
			array[position] = (signed char)0;
			position++;
			array[position] = (signed char)beat_sound_array[i];
			position++;
		}		
	}
	//printf("\n!!!!!!!!!!!!!!!!!! Measured Event at position: %ld !!!!!!!!!!!!!!!!!!!!!!", 
	//	(interval_min + position - total_beat_length));
	last_beat = current_position + position;
}


/**
	inserts a test sound into the input audio sound

	@param p: particle which needs to be inserted
*/

void insert_test_sound (char * array)
	{

	int i, j, total_beat_length = 0;
	#define SIZE2 17
	// define beat in 'size' segments with individual length and amplitude
	int beat_length_array[SIZE2] = { 32,  32,  32,  32,  64,  32,  32,  32,  32,  32,  32,  32,  64,  32,  32,  32,  32};
	int beat_sound_array[SIZE2] =  {  0,  30,  60,  90, 127,  90,  60,  30,   0, 220, 190, 160, 128, 160, 190, 220,   0};

	// calculate total beat length
	for (i=0; i<SIZE2; i++)
	{
		total_beat_length += 2*beat_length_array[i];
	}
	
	int position = 0;
	//if (total_beat_length > MEASUREMENT_BUFFER) printf("\n////////////////////////////////////////////////////");

	int16 number;
	for (i=0; i<SIZE2; i++)
	{

			for(j=0; j<beat_length_array[i]; j++){

				array[position] = (char) 0; // lower bit
				position++;
				array[position] = (char) beat_sound_array[i]; // higher bit
				position++;
				memcpy(&number, &array[position-2],   2);
				//printf("\nleft byte [low](%d) + right byte [high] (%d) => %d", (int) array[position-2],
					//(int) array[position-1], number);			
			}		
	}
	//printf("\n*********************# Do a test sound at position: %d **********************", 
	//	(interval_min + position - total_beat_length));
}



/**
   user function called before resampling starts. No particles are processed in the filter steps.
   In this function the state can be estimated (using the particles p), a new reference data can
   be set (observations may be usefull) and the filter can be repartitioned using the 
   set_..._hw/sw functions.

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   @param p: pointer to particle array
   @param o: pointer to observation array
   @param ref: pointer to reference data
   @param number: number of particles / observations
*/
void iteration_done(particle * p, observation * o, observation * ref, int number)
{

	int i;

	// (1) estimate best particle
	int best_particle_ind = get_best_particle(p, number);
	particle * best_particle = &particles[best_particle_ind];
	//best_particle = &particles[0];
	/*printf("\nparticles[best].w = %d", particles[best_particle_ind].w);
	printf("\nparticles[best].likelihood = %d", particles[best_particle_ind].likelihood);
	printf("\nparticles[best].next_beat = %lu", particles[best_particle_ind].next_beat);
	printf("\nparticles[best].last_beat = %lu", particles[best_particle_ind].last_beat);
	printf("\nparticles[best].tempo = %u", particles[best_particle_ind].tempo);
	printf("\nparticles[best].initial_phase = %u", particles[best_particle_ind].initial_phase);
	printf("\nparticles[best].interval_min = %lu", particles[best_particle_ind].interval_min);
	printf("\nparticles[best].interval_max = %lu", particles[best_particle_ind].interval_max);*/
	
	// calculate maximal amplitude in buffer
	int16 max_value = 0, sample_value = 0;
	//printf("\n[iteration done]");

	for (i=0; i<MEASUREMENT_BUFFER/2; i++)
	{
	
		// calculate maximal sound value
		memcpy(&sample_value, &output[2*i], 2);
		sample_value = ABS(ntohl(sample_value));
		if (sample_value > max_value) max_value = sample_value;					
	}

	// initial phase
	if (initial_phase==TRUE)
	{
		for(i=0;i<NUM_INITIAL_BEATS;i++)
		{
			if (interval_min<=initial_beats[i] &&  initial_beats[i]<=interval_max && event_found==TRUE)
			{
				//printf("\n%d. measured beat", (i+1));
				beat_counter++;
				insert_concrete_event(output);
			}
		}
		// end initial phase, if first 'NUM_INITIAL_BEATS' are found
		if (initial_beats[NUM_INITIAL_BEATS-1] > 0)
		{
			initial_phase = FALSE;
			//printf("\n[end] of initial phase (initial_beat[%d] = %ld)", 
			//	(NUM_INITIAL_BEATS-1), initial_beats[NUM_INITIAL_BEATS-1]);
		}
	} else
	{
		if (particle_beat_inside_interval(best_particle)==TRUE && max_value>MIN_SOUND_AMPLITUDE)
		{
			//printf("\ninsert best beat");
			beat_counter++;
			low_volume_counter = 0;
			insert_beat(best_particle, output);
			last_best_particle_ind = best_particle_ind;
		} else
		if (particle_beat_inside_interval(&particles[last_best_particle_ind])==TRUE
			&& max_amplitude>MIN_SOUND_AMPLITUDE)
		{
			//printf("\ninsert last best beat");
			beat_counter++;
			low_volume_counter = 0;
			insert_beat(&particles[last_best_particle_ind], output);		
		} /*else
		if (particle_beat_inside_interval(best_particle)==TRUE && max_amplitude<=MIN_SOUND_AMPLITUDE)
		{
			// too low volume: re-initialize
			low_volume_counter++;
			//if (low_volume_counter)
			initial_phase = TRUE;
			for(i=0;i<NUM_INITIAL_BEATS;i++) initial_beats[i] = 0;
		}*/
	}

	// store old likelihood values
	for(i=0;i<N;i++)
	{
		particles[i].likelihood		= particles[i].w;
		observations[i].old_likelihood	= particles[i].w;
	}

	/*printf("\nparticles[0].w = %d", particles[0].w);
	printf("\nparticles[0].likelihood = %d", particles[0].likelihood);
	printf("\nparticles[0].next_beat = %lu", particles[0].next_beat);
	printf("\nparticles[0].last_beat = %lu", particles[0].last_beat);
	printf("\nparticles[0].tempo = %u", particles[0].tempo);
	printf("\nparticles[0].initial_phase = %u", particles[0].initial_phase);
	printf("\nparticles[0].interval_min = %lu", particles[0].interval_min);
	printf("\nparticles[0].interval_max = %lu", particles[0].interval_max);*/
	/*// (2) check if beat occurs in current particle. If so, edit soundfile for beat
	if (first_beat_pos > 0 && first_beat_pos >= interval_min && event_found == TRUE)
	{
		
		// 1st measured beat
		printf("\n1st measured beat");
		beat_counter++;
		insert_concrete_event(output);
	} else
	if (second_beat_pos > 0 && second_beat_pos >= interval_min && event_found == TRUE)
	{
		
		// 2nd measured beat
		printf("\n2nd measured beat");
		beat_counter++;
		insert_concrete_event(output);
	} else

	if (particle_beat_inside_interval(best_particle)==TRUE && max_value>MIN_SOUND_AMPLITUDE)
	{

		//if (best_particle->successfull_beat == TRUE)
		//	printf("\n######################## insert successfull beat #############################");
		beat_counter++;
		insert_beat(best_particle, output);
		//event_position = best_particle->next_beat;
		//insert_concrete_event(output);
		last_best_particle_ind = best_particle_ind;
		
	} else
	if (particle_beat_inside_interval(&particles[last_best_particle_ind])==TRUE && max_amplitude>MIN_SOUND_AMPLITUDE)
	{

		//if (best_particle->successfull_beat == TRUE)
		//	printf("\n######################## insert successfull beat #############################");
		beat_counter++;
		insert_beat(&particles[last_best_particle_ind], output);
		//event_position = particles[last_best_particle_ind].next_beat;
		//insert_concrete_event(output);
		
	}*/
	/*if (event_found == TRUE)
	{
		insert_concrete_event(output);
	}*/

	// (3) send sound frame
	//memcpy(output, measurement, MEASUREMENT_BUFFER);

	#ifndef STORE_AUDIO
		send_sound_frame(output, MEASUREMENT_BUFFER);
	#endif

	//send_sound_frame(measurement, (MEASUREMENT_BUFFER/2));
	//for (i=0; i<MEASUREMENT_BUFFER/2; i++){
	//	fwrite(&measurement[i],1,(BUFFSIZE-1),outputstream);
	//}

	// set interval times
	current_position += MEASUREMENT_BUFFER;
	interval_min = current_position;
	interval_max = interval_min + MEASUREMENT_BUFFER;
	for (i=0; i<N; i++)
	{
		particles[i].interval_min =  (long unsigned int)interval_min;
		particles[i].interval_max = (long unsigned int)interval_max;
		particles[i].initial_phase = (unsigned int) initial_phase;
		/*if (particles[i].next_beat < interval_min - MEASUREMENT_BUFFER)
		{
			particles[i].next_beat = 200000;
			particles[i].last_beat = 150000;	
			particles[i].tempo = 10000;
		}*/
	}
	/*printf("\nnew: particles[0].interval_min = %lu", particles[0].interval_min);
	printf("\nnew: particles[0].next_beat = %lu", particles[0].next_beat);
	printf("\nnew: particles[0].initial_phase = %u", particles[0].initial_phase);*/
	//printf("\nnew: particles[0].next_beat = %lu", particles[0].next_beat);
	//printf("\nnew: particles[0].last_beat = %lu", particles[0].last_beat);
	//printf("\nnew: particles[0].tempo = %u", particles[0].tempo);	
	//printf("\ncurrent_interval min: %d", interval_min); 

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif
	

}
