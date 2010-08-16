///
/// \file timing.h
/// Timing functions.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#ifndef __TIMING_H__
#define __TIMING_H__

// NOTE: We can only time up to 42.9 seconds (32 bits @ 100 MHz) on eCos!

typedef unsigned int timing_t;

timing_t gettime(  );
timing_t calc_timediff_ms( timing_t start, timing_t stop );
timing_t calc_timediff_cyc( timing_t start, timing_t stop );

#endif                          // __TIMING_H__
