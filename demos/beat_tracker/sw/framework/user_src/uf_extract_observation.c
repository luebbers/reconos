#include "../header/particle_filter.h"

#include <stdlib.h>
#include <stdio.h>
#ifndef ONLYPC
#include <xcache_l.h>
#endif

#include "../../header/config.h"
#include "../../header/fft.h"


/**
    extract observation to corresponding particle

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    @param p: particle, where the observation is needed
    @param o: observation to corresponding particle
*/
void extract_observation(particle * p, observation * o)
{

	// 0. only if first initial events/beats are found
	int i;
	if (initial_phase == TRUE)
	{
		o->no_tracking_needed = TRUE;
		return;
	}

	// 1. check, if estimated particle beat is in interval. If not, return
	if (!(p->next_beat < interval_max && interval_min <= p->next_beat))
	{
		// particle does not estimate beat in this interval
		o->no_tracking_needed = TRUE;
		return;
	}

	o->no_tracking_needed = FALSE;

	// 2. extract samples around estimated beat position (#bytes = 2*OBSERVATION_LENGTH)
	int16 * samples;
	volatile int * mem_s = malloc((OBSERVATION_LENGTH * sizeof(int16)) + 8); // 8 bytes extra
	volatile int * src_s = (volatile int*)(((int)mem_s / 8 + 1) * 8);
	samples = (int16*) src_s;
	int start_index;

	//printf("\n[extract observation]");

	// i. find start index
	start_index = (int)(p->next_beat % MEASUREMENT_BUFFER);
	start_index -= start_index%4;
	start_index = MAX(start_index, 0);
	start_index = MIN(start_index, (MEASUREMENT_BUFFER - (OBSERVATION_LENGTH*sizeof(int16))));

	// ii. extract samples
	memcpy(samples, &measurement[start_index], (OBSERVATION_LENGTH*sizeof(int16)));

	
	// iii. change Little Endian <-> Big Endian
	for (i=0; i<OBSERVATION_LENGTH; i++)
	{
		samples[i] = ntohl(samples[i]);
	}

	// 3. make short time fourier transformation for these samples
	//fft_analysis_new (samples, OBSERVATION_LENGTH, o, sample_rate);
	// this does only work for a singe thread solution
	// -> else: give hw-thread (TODO) block number, addresses of samples, particles, observations

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif   

	// (3) make fft
	// -a: send message: input address
	while (cyg_mbox_tryput( *mb_fft_start_handle, (void *) samples ) == 0)
	{
	}
	// -b: send message: output address
	while (cyg_mbox_tryput( *mb_fft_start_handle, (void *) o ) == 0)
	{
	}

	// -c: receive message: fft done
	while (cyg_mbox_get( *mb_fft_done_handle ) == 0)
	{
	}

	

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif 
	

}
