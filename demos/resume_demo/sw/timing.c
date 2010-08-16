///
/// \file timing.c
/// Implementation of timing functions.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#include <time.h>
#include <limits.h>
#include "timing.h"

#include <xparameters.h>


volatile unsigned int *const twcsr0 =
    ( unsigned int * ) XPAR_OPB_TIMEBASE_WDT_0_BASEADDR;
volatile unsigned int *const twcsr1 =
    ( unsigned int * ) XPAR_OPB_TIMEBASE_WDT_0_BASEADDR + 1;
volatile unsigned int *const tbr =
    ( unsigned int * ) XPAR_OPB_TIMEBASE_WDT_0_BASEADDR + 2;

// get system timer value
timing_t gettime(  )
{
    return *tbr;
}


// calculate difference between start and stop time
// and convert to milliseconds
timing_t calc_timediff_ms( timing_t start, timing_t stop )
{

    if ( start <= stop ) {
        return ( stop - start ) / 100000;
    } else {
        return ( UINT_MAX - start + stop ) / 100000;                           // Milliseconds
    }
}


// calculate difference between start and stop time
// in cycles
timing_t calc_timediff_cyc( timing_t start, timing_t stop )
{

    if ( start <= stop ) {
        return ( stop - start );
    } else {
        return ( UINT_MAX - start + stop );
    }
}
