/* $Id: xuartns550_sinit.c,v 1.1 2007/04/04 18:35:36 wre Exp $ */
/*****************************************************************************
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
*       (c) Copyright 2005-2007 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xuartns550_sinit.c
*
* The implementation of the XUartNs550 component's static initialzation
* functionality.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date	 Changes
* ----- ---- -------- -----------------------------------------------
* 1.01a jvb  10/13/05 First release
* 1.11a sv   03/20/07 Updated to use the new coding guidelines.
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xstatus.h"
#include "xparameters.h"
#include "xuartns550_i.h"

/************************** Constant Definitions ****************************/

#ifndef XPAR_DEFAULT_BAUD_RATE
#define XPAR_DEFAULT_BAUD_RATE 19200
#endif

/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/

/****************************************************************************/
/**
*
* Looks up the device configuration based on the unique device ID. A table
* contains the configuration info for each device in the system.
*
* @param	DeviceId contains the ID of the device to look up the
*		configuration for.
*
* @return	A pointer to the configuration found or NULL if the specified
*		device ID was not found.
*
* @note		None.
*
******************************************************************************/
XUartNs550_Config *XUartNs550_LookupConfig(u16 DeviceId)
{
	XUartNs550_Config *CfgPtr = NULL;

	int i;

	for (i=0; i < XPAR_XUARTNS550_NUM_INSTANCES; i++) {
		if (XUartNs550_ConfigTable[i].DeviceId == DeviceId) {
			CfgPtr = &XUartNs550_ConfigTable[i];
			break;
		}
	}

	return CfgPtr;
}

/****************************************************************************/
/**
*
* Initializes a specific XUartNs550 instance such that it is ready to be used.
* The data format of the device is setup for 8 data bits, 1 stop bit, and no
* parity by default. The baud rate is set to a default value specified by
* XPAR_DEFAULT_BAUD_RATE if the symbol is defined, otherwise it is set to
* 19.2K baud. If the device has FIFOs (16550), they are enabled and the a
* receive FIFO threshold is set for 8 bytes. The default operating mode of the
* driver is polled mode.
*
* @param	InstancePtr is a pointer to the XUartNs550 instance .
* @param	DeviceId is the unique id of the device controlled by this
*		XUartNs550 instance. Passing in a device id associates the
*		generic XUartNs550 instance to a specific device, as chosen
*		by the caller or application developer.
*
* @return
*
* 		- XST_SUCCESS if initialization was successful
* 		- XST_DEVICE_NOT_FOUND if the device ID could not be found in
*		the configuration table
* 		- XST_UART_BAUD_ERROR if the baud rate is not possible because
*		the input clock frequency is not divisible with an acceptable
*		amount of error
*
* @note		None.
*
*****************************************************************************/
int XUartNs550_Initialize(XUartNs550 *InstancePtr, u16 DeviceId)
{
	XUartNs550_Config *ConfigPtr;

	/*
	 * Assert validates the input arguments
	 */
	XASSERT_NONVOID(InstancePtr != NULL);

	/*
	 * Lookup the device configuration in the temporary CROM table. Use this
	 * configuration info down below when initializing this component.
	 */
	ConfigPtr = XUartNs550_LookupConfig(DeviceId);
	if (ConfigPtr == (XUartNs550_Config *)NULL) {
		return XST_DEVICE_NOT_FOUND;
	}

	ConfigPtr->DefaultBaudRate = XPAR_DEFAULT_BAUD_RATE;
	return XUartNs550_CfgInitialize(InstancePtr, ConfigPtr,
					ConfigPtr->BaseAddress);
}

