#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include <reconos/ecap.h>

// Application Header
#include "../header/config.h"


#ifndef NO_ETHERNET
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <network.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <xcache_l.h>

#include "../header/circuits.h"
#include "../header/ethernet.h"
#include "../header/bgr2hsv.h"
#include "../header/observation.h"
#include "../header/histogram.h"
#include "../header/frame_size.h"
#include "../header/display.h"
#include "../header/tft_screen.h"

// Particle Filter Framework Interface
#include "../framework/header/particle_filter.h"
#include "../framework/header/timing.h"
#include <math.h>

//#include "../sort_demo/sort8k.h"
//#include "../header/circuits.h"

//#include "../prm0_sampling_routed_partial.bit.h"
//#include "../prm0_observation_routed_partial.bit.h"
//#include "../prm1_sampling_routed_partial.bit.h"
//#include "../prm1_observation_routed_partial.bit.h"


/**
 * @mainpage
 *
 *
 * The 'Particle Filter Object Tracker' Application runs on a FPGA card and uses
 * the 'Particle Filter Framework' to track an object in a video using colour histograms.
 * <ul>
 * <li>For every filter step (sampling, importance, resampling) there can be multiple threads in SW and HW. </li>
 * <li>For every filter step there has to be at least one thread (in HW or in SW).</li>
 * <li>In every iteration step SW and HW threads can be added to or removed from a filter block. </li>
 * </ul>
 * Information about the specified particle filter:
 * <ul>
 * <li>A particle contains current and previous values of (x,y)-position and scale factor and estimates the next position and the next scale factor.</li>
 * <li>A observation is a HSV-histogramm, which differs between 110 possible values.</li>
 * <li>The Likelihood-function compares the HSV-histogram of the particle with the refrerene HSV-histogram of the initially selected object.</li>
 * <li>The prediction function uses second-order autoregressive dynamics to estimate the new position and scale factor.</li>
 * </ul>
 */



/*! \file object_tracker.c 
 * \brief SW program to track an object by a particle filter
 */


//! integer value for using soccer video (needed for testing)
#define SOCCER 1
//! integer value for using football video (needed for testing)
#define FOOTBALL 2
//! integer value for using hockey video (needed for testing)
#define HOCKEY 3

//! sw threads for the sir algorithm
cyg_thread sw_thread;

//! Stack for the sw thread
char sw_thread_stack[STACK_SIZE];

//! thread handle to sw thread
cyg_handle_t sw_thread_handle;

//! sw threads for read_new_frame sw thread
cyg_thread sw_thread_read_new_frame;

//! Stack for read_new_frame sw thread
char sw_thread_read_new_frame_stack[STACK_SIZE];

//! thread handle to read_new_frame sw thread
cyg_handle_t sw_thread_read_new_frame_handle;


//! sw threads for measuremnts
cyg_thread sw_measurement_thread;

//! Stack for the sw measurement thread
char sw_measurement_thread_stack[STACK_SIZE];

//! thread handle to sw measurement thread
cyg_handle_t sw_measurement_thread_handle;

//! sw threads for measuremnts (2nd thread)
cyg_thread sw_measurement_thread_2;

//! Stack for the sw measurement thread (2nd thread)
char sw_measurement_thread_2_stack[STACK_SIZE];

//! thread handle to sw measurement thread (2nd thread)
cyg_handle_t sw_measurement_thread_2_handle;

//! sw threads for measuremnts (3rd thread)
cyg_thread sw_measurement_thread_3;

//! Stack for the sw measurement thread (3rd thread)
char sw_measurement_thread_3_stack[STACK_SIZE];

//! thread handle to sw measurement thread (3rd thread)
cyg_handle_t sw_measurement_thread_3_handle;

//! sw threads for measuremnts (4th thread)
cyg_thread sw_measurement_thread_4;

//! Stack for the sw measurement thread (4th thread)
char sw_measurement_thread_4_stack[STACK_SIZE];

//! thread handle to sw measurement thread (4th thread)
cyg_handle_t sw_measurement_thread_4_handle;


//! sw threads for test thread
cyg_thread * sw_test_thread;

//! Stack for the sw test thread
char * sw_test_thread_stack;
//char sw_test_thread_stack[STACK_SIZE];

//! thread handle to sw test thread
cyg_handle_t * sw_test_thread_handle;


//! sw thread for histograms
cyg_thread sw_histogram_thread;

//! Stack for the sw histogram thread
char sw_histogram_thread_stack[STACK_SIZE];

//! thread handle to sw histogram thread
cyg_handle_t sw_histogram_thread_handle;


//! main pthread
pthread_t main_thread; 
pthread_attr_t main_thread_attr;

//! sw thread for histograms
cyg_thread sw_histogram_thread2;

//! Stack for the sw histogram thread
char sw_histogram_thread_stack2[STACK_SIZE];

//! thread handle to sw histogram thread
cyg_handle_t sw_histogram_thread_handle2;


//! hw thread for histograms
cyg_thread hw_histogram_thread;

//! Stack for the hw histogram thread
char hw_histogram_thread_stack[STACK_SIZE];

//! thread handle to hw histogram thread
cyg_handle_t hw_histogram_thread_handle;

//! resources hw thread for histograms
reconos_res_t hw_histogram_thread_res[2];

//! attributes for hw thread for histograms 
rthread_attr_t hw_histogram_thread_attr;

//! reference data
observation reference_data;

//! reconos slots
unsigned int * slots;

//! region information
int * region_information;

#ifdef STORE_VIDEO
//! framecounter
int framecounter;
#endif


// hardware thread
/*cyg_thread hwthread_sorter;
rthread_attr_t hwthread_sorter_attr;
cyg_handle_t hwthread_sorter_handle;
char hwthread_sorter_stack[STACK_SIZE];
reconos_res_t hwthread_sorter_resources[3] = { {&mb_importance_handle, CYG_MBOX_HANDLE_T},
  {&mb_importance_done_handle, CYG_MBOX_HANDLE_T},
  {&hw_mb_importance_measurement_handle, CYG_MBOX_HANDLE_T}
};*/


/*
// bitstreams and circuits
// sampling
reconos_bitstream_t sampling_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_sampling_routed_partial_bit,
    .size     = PRM0_SAMPLING_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm0_sampling_routed_partial.bit"
};

reconos_bitstream_t sampling_bitstream_1 = {
    .slot_num = 1,
    .data     = prm1_sampling_routed_partial_bit,
    .size     = PRM1_SAMPLING_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm1_sampling_routed_partial.bit"
};

reconos_circuit_t hw_thread_s_circuit = {
    .name     = "SAMPLING",
//    .bitstreams = {&sampling_bitstream_0, &sampling_bitstream_1},
//    .num_bitstreams = 2
    .bitstreams = {&sampling_bitstream_0},
    .num_bitstreams = 1
};


// bitstreams and circuits
// sampling
reconos_bitstream_t observation_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_observation_routed_partial_bit,
    .size     = PRM0_OBSERVATION_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm0_observation_routed_partial.bit"
};

reconos_bitstream_t observation_bitstream_1 = {
    .slot_num = 1,
    .data     = prm1_observation_routed_partial_bit,
    .size     = PRM1_OBSERVATION_ROUTED_PARTIAL_BIT_SIZE,
    .filename = "prm1_observation_routed_partial.bit"
};

reconos_circuit_t hw_thread_o_circuit = {
    .name     = "OBSERVATION",
//    .bitstreams = {&observation_bitstream_0, &observation_bitstream_1},
//    .num_bitstreams = 2
    .bitstreams = {&observation_bitstream_0},
    .num_bitstreams = 1
};*/



/**
   prints histogram to screen

  @param h: pointer to histogram
*/
void print_histogram2 (histogram * h){

    int i, j, k = 0;
    printf("\nREFERENCE  HISTOGRAM:\n");
    /*for (i=0; i<110; i++){
       printf("\n%d", h->histo[i]);
       if (h->histo[i] == 0) k++;
    }*/
    for (i=0; i<10; i++)
        for (j=0; j<10; j++){

        printf("\n%d", h->histo[(j*10)+i]);
        if (h->histo[(j*10)+i] == 0) k++;
    }

    for (i=100; i<110; i++){

        printf("\n%d", h->histo[i]);
        if (h->histo[i] == 0) k++;
    }
    printf("\n\nNumber of Zeros: %d\n\n", k);
}

/**
  test thread
  @param data: input/init data for sw thread
*/
void test_thread(cyg_addrword_t data){


}


/**
 * This SW thread will create the particle filter, receive the object information, calculate the reference histogram and will start the Particle Filter Object Tracker.
 *
 * @param data: entry data for thread (e.g. an address)
 */
//void main_function(cyg_addrword_t data) {
void * main_function(void * data) {

    
    int tmp = 1;

    region_information = (int *) malloc (4 * sizeof(int));

     // create particles
    create_particle_filter(100, 10); 

    /*slots = (int *) malloc (6 * sizeof(int));
    slots[0] = 0;
    slots[1] = 1;
    slots[2] = 2;
    slots[3] = 3;
    slots[4] = 4;
    slots[5] = 5;
    set_importance_hw_static(1, &slots[0]);*/

    /*rthread_attr_init(&hwthread_sorter_attr);
    rthread_attr_setslotnum(&hwthread_sorter_attr, 0);
    rthread_attr_setresources(&hwthread_sorter_attr, hwthread_sorter_resources, 3);
    reconos_hwthread_create( 15,                                               // priority
                             &hwthread_sorter_attr,                             // hardware thread attributes
                             0,                                                // entry data (not needed)
                             "MT_HW_SORT",                                     // thread name
                             hwthread_sorter_stack,                            // stack
                             STACK_SIZE,                                       // stack size
                             &hwthread_sorter_handle,                          // thread handle
                             &hwthread_sorter                                  // thread object
    );
    cyg_thread_resume( hwthread_sorter_handle );*/
    
    //cyg_thread_delay(50);

#ifndef NO_ETHERNET
    init_all_network_interfaces();
    if(!eth0_up){
		printf("failed to initialize eth0\naborting\n");
		return NULL;
    }
    else{
		printf(" eth0 up\n");
    }

    diag_printf( "initializing ECAP interface..." );
    ecap_init();
    diag_printf( "done\n" );

    // establish connection
    while (tmp == 1){
         tmp = establish_connection(6666, region_information);
    }
#endif


    // start read_new_frame 
    cyg_semaphore_post(sem_read_new_frame_start);

    srand(1);

    // set region information for equal time measurements

   #define VIDEO 1
    
   printf("\n#################################################");
   printf("\n#################################################");
      #ifdef VIDEO    
      #if VIDEO==1
       printf("\n##########  S O C C E R   V I D E O  ############");
       region_information[0] = 286;
       region_information[1] = 247;
       region_information[2] = 117;
       region_information[3] = 171;
      #else
      #if VIDEO==2
       printf("\n########  F O O T B A L L   V I D E O  ##########");
       region_information[0] = 255;
       region_information[1] = 252;
       region_information[2] =  23;
       region_information[3] =  41;
      #else
      #if VIDEO==3
       printf("\n##########  H O C K E Y   V I D E O  ############");
       region_information[0] = 152;
       region_information[1] =  95;
       region_information[2] =  19;
       region_information[3] =  39;
      #else
      #if VIDEO==4
       printf("\n##########  H O C K E Y   V I D E O (FULL PICTURE) ############");
       region_information[0] = 159;
       region_information[1] = 119;
       region_information[2] = 320;
       region_information[3] = 240;
      #endif
      #endif
      #endif
      #endif
      #else
       printf("\n######  N O   V I D E O   D E F I N E D  ########");

      #endif
    printf("\n#################################################");
    printf("\n#################################################\n");
    
    // init particles
    init_particles(region_information, 4);


    // Output Object Region
    printf("\n\nx0 = %d\ny0 = %d\nwidth = %d\nheight = %d\n\n", region_information[0], region_information[1], region_information[2], region_information[3]);
    
    particle p;
    p.x = region_information[0]*PF_GRANULARITY;
    p.y = region_information[1]*PF_GRANULARITY;
    p.x0 = p.x;
    p.y0 = p.y;
    p.xp = p.x;
    p.yp = p.y;
    p.s = PF_GRANULARITY;
    p.sp = p.s;
    p.width = region_information[2];
    p.height = region_information[3]; 

    // get reference data
    get_reference_data(&p, &reference_data);

    init_reference_data (&reference_data);

    print_histogram(&reference_data);
    //print_histogram2(&reference_data);

#ifdef STORE_VIDEO
    int i;
    printf("\n\nThe first %d Frames will be stored into Main Memory. Again this will take some time.\n", (int)MAX_FRAMES);

    
    // load first frames
    for(i=0; i<MAX_FRAMES-1; i++){

	  //switch_framebuffer();
	    read_frame();
    }

    printf("\nFinished: The first %d Frames are stored in the Main Memory.\n", (int)MAX_FRAMES);
#endif

       
    parameter_s = (int *) malloc (5 * sizeof(int));
    parameter_s[0] = SIZE_X;
    parameter_s[1] = SIZE_Y;
    parameter_s[2] = 16384; // GRANULARITY / TRANS_STD_X
    parameter_s[3] = 8192;  // GRANULARITY / TRANS_STD_Y
    parameter_s[4] = 16;    // GRANULARITY / TRANS_STD_S

    parameter_o = (int *) malloc (2 * sizeof(int));
    parameter_o[0] = SIZE_X;
    parameter_o[1] = SIZE_Y;

    slots = (int *) malloc (6 * sizeof(int));
    slots[0] = 0;
    slots[1] = 1;
    slots[2] = 2;
    slots[3] = 3;
    slots[4] = 4;
    slots[5] = 5;


    // create sampling, importance, resampling thread

   printf("\n#################################################");
   printf("\n#################################################");
   #ifdef PARTITIONING
    #if PARTITIONING==1
    printf("\n######   P A R T I T I O N I N G    S W   #######");
    set_sample_sw(1);
    set_observe_sw(1);
    set_importance_sw(1);
    set_resample_sw(1);
    #else
    #if PARTITIONING==2
    printf("\n####   P A R T I T I O N I N G    H W  I   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_importance_sw(1);
    set_importance_hw_static(1, &slots[2]);
    set_resample_sw(1);   
    #else
    #if PARTITIONING==3
    printf("\n####   P A R T I T I O N I N G    H W   II   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_importance_sw(1);
    set_importance_hw_static(2, &slots[2]);
    set_resample_sw(1); 
   #else
   #if PARTITIONING==4
    printf("\n####   P A R T I T I O N I N G    H W   O   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw_static(1, &slots[0], parameter_o, 2);
    set_importance_sw(1);
    set_resample_sw(1);
   #else
   #if PARTITIONING==5
    printf("\n####   P A R T I T I O N I N G    H W   OO   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw_static(1, &slots[0], parameter_o, 2);
    set_importance_sw(1);
    set_resample_sw(1);
   #else
   #if PARTITIONING==6
    printf("\n####   P A R T I T I O N I N G    H W   IO   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw_static(1, &slots[0], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw_static(1, &slots[2]);
    set_resample_sw(1);
   #else
   #if PARTITIONING==7
    printf("\n####   P A R T I T I O N I N G    H W   IIO   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw_static(2, &slots[0], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw_static(1, &slots[2]);
    set_resample_sw(1);
   #else
   #if PARTITIONING==8
    printf("\n####   P A R T I T I O N I N G    H W   IOO   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw_static(1, &slots[0], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw_static(2, &slots[2]);
    set_resample_sw(1);
   #else
   #if PARTITIONING==9
    printf("\n####   P A R T I T I O N I N G    H W   IIOO   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw_static(2, &slots[0], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw_static(2, &slots[2]);
    set_resample_sw(1);
   #endif
   #endif
   #endif
   #endif
   #endif
   #endif
   #endif
   #endif
   #endif
   #else
    //printf("\n#  N O  P A R T I T I O N I N G   D E F I N E D #");
    printf("\n####   P A R T I T I O N I N G    S W   O   #####");
    reconf_mode_observation_on = TRUE;
    reconf_mode_observation_last_slot_on = FALSE;

    // I. SAMPLING ////////////////////////////////////////
    set_sample_sw(1);
    //set_sample_hw_dynamic(1, &hw_thread_s_circuit, parameter_s, 5);

    // II. OBSERVATION ////////////////////////////////////
    //set_observe_sw(1);
    set_observe_hw_dynamic(2, &hw_thread_o_circuit, parameter_o, 2);
    //set_observe_hw_dynamic(2, &hw_thread_o_circuit, parameter_o, 2);
    //set_observe_hw_static(1, &slots[2], parameter_o, 2);

    // III. IMPORTANCE ////////////////////////////////////
    set_importance_sw(1);
    //set_importance_hw_dynamic(1, &hw_thread_i_circuit);
    //set_importance_hw_dynamic(2, &hw_thread_i_circuit);
    set_importance_hw_static(1, &slots[2]); //[2]

    // IV. RESAMPLING /////////////////////////////////////
    set_resample_sw(1);
   #endif
   printf("\n#################################################");
   printf("\n#################################################\n");
   /*
   // create and start sorting thread
    init_all_network_interfaces();
    if(!eth0_up){
        printf("failed to initialize eth0\naborting\n");
        return NULL;
    }
    else{
        printf(" eth0 up\n");
    }  
   diag_printf( "initializing ECAP interface..." );
   ecap_init();
   diag_printf( "done\n" );*/
   //create_particle_filter(100, 10); 
   //set_observe_hw_dynamic(2, &hw_thread_o_circuit, 0, 0);
   //sw_test_thread = (cyg_thread *) malloc (sizeof(cyg_thread));
   //sw_test_thread_stack = (char *) malloc (sizeof(char) * STACK_SIZE);
   //sw_test_thread_handle = (cyg_handle_t *) malloc(sizeof(cyg_handle_t));
   /*cyg_thread_create(PRIO,                       // scheduling info (eg pri)  
                      test_thread,               // entry point function   
                      0,                         // entry data                
                      "TEST",                    // optional thread name      
                      //sw_test_thread_stack,      // stack base          
                      sw_measurement_thread_4_stack,    // stack base          
                      STACK_SIZE,                // stack size,       
                      //sw_test_thread_handle,     // returned thread handle 
                      &sw_measurement_thread_4_handle,  // returned thread handle  
                      //sw_test_thread             // put thread here 
                      &sw_measurement_thread_4          // put thread here 
          
     );

    // resume thread
    cyg_thread_resume(sw_measurement_thread_4_handle);*/
    //cyg_thread_resume(*sw_test_thread_handle);
   /*cyg_thread_create(PRIO,                             // scheduling info (eg pri)  
                      test_thread,               // entry point function     
                      0,                                // entry data                
                      "READ_MEASUREMENTS_4",            // optional thread name      
                      sw_measurement_thread_4_stack,    // stack base                
                      STACK_SIZE,                       // stack size,       
                      &sw_measurement_thread_4_handle,  // returned thread handle    
                      &sw_measurement_thread_4          // put thread here           
     );

    // resume thread
    cyg_thread_resume(sw_measurement_thread_4_handle);*/

   //cyg_thread_delay(1000);
   //diag_printf( "Reconfigure!\n" );
   /*old_number_of_sortings = 0;
   start_sorting();
   set_sort8k_hw_dynamicB(2);
   set_sort8k_hw_dynamic(2);
   cyg_thread_delay(1000);*/

   start_particle_filter();

   printf("\nstart particle filter");
   return NULL;
  }




/**
 * This SW thread which reads the new frame (if it is not allready stored in Main Memory) and sends particle data back to the PV via TCP/IP packages.
 *
 * @param data: entry data for thread (e.g. an address)
 */
void read_new_frame(cyg_addrword_t data) {

  int frame_counter = 0;
#ifndef STORE_VIDEO
  timing_t t_start = 0, t_stop = 0, t_result = 0;
#else
  int i;
#endif
  while (42){

        // 1) wait for semaphore
        //diag_printf("\n+++++++++++++++wait for sem_read_new_frame_start semaphore");
        cyg_semaphore_wait(sem_read_new_frame_start);
        //diag_printf("\n+++++++++++++++received sem_read_new_frame_start semaphore");
        frame_counter++;
        //printf("\nFrame %d", frame_counter);


 
        // 2) read new frame
#ifdef STORE_VIDEO
        // all frames are read
        framecounter++;
        //printf("\nframe counter: %d", frame_counter);
        if ((frame_counter % MAX_FRAMES) == 0 && frame_counter > 0){
             
             //diag_printf("\nload next %d Frames", MAX_FRAMES);
#ifndef NO_ETHERNET
#ifdef NO_VGA_FRAMEBUFFER
              send_particles_back(particles, N);
#endif
#endif
             reset_the_framebuffer();
             set_observations_input(tft_editing.fb);
              // load first frames
             for(i=0; i<MAX_FRAMES; i++){
	       //switch_framebuffer();
               //diag_printf("\n+++++++++++++++read frame");
#ifndef NO_ETHERNET
	       read_frame();
#endif
             }
             set_observations_input(tft_editing.fb);
        }
        //send_best_particle_back(particles, N);
 
#else
        // send particle data to pc program
        t_start = gettime();
#ifndef NO_ETHERNET
#ifdef NO_VGA_FRAMEBUFFER
        send_particles_back(particles, N);
#endif
#endif
        //send_best_particle_back(particles, N);
        t_stop = gettime();
        t_result = calc_timediff(t_start, t_stop);
        //printf("\nSend Particles back: %d", t_result);
        //send_particles_back();

        t_start = gettime();
        // read next frame
#ifndef NO_ETHERNET
        read_frame();
#endif
        t_stop = gettime();
        t_result = calc_timediff(t_start, t_stop);
        //printf("\nRead Frame: %d", t_result);
#endif

        //diag_printf("\n+++++++++++++++send sem_read_new_frame_stop semaphore");
        // 3) post semaphore
       cyg_semaphore_post(sem_read_new_frame_stop);
   }
}




/**
 * This SW thread which reads measurements from sampling hw threads
 *
 * @param data: entry data for thread (e.g. an address, here: not needed)
 */
void read_measurement(cyg_addrword_t data) {

  int message = 0;
  //int measurement = 0;
  //int sum_of_measurements = 0;
  int number_of_measurements = 0;
  //int middle_of_measurements = 0;

  while (42){

        // 1) wait for time measurement message
        message = (int) cyg_mbox_get( hw_mb_sampling_measurement_handle[0] );
        //message = (int) cyg_mbox_get( hw_mb_importance_measurement_handle[0] );
        //message = (int) cyg_mbox_get( hw_mb_resampling_measurement_handle[0] );

          if (message > 0){
 
             // 2) add new measurement
	     //measurement = message/1000;
             //sum_of_measurements += measurement;
             number_of_measurements++;
             //middle_of_measurements = sum_of_measurements / number_of_measurements;
             //diag_printf("\n!!!!!!!Sampling HW: %d (No. %d)", message, number_of_measurements);
             //printf("\nMeasurement [%d]: %d \t Average: %d", number_of_measurements, message, middle_of_measurements);
             //printf("\nSampling HW: %d \t%d", number_of_measurements, message);
	}

       
        
   }
}


/**
 * This SW thread which reads measurements from importance hw threads
 *
 * @param data: entry data for thread (e.g. an address, here: not needed)
 */
void read_measurement_2(cyg_addrword_t data) {

  int message = 0;
  //int measurement = 0;
  //int sum_of_measurements = 0;
  int number_of_measurements = 0;
  //int middle_of_measurements = 0;

  while (42){

        // 1) wait for time measurement message
        //message = (int) cyg_mbox_get( hw_mb_sampling_measurement_handle[0] );
        message = (int) cyg_mbox_get( hw_mb_importance_measurement_handle[0] );
        //message = (int) cyg_mbox_get( hw_mb_resampling_measurement_handle[0] );

          if (message > 0){
 
             // 2) add new measurement
	     //measurement = message/1000;
             //sum_of_measurements += measurement;
             number_of_measurements++;
             //middle_of_measurements = sum_of_measurements / number_of_measurements;
             //printf("\nMeasurement [%d]: %d \t Average: %d", number_of_measurements, message, middle_of_measurements);
             //printf("\nImportance HW: %d \t%d", number_of_measurements, message);
	}

       
        
   }
}



/**
 * This SW thread which reads measurements from resampling hw thread
 *
 * @param data: entry data for thread (e.g. an address, here: not needed)
 */
void read_measurement_3(cyg_addrword_t data) {

  int message = 0;
  //int measurement = 0;
  //int sum_of_measurements = 0;
  int number_of_measurements = 0;
  //int middle_of_measurements = 0;

  while (42){

        // 1) wait for time measurement message
        //message = (int) cyg_mbox_get( hw_mb_sampling_measurement_handle[0] );
        //message = (int) cyg_mbox_get( hw_mb_importance_measurement_handle[0] );
        message = (int) cyg_mbox_get( hw_mb_resampling_measurement_handle[0] );

          if (message > 0){
 
             // 2) add new measurement
	     //measurement = message/1000;
             //sum_of_measurements += measurement;
             number_of_measurements++;
             //middle_of_measurements = sum_of_measurements / number_of_measurements;
             //diag_printf("\n!!!!!!Resampling HW: %d (No. %d)", message, number_of_measurements);
             //printf("\nMeasurement [%d]: %d \t Average: %d", number_of_measurements, message, middle_of_measurements);
             //printf("\nResampling HW: %d \t%d", number_of_measurements, message);
	}        
   }
}


/**
 * This SW thread which reads measurements from observation hw threads
 *
 * @param data: entry data for thread (e.g. an address, here: not needed)
 */
void read_measurement_4(cyg_addrword_t data) {

  int message = 0;
  //int measurement = 0;
  //int sum_of_measurements = 0;
  int number_of_measurements = 0;
  //int middle_of_measurements = 0;

  while (42){


	/*diag_printf("\n############ ICAP: LOAD SAMPLING THREAD #################");
        icap_load( sampling_bitstream_00.data, sampling_bitstream_00.size );

	cyg_thread_delay(10);

	diag_printf("\n############ ICAP: LOAD RESAMPLING THREAD #################");
        icap_load( resampling_bitstream_00.data, resampling_bitstream_00.size );

	cyg_thread_delay(10);*/

        // 1) wait for time measurement message
        message = (int) cyg_mbox_get( hw_mb_observation_measurement_handle[0] );

          if (message > 0){
 
             // 2) add new measurement
	     //measurement = message/1000;
             //sum_of_measurements += measurement;
             number_of_measurements++;
             //middle_of_measurements = sum_of_measurements / number_of_measurements;
             //diag_printf("\n!!!!!!Observation HW: %d (No. %d)", message, number_of_measurements);
             //printf("\nMeasurement [%d]: %d \t Average: %d", number_of_measurements, message, middle_of_measurements);
             //diag_printf("\nObservation HW: %d \t%d", number_of_measurements, message);
	}        
   }
}



//! at start enable cache
void cyg_user_start(void){

   
#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
     XCache_EnableDCache( 0xF0000000 );
#else
    printf( "data cache disabled\n" );
    XCache_DisableDCache(  );
#endif   

}






// MAIN ////////////////////////////////////////////////////////////////////
/**
 * Main thread of the Particle Filter Object Tracker Application. 
 * SW Threads for creating & starting the particle filter, receiving hw measurements
 * and receiving a new frame are instanciated and started
 *
 * @param argc: number of parameters (here: not needed)
 * @param argv: parameter array (here: not needed)
 */
int main(int argc, char *argv[]) {

#ifdef STORE_VIDEO
    framecounter = 0;
#endif

    diag_printf( "-------------------------------------------------------\n"
            "PARTICLE FILTER OBJECT TRACKER\n"
            "(" __FILE__ ")\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

    /*diag_printf( "initializing ECAP interface..." );
    ecap_init();
    diag_printf( "done\n" );*/    
    
    // create sw thread for particle filter
    /*cyg_thread_create(PRIO,                         // scheduling info (eg pri)  
                      main_function,                // entry point function     
                      0,                            // entry data                
                      "SW_MAIN_THREAD",             // optional thread name      
                      sw_thread_stack,              // stack base                
                      STACK_SIZE,                   // stack size,       
                      &sw_thread_handle,            // returned thread handle    
                      &sw_thread                    // put thread here           
     );  
   
    // resume thread
    cyg_thread_resume(sw_thread_handle);*/

    pthread_attr_init(&main_thread_attr);
    pthread_attr_setstacksize(&main_thread_attr, STACK_SIZE);
    pthread_create(&main_thread, &main_thread_attr, main_function, 0);

    //main_function(0);
    
    // create and start resources for read_new_frame sw thread
    // create semaphores
    sem_read_new_frame_start = (cyg_sem_t *) malloc (sizeof(cyg_sem_t));
    sem_read_new_frame_stop  = (cyg_sem_t *) malloc (sizeof(cyg_sem_t));

   
    // init semaphores
    cyg_semaphore_init(sem_read_new_frame_start, 0);
    cyg_semaphore_init(sem_read_new_frame_stop,  0);

        // create sw thread for particle filter
    cyg_thread_create(PRIO+1,                   // scheduling info (eg pri)  
                      read_new_frame,                   // entry point function     
                      0,                                // entry data                
                      "READ_NEW_FRAME_THREAD",          // optional thread name      
                      sw_thread_read_new_frame_stack,   // stack base                
                      STACK_SIZE,                       // stack size,       
                      &sw_thread_read_new_frame_handle, // returned thread handle    
                      &sw_thread_read_new_frame         // put thread here           
     );
   
   

    // resume thread
    cyg_thread_resume(sw_thread_read_new_frame_handle);
    
    /*// create sw for measurement
    cyg_thread_create(PRIO,                             // scheduling info (eg pri)  
                      read_measurement,                 // entry point function     
                      0,                                // entry data                
                      "READ_MEASUREMENTS",              // optional thread name      
                      sw_measurement_thread_stack,      // stack base                
                      STACK_SIZE,                       // stack size,       
                      &sw_measurement_thread_handle,    // returned thread handle    
                      &sw_measurement_thread            // put thread here           
     );

    // resume thread
    cyg_thread_resume(sw_measurement_thread_handle);
    
    // create sw for measurement (2nd thread)
    cyg_thread_create(PRIO,                             // scheduling info (eg pri)  
                      read_measurement_2,               // entry point function     
                      0,                                // entry data                
                      "READ_MEASUREMENTS_2",            // optional thread name      
                      sw_measurement_thread_2_stack,    // stack base                
                      STACK_SIZE,                       // stack size,       
                      &sw_measurement_thread_2_handle,  // returned thread handle    
                      &sw_measurement_thread_2          // put thread here           
     );

    // resume thread
    cyg_thread_resume(sw_measurement_thread_2_handle);
    */
    
    // create sw for measurement (3rd thread)
    /*cyg_thread_create(PRIO,                             // scheduling info (eg pri)  
                      read_measurement_3,               // entry point function     
                      0,                                // entry data                
                      "READ_MEASUREMENTS_3",            // optional thread name      
                      sw_measurement_thread_3_stack,    // stack base                
                      STACK_SIZE,                       // stack size,       
                      &sw_measurement_thread_3_handle,  // returned thread handle    
                      &sw_measurement_thread_3          // put thread here           
     );

    // resume thread
    cyg_thread_resume(sw_measurement_thread_3_handle);
 
    // create sw for measurement (4th thread)
    cyg_thread_create(PRIO,                             // scheduling info (eg pri)  
                      read_measurement_4,               // entry point function     
                      0,                                // entry data                
                      "READ_MEASUREMENTS_4",            // optional thread name      
                      sw_measurement_thread_4_stack,    // stack base                
                      STACK_SIZE,                       // stack size,       
                      &sw_measurement_thread_4_handle,  // returned thread handle    
                      &sw_measurement_thread_4          // put thread here           
     );

    // resume thread
    cyg_thread_resume(sw_measurement_thread_4_handle);
    */
    /*
    /////////////////// TODO REMOVE
    create_particle_filter(100, 10);    
        
    //hw_thread_s_swattr1 = (pthread_attr_t *) malloc (sizeof(pthread_attr_t));
    //hw_thread_s_hwattr1 = (rthread_attr_t *) malloc (sizeof(rthread_attr_t));

    // set ressources
    res_s1 = (reconos_res_t *) malloc (3 * sizeof(reconos_res_t));
          
    res_s1[0].ptr  =  mb_sampling_handle;
    res_s1[0].type =  CYG_MBOX_HANDLE_T;
    res_s1[1].ptr  =  mb_sampling_done_handle;
    res_s1[1].type =  CYG_MBOX_HANDLE_T;
    res_s1[2].ptr  =  hw_mb_sampling_measurement_handle;
    res_s1[2].type =  CYG_MBOX_HANDLE_T;

    int * parameter_s1 = (int *) malloc (5 * sizeof(int));
    parameter_s1[0] = SIZE_X;
    parameter_s1[1] = SIZE_Y;
    parameter_s1[2] = 16384; // GRANULARITY / TRANS_STD_X
    parameter_s1[3] = 8192;  // GRANULARITY / TRANS_STD_Y
    parameter_s1[4] = 16;    // GRANULARITY / TRANS_STD_S

    // set information
    information_s1 = (information_struct_s1 *) malloc (sizeof(information_struct_s1));

    // set information
    information_s1[0].particles = particles;
    information_s1[0].number_of_particles = N;
    information_s1[0].particle_size = sizeof(particle);
    information_s1[0].max_number_of_particles = 8096 / sizeof(particle);
    information_s1[0].block_size = block_size;

    // parameter
    information_s1[0].parameter = parameter_s1;
    information_s1[0].number_of_parameter = 5;

    int ret = pthread_attr_init(&hw_thread_s_swattr1);
    diag_printf("\np_thread_attr_init = %d", ret);
    ret = pthread_attr_setstacksize(&hw_thread_s_swattr1, STACK_SIZE);
    diag_printf("\np_thread_attr_set_stacksize = %d", ret);
    ret = rthread_attr_init(&hw_thread_s_hwattr1);
    diag_printf("\nr_thread_attr_init = %d", ret);
    ret = rthread_attr_setcircuit(&hw_thread_s_hwattr1, &hw_thread_s_circuit1);
    diag_printf("\nr_thread_set_circuit = %d", ret);
    //rthread_attr_setstatesize(&hw_thread_s_hwattr1, 16384);
 
    ret = rthread_attr_setresources(&hw_thread_s_hwattr1, res_s1, 3);
    //diag_printf("\nr_thread_attr_setresources = %d", ret);

    ret = rthread_create(&hw_thread_s1, &hw_thread_s_swattr1, &hw_thread_s_hwattr1, (void*)information_s1); 
    diag_printf("\nr_thread_create = %d", ret);
    /////////////////// TODO END
    */

    return 0;

}




