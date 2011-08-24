///
/// \file shared_tlb_demo.c
///
/// This program tests the operation of a shared TLB and the TLB arbiter.
/// 
/// The testing algorithm works as follows:
/// 
/// Software allocates and zeros 64 continuous pages of memory. Each hardware
/// thread is given a word offset into a page, beginning with an offset of 0
/// bytes for thread 0, an offset of 4 bytes for thread 1, and so on.
///     For each page address A_i and each offset O_i, software initiates the
/// memory locations (A_i || O_i) with 4-byte random numbers from rand().
/// Each hardware thread has a LFSR that generates a new page address in every
/// iteration beginning with A_0. The LFSR is then updated by xor-ing with the
/// content of memory location (A_i || O_i).
/// This leads to each of the hardware threads performing a unique random walk
/// over the allocated area. After N iterations the hardware threads' LFSR is
/// compared to the result of a software simulation. Any errors in hardware
/// address translation will (very likely) lead to a mismatch of simulated and
/// actual LFSR states.
///
/// usage: shared_tlb_demo <#iterations> <random seed>
///
/// \author     Andreas Agne <agne@upb.de>
/// \date       22.08.2010
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
// Major Changes:
// 
// 22.08.2010   Andreas Agne   File created

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <mqueue.h>
#include <sys/stat.h>   // for mode constants
#include <fcntl.h>
#include <unistd.h>
#include "reconos.h"
#include "resources.h"

// Number of HWTs in the system:
#define NUM_HWTS 2

// message queues + attributes
mqd_t mbox0[NUM_HWTS], mbox1[NUM_HWTS]; // mbox0: main->thread, mbox1: thread->main
struct mq_attr mbox0_attr[NUM_HWTS], mbox1_attr[NUM_HWTS];
static rthread_attr_t rattr[NUM_HWTS];
static pthread_t posix_thread[NUM_HWTS];
static unsigned long pgd;

static inline int posix_hwt_create(int nslot, void * init_data, reconos_res_t * res, int nres)
{

        rthread_attr_init(&rattr[nslot]);
        rthread_attr_setslotnum(&rattr[nslot], nslot);
        rthread_attr_setresources(&rattr[nslot], res, nres);

        //pthread_attr_init(&posix_attr);

        return rthread_create(&posix_thread[nslot], &rattr[nslot], init_data);
}


reconos_res_t thread_resources[NUM_HWTS][2];

void put_msg(int slot, unsigned long msg){
    int retval;
    
    retval = mq_send(mbox0[slot], (char*)&msg, 4, 10);
    if (retval < 0) {
        perror("mq_send");
        exit(5);
    }
}


unsigned long get_msg(int slot){
    unsigned long result;
    int retval;
    
    retval = mq_receive(mbox1[slot], (char*)&result, 4, NULL);
    if (retval < 0) {
        perror("mq_receive");
        exit(6);
    }

    return result;
}

#define DCACHE_SIZE (1024*1024*40)
int flushmem[3*DCACHE_SIZE/4];
void flush_dcache(void){
    int i;
    for(i = 0; i < 3*DCACHE_SIZE/4; i++){
        flushmem[i]++;
    }
    for(i = 0; i < DCACHE_SIZE/4; i++){
        flushmem[i+DCACHE_SIZE/4]++;
    }
}

unsigned int * allocate_memory(int num_pages){
    unsigned int * mem;
    int i;

    if(posix_memalign(&mem, 4096, 4096*num_pages)){
        fprintf(stderr,"memory allocation failed\n");
        exit(2);
    }	

    for(i = 0; i < 1024*num_pages; i++){
        mem[i] = 0;
    }

    return mem;
}

void exit_usage(const char * progname)
{
    fprintf(stderr,"Usage : %s <n> [seed]\n", progname);
    fprintf(stderr,"\tn    : number of iterations\n");
    fprintf(stderr,"\tseed : random seed\n");
    exit(2);
}

unsigned int lfsr_iterate(unsigned int state)
{
    return (state >> 1) ^ (-(state & 1u) & 0xB400u);
}

// set message queue attributes to non-blocking, 10 messages with 4 bytes each
void setup_mbox(mqd_t *mbox, struct mq_attr * attr, const char * name)
{
    attr->mq_flags = 0;
    attr->mq_maxmsg = 10;
    attr->mq_msgsize = 4;
    attr->mq_curmsgs = 0;
    
    *mbox = mq_open(name, O_RDWR | O_CREAT, S_IRWXU | S_IRWXG, attr);
    if (*mbox == (mqd_t)-1) {
        perror("mq_open");
        fprintf(stderr,"-- unable to create mbox '%s'", name);
    }
    mq_getattr(*mbox, attr);
}

// This must be the same number the hardware thread uses
#define NUM_PAGES 64

int main(int argc, char **argv) {
    int error, i,j;
    int num_iterations;
    int seed = 12345;
    unsigned int lfsr[NUM_HWTS];
    unsigned int index[NUM_HWTS];
    unsigned int result[NUM_HWTS];
    unsigned int *mem;

    if(argc < 2 || argc > 3) exit_usage(argv[0]);

    num_iterations = atoi(argv[1]);
    
    if(argc == 3) seed = atoi(argv[2]);
    
    fprintf(stderr,"Allocating %d pages. Accessing memory %d times.\n", NUM_PAGES, num_iterations);
    fprintf(stderr,"Using %d hardware threads\n",NUM_HWTS);
    
    mem = allocate_memory(NUM_PAGES);

    for(i = 0; i < NUM_HWTS; i++){
        char name[32];
        snprintf(name,32,"/mbox0%d",i);
        setup_mbox(&mbox0[i],&mbox0_attr[i],name);
        snprintf(name,32,"/mbox1%d",i);
        setup_mbox(&mbox1[i],&mbox1_attr[i],name);
    }
    //setup_mbox(&mbox00,&mbox00_attr,"/mbox00");
    //setup_mbox(&mbox01,&mbox01_attr,"/mbox01");
    //setup_mbox(&mbox10,&mbox10_attr,"/mbox10");
    //setup_mbox(&mbox11,&mbox11_attr,"/mbox11");

    //fprintf(stderr,"-- creating hw thread... ");

    fprintf(stderr,"Creating delegate threads...\n");

    for(i = 0; i < NUM_HWTS; i++){
        thread_resources[i][0].ptr = &mbox0[i];
        thread_resources[i][0].type = PTHREAD_MQD_T;
        thread_resources[i][1].ptr = &mbox1[i];
        thread_resources[i][1].type = PTHREAD_MQD_T;
        error = posix_hwt_create(i,(void*)pgd, thread_resources[i], 2);
        if(error){
            perror("pthread_create");
            exit(2);
        }
    }
        
// ------------------------------------------------------------------------------------------	

    srand(seed);
    
    fprintf(stderr,"initializing memory...\n");

    for(i = 0; i < NUM_PAGES; i++){
        for(j = 0; j < NUM_HWTS; j++){
            mem[i*1024 + j] = rand();
        }
    }	


    fprintf(stderr,"flushing cache...\n");
    flush_dcache();

    fprintf(stderr,"starting threads...\n");

    for(i = 0; i < NUM_HWTS; i++){
        put_msg(i,num_iterations);
    }

    //put_msg(0,0x00001000);

    for(i = 0; i < NUM_HWTS; i++){
        put_msg(i,(unsigned int)(mem + i));
    }

    fprintf(stderr,"running simulation...\n");

    for(i = 0; i < NUM_HWTS; i++){
        lfsr[i] = index[i] = result[i] = 0;
    }

    for(i = 0; i < num_iterations; i++){
        for(j = 0; j < NUM_HWTS; j++){
            lfsr[j] = lfsr_iterate(lfsr[j] ^ (0x0000FFFF & mem[index[j]*1024 + j]));
            index[j] = 0x3F & lfsr[j];
        }

    }
    
    for(i = 0; i < NUM_HWTS; i++){
        result[i] = get_msg(i) & 0x0000FFFF;
    }

    fprintf(stderr,"       ");
    for(i = 0; i < NUM_HWTS; i++){
        fprintf(stderr,"|  Thread %d    ",i);
    }
    fprintf(stderr,"\ntarget ");
    for(i = 0; i < NUM_HWTS; i++){
        fprintf(stderr,"|  0x%08X  ",lfsr[i]);
    }
    fprintf(stderr,"\nactual ");
    for(i = 0; i < NUM_HWTS; i++){
        fprintf(stderr,"|  0x%08X  ",result[i]);
    }
    fprintf(stderr,"\n");

    for(i = 0; i < NUM_HWTS; i++){
        if(lfsr[i] != result[i]) fprintf(stderr,"Test FAILED for thread %d.\n",i);
    }

    return 0;
}

