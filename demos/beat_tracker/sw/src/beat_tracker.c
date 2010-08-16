// Particle Filter Framework Interface
#include "../framework/header/particle_filter.h"
#include "../framework/header/timing.h"
#include <math.h>

#ifndef ONLYPC
//#define ONLYPC 1
#endif

#ifndef ONLYPC
#include <xcache_l.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/infra/diag.h>
#include <cyg/kernel/kapi.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "../header/ethernet.h"
#endif

//#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

// Application Header
#include "../header/config.h"


/**
 * @mainpage
 *
 *
 * The 'Particle Filter Beat Tracker' Application runs on a FPGA card and uses
 * the 'Particle Filter Framework' to track an object in a video using colour histograms.
 * <ul>
 * <li>For every filter step (sampling, importance, resampling) there can be multiple threads in SW and HW. </li>
 * <li>For every filter step there has to be at least one thread (in HW or in SW).</li>
 * <li>In every iteration step SW and HW threads can be added to or removed from a filter block. </li>
 * </ul>
 * Information about the specified particle filter:
 * <ul>
 * <li></li>
 * <li></li>
 * <li></li>
 * <li></li>
 * </ul>
 */



/*! \file beat_tracker.c 
 * \brief SW program to track a beat by a particle filter
 */

//! sw thread for sir algorithm
//pthread_t sw_thread;

//! thread handle to sw thread
//int sw_thread_handle;

//! sw threads for the sir algorithm
cyg_thread sw_thread;

//! Stack for the sw thread
char sw_thread_stack[STACK_SIZE];

//! thread handle to sw thread
cyg_handle_t sw_thread_handle;

//! sw threads for read_new_frame sw thread
//cyg_thread sw_thread_read_new_frame;

//! Stack for read_new_frame sw thread
//char sw_thread_read_new_frame_stack[STACK_SIZE];

//! thread handle to read_new_frame sw thread
//cyg_handle_t sw_thread_read_new_frame_handle;



//! hw thread fft
cyg_thread * hw_thread_fft;
//! stack for hw thread fft	
char * hw_thread_fft_stack;
//! hw thread handle for fft thread
cyg_handle_t * hw_thread_fft_handle;
//! resources for fft hw thread
reconos_res_t * res_fft;          
//! attributes for fft hw thread
rthread_attr_t * hw_thread_fft_attr;   




//! reference data
//observation reference_data;

//! parameter arrays
int * parameter_s, * parameter_o;

//! reconos slots
unsigned int * slots;

//! region information
int * region_information;

//! open audio file
/*void open_audiofile(void){
	
	char line[100000]; 
	inputstream = malloc(sizeof(FILE));
	outputstream = malloc(sizeof(FILE));
	int * number = malloc(sizeof(int));
	int byterate;

        inputstream = fopen( INPUTFILE, "r"); // open file
	outputstream = fopen( OUTPUTFILE, "w"); // open file
        if (inputstream == NULL) // file not found or other error
	{
		printf( "The file '%s' was not opened\n", INPUTFILE );//error
		return;
	}; 

        if (outputstream == NULL) // file not found or other error
	{
		printf( "The file '%s' was not opened\n", OUTPUTFILE );//error
		return;
	}; 
        
        //printf( "The files '%s', '%s' are open.\n\n", INPUTFILE, OUTPUTFILE);
	printf ("----------------------------------------------------------------\n");
	printf ("---------------          WAVE-HEADER              --------------\n");
	printf ("----------------------------------------------------------------\n");
	printf ("\nI. RIFF WAV CHUNK\n");
        */
	/*
		------------------------------------------
		--	.WAV-HEADER			--
		------------------------------------------	
		1. format tag (4 byte, char)
		2. number of channels [1 for mono, 2 for stereo] (4 byte, ?)
		3. number of samples per second (4 byte, ?)
		4. average data rate per second (4 byte, ?)
		5. size of blocks in bytes (4 byte, ?)
		6. number of bits per data sample [usually 8] (2 byte, ?) 
		7. size in bytes of extra information in
			the extended WAVE 'fmt' header [usually 0] (2 byte, ?) 
		8. sample rate [e.g 44100] (4 byte, ?)
		9. bytes/second [sample rate * block align] (4 byte, ?)
		10. 10. block align [channels * bits per sample / 8] (2 byte, ?) 
		11. 11. bits per sample [8 or 16] (2 byte, ?) 
 
	*//*

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		printf ("-- (1) group ID\t\t\t: %s\n", line);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		printf ("-- (2) file size in byte - 8\t: %d\n",*number);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		printf ("-- (3) riff type\t\t: %s\n", line);
	};

	printf ("----------------------------------------------------------------\n");
	printf ("\nII. FORMAT CHUNK\n");


	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);

		printf ("-- (1) chunk ID\t\t\t\t\t\t: %s\n", line);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		printf ("-- (2) length of fmt data [16]\t\t\t\t: %d\n",*number);
	};

	*number = 0;

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		printf ("-- (3) format-tag [1=PCM]\t\t\t\t: %d\n", *number);
	};

	*number = 0;

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		printf ("-- (4) channels [1=mono, 2=stereo]\t\t\t: %d\n", *number);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		sample_rate = *number;
		printf ("-- (5) sample rate [e.g 44100]\t\t\t\t: %d\n", *number);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		printf ("-- (6) bytes/second [sample rate * block align]\t\t: %d\n", *number);
	};

	byterate = *number;

	*number = 0;

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		printf ("-- (7) block align [channels * bits per sample / 8]\t: %d\n", *number);
	};

	*number = 0;

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		printf ("-- (8) bits per sample [8 or 16]\t\t\t: %d\n", *number);
	};

	printf ("----------------------------------------------------------------\n");
	printf ("\nIII. SOUND DATA CHUNK\n");

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		printf ("-- (1) chunk ID\t\t: %s\n", line);
	};

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		printf ("-- (2) chunk length\t: %d\n", *number);
	};

	//int chunklength = (int)(*number);

	printf ("-- (3) sample data\t:\n");

	bytespersecond = byterate;

	// CHANGE CHANGE CHANGE
	//fclose( inputstream );
	//fclose( outputstream );
}*/





/**
 * This SW thread will create the particle filter, receive the object information, calculate the reference histogram and will start the Particle Filter Object Tracker.
 *
 * @param data: entry data for thread (e.g. an address)
 */
void main_function (cyg_addrword_t data) {//(void * threadid) { //cyg_addrword_t data) {

#ifndef ONLYPC
	// (1) create hw thread and message boxes
	mb_fft_start = (cyg_mbox*) malloc(sizeof(cyg_mbox));
	mb_fft_done = (cyg_mbox*) malloc(sizeof(cyg_mbox));
	mb_fft_start_handle = (cyg_handle_t *) malloc(sizeof(cyg_handle_t));
	mb_fft_done_handle = (cyg_handle_t *) malloc(sizeof(cyg_handle_t));
	cyg_mbox_create( mb_fft_start_handle, mb_fft_start);
	cyg_mbox_create( mb_fft_done_handle, mb_fft_done);

	// create hw threas
	hw_thread_fft = (cyg_thread *) malloc (sizeof(cyg_thread));	
	hw_thread_fft_stack = (char *) malloc (STACK_SIZE * sizeof(char));
	hw_thread_fft_handle = (cyg_handle_t *) malloc (sizeof(cyg_handle_t));

	// set ressources for hw thread
	res_fft = (reconos_res_t *) malloc (2 * sizeof(reconos_res_t));          
	res_fft[0].ptr  = mb_fft_start_handle;
	res_fft[0].type = CYG_MBOX_HANDLE_T ;
	res_fft[1].ptr  = mb_fft_done_handle;
	res_fft[1].type = CYG_MBOX_HANDLE_T ;

	// attributes for hw threads
	hw_thread_fft_attr = (rthread_attr_t *) malloc(sizeof(rthread_attr_t));     
	rthread_attr_init(hw_thread_fft_attr);
	rthread_attr_setslotnum(hw_thread_fft_attr, 0);
	rthread_attr_setresources(hw_thread_fft_attr, res_fft, 2); 

	// create hw sampling thread
	reconos_hwthread_create(
		(cyg_addrword_t) PRIO_HW, // priority
		hw_thread_fft_attr,    // attributes
		(cyg_addrword_t) 0 ,   // entry data
		"HW_FFT",              // thread name 
		hw_thread_fft_stack,   // stack
		STACK_SIZE,            // stack size 
		hw_thread_fft_handle,  // thread handle
		hw_thread_fft          // thread object
	);
          
	// resume threads
	cyg_thread_resume(*hw_thread_fft_handle);

	// (2) create init data
	//int16 samples[2048];
	//complex_number fft_values[2048];
	/*
	volatile int * mem_s = malloc((2048 * sizeof(int16)) + 8 + 256); // 8 bytes extra
	volatile int * src_s = (volatile int*)(((int)mem_s / 8 + 1) * 8);

	volatile int * mem_f = malloc((1024 * sizeof(complex_number)) + 8 + 256); // 8 bytes extra
	volatile int * src_f = (volatile int*)(((int)mem_f / 8 + 1) * 8);
	
	// double word aligned addresses
	int16 * samples = (int16 *)src_s;
	complex_number * fft_values = (complex_number *)src_f;	
	int i;

	for (i=0; i<2048; i++)
	{
		//samples[i] = (int16)(16000.0 * cos((i*1.0)/128.0));
		samples[i] = (int16)(rand() % MEASUREMENT_BUFFER);	
		samples[i] -= MEASUREMENT_BUFFER/2;
		fft_values[i].re = 666;
		fft_values[i].im = 777;
	}

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif   

	// (3) make fft
	// -a: send message: input address
	while (cyg_mbox_tryput( *mb_fft_start_handle, (void *) samples ) == 0)
	{
	}
	// -b: send message: output address
	while (cyg_mbox_tryput( *mb_fft_start_handle, (void *) fft_values ) == 0)
	{
	}

	// -c: receive message (fft done)
	while (cyg_mbox_get( *mb_fft_done_handle ) == 0)
	{
	}

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif    

	// (4) view results
	printf("\n...\n");
	int16 re, im;
	int amplitude;
	for (i=0; i<2048; i++)
	{
		re = (int16)fft_values[i].re;
		im = (int16)fft_values[i].im;
		amplitude = (re*re) + (im*im);
		amplitude = sqrt(amplitude);
		printf("\n%d: \t re=%d \tim=%d \t --> amplitude: %d", i, re, im, amplitude);
	}
	printf("\n\nsamples:");
	for (i=0; i<2048; i++)
	{
		printf("\n%d", samples[i]);
	}*/	

	region_information = (int *) malloc (1 * sizeof(int));
	

	// establish connection
#ifndef IMPORTANCE_DEBUG
#ifndef OBSERVATION_DEBUG
	int tmp = 1;
	while (tmp == 1)
	{
		tmp = establish_connection(6666, region_information);
	}
#endif
#endif
	
	int slots[5] = {0, 1, 2, 3, 4};

	//open_audiofile();

	// create particles
	create_particle_filter(100,10);    

	srand(1); 

	// init particles
	init_particles(region_information, 0);
    
	//particle p;
	//get reference data
	//get_reference_data(&p, &reference_data);
	//init_reference_data (&reference_data);
       
	parameter_s = (int *) malloc (1 * sizeof(int));
	parameter_o = (int *) malloc (2 * sizeof(int));

	parameter_o[0] = (int) MEASUREMENT_BUFFER;
	parameter_o[1] = sizeof(observation);

	// create sampling, importance, resampling thread/s
	//set_sample_sw(1);
	//set_sample_hw(1, &slots[0], NULL, 0);
	//set_observe_sw(1);
	//set_observe_hw(1, &slots[0], parameter_o, 2);
	//set_importance_sw(1);
	//set_importance_hw(1, &slots[0]);
	//set_resample_sw(1);

#ifdef STORE_AUDIO
	int i;
	printf("\n\nThe first %d Frames will be stored into Main Memory. Again this will take some time.\n", (int)MAX_FRAMES);

	sound_frames = malloc(MAX_FRAMES*MEASUREMENT_BUFFER*sizeof(unsigned char));

	// load first frames
	for(i=0; i<MAX_FRAMES-1; i++){
		
		receive_sound_frame(&sound_frames[i*MEASUREMENT_BUFFER], MEASUREMENT_BUFFER);		
 	}
	current_audio_frame = 0;

    printf("\nFinished: The first %d Frames are stored in the Main Memory.\n", (int)MAX_FRAMES);
#endif


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
    set_importance_hw(1, &slots[1]);
    set_resample_sw(1);   
    #else
    #if PARTITIONING==3
    printf("\n####   P A R T I T I O N I N G    H W   II   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_importance_sw(1);
    set_importance_hw(2, &slots[1]);
    set_resample_sw(1); 
   #else
   #if PARTITIONING==4
    printf("\n####   P A R T I T I O N I N G    H W   O   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw(1, &slots[3], parameter_o, 2);
    set_importance_sw(1);
    set_resample_sw(1);
   #else
   #if PARTITIONING==5
    printf("\n####   P A R T I T I O N I N G    H W   OO   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw(2, &slots[3], parameter_o, 2);
    set_importance_sw(1);
    set_resample_sw(1);
   #else
   #if PARTITIONING==6
    printf("\n####   P A R T I T I O N I N G    H W   OI   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw(1, &slots[3], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw(1, &slots[1]);
    set_resample_sw(1);
   #else
   #if PARTITIONING==7
    printf("\n####   P A R T I T I O N I N G    H W   OII   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw(1, &slots[3], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw(2, &slots[1]);
    set_resample_sw(1);
   #else
   #if PARTITIONING==8
    printf("\n####   P A R T I T I O N I N G    H W   OOI   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw(2, &slots[3], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw(1, &slots[1]);
    set_resample_sw(1);
   #else
   #if PARTITIONING==9
    printf("\n####   P A R T I T I O N I N G    H W   OOII   #####");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw(2, &slots[3], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw(2, &slots[1]);
    set_resample_sw(1);
   #else
    printf("\n#  N O  P A R T I T I O N I N G   D E F I N E D #");
    set_sample_sw(1);
    set_observe_sw(1);
    set_observe_hw(1, &slots[3], parameter_o, 2);
    set_importance_sw(1);
    set_importance_hw(2, &slots[1]);
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
   #endif
   printf("\n#################################################");
   printf("\n#################################################\n");

	printf("\nstart particle filter");
	// start particle filter
#ifndef IMPORTANCE_DEBUG
#ifndef OBSERVATION_DEBUG
	start_particle_filter();
#endif
#endif


#ifdef IMPORTANCE_DEBUG
	// debug
	//volatile int * mem_d = malloc((N * sizeof(debug_ob)) + 8 + 256); // 8 bytes extra
	//volatile int * src_d = (volatile int*)(((int)mem_d / 8 + 1) * 8);
	//debug_obs = (debug_ob *) src_d;
	int i, j;
	//int zero = 0;
	for (i=0;i<N;i++)
	{
		observations[i].no_tracking_needed = FALSE;
		observations[i].old_likelihood = i + 1000;
		for (j=0;j<OBSERVATION_LENGTH;j++)
		{
			//memcpy(&observations[i].fft[j], &zero, 4);
			observations[i].fft[j].re = 0;
			observations[i].fft[j].im = 0;			
		}	
		particles[i].w = 5000 + i;	
	}


	for (i=0;i<N;i++)
	{
		observations[i].fft[i+1].re = 190+(2*i);
		observations[i].fft[i+1].im = 19+(10*i);		
	}

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif   

	// (3) make fft
	// -a: send message
	int message = 1;
	for (i=0;i<100;i++)
	{
	diag_printf("\nrun no. %d", i+1);
	for (message=1;message<=10;message++)
	{
		while (cyg_mbox_tryput( *mb_importance_handle, (void *) message ) == 0)
		{
		}

		diag_printf("\nsent %d. message", message);

		// -b: receive message
		cyg_mbox_get( *mb_importance_done_handle );
		//while (cyg_mbox_get( *mb_importance_done_handle ) == 0)
		//{
		//}

		diag_printf("\nFinished %d\n", message);

		/*diag_printf("\nsw: observation address = %d", (int) observations);
		diag_printf("\nhw: observation address = %d", (int) message);*/

	}
	}

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif  
	
	for (i=0;i<N;i++)
	{
		diag_printf("\nhw: weight of particle[%d] = %d", i, particles[i].w);
		/*if (particles[i].w == TRUE)
			diag_printf("\nhw: weight of particle[%d] = TRUE", i);
		else if (particles[i].w == FALSE)
			diag_printf("\nhw: weight of particle[%d] = FALSE", i);
		else
			diag_printf("\nhw: weight of particle[%d] = %d", i, particles[i].w);*/
			
	}

	diag_printf("\n");
	int sw_likelihood;
	for (i=0;i<N;i++)
	{
		sw_likelihood = likelihood(&particles[i], &observations[i], NULL);
		diag_printf("\nsw: weight of particle[%d] = %d", i, sw_likelihood);
		/*if (sw_likelihood == TRUE)
			diag_printf("\nsw: weight of particle[%d] = TRUE", i);
		else if (sw_likelihood == FALSE)
			diag_printf("\nsw: weight of particle[%d] = FALSE", i);
		else
			diag_printf("\nsw: weight of particle[%d] = %d", i, sw_likelihood);*/
	}	

	diag_printf("\nsizeof(observation) = %d", sizeof(observation));	
	
#endif


#ifdef OBSERVATION_DEBUG

	int i, j;
	// set measurement
	for (i=0;i<MEASUREMENT_BUFFER;i++)
	{
		//measurement[i] = (int16)(rand() % MEASUREMENT_BUFFER);//(int16)(16000.0 * cos((i*1.0)/128.0));	
		//measurement[i] -= MEASUREMENT_BUFFER/2;
		measurement[i] = 0;//i;
	}
	for (i=0;i<(MEASUREMENT_BUFFER/4)-1;i++)
	{
		//measurement[i] = (int16)(rand() % MEASUREMENT_BUFFER);//(int16)(16000.0 * cos((i*1.0)/128.0));	
		//measurement[i] -= MEASUREMENT_BUFFER/2;
		//j = 8000;
		j = (int)i;
		memcpy(&measurement[4*i], &j, 4);
		//memcpy(&measurement[2*i+1], &j, 4);
		//measurement[2*i+1] = (int16)j;
	}
	

	interval_min = 0;
	interval_max = MEASUREMENT_BUFFER-1;
	initial_phase = FALSE;
	for (i=0;i<N;i++)
	{
		// set observtions
		for (j=0;j<OBSERVATION_LENGTH;j++)
		{
			observations[i].fft[j].re = 111;
			observations[i].fft[j].im = 222;
		}
		observations[i].old_likelihood = 1000*i;
		observations[i].no_tracking_needed = FALSE;
		
		// set particles
		particles[i].w = 4*i;
		particles[i].likelihood = 5*i;	
		particles[i].next_beat = i;
		particles[i].last_beat = 2;
		particles[i].tempo = 12000;
		particles[i].initial_phase = FALSE;//TRUE;	
		particles[i].interval_min = 0;
		particles[i].interval_max = MEASUREMENT_BUFFER-1;	
		
	}

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif   

	// (3) make fft
	// -a: send message
	int message = 1; i = 0;
	for (i=0;i<100;i++)
	{
		diag_printf("\nrun no. %d", i+1);
		for (message=1;message<=10;message++)
		{
			while (cyg_mbox_tryput( *mb_sampling_done_handle, (void *) message ) == 0)
			{
			}

			diag_printf("\nsent %d. message", message);

			// -b: receive message
			cyg_mbox_get( *mb_importance_handle );
			diag_printf("\nFinished %d\n", message);
		}
	}

	#ifdef USE_CACHE
		XCache_EnableDCache( 0xF0000000 );
	#endif 

	i = 0;
	unsigned int tmp_ui = 0;
	unsigned long int tmp_lui = 0;
	int tmp_i = 0;// int tmp_i2 = 0;
	for (i=0;i<10;i++)
	{
		diag_printf("\n\nparticle[%d]:\n--------------------", i);
		diag_printf("\n1) %d", particles[i].w);
		diag_printf("\n2) %d", particles[i].likelihood);
		diag_printf("\n3) %lu", particles[i].next_beat);
		diag_printf("\n4) %lu", particles[i].last_beat);
		diag_printf("\n5) %u", particles[i].tempo);
		diag_printf("\n6) %u", particles[i].initial_phase);
		diag_printf("\n7) %lu", particles[i].interval_min);
		diag_printf("\n8) %lu", particles[i].interval_max);

		diag_printf("\n\nobservation[%d]:\n--------------------", i);
		int start_index;
		start_index = (int)(particles[i].next_beat % MEASUREMENT_BUFFER);
		start_index -= start_index%4;
		start_index = MAX(start_index, 0);
		start_index = MIN(start_index, (MEASUREMENT_BUFFER - (OBSERVATION_LENGTH*sizeof(int16))));
		diag_printf("\nstart_index sw=%d", start_index);
		/*memcpy(&tmp_i, &observations[i].fft[0], 4);
		diag_printf("\n1) %d", tmp_i);
		memcpy(&tmp_i, &observations[i].fft[1], 4);
		diag_printf("\n2) %d", tmp_i);
		memcpy(&tmp_lui, &observations[i].fft[2], 4);
		diag_printf("\n3) %lu", tmp_lui);
		memcpy(&tmp_lui, &observations[i].fft[3], 4);
		diag_printf("\n4) %lu", tmp_lui);
		memcpy(&tmp_ui, &observations[i].fft[4], 4);
		diag_printf("\n5) %u", tmp_ui);
		memcpy(&tmp_ui, &observations[i].fft[5], 4);
		diag_printf("\n6) %u", tmp_ui);
		memcpy(&tmp_lui, &observations[i].fft[6], 4);
		diag_printf("\n7) %lu", tmp_lui);
		memcpy(&tmp_lui, &observations[i].fft[7], 4);
		diag_printf("\n8) %lu", tmp_lui);*/

		
		observation obs;
		extract_observation(&particles[i], &obs);
		//extract_observation(&particles[i], &observations[i]);
		// 2 times hw calculation
		/*memcpy(&obs, &observations[i], 4);
		#ifdef USE_CACHE
			XCache_EnableDCache( 0xF0000000 );
		#endif 
		message = 1 + (i%10);
		while (cyg_mbox_tryput( *mb_sampling_done_handle, (void *) message ) == 0)
		{
		}
		cyg_mbox_get( *mb_importance_handle );
		#ifdef USE_CACHE
			XCache_EnableDCache( 0xF0000000 );
		#endif */
		

		for(j=0;j<OBSERVATION_LENGTH;j++)
		{
			//memcpy(&tmp_i, &observations[i].fft[j], 4);
			//memcpy(&tmp_i2, &obs.fft[j], 4);
			//diag_printf("\n%d) hw=%d, sw=%d, difference=%d", j, (int)tmp_i, (int)tmp_i2, (tmp_i-tmp_i2));
			diag_printf("\n%d) re - hw=%d, sw=%d, difference=%d", j, 
			(int)observations[i].fft[j].re,(int)obs.fft[j].re,(int)(observations[i].fft[j].re-obs.fft[j].re));
			diag_printf("\n%d) im - hw=%d, sw=%d, difference=%d", j, 
			(int)observations[i].fft[j].im,(int)obs.fft[j].im,(int)(observations[i].fft[j].im-obs.fft[j].im));

		}
		diag_printf("\nold_likelihood %d", observations[i].old_likelihood);		
		if (observations[i].no_tracking_needed==TRUE)
		        diag_printf("\nno_tracking_needed: TRUE");
		else if (observations[i].no_tracking_needed==FALSE)
		        diag_printf("\nno_tracking_needed: FALSE");
		else
		        diag_printf("\nno_tracking_needed: %d", observations[i].no_tracking_needed);

	}
	diag_printf("\nmeasurement=%d, input_address=%d", (int)measurement, (int)observations_input);
		
#endif

#endif

}




/**
 * This SW thread which reads the new frame (if it is not allready stored in Main Memory) and sends particle data back to the PV via TCP/IP packages.
 *
 * @param data: entry data for thread (e.g. an address)
 *//*
void read_new_frame(cyg_addrword_t data) {

	int frame_counter = 0;
	while (42){

		// 1) wait for semaphore
		cyg_semaphore_wait(sem_read_new_frame_start);

		frame_counter++;

 		// 2) read new frame
		framecounter++;
		receive_sound_frame();

		// 3) post semaphore
		cyg_semaphore_post(sem_read_new_frame_stop);
	}
}*/







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

 	printf( "-------------------------------------------------------\n"
		"PARTICLE FILTER BEAT TRACKER\n"
		"(" __FILE__ ")\n"
		"Compiled on " __DATE__ ", " __TIME__ ".\n"
		"-------------------------------------------------------\n\n" );

    
	// create sw thread for particle filter
	cyg_thread_create(PRIO,                         // scheduling info (eg pri)  
		main_function,                // entry point function     
		0,                            // entry data                
		"SW_MAIN_THREAD",             // optional thread name      
		sw_thread_stack,              // stack base                
		STACK_SIZE,                   // stack size,       
 		&sw_thread_handle,            // returned thread handle    
		&sw_thread                    // put thread here           
	);

	// resume thread
	cyg_thread_resume(sw_thread_handle);
    

	/*int rc = pthread_create(&sw_thread, NULL, main_function, (void *)0);
	if (rc){
 		printf("ERROR; return code from pthread_create() is %d\n", rc);
		exit(-1);
	}

	pthread_exit(NULL);
	*/
  	/*

	// create and start resources for read_new_frame sw thread
	// create semaphores
	sem_read_new_frame_start = (cyg_sem_t *) malloc (sizeof(cyg_sem_t));
	sem_read_new_frame_stop  = (cyg_sem_t *) malloc (sizeof(cyg_sem_t));

   
	// init semaphores
	cyg_semaphore_init(sem_read_new_frame_start, 0);
	cyg_semaphore_init(sem_read_new_frame_stop,  0);

	// create sw thread for particle filter
	cyg_thread_create((PRIO+1),                         // scheduling info (eg pri)  
		read_new_frame,                   // entry point function     
		0,                                // entry data                
		"READ_NEW_FRAME_THREAD",          // optional thread name      
		sw_thread_read_new_frame_stack,   // stack base                
		STACK_SIZE,                       // stack size,       
		&sw_thread_read_new_frame_handle, // returned thread handle    
		&sw_thread_read_new_frame         // put thread here           
	);
   
	*/


	return 0;

}




