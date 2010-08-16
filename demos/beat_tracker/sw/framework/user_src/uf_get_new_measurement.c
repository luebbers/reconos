#include "../header/particle_filter.h"
#ifndef ONLYPC
#include <xcache_l.h>
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#endif
#include <stdlib.h>
#include <stdio.h>



#include "../../header/config.h"
#include "../../header/ethernet.h"
#include "../../header/fft.h"

#define _USE_MATH_DEFINES
#include <math.h>



/**
    get new measurement
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

*/
void get_new_measurement(void){

		int i, j, k, l;
		int16 re, im;
		
		//unsigned char byte_buffer[1];
		//int counter = 0;
		// fill measurement buffer with next bytes of audio input file

		// (a) shift old values
		//memcpy(&measurement[MEASUREMENT_BUFFER/2], &measurement[0], (MEASUREMENT_BUFFER/2));
		// (b) get new sound data
		//receive_sound_frame(measurement, (MEASUREMENT_BUFFER/2));		
		
		#ifndef STORE_AUDIO
			receive_sound_frame(measurement, MEASUREMENT_BUFFER);
			//printf("\nload next frame");
		#else
			memcpy(measurement, &sound_frames[current_audio_frame*MEASUREMENT_BUFFER], MEASUREMENT_BUFFER);
			current_audio_frame++;
			if (MAX_FRAMES <= current_audio_frame)
			{
				//printf("\nload %d frames", MAX_FRAMES);
				current_audio_frame = 0;
				// load first frames
				for(i=0; i<MAX_FRAMES-1; i++)
				{
					receive_sound_frame(&sound_frames[i*MEASUREMENT_BUFFER],
						MEASUREMENT_BUFFER);		
 				}
			}
		#endif
		memcpy(output, measurement, MEASUREMENT_BUFFER);

		event_found = FALSE;
		// spectral center (sc)
		//complex_number sc, sc_old;
		//sc_old.re = 0; sc_old.im = 0; sc.re = 0; sc.im = 0;

		// find first two beats
		//printf("\ninterval min: %ld ", interval_min);
		//for(i=0;i<NUM_INITIAL_BEATS;i++) printf("\n%d. initial beat: %ld", i, initial_beats[i]);
		if (initial_phase == TRUE )
		{
			//printf("\ninitial phase");
			int16 samples[OBSERVATION_LENGTH];
			//observation obs;
			complex_number obs[OBSERVATION_LENGTH];

			int max_amplitude = 0, max_frequency = 0, current_amplitude;
			int max_amplitude_total = 0, max_frequency_total = 0;
			int16 max_sample_value = 0, max_sample_value_total = 0;
			long int position = 0;

			event_found = FALSE;

			// check current measurement frame
			for (i=0; i<MEASUREMENT_BUFFER/(OBSERVATION_LENGTH); i++)
			{

				memcpy(samples, &measurement[i*OBSERVATION_LENGTH], (OBSERVATION_LENGTH*sizeof(int16)));

				//change Little Endian <-> Big Endian
				max_sample_value = 0;
				for (j=0; j<OBSERVATION_LENGTH; j++)
				{
					samples[j] = ntohl(samples[j]);
					if (ABS(samples[j]) > max_sample_value)
					{
						max_sample_value = ABS(samples[j]);
					}
				}

				for (j=0; j<OBSERVATION_LENGTH; j++)
				{
					obs[j].re = 111;
					obs[j].im = 222;				
				}

				#ifdef USE_CACHE
					XCache_EnableDCache( 0xF0000000 );
				#endif 

				// fft
				//fft_analysis_try (samples, OBSERVATION_LENGTH, obs, sample_rate);
				// -a: send message: sample address (input)
				while (cyg_mbox_tryput( *mb_fft_start_handle, (void *) samples ) == 0)
				{
				}

				// -b: send message: observations address (output)
				while (cyg_mbox_tryput( *mb_fft_start_handle, (void *) obs ) == 0)
				{
				}

				// -c: receive message (fft done)
				while (cyg_mbox_get( *mb_fft_done_handle ) == 0)
				{
				}

				#ifdef USE_CACHE
					XCache_EnableDCache( 0xF0000000 );
				#endif

				
				// find spectral center (sc)
				/*sc.re = 32000; sc.im = 32000; 
				for (j=1;j<((OBSERVATION_LENGTH/2)-1);j++)
				{
				}*/

 

				// max amplitude, frequency
				//for (j=0; j<OBSERVATION_LENGTH; j++)
				/*printf("\n\nSAMPLES\n");
				for (j=0; j<OBSERVATION_LENGTH; j++)
				{
					printf("\n%d", samples[j]);
				}

				printf("\n\nFFT RESULTS\n");*/
				for (j=0; j<OBSERVATION_LENGTH; j++)
				{

					
					// i. calculate current amplitude
					re = (int16) obs[j].re;
					im = (int16) obs[j].im;
					current_amplitude = (re*re) + (im*im);
					current_amplitude = sqrt(current_amplitude);

					// ii. max amplitude
					if (current_amplitude > max_amplitude)
					{

						max_amplitude = current_amplitude;
						// calculate max frequency
						max_frequency = j*(sample_rate/2);
						max_frequency /= (OBSERVATION_LENGTH);
					}
					//printf("\n%d", current_amplitude);
				}

				//printf("\nmax frequency %d, \tmax amplitude: %d", max_frequency, max_amplitude);

				// likelihood for 'beat' (frequency > 100 => amplitude)
				if (max_frequency>100 && max_frequency<5000 && max_amplitude_total<max_amplitude)//<5000
				{
					max_amplitude_total = max_amplitude;
					max_frequency_total = max_frequency;
					max_sample_value_total = max_sample_value;
					position = interval_min + i*OBSERVATION_LENGTH - (OBSERVATION_LENGTH/2);
				}
			}

			//printf("\n!!!!!!!max frequency %d, \tmax amplitude: %d", max_frequency_total, max_amplitude_total);

			// analyse if event was found
			if (max_frequency_total>100 && max_amplitude_total>50 && 
				max_frequency_total<5000 && max_sample_value_total>5000){

				//printf("\nEVENT FOUND at position %ld", position);
				event_found = TRUE;
				event_position = position;
				event_salience = max_amplitude_total;
			}

			// init particle filter if needed;
			
			if (event_found == TRUE) // new beat
			{

				int beat_ind = 0;
				while (initial_beats[beat_ind]>0 && beat_ind<(NUM_INITIAL_BEATS-1))
				{
					beat_ind++;
				}	
				
				// 'beat_ind' is the current initial beat
				initial_beats[beat_ind] = event_position;
				if ((beat_ind>0 && initial_beats[beat_ind] - initial_beats[beat_ind-1] < bytespersecond/5))
				{
					event_found = FALSE;
					initial_beats[beat_ind] = 0;
					return;
				}
				//printf("\n%d. beat at position: %ld", beat_ind, event_position);

				// if last initial beat found: extract hypothesises
				if (beat_ind == (NUM_INITIAL_BEATS-1))
				{					

					// if last initial beat => initialize particles with extracted hypothesis
					// number of possibilities to create hypothesis for beats 
					// mathematical reasoning to calcualate the number of possibilities
					int num_hypothesis = (NUM_INITIAL_BEATS*NUM_INITIAL_BEATS)
						- (((NUM_INITIAL_BEATS+1)*NUM_INITIAL_BEATS)/2);

					// generic algorithm to calcualte all possibilities for tempo hypothesises
					// i: current initial beat
					// j: other initial beats before current initial beat
					// k: current hypothesis [0,...,num_hypothesis-1]
					// l: current particle position: (N/num_hypothesis) particles per hypothesis
					k = 0;
					for (i=NUM_INITIAL_BEATS-1; i>=0;i--)
					{
						
						for (j=i-1; j>=0;j--)
						{

							for(l=(k*N)/num_hypothesis; l<MIN((((k+1)*N)/num_hypothesis),N);l++)
							{
								// init particle according to hypothesis
								particles[l].tempo = (int)initial_beats[i] 
									- initial_beats[j];
								if((5*particles[l].tempo)<bytespersecond)
								{
									//printf("\ndifference short, set to default value");
									particles[l].tempo = bytespersecond/5;
								}
								particles[l].last_beat = initial_beats[i];
								particles[l].next_beat = initial_beats[i] 
									+ particles[l].tempo;
								particles[l].w		= 100;
								particles[l].likelihood	= 100;
							}
							//printf("\n%d. hypothesis: tempo = %d,\tlast beat: %ld", 
							//	(k+1),(int)(initial_beats[i]-initial_beats[j]),
							//	initial_beats[i]);
							k++;
						}
					}		
				}

				/*if (first_beat_pos <= 0)
				{
				
					first_beat_pos = event_position;
					printf("\n1st beat at position: %ld", first_beat_pos);

				}
				else
				{
				
					if (second_beat_pos <= 0 && (event_position - first_beat_pos > (bytespersecond/5)))
					{
	
						second_beat_pos = event_position;
						printf("\n2nd beat at position: %ld (init particles, tempo: %ld)", 
							second_beat_pos, (second_beat_pos -
							first_beat_pos));
						
						// init particles
						for (i=0; i<N; i++)
						{

							particles[i].tempo = second_beat_pos - first_beat_pos;	
							particles[i].last_beat = second_beat_pos;
							particles[i].next_beat = second_beat_pos 
									+ particles[i].tempo;
							particles[i].last_event_time	= second_beat_pos;
							particles[i].w			= PF_GRANULARITY/N;
							particles[i].likelihood		= 100;
						}
					}
				}*/
				//last_event_found = TRUE;
			}
			/*else
			{
				last_event_found = FALSE;
			}*/

		}

		//int16 sample_value = 0;
	
		// make short-time Fourier transformation for the incoming sound data
		/*fft_analysis (measurement, (MEASUREMENT_BUFFER/2), fft_window, sample_rate);
		// real, and imaginary component

		// debug: find max frequency
		double amplitude_max = 0; int max_freq = 0;
		for(i = 0; i < (sample_rate/(2*FREQUENCY_HOPPING)); i++){

			if (amplitude_max < fft_window[i]){

				max_freq  = i*FREQUENCY_HOPPING;
				amplitude_max = fft_window[i];
			}
		}

		event_found = FALSE;
		// extract events
		if (max_freq > 100 && amplitude_max > 60){
			//if (last_event_found == FALSE){

				printf("\nevent found!!!!!!!!!!!");
				// event found
				event_found = TRUE;
				event_position = interval_min + (MEASUREMENT_BUFFER/4);
				event_salience = amplitude_max;
			//}
		} 
		else
		{
			
			last_event_found = FALSE;
		}


		// init particle filter if needed;
		if (first_beat_pos <= 0 || second_beat_pos <= 0 ){ // init still needed

			
			if (event_found == TRUE && last_event_found == FALSE){ // new beat

				if (first_beat_pos <= 0){
				
					first_beat_pos = event_position;
					printf("\n1st beat at position: %d", (int)(first_beat_pos/10000));

				} else {
				
					if (second_beat_pos <= 0){
	
						second_beat_pos = event_position;
						printf("\n2nd beat at position: %d (init particles, tempo: %d)", 
							(int)(second_beat_pos/10000), (int)((second_beat_pos -
							first_beat_pos)/10000));
						// init particles
						for (i=0; i<N; i++){

							particles[i].tempo		= second_beat_pos - first_beat_pos;
							particles[i].last_beat 		= second_beat_pos;
							particles[i].next_beat 		= second_beat_pos 
									+ particles[i].tempo;
							particles[i].last_event_time	= second_beat_pos;
							particles[i].w			= PF_GRANULARITY/N;
							particles[i].likelihood		= 100;
						}
					}
				}
			}
		}

		if (event_found == TRUE) {last_event_found = TRUE; }
		*/

 		// calculate 'energy' in buffer
		//int16 output_value = max_ind;
		//for(i = 0; i < MEASUREMENT_BUFFER/2; i++) memcpy(&output[2*i], &output_value, 2);

		/*
		// debug: print sample values to screen
		for(i = 0; i < MEASUREMENT_BUFFER/2; i++){
			
			double result = fft_window[i];
			memcpy(&sample_value, &measurement[2*i], 2);
			if (interval_min > bytespersecond && interval_min < bytespersecond+1000)
				printf("\n%f", 1.0*sample_value);
			//if (i>0) result *= 8;
			if (result > 32767){printf("\nFFT value to high ( < 32768), but it is %f", result); result = 32767;}
			if (result<-32768){printf("\nFFT value to high ( >= -32768), but it is %f", result); result=-32768;}
			sample_value = (signed short int)result;
			//printf("\n sample value: %d", sample_value);
			//memcpy(&measurement[2*i], &sample_value, 2);			
			//printf("\nA[%d] = %d", i, sample_value]);
		}*/


		// TRY START: CHANGE CHANGE CHANGE
		/*event_found = FALSE;
		long int energy = 0;
		char current_sample[2];

		// calculate 'energy' in buffer
		int16 max_value = 0;

		for (i=0; i<MEASUREMENT_BUFFER/2; i++){
	
			current_sample[1] = measurement[(2*i) + 1]; 
			current_sample[0] = measurement[(i*2)];
			memcpy(&sample_value, current_sample, 2);

			if (ABS(sample_value) > max_value) max_value = ABS(sample_value);

			energy += (sample_value * sample_value);			
		}

		max_amplitude = max_value;

		// adjust energy change
		long int value = sqrt(sqrt(energy-last_energy));// / 2;
                //long int value = (energy-last_energy)/80000;
		sample_value = value;

		if (value > 32767){

			sample_value = 32768;
			printf("\nenergy change too high (%d > 32767)", value);
		} else if (value < -32768) {

			sample_value = -32768;
			printf("\nenergy change too high (%d < -32768)", value);
		}

		if (max_value < 15000 || sample_value == 0) {

			sample_value = 0;
			last_event_found = FALSE;
			//energy = 0;
		} else {

			if (last_event_found == FALSE){

				event_found = TRUE;
				last_event_found = TRUE;
				event_position = interval_min + (MEASUREMENT_BUFFER/2);
				event_salience = ABS(sample_value);
			
				//printf("\nEvent found: position = %d, salience = %d", event_position, event_salience);
                         }
			
		}

		last_energy = energy;*/

		// debug: write energy into file
		/*for (i=0; i<MEASUREMENT_BUFFER/2; i++){
		
			memcpy(current_sample, &sample_value, 2);
			measurement[(2*i) + 1] = current_sample[0]; 
			measurement[(i*2)] = current_sample[1];
		}*/

		// TRY TRY TRY
		//fft_calc(measurement, MEASUREMENT_BUFFER/2);

		// TRY END: CHANGE CHANGE CHANGE

		/*
		char current_sample[2];
		int16 sample_value;
		long int left_max = 0, right_max=0; int s;
		event_found = FALSE;

		// calcualte left sum
		for (s=0; s<MEASUREMENT_BUFFER/4; s++){
		
			current_sample[0] = measurement[(2*s) + 1]; 
			current_sample[1] = measurement[(2*s)];
			memcpy(&sample_value, current_sample, 2);
			
			if (ABS(sample_value) > left_max)
				
				left_max = ABS(sample_value);
		}

		// calculate right sum
		for (s=MEASUREMENT_BUFFER/4; s<MEASUREMENT_BUFFER/2; s++){
		
			current_sample[0] = measurement[(2*s) + 1]; 
			current_sample[1] = measurement[(2*s)];
			memcpy(&sample_value, current_sample, 2);
			
			if (ABS(sample_value) > right_max)
				
				right_max = ABS(sample_value);
		}
		
		if ((left_max > 0) && (((4.0 * right_max) / (1.0 * left_max)) > 4.5) && ((right_max + left_max) > 40000)){
			event_found = TRUE;
			event_position = interval_min + (MEASUREMENT_BUFFER/2);
			if (left_max > 0)
				event_salience = (4*right_max) / left_max;
			else
				event_salience = 2;
			
			printf("\nEvent found: position = %d, salience = %d", event_position, event_salience);
		}
		

	}*/

	//for (i=0; i<MEASUREMENT_BUFFER; i++) fwrite(&measurement[i],1,(BUFFSIZE-1),outputstream);

}

