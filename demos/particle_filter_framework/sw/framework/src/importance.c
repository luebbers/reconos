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

//debug
#include "../../header/frame_size.h"
#include "../../header/histogram.h"
#include "../../header/bgr2hsv.h"
#include "../../header/tft_screen.h"

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

//! needed for dynamic hw threads (i)
//pthread_t hw_thread_i_dynamic;
//pthread_attr_t * hw_thread_i_dynamic_swattr;
//rthread_attr_t * hw_thread_i_dynamic_hwattr;
hw_thread_node * hw_threads_i_dynamic = NULL;

//! ressources array for the importance hw thread
reconos_res_t * res_i, * res_i_dynamic = NULL;


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
information_struct_i * information_i, * information_i_dynamic = NULL;

//! number of sw threads
int sw_number_of_threads_i = 0;

//! number of hw threads (static)
int hw_number_of_threads_i = 0;

//! number of hw threads (dynamic)
int hw_number_of_threads_i_dynamic = 0;

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
                  //diag_printf("\n[Importance] received message %d.", message);
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

#ifdef USE_CACHE  
           XCache_EnableDCache( 0xF0000000 );
#endif    
      

      for (i=from; i<=to; i++){
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////    T E S T    T E S T    T E S T    T E S T    T E S T    T E S T    T E S T    T E S T    T E S T   ///
/////////////////////////////////////////////////////////////////////////////////////////////////////////////    
	    /*observation o;
            int j;
            int sum = 0;
            int sum2 = 0;
            //observations[i].n = 0;    observations[i].dummy = 0;
            //diag_printf("\n\nHW: Observation No. %d:\n", i);
            //for (j=0; j<110; j++) {

               //if ((j % 10) == 0) diag_printf("\n");
               //diag_printf("%d ", observations[i].histo[j]);
            //   sum += observations[i].histo[j];
            //   if (j> 99) sum2 += observations[i].histo[j];
            //}

            //diag_printf("\n1st Sum: %d, \tgray pixel sum: %d", sum, sum2);
            //diag_printf("\nhisto->n: %d \thisto->dummy: %d", observations[i].n, observations[i].dummy);

            extract_observation(&particles[i], &o);
            //sum = 0; sum2 = 0;
            //diag_printf("\n\nSW: Observation No. %d:\n", i);
            //for (j=0; j<110; j++) {

               //if ((j % 10) == 0) diag_printf("\n");
               //diag_printf("%d ", o.histo[j]);
               //sum += o.histo[j];
               //if (j> 99) sum2 += o.histo[j];
            //}
            //diag_printf("\n2nd Sum: %d, \tgray pixel sum: %d", sum, sum2);

            //diag_printf("\n\nHW/SW-Comparison");
            sum = 0;
            int failure = 0;

            for (j=0; j<110; j++) {

               //if ((j % 10) == 0) diag_printf("\n");
               //diag_printf("%d ", (observations[i].histo[j] - o.histo[j]));
               sum += (observations[i].histo[j] - o.histo[j]);
               if (observations[i].histo[j] != o.histo[j]) {
                     //diag_printf("\n##################Difference between SW and HW for particle %d, histogram(%d). hw: %d <-> sw: %d", i, j, o.histo[j], observations[i].histo[j]); 
                     failure = 1;}
            }
            //diag_printf("\nsum: %d", sum);
	    
//////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        //if (observations[i].histo[106] != particles[i].width ){
        if (failure == 1){
            diag_printf("\nPARTICLE NO. %d    (particle size = %d, particle address = %d)\n############################################################", i, sizeof(particles[i]), (int) &particles[i]);
            particle * p = &particles[i];
            int x1 = (p->x - (p->s * (( p->width - 1) / 2))) / PF_GRANULARITY;
            int x2 = (p->x + (p->s * (( p->width - 1) / 2))) / PF_GRANULARITY;
            int y1 = (p->y - (p->s * (( p->height - 1) / 2))) / PF_GRANULARITY;
	    int y2 = (p->y + (p->s * (( p->height - 1) / 2))) / PF_GRANULARITY;
            if (x1<0) { x1 = 0; }
            if (y1<0) { y1 = 0; }
            if (x2>SIZE_X-1) { x2 = SIZE_X - 1; }
            if (y2>SIZE_Y-2) { y2 = SIZE_Y - 1;} 
            diag_printf("\nSW: x: %d \ty: %d \tscale: %d \twidth: %d \theight: %d \tx1: %d \tx2: %d \ty1: %d \ty2: %d",
            (p->x / PF_GRANULARITY), (p->y / PF_GRANULARITY), p->s, p->width, p->height, x1, x2, y1, y2);
            diag_printf("\nHW: x: %d \ty: %d \tscale: %d \twidth: %d \theight: %d \tx1: %d \tx2: %d \ty1: %d \ty2: %d",
            (observations[i].histo[103] / PF_GRANULARITY), (observations[i].histo[104] / PF_GRANULARITY), 
             observations[i].histo[105], observations[i].histo[106], observations[i].histo[107], observations[i].histo[108], 
             observations[i].histo[109], observations[i].n, observations[i].dummy);

            diag_printf("\n\nHW: Observation No. %d:\n", i);
            sum = 0;
            for (j=0; j<110; j++) {
       
               if ((j % 10) == 0) diag_printf("\n");
               diag_printf("%d ", observations[i].histo[j]);
               if (j<103) sum += observations[i].histo[j];
            }
            diag_printf("\nSum: %d", sum);

            sum = 0;
            diag_printf("\n\nSW: Observation No. %d:\n", i);
            for (j=0; j<110; j++) {

               if ((j % 10) == 0) diag_printf("\n");
               diag_printf("%d ", o.histo[j]);
               if (j<110)sum += o.histo[j];
            }
            diag_printf("\nSum: %d", sum);

            sum = 0; sum2 = 0;
            diag_printf("\n\nHW/SW-Comparison");
            for (j=0; j<110; j++) {

               if ((j % 10) == 0) diag_printf("\n");
               diag_printf("%d ", (observations[i].histo[j] - o.histo[j]));
               if (j<110) sum += (observations[i].histo[j] - o.histo[j]);
               if (j<110){ 
                   if ((observations[i].histo[j] - o.histo[j]) > 0)
                       sum2 +=  (observations[i].histo[j] - o.histo[j]);
                   else
                      sum2 -=  (observations[i].histo[j] - o.histo[j]);}
            }
            diag_printf("\nSum: %d", sum);
            diag_printf("\n# Wrong Values: %d", sum2);

            diag_printf("\n------------------------------------------------------------------------------------------");
          }
            observations[i].n = 110; observations[i].dummy = 0;
	 /* */
//////////////////////////////////////////////////////////////////////////////////////////////////////////
             //diag_printf("\nparticle[%d].x = %d (old: %d)", i, particles[i].x, particles[i].xp);
             particles[i].w = likelihood (&observations[i], ref_data);
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
              //diag_printf("\n[Importance Thread No. %d] s %d geschickt", (int) thread_number, message);
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
     

          // create sw sampling threads
          cyg_thread_create(PRIO,                   // scheduling info (eg pri)  
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
 terminates and deletes all HW threads for Importance (static)
*/
void importance_hw_delete_static(void){

  int i;

  // terminate all hw threads
  for (i=0; i<hw_number_of_threads_i;i++){

       while (!cyg_thread_delete(hw_thread_i_handle[i]))
                cyg_thread_release(hw_thread_i_handle[i]);

  }
  
}



/**
   creates importance HW threads (and deletes 'old' HW threads) (static)

   @param number_of_threads: number of threads for importance step
   @param reconos_slots: pointer to array including the slot numbers, where the importance hw threads are connected with 

*/
void set_importance_hw_static (unsigned int number_of_threads, unsigned int * reconos_slots){

     
     int i;

     // terminate old sw threads if needed
     if (hw_number_of_threads_i > 0){

       importance_hw_delete_static();

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

     //unsigned char * information_i_pos = (unsigned char*)0x01C00000;
     //diag_printf("information...");
     //memcpy((void*)information_i_pos, (void*)information_i, sizeof(information_struct_i));
     //diag_printf("\nimportance: information_struct = %d", (int)information_i);
     
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

          //diag_printf("\n--> hw importance (%d, slot %d) dcr address: %d", i, reconos_slots[i], 
          //            hw_thread_i_attr[i].dcr_base_addr);

          // create hw sampling thread
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




/**
 terminates and deletes all HW threads for Importance (dynamic)
*/
void importance_hw_delete_dynamic( int number)
{

  int i;
  for (i = 0; i<number; i++)
  {
        cyg_mbox_tryput( hw_mb_importance_exit_handle[0], (void *) 1 );
  }  
}




/**
   creates importance HW threads (dynamic)

   @param number_of_threads: number of threads for importance step
   @param hw_circuit: hardware circuit of the thread
*/
void set_importance_hw_dynamic (unsigned int number_of_threads, reconos_circuit_t *  hw_circuit)
{
     
     int i;

     // terminate old sw threads if needed
     if (number_of_threads < 0 || number_of_threads == hw_number_of_threads_i_dynamic) 
     {
          return;
     } 
     else 
     {
          if (number_of_threads < hw_number_of_threads_i_dynamic)
          {
               // remove slots, which are not needed
               importance_hw_delete_dynamic(hw_number_of_threads_i_dynamic - number_of_threads);
               hw_number_of_threads_i_dynamic = number_of_threads;
               return;
          }
     }

     if (information_i_dynamic == NULL)
     {
        // set information
        information_i_dynamic = (information_struct_i *) malloc (sizeof(information_struct_i));
        information_i_dynamic[0].particles = particles;
        information_i_dynamic[0].number_of_particles = N;
        information_i_dynamic[0].particle_size = sizeof(particle);
        information_i_dynamic[0].block_size = block_size;
        information_i_dynamic[0].observation_size = sizeof(observation);
        information_i_dynamic[0].observations = observations;
        information_i_dynamic[0].ref_data = ref_data;
     }

     //diag_printf("\nimportance: information_struct = %d", (int)information_i);

     if (res_i_dynamic == NULL)
     {
        // set ressources
        res_i_dynamic = (reconos_res_t *) malloc (4 * sizeof(reconos_res_t));  
        res_i_dynamic[0].ptr  =  mb_importance_handle;
        res_i_dynamic[0].type =  CYG_MBOX_HANDLE_T ;
        res_i_dynamic[1].ptr  =  mb_importance_done_handle;
        res_i_dynamic[1].type =  CYG_MBOX_HANDLE_T ;
        res_i_dynamic[2].ptr  =  hw_mb_importance_measurement_handle;
        res_i_dynamic[2].type =  CYG_MBOX_HANDLE_T ;
        res_i_dynamic[3].ptr  =  hw_mb_importance_exit_handle;
        res_i_dynamic[3].type =  CYG_MBOX_HANDLE_T ;    
     }
     
     // create and resume hw importance threads in eCos
     for (i = 0; i < (number_of_threads - hw_number_of_threads_i_dynamic); i++)
     {

          hw_thread_node * new_node = malloc (sizeof(hw_thread_node));
          new_node->sw_attr = (pthread_attr_t *) malloc (sizeof(pthread_attr_t));
          new_node->hw_attr = (rthread_attr_t *) malloc (sizeof(rthread_attr_t));
     
          int ret = pthread_attr_init(new_node->sw_attr);
          //diag_printf("\nI: p_thread_attr_init = %d", ret);
          ret = pthread_attr_setstacksize(new_node->sw_attr, STACK_SIZE);
          //diag_printf("\nI: p_thread_attr_set_stacksize = %d", ret);
          ret = rthread_attr_init(new_node->hw_attr);
          //diag_printf("\nI: r_thread_attr_init = %d", ret);
          ret = rthread_attr_setcircuit(new_node->hw_attr, hw_circuit);
          //diag_printf("\nI: r_thread_set_circuit = %d", ret);
	  //rthread_attr_setstatesize(new_node->hw_attr, 16384);

          ret = rthread_attr_setresources(new_node->hw_attr, res_i_dynamic, 4);
          //diag_printf("\nI: r_thread_attr_setresources = %d", ret);

          ret = rthread_create(&(new_node->hw_thread), new_node->sw_attr, new_node->hw_attr, 
                 (void*)information_i_dynamic); 
          //diag_printf("\nI: r_thread_create = %d", ret);

          // insert node to list
          new_node->next = hw_threads_i_dynamic;
          hw_threads_i_dynamic = new_node;
     }

     // set number of hw threads
     hw_number_of_threads_i_dynamic = number_of_threads;
}



