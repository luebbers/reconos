#include "../header/particle_filter.h"
#include <stdio.h>
#include <stdlib.h>
#ifndef ONLYPC
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "../header/timing.h"
#endif

#ifndef ONLYPC
//! preSampling sw thread
cyg_thread * sw_thread_preSampling;

//! Stack for the preSampling sw thread
char ** sw_thread_preSampling_stack;

//! thread handle of preSampling sw thread
cyg_handle_t * sw_thread_preSampling_handle;

#endif

/*
  Compare two indexes based on the replication factor.  For use in qsort.

  @param p1 pointer to a index
  @param p2 pointer to a index

  @return Returns -1 if the \a p1 has lower weight than \a p2, 1 if \a p1
    has higher weight than \a p2, and 0 if their weights are equal.
*/
int index_cmp( const void* p1, const void* p2 )
{

  index_type* _p1 = (index_type*)p1;
  index_type* _p2 = (index_type*)p2;

  if( _p1->replication > _p2->replication )
    return -1;
  if( _p1->replication < _p2->replication )
    return 1;
  return 0;

}





/**
  prepares sampling by copying the particles with higher replication/clone factors to the ones, which are discarded.

  Assumption: The index array is sorted in such a way, that the first entries have replication/clone factors higher than 0,
  and the last entries have a replication/clone factor of 0.


*/
void prepare_sampling(){

    int i = 0, j;
    int ind_up  = 0;
    int ind_low = N-1;

    // sort index array
    qsort( &indexes[0], N, sizeof( index_type ), &index_cmp );

    i = 0;

    //while (i<N && indexes[i].replication > 0){
    while (i<N){
         
        if (indexes[i].replication == -1) printf("\nParticle %d is not resampled.", i);

        // replicated/clone one time (=> do not do anything)

        
        if (indexes[i].replication <= 0) return;  // finished
        

        // replicate/clone replication factor - 1 times
        for (j=1; j<indexes[i].replication; j++){
              
	     memcpy(&particles[indexes[ind_low].index], &particles[indexes[ind_up].index], sizeof(particle));
	     ind_low--;
        }
       
	ind_up++;
        i++;
    } 

               
}

#ifndef ONLYPC
/**
   preSampling sw thread. First this thread starts the userfunction to get a new message. Then it puts messages from messagebox mb_resampling_done either in sw_mb_sampling or hw_mb_sampling.
*/
void preSampling_thread (cyg_addrword_t data){

  int done;
  int message_delivered = TRUE;
  int message = 1;
  int i;
  int * messages  = (int *) malloc(sizeof(int)*(number_of_blocks));
  timing_t t_start = 0, t_stop = 0, t_result = 0;
  for (i=0; i<number_of_blocks; i++){
     
       messages[i] = FALSE;
  }


  while (42){

      for (i=0; i<number_of_blocks; i++){
     
       messages[i] = FALSE;
      }       

      // 1) check, if all messages are received to message box
      //    If this is not true, get the next message
      while (!all_messages_received(messages, number_of_blocks)){

          message = (int) cyg_mbox_get( mb_resampling_done_handle[0] );

          if (message > 0 && message <= number_of_blocks){

	      messages[message-1] = TRUE; 
              //diag_printf("\n[Sampling Switch] Nachricht %d erhalten", message);
	  }
      }
    

      //diag_printf("\n[Sampling Switch] alle Nachrichten erhalten"); 

      t_start = gettime();

      // set messages back to 'not received'
      for (i=0; i<number_of_blocks; i++){
     
           messages[i] = FALSE;
      }

#ifdef USE_CACHE      
       XCache_EnableDCache( 0xF0000000 );    
#endif
    
      // 2) get new meausurement
      get_new_measurement();

      // 3) prepare sampling
      prepare_sampling();


      for (i=0; i<N; i++){

	    particles[i].w = 128;
      }

#ifdef USE_CACHE
      XCache_EnableDCache( 0xF0000000 ); 
#endif

      t_stop = gettime();
      t_result = calc_timediff(t_start, t_stop);
      //printf("\nPresampling: %d", t_result);

      
      // 4) Deliver all messages to message box
      for (message=1; message<=number_of_blocks; message++){

           
	   message_delivered = FALSE;
	   while (message_delivered == FALSE){
      
	         done = cyg_mbox_tryput( mb_sampling_handle[0], ( void * ) message );

	      if (done > 0){
		//printf("\n[Sampling Switch] Nachricht %d geschickt", message);
                  message_delivered = TRUE;   
              } 
          }
      }
  }
} 




/**
  creates preSampling sw thread. 
*/
void create_preSampling_thread(){

     
     // create sw threads variables
     sw_thread_preSampling = (cyg_thread *) malloc (sizeof(cyg_thread));

     // create sw thread stacks 
     sw_thread_preSampling_stack = (char **) malloc (sizeof (char *));
     sw_thread_preSampling_stack[0] = (char *) malloc (STACK_SIZE * sizeof(char));    

     // create sw handles
     sw_thread_preSampling_handle = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));

   
     // create and resume sw sampling switch thread in eCos

     // create sw sampling threads
     cyg_thread_create(PRIO,                   // scheduling info (eg pri)  
                  preSampling_thread,          // entry point function     
                  0,                           // entry data                
                  "PRESAMPLING",               // optional thread name      
                  sw_thread_preSampling_stack[0], // stack base                
                  STACK_SIZE,                     // stack size,       
                  sw_thread_preSampling_handle,   // returned thread handle    
                  sw_thread_preSampling           // put thread here           
      );
 
      // resume threads
     cyg_thread_resume(sw_thread_preSampling_handle[0]);
}

#endif

