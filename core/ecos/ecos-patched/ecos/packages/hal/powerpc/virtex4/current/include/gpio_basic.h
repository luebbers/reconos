///
/// \file gpio_basic.h
///
/// Functions to manage general purpose I/O
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

#ifndef GPIO_BASIC_H
#define GPIO_BASIC_H

void enable_interrupt_gpio( cyg_uint32 mask );
void disable_interrupt_gpio( cyg_uint32 mask );
void clear_interrupt_gpio( cyg_uint32 mask );
void init_gpio_manager( void );
int get_status_gpio( cyg_uint32 * status );
int turn_on_bit( cyg_uint32 bit );
int turn_off_bit( cyg_uint32 bit );

#endif // GPIO_BASIC_H
