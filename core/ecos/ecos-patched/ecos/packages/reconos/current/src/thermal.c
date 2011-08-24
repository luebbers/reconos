///
/// \file thermal.c
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
// Major Changes:
//
// 23.08.2011   Markus Happe   File created.

#include <reconos/reconos.h>
#include <reconos/thermal.h>

#define THERMAL_MONITOR_BASEADDR XPAR_THERMAL_MONITOR_1_BASEADDR
#define SYSMON_BASEADDR XPAR_XPS_SYSMON_ADC_0_BASEADDR
#define TIMEBASE_BASEADDR XPAR_SIMPLE_TIMEBASE_0_BASEADDR
#define HEAT_SOURCE_BASEADDR XPAR_VECTOR_HEATER_A_0_BASEADDR

#define NUM_SENSORS 144
#define H 15
#define W 10
#define SIZE_X W
#define SIZE_Y H
#define HEATERS 12

#define SENSOR_VALID(x,y) (sensor_pos[y][x] >= 0)
#define SENSOR_READ(x,y) (sensor[sensor_pos[y][x]])


int sensor_pos[H][W] = {
	{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9},
	{ 10, 11, 12, 13, 14, 15, 16, 17, 18, 19},
	{ 20, 21, 22, 23, 24, 25, 26, 27, 28, 29},
	{ 30, 31, 32, 33, 34, 35, 36, 37, 38, 39},
	{ 40, 41, 42, 43, 44, 45, 46, 47, 48, 49},
	{ 50, 51, 52, 53, -1, 54, 55, 56, 57, 58},
	{ 59, 60, 61, 62, -1, 63, 64, 65, 66, 67},
	{ 68, 69, 70, 71, -1, 72, 73, 74, 75, 76},
	{ 77, 78, 79, 80, -1, 81, 82, 83, 84, 85},
	{ 86, 87, 88, 89, -1, 90, 91, 92, 93, 94},
	{ 95, 96, 97, 98, -1, 99, 100, 101, 102, 103},
	{ 104, 105, 106, 107, 108, 109, 110, 111, 112, 113},
	{ 114, 115, 116, 117, 118, 119, 120, 121, 122, 123},
	{ 124, 125, 126, 127, 128, 129, 130, 131, 132, 133},
	{ 134, 135, 136, 137, 138, 139, 140, 141, 142, 143}
};

int heat_code_top[57] = {0,   1,   2,   3,   4,   5,   6 ,  7,   8,   9,  10,  
		11,  12,  13,  14,  15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  
		26,  27,  28,  29,  30,  31,  32,  33,  35,  36,  37,  38,  39,  40,  41,  
		42,  43,  45,  46,  47,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58};
	
int heat_code_bottom[57] = {	86,  87,  88,  89,  90,  91,  92,  93,  94,  95,  96,  
		97,  98,  99, 100, 101, 102, 103, 104, 105, 106, 107, 109, 110, 111, 112, 113, 
		114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 
		131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143};
		
int heat_code_right[67] = { 6,  7,   8,   9,   16,  17,  18,  19,  26,  27,  28,  29,  
		35,  36,  37,  38,  39,  45,  46,  47,  48,  49,  55,  56,  57,  58,  63,  64,  65,  
		66,  67,  72,  73,  74,  75,  76,  82,  83,  84,  85,  90,  91,  92,  93,  94,  99, 
		100, 101, 102, 103, 109, 110, 111, 112, 113, 120, 121, 122, 123, 130, 131, 132, 133, 
		140, 141, 142, 143};

int heat_code_left[54] = {	0,   1,   2,  10,  11,  12,  20,  21,  22,  30,  31,  32,  33,  
		40,  41,  42,  43,  50,  51,  52,  53,  59,  60,  61,  62,  68,  69,  70,  71,  77,  
		78,  79,  80,  86,  87,  88,  89,  95,  96,  97,  98, 104, 105, 106, 107, 114, 115, 
		116, 124, 125, 126, 134, 135, 136 };
		

typedef float sensor_array_float[NUM_SENSORS];
typedef int   sensor_array_int[NUM_SENSORS];

sensor_array_float gradients;
sensor_array_float offsets;

//#define UINT_MAX 4294967295

volatile unsigned int * sensor = (unsigned int*)THERMAL_MONITOR_BASEADDR;
volatile unsigned int * sysmon = (unsigned int*)SYSMON_BASEADDR;
volatile unsigned int * timebase = (unsigned int*)TIMEBASE_BASEADDR;
volatile unsigned int * heat_source = (unsigned int*)HEAT_SOURCE_BASEADDR;

const float TEMPERATURE_FACTOR = 0.0076900482177734378;

//! reads temperature of thermal diode
unsigned int sysmon_temp_reg(void)
{
	return sysmon[0x80];
}

//! triggers measurement 
void sensor_measure(void)
{
	*sensor = 0;
}

//! activates all local heaters
void start_heating(void)
{
	unsigned int * heater = (unsigned int*)heat_source;
	unsigned int i;
	for (i=0; i<HEATERS; i++)
	{
	    *heater = 1;
	     heater += 0x40;
	}
}

//! deactivates all local heaters
void stop_heating(void)
{
   unsigned int * heater = (unsigned int*)heat_source;
	unsigned int i;
	for (i=0; i<HEATERS; i++)
	{
	    *heater = 0;
	     heater += 0x40;
	}
}


//! calculate time difference between two time measurements
unsigned int calc_timediff( unsigned int start, unsigned int stop )
{
    if ( start <= stop ) {
        return ( stop - start );
    } else {
        return ( 4294967295UL - start + stop ); 
    }
}

//! waits until the temperature does not change more than 'temp' degree Celsius in 'dt' seconds
void wait_for_stable_temperature(float temp, int dt){
	unsigned int time_in_sec = 0, t_start = 0, t_stop;
	float diode_test_1 = 0, diode_test_2 = 0, diode_difference;
	int milli_temp = (int)(1000*temp);
	milli_temp %= 1000;
	diode_test_2 = sysmon_temp_reg() * TEMPERATURE_FACTOR;
	diode_difference = diode_test_2 - diode_test_1;
	if (diode_difference<0) diode_difference = -diode_difference;
#ifdef UPBDBG_RECONOS_DEBUG
	diag_printf("\nwait until temporal temperature difference is below %d.%03d degree Celsius inside %d seconds interval \n", (int) temp, milli_temp, dt);
#endif
	// temperature is considered stable when difference in x seconds is less than defined temperature difference
	while (diode_difference > temp ){
		diode_test_1 = diode_test_2;
		// 1. wait for 20 seconds
		time_in_sec = 0;
		// busy waiting
		t_start = *timebase;
		while (time_in_sec < dt){
			t_stop = *timebase;
			time_in_sec = (calc_timediff(t_start, t_stop) / 100000000);
		}
#ifdef UPBDBG_RECONOS_DEBUG
		diag_printf(".");
#endif
		diode_test_2 = sysmon_temp_reg() * TEMPERATURE_FACTOR;
		diode_difference = diode_test_2 - diode_test_1;
		if (diode_difference<0) diode_difference = -diode_difference;
	}
#ifdef UPBDBG_RECONOS_DEBUG
	diag_printf("done\n");
#endif
}

//! calibrates sensors. This function takes 3-4 minutes.
void reconos_calibrate_temperature_sensors(void){
    int i, f1, f2;
    sensor_array_int m1,m2;
    float diode1, diode2;

    // init
    for (i=0;i<NUM_SENSORS;i++){
         gradients[i] = 0;
         offsets[i]   = 0;
         m1[i]        = 0;
         m2[i]        = 0;
    }

    // measurement m1
    stop_heating();
    wait_for_stable_temperature(0.3, 20);
    diode1 = sysmon_temp_reg() * TEMPERATURE_FACTOR;
    diode1 -= 273.15;
#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("\nmake 1st calibration measurement...");
#endif
    sensor_measure();
#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("done\r\n");
#endif
    for(i = 0; i < NUM_SENSORS; i++){
        m1[i] = sensor[i];
    }

    // measurement m2
    start_heating();
    wait_for_stable_temperature(0.3, 20);
    diode2 = sysmon_temp_reg() * TEMPERATURE_FACTOR;
    diode2 -= 273.15;
#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("\nmake 2nd calibration measurement...");
#endif
    sensor_measure();
#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("done\n");
#endif
    for(i = 0; i < NUM_SENSORS; i++){
        m2[i] = sensor[i];
    }
    stop_heating();

#ifdef UPBDBG_RECONOS_DEBUG
    diag_printf("\nsensor calibration (T1=%d.%03d, T2=%d.%03d)\n", (int)diode1, ((int)(diode1*1000))%1000, (int)diode2, ((int)(diode2*1000))%1000);
#endif

    // self-calibration
    for(i = 0; i < NUM_SENSORS; i++){
        f1 = (int) m1[i];
        f2 = (int) m2[i];
        gradients[i]  = (diode2-diode1);
        gradients[i] /= (f2-f1);
        offsets[i]  = diode1;
        offsets[i] -= (gradients[i]*m1[i]);
    }
}

//! triggers new temperature measurement
void reconos_make_temperature_measurement(void){
    sensor_measure();
}

//! returns temperature of sensor no. sensor_id
// negative return values are used for error codes
float reconos_get_temperature(int sensor_id){
    float temp = 0; 
    int i;
    if (NUM_SENSORS <= sensor_id) return -1;
    i = sensor_id;
    temp = sensor[i] * gradients[i]; // * gradient
    temp += offsets[i]; // + offset
    return temp;
}

//! returns temperature of sensor at location (x,y)
// negative return values are used for error codes
float reconos_get_temperature_at_loc(int x, int y){
    int i;
    float temp = 0;
    if (SIZE_X <= x) return -1;
    if (SIZE_Y <= y) return -2;
    if (sensor_pos[y][x] == -1) return -3;
    i = sensor_pos[y][x];
    temp = sensor[i] * gradients[i]; // * gradient
    temp += offsets[i]; // + offset
    return temp;
}

//! returns temperature of internal thermal diode 
float reconos_get_diode_temperature(void){
   unsigned int sysmon = sysmon_temp_reg();
   float diode = sysmon * TEMPERATURE_FACTOR;
   diode -= 273.15f;
   return diode;
}

//! activate local heater
void reconos_activate_local_heater(int heater_id){
    unsigned int * heater = (unsigned int*)heat_source;
    int i;
    if (HEATERS <= heater_id) return;
    for (i=0; i<heater_id; i++){
         heater += 0x40;
    }
    *heater = 1;
}

//! deactivate local heater
void reconos_deactivate_local_heater(int heater_id){
    unsigned int * heater = (unsigned int*)heat_source;
    int i;
    if (HEATERS <= heater_id) return;
    for (i=0; i<heater_id; i++){
         heater += 0x40;
    }
    *heater = 0;
}

//! returns number of local heat-generating cores
int reconos_get_local_heater_num(void){
   return HEATERS;
}

//! returns number of sensors
int reconos_get_temperature_sensor_grid_num(void){
   return NUM_SENSORS;
}

//! returns width of sensor grid
int reconos_get_temperature_sensor_grid_width(void){
   return SIZE_X;
}

//! returns height of sensor grid
int reconos_get_temperature_sensor_grid_height(void){
   return SIZE_Y;
}

