#include "../header/particle_filter.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <xcache_l.h>
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "../header/timing.h"

#include "../../sort_demo/sort8k.h"


//! preResampling sw thread 
//cyg_thread * sw_thread_preResampling;

//! Stack for the preResampling sw thread 
//char ** sw_thread_preResampling_stack;

//! thread handles of preResampling sw thread 
//cyg_handle_t * sw_thread_preResampling_handle;

//! preResampling sw thread 
pthread_t sw_thread_preResampling; 
pthread_attr_t sw_thread_preResampling_attr;


/*
  Compare two particles based on weight.  For use in qsort.

  @param p1 pointer to a particle
  @param p2 pointer to a particle

  @return Returns -1 if the \a p1 has lower weight than \a p2, 1 if \a p1
    has higher weight than \a p2, and 0 if their weights are equal.
*/
int particle_cmp( void* p1, void* p2 )
{

  particle* _p1 = (particle*)p1;
  particle* _p2 = (particle*)p2;

  if( _p1->w > _p2->w )
    return -1;
  if( _p1->w < _p2->w )
    return 1;
  return 0;

}



void print_particles_and_weights(){

  int i;

  for (i=0; i<N; i++)
    printf("\nParticle %d:\tWeight %d", i, particles[i].w);

}


/**
  Returns TRUE, if all messages received, else FALSE

 @param messages: array containing FALSE, whenever a message is not received
 @param number: number of messages
 @return information, if every message is received
*/
int all_messages_received(int * messages, int number){

  int i;
  // TODO: message[0] - send??
  for (i=0; i<number; i++){

      if (messages[i] == FALSE){

	  return FALSE;
      }
  }

  return TRUE;

}




/**
  normalizes particle weights
*/
void normalize_particle_weights(){

     int i, sum_weights = 0;

     //int max = particles[0].w;
     //int min = max;
     
     // calculates sum of particle weights
     for (i=0; i<N; i++){
     
            
            //printf("\nParticles [%d]: \t %d", i, particles[i].w);
            sum_weights += particles[i].w;
            
            /*
	    if (max < particles[i].w)
	         
                   max = particles[i].w;
            
            if (min > particles[i].w)
	         
	    min = particles[i].w;
            //printf("\nParticles[%d]: \t%d", i, particles[i].w);
            */
     }

     //printf("\nMax. Likelihood %d, \tMin Likelihood: %d", max, min);

     // worst case scenario
     if (sum_weights == 0){ 
         
         printf("Error: sum of particle weights is 0");
         return;
     }


      // normalize particle weights
        for (i=0; i<N; i++){

	     //sum_weights /= PF_GRANULARITY;
             particles[i].w *= PF_GRANULARITY;
             particles[i].w /= sum_weights;
             if (particles[i].w < 0){
		   particles[i].w = 0;
	     }
        }
}



void calculate_resampling_function(){

   int i, j, from, to, r, test;
   int sum = 0;

   U[0] = (rand() / (RAND_MAX / PF_GRANULARITY));
   //U[0] = PF_GRANULARITY;
   //U[0] /= 2;
 
   for (i=1; i<number_of_blocks; i++){

        // calculate block sum of block before
        sum = 0;
        from = (i-1)*block_size;
        to = from + block_size - 1;
        if ((N-1) < to){
           
	    to = N - 1;
        }
        for (j=from; j<=to; j++){

	     sum += particles[i].w;
        }
                 
        // calcualte replication factor of (i-1)-th block
        r = (sum * N) - U[i-1];

        test = r % PF_GRANULARITY;
        r /= PF_GRANULARITY;

        if (test > 0){
            r ++;
        }
        
        // set resampling function values
        U[i] =  U[i-1];
        U[i] += r * PF_GRANULARITY;
	U[i] -=  N * sum;
   }  


   // reset index array
   for (i=0; i<N; i++){

       indexes[i].index       = i;
       indexes[i].replication = -1;
   }


}



/**
   preResampling sw thread. Waits for all importance_done messages, normalizes the particle weights,
   calls iteration_done function and finally sends messages to the resampling message box.
*/
//void  preResampling_thread (cyg_addrword_t data){
void *  preResampling_thread (void * data){

  int message = 1;
  int i, done;
  int message_delivered = FALSE;
  int * messages = (int *) malloc(sizeof(int)*(number_of_blocks));
  //int * messages = (int *) malloc(sizeof(int)*N);
  timing_t time_start = 0, time_stop = 0, time_particle_filter = 0;
  int number_of_measurements = 0;
  timing_t t_start = 0, t_stop = 0, t_result_1 = 0, t_result;

  for (i=0; i<number_of_blocks; i++){
     
       messages[i] = FALSE;
  }


  while (42){

      // 1) check, if all messages are received to message box
      //    If this is not true, get the next message
      while (!all_messages_received(messages, number_of_blocks) ){

          message = (int) cyg_mbox_get( mb_importance_done_handle[0] );

          if (message > 0){
              //diag_printf("\n[Resampling Switch] received message %d", message);
              messages[message-1] = TRUE;
	  }
      }
      //diag_printf("\n[Resampling Switch] received all messages");

      t_start = gettime();

      // set messages back to 'not received'
      for (i=0; i<number_of_blocks; i++){
     
           messages[i] = FALSE;
      }

#ifdef USE_CACHE
      XCache_EnableDCache( 0xF0000000 );
#endif      

      // 2) normalize particle weights 
      normalize_particle_weights();

      t_stop = gettime();
      t_result_1 = calc_timediff(t_start, t_stop);
      //printf("\nNormalize weights: %d", t_result_1);;

      // 3) calls iteration_done user function
      iteration_done(particles, observations, ref_data, N);

      // calculate time for one particle filter loop
      time_stop = gettime();
      time_particle_filter = calc_timediff( time_start, time_stop );
      if (number_of_measurements > 0)
      {
	 //printf("\n%d \t%d", number_of_measurements, time_particle_filter);
         diag_printf("\n%d", time_particle_filter);
         //diag_printf("\nnumber of sortings: %d", (sort_counter - old_number_of_sortings));
	 old_number_of_sortings = sort_counter;
	 //diag_printf("\n%d \t%d", number_of_measurements, time_particle_filter);
      }
      time_start = gettime();
      number_of_measurements++;

      t_start = gettime();
      

      // 4) calculate Resampling Function U
      calculate_resampling_function();

      t_stop = gettime();
      t_result = calc_timediff(t_start, t_stop);
      t_result += t_result_1;
      //printf("\nPreresampling: %d", t_result);


#ifdef USE_CACHE 
       XCache_EnableDCache( 0xF0000000 );
#endif
   
      

      // 5) send all messages to sw/hw message box
      for (message=1; message<=number_of_blocks; message++){

           
	   message_delivered = FALSE;
	   while (message_delivered == FALSE){

		done = cyg_mbox_tryput( mb_resampling_handle[0], ( void * ) message );

	     if (done > 0){
	          //diag_printf("\n[Resampling Switch] forwarded %d to Reampling stage", message);
                  message_delivered = TRUE;   
             }
	      
	  }
      } 
          
      //printf("\n[Sampling Switch] sent all messages");   
  }
  return NULL;
} 




/**
  creates preResampling sw thread. 
*/
void create_preResampling_thread(){

    pthread_attr_init(&sw_thread_preResampling_attr);
    pthread_attr_setstacksize(&sw_thread_preResampling_attr, STACK_SIZE);
    pthread_create(&sw_thread_preResampling, &sw_thread_preResampling_attr, preResampling_thread, 0);


     /*// create sw threads variables
     sw_thread_preResampling = (cyg_thread *) malloc (sizeof(cyg_thread));

     // create sw thread stacks 
     sw_thread_preResampling_stack = (char **) malloc (sizeof (char *));
     sw_thread_preResampling_stack[0] = (char *) malloc (STACK_SIZE * sizeof(char));    

     // create sw handles
     sw_thread_preResampling_handle = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));

   
     // create and resume sw resampling switch thread in eCos
        
     // create sw resampling threads
     cyg_thread_create(PRIO,                     // scheduling info (eg pri)  
                  preResampling_thread,          // entry point function     
                  0,                             // entry data                
                  "PRERESAMPLING",              // optional thread name      
                  sw_thread_preResampling_stack[0], // stack base                
                  STACK_SIZE,                       // stack size,       
                  sw_thread_preResampling_handle,   // returned thread handle    
                  sw_thread_preResampling           // put thread here           
     );
        
     // resume threads
     cyg_thread_resume(sw_thread_preResampling_handle[0]);*/
}




