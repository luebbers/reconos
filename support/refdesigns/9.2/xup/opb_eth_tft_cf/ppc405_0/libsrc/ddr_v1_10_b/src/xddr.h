/* $Id: xddr.h,v 1.2 2007/05/31 00:29:40 wre Exp $ */
/******************************************************************************
*
*       XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
*       AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND
*       SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,
*       OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
*       APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION
*       THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
*       AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
*       FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
*       WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
*       IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
*       REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
*       INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*       FOR A PARTICULAR PURPOSE.
*
*       (c) Copyright 2003 - 2004 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xddr.h
*
* This header file contains interface for the DDR device driver.  This device
* driver is not necessary for the DDR device unless ECC is being used.
*
* ECC (Error Correction Code) is a mode that detects and corrects some memory
* errors.  This device driver provides the following abilities.
*  - Enable and disable ECC mode
*  - Enable and disable interrupts for specific ECC errors
*  - Error injection for testing of ECC mode
*  - Statistics for specific ECC errors detected
*
* The Xilinx DDR controller is a soft IP core designed for Xilinx FPGAs on
* the OPB or PLB bus. The OPB DDR device does not currently support ECC such
* that there would be no reason to use this driver for the device.
*
*<b> Hardware Parameters Needed</b>
*
* In order for the driver to be used with the hardware device, ECC registers
* must be enabled in the hardware.
*
* The interrupt capability for the device must be enabled in the hardware
* if interrupts are to be used with the driver.  The interrupt functions of
* the device driver will assert when called if interrupt support is not
* present in the hardware.
*
* The ability to force errors is a test mode and it must be enabled
* in the hardware if the control register is to be used to force ECC errors.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a jhl  12/24/03 First release
* 1.10a wgr  03/22/07 Converted to new coding style.
* </pre>
*
******************************************************************************/

#ifndef XDDR_H			/* prevent circular inclusions */
#define XDDR_H			/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xddr_l.h"
#include "xbasic_types.h"
#include "xio.h"
#include "xstatus.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/

/*
 * This typedef contains configuration information for the device.
 */
typedef struct {
	u16 DeviceId;
	u32 BaseAddress;
	int InterruptPresent;
} XDdr_Config;

/**
 * The XDdr driver stats data. A pointer to a variable of this type is
 * passed to the driver API functions.
 */
typedef struct {
	u16 SingleErrorCount;
	u16 DoubleErrorCount;
	u16 ParityErrorCount;
} XDdr_Stats;

/**
 * The XDdr driver instance data. The user is required to allocate a
 * variable of this type for every DDR device in the system. A pointer
 * to a variable of this type is then passed to the driver API functions.
 */
typedef struct {
	u32 BaseAddress;	/**< Base address of registers */
	int IsReady;		/**< Device is initialized and ready */
	XDdr_Config *ConfigPtr;
} XDdr;

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

/*
 * API Basic functions implemented in xddr.c
 */
int XDdr_Initialize(XDdr * InstancePtr, u16 DeviceId);
void XDdr_EnableEcc(XDdr * InstancePtr);
void XDdr_DisableEcc(XDdr * InstancePtr);

void XDdr_SetControl(XDdr * InstancePtr, u32 Control);
u32 XDdr_GetControl(XDdr * InstancePtr);
u32 XDdr_GetStatus(XDdr * InstancePtr);
void XDdr_ClearStatus(XDdr * InstancePtr);

XDdr_Config *XDdr_LookupConfig(u16 DeviceId);

/*
 * API Functions implemented in xddr_stats.c
 */
void XDdr_GetStats(XDdr * InstancePtr, XDdr_Stats * StatsPtr);
void XDdr_ClearStats(XDdr * InstancePtr);

/*
 * API Functions implemented in xddr_selftest.c
 */
int XDdr_SelfTest(XDdr * InstancePtr);

/*
 * API Functions implemented in xddr_intr.c
 */
void XDdr_InterruptGlobalEnable(XDdr * InstancePtr);
void XDdr_InterruptGlobalDisable(XDdr * InstancePtr);

void XDdr_InterruptEnable(XDdr * InstancePtr, u32 Mask);
void XDdr_InterruptDisable(XDdr * InstancePtr, u32 Mask);
void XDdr_InterruptClear(XDdr * InstancePtr, u32 Mask);
u32 XDdr_InterruptGetEnabled(XDdr * InstancePtr);
u32 XDdr_InterruptGetStatus(XDdr * InstancePtr);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
