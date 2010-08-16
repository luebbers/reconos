#include "../header/particle_filter.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#ifndef ONLYPC
#include <cyg/infra/cyg_type.h>
#include <xcache_l.h>
#include <cyg/infra/diag.h>
#include <cyg/kernel/kapi.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#endif
#include "../header/timing.h"

#ifndef ONLYPC
//! sw thread for resampling (r)
cyg_thread *  sw_thread_r;

//! hw thread for resampling (r)
cyg_thread * hw_thread_r;

//! Stacks for every thread
char ** sw_thread_r_stack;
char ** hw_thread_r_stack;

//! thread handles to every thread
cyg_handle_t * sw_thread_r_handle;
cyg_handle_t * hw_thread_r_handle;

//! attributes for a hw thread
rthread_attr_t * hw_thread_r_attr;

//! ressources array for the resampling hw thread
reconos_res_t * res_r;

//! number of sw threads
int sw_number_of_threads_r = 0;

//! number of hw threads
int hw_number_of_threads_r = 0;


//! resampling function
//int * sw_U;

//! start indexes for resampling threads
//int * sw_start_indexes;
//int * hw_start_indexes;


//! struct definition with all informations needed by the hw resampling
typedef struct information_struct_r{

  volatile particle *   particles;
  volatile index_type * indexes;
  volatile int N;
  volatile int particle_size;
  volatile int block_size;
  volatile int * U;

} information_struct_r;

//! pointer to struct with all information needed by hw resampling
information_struct_r * information_r;

#endif

//#define DEBUG 1

#ifdef ONLYPC

/**
  normalizes particle weights
*/
void normalize_particle_weights(){

     int i, sum_weights = 0;
     
     // calculates sum of particle weights
     for (i=0; i<N; i++) sum_weights += particles[i].w;

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
             if (particles[i].w < 0) particles[i].w = 0;
     }
}


/**
   resamples all particles (PC VERSION)
*/
void resampling_pc(){

  int U_1, temp;
  int fact;
  int ind_up, ind_low;
  int i;

  ind_up = 0;
  ind_low = N - 1;

  normalize_particle_weights();
  
  // resample particles into index array
  U_1 = (rand() / (RAND_MAX / PF_GRANULARITY));
  for (i=0; i<=(N-1); i++){


	  // temporary variable
          temp =  particles[i].w;       
          temp *= N;
          temp -= U_1;
  
          // calculate replication factor
          fact = temp + PF_GRANULARITY;
          fact /= PF_GRANULARITY;

          // calculate U
          U_1 =  fact * PF_GRANULARITY;
          U_1 -= temp;    

          if (fact > 0){
      
              // replicate particle
              indexes[ind_up].index       = i;
              indexes[ind_up].replication = fact;
              ind_up++;

           } else {

              // discard particle
              indexes[ind_low].index       = i;
              indexes[ind_low].replication = 0;
              ind_low--;
	    }

      }
}



#else




/**

     resamples particles using a index array.

     The algorithm was introduced by the paper "Generic Hardware Architectures 
     for Sampling and Resampling in Particle Filters" by Bolic et al.

*/
void resampling_sw_thread (cyg_addrword_t data){

  int U_1, temp;
  int fact;
  int ind_up, ind_low;
  int i;
  int done, from, to;
  int message = 1;
  int message_to_delivere = FALSE;
  int new_message = FALSE;
  timing_t time_start_r = 0, time_stop_r = 0, time_resampling_sw = 0;
  int number_of_measurements_r = 0;
  
  //unsigned int thread_number = (unsigned int) data;




  while (42) {


      // 1) check, if the last message is delivered to message box.
      //    If this is true, get next message box
      while (message_to_delivere == FALSE && new_message == FALSE){

          message = (int) cyg_mbox_get( mb_resampling_handle[0] );

          if (message > 0 && message<=number_of_blocks){

	       new_message = TRUE;
               time_start_r = gettime();
               //diag_printf("\n[Resampling Thread No. %d] Nachricht %d erhalten", (int)thread_number, message);
               //diag_printf("\n[Resampling] Nachricht %d erhalten", message);
          } 
      }

#ifdef USE_CACHE
      XCache_EnableDCache( 0xF0000000 ); 
#endif
      // 2) resample particles in block 'message'

      // calculate from and to indexes
      from = (message - 1) * block_size;
      to = from + block_size - 1;
      if ((N - 1) < to){
          to = N - 1;
      }
      ind_up = from;
      ind_low = to;

      //printf("\nRESAMPLING");
  
      // resample particles into index array
      U_1 = U[message-1];
      for (i=from; i<=to; i++){


	  // temporary variable
          temp =  particles[i].w;       
          temp *= N;
          temp -= U_1;
  
          // calculate replication factor
          fact = temp + PF_GRANULARITY;
          fact /= PF_GRANULARITY;

          // calculate U
          U_1 =  fact * PF_GRANULARITY;
          U_1 -= temp;    

          if (fact > 0){
      
              // replicate particle
              indexes[ind_up].index       = i;
              indexes[ind_up].replication = fact;
              ind_up++;

           } else {

              // discard particle
              indexes[ind_low].index       = i;
              indexes[ind_low].replication = 0;
              ind_low--;
	    }

      }
  
      new_message = FALSE;
      message_to_delivere = TRUE;

      time_stop_r = gettime();


#ifdef USE_CACHE
      XCache_EnableDCache( 0xF0000000 ); 
#endif

      // 3) try to deliver message to hw / sw message box
      while (message_to_delivere == TRUE && new_message == FALSE){
      
	   done = cyg_mbox_tryput( mb_resampling_done_handle[0], ( void * ) message );

	   if (done > 0){

               message_to_delivere = FALSE;
               time_resampling_sw = calc_timediff( time_start_r, time_stop_r );
               number_of_measurements_r++;
               //printf("\nResampling SW: %d, \tmessage %d, \ttime: %d", 
               //       number_of_measurements_r, (message-1), time_resampling_sw);
               //diag_printf("\n[Resampling Thread No. %d] Nachricht %d geschickt", (int)thread_number, message);
           }
      }
  }
}



/**
 terminates sw threads
*/
void resample_sw_delete(void){
  
  int i;  

  // terminate all sw threads
  for (i=0; i<sw_number_of_threads_r; i++){

       //cyg_thread_suspend(sw_thread_r_handle[i]);
       //cyg_thread_kill(sw_thread_r_handle[i]);
       while (!cyg_thread_delete(sw_thread_r_handle[i]))
                cyg_thread_release(sw_thread_r_handle[i]);

  }

}





/**
   creates resample SW thread (and deletes 'old' SW threads)

   @param number_of_threads: number of hw threads for resampling thread
*/
void set_resample_sw ( int number_of_threads ) {

     int i;

     // terminate old sw threads if needed
     if (sw_number_of_threads_r > 0) {
     
         resample_sw_delete();
 
         // free all variables
         for (i=0; i<sw_number_of_threads_r; i++){
         
             free(sw_thread_r_stack[i]);
         }
         
         free(sw_thread_r);
         free(sw_thread_r_stack);
         free(sw_thread_r_handle);
     }

     // set number of sw threads
     sw_number_of_threads_r = number_of_threads;

     // create sw thread stacks 
     sw_thread_r_stack = (char **) malloc (number_of_threads * sizeof (char *));
     for (i=0; i<number_of_threads; i++){
           sw_thread_r_stack[i] = (char *) malloc (STACK_SIZE * sizeof(char));
     }     
      
     // create sw handles
     sw_thread_r_handle = (cyg_handle_t *) malloc ( number_of_threads * sizeof(cyg_handle_t));

     // create sw threads variables
     sw_thread_r = (cyg_thread *) malloc (number_of_threads * sizeof(cyg_thread));

     for (i=0; i<number_of_threads; i++){

        // create sw resampling thread
        cyg_thread_create(PRIO,               // scheduling info (eg pri)  
                      resampling_sw_thread,   // entry point function     
                      ( cyg_addrword_t ) i,   // entry data                
                      "RESAMPLING",           // optional thread name      
                      sw_thread_r_stack[i],   // stack base                
                      STACK_SIZE,             // stack size,       
                      &sw_thread_r_handle[i], // returned thread handle    
                      &sw_thread_r[i]         // put thread here           
        );
         
        // resume thread
        cyg_thread_resume(sw_thread_r_handle[i]);
     }
  
}



/**
 terminates and deletes all HW threads for Resampling
*/
void resample_hw_delete(void){
  
  int i;

  // terminate all hw threads
  for (i=0; i<hw_number_of_threads_r;i++){

       while (!cyg_thread_delete(hw_thread_r_handle[i]))
                cyg_thread_release(hw_thread_r_handle[i]);
  }
 
}



/**
   creates resample HW thread (and delete old hw threads)

  @param number_of_threads: number of hw threads for resampling thread
  @param reconos_slots: reconos slots, where the resampling hw threads are connected to
*/
void set_resample_hw ( unsigned int number_of_threads, unsigned int *  reconos_slots  ){

         
     int i;

     // terminate old sw threads if needed
     if (hw_number_of_threads_r > 0){

         resample_hw_delete();

         // free all variables
         for (i=0; i<hw_number_of_threads_r; i++){
 
             free(hw_thread_r_stack[i]);
         }

          free(hw_thread_r);
          free(hw_thread_r_stack);
          free(hw_thread_r_handle);
          free(res_r);
          free(hw_thread_r_attr);
          free(information_r);
     }

     // set number of hw threads
     hw_number_of_threads_r = number_of_threads;

     if (number_of_threads < 1) return;

     // set information
     information_r = (information_struct_r *) malloc ( sizeof(information_struct_r));

     information_r[0].particles = particles;
     information_r[0].indexes = indexes;
     information_r[0].N = N;
     information_r[0].particle_size = sizeof(particle);
     information_r[0].block_size = block_size;
     information_r[0].U = U;

     // create hw thread stacks 
     hw_thread_r_stack = (char **) malloc (number_of_threads * sizeof (char *));
     for (i=0; i<number_of_threads; i++){

           hw_thread_r_stack[i] = (char *) malloc (STACK_SIZE * sizeof(char));
     }     
 
     // create hw handles
     hw_thread_r_handle = (cyg_handle_t *) malloc (number_of_threads * sizeof(cyg_handle_t));

     // ressources
     res_r = (reconos_res_t *) malloc (3 * sizeof(reconos_res_t));
     
     res_r[0].ptr  =  mb_resampling_handle;
     res_r[0].type =  CYG_MBOX_HANDLE_T ;
     res_r[1].ptr  =  mb_resampling_done_handle;
     res_r[1].type =  CYG_MBOX_HANDLE_T ;
     res_r[2].ptr  =  hw_mb_resampling_measurement_handle;
     res_r[2].type =  CYG_MBOX_HANDLE_T ;

     // attributes for hw threads
     hw_thread_r_attr = malloc (number_of_threads * sizeof(rthread_attr_t));

     // create hw threads variables
     hw_thread_r = (cyg_thread *) malloc (number_of_threads * sizeof(cyg_thread));

     for (i=0; i<number_of_threads; i++){

        // set attributes
        rthread_attr_init(&hw_thread_r_attr[i]);
        // set slot number
        rthread_attr_setslotnum(&hw_thread_r_attr[i], reconos_slots[i]);
        // add ressources
        rthread_attr_setresources(&hw_thread_r_attr[i], res_r, 3); 

        //diag_printf("\n--> hw resampling (%d, slot %d) dcr address: %d", i, reconos_slots[i], hw_thread_r_attr[i].dcr_base_addr);

        // create hw resampling thread
        reconos_hwthread_create(
	      (cyg_addrword_t) PRIO_HW, // priority
              &hw_thread_r_attr[i], // attributes
              (cyg_addrword_t) &information_r[0] , // entry data
              "HW_RESAMPLING",         // thread name 
               hw_thread_r_stack[i],   // stack
               STACK_SIZE,             // stack size 
               &hw_thread_r_handle[i], // thread handle
               &hw_thread_r[i]         // thread object
        );
       
          
       // resume threads
       cyg_thread_resume(hw_thread_r_handle[i]);
     }
}

#endif



