///
/// \file crc32.h
///
/// \author     Enno Luebbers <luebbers@reconos.de>
/// \date       04.10.2007
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

#ifndef CRC32_H
#define CRC32_H

#include <stdlib.h>
#include <inttypes.h>

/*
 *  implementation of the CRC32 algorithm defined by IEEE 802.3
 */

/* bitwise input, returns new crc32 value */
uint32_t crc32_add_bit(uint32_t crc, int bit);

/* bytewise input, returns new crc32 value */
uint32_t crc32_add_byte(uint32_t crc, uint8_t byte);

/* returns crc32 value of the given sequence */
uint32_t crc32(uint8_t * data, size_t size);

#endif
