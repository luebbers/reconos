#include "../header/config.h"
#include "../header/fft.h"

#define _USE_MATH_DEFINES
#include <math.h>
#include <stdio.h>
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdlib.h>
 


#ifndef M_PI
#define M_PI 3.141592653589793238
#endif

/**
 * FFT - Fast Fourier Transform Program
 * by Tracy Hammond
 * Algorithm used from Applied Numerical Analysis, 
 * Fifth Edition; Curtis F. Gerald, Patrick O. Wheatley
 * Addison Wesley 1994
 */
void fft_calc(char * samples, int n)
	{

		int i;
		int datapoints[n];
		int16 sample_value;
		for (i=0; i<n; i++){

			char current_sample[2];
			current_sample[1] = samples[(2*i) + 1]; 
			current_sample[0] = samples[(i*2)];
			memcpy(&sample_value, current_sample, 2);

			datapoints[i] = sample_value;
		}

		double XREAL[n];
		double AFFT[n];  
		double BFFT[n];
		double COSX[n];
		double SINX[n];
		int POWER[n];
			
		// (1) put the given values in to an array
		for(i = 0; i < n; i++)
		{
			AFFT[i] = (1.0 * datapoints[i]);
		}

		// (2) makeImaginaryArray(datapoints);
		for (i=0; i < n; i++)
		{
			BFFT[i] = 0.0;
		}
		
		// (3)  make array of x values
		for (i = 0; i < n; i++)
		{
			XREAL[i] = ((8.0 * i) / (1.0 * n)) + 2.0;
		}
		
		// (5)  make cos(x) array and sin(x) array
		for (i = 0; i < n; i++)
		{
			COSX[i] = cos(XREAL[i]);
			SINX[i] = sin(XREAL[i]);
		}

		
		// (6)  generate power array
		// This create something an array of Zn* with the first element zero
		// initialize to zero
		for (i = 0; i < n; i++)
		{
			POWER[i] = 0;
		}
		
		// reevaluate elements
		int TotalNumberOfRuns =  (int) (log(n)/log(2));
		int j;
		for (i = 1; i <= TotalNumberOfRuns; i++)
		{
			for (j = 1; j <= pow(2, i - 1); j++)
			{
				POWER[j] *= 2;
			}
			for (j = 0; j < pow(2, i - 1); j++)
			{
				POWER[j + (int) pow(2, i - 1)] = POWER[j] + 1;
			}
		}
	
		// (7)  actual fft calculation done here
		// Sets A and B arrays to Fourier series values
		int stage = 1;
		int NumberOfSets = 1;
		int cycleLength = n/2;
		int k = 0;

		double TEMPA[n]; for (i=0; i<n; i++) TEMPA[i] = AFFT[i];
		double TEMPB[n]; for (i=0; i<n; i++) TEMPB[i] = BFFT[i];

		do
		{
			int setNumber;
			for(setNumber=0; setNumber <= NumberOfSets; setNumber++)
			{
				for (i = 0; i < n/NumberOfSets; i++)
				{
					int j = (i % cycleLength) + (setNumber - 1) * cycleLength * 2;
					int l = POWER[(int)(k/cycleLength)];
					if (j > n || l > n || j+cycleLength > n)
						printf("\nHELP");
					TEMPA[k] = AFFT[j] + COSX[l]*AFFT[j+cycleLength] - SINX[l]*BFFT[j+cycleLength];
					TEMPB[k] = BFFT[j] + COSX[l]*BFFT[j+cycleLength] - SINX[l]*AFFT[j+cycleLength];
					k++;
				}
			}
			for (i=0; i<n; i++) AFFT[i] = TEMPA[i];
			//for (i=0; i<n; i++) BFFT[i] = TEMPB[i];
			stage++;
			NumberOfSets *= 2;
			cycleLength /= 2;
			k=0;
		} while (stage <= (int)(log(n)/log(2)));
		
		// (8)  unscramble the vertices according to POW values (rearranges the A and B values)
		for (i=0; i<n; i++) TEMPA[i] = AFFT[i];
		for (i=0; i<n; i++) TEMPB[i] = BFFT[i];
		for (i=0; i < n; i++)
		{
			AFFT[i] = TEMPA[POWER[i]];
			BFFT[i] = TEMPB[POWER[i]];
		}
		

		
		
		for(i = 0; i < n; i++){
			
			char current_sample[2];
			if (AFFT[i] < 0)
				sample_value = -(sqrt(ABS(AFFT[i]))/2);
			else
				sample_value = (sqrt(ABS(AFFT[i]))/2);
			memcpy(current_sample, &sample_value, 2);
			samples[2*i]		= current_sample[1]; 
			samples[(2*i)+1]	= current_sample[0];			
			//printf("\nA[%d] = %d", i, sample_value]);
		}
	}
	
	
	/**
	 * Method: main
	 * Input: command-line arguments
	 * the 0th argument is the number of datapoints
	 * each following argument is the yreal value followed by
	 * the yimaginary value
	 * the number of datapoints must be a power of 2
	 */
/*	public static void main (String[] args)
	{
		// hopefully a string of arguments will be entered.
		try
		{
			// if no arguments, print usage
			if (args.length == 0)
			{
				String[] data1 = {"32", "3.804", "0", "6.503", 
								  "0", "7.496", "0", "6.094", "0", 
								  "3.003", "0", "-0.105", "0", "-1.589", 
								  "0", "-0.721", "0", "1.806", "0", 
								  "4.350", "0", "5.2555", "0", "3.878", 
								  "0", "0.893", "0", "-2.048", "0", 
								  "-3.280", "0", "-2.088", "0", "3.746",
								  "0", "5.115", "0", "4.156", "0", 
								  "1.593", "0", "-0.941", "0", "-1.821", 
								  "0", "-0.329", "0", "2.799", "0", 
								  "5.907", "0", "7.338", "0", "6.380", 
								  "0", "3.709", "0", "0.992", "0", 
								  "-.0116", "0", "1.047", "0", "3.802", "0"};
				fft alg = new fft(data1);
				printUsage();
			}
			
			// make sure is a positive integer entered
			if (Integer.parseInt(args[0]) <= 0)
			{
				printUsage();
			}
			
			// make sure number is a power of 2
			int i = 0;
			do 
			{
				if(Math.pow(2.0,(double) i) < Integer.parseInt(args[0]))
					i++;
				if(Math.pow(2.0,(double) i) == Integer.parseInt(args[0]))
					break;
				if(Math.pow(2.0,(double) i) > Integer.parseInt(args[0]))
					printUsage();			
			} while (true);
			
			// make sure number entered equals the number of
			// datapoints
			if ((args.length - 1)/2 != Integer.parseInt(args[0]))
				printUsage();
			
		} 
		catch (Exception e){
			// probably error in input
			printUsage();
		}
		
		// all is good.
		// start the program (Fast Fourier Transform)
		fft alg = new fft(args);
				 
	}
	
*/


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
	zip first and second half of an array of complex values
	i.e "0 1 2 3 4 5 6 7"  ->  "0 4 1 5 2 6 3 7" (for n = 8)

	@param a:  array of complex values
	@param n:  array length (power of 2)
	@param lo: lowest index

	@author: H.W. Lang, FH Flensburg, 1997, "http://www.iti.fh-flensburg.de/lang/algorithmen/fft/fft.htm"
*/
/*void shuffle(complex_number* a, int n, int lo)
{
	int i, m = n/2;
	complex_number* b = malloc(sizeof(complex_number)*m);

	// (1) store first half of array into helper array
	for (i=0; i<m; i++){

		b[i].re = a[lo+i].re;
		b[i].im = a[lo+i].im;
	}

	// (2) zip second half
	for (i=0; i<m; i++){

		a[lo+i+i+1].re = a[lo+i+m].re;
		a[lo+i+i+1].im = a[lo+i+m].im;
	}

	// (3) zip first half
	for (i=0; i<m; i++){

		a[lo+i+i].re = b[i].re;
		a[lo+i+i].im = b[i].im;
	}
}
*/

/**
	Fast Fourier Transformation

	@param a:   array of n complex numbers
	@param n:   array length (power of 2)
	@param low: lowest index for array a
	@param w:   complex root of unity (n roots in total)

	@author: H.W. Lang, FH Flensburg, 1997, "http://www.iti.fh-flensburg.de/lang/algorithmen/fft/fft.htm" 
*/
/*void fft_func(complex_number* a, int n, int lo, complex_number w)
{
    int i, m;
    complex_number z, v, h;

    if (n>1){
        
	// calculate n/2
	m = n / 2;
        
	// first complex root of unity (z = w^0)
	z.re = 1.0;
	z.im = 0.0;
        
	for (i=lo; i<lo+m; i++){
        
		// h = difference of i-th value of 1st and 2nd half
		h.re 		= a[i].re - a[i+m].re;
		h.re 		= a[i].im - a[i+m].im; 

		// add i-th value of 2nd half to i-th value of 1st half
		a[i].re 	= a[i].re + a[i+m].re;
		a[i].im 	= a[i].im + a[i+m].im;

		// i-th value of second half = product of h and the current root of unity
		// (c1.re + c1.im) * (c2.re + c2.im) = (c1.re*c2.re - c1.im*c2.im).re + (c1.im*c2.re + c1.re*c2.im).im
		a[i+m].re	= (h.re * z.re) - (h.im * z.im);
 		a[i+m].im	= (h.im * z.re) + (h.re * z.im);

		// calculate next complex root of unity (z = w^(i-lo+1))
		z.re 		= (z.re * w.re) - (z.im * w.im);
 		z.im 		= (z.im * w.re) + (z.re * w.im);  
        }

	// square the root of unity w (n roots in total) -> root of unity v (n/2 roots in total)
	v.re 		= (w.re * w.re) - (w.im * w.im);
 	v.im 		= (w.im * w.re) + (w.re * w.im); 
 
	// divide and conquer
	// recursive function call for 1st half
        fft_func (a, m, lo, v);
	// recursive function call for 2nd half
        fft_func (a, m, lo+m, v);

	// after recursion: shuffle values
        shuffle  (a, n, lo);
    }
}

*/



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/**
	reverses byte positioning

	@param x: signed short int number
	@return number, where byte positions are reverse
*/
int16 ntohl(int16 x)
{

	/*char *s = (char *)&x;
	return (int16)(s[0] << 8 | s[1]);*/
	char tmp[2]; char tmp2; int16 result;
	
	// copy value into char array
	memcpy(tmp, &x, sizeof(int16));
	
	// change byte order
	tmp2	= tmp[0];
	tmp[0]	= tmp[1];
	tmp[1]	= tmp2;

	// copy back
	memcpy(&result, tmp, sizeof(int16));
	return result;		
}


/**
	calculates short-time Fourier transformation for sample array

	@param samples: int array of samples
	@param size: size of 'samples'-array
	@param fft_results: pointer results of FFT analysis (double)
	@param sample_rate: sample rate
*/
void fft_analysis (unsigned char * samples, int size, double * fft_results, int sample_rate){

	// real, and imaginary component
	double re;
	double im;
	double hamming_window;
	int f, s;
	int16 sample_value;
	//char current_sample[2];
	double pos = 0.0;
	// calculate other frequencies
	//double max = 0;
	//int max_i;
	//int number = 0;
	//long int max_position = 0;
	double pos2 = 1.0 * interval_min;
	//double threshold = 25.0;
	double squared_amplitude;
	
	// exception handling
	//if (sample_rate <= 0 || size <= 0) return;

	// calculate frequency f=0
	re = 0;

	//for (s=0; s<size; s++) printf("\nvalue: %d", (int)measurement[s]);

	for (s=0; s<size/2; s++){

		//////////////////// TODO: correct?? copy 2 bytes into a short int (reverse order)
		memcpy(&sample_value, &samples[2*s], 2);
		sample_value = ntohl(sample_value);
		//printf("\n!!!!!!!!!! sample value: %d !!!!!!!!!!!!!!!", (int) sample_value);
		//calculate sample[s] * hamming_window[s]
		pos = ((((4.0*s)/(size)) - 1.0)/2.0);
		hamming_window = (0.85*cos(2.0*M_PI*pos)) + 1.0;
		//printf("\nhamming[%f] = %f", pos, hamming_window);
		sample_value *= hamming_window;

		re += sample_value * cos(0);
	}
	re /= sample_rate;
	if (re<0) fft_results[0] = -re; else fft_results[0] = re;
	event_found = FALSE;
	//printf("\n\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
	//if (interval_min > bytespersecond && interval_min < bytespersecond+1020)
	//if  (fft_results[0] > 30.0001)
		// printf("\n%d \t%f", 0, fft_results[0]);

	//printf("\nsample rate: %d", sample_rate);
	

	for (f=1; f<(sample_rate/(2*FREQUENCY_HOPPING)); f++){

		re = 0;
		im = 0;
		fft_results[f] = 0;
		
		// for all samples
		for (s=0; s<size/2; s++){
			
			
			memcpy(&sample_value, &samples[2*s], 2);
			sample_value = ntohl(sample_value);
			//if (sample_value > 20000) 
			//if (f==1) printf("\n!!!!!!!!!! sample value: %d !!!!!!!!!!!!!!!", (int) sample_value);
			//calculate sample[s] * hamming_window[s]
			pos = ((((4.0*s)/(size)) - 1.0)/2.0);
			hamming_window = (0.85*cos(2.0*M_PI*pos)) + 1.0;
			//printf("\nhamming[%f] = %f", pos, hamming_window);
			sample_value *= hamming_window;

			pos2 = 1.0 * interval_min + (2.0*s);
			pos2 /= (1.0 * bytespersecond);

			re += sample_value * cos(2.0*M_PI*(f*FREQUENCY_HOPPING)*pos2);
			im += sample_value * sin(2.0*M_PI*(f*FREQUENCY_HOPPING)*pos2);

			// current x position sound wave 
			//pos2 += 2.0;			
		}

		// averaging
		re *= 2.0 / sample_rate;
		im *= 2.0 / sample_rate;

 		//re *= 0.5 / (sample_rate * 1.0);
		//im *= 0.5 / (sample_rate * 1.0);


		// this calculates the amplitude
		squared_amplitude = (1.0*re*re) + (1.0*im*im);
		fft_results[f] = sqrt(squared_amplitude);

		//if (interval_min > bytespersecond && interval_min < bytespersecond+1000)
		//if  (fft_results[f*FREQUENCY_HOPPING] > 10.0001) 
		//		printf("\n%d, %f", f*FREQUENCY_HOPPING, fft_results[f]);
		//if (f*FREQUENCY_HOPPING == 52) printf("\namplitude[%d]: %f", f*FREQUENCY_HOPPING, fft_results[f]);

		//if (threshold < fft_results[f] && (f*FREQUENCY_HOPPING < 12000)){
		//	if (fft_results[f] > max){ 

		//		max		= fft_results[f];
		//		max_i		= f*FREQUENCY_HOPPING;	
		//		max_position	= interval_min + (2*s);			
		//	}
		//	number ++;
		//	//printf("\namplitude[%d]: %f", f*FREQUENCY_HOPPING, fft_results[f]);
		//}	
	}

	// amplitude of frequency over specific threshold => beat
	/*if (max > threshold && max_i > 9){
		
		// found event
		event_found	= TRUE;
		event_salience	= (int) max;
		event_position 	= max_position;		
		//printf("\namplitude[%d]: %f \t(number of frequencies in total: %d)", max_i, max, number);
	}*/
}


/**
	calculates short-time Fourier transformation for sample array

	@param samples: short int array of samples
	@param size: size of 'samples'-array
	@param fft_results: pointer results of FFT analysis (complex numbers)
	@param sample_rate: sample rate
*/
void fft_analysis_try (int16 * samples, int size, complex_number * fft_results, int sample_rate){

	// real, and imaginary component
	double re;
	double im;
	int k, s;
	double pos = 0.0;
	double pos2 = 1.0 * interval_min;

	double hamming_window[size];
	// calculate hamming window
	for (s=0; s<size; s++){

		// calculate position
		pos = ((((2.0*s)/(size)) - 1.0)/2.0);
		hamming_window[s] = (0.85*cos(2.0*M_PI*pos)) + 1.0;

	}

	// calculate frequency f=0
	re = 0;
	for (s=0; s<size; s++){

		re += samples[0] * cos(0) * hamming_window[s];
	}
	re /= sample_rate;
	if (re<0) fft_results[0].re = (int)-re; else fft_results[0].re = (int)re;
	fft_results[0].im = 0;
	
	// calculate other frequencies
	//for (k=1; k<size; k++){
	for (k=1; k<(sample_rate/(2*FREQUENCY_HOPPING)); k++){

		re = 0;
		im = 0;
		
		// for all samples
		for (s=0; s<size; s++){
			
			//calculate sample[s] * hamming_window[s]
			pos2 = 1.0 * interval_min + (2.0*s);
			pos2 /= (1.0 * bytespersecond);

			// TODO: 			

			re += samples[s] * cos(2.0*M_PI*k*FREQUENCY_HOPPING*pos2) * hamming_window[s];
			im += samples[s] * sin(2.0*M_PI*k*FREQUENCY_HOPPING*pos2) * hamming_window[s];
			
		}

		// averaging
		re *= 2.0 / sample_rate; // * factor 2 (because of hamming window)
		im *= 2.0 / sample_rate; // same reason

		// results
		fft_results[k].re = (int)re;
		fft_results[k].im = (int)im;			
	}	
}



/**
	calculates short-time Fourier transformation for sample array

	@param samples: short int array of samples
	@param size: size of 'samples'-array
	@param fft_results: pointer results of FFT analysis (complex numbers)
	@param sample_rate: sample rate
*/
void fft_analysis_new (int16 * samples, int size, observation * fft_results, int sample_rate){

	// real, and imaginary component
	double re;
	double im;
	int k, s;
	double pos = 0.0;
	double pos2 = 1.0 * interval_min;

	double hamming_window[size];
	// calculate hamming window
	for (s=0; s<size; s++){

		// calculate position
		pos = ((((2.0*s)/(size)) - 1.0)/2.0);
		hamming_window[s] = (0.85*cos(2.0*M_PI*pos)) + 1.0;

	}

	// calculate frequency f=0
	re = 0;
	for (s=0; s<size; s++){

		re += samples[0] * cos(0) * hamming_window[s];
	}
	re /= size;
	if (re<0) fft_results->fft[0].re = (int)-re; else fft_results->fft[0].re = (int)re;
	fft_results->fft[0].im = 0;
	
	// calculate other frequencies
	for (k=1; k<size; k++){

		re = 0;
		im = 0;
		
		// for all samples
		for (s=0; s<size; s++){
			
			//calculate sample[s] * hamming_window[s]
			pos2 = 1.0 * interval_min + (2.0*s);
			pos2 /= (1.0 * bytespersecond);

			// TODO: 			

			re += samples[s] * cos(2.0*M_PI*k*pos2) * hamming_window[s];
			im += samples[s] * sin(2.0*M_PI*k*pos2) * hamming_window[s];
			
		}

		// averaging
		re *= 2.0 / size; // * factor 2 (because of hamming window)
		im *= 2.0 / size; // same reason

		// results
		fft_results->fft[k].re = (int)re;
		fft_results->fft[k].im = (int)im;			
	}	
}
