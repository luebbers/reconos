///
/// \file timebase.h
///
/// DCR device driver for ReconOS dcr_timebase on Linux 2.6.
///
/// \author     Enno Luebbers <enno.luebbers@upb.de>
/// \date       18.03.2008
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
// Major Changes:
// 
// 18.03.2008   Enno Luebbers   File created
//

#ifndef __TIMEBASE_MODULE_H__
#define __TIMEBASE_MODULE_H__

//#define TIMEBASE_DEBUG 1


// CONSTANTS ==============================================

#define TIMEBASE_MAJOR  0       // dynamic major by default
// we start at minor 0 

//#define TIMEBASE_DCR_WRITESIZE 3     // number of DCR registers (writable)
#define TIMEBASE_DCR_READSIZE  1     // numberof DCR registers (readable)


// MACROS =================================================

#undef PDEBUG             /* undef it, just in case */
#ifdef TIMEBASE_DEBUG
#  ifdef __KERNEL__
     // This one if debugging is on, and kernel space
#    define PDEBUG(fmt, args...) printk( KERN_WARNING "timebase: " fmt, ## args)
#  else
     // This one for user space 
#    define PDEBUG(fmt, args...) fprintf(stderr, fmt, ## args)
#  endif
#else
#  define PDEBUG(fmt, args...) 0      // not debugging: nothing
#endif

#endif  // __TIMEBASE_MODULE_H__

