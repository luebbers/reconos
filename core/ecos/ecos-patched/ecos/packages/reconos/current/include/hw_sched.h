///
/// \file hw_sched.h
///
/// Definitions for hardware thread scheduler
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       11.03.2009
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
#ifndef __HW_SCHED_H__
#define __HW_SCHED_H__

#include <reconos/reconos.h>

void reconos_hwsched_init( void );
void reconos_hwsched_destroy( void );
void reconos_register_hwthread( rthread_attr_t *t );
void reconos_unregister_hwthread( rthread_attr_t *t );
void dump_all_hwthreads( void );
void reconos_hw_scheduler(cyg_addrword_t data);

#endif // __HW_SCHED_H__
