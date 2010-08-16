///
/// \file params.h
///
/// Macros to automatically determine timebase parameters from compiled Linux image.
///
/// \author     Enno Luebbers <enno.luebbers@upb.de>
/// \date       14.03.2008
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
// 09.02.2008   Enno Luebbers   File created
//
 
#ifndef __TIMEBASE_PARAMS_H__
#define __TIMEBASE_PARAMS_H__

#include "xparameters.h"

// MACROS ==============================================

//
// DCR base addresses
//
#ifdef XPAR_DCR_TIMEBASE_0_DCR_BASEADDR
#define TIMEBASE_BASEADDR XPAR_DCR_TIMEBASE_0_DCR_BASEADDR
#endif // XPAR_DCR_TIMEBASE_0_DCR_BASEADDR

//
// OPB2DCR bridge detection
//
#ifdef TIMEBASE_BASEADDR
// DCR address bus is 10 bit wide, so if the address is is greater than
// 1023, it can't be a native DCR address
#if TIMEBASE_BASEADDR > 1023
#define USE_OPB2DCR 1
#else
#define USE_OPB2DCR 0
#endif
#endif

#endif  // __TIMEBASE_PARAMS_H__

