///
/// \file ecap_net.h
///
/// Low-level routines for partial reconfiguration via network.
/// This is a kind of hack. :) It sends the filename of the required
/// partial bitstream via TCP to a host PC, which then reconfigures it
/// via JTAG. ECAP as in external configuration access port...
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       16.06.2009
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
#ifndef __ECAP_NET_H__
#define __ECAP_NET_H__
#include <reconos/reconos.h>

void ecap_init(void);
void ecap_load(reconos_bitstream_t *bitstream);

#endif	// __ECAP_NET_H__
