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
#endif
#include "../header/timing.h"

#ifndef ONLYPC

//! sw threads for importance (i)
cyg_thread * sw_thread_i;

//! hw thread for importance (i)
cyg_thread * hw_thread_i;

//! Stacks for every thread
char ** sw_thread_i_stack;
char ** hw_thread_i_stack;

//! thread handles to every thread
cyg_handle_t * sw_thread_i_handle;
cyg_handle_t * hw_thread_i_handle;

//! attributes for a hw thread
rthread_attr_t * hw_thread_i_attr;

//! ressources array for the importance hw thread
reconos_res_t * res_i;


//! struct definition with all informations needed by the hw importance
typedef struct information_struct_i{

  volatile particle * particles;
  volatile int number_of_particles;
  volatile int particle_size;
  volatile int block_size;
  volatile int observation_size;
  volatile observation * observations;
  volatile observation * ref_data;

} information_struct_i;

//! pointer to struct with all information needed by hw importance
information_struct_i * information_i;

//#define DEBUG 1
//#define DEBUG3 1

//! number of sw threads
int sw_number_of_threads_i = 0;

//! number of hw threads
int hw_number_of_threads_i = 0;

//! frame counter (debug)
int framecounter = 0;



/**
   prints observation to screen
  
   @param histo: histogram, which should be printed
 */
/*
void print_observation (observation * o){

   
  printf("\nx = %d", o->x);
  printf("\ny = %d", o->y);
  printf("\nwidth  = %d", o->width);
  printf("\nheight = %d", o->height);
  printf("\n-------------------------------\n\n");

}
*/



/**
   importance sw thread

    @param data: input data for sw thread
*/
void importance_sw_thread (cyg_addrword_t data){


  // unsigned int thread_number = (unsigned int) data;
    int from, to;
    int done;
    int i;
    int new_message = FALSE;
    int message = 1;
    int message_to_delivere = FALSE;
    int number_of_measurements_i = 0;
    //int sum_of_measurements_i = 0;
    //int average_of_measurements_i = 0;
    timing_t time_start_i = 0, time_stop_i = 0, time_importance_sw = 0;
    
    while (42) {

      // 1) if there is no message to delivered, check for new message
      while (message_to_delivere == FALSE && new_message == FALSE){

            message = (int) cyg_mbox_get( mb_importance_handle[0] );
            if (message > 0 && message <= (N/block_size)){
                 
	          new_message = TRUE;
                  time_start_i = gettime();      
                  //diag_printf("\n[Importance Thread No. %d] received message %d", (int) thread_number, message);
                  //diag_printf("\n[Importance] received message %d", message);
            }
      }

#ifdef USE_CACHE  
       XCache_EnableDCache( 0xF0000000 );
#endif

      // 2) if a new message has arrived, sample the particles
      new_message = FALSE;


      from = (message - 1) * block_size;
      to   = from + block_size - 1;
      if ((N - 1) < to)
	       to = N - 1; 

      //printf("\nIMPORTANCE");
      for (i=from; i<=to; i++)
      {

            //observations[i].no_tracking_needed = TRUE;
            // CHANGE CHANGE CHANGE - TODO: REMOVE
            /*observation obs;
            memcpy(&obs, &observations[i], sizeof(observation));
            extract_observation(&particles[i], &observations[i]);

            int j;
            for(j=0;j<OBSERVATION_LENGTH;j++)
            {
              if(obs.fft[j].re!=observations[i].fft[j].re)
                diag_printf("\nparticle[%d].fft[%d].re: hw=%d, sw=%d",i,j,(int)obs.fft[j].re,(int)observations[i].fft[j].re);
              if(obs.fft[j].im!=observations[i].fft[j].im)
                diag_printf("\nparticle[%d].fft[%d].im: hw=%d, sw=%d",i,j,(int)obs.fft[j].im,(int)observations[i].fft[j].im);
            }
            */
            particles[i].w = likelihood (&particles[i], &observations[i], ref_data);
            //if (particles[i].w <= 0) { particles[i].w = 1;}     
      }

      message_to_delivere = TRUE;


#ifdef USE_CACHE  
       XCache_EnableDCache( 0xF0000000 );
#endif
  
      time_stop_i = gettime();

      // 3) if a message should be delivered, deliver it
      while ( message_to_delivere == TRUE){

           done = cyg_mbox_tryput( mb_importance_done_handle[0], ( void * ) message );
              
           if (done > 0){
  
              message_to_delivere = FALSE;
              time_importance_sw = calc_timediff( time_start_i, time_stop_i );
              number_of_measurements_i++;
              //sum_of_measurements_i += time_importance_sw;
              //average_of_measurements_i = sum_of_measurements_i / number_of_measurements_i;
              //printf("\nImportance SW: %d, \tmessage %d, \ttime: %d", number_of_measurements_i, (message-1), time_importance_sw);
              //printf("\n[Importance Thread No. %d] s %d geschickt", (int) thread_number, message);
           }
      }
      
          
   }
}


/**
 terminates sw threads
*/
void importance_sw_delete(void){
  
  int i;

  // terminate all sw threads
  for (i=0; i<sw_number_of_threads_i;i++){
 
       while (!cyg_thread_delete(sw_thread_i_handle[i]))
                cyg_thread_release(sw_thread_i_handle[i]);
  }

}




/**
   creates importance SW threads (an delete old 'SW' threads)

   @param number_of_threads: number of threads for importance step
*/
void set_importance_sw (unsigned int number_of_threads){

     int i;

     // terminate old sw threads if needed
     if (sw_number_of_threads_i > 0){

        importance_sw_delete();

        // free all variables
        for (i=0; i<sw_number_of_threads_i;i++){
 
            free(sw_thread_i_stack[i]);
        }

        free(sw_thread_i);
        free(sw_thread_i_stack);
        free(sw_thread_i_handle);
  
     }

     // set number of sw threads
     sw_number_of_threads_i = number_of_threads;
     
     // create sw threads variables
     sw_thread_i = (cyg_thread *) malloc (number_of_threads * sizeof(cyg_thread));

     // create sw thread stacks 
     sw_thread_i_stack = (char **) malloc (number_of_threads * sizeof (char *));
     for (i=0; i<number_of_threads; i++){
          
          sw_thread_i_stack[i] = (char *) malloc (STACK_SIZE * sizeof(char));     
     }
 
     // create sw handles
     sw_thread_i_handle = (cyg_handle_t *) malloc (number_of_threads * sizeof(cyg_handle_t));

     
     // create and resume sw importance threads in eCos
     for (i = 0; i < number_of_threads; i++){
     

          // create sw importance threads
          cyg_thread_create(PRIO,                // scheduling info (eg pri)  
                      importance_sw_thread,         // entry point function     
                      ( cyg_addrword_t ) i,         // entry data                
                      "IMPORTANCE",                 // optional thread name      
                      sw_thread_i_stack[i],         // stack base                
                      STACK_SIZE,                   // stack size,       
                      &sw_thread_i_handle[i],       // returned thread handle    
                      &sw_thread_i[i]               // put thread here           
           );
          
	  // resume threads
          cyg_thread_resume(sw_thread_i_handle[i]);   
     }
}


/**
 terminates and deletes all HW threads for Importance
*/
void importance_hw_delete(void){


  int i;

  // terminate all hw threads
  for (i=0; i<hw_number_of_threads_i;i++){

       while (!cyg_thread_delete(hw_thread_i_handle[i]))
                cyg_thread_release(hw_thread_i_handle[i]);

  }
}



/**
   creates importance HW threads (and deletes 'old' HW threads)

   @param number_of_threads: number of threads for importance step
   @param reconos_slots: pointer to array including the slot numbers, where the importance hw threads are connected with 

*/
void set_importance_hw (unsigned int number_of_threads, unsigned int * reconos_slots){

     
     int i;

     // terminate old sw threads if needed
     if (hw_number_of_threads_i > 0){

       importance_hw_delete();

        // free all variables
        for (i=0; i<hw_number_of_threads_i;i++){
   
            free(hw_thread_i_stack[i]);
         }

        free(hw_thread_i);
        free(hw_thread_i_stack);
        free(hw_thread_i_handle);
        free(res_i);
        free(hw_thread_i_attr);
        free(information_i);
     }

     // set number of hw threads
     hw_number_of_threads_i = number_of_threads;

     if (number_of_threads < 1) return;

     // set information
     information_i = (information_struct_i *) malloc (sizeof(information_struct_i));
           

     // set information particles
     information_i[0].particles = particles;
     information_i[0].number_of_particles = N;
     information_i[0].particle_size = sizeof(particle);
     information_i[0].block_size = block_size;

     // observations
     information_i[0].observation_size = sizeof(observation);
     information_i[0].observations = observations;
     information_i[0].ref_data = ref_data;

     #ifdef USE_CACHE
         XCache_EnableDCache( 0xF0000000 );
     #endif 

     // debug
     //information_i[0].block_size = 2;
     //information_i[0].observation_size = sizeof(debug_ob);
     //information_i[0].observations = (observation*)debug_obs;
     
     // create hw threads variables
     hw_thread_i = (cyg_thread *) malloc (number_of_threads * sizeof(cyg_thread));

     // create hw thread stacks 
     hw_thread_i_stack = (char **) malloc (number_of_threads * sizeof (char *));
     for (i=0; i<number_of_threads; i++){
          
          hw_thread_i_stack[i] = (char *) malloc (STACK_SIZE * sizeof(char));     
     }
 
     // create hw handles
     hw_thread_i_handle = (cyg_handle_t *) malloc (number_of_threads * sizeof(cyg_handle_t));

     // set ressources
     res_i = (reconos_res_t *) malloc (3 * sizeof(reconos_res_t));
          
     res_i[0].ptr  =  mb_importance_handle;
     res_i[0].type =  CYG_MBOX_HANDLE_T ;
     res_i[1].ptr  =  mb_importance_done_handle;
     res_i[1].type =  CYG_MBOX_HANDLE_T ;
     res_i[2].ptr  =  hw_mb_importance_measurement_handle;
     res_i[2].type =  CYG_MBOX_HANDLE_T ;

     // attributes for hw threads
     hw_thread_i_attr = malloc (number_of_threads * sizeof(rthread_attr_t));

     // create and resume hw importance threads in eCos
     for (i = 0; i < number_of_threads; i++){
     
         
          // set attributes
          rthread_attr_init(&hw_thread_i_attr[i]);
          // set slot number
          rthread_attr_setslotnum(&hw_thread_i_attr[i], reconos_slots[i]);
          // add ressources
          rthread_attr_setresources(&hw_thread_i_attr[i], res_i, 3); 

          //diag_printf("\n--> hw importance (%d, slot %d) dcr address: %d", i, reconos_slots[i], hw_thread_i_attr[i].dcr_base_addr);

          // create hw importance thread
          reconos_hwthread_create(
	      (cyg_addrword_t) PRIO_HW,  // priority
              &hw_thread_i_attr[i], // attributes
              (cyg_addrword_t) &information_i[0] , // entry data
              "HW_IMPORTANCE",         // thread name 
               hw_thread_i_stack[i],   // stack
               STACK_SIZE,             // stack size 
               &hw_thread_i_handle[i], // thread handle
               &hw_thread_i[i]         // thread object
          );
          
	  // resume threads
          cyg_thread_resume(hw_thread_i_handle[i]);   
      }
    

}
#endif




