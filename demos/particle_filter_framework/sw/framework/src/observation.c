#include "../header/particle_filter.h"
#include <stdio.h>
#include <stdlib.h>
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "../header/timing.h"


//! sw threads for observation (o)
cyg_thread * sw_thread_o;
cyg_thread * hw_thread_o;



//! needed for dynamic hw threads (o)
//pthread_t hw_thread_o_dynamic;
//pthread_attr_t * hw_thread_o_dynamic_swattr;
//rthread_attr_t * hw_thread_o_dynamic_hwattr;
hw_thread_node2 * hw_threads_o_dynamic = NULL;

//! Stacks for every thread
char ** sw_thread_o_stack;
char ** hw_thread_o_stack;

//! thread handles to every thread
cyg_handle_t * sw_thread_o_handle;
cyg_handle_t * hw_thread_o_handle;

//! attributes for a hw thread
rthread_attr_t * hw_thread_o_attr;

//! ressources array for the importance hw thread
reconos_res_t * res_o, * res_o_dynamic = NULL;


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
information_struct_o * information_o, * information_o_dynamic = NULL;

//! number of sw threads
int sw_number_of_threads_o = 0;

//! number of hw threads (static)
int hw_number_of_threads_o = 0;

//! number of hw threads (dynamic)
int hw_number_of_threads_o_dynamic = 0;

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
                  //diag_printf("\n[Observation Thread No. %d] received message %d", (int) thread_number, message);
                  //diag_printf("\n[Observation SW Thread] received message %d", message);
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
              //printf("\n[Observation Thread No. %d] sent message %d", (int) thread_number, message);
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
 terminates and deletes all HW threads for Observation (static)
*/
void observation_hw_delete_static(void){
 
  int i;
  for (i=0; i<hw_number_of_threads_o;i++){

      while (!cyg_thread_delete(hw_thread_o_handle[i]))
                cyg_thread_release(hw_thread_o_handle[i]);
  }
  
}



/**
   creates observation HW threads (static)

   @param number_of_threads: number of threads for observation step
   @param reconos_slots: pointer to array including the slot numbers, where the observation hw threads are connected to
   @param parameter: pointer to a array filled with parameter (size <= 128 byte)
   @param number_of_parameter: number of parameter in parameter array
*/
void set_observe_hw_static (unsigned int number_of_threads, unsigned int * reconos_slots, int * parameter, unsigned int number_of_parameter){

     
     int i;

     // terminate old sw threads if needed
     if (hw_number_of_threads_o > 0){

       observation_hw_delete_static();

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
     information_o[0].parameter_size = number_of_parameter;
     information_o[0].parameter = parameter;

     //unsigned char * information_o_pos = (unsigned char*)0x01C00000;
     //diag_printf("information...");
     //memcpy((void*)information_o_pos, (void*)information_o, sizeof(information_struct_o));
     //diag_printf("\nobservation: information_struct = %X", (unsigned int)information_o);
     
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
     res_o = (reconos_res_t *) malloc (4 * sizeof(reconos_res_t));
          
     res_o[0].ptr  =  mb_sampling_done_handle;
     res_o[0].type =  CYG_MBOX_HANDLE_T ;
     res_o[1].ptr  =  mb_importance_handle;
     res_o[1].type =  CYG_MBOX_HANDLE_T ;
     res_o[2].ptr  =  hw_mb_observation_measurement_handle;
     res_o[2].type =  CYG_MBOX_HANDLE_T ;
     res_o[3].ptr  =  hw_mb_observation_exit_handle;
     res_o[3].type =  CYG_MBOX_HANDLE_T ; 

     // attributes for hw threads
     hw_thread_o_attr = malloc (number_of_threads * sizeof(rthread_attr_t));

     // create and resume hw observation threads in eCos
     for (i = 0; i < number_of_threads; i++){
     
         
          // set attributes
          rthread_attr_init(&hw_thread_o_attr[i]);
          // set slot number
          rthread_attr_setslotnum(&hw_thread_o_attr[i], reconos_slots[i]);
          // add ressources
          rthread_attr_setresources(&hw_thread_o_attr[i], res_o, 4); 

          //diag_printf("\n--> hw observation (%d, slot %d) dcr address: %d", i, 
          //             reconos_slots[i], hw_thread_o_attr[i].dcr_base_addr);

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




/**
 terminates and deletes all HW threads for Observation (dynamic)
*/
void observation_hw_delete_dynamic(int number){
 
  int i;
  for (i = 0; i<number; i++)
  {
        cyg_mbox_tryput( hw_mb_observation_exit_handle[0], (void *) 1 );
  }  
}




/**
   creates observation HW threads (dynamic)

   @param number_of_threads: number of threads for observation step
   @param hw_circuit: hardware circuit of the thread
   @param parameter: pointer to a array filled with parameter (size <= 128 byte)
   @param number_of_parameter: number of parameter in parameter array
*/
void set_observe_hw_dynamic (unsigned int number_of_threads, reconos_circuit_t *  hw_circuit, int * parameter, unsigned int number_of_parameter){
     
     int i;

     // terminate old sw threads if needed
     if (number_of_threads < 0 || number_of_threads == hw_number_of_threads_o_dynamic) 
     {
          return;
     } 
     else 
     {
          if (number_of_threads < hw_number_of_threads_o_dynamic)
          {
               // remove slots, which are not needed
               observation_hw_delete_dynamic(hw_number_of_threads_o_dynamic - number_of_threads);
               hw_number_of_threads_o_dynamic = number_of_threads;
               return;
          }
     }

     
     if (information_o_dynamic == NULL)
     {
         // set information for hw threads
         information_o_dynamic = (information_struct_o *) malloc (sizeof(information_struct_o));
         information_o_dynamic[0].particles = particles;
         information_o_dynamic[0].number_of_particles = N;
         information_o_dynamic[0].particle_size = sizeof(particle);
         information_o_dynamic[0].block_size = block_size;
         information_o_dynamic[0].observation_size = sizeof(observation);
         information_o_dynamic[0].observations = observations;
         information_o_dynamic[0].input = &observations_input;
         information_o_dynamic[0].parameter_size = number_of_parameter;
         information_o_dynamic[0].parameter = parameter;
     }
     
     
     /*if (information_o_dynamic == NULL)
     {
         // set information for hw threads
         information_o_dynamic = (information_struct_o *) malloc (sizeof(information_struct_o));
         information_o_dynamic[0].particles = 4000000;
         information_o_dynamic[0].number_of_particles = 100;
         information_o_dynamic[0].particle_size = 128;
         information_o_dynamic[0].block_size = 10;
         information_o_dynamic[0].observation_size = 256;
         information_o_dynamic[0].observations = 4000000;
         information_o_dynamic[0].input = 4000000;
         information_o_dynamic[0].parameter_size = 0;
         information_o_dynamic[0].parameter = 4000000;
     }*/

     if (res_o_dynamic == NULL)
     {
         /*mb_sampling_done = (cyg_mbox *) malloc (sizeof(cyg_mbox));
         mb_sampling_done_handle      = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
         cyg_mbox_create( mb_sampling_done_handle, mb_sampling_done);
         mb_importance = (cyg_mbox *) malloc (sizeof(cyg_mbox));
         mb_importance_handle      = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
         cyg_mbox_create( mb_importance_handle, mb_importance);
         hw_mb_observation_measurement = (cyg_mbox *) malloc (sizeof(cyg_mbox));
         hw_mb_observation_measurement_handle      = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
         cyg_mbox_create( hw_mb_observation_measurement_handle, hw_mb_observation_measurement);
         hw_mb_observation_exit = (cyg_mbox *) malloc (sizeof(cyg_mbox));
         hw_mb_observation_exit_handle      = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
         cyg_mbox_create( hw_mb_observation_exit_handle, hw_mb_observation_exit);*/
         // set ressources
         res_o_dynamic = (reconos_res_t *) malloc (4 * sizeof(reconos_res_t)); 
         res_o_dynamic[0].ptr  =  mb_sampling_done_handle;
         res_o_dynamic[0].type =  CYG_MBOX_HANDLE_T ;
         res_o_dynamic[1].ptr  =  mb_importance_handle;
         res_o_dynamic[1].type =  CYG_MBOX_HANDLE_T ;
         res_o_dynamic[2].ptr  =  hw_mb_observation_measurement_handle;
         res_o_dynamic[2].type =  CYG_MBOX_HANDLE_T ;
         res_o_dynamic[3].ptr  =  hw_mb_observation_exit_handle;
         res_o_dynamic[3].type =  CYG_MBOX_HANDLE_T ;    
     }
     
     // create and resume hw observation threads in eCos
     for (i = 0; i < (number_of_threads - hw_number_of_threads_o_dynamic); i++)
     {

          hw_thread_node * new_node = malloc (sizeof(hw_thread_node));
          new_node->sw_attr = (pthread_attr_t *) malloc (sizeof(pthread_attr_t));
          new_node->hw_attr = (rthread_attr_t *) malloc (sizeof(rthread_attr_t));
     
          int ret = pthread_attr_init(new_node->sw_attr);
          //diag_printf("\nO: p_thread_attr_init = %d", ret);
          ret = pthread_attr_setstacksize(new_node->sw_attr, STACK_SIZE);
          //diag_printf("\nO: p_thread_attr_set_stacksize = %d", ret);
          ret = rthread_attr_init(new_node->hw_attr);
          //diag_printf("\nO: r_thread_attr_init = %d", ret);
          ret = rthread_attr_setcircuit(new_node->hw_attr, hw_circuit);
          //diag_printf("\nO: r_thread_set_circuit = %d", ret);
	  //rthread_attr_setstatesize(new_node->hw_attr, 16384);

          ret = rthread_attr_setresources(new_node->hw_attr, res_o_dynamic, 4);
          //diag_printf("\nO: r_thread_attr_setresources = %d", ret);

          // set hw priority
          //ret = rthread_attr_setpriority(new_node->hw_attr, (unsigned char) 17);

          ret = rthread_create(&(new_node->hw_thread), new_node->sw_attr, new_node->hw_attr, 
                 (void*)information_o_dynamic); 
          //diag_printf("\nO: r_thread_create = %d", ret);

          // insert node to list
          new_node->next = hw_threads_o_dynamic;
          hw_threads_o_dynamic = new_node;

          /*hw_thread_node2 * new_node = malloc (sizeof(hw_thread_node2));
          new_node->hw_thread = (cyg_thread *) malloc (sizeof(cyg_thread));
          new_node->hw_thread_handle = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));
          new_node->hw_thread_stack = (char *) malloc (STACK_SIZE*sizeof(char));
          new_node->hw_attr = (rthread_attr_t *) malloc (sizeof(rthread_attr_t));

          // insert node to list
          new_node->next = hw_threads_o_dynamic;
          hw_threads_o_dynamic = new_node;

          rthread_attr_init(new_node->hw_attr);
          ////////////////////////////////////////////////////rthread_attr_setcircuit(new_node->hw_attr, hw_circuit);
          rthread_attr_setresources(new_node->hw_attr, res_o_dynamic, 4);
          //rthread_attr_setpriority(new_node->hw_attr, (unsigned char) 16);
          reconos_hwthread_create( 15,                                        // delegate priority
                                     new_node->hw_attr,                       // hardware thread attributes
                                     (cyg_addrword_t) information_o_dynamic,  // entry data (address of counter)
                                     "HW_OBSERVATION",                        // thread name
                                     new_node->hw_thread_stack,               // stack
                                     STACK_SIZE,                              // stack size
                                     new_node->hw_thread_handle,              // thread handle
                                     new_node->hw_thread                      // thread object
          );

          // run hardware thread
          cyg_thread_resume( *(new_node->hw_thread_handle));*/
     }

     // set number of hw threads
     hw_number_of_threads_o_dynamic = number_of_threads;
}



