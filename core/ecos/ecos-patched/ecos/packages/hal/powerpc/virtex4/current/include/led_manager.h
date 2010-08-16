///
/// \file led_manager.h
///
/// Functions to manage the LEDs on a ML403 through GPIO
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

#ifndef LED_MANAGER_H
#define LED_MANAGER_H
#include <pkgconf/hal.h>

#if defined(CYGHWR_HAL_VIRTEX_BOARD_ML403)
  enum LEDS { NO_LEDS = 0x0000, GP_LED0 = 0x0001, GP_LED1 = 0x0002, GP_LED2 = 0x0004, GP_LED3 = 0x0008, CD_LED = 0x0010, WD_LED = 0x0020, SD_LED = 0x0040, ED_LED = 0x0080, ND_LED = 0x0100, ALL_LEDS = 0x01FF };
#elif defined(CYGHWR_HAL_VIRTEX_BOARD_XUP)
  enum LEDS { NO_LEDS = 0x0000, GP_LED0 = 0x0001, GP_LED1 = 0x0002, GP_LED2 = 0x0004, GP_LED3 = 0x0008, ALL_LEDS = 0x000F };
#endif


void init_led_manager( void );
int get_status_led_manager( cyg_uint32 * status );
int turn_on_led( cyg_uint32 led );
int turn_off_led( cyg_uint32 led );

#endif // LED_MANAGER_H
