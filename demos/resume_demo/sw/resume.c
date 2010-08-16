///
/// \file resume.c
///
/// Test application for thread yield and resume
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       05.03.2009
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//
// Major Changes:
//
// 05.03.2009   Enno Luebbers   File created.

#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <xcache_l.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include <cyg/hal/icap.h>

#include "timing.h"

#include "prm0_wait_and_yield_routed_partial.bit.h"
#include "prm0_just_wait_routed_partial.bit.h"

#define STACK_SIZE 8192
#define USE_CACHE 1

#define MEMCOPY_LOOP_COUNT 10000
#define ICAP_LOOP_COUNT 100
#define MAX_STATE_SIZE 16384
#define STATE_SIZE_STEP 2

#define BENCHMARK_THREADS
//#define BENCHMARK_OPS

// bitstreams and circuits
// wait_and_yield
reconos_bitstream_t wait_and_yield_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_wait_and_yield_routed_partial_bit,
    .size     = PRM0_WAIT_AND_YIELD_ROUTED_PARTIAL_BIT_SIZE
};
reconos_circuit_t wait_and_yield_circuit = {
    .name     = "WAIT_AND_YIELD",
    .bitstreams = {&wait_and_yield_bitstream_0},
    .num_bitstreams = 1
};
// just_wait
reconos_bitstream_t just_wait_bitstream_0 = {
    .slot_num = 0,
    .data     = prm0_just_wait_routed_partial_bit,
    .size     = PRM0_JUST_WAIT_ROUTED_PARTIAL_BIT_SIZE
};
reconos_circuit_t just_wait_circuit = {
    .name     = "JUST_WAIT",
    .bitstreams = {&just_wait_bitstream_0},
    .num_bitstreams = 1
};

pthread_t wait_and_yield_thread;
pthread_attr_t wait_and_yield_swattr;
rthread_attr_t wait_and_yield_hwattr;
char wait_and_yield_stack[STACK_SIZE];
uint32 wait_and_yield_init_data;
pthread_t just_wait_thread;
pthread_attr_t just_wait_swattr;
rthread_attr_t just_wait_hwattr;
char just_wait_stack[STACK_SIZE];
uint32 just_wait_init_data;

#define T2_START    0           // 0 ms
#define T2_STEP     38          // 50 ms
#define T2_END      380         // 500 ms

#define TD_START    0           // 0 ms
#define TD_STEP     5           // 50 ms
#define TD_END      100          // 1000 ms

int do_yield = 1;
int t_exec_1 = 50;      // 66 ms
int t_exec_2 = 500;     // 655 ms
int t_delay = 100;      // 1000 ms

// FIXME: remove me!
extern uint32 t_load_start;
extern uint32 t_load_end;
// FIXME: remove me!


int main( int argc, char *argv[] )
{
    timing_t t_start, t_stop, t_icap, t_memcopy_memhw, t_memcopy_hwmem, t_threads;

// FIXME: remove me!
    timing_t t_init_start;
// FIXME: remove me!

    int i, j;

    printf( "-------------------------------------------------------\n"
            "ReconOS hardware multithreading case study (resume)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            __FILE__ "\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

    // NOTE: for icap_init(), the ICAP interface may not be cached!
    printf( "initializing ICAP interface..." );
    icap_init();
    printf( "done\n" );

#ifdef USE_CACHE
    printf( "enabling data cache for external ram\n" );
//    XCache_EnableDCache( 0xF8080000 );
    XCache_EnableDCache( 0xF8000000 );
#else
    printf( "data cache disabled\n" );
    XCache_DisableDCache(  );
#endif
    

#ifdef BENCHMARK_THREADS
    for ( t_exec_2 = T2_START; t_exec_2 <= T2_END; t_exec_2 += T2_STEP ) {
        for ( t_delay = TD_START; t_delay < TD_END; t_delay += TD_STEP ) {

            for (do_yield = 0; do_yield <= 1; do_yield++) {
#endif
// FIXME: remove me
                t_init_start = gettime();
// FIXME: remove me
                pthread_attr_init(&wait_and_yield_swattr);
                pthread_attr_setstacksize(&wait_and_yield_swattr, STACK_SIZE);
                rthread_attr_init(&wait_and_yield_hwattr);
                rthread_attr_setcircuit(&wait_and_yield_hwattr, &wait_and_yield_circuit);
//                rthread_attr_setstatesize(&wait_and_yield_hwattr, 16384);
                wait_and_yield_init_data = (((t_exec_1/2) & 0x00007FFF) << 16) | (t_delay & 0x0000FFFF) | (do_yield ? 0x80000000 : 0x00000000);

                pthread_attr_init(&just_wait_swattr);
                pthread_attr_setstacksize(&just_wait_swattr, STACK_SIZE);
                rthread_attr_init(&just_wait_hwattr);
                rthread_attr_setcircuit(&just_wait_hwattr, &just_wait_circuit);
//                rthread_attr_setstatesize(&just_wait_hwattr, 16384);
                just_wait_init_data = t_exec_2 & 0x00007FFF;

#ifdef BENCHMARK_THREADS
                t_start = gettime();

                rthread_create(&wait_and_yield_thread, &wait_and_yield_swattr, &wait_and_yield_hwattr, (void*)wait_and_yield_init_data);
                rthread_create(&just_wait_thread, &just_wait_swattr, &just_wait_hwattr, (void*)just_wait_init_data);

                pthread_join( wait_and_yield_thread, NULL );
                pthread_join( just_wait_thread, NULL );

                t_stop = gettime();
                t_threads = calc_timediff_cyc( t_start, t_stop );
                printf("t_exec_1: %.3f ms, t_exec_2: %.3f ms, t_delay : %.1f ms, do_yield: %d. total run time: %d ms\n",
                        t_exec_1 * 1.31072, t_exec_2 * 1.31072, t_delay * 10.0, do_yield, t_threads / 100000);
// FIXME: remove me
                printf("\t\t\tt_init_start: %d\n", t_init_start);
// FIXME: remove me
            }
        }
    }
#endif

#ifdef BENCHMARK_OPS
    printf("measuring ICAP reconfiguration performance (%d reconfigurations of bitstream size %d bytes)\n",
            ICAP_LOOP_COUNT, just_wait_bitstream_0.size);
    t_icap = 0;
    for (i = 0; i < ICAP_LOOP_COUNT; i++) {
//        printf(".");
        t_start = gettime(  );
        icap_load( just_wait_bitstream_0.data, just_wait_bitstream_0.size );
        t_stop = gettime(  );
        t_icap += calc_timediff_cyc( t_start, t_stop );
    }
    t_icap /= ICAP_LOOP_COUNT;
    printf("average: %d cycles\n", t_icap);


    printf("measuring memcopy HW->MEM latency (%d loops)\n", MEMCOPY_LOOP_COUNT);
    for (j = 1; j <= MAX_STATE_SIZE; j*= STATE_SIZE_STEP) {
        t_memcopy_hwmem = 0;
        for (i = 0; i < MEMCOPY_LOOP_COUNT; i++ ) {
//            printf(".");
            t_start = gettime(  );
            XCache_InvalidateDCacheRange((unsigned int)(0x20000000 + 0x4000), j);
            memcpy(just_wait_hwattr.state_buf, 0x20000000 + 0x4000, j);
            t_stop = gettime(  );
            t_memcopy_hwmem += calc_timediff_cyc( t_start, t_stop );
        }
        t_memcopy_hwmem /= MEMCOPY_LOOP_COUNT;
        printf("average (%d bytes): %d cycles\n", j, t_memcopy_hwmem);
    }

    printf("measuring memcopy MEM->HW latency (%d loops)\n", MEMCOPY_LOOP_COUNT);
    for (j = 1; j <= MAX_STATE_SIZE; j*= STATE_SIZE_STEP) {
        t_memcopy_memhw = 0;
        for (i = 0; i < MEMCOPY_LOOP_COUNT; i++ ) {
 //           printf(".");
            t_start = gettime(  );
            memcpy(0x20000000 + 0x4000, just_wait_hwattr.state_buf, j);
            XCache_FlushDCacheRange((unsigned int)(0x20000000 + 0x4000), j);
            t_stop = gettime(  );
            t_memcopy_memhw += calc_timediff_cyc( t_start, t_stop );
        }
        t_memcopy_memhw /= MEMCOPY_LOOP_COUNT;
        printf("average (%d bytes): %d cycles\n", j, t_memcopy_memhw);
    }
#endif
    for (;;);

}
