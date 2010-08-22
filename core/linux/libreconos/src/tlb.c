///
/// \file tlb.c
///
/// ReconOS TLB access functions.
///
/// \author     Andreas Agne <agne@upb.de>
/// \date       22.08.2010
//
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
//
// Major changes
// 22.08.2010    Andreas Agne        File created

#include "reconos.h"

#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

static int open_tlb()
{
	int tlb_fd = open("/dev/tlb0",O_RDWR);
	if(tlb_fd == -1){
		perror("open '/dev/tlb0'\n");
	}
	return tlb_fd;
}

static unsigned int tlb_read(int tlb_fd, int reg)
{
	off_t off;
	ssize_t len;
	unsigned long value;
	
	off = lseek(tlb_fd, reg*4, SEEK_SET);
	if(off == (off_t)-1){
		perror("lseek\n");
		return -1;
	}

	len = read(tlb_fd, &value, 4);
	if(len == -1){
		perror("read /dev/tlb0");
		return -1;
	}
	
	return (unsigned int)value;
}

static void tlb_write(int tlb_fd, int reg, unsigned int value)
{
	off_t off;
	ssize_t len;
	unsigned long v = value;
	
	off = lseek(tlb_fd, reg*4, SEEK_SET);
	if(off == (off_t)-1){
		perror("lseek\n");
	}

	len = write(tlb_fd, &v, 4);
	if(len == -1){
		perror("write /dev/tlb0");
	}
}

#define TLB_INVALIDATE 0x147A11DA

void tlb_invalidate(reconos_hwthread *hwt)
{
	tlb_write(hwt->tlb_fd,1,TLB_INVALIDATE);
}

// TODO: Do this in reconos.ko:
//void tlb_setid(reconos_tlb_t * tlb, unsigned long id){
//	tlb_write(0, id);
//}

void tlb_init(reconos_hwthread *hwt)
{
	hwt->tlb_fd = open_tlb();
	hwt->page_faults = 0;
	tlb_invalidate(hwt);
}

uint32 mmu_hits(reconos_hwthread *hwt)
{
	off_t off;
	uint32 hits;
	
	off = lseek(hwt->osif_fd, 5*4, SEEK_SET);
	if(off == (off_t)-1){
		perror("tlb.c:mmu_hits: lseek: error while reading data from OSIF\n");
		fprintf(stderr,"fd=%d\n",hwt->osif_fd);
	}
	// read command and data (this blocks until there is new data
	if (read(hwt->osif_fd, &hits, sizeof(hits)) != sizeof(hits)) {
		perror("error while reading data from OSIF");
	}
	
	return hits;
}

uint32 mmu_misses(reconos_hwthread *hwt)
{
	off_t off;
	uint32 misses;
	
	off = lseek(hwt->osif_fd, 4*4, SEEK_SET);
	if(off == (off_t)-1){
		perror("tlb.c:mmu_misses:lseek: error while reading data from OSIF\n");
	}
	// read command and data (this blocks until there is new data
	if (read(hwt->osif_fd, &misses, sizeof(misses)) != sizeof(misses)) {
		perror("error while reading data from OSIF");
	}
	
	return misses;
}

uint32 mmu_page_faults(reconos_hwthread *hwt){
	return hwt->page_faults;
}

