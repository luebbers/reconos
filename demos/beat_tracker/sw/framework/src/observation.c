#include "../header/particle_filter.h"
#include <stdio.h>
#include <stdlib.h>
#ifndef ONLYPC
#include <cyg/infra/cyg_type.h>
#include <cyg/infra/diag.h>
#include <cyg/kernel/kapi.h>
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#endif
#include "../header/timing.h"


#ifndef ONLYPC
//! sw threads for observation (o)
cyg_thread * sw_thread_o;

//! hw thread for observation (o)
cyg_thread * hw_thread_o;

//! Stacks for every thread
char ** sw_thread_o_stack;
char ** hw_thread_o_stack;

//! thread handles to every thread
cyg_handle_t * sw_thread_o_handle;
cyg_handle_t * hw_thread_o_handle;

//! attributes for a hw thread
rthread_attr_t * hw_thread_o_attr;

//! ressources array for the importance hw thread
reconos_res_t * res_o;


//! struct definition with all informations needed by the hw importance
typedef struct information_struct_o{

  volatile particle * particles;
  volatile int number_of_particles;
  volatile int particle_size;
  volatile int block_size;
  volatile int observation_size;
  volatile observation * observations;
  volatile void * input;
  volatile int parameter_size;
  volatile int * parameter;
} information_struct_o;

//! pointer to struct with all information needed by hw importance
information_struct_o * information_o;

//! number of sw threads
int sw_number_of_threads_o = 0;

//! number of hw threads
int hw_number_of_threads_o = 0;





/**
   observation sw thread

    @param data: input data for sw thread
*/
void observation_sw_thread (cyg_addrword_t data){


  //unsigned int thread_number = (unsigned int) data;
    int from, to;
    int done;
    int i;
    int new_message = FALSE;
    int message = 1;
    int message_to_deliver = FALSE;
    int number_of_measurements_o = 0;
    //int sum_of_measurements_o = 0;
    //int average_of_measurements_o = 0;
    timing_t time_start_o = 0, time_stop_o = 0, time_observation_sw = 0;
    
    while (42) {

      // 1) if there is no message to delivered, check for new message
      while (message_to_deliver == FALSE && new_message == FALSE){

            message = (int) cyg_mbox_get( mb_sampling_done_handle[0] );
            if (message > 0 && message <= (N/block_size)){
                 
	          new_message = TRUE;
                  time_start_o = gettime();      
                  //printf("\n[Observation Thread No. %d] Nachricht %d erhalten", (int) thread_number, message);
                  //diag_printf("\n[Observation] Nachricht %d erhalten", message);
            }
      }


      // 2) if a new message has arrived, sample the particles
      new_message = FALSE;

      from = (message - 1) * block_size;
      to   = from + block_size - 1;
      if ((N - 1) < to)
	       to = N - 1; 

#ifdef USE_CACHE  
       XCache_EnableDCache( 0xF0000000 );
#endif

      //printf("\nOBSERVATION");
      
      // extract observations
      for (i=from; i<=to; i++){
          
            extract_observation(&particles[i], &observations[i]);
      }

      message_to_deliver = TRUE;


#ifdef USE_CACHE  
       XCache_EnableDCache( 0xF0000000 );
#endif
  
      time_stop_o = gettime();

      // 3) if a message should be delivered, deliver it
      while ( message_to_deliver == TRUE){

           done = cyg_mbox_tryput( mb_importance_handle[0], ( void * ) message );
              
           if (done > 0){
  
              message_to_deliver = FALSE;
              time_observation_sw = calc_timediff( time_start_o, time_stop_o );
              number_of_measurements_o++;
              //sum_of_measurements_o += time_observation_sw;
              //average_of_measurements_o = sum_of_measurements_o / number_of_measurements_o;
              //diag_printf("\nObservation SW: %d, \tmessage %d, \ttime: %d", 
              //         number_of_measurements_o, (message-1), time_observation_sw);
              //printf("\n[Observation Thread No. %d] Nachricht %d geschickt", (int) thread_number, message);
           }
      }
      
          
   }
}


/**
 terminates sw threads
*/
void observation_sw_delete(void){
  
  int i;

  // terminate all sw threads
  for (i=0; i<sw_number_of_threads_o;i++){
 
       while (!cyg_thread_delete(sw_thread_o_handle[i]))
                cyg_thread_release(sw_thread_o_handle[i]);
  }

}




/**
   creates observation SW threads (an delete old 'SW' threads)

   @param number_of_threads: number of threads for observation step
*/
void set_observe_sw (unsigned int number_of_threads){

     int i;

     // terminate old sw threads if needed
     if (sw_number_of_threads_o > 0){

        observation_sw_delete();

        // free all variables
        for (i=0; i<sw_number_of_threads_o;i++){
 
            free(sw_thread_o_stack[i]);
        }

        free(sw_thread_o);
        free(sw_thread_o_stack);
        free(sw_thread_o_handle);
  
     }

     // set number of sw threads
     sw_number_of_threads_o = number_of_threads;
     
     // create sw threads variables
     sw_thread_o = (cyg_thread *) malloc (number_of_threads * sizeof(cyg_thread));

     // create sw thread stacks 
     sw_thread_o_stack = (char **) malloc (number_of_threads * sizeof (char *));
     for (i=0; i<number_of_threads; i++){
          
          sw_thread_o_stack[i] = (char *) malloc (STACK_SIZE * sizeof(char));     
     }
 
     // create sw handles
     sw_thread_o_handle = (cyg_handle_t *) malloc (number_of_threads * sizeof(cyg_handle_t));

     
     // create and resume sw importance threads in eCos
     for (i = 0; i < number_of_threads; i++){
     

          // create sw sampling threads
          cyg_thread_create(PRIO,                // scheduling info (eg pri)  
                      observation_sw_thread,         // entry point function     
                      ( cyg_addrword_t ) i,         // entry data                
                      "OBSERVATION_SW",             // optional thread name      
                      sw_thread_o_stack[i],         // stack base                
                      STACK_SIZE,                   // stack size,       
                      &sw_thread_o_handle[i],       // returned thread handle    
                      &sw_thread_o[i]               // put thread here           
           );
          
	  // resume threads
          cyg_thread_resume(sw_thread_o_handle[i]);   
     }
}



/**
 terminates and deletes all HW threads for Observation
*/
void observation_hw_delete(void){


  int i;

  // terminate all hw threads
  for (i=0; i<hw_number_of_threads_o;i++){

       while (!cyg_thread_delete(hw_thread_o_handle[i]))
                cyg_thread_release(hw_thread_o_handle[i]);

  }
}



/**
   creates observation HW threads

   @param number_of_threads: number of threads for observation step
   @param reconos_slots: pointer to array including the slot numbers, where the observation hw threads are connected to
   @param parameter: pointer to a array filled with parameter (size <= 128 byte)
   @param number_of_parameter: number of parameter in parameter array
*/
void set_observe_hw (unsigned int number_of_threads, unsigned int * reconos_slots, int * parameter, unsigned int number_of_parameter){

     
     int i;

     // terminate old sw threads if needed
     if (hw_number_of_threads_o > 0){

       observation_hw_delete();

        // free all variables
        for (i=0; i<hw_number_of_threads_o;i++){
   
            free(hw_thread_o_stack[i]);
         }

        free(hw_thread_o);
        free(hw_thread_o_stack);
        free(hw_thread_o_handle);
        free(res_o);
        free(hw_thread_o_attr);
        free(information_o);
     }

     // set number of hw threads
     hw_number_of_threads_o = number_of_threads;

     if (number_of_threads < 1) return;

     // set information
     information_o = (information_struct_o *) malloc (sizeof(information_struct_o));
           

     // set information particles
     information_o[0].particles = particles;
     information_o[0].number_of_particles = N;
     information_o[0].particle_size = sizeof(particle);
     information_o[0].block_size = block_size;
     information_o[0].observation_size = sizeof(observation);
     information_o[0].observations = observations;
     information_o[0].input = &observations_input;
     information_o[0].parameter_size = (int) number_of_parameter;
     information_o[0].parameter = parameter;

     
     // create hw threads variables
     hw_thread_o = (cyg_thread *) malloc (number_of_threads * sizeof(cyg_thread));

     // create hw thread stacks 
     hw_thread_o_stack = (char **) malloc (number_of_threads * sizeof (char *));
     for (i=0; i<number_of_threads; i++){
          
          hw_thread_o_stack[i] = (char *) malloc (STACK_SIZE * sizeof(char));     
     }
 
     // create hw handles
     hw_thread_o_handle = (cyg_handle_t *) malloc (number_of_threads * sizeof(cyg_handle_t));

     // set ressources
     res_o = (reconos_res_t *) malloc (3 * sizeof(reconos_res_t));
          
     res_o[0].ptr  =  mb_sampling_done_handle;
     res_o[0].type =  CYG_MBOX_HANDLE_T ;
     res_o[1].ptr  =  mb_importance_handle;
     res_o[1].type =  CYG_MBOX_HANDLE_T ;
     res_o[2].ptr  =  hw_mb_observation_measurement_handle;
     res_o[2].type =  CYG_MBOX_HANDLE_T ;

     // attributes for hw threads
     hw_thread_o_attr = malloc (number_of_threads * sizeof(rthread_attr_t));

     // create and resume hw observation threads in eCos
     for (i = 0; i < number_of_threads; i++){
     
         
          // set attributes
          rthread_attr_init(&hw_thread_o_attr[i]);
          // set slot number
          rthread_attr_setslotnum(&hw_thread_o_attr[i], reconos_slots[i]);
          // add ressources
          rthread_attr_setresources(&hw_thread_o_attr[i], res_o, 3); 

          //diag_printf("\n--> hw observation (%d, slot %d) dcr address: %d", i, reconos_slots[i], hw_thread_o_attr[i].dcr_base_addr);

          // create hw observation thread
          reconos_hwthread_create(
	      (cyg_addrword_t) PRIO_HW,  // priority
              &hw_thread_o_attr[i], // attributes
              (cyg_addrword_t) &information_o[0] , // entry data
              "HW_OBSERVATION",        // thread name 
               hw_thread_o_stack[i],   // stack
               STACK_SIZE,             // stack size 
               &hw_thread_o_handle[i], // thread handle
               &hw_thread_o[i]         // thread object
          );
          
	  // resume threads
          cyg_thread_resume(hw_thread_o_handle[i]);   
      }
    

}
#endif




