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
#ifdef __POSIX__
#include <mqueue.h>
#endif
#endif
#include "config.h"
#include "bubblesort.h"
#include "sort8k.h"

#ifdef __POSIX__
extern mqd_t mb_start, mb_done;
#else
extern cyg_handle_t mb_start_handle, mb_done_handle;
#endif

void sort8k_entry( cyg_addrword_t data )
{
#ifdef USE_ECOS
#ifndef __POSIX__
    void *ptr;

    while ( 1 ) {
        // get pointer to next chunk of data
        ptr = cyg_mbox_get( mb_start_handle );
        // sort it
        bubblesort( ( unsigned int * ) ptr, N );
        // return
        cyg_mbox_put( mb_done_handle, ( void * ) 23 );                         // return any value
    }
#endif
#endif
}

void *sort8k_entry_posix( void *data ) {
#ifdef USE_ECOS
#ifdef __POSIX__
    void *ptr;
    unsigned int dummy = 23;
    
    while ( 1 ) {
        mq_receive(mb_start, (void*)&ptr, sizeof(ptr), 0);
        bubblesort( (unsigned int*) ptr, N);
        mq_send(mb_done, (void*)&dummy, sizeof(dummy), 0);
    }
#endif
#endif
    return (void*)0;
}

