///
/// \file resources.h
///
/// Defines data types, constants and functions for ReconOS resources,
/// also calles OS objects, e.g. semaphores, mutexes etc.
/// 
/// \author     Enno Luebbers <enno.luebbers@upb.de>
/// \created    2007
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
#ifndef __RESOURCES_H__
#define __RESOURCES_H__

#include <cyg/kernel/kapi.h>	// for eCos datatypes

#ifdef __cplusplus
extern "C" {
#endif

// TYPE DEFINITIONS ========================================================

/// stores pointers to ReconOS resources
///
/// For semaphores, mutexes and condition variables, store a pointer
/// to the corresponding object. For mailboxes, store a pointer to
/// the mailbox handle.
typedef struct {
        void * ptr;                     ///< pointer to resource (can be an object or a handle)
        cyg_uint32 type;        ///< integer identifying the resource type
} reconos_res_t;

// CONSTANTS ===============================================================

// Resource Identifiers ----------------------------------------------------
// Can (later) also be used as bit masks (e.g. for capabilities)

// eCos resource identifiers
#define CYG_SEM_T              0x00000001
#define CYG_MUTEX_T            0x00000002
#define CYG_COND_T             0x00000004
#define CYG_MBOX_HANDLE_T      0x00000008

#ifdef UPBFUN_RECONOS_POSIX
// POSIX resource identifiers
#define PTHREAD_SEM_T             0x00001000
#define PTHREAD_MUTEX_T           0x00002000
#define PTHREAD_COND_T            0x00004000
#define PTHREAD_MQD_T              0x00008000
#endif // UPBFUN_RECONOS_POSIX

// ReconOS-only resource identifiers
// used for hardware-handled resources (e.g. hw mailboxes)
#define RECONOS_HWMBOX_READ_T   0x01000000
#define RECONOS_HWMBOX_WRITE_T  0x02000000
#define RECONOS_DUMMY_T         0xFF000000



#ifdef __cplusplus
} // extern "C"
#endif

#endif //__RESOURCES_H__
