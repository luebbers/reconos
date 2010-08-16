/*! \file config.h 
 * \brief offers configuration constants
 */
#include <stdio.h>
#include <stdlib.h>
#ifndef SEND_VIDEO_FROM_PC
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <reconos/reconos.h>
#endif

#ifndef __CONFIG_H__
#define __CONFIG_H__

//typedef int reconos_circuit_t;

//! defines, if cache will be used
#define USE_CACHE 1

//! no ethernet needed
//#define NO_ETHERNET 1

//! granularity of the weights as fixed point representation (= potention of 2)
#define GRANULARITY 16384

//! defines if video is stored in main memory (for 512 MB RAM, 448 MB RAM can be used to store max 224 Frames)
#define STORE_VIDEO 1

//! defines maximum number of frames, which can be stored into Main Memory (without any compression)
#define MAX_FRAMES 20 //20 // 20 for 64 mb  // 220 for 512 MB RAM

//! define this if a VGA Framebuffer is not used
#define NO_VGA_FRAMEBUFFER 1

//! thresholds for reconfiguration
#define RECONF_THRESHOLD_1 150000//130000//24576
#define RECONF_THRESHOLD_2 160000
#define RECONF_THRESHOLD_3 155000
#define RECONF_THRESHOLD_4 135000//140000

//! parameter arrays
int * parameter_s, * parameter_o;

//! reconfiguration mode
int reconf_mode_observation_on;
int reconf_mode_observation_last_slot_on;

//! number of sortings (sort demo)
int old_number_of_sortings;

/*-***************************** image definitions *****************************/

//! maximal value of a RGB component
#define MAX_COLOR_VALUE 255


//!  hsv value structure
typedef struct hsv_value{
  //! hue component
  int h; 
  //! saturation component
  int s; 
  //! value component
  int v;
} hsv_value;


#ifndef SEND_VIDEO_FROM_PC

//!  hw thread node for dynamic hw threads
typedef struct hw_thread_node{
  //! hw thread
  pthread_t hw_thread;
  //! sw attributes
  pthread_attr_t * sw_attr;
  //! hw attributes
  rthread_attr_t * hw_attr;
  //! next dynamic hw thread node
  struct hw_thread_node * next;
} hw_thread_node;


//!  hw thread node for dynamic hw threads
typedef struct hw_thread_node2{
  //! hw thread
  cyg_thread * hw_thread;
  //! hw thread handle
  cyg_handle_t * hw_thread_handle;
  //! hw thread stack
  char * hw_thread_stack;
  //! hw attributes
  rthread_attr_t * hw_attr;
  //! next dynamic hw thread node
  struct hw_thread_node2 * next;
} hw_thread_node2;

#endif



/*-***************************** histogram definitions  *****************************/
// see particle filter object tracking by Rob Hess (see: http://web.engr.oregonstate.edu/~hess)

//! number of H-bins of HSV in histogram
#define NH 10
//! number of S-bins of HSV in histogram
#define NS 10
//! number of V-bins of HSV in histogram
#define NV 10

//! maximal H-value of HSV value
#define H_MAX 360
//! maximal S-value of HSV value
#define S_MAX 100
//! maximal V-value of HSV value
#define V_MAX 100

//! low thresholds on saturation value for histogramming
#define S_THRESH 10
//! low thresholds on V-value for histogramming
#define V_THRESH 20


//! maximal H-value of HSV value
#define H_MAX_2 180
//! maximal S-value of HSV value
#define S_MAX_2 255
//! maximal V-value of HSV value
#define V_MAX_2 255

//! low thresholds on saturation value for histogramming
#define S_THRESH_2 25
//! low thresholds on V-value for histogramming
#define V_THRESH_2 50

#define DUMMIES 17


/**
   An HSV histogram represented by NH * NS + NV bins.  Pixels with saturation
   and value greater than S_THRESH and V_THRESH fill the first NH * NS bins.
   Other, "colorless" pixels fill the last NV value-only bins.
*/
typedef struct histogram {
  //! histogram array
  int histo[NH*NS + NV];  
  //! length of histogram array
  int n;
  int dummy[DUMMIES];             
} histogram;




/*-***************************** Defs and macros *****************************/

#ifndef TRUE
//! defines integer value for true
#define TRUE 1
#endif
#ifndef FALSE
//! defines integer value for false
#define FALSE 0
#endif
#ifndef MIN
//! defines min-function with two values
#define MIN(x,y) ( ( x < y )? x : y )
#endif
#ifndef MAX
//! defines max-function with two values
#define MAX(x,y) ( ( x > y )? x : y )
#endif
#ifndef ABS
//! defines absolute-value-function
#define ABS(x) ( ( x < 0 )? -x : x )
#endif



#endif
