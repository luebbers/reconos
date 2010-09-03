#ifndef CYGONCE_VAR_CACHE_H
#define CYGONCE_VAR_CACHE_H
//=============================================================================
//
//      var_cache.h
//
//      Variant HAL cache control API
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002, 2003 Gary Thomas
//
// eCos is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 or (at your option) any later version.
//
// eCos is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with eCos; if not, write to the Free Software Foundation, Inc.,
// 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
//
// As a special exception, if other files instantiate templates or use macros
// or inline functions from this file, or you compile this file and link it
// with other works to produce a work based on this file, this file does not
// by itself cause the resulting work to be covered by the GNU General Public
// License. However the source code for this file must still be made available
// in accordance with section (3) of the GNU General Public License.
//
// This exception does not invalidate any other reasons why a work based on
// this file might be covered by the GNU General Public License.
//
// Alternative licenses for eCos may be arranged by contacting Red Hat, Inc.
// at http://sources.redhat.com/ecos/ecos-license/
// -------------------------------------------
//####ECOSGPLCOPYRIGHTEND####
//=============================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):      Michal Pfeifer
// Original data:  PowerPC
// Contributors: 
// Date:        2000-04-02
// Purpose:     Variant cache control API
// Description: The macros defined here provide the HAL APIs for handling
//              cache control operations on the mb4a variant CPUs.
// Usage:       Is included via the architecture cache header:
//              #include <cyg/hal/hal_cache.h>
//              ...
//
//####DESCRIPTIONEND####
//
//=============================================================================

#include <pkgconf/hal.h>
#include <cyg/infra/cyg_type.h>

#include <cyg/hal/mb_regs.h>
#include <cyg/hal/plf_cache.h>

#include <pkgconf/hal_microblaze_platform.h>
#include <xparameters.h>

//-----------------------------------------------------------------------------
// Cache dimensions

// FIXME size of caches is wrong
// Data cache
#ifndef HAL_DCACHE_SIZE
#define HAL_DCACHE_SIZE                 (XPAR_MICROBLAZE_0_DCACHE_HIGHADDR - XPAR_MICROBLAZE_0_DCACHE_BASEADDR + 1)   // Size of data cache in bytes
#define HAL_DCACHE_LINE_SIZE            16      // Size of a data cache line
#define HAL_DCACHE_WAYS                 1       // Associativity of the cache
#endif
#define CYGARC_DCACHE_BASEADDR		XPAR_MICROBLAZE_0_DCACHE_BASEADDR
#define CYGARC_DCACHE_HIGHADDR		XPAR_MICROBLAZE_0_DCACHE_HIGHADDR

// Instruction cache
#ifndef HAL_ICACHE_SIZE
#define HAL_ICACHE_SIZE			(XPAR_MICROBLAZE_0_ICACHE_HIGHADDR - XPAR_MICROBLAZE_0_ICACHE_BASEADDR + 1)    // Size of cache in bytes
#define HAL_ICACHE_LINE_SIZE		16      // Size of a cache line
#define HAL_ICACHE_WAYS			1       // Associativity of the cache
#endif
#define CYGARC_ICACHE_BASEADDR		XPAR_MICROBLAZE_0_ICACHE_BASEADDR
#define CYGARC_ICACHE_HIGHADDR		XPAR_MICROBLAZE_0_ICACHE_HIGHADDR

#define HAL_DCACHE_SETS		(HAL_DCACHE_SIZE/(HAL_DCACHE_LINE_SIZE*HAL_DCACHE_WAYS))
#define HAL_ICACHE_SETS		(HAL_ICACHE_SIZE/(HAL_ICACHE_LINE_SIZE*HAL_ICACHE_WAYS))

//-----------------------------------------------------------------------------
// Global control of data cache

// Enable the data cache
#define HAL_DCACHE_ENABLE()			\
	CYG_MACRO_START				\
	asm volatile ("msrset	r0, 0x80\n");	\
	CYG_MACRO_END

// Disable the data cache
#define HAL_DCACHE_DISABLE()			\
	CYG_MACRO_START				\
	asm volatile ("msrclr	r0, 0x80\n");	\
	CYG_MACRO_END

// Invalidate the entire cache
#define HAL_DCACHE_INVALIDATE_ALL()				\
	CYG_MACRO_START						\
	cyg_int32 _msr, _cmp, _adr, _hadr;			\
	_adr = CYGARC_DCACHE_BASEADDR - 4;			\
	_hadr = CYGARC_DCACHE_BASEADDR + HAL_DCACHE_SIZE - 4;	\
	asm volatile (						\
		"msrclr	%0, 0x80\n"				\
		"0:\n"						\
		"rsub	%1, %2, %3\n"				\
		"bleid	%1, 1f\n"				\
		"addi	%2, %2, 4\n"				\
		"brid	0b\n"					\
		"wdc	%2, r0\n"				\
		"1:\n"						\
		"mts	rmsr, %0\n"				\
		: "=&r"	(_msr),					\
		  "=&r"	(_cmp)					\
		: "r" 	(_adr),					\
		  "r"	(_hadr)					\
	);							\
	CYG_MACRO_END

// Synchronize the contents of the cache with memory.
#define HAL_DCACHE_SYNC()											\
	CYG_MACRO_START												\
	cyg_int32 i;												\
	cyg_uint32 *__base = (cyg_uint32 *) (CYGARC_DCACHE_BASEADDR);						\
	for (i = 0; i < (HAL_DCACHE_SIZE / HAL_DCACHE_LINE_SIZE); i++, __base += HAL_DCACHE_LINE_SIZE/4) {	\
		asm volatile ("lwi r0, %0, 0\n" : : "r" (__base));						\
	}													\
	CYG_MACRO_END

// Query the state of the data cache
#define HAL_DCACHE_IS_ENABLED(_state_)		\
	CYG_MACRO_START				\
	cyg_int32 _scratch;			\
	asm volatile ("mfs	%0, rmsr\n"	\
			"andi	%0,%0,0x80\n"	\
			: "=&r" (_scratch)	\
	);					\
	(_state_) = _scratch != 0;		\
	CYG_MACRO_END

// Set the data cache refill burst size
//#define HAL_DCACHE_BURST_SIZE(_size_)

// Set the data cache write mode
//#define HAL_DCACHE_WRITE_MODE( _mode_ )

//#define HAL_DCACHE_WRITETHRU_MODE       0
//#define HAL_DCACHE_WRITEBACK_MODE       1

// Load the contents of the given address range into the data cache
// and then lock the cache so that it stays there.
//#define HAL_DCACHE_LOCK(_base_, _size_)

// Undo a previous lock operation
//#define HAL_DCACHE_UNLOCK(_base_, _size_)

// Unlock entire cache
//#define HAL_DCACHE_UNLOCK_ALL()

//-----------------------------------------------------------------------------
// Data cache line control

// Allocate cache lines for the given address range without reading its
// contents from memory.
//#define HAL_DCACHE_ALLOCATE( _base_ , _size_ )

// Write dirty cache lines to memory and invalidate the cache entries
// for the given address range.
#define HAL_DCACHE_FLUSH( _base_ , _size_ )
//    CYG_MACRO_START                                             
//    cyg_uint32 __base = (cyg_uint32) (_base_);                  
//    cyg_int32 __size = (cyg_int32) (_size_);                   
//    while (__size > 0) {                                       
//        asm volatile ("dcbf 0,%0;sync;" : : "r" (__base));     
//        __base += HAL_DCACHE_LINE_SIZE;                         
//        __size -= HAL_DCACHE_LINE_SIZE;                        
//    }                                                          
//    CYG_MACRO_END
   
// Invalidate cache lines in the given range without writing to memory.
#define HAL_DCACHE_INVALIDATE( _base_ , _size_ )				\
	CYG_MACRO_START								\
	cyg_int32 _msr, _cmp, _adr, _hadr, _siz;				\
										\
	/* Compute base and size in cachable mem */				\
	if(_base_<CYGARC_DCACHE_BASEADDR){					\
		_adr = CYGARC_DCACHE_BASEADDR - 4;				\
		_siz = _size_ - CYGARC_DCACHE_BASEADDR + _base_;		\
	}									\
	else {									\
		_adr = _base_- 4;						\
		_siz = _size_;							\
	}									\
	if((_adr + _siz) > CYGARC_DCACHE_HIGHADDR)				\
		_siz = CYGARC_DCACHE_HIGHADDR - _adr;				\
	if(_siz > HAL_DCACHE_SIZE)						\
		_siz = HAL_DCACHE_SIZE;						\
										\
	/* Compute base and high addr in cache and round them to 4B addr */	\
	_hadr = (_adr + _siz) & 0xFFFFFFFC;					\
	_adr &= 0xFFFFFFFC;							\
										\
	asm volatile (								\
		"msrclr	%0, 0x80\n"						\
		"0:\n"								\
		"rsub	%1, %2, %3\n"						\
		"bleid	%1, 1f\n"						\
		"addi	%2, %2, 4\n"						\
		"brid	0b\n"							\
		"wdc	%2, r0\n"						\
		"1:\n"								\
		"mts	rmsr, %0\n"						\
		: "=&r"	(_msr),							\
		  "=&r"	(_cmp)							\
		: "r" 	(_adr),							\
		  "r"	(_hadr)							\
	);                                                                      \
        CYG_MACRO_END

// Write dirty cache lines to memory for the given address range.
#define HAL_DCACHE_STORE( _base_ , _size_ )
//    CYG_MACRO_START                                             
//    cyg_uint32 __base = (cyg_uint32) (_base_);                  
//    cyg_int32 __size = (cyg_int32) (_size_);                    
//    while (__size > 0) {                                       
//        asm volatile ("dcbst 0,%0;sync;" : : "r" (__base));     
//        __base += HAL_DCACHE_LINE_SIZE;                         
//        __size -= HAL_DCACHE_LINE_SIZE;                         
//    }                                                           
//    CYG_MACRO_END

// Preread the given range into the cache with the intention of reading
// from it later.
// FIXME possible problem with _hadr value 
#define HAL_DCACHE_READ_HINT( _base_ , _size_ )					\
	CYG_MACRO_START								\
	cyg_uint32 _adr, _siz, _hadr;						\
										\
	/* Compute base and size in cachable mem */				\
	if( _base_ < CYGARC_DCACHE_BASEADDR ) {					\
		_adr = CYGARC_DCACHE_BASEADDR;					\
		_siz = _size_ - CYGARC_DCACHE_BASEADDR + _base_;		\
	} else {								\
		_adr = _base_;							\
		_siz = _size_;							\
	}									\
	if((_adr + _siz - 4) > CYGARC_DCACHE_HIGHADDR)				\
		_siz = CYGARC_DCACHE_HIGHADDR - _adr + 4;			\
	if(_siz > HAL_DCACHE_SIZE)						\
		_siz = HAL_DCACHE_SIZE;						\
										\
	/* Compute base and high addr in cache and round them to 4B addr */	\
	_hadr = (_adr + _siz - 4) & 0xFFFFFFFC;					\
	_adr &= 0xFFFFFFFC;							\
										\
	for (; _adr < _hadr; _adr += (HAL_DCACHE_LINE_SIZE/4)){ 		\
		asm volatile ("lwi r0, %0, 0\n" : : "r" (_adr));		\
	}									\
	CYG_MACRO_END

// Preread the given range into the cache with the intention of writing
// to it later.
#define HAL_DCACHE_WRITE_HINT( _base_ , _size_ )                
//    CYG_MACRO_START                                             
//    cyg_uint32 __base = (cyg_uint32) (_base_);                  
//    cyg_int32 __size = (cyg_int32) (_size_);                    
//    while (__size > 0) {                                       
//        asm volatile ("dcbtst 0,%0;" : : "r" (__base));         
//        __base += HAL_DCACHE_LINE_SIZE;                         
//        __size -= HAL_DCACHE_LINE_SIZE;                         
//    }                                                           
//    CYG_MACRO_END

// Allocate and zero the cache lines associated with the given range.
// FIXME this is commented in all arch
//#define HAL_DCACHE_ZERO( _base_ , _size_ )                      
//    HAL_DCACHE_INVALIDATE( _base_ , _size_ )

//-----------------------------------------------------------------------------
// Global control of Instruction cache

// Enable the instruction cache
#define HAL_ICACHE_ENABLE()			\
	CYG_MACRO_START				\
	asm volatile ("msrset	r0, 0x20\n");	\
	CYG_MACRO_END

// Disable the instruction cache
#define HAL_ICACHE_DISABLE()			\
	CYG_MACRO_START				\
	asm volatile ("msrclr	r0, 0x20\n");	\
	CYG_MACRO_END

// Invalidate the entire cache
#define HAL_ICACHE_INVALIDATE_ALL()				\
	CYG_MACRO_START						\
	cyg_int32 _msr, _cmp, _adr, _hadr;			\
	_adr = CYGARC_ICACHE_BASEADDR - 4;			\
	_hadr = CYGARC_ICACHE_BASEADDR + HAL_ICACHE_SIZE - 4;	\
	asm volatile (						\
		"msrclr	%0, 0x20\n"				\
		"0:\n"						\
		"rsub	%1, %2, %3\n"				\
		"bleid	%1, 1f\n"				\
		"addi	%2, %2, 4\n"				\
		"brid	0b\n"					\
		"wic	%2, r0\n"				\
		"1:\n"						\
		"mts	rmsr, %0\n"				\
		: "=&r"	(_msr),					\
		  "=&r"	(_cmp)					\
		: "r" 	(_adr),					\
		  "r"	(_hadr)					\
	);							\
	CYG_MACRO_END

// Synchronize the contents of the cache with memory.
#define HAL_ICACHE_SYNC()											\
	CYG_MACRO_START												\
	cyg_int32 i;												\
	cyg_uint32 *__base = (cyg_uint32 *) (CYGARC_ICACHE_BASEADDR);						\
	for (i = 0; i < (HAL_ICACHE_SIZE / HAL_ICACHE_LINE_SIZE); i++, __base += HAL_ICACHE_LINE_SIZE/4){	\
		asm volatile ("lwi r0, %0, 0\n" : : "r" (__base));						\
	}													\
	CYG_MACRO_END

// Query the state of the instruction cache
#define HAL_ICACHE_IS_ENABLED(_state_)			\
	CYG_MACRO_START					\
	cyg_int32 _scratch;				\
	asm volatile ("mfs	%0, rmsr\n"		\
			"andi	%0,%0,0x20\n"		\
			: "=&r" (_scratch)		\
	);						\
	(_state_) = _scratch != 0;			\
	CYG_MACRO_END


// Set the instruction cache refill burst size
//#define HAL_ICACHE_BURST_SIZE(_size_)

// Load the contents of the given address range into the instruction cache
// and then lock the cache so that it stays there.
//#define HAL_ICACHE_LOCK(_base_, _size_)

// Undo a previous lock operation
//#define HAL_ICACHE_UNLOCK(_base_, _size_)

// Unlock entire cache
//#define HAL_ICACHE_UNLOCK_ALL()

//-----------------------------------------------------------------------------
// Instruction cache line control

// Invalidate cache lines in the given range without writing to memory.
//#define HAL_ICACHE_INVALIDATE( _base_ , _size_ )

//-----------------------------------------------------------------------------
#endif // ifndef CYGONCE_VAR_CACHE_H
// End of var_cache.h
