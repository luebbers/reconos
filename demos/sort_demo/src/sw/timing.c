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

#ifdef USE_ECOS
#include <xparameters.h>
#endif

#ifdef XPAR_DCR_TIMEBASE_0_DCR_BASEADDR
    #define USE_DCR_TIMEBASE
    #if XPAR_DCR_TIMEBASE_0_DCR_BASEADDR > 1024
        #include <xil_io.h>
        #define DCR_READ(s, reg)            Xil_In32(s + (reg*4))
        #define DCR_WRITE(s, reg, value)    Xil_Out32(s + (reg*4), value)
    #else
        #include <xio_dcr.h>
        #define DCR_READ(s, reg)            XIo_DcrIn(s + reg)
        #define DCR_WRITE(s, reg, value)    XIo_DcrOut(s + reg, value)
    #endif
#endif


#ifdef USE_ECOS
#ifndef USE_DCR_TIMEBASE
volatile unsigned int *const twcsr0 =
    ( unsigned int * ) XPAR_OPB_TIMEBASE_WDT_0_BASEADDR;
volatile unsigned int *const twcsr1 =
    ( unsigned int * ) XPAR_OPB_TIMEBASE_WDT_0_BASEADDR + 1;
volatile unsigned int *const tbr =
    ( unsigned int * ) XPAR_OPB_TIMEBASE_WDT_0_BASEADDR + 2;
#endif
#endif

// get system timer value
timing_t gettime(  )
{

#ifdef USE_ECOS
    #ifdef USE_DCR_TIMEBASE
        return DCR_READ(XPAR_DCR_TIMEBASE_0_DCR_BASEADDR, 1);
    #else
        return *tbr;
    #endif // USE_DCR_TIMEBASE
#else
    return clock(  );
#endif
}



// calculate difference between start and stop time
// and convert to milliseconds
timing_t calc_timediff_ms( timing_t start, timing_t stop )
{

    if ( start <= stop ) {
#ifdef USE_ECOS
        return ( stop - start ) / 100000;
#else
        return ( stop - start ) / ( CLOCKS_PER_SEC / 1000 );
#endif
    } else {
#ifdef USE_ECOS
        return ( UINT_MAX - start + stop ) / 100000;                           // Milliseconds
#else
        return ( ULONG_MAX - start + stop ) / ( CLOCKS_PER_SEC / 1000 );       // Milliseconds
#endif
    }
}
