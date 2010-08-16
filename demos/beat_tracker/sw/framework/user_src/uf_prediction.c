#include "../header/particle_filter.h"
#include "../../header/config.h"
#include <math.h>
#include <stdlib.h>



/**
  predicts the new state after a transition model for a given particle
  
  @param p a particle to be predicted
  @return a new particle sampled based on <EM>p</EM>'s transition model
*/
void prediction( particle * p){
	
	/*if (p->successfull_beat == TRUE){ // predicted beat <-> estimated beat (event)

		if (p->next_beat < interval_min){
				
			//printf("\nSUCCESSFULL BEAT");
			//tempo correction
			long int error 	 = p->last_event_time - p->next_beat;
			p->tempo 	+= (error/TEMPO_CORRECTION_FACTOR);
			if (p->tempo < bytespersecond/6) p->tempo = bytespersecond/6;

			// set last beat position
			p->last_beat	 = p->next_beat;//p->last_event_time;

			// next beat prediction
			long int noise 	 =  (rand() / (RAND_MAX / NOISE_FACTOR));
			noise 		-= (NOISE_FACTOR/2);
			p->next_beat 	= p->last_event_time + p->tempo + noise;
		}

		while (p->next_beat < interval_min){
		
			long int noise 	 =  (rand() / (RAND_MAX / NOISE_FACTOR));
			noise 		-= (NOISE_FACTOR/2);		
			p->last_beat = p->next_beat;
			p->next_beat += p->tempo + noise;
		}


	} else { // no successfull beat
	*/
		// create next (intermediate) beat/s if needed
		while (p->next_beat < interval_min){
				
			p->last_beat = p->next_beat;
			p->next_beat += p->tempo;
			//long int noise 	 =  (rand() / (RAND_MAX / NOISE_FACTOR));
			int noise;
			noise	 	 =  (int)(rand() % NOISE_FACTOR);
			noise 		-= (NOISE_FACTOR/2);
			p->next_beat 	+= noise;
			int noise2;
			noise2	 	 =  (int)(rand() % (NOISE_FACTOR/4));
			noise2 		-= (NOISE_FACTOR/8);
			p->tempo 	+= noise2;
		}
	//}
	

}

