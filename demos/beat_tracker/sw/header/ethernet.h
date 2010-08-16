#ifndef __ETHERNET_H__
#define __ETHERNET_H__

#include "config.h"
#include "../framework/header/particle_filter.h"


/*! \file ethernet.h 
 * \brief uses ethernet to establish a connection and to receive frames
 */



//! semaphores
cyg_sem_t *sem_read_new_frame_start, *sem_read_new_frame_stop;


/**
	establishes connection to ethernet

	@param port: port number for videotransfer
	@param region: pointer to input region array
	@return returns '0' if connection is established, else '1'
*/
int establish_connection(int port, int * region);


/**
	writes next sound frame to specific ram
	@param input: input buffer
	@param length: buffer length
*/
void receive_sound_frame( char * input, int length );


/**
	sends next sound frame back to pc
	@param output: input buffer
	@param length: buffer length	
*/
void send_sound_frame( char * output, int length  );





#endif                          //__ETHERNET_H__
