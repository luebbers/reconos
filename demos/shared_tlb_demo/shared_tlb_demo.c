///
/// \file shared_tlb_demo.c
///
/// This program tests the operation of a shared TLB and the TLB arbiter.
/// 
/// The testing algorithm works a follows:
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

// message queues + attributes
mqd_t mbox00, mbox01, mbox10, mbox11;     // mbox0: main->thread, mbox1: thread->main
struct mq_attr mbox00_attr, mbox01_attr, mbox10_attr, mbox11_attr;
static rthread_attr_t rattr[2];
static pthread_t posix_thread[2];
static unsigned long pgd;

static inline int posix_hwt_create(int nslot, void * init_data, reconos_res_t * res, int nres)
{

        rthread_attr_init(&rattr[nslot]);
        rthread_attr_setslotnum(&rattr[nslot], nslot);
        rthread_attr_setresources(&rattr[nslot], res, nres);

        //pthread_attr_init(&posix_attr);

        return rthread_create(&posix_thread[nslot], &rattr[nslot], init_data);
}


reconos_res_t thread_resources0[2] =
{
	{&mbox00, PTHREAD_MQD_T},
	{&mbox01, PTHREAD_MQD_T}
};

reconos_res_t thread_resources1[2] =
{
	{&mbox10, PTHREAD_MQD_T},
	{&mbox11, PTHREAD_MQD_T}
};

void put_msg(int slot, unsigned long msg){
	int retval;
	
	if(slot == 0){
		retval = mq_send(mbox00, (char*)&msg, 4, 10);
	} else {
		retval = mq_send(mbox10, (char*)&msg, 4, 10);
	}
	if (retval < 0) {
		perror("mq_send");
		exit(5);
	}
}


unsigned long get_msg(int slot){
	unsigned long result;
	int retval;
	
	if(slot == 0){
		retval = mq_receive(mbox01, (char*)&result, 4, NULL);
	} else {
		retval = mq_receive(mbox11, (char*)&result, 4, NULL);
	}
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

unsigned int lfsr(unsigned int state)
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
	int error, i;
	int num_iterations;
	int seed = 12345;
	unsigned int lfsr0 = 0;
	unsigned int lfsr1 = 0;
	unsigned int index0 = 0;
	unsigned int index1 = 0;
	unsigned int result0 = 0;
	unsigned int result1 = 0;
	unsigned int *mem;

	if(argc < 2 || argc > 3) exit_usage(argv[0]);

	num_iterations = atoi(argv[1]);
	
	if(argc == 3) seed = atoi(argv[2]);

	fprintf(stderr,"Allocating %d pages. Accessing memory %d times.\n", NUM_PAGES, num_iterations);

	mem = allocate_memory(NUM_PAGES);

	setup_mbox(&mbox00,&mbox00_attr,"/mbox00");
	setup_mbox(&mbox01,&mbox01_attr,"/mbox01");
	setup_mbox(&mbox10,&mbox10_attr,"/mbox10");
	setup_mbox(&mbox11,&mbox11_attr,"/mbox11");

	//fprintf(stderr,"-- creating hw thread... ");

	fprintf(stderr,"Creating delegate thread 0...\n");

	error = posix_hwt_create(0,(void*)pgd, thread_resources0, 2);
	if(error){
		perror("pthread_create (slot 0)");
		exit(2);
	}
		
	fprintf(stderr,"Creating delegate thread 1...\n");

	error = posix_hwt_create(1,(void*)pgd, thread_resources1, 2);
	if(error){
		perror("pthread_create (slot 1)");
		exit(2);
	}
	
// ------------------------------------------------------------------------------------------	

	srand(seed);
	
	fprintf(stderr,"initializing memory...\n");

	for(i = 0; i < NUM_PAGES; i++){
		mem[i*1024 + 0] = rand();
		mem[i*1024 + 1] = rand();	
	}	


	fprintf(stderr,"flushing cache...\n");
	flush_dcache();

	fprintf(stderr,"starting threads...\n");

	put_msg(0,num_iterations);
	put_msg(1,num_iterations);

	//put_msg(0,0x00001000);

	put_msg(0,(unsigned int)(mem + 0));
	put_msg(1,(unsigned int)(mem + 1));

	fprintf(stderr,"running simulation...\n");

	fprintf(stderr,"lfsr0 = 0x%08X\n",lfsr0);
	fprintf(stderr,"lfsr1 = 0x%08X\n",lfsr1);

	for(i = 0; i < num_iterations; i++){
		lfsr0 = lfsr(lfsr0 ^ (0x0000FFFF & mem[index0*1024 + 0]));
		lfsr1 = lfsr(lfsr1 ^ (0x0000FFFF & mem[index1*1024 + 1]));
		index0 = 0x3F & lfsr0;
		index1 = 0x3F & lfsr1;
		//fprintf(stderr,"lfsr0 = 0x%08X\n",lfsr0);
		//fprintf(stderr,"lfsr1 = 0x%08X\n",lfsr1);
	}

	result0 = get_msg(0) & 0x0000FFFF;
	result1 = get_msg(1) & 0x0000FFFF;

	fprintf(stderr,"           Thread 0  |  Thread 1\n");
	fprintf(stderr,"target : 0x%08X  |  0x%08X\n", lfsr0, lfsr1);
	fprintf(stderr,"actual : 0x%08X  |  0x%08X\n", result0, result1);

	if(lfsr0 != result0) fprintf(stderr,"Test FAILED for thread 0.\n");
	if(lfsr1 != result1) fprintf(stderr,"Test FAILED for thread 1.\n");

	return 0;
}

