/*! \file fft.h 
 * \brief offers Fourier transformations
 */



#ifndef __FFT_H__
#define __FFT_H__

#include "../framework/header/particle_filter.h"

/**
	reverses byte positioning

	@param x: signed short int number
	@return number, where byte positions are reverse
*/
int16 ntohl(int16 x);

/**
	calculates short-time Fourier transformation for sample array

	@param samples: int array of samples
	@param size: size of 'samples'-array
	@param fft_results: pointer results of FFT analysis (double)
	@param sample_rate: sample rate
*/
void fft_analysis (unsigned char * samples, int size, double * fft_results, int sample_rate);


/**
	calculates short-time Fourier transformation for sample array

	@param samples: short int array of samples
	@param size: size of 'samples'-array
	@param fft_results: pointer results of FFT analysis (complex numbers)
	@param sample_rate: sample rate
*/
void fft_analysis_new (int16 * samples, int size, observation * fft_results, int sample_rate);


/**
	calculates short-time Fourier transformation for sample array

	@param samples: short int array of samples
	@param size: size of 'samples'-array
	@param fft_results: pointer results of FFT analysis (complex numbers)
	@param sample_rate: sample rate
*/
void fft_analysis_try (int16 * samples, int size, complex_number * fft_results, int sample_rate);

void fft_calc(char * samples, int n);

#endif
