/** @file
    definition of observation data
*/

#ifndef UF_OBSERVATION_H
#define UF_OBSERVATION_H

//////////////////////////////////
// U S E R   I N C L U D E     //
// IF NEEDED, INCLUDE STH.    //
///////////////////////////////


/////////////////////////////////
// END OF USER INCLUDE       ///
///////////////////////////////


/******************************* Structures **********************************/

//! size of an observation
#define OBSERVATION_LENGTH 128//2048//128


//! complex value
typedef struct complex_number{

	//! real component
	volatile int16 re;

	//! imaginary component
	volatile int16 im;
	
}complex_number;


//! USER SPECIFIC TYPEDEF of observation
typedef struct observation{

	//! results of fast fourier transformation
	complex_number fft[OBSERVATION_LENGTH];
	//! old likelihood value
	volatile int old_likelihood;
	//! true, if no tracking is needed (initial phase or particle not in interval)
	volatile int no_tracking_needed;
	
}observation; // here: byte array

#endif
