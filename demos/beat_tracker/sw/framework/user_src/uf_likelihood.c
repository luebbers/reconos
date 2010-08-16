#include "../header/particle_filter.h"
#include "../../header/config.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>




/**
  calculates likelihood between observation data and reference data (user functio)
  
  @param p: particle data   
  @param o: observation data
  @param reference_data: pointer to reference data 
  @return likelihood value
*/
int likelihood (particle * p, observation * o, observation * reference_data){


	int result, i;
	// 1. check, if likelihood calculation is needed
	if (o->no_tracking_needed == TRUE)
	{
		// i. particle does not estimate beat in this interval, return last likelihood
		return o->old_likelihood;//p->likelihood;
		//return o->no_tracking_needed;
	}

	// 2. find maximum amplitude / frequency
	int max_amplitude = 0, current_amplitude, max_frequency = 0;
	int16 re, im;
	for (i=0; i<OBSERVATION_LENGTH; i++)
	{

		// i. calculate current amplitude
		re = (int16) o->fft[i].re;
		im = (int16) o->fft[i].im;
		current_amplitude = (re*re) + (im*im);
		//current_amplitude = sqrt(current_amplitude);

		// ii. max amplitude
		if (current_amplitude > max_amplitude)
		{

			max_amplitude = current_amplitude;
			// calculate max frequency
			max_frequency = i;// *(sample_rate/2);
			//max_frequency /= OBSERVATION_LENGTH;
		}
	}

	//printf("\nmax frequency: %d,\tmax amplitude: %d", max_frequency, max_amplitude);
	// 3. likelihood for 'beat' (low frequency > 100 => amplitude)
	//if (max_frequency > 100 && max_frequency < 5000)
	if (max_frequency > 0 && max_frequency < 29)
	{
		result = sqrt(max_amplitude);
		//result = max_amplitude;
	}
	else
	{
		result = 5;
	}
	// debug (TODO remove)
	//result = max_frequency;
	//result = o->no_tracking_needed;

	return result;

	// OLD VERSION
	/*p->successfull_beat = FALSE;

	// event was found
	if (event_found==TRUE)
	{

		// if particle is unsuccessfull for a long time => delete particle
		if ((event_position - p->last_beat) > (TIME_OUT * bytespersecond))
		{ 

			p->likelihood = 0;
			return 50;
		}

		// if measured beat is in correct interval
		if ((p->next_beat - (p->tempo/5) <= event_position) && (event_position <= (p->next_beat + ((2*p->tempo)/5))))
		{

			p->last_event_time	= event_position;
			p->successfull_beat	= TRUE;
			if (ABS(p->next_beat - event_position) <= (GOOD_ESTIMATION_TIME*bytespersecond))
			{

				// good estimation
				p->likelihood += FACTOR_FOUND_BEAT * event_salience;					
			} 
			else
			{

				// quite good estimation
				p->likelihood += FACTOR_ALMOST_FOUND_BEAT * event_salience;
			}			
		}
	} 

	// default
	return p->likelihood;	*/	
}



