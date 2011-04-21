///
/// \file config.h
/// Configuration constants
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#ifndef __CONFIG_H__
#define __CONFIG_H__

//
// Common options for all implementations
//
/// number of words per block
#define N (8192/sizeof(unsigned int))
/// total number of words to sort
#define SIZE (64*N) //(128*N) does not work on my system (Markus)

//
// eCos specific options, common to all eCos implementations
//
/// comment out to disable data cache
#define USE_CACHE 1
#define STACK_SIZE 8192

//
// eCos, multi-threaded, software-only (sort_ecos_mt_sw)
//
/// number of threads
#define MT_SW_NUM_THREADS 4

//
// eCos, multi-threaded, hardware/software (sort_ecos_mt_hw)
//
/// number of software threads (there's always just one hardware thread)
#define MT_HW_NUM_SW_THREADS 4

#endif
