///
/// \file thermal.h
///
/// Low-level routines for temperature sensor grid. The sensor grid (thermal_monitor) 
/// can be calibrated using the pre-calibrated thermal diode (xps_sysmon) and 
/// local heat-generating cores (vector_heater). After calibration the sensors 
/// can be accessed and return a temperature in degree Celsius.
///
/// \author     Markus Happe   <markus.happe@upb.de>
/// \date       23.08.2011
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2011 The ReconOS Project and contributors (see AUTHORS).
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
#ifndef __THERMAL_H__
#define __THERMAL_H__
#include <reconos/reconos.h>

//! calibrates sensors. This function takes 3-4 minutes.
void reconos_calibrate_temperature_sensors(void);

//! triggers new temperature measurement
void reconos_make_temperature_measurement(void);

//! returns temperature of sensor no. sensor_id
// negative return values are used for error codes
float reconos_get_temperature(int sensor_id);

//! returns temperature of sensor at location (x,y)
// negative return values are used for error codes
float reconos_get_temperature_at_loc(int x, int y);

//! returns temperature of internal thermal diode 
float reconos_get_diode_temperature(void);

//! returns number of sensors
int reconos_get_temperature_sensor_grid_num(void);

//! returns width of sensor grid
int reconos_get_temperature_sensor_grid_width(void);

//! returns height of sensor grid
int reconos_get_temperature_sensor_grid_height(void);

//! activate local heater
void reconos_activate_local_heater(int heater_id);

//! deactivate local heater
void reconos_deactivate_local_heater(int heater_id);

//! returns number of local heat-generating cores
int reconos_get_local_heater_num(void);

#endif	// __THERMAL_H__
