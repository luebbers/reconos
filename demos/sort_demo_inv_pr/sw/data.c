///
/// \file data.c
/// Data generation and verification functions
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#ifdef USE_ECOS
#include <cyg/infra/diag.h>
#endif
#include "data.h"
#include "config.h"

// generates an array of decreasing values
void generate_data_dec( unsigned int *array, unsigned int size )
{
    unsigned int i;
    for ( i = 0; i < size; i++ ) {
        array[i] = size-i-1;
    }
}

// generates an array of increasing values
void generate_data_inc( unsigned int *array, unsigned int size )
{
    unsigned int i;
    for ( i = 0; i < size; i++ ) {
        array[i] = i;
    }
}

// generates an array of random values
void generate_data( unsigned int *array, unsigned int size )
{
    unsigned int i;

#ifdef USE_ECOS
    srand( time( 0 ) );
    for ( i = 0; i < size; i++ ) {
        array[i] = ( unsigned int ) rand(  );
    }
#else
    srandom( time( 0 ) );
    for ( i = 0; i < size; i++ ) {
        array[i] = ( unsigned int ) random(  );
    }
#endif
}

// checks whether data is sorted
int check_data( unsigned int *data, unsigned int size )
{
    int i;

    for ( i = 0; i < size - 1; i++ ) {
        if ( data[i] > data[i + 1] ) {
            //diag_printf("error at data[%d] (=%d) > data[%d] (=%d) of data[0:%d]...", i, data[i], i+1, data[i+1], size-1);
            return -1;
        }
    }
    return 0;
}


// checks whether data is sorted
int check_data_inv( unsigned int *data, unsigned int size )
{
    int i;

    for ( i = 0; i < size - 1; i++ ) {
        if ( data[i] < data[i + 1] ) {
            /*if (SIZE-N <= i){
                 diag_printf("faulty...sorting...in...last...package...but...rest...sorted...correctly...");
                 return -1;
            }*/
            //diag_printf("error at data[%d] (=%d) < data[%d] (=%d) of data[0:%d]...", i, data[i], i+1, data[i+1], size-1);
            return -1;
        }
    }
    return 0;
}
