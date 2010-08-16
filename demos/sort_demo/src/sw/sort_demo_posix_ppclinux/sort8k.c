///
/// \file sort8k.c
/// eCos thread entry function for sorting
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#ifdef USE_ECOS
#include <cyg/infra/diag.h>
#include <cyg/kernel/kapi.h>
#else
#include <mqueue.h>
#endif
#include "config.h"
#include "bubblesort.h"
#include "sort8k.h"

// REMOVEME
#include "timing.h"



#include <stdio.h>

#ifdef USE_ECOS
extern cyg_handle_t mb_start_handle, mb_done_handle;
#else
extern mqd_t mb_start, mb_done;
#endif

void sort8k_entry( cyg_addrword_t data )
{
#ifdef USE_ECOS
    void *ptr;
    unsigned int thread_number = ( unsigned int ) data;

    while ( 1 ) {
        // get pointer to next chunk of data
        ptr = cyg_mbox_get( mb_start_handle );
        // sort it
        bubblesort( ( unsigned int * ) ptr, N );
        // return
        cyg_mbox_put( mb_done_handle, ( void * ) 23 );                         // return any value
    }
#endif
}

#ifndef USE_ECOS
void *sort8k_entry_posix( void *data ) {
    void *ptr;
    unsigned int dummy = 23;
    timing_t t_start = 0, t_stop = 0;
    
    while ( 1 ) {
        mq_receive(mb_start, (void*)&ptr, sizeof(ptr), 0);
//        fprintf(stderr, "*");

        t_start = gettime();
        bubblesort( (unsigned int*) ptr, N);
        t_stop = gettime();
        fprintf(stderr, "bubble: %d ms\n", calc_timediff_ms( t_start, t_stop ));
        mq_send(mb_done, (void*)&dummy, sizeof(dummy), 0);
    }
}
#endif

