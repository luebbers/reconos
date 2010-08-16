///
/// \file hw_thread.hxx
///
/// ReconOS hardware thread
///
/// Contains type definitions, constants and function prototypes.
///
/// \author     Enno Luebbers <enno.luebbers@uni-paderborn.de>
/// \date       08.08.2006
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
#ifndef __RECONOS_HW_THREAD_H__
#define __RECONOS_HW_THREAD_H__

#include <cyg/kernel/thread.hxx>
#include <reconos/reconos.h>


// ReconOS HW Thread C++ Class

class ReconOS_HardwareThread 
		: public Cyg_Thread 
{
	
public:
	ReconOS_HardwareThread(
							    CYG_ADDRWORD        sched_info,
							    cyg_addrword_t      init_data,
							    char                *name,
							    CYG_ADDRESS         stack_base,
							    cyg_ucount32        stack_size,
							
								uint32 				dcrBaseAddr,	
								cyg_vector_t 		intrVector, 	
								reconos_res_t 			*resources,	 
								uint32 				numResources,
								uint32                          fifoRead_resNum,
								uint32                          fifoWrite_resNum
							);

        ~ReconOS_HardwareThread();

protected:
	RECONOS_HWTHREAD_MEMBERS
	
};


//#include <cyg/kernel/kapi.h>


#endif // __RECONOS_HW_THREAD_H__
