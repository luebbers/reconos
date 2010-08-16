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
            return -1;
        }
    }
    return 0;
}
