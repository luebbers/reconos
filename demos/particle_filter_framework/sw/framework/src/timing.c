#include <time.h>
#include <limits.h>
#include "../header/timing.h"

#include <xparameters.h>
#include <stdio.h>
#include <xio_dcr.h>


/**
 * gets dcr timebase value
 *
 * @return dcr timebase value
 */
timing_t gettime(  ){


  timing_t ret;
  //ret = XIo_DcrIn((unsigned int) 65);
//#ifndef NO_VGA_FRAMEBUFFER
//  ret = XIo_DcrIn((unsigned int) 65);
//#else
// ret = XIo_DcrIn((unsigned int) 5);
   ret = XIo_DcrIn((unsigned int) 33);
//#endif
  return ret;
}


/**
 * calculates difference between two time points
 *
 * @param start: first time point
 * @param stop: second time point
 *
 * @return difference between two time points
 */
timing_t calc_timediff( timing_t start, timing_t stop )
{

    if ( start <= stop ) {
        return ( stop - start );
    } else {
        return ( UINT_MAX - start + stop ); 
    }
}
