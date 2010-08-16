///
/// \file  sendvideo.c
/// Send, display and save audio streams from a file.
/// 
/// This tool is able to open a audio file,
/// capture audio data from it, and stream it over
/// a TCP/IP connection. It expectss uncompressed wav-files
/// (mono, sample rate 44100 Hz, 16 bits per sample.
/// The sound data is streamed "as is".
/// 
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       12.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group 
//
// (C) Copyright University of Paderborn 2007. Permission to copy,
// use, modify, sell and distribute this software is granted provided
// this copyright notice appears in all copies. This software is
// provided "as is" without express or implied warranty, and with no
// claim as to its suitability for any purpose.
//
// -------------------------------------------------------------------------
// Major Changes:
// 
// 12.09.2007   Enno Luebbers   File created
// 10.03.2009	Markus Happe	adapted to send sound files
// 

// INCLUDES ================================================================

#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h> // for 'basename()'

// header for application
//#include "../../sw/header/config.h"
// header for number of particles
//#include "../../sw/framework/header/particle_filter.h"


//! input audio file
//#define INPUTFILE "./../audio/stepmom_mono.wav"
#define INPUTFILE "./../audio/beatallica_mono.wav"
//#define INPUTFILE "./../audio/madness_mono.wav"
//#define INPUTFILE "./../audio/testSound.wav"
//#define INPUTFILE "./../audio/beethoven_mono.wav"
//! output audio file
//#define OUTPUTFILE "./../audio/stepmom_output.wav"
#define OUTPUTFILE "./../audio/beatallica_output_test.wav"
//#define OUTPUTFILE "./../audio/madness_output.wav"
//#define OUTPUTFILE "./../audio/testSound_output.wav"
//#define OUTPUTFILE "./../audio/beethoven_output.wav"

#include "tcp_connection.h"
#include "debug.h"

#define TRUE  1
#define FALSE 0




// CONSTANTS ===============================================================

#define MAX_HOSTNAMELEN 256		///< maximum length of hostname string
#define MAX_FILENAMELEN 256		///< maximum length of filenames


// GLOBAL VARIABLES ========================================================

// options
char host[MAX_HOSTNAMELEN] = "localhost";       ///< hostname to connect to
char inputfilename[MAX_HOSTNAMELEN]	= "./../audio/madness_mono.wav";  
char outputfilename[MAX_HOSTNAMELEN]	= "./../audio/madness_output_test.wav"; 
int port = 6666;                ///< port to connect to
int max_frames = 5000;         ///< max frames, can be set by parameter


char line[100000]; 
FILE * inputstream;
FILE * outputstream;
int byterate;
int sample_rate;
int bytespersecond;





///
/// Prints the program usage.
///
/// \param      basename        the name of this program's executable
/// 
void usage( char *basename )
{
    printf( "%s: send and save audio streams.\n"
            "(c) 2007 Enno Luebbers (luebbers@reconos.de)\n"
            "Computer Engineering Group, University of Paderborn\n\n"
            "USAGE:\n"
            "       %s [-h] [-o <outfile>] [-p <port>] [-i <infile>] <host>\n"
            "\n"
            "       -h                  display this help\n"
            "       -o <outfile>        save audio file to <outfile>\n"
            "       -m <number_of_frames>  number of frames to track\n"
            "\n"
            "DESTINATION OPTIONS:\n"
            "       <host>              host to send to\n"
            "       -p <port>           send to port <port> (default: 6666)\n"
            "\n", basename, basename );
}


///
/// Parses command line arguments using getopt() and sets the global
/// option variables.
///
/// \param      argc            number of command line arguments
/// \param      argv            pointer to array of command line argument
///                             strings
///
void parse_args( int argc, char *argv[] )
{

    int c;


    while ( 1 ) {
        c = getopt( argc, argv, "qo:f:F:i:c::p:m:h" );

        if ( c == -1 )
            break;

        switch ( c ) {

        case 'o':
            strncpy( outputfilename, optarg, MAX_FILENAMELEN );
            break;

        case 'p':
            port = atoi( optarg );
            break;

        case 'm':
            max_frames = atoi( optarg );
            break;

        case 'i':
            strncpy( inputfilename, optarg, MAX_FILENAMELEN );
            break;

        case '?':
        case 'h':
        default:
            usage( basename( argv[0] ) );
            exit( 1 );
            break;
        }
    }

    // we need exactly one argument (the host name)
    if ( optind >= argc ) {
        fprintf( stderr, "no target host specified.\n" );
        usage( basename( argv[0] ) );
        exit( 1 );
    }

    if ( optind < argc - 1 ) {
        fprintf( stderr, "too many arguments.\n" );
        usage( basename( argv[0] ) );
        exit( 1 );
    }

    strncpy( host, argv[optind], MAX_HOSTNAMELEN );

}



////////////////////////////////////////////////////////////////////////////
// MAIN ////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///
/// Main program.
///
int main( int argc, char *argv[] )
{

	char line[10]; 
	inputstream = malloc(sizeof(FILE));
	outputstream = malloc(sizeof(FILE));
	int * number = malloc(sizeof(int));
	tcp_connection *con;
	int byterate;
	int j;
	long int i;
	int result;
	int counter;

	parse_args(argc, argv);

	inputstream = fopen( inputfilename, "r"); // open file
	outputstream = fopen( outputfilename, "w"); // open file
	if (inputstream == NULL) // file not found or other error
	{
		printf( "The file '%s' was not opened\n", inputfilename );//error
		return;
	}; printf( "The file '%s' was opened\n", inputfilename );

	if (outputstream == NULL) // file not found or other error
	{
		printf( "The file '%s' was not opened\n", outputfilename  );//error
		return;
	}; printf( "The file '%s' was opened\n", outputfilename );

 	//printf( "The files '%s', '%s' are open.\n\n", INPUTFILE, OUTPUTFILE);
	//printf ("----------------------------------------------------------------\n");
	//printf ("---------------          WAVE-HEADER              --------------\n");
	//printf ("----------------------------------------------------------------\n");
	//printf ("\nI. RIFF WAV CHUNK\n");

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
 
	*/

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		//printf ("-- (1) group ID\t\t\t: %s\n", line);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		//printf ("-- (2) file size in byte - 8\t: %d\n",*number);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		//printf ("-- (3) riff type\t\t: %s\n", line);
	};

	//printf ("----------------------------------------------------------------\n");
	//printf ("\nII. FORMAT CHUNK\n");


	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);

		//printf ("-- (1) chunk ID\t\t\t\t\t\t: %s\n", line);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		//printf ("-- (2) length of fmt data [16]\t\t\t\t: %d\n",*number);
	};

	*number = 0;

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		//printf ("-- (3) format-tag [1=PCM]\t\t\t\t: %d\n", *number);
	};

	*number = 0;

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		//printf ("-- (4) channels [1=mono, 2=stereo]\t\t\t: %d\n", *number);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		sample_rate = *number;
		//printf ("-- (5) sample rate [e.g 44100]\t\t\t\t: %d\n", *number);
	};

	if (!feof(inputstream)) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		*number /= 2;
		//printf ("-- (6) bytes/second [sample rate * block align]\t\t: %d\n", *number);
	};

	byterate = *number;

	*number = 0;

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		*number /= 2;
		//printf ("-- (7) block align [channels * bits per sample / 8]\t: %d\n", *number);
	};

	*number = 0;

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 3, inputstream);
		fwrite(line,1,2,outputstream);
		memcpy(number, line, 2);
		//printf ("-- (8) bits per sample [8 or 16]\t\t\t: %d\n", *number);
	};

	//printf ("----------------------------------------------------------------\n");
	//printf ("\nIII. SOUND DATA CHUNK\n");

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		//printf ("-- (1) chunk ID\t\t: %s\n", line);
	};

	if (!feof(inputstream) ) // read to end of file
	{
		fgets (line, 5, inputstream);
		fwrite(line,1,4,outputstream);
		memcpy(number, line, 4);
		*number /= 2;
		//printf ("-- (2) chunk length\t: %d\n", *number);
	};

	long int chunk_length = *number;

	//printf ("-- (3) sample data\t:\n");

	bytespersecond = byterate;
	#define MEASUREMENT_BUFFER 8192//16384

	char sound;

	con = tcp_connection_create( host, port );
 	if ( !con ) {
		fprintf( stderr, "unable to connect to %s, port %d\n", host, port );
		return;
	}
	printf( "Connected to %s, port %d.\n", host, port );

	char measurement[MEASUREMENT_BUFFER];
	char beat_track[MEASUREMENT_BUFFER];

	//for(i=0; i<MEASUREMENT_BUFFER * 54; i++) measurement[0] = fgetc (inputstream);
	counter = 0;

	for (i=0; i<(chunk_length/MEASUREMENT_BUFFER); i++)
	{

		if (!feof(inputstream))
		{
		
			//printf("\nsend package no. %d", (int)i);
			// 1. get measurement
			for (j=0; j<MEASUREMENT_BUFFER; j++)
			{
				measurement[j] = fgetc (inputstream);
			}

			// 2. send sound part
			result = tcp_send( con, measurement, MEASUREMENT_BUFFER);

			// 3. receive sound part
			//result = tcp_receive( con, beat_track, MEASUREMENT_BUFFER);

			// 4. write sound part to file
			//for (j=0; j<MEASUREMENT_BUFFER; j++)
			//{
			//	fwrite(&beat_track[j],1,1,outputstream);
			//}
		}
		counter++;
		if (max_frames<=counter)
		{
			i = chunk_length/MEASUREMENT_BUFFER;
		}
	}

	// write last bits of sound file
	if (max_frames < 5000)
	{
		while (!feof(inputstream))
		{
			sound = fgetc (inputstream);
			fwrite(&sound,1,1,outputstream);
		}
	}


	// send header information to FPGA
	/*if ( netimage_send_header( con, frame ) <= 0 ) {
		fprintf( stderr, "unable to send header information.\n" );
		exit( 1 );
 	}*/

	// send file information
	//result = tcp_send( con, hsv->imageData, hsv->imageSize);
	//result = tcp_send( con, (char *) region, 4 * sizeof(int));

  
	

	// send sth:
	// result = tcp_send( con, frame->imageData, frame->imageSize );
	// receive sth:
	// result = tcp_receive( con, particles_data, ((number_of_particles+1) * sizeof(particle_data)));
	// if (result > 0)
	// byteconversion: 
	// particles_data[i].best_particle = ntohl(particles_data[i].best_particle);


	fclose( inputstream );
	fclose( outputstream );


	return 0;
}





