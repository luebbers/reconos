#include "../header/particle_filter.h"
#include "../../header/config.h"
#include "../../header/frame_size.h"
#include <stdlib.h>


//! if this is defined then TRANS_X_STD and TRANS_Y_STD are denominators
//#define DIVISION 1

//! standard deviations for gaussian sampling in transition model
#define TRANS_X_STD 3 // good: 1 (DIVISION)

//! standard deviations for gaussian sampling in transition model
#define TRANS_Y_STD 2 // good: 2 (DIVISION)

//! standard deviations for gaussian sampling in transition model
#define TRANS_S_STD 1000 // good: 1000

//! autoregressive dynamics parameters for transition model
#define A1 2

//! autoregressive dynamics parameters for transition model
#define A2 -1

//! autoregressive dynamics parameters for transition model
#define B0  1



/**
  calculates a pseudo gaussian value in a specific range
 
  @param range: range of pseudo gaussian function
  @return pseudo gaussian value
*/
int get_pseudo_gaussian_xy (int range){

  int ret;
  
  ret = (rand() / (RAND_MAX / ( 3 * range)));


  ////////////////////////////////////////////////////
  //                                                //  
  //  1/3 has the value 0, the rest is distributed  //
  //                                                //  
  //                                                //
  //             -0,125  ---- +0,125                //
  //             -0,125  ---- +0,125                //
  //            -0.25  -------- +0,25               //
  //         -0,5  ---------------- +0,5            //
  //                                                //
  ////////////////////////////////////////////////////


  if (ret > (2 * range) - 1) return 0;

  
  // layer 1 bottom layer ( -0.5 <-> +0.5 )
  ret -= (range/2);

  // layer 2 layer        ( -0.25 <-> +0.25 )
  if (ret > range-1) ret -= (( 5 * range) / 4);

  // layer 3 layer        ( -0.125 <-> +0.125 )
  if (ret > ((3 * range) / 4) - 1) ret -= (( 7 * range) / 8);

  // layer 4 top layer    ( -0.125 <-> +0.125 )
  if (ret > (range / 2) - 1) ret -= (( 5 * range) / 8);
  
  // return pseudo gaussian value
  return  ret;
}




/**
  calculates a pseudo gaussian value in a specific range for scaling
 
  @param range: range of pseudo gaussian function
  @return pseudo gaussian value
*/
int get_pseudo_gaussian_s (int range){

  int ret;
  
  ret = (rand() / (RAND_MAX / ( 4 * range)));


  ////////////////////////////////////////////////////
  //                                                //  
  //  1/2 has the value 0, the rest is distributed  //
  //                                                //  
  //                                                //
  //             -0,125  ---- +0,125                //
  //             -0,125  ---- +0,125                //
  //            -0.25  -------- +0,25               //
  //         -0,5  ---------------- +0,5            //
  //                                                //
  ////////////////////////////////////////////////////


  if (ret > (2 * range) - 1) return 0;

  
  // layer 1 bottom layer ( -0.5 <-> +0.5 )
  ret -= (range/2);

  // layer 2 layer        ( -0.25 <-> +0.25 )
  if (ret > range-1) ret -= (( 5 * range) / 4);

  // layer 3 layer        ( -0.125 <-> +0.125 )
  if (ret > ((3 * range) / 4) - 1) ret -= (( 7 * range) / 8);

  // layer 4 top layer    ( -0.125 <-> +0.125 )
  if (ret > (range / 2) - 1) ret -= (( 5 * range) / 8);
  
  // return pseudo gaussian value
  return  ret;
}




/**
  calculates a pseudo gaussian value in a specific range for scaling
 
  @param range: range of pseudo gaussian function
  @return pseudo gaussian value
*/
int get_pseudo_gaussian (int range){

  int ret,t;
  
  t = range%2;
  ret = (rand() / (RAND_MAX / (range+t)));
  ret -= (range+t)/2;

  return ret;
}


/**
  calculates a pseudo gaussian value in a specific range for scaling
 
  @param range: range of pseudo gaussian function
  @return pseudo gaussian value
*/
int get_pseudo_gaussian_s2 (int range){

  int ret;
 
  ret = (rand() / (RAND_MAX / (range)));
  ret -= (range)/2;

  return ret;
}


/**
  calculates a pseudo gaussian value in a specific range for scaling
 
  @param range: range of pseudo gaussian function
  @return pseudo gaussian value
*/
int get_pseudo_gaussian_z (int range){

  //return get_pseudo_gaussian_xy(range);

  return get_pseudo_gaussian(range);
}





/**
  predicts the new state after a transition model for a given particle
  
  @param p a particle to be predicted
  @return Returns a new particle sampled based on <EM>p</EM>'s transition model
*/

void prediction( particle * p){

  int x, y, s;
  
  // sample new state using second-order autoregressive dynamics
 
  x  = A1 * (p->x  - p->x0)
     + A2 * (p->xp - p->x0)
#ifdef DIVISION
     + B0 * get_pseudo_gaussian_z (PF_GRANULARITY / TRANS_X_STD)
#else
     + B0 * get_pseudo_gaussian_z (PF_GRANULARITY * TRANS_X_STD)
#endif
     + p->x0;
  

  y  = A1 * (p->y  - p->y0)
     + A2 * (p->yp - p->y0)
#ifdef DIVISION
     + B0 * get_pseudo_gaussian_z (PF_GRANULARITY / TRANS_Y_STD)
#else
     + B0 * get_pseudo_gaussian_z (PF_GRANULARITY * TRANS_Y_STD)
#endif
     + p->y0;

  
  s  = A1 * (p->s  - PF_GRANULARITY)
     + A2 * (p->sp - PF_GRANULARITY)
     + B0 * get_pseudo_gaussian_s2 (PF_GRANULARITY / TRANS_S_STD)
     + PF_GRANULARITY;
  
  
  //s = PF_GRANULARITY;
  
  // set old values
  p->xp = p->x;
  p->yp = p->y;
  p->sp = p->s;


  // set new state
  p->x = MAX( 0, MIN( ((SIZE_X-1) * PF_GRANULARITY), x ) );
  p->y = MAX( 0, MIN( ((SIZE_Y-1) * PF_GRANULARITY), y ) );
  // 0.1 <= s <= 10.0
  p->s = MAX((PF_GRANULARITY / 10) , s );
  p->s = MIN(p->s, 10*PF_GRANULARITY);
  
  //p->s = 13584;
  
}

