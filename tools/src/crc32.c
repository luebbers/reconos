///
/// \file crc32.c
///
/// Implementation of the CRC32 algorithm defined by IEEE 802.3
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


#include <inttypes.h>
#include <stdlib.h>

#define CRC32POLYREV 0xEDB88320 /* reverse crc32 polynomial */


uint32_t crc32_add_bit(uint32_t crc, int bit)
{
	int lbit = crc & 1;
	crc = crc >> 1;
	if (lbit != bit)
		crc ^= CRC32POLYREV;
	
	return crc;
}

uint32_t crc32_add_byte(uint32_t crc, uint8_t byte){
	int i;
	crc = ~crc;
	for(i = 0; i < 8; i++){
		crc = crc32_add_bit(crc, (byte >> i) & 1);
	}
	return ~crc;
}

uint32_t crc32(uint8_t * data, size_t size){
	uint32_t crc = 0;
	size_t i;
	for(i = 0; i < size; i++){
		crc = crc32_add_byte(crc,data[i]);
	}
	return crc;
}
