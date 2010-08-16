///
/// \file statetrace.c
///
/// Functions to analyze state traces from ReconOS hardware threads
///
/// \author     Enno Luebbers <enno.luebbers@upb.de>
/// \date       02.04.2007
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
 
 // INCLUDES ////////////////////////////////////////////////////////////////
 
 #include <reconos/statetrace.h>
   

// FUNCTIONS ////////////////////////////////////////////////////////////////   
 /** 
 * Clears trace memory 
 */
void reconos_clearStateTrace(reconos_hwThread_t *hwt) {

	unsigned int *ptr = (unsigned int *)hwt->stateTraceBaseAddr;
	unsigned int i = 0;
	unsigned int size = hwt->stateTraceLen;
	
	for(i = 0; i < size; i++) {
		ptr[i] = 0x00000000;
	}

}
