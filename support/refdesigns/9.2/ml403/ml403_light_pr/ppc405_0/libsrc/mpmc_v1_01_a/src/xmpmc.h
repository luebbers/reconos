/* $Id: xmpmc.h,v 1.3 2007/06/04 15:17:03 mta Exp $ */
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
*       (c) Copyright 2007 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xmpmc.h
*
* The Xilinx XMpmc driver supports ECC capability of the MPMC device. This
* device driver is not necessary for the MPMC device unless ECC is being used.
*
* This header file contains interface for the MPMC device driver.
*
* ECC (Error Correction Code) is a mode that detects and corrects single memory
* errors and detects the double memory errors.
*
* This device driver provides the following abilities:
*  - Enable and disable ECC mode in Read logic/Write logic/both .
*  - Enable and disable interrupts for specific ECC errors.
*  - Error injection for testing of ECC mode.
*  - Statistics for specific ECC errors detected.
*  - Information about address where the last error has been detected.
*
* The Xilinx MPMC controller is a soft IP core designed for Xilinx FPGAs.
*
*<b> Initialization and Configuration </b>
*
* The device driver enables higher layer software (e.g., an application) to
* work with ECC functionality in MPMC.The driver allows to configure the
* ECC functionality as per requirement of the user.
*
* XMpmc_CfgInitialize() API is used to initialize the XMpmc device instance.
* The user needs to first call the XMpmc_LookupConfig() API which returns the
* Configuration structure pointer which is passed as a parameter to the
* XMpmc_CfgInitialize() API.
*
*<b> Interrupts</b>
*
* The MPMC device has one physical interrupt and this has to be connected to
* the interrupt controller in the system. The driver does not provides any
* interrupt handler for handling this interrupt. The users of this driver
* have connect their own handler with the interrupt system.
*
* <b> Asserts </b>
*
* Asserts are used within all Xilinx drivers to enforce constraints on argument
* values. Asserts can be turned off on a system-wide basis by defining, at
* compile time, the NDEBUG identifier. By default, asserts are turned on and it
* is recommended that users leave asserts on during development.
*
** <b> Threads </b>
*
* This driver is not thread safe. Any needs for threads or thread mutual
* exclusion must be satisfied by the layer above this driver.
*
*<b> Hardware Parameters Needed</b>
*
* In order for the driver to be used with the hardware device, ECC registers
* must be enabled in the hardware.
*
* The interrupt capability for the device must be enabled in the hardware
* if interrupts are to be used with the driver. The interrupt functions of
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
* 1.00a mta  02/24/07 First release
* </pre>
*
******************************************************************************/

#ifndef XMPMC_H			/* prevent circular inclusions */
#define XMPMC_H			/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xmpmc_hw.h"
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
	int EccSupportPresent;
} XMpmc_Config;

/**
 * The XMpmc driver stats data. A pointer to a variable of this type is
 * passed to the driver API functions.
 */
typedef struct {
	u16 SingleErrorCount; /* Single Error Count */
	u16 DoubleErrorCount; /* Double Error Count */
	u16 ParityErrorCount; /* Parity Error Count */
	u32 LastErrorAddress; /* Address of memory where error has occurred. */
	u8 EccErrorSyndrome;  /* Indicates ECC error syndrome value. */
	u8 EccErrorTransSize; /* Size of NPI trans where the error occured */
	u8 ErrorReadWrite;    /* Indicates if error occurred in read/write */
} XMpmc_Stats;

/**
 * The XMpmc driver instance data. The user is required to allocate a
 * variable of this type for every MPMC device in the system. A pointer
 * to a variable of this type is then passed to the driver API functions.
 */
typedef struct {
	u32 IsReady;		/**< Device is initialized and ready */
	XMpmc_Config *ConfigPtr;
} XMpmc;

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

/*
 * API Basic functions implemented in xmpmc.c.
 */
int XMpmc_CfgInitialize(XMpmc * InstancePtr, XMpmc_Config * ConfigPtr,
			u32 EffectiveAddr);
void XMpmc_EnableEcc(XMpmc * InstancePtr);
void XMpmc_DisableEcc(XMpmc * InstancePtr);

void XMpmc_SetControl(XMpmc * InstancePtr, u32 Control);
u32 XMpmc_GetControl(XMpmc * InstancePtr);
u32 XMpmc_GetStatus(XMpmc * InstancePtr);
void XMpmc_ClearStatus(XMpmc * InstancePtr);

XMpmc_Config *XMpmc_LookupConfig(u16 DeviceId);

/*
 * API Functions implemented in xmpmc_stats.c.
 */
void XMpmc_GetStats(XMpmc * InstancePtr, XMpmc_Stats * StatsPtr);
void XMpmc_ClearStats(XMpmc * InstancePtr);

/*
 * API Functions implemented in xmpmc_selftest.c.
 */
int XMpmc_SelfTest(XMpmc * InstancePtr);

/*
 * API Functions implemented in xmpmc_intr.c.
 */
void XMpmc_IntrGlobalEnable(XMpmc * InstancePtr);
void XMpmc_IntrGlobalDisable(XMpmc * InstancePtr);

void XMpmc_IntrEnable(XMpmc * InstancePtr, u32 Mask);
void XMpmc_IntrDisable(XMpmc * InstancePtr, u32 Mask);
void XMpmc_IntrClear(XMpmc * InstancePtr, u32 Mask);
u32 XMpmc_IntrGetEnabled(XMpmc * InstancePtr);
u32 XMpmc_IntrGetStatus(XMpmc * InstancePtr);

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */

