/** @file
    header file for inter-thread communication
*/
#ifndef ONLYPC
//#define ONLYPC 1
#endif

#ifndef COMMUNICATION_H
#define COMMUNICATION_H


#ifndef ONLYPC
#include <cyg/infra/cyg_type.h>
#include <cyg/infra/diag.h>
#include <cyg/kernel/kapi.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#endif

// T H R E A D S   F O R   I N T E R - T H R E A D   C O M M U N I C A T I O N

//! sw threads for inter-thread communication
//cyg_thread sw_thread_user_thread, sw_thread_sampling_switch, sw_thread_importance_switch, sw_thread_resampling_switch;

//! Stack for the sw threads for inter-thread communication
//char sw_thread_stack[STACK_SIZE], ;

//! thread handles to sw threads for inter-thread communication
//cyg_handle_t sw_thread_handle;

//! defines integer values for SW
#define SW 0
//! defines integer values for HW
#define HW 1
//! defines integer values for true
#define FALSE 0
//! defines integer values for tfalse
#define TRUE  1

//! defines priority for sw threads
#define PRIO 15
//! defines priority for hw threads
#define PRIO_HW 14


#ifndef ONLYPC
//! message boxes  for samling, importance and resampling (incoming and outgoing)
cyg_mbox *mb_sampling,        *mb_sampling_done,   *mb_importance,  
         *mb_importance_done, *mb_resampling,      *mb_resampling_done;

//! handles for message boxes for samling, importance and resampling (incoming and outgoing)
cyg_handle_t *mb_sampling_handle,   *mb_sampling_done_handle,
             *mb_importance_handle, *mb_importance_done_handle,
             *mb_resampling_handle, *mb_resampling_done_handle;

//! message boxes for time measurement
cyg_mbox *hw_mb_sampling_measurement,
         *hw_mb_observation_measurement,
         *hw_mb_importance_measurement,
         *hw_mb_resampling_measurement; 

//! handles for message boxes for time measurements for samling, importance and resampling 
cyg_handle_t *hw_mb_sampling_measurement_handle,
             *hw_mb_observation_measurement_handle,
             *hw_mb_importance_measurement_handle,
             *hw_mb_resampling_measurement_handle; 
#endif

#ifndef ONLYPC
/**
  creates sw thread for sampling switch. This thread puts Messages into sw or hw message boxes. 
*/
void create_preSampling_thread(void);


/**
  creates sw thread for resampling switch. This thread waits for all messages to arrive.
  Then normalizes the particle weights and it starts the user function iteration_done.
  When the user thread is finished, the messages are put into hw or sw message box for resampling.
*/
void create_preResampling_thread(void);



/**
  creates sw user thread. Here all particle data is available. So the particle weights get normalized,
  a output function is called and a new measurement is taken.
*/
void create_user_thread(void);


/**
  Returns TRUE, if all messages received, else FALSE

 @param messages: array containing FALSE, whenever a message is not received
 @param number: number of messages
 @return information, if every message is received
*/
int all_messages_received(int * messages, int number);
#endif

//! index type
typedef struct index_type{
  //! index of particle in particle array
  volatile int index;
  //! replication factpr
  volatile int replication;

} index_type;


#endif

