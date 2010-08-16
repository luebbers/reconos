#ifndef __TIMING_H__
#define __TIMING_H__

#include "communication.h"

/*! \file timing.h 
 * \brief used for time measurements
 */

// NOTE: We can only time up to 42.9 seconds (32 bits @ 100 MHz) on eCos!

/**
 * variable type of a time point
 */
typedef unsigned int timing_t;

/**
 * gets system time
 *
 * @return system time
 */
timing_t gettime( void  );

/**
 * calculates difference between two time points
 *
 * @param start: first time point
 * @param stop: second time point
 *
 * @return difference between two time points
 */
timing_t calc_timediff( timing_t start, timing_t stop );

#endif                          // __TIMING_H__
