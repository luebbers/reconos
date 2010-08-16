///
/// \file sort_ecos_pc.c
/// Sorting application. Plain single-threaded version.
/// version.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#include <stdio.h>
#include <time.h>
#include "config.h"
#include "bubblesort.h"
#include "merge.h"
#include "data.h"
#include "timing.h"

unsigned int buf_a[SIZE];
unsigned int buf_b[SIZE];       // buffer for merging
unsigned int *data;

int main( int argc, char argv[] )
{

    unsigned int i;
    timing_t t_start, t_stop, t_gen, t_sort, t_merge, t_check;

    printf( "-------------------------------------------------------\n"
            "ReconOS hardware multithreading case study (sort)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            "Standalone, single-threaded software version (" __FILE__ ")\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

    data = buf_a;

    //----------------------------------
    //-- GENERATE DATA
    //----------------------------------
    printf( "Generating data..." );
    t_start = gettime(  );
    generate_data( data, SIZE );
    t_stop = gettime(  );
    t_gen = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

    //----------------------------------
    //-- SORT DATA
    //----------------------------------
    printf( "Sorting data..." );
    t_start = gettime(  );
    for ( i = 0; i < SIZE; i += N ) {
        bubblesort( &data[i], N );
    }
    t_stop = gettime(  );
    t_sort = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

    //----------------------------------
    //-- MERGE DATA
    //----------------------------------
    printf( "Merging data..." );
    t_start = gettime(  );
    data = recursive_merge( data, buf_b, SIZE, N, simple_merge );
    t_stop = gettime(  );
    t_merge = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

    //----------------------------------
    //-- CHECK DATA
    //----------------------------------
    printf( "Checking sorted data..." );
    t_start = gettime(  );
    if ( check_data( data, SIZE ) != 0 )
        printf( "CHECK FAILED!\n" );
    else
        printf( "check successful.\n" );
    t_stop = gettime(  );
    t_check = calc_timediff_ms( t_start, t_stop );

    printf( "\nRunning times (size: %d words):\n"
            "\tGenerate data: %d ms\n"
            "\tSort data    : %d ms\n"
            "\tMerge data   : %d ms\n"
            "\tCheck data   : %d ms\n"
            "\nTotal computation time (sort & merge): %d ms\n",
            SIZE, t_gen, t_sort, t_merge, t_check, t_sort + t_merge );

}
