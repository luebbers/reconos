#include "../header/particle_filter.h"
#include "../../header/display.h"
#include "../../header/ethernet.h"
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdlib.h>
#include "../header/timing.h"
#include "../../header/tft_screen.h"

#include <reconos/reconos.h>
#include <reconos/resources.h>


#include "../../sort_demo/sort8k.h"


//#include "../../header/circuits.h"

//extern reconos_circuit_t hw_thread_o_circuit;
//extern reconos_circuit_t hw_thread_s_circuit;
int framecounter4 = 0;


/**
   user function called before resampling starts. No particles are processed in the filter steps.
   In this function the state can be estimated (using the particles p), a new reference data can
   be set (observations may be usefull) and the filter can be repartitioned using the 
   set_..._hw/sw functions.

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   @param p: pointer to particle array
   @param o: pointer to observation array
   @param ref: pointer to reference data
   @param number: number of particles / observations
*/
void iteration_done(particle * p, observation * o, observation * ref, int number){

#ifndef NO_VGA_FRAMEBUFFER
  //timing_t t_start = 0, t_stop = 0, t_result = 0;

     //t_start = gettime();

  // display all N particles
  display_particles( p, number);

  // best particle only
  display_best_particle( p);

    //t_stop = gettime();
    //t_result = calc_timediff(t_start, t_stop);
    //printf("\nUser Thread (Output): %d", t_result);
#endif

	// sorting demo
	//diag_printf("number of sortings: %d\n", (sort_counter - old_number_of_sortings));
	//old_number_of_sortings = sort_counter;


///////////////////////////////////////////////////////////////////////////////////////
//      R E C O N F I G U R A T I O N       S T A R T                                //
///////////////////////////////////////////////////////////////////////////////////////
        /*
	// 1) calculate number of pixels in block
        framecounter4++;
	if (framecounter4%50 == 0)
	{
		//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
		diag_printf("\n+ 14 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
		sort_assign_priority(14);
	} else
        {
		if (framecounter4%25 == 0)
		{
			//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			//diag_printf("\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
			diag_printf("\n+ 17 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
			//sort_assign_priority(17);
		}

        }
	
	int scaling = 0;
	int i;
	for (i=0; i<block_size; i++)
	{

		scaling += particles[i].s;
	}*/
	//diag_printf("\n/////////////////  SCALING FACTOR: %d   ////////////////", scaling);

	// 2) check if a threshold is passed
	/*if (reconf_mode_observation_on == TRUE)
	{
		//if (scaling < RECONF_THRESHOLD_1)
		if (scaling < RECONF_THRESHOLD_3)
		{
			//diag_printf("AAAAAAAAAAAAAAAAAAAAAAA         [HW SAMPLING ON]          AAAAAAAAAAAAAAAAAAAAAAAAA\n");
			diag_printf("\nAAAAAAAAAAAAAAAAAAAAAAA         [FREE FIRST SLOT]          AAAAAAAAAAAAAAAAAAAAAAAAA");
			// a) exit hw thread for observation
			//set_observe_hw_dynamic(1, &hw_thread_o_circuit, parameter_o, 2);
			set_observe_hw_dynamic(1, &hw_thread_o_circuit, parameter_o, 2);
			// b) start hw sampling threadS
			//set_sample_hw_dynamic(1, &hw_thread_s_circuit, parameter_s, 5);
			// c) start hw sorting demo
			set_sort8k_hw_dynamic (1);
			// d) set reconfiguration mode
			reconf_mode_observation_on = FALSE;
			reconf_mode_observation_last_slot_on = TRUE;
		}
		
	}
	else
	{
		if (reconf_mode_observation_last_slot_on == TRUE)
		{
			//if (scaling > RECONF_THRESHOLD_2)
			if (scaling < RECONF_THRESHOLD_4)
			{
				//diag_printf("BBBBBBBBBBBBBBBBBBBBBBB         [HW OBSERVATION ON]          BBBBBBBBBBBBBBBBBBBBBB\n");
				diag_printf("\nBBBBBBBBBBBBBBBBBBBBBBB         [FREE SECOND SLOT]          BBBBBBBBBBBBBBBBBBBBBB");
				// a) exit hw thread for sampling
				//set_sample_hw_dynamic(0, &hw_thread_s_circuit, parameter_s, 5);
				// b) start hw observation thread
				set_observe_hw_dynamic(0, &hw_thread_o_circuit, parameter_o, 2);
				// c) start hw sorting demo
				set_sort8k_hw_dynamic (2);
				// d) set reconfiguration mode
				reconf_mode_observation_last_slot_on = FALSE;
				// e) start importance sw thread
				//set_importance_sw(1);
			}
		}
	}*/

///////////////////////////////////////////////////////////////////////////////////////
//      R E C O N F I G U R A T I O N        E N D                                   //
///////////////////////////////////////////////////////////////////////////////////////

#ifndef HWMEASURE
  /*diag_printf("\n[iteration_done.c]---------delay...");
  cyg_thread_delay(50);

  // 1) reset hsv image
  reset_hsvImage();  

  diag_printf("\n[iteration_done.c]---------wait for frame");

  // 2) start thread for reading new frame
  cyg_semaphore_post(sem_read_new_frame_start);*/

  // wait for semaphore, that last frame has been read
  cyg_semaphore_wait(sem_read_new_frame_stop);

  //diag_printf("\n[iteration_done.c]---------received frame");

  // switch framebuffer
  switch_framebuffer_on_screen();

  // reset observations input address
  set_observations_input(tft_editing.fb);
#endif

}
