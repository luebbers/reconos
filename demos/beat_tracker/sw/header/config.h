/*! \file config.h 
 * \brief offers configuration constants
 */
#include <string.h>
#include <stdio.h>
#ifndef ONLYPC
#include <cyg/infra/cyg_type.h>
#include <cyg/infra/diag.h>
#include <cyg/kernel/kapi.h>
#endif


#ifndef __CONFIG_H__
#define __CONFIG_H__


//! defines, if cache will be used
#define USE_CACHE 1

//! defines if audio frames are stored
#define STORE_AUDIO 1

//! number of audio frames to store
#define MAX_FRAMES 500

//! granularity of the weights as fixed point representation (= potention of 2)
#define GRANULARITY 16384

//! typedef signed integer with 16 bits
typedef signed short int int16;



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



/*-***************************** Defs and macros *****************************/

//! bytes per second of audio file
volatile int bytespersecond;

//! sample rate
volatile int sample_rate;

//! type definition for a complex number
typedef struct complex{

	double re;
	double im;
}complex;

//#define IMPORTANCE_DEBUG 1
//#define OBSERVATION_DEBUG 1

//! current interval for beat tracking
volatile long unsigned int interval_min;
volatile long unsigned int interval_max;

//! initial phase (true, false)
int initial_phase;

//! low_volume counter
int low_volume_counter;

//! number of initial beats
#define NUM_INITIAL_BEATS 4

// initial beat positions
volatile long int * initial_beats;

// first two beats at all (old, now array)
//volatile long int first_beat_pos;
//volatile long int second_beat_pos;

//! measurement buffer size
#define MEASUREMENT_BUFFER 8192//16384//2048//512//1024 //524288//1024

#define FREQUENCY_HOPPING 100 //(old)

//! measurement
unsigned char * measurement;

//! stored audio frames
unsigned char * sound_frames;

//! current audio frame
int current_audio_frame;

//! output
unsigned char * output;

//! short time Fourier transformation window (old)
//double * fft_window;

//! last event found (yes/no) -> ignore successive/consecutive events (old)
int last_event_found;

// last energy (old)
//long int last_energy;

//! input audio file (old)
//#define INPUTFILE "/home/markus/work/BeatTrackPF/audio/stepmom_mono.wav"
//#define INPUTFILE "/home/markus/work/BeatTrackPF/audio/beatallica_mono.wav"
#define INPUTFILE "./audio/madness_mono.wav"
//#define INPUTFILE "./audio/testSound.wav"
//#define INPUTFILE "/home/markus/work/BeatTrackPF/audio/beethoven_mono.wav"
//! output audio file (old)
//#define OUTPUTFILE "/home/markus/work/BeatTrackPF/audio/stepmom_output.wav"
//#define OUTPUTFILE "/home/markus/work/BeatTrackPF/audio/beatallica_output.wav"
#define OUTPUTFILE "./audio/madness_output_test.wav"
//#define OUTPUTFILE "./audio/testSound_output.wav"
//#define OUTPUTFILE "/home/markus/work/BeatTrackPF/audio/beethoven_output.wav"

//! buffer size for byte reading
#define BUFFSIZE 2

//! measured an beat event (old)
int event_found;

//! measured an beat event position (old)
long int event_position;

//! measured an beat event salience (old)
int event_salience;

//! factor for a good beat estimation
#define FACTOR_FOUND_BEAT 5

//! factor for a quite good beat estimation
#define FACTOR_ALMOST_FOUND_BEAT 4

//! good estimation time interval (accepted beat, good)
#define GOOD_ESTIMATION_TIME 0.04

//! store last 'x' likelihood results
#define OLD_LIKELIHOOD_VALUES 20

//! tempo correction factor
#define TEMPO_CORRECTION_FACTOR 2

//! noise factor for prediction
#define NOISE_FACTOR 150

//! time out for tracking (in seconds)
#define TIME_OUT 30

//! minimum sound amplitude
#define MIN_SOUND_AMPLITUDE 5000

//! max. amplitude in current interval (old)
int max_amplitude;


//! beat counter
int beat_counter;

//! best particle remember (old)
//int best_particle_remember;

//!input audio file (old)
//FILE *inputstream;

//!output audio file (old)
//FILE *outputstream;

//!debug graph for audio file (old)
//FILE *graphstream;

//! last best particle index
int last_best_particle_ind;

//! last beat position (global) (old)
long unsigned int last_beat;

//! length of next measurement (old)
//int length_of_next_measurement;

//! current byte position in audio file
volatile long unsigned int current_position;

//! message boxes for fft
cyg_mbox * mb_fft_start;
cyg_mbox * mb_fft_done;

//! handles for message boxes for fft
cyg_handle_t * mb_fft_start_handle;
cyg_handle_t * mb_fft_done_handle;


#endif
