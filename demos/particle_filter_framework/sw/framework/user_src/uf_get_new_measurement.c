#include "../header/particle_filter.h"
#include "../../header/ethernet.h"
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdlib.h>
#include <stdio.h>

int my_frame_counter = 0;

/**
    get new measurement
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  !!!!!  U S E R    F U N C T I O N  !!!!!
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

*/
void get_new_measurement(void){

  if (my_frame_counter > 0){

     // 1) reset histogram box image
     reset_hsvImage();  

     // 2) start thread for reading new frame
     cyg_semaphore_post(sem_read_new_frame_start);
  }
 
  my_frame_counter++;
}

