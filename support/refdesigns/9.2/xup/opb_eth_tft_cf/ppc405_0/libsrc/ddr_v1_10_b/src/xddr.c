/* $Id: xddr.c,v 1.2 2007/05/31 00:29:40 wre Exp $ */
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
/**
* @file xddr.c
*
* The implementation of the XDdr component's basic functionality. See xddr.h
* for more information about the component.
*
* @note
*
* None
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
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xparameters.h"
#include "xddr.h"
#include "xstatus.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/


/****************************************************************************/
/**
* Initialize the XDdr instance provided by the caller based on the
* given DeviceID.
*
* Nothing is done except to initialize the InstancePtr.
*
* @param InstancePtr is a pointer to an XDdr instance. The memory the pointer
*        references must be pre-allocated by the caller. Further calls to
*        manipulate the component through the XDdr API must be made with this
*        pointer.
*
* @param DeviceId is the unique id of the device controlled by this XDdr
*        component.  Passing in a device id associates the generic XDdr
*        instance to a specific device, as chosen by the caller or application
*        developer.
*
* @return
*
* - XST_SUCCESS           Initialization was successfull.
* - XST_DEVICE_NOT_FOUND  Device configuration data was not found for a device
*                         with the supplied device ID.
*
* @note
*
* None.
*
*****************************************************************************/
int XDdr_Initialize(XDdr * InstancePtr, u16 DeviceId)
{
	XDdr_Config *ConfigPtr;

	/*
	 * Assert arguments
	 */
	XASSERT_NONVOID(InstancePtr != NULL);

	/*
	 * Lookup configuration data in the device configuration table.
	 * Use this configuration info down below when initializing this component.
	 */
	ConfigPtr = XDdr_LookupConfig(DeviceId);
	if (ConfigPtr == (XDdr_Config *) NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	/*
	 * Set some default values.
	 */
	InstancePtr->BaseAddress = ConfigPtr->BaseAddress;
	InstancePtr->ConfigPtr = ConfigPtr;

	/*
	 * Indicate the instance is now ready to use, initialized without error
	 */
	InstancePtr->IsReady = XCOMPONENT_IS_READY;
	return (XST_SUCCESS);
}

/******************************************************************************/
/**
* Lookup the device configuration based on the unique device ID.  The table
* XDdr_ConfigTable contains the configuration info for each device in the
* system.
*
* @param DeviceID is the device identifier to lookup.
*
* @return
*
* - XDdr configuration structure pointer if DeviceID is found.
* - NULL if DeviceID is not found.
*
* @note
*
* None.
*
******************************************************************************/
XDdr_Config *XDdr_LookupConfig(u16 DeviceId)
{
	XDdr_Config *CfgPtr = NULL;
	extern XDdr_Config XDdr_ConfigTable[];

	int i;

	for (i = 0; i < XPAR_XDDR_NUM_INSTANCES; i++) {
		if (XDdr_ConfigTable[i].DeviceId == DeviceId) {
			CfgPtr = &XDdr_ConfigTable[i];
			break;
		}
	}

	return CfgPtr;
}

/****************************************************************************/
/**
* Enable the ECC mode for both read and write operations in the DDR ECC
* device.
*
* @param InstancePtr is a pointer to an XDdr instance to be worked on.
*
* @return
*
* None.
*
* @note
*
* None.
*
*****************************************************************************/
void XDdr_EnableEcc(XDdr * InstancePtr)
{
	u32 Register;

	/*
	 * Assert arguments
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/* Set the bits to enable both the read and write ECC operations without
	 * altering any other bits of the register.
	 */
	Register = XDdr_mReadReg(InstancePtr->BaseAddress, XDDR_ECCCR_OFFSET);
	XDdr_mWriteReg(InstancePtr->BaseAddress, XDDR_ECCCR_OFFSET,
		       Register | (XDDR_ECCCR_RE_MASK | XDDR_ECCCR_WE_MASK));
}

/****************************************************************************/
/**
* Disable the ECC mode for both read and write operations in the DDR ECC
* device.
*
* @param InstancePtr is a pointer to an XDdr instance to be worked on.
*
* @return
*
* None.
*
* @note
*
* None.
*
*****************************************************************************/
void XDdr_DisableEcc(XDdr * InstancePtr)
{
	u32 Register;

	/*
	 * Assert arguments
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/* Clear the bits to disable both the read and write ECC operations without
	 * altering any other bits of the register.
	 */
	Register = XDdr_mReadReg(InstancePtr->BaseAddress, XDDR_ECCCR_OFFSET);
	XDdr_mWriteReg(InstancePtr->BaseAddress, XDDR_ECCCR_OFFSET,
		       Register & ~(XDDR_ECCCR_RE_MASK | XDDR_ECCCR_WE_MASK));
}

/****************************************************************************/
/**
* Set the ECC Control Register of the DDR device to the specified value. This
* function can be used to individually enable/disable read or write ECC and
* force specific types of ECC errors to occur.
*
* @param InstancePtr is a pointer to an XDdr instance to be worked on.
*
* @param Control contains the value to be written to the register and consists
*        of constants named XDDR_ECCCR* for each bit field as specified in
*        xddr_l.h.
*
* @return
*
* None.
*
* @note
*
* None.
*
*****************************************************************************/
void XDdr_SetControl(XDdr * InstancePtr, u32 Control)
{
	/*
	 * Assert arguments
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/* Set the control register without any concern for destructiveness. */

	XDdr_mWriteReg(InstancePtr->BaseAddress, XDDR_ECCCR_OFFSET, Control);
}

/****************************************************************************/
/**
* Get the ECC Control Register contents of the DDR device. This function can
* be used to determine which features are enabled in the device.
*
* @param InstancePtr is a pointer to an XDdr instance to be worked on.
*
* @return
*
* The value read from the register which consists of constants named
* XDDR_ECCCR* for each bit field as specified in xddr_l.h.
*
* @note
*
* None.
*
*****************************************************************************/
u32 XDdr_GetControl(XDdr * InstancePtr)
{
	/*
	 * Assert arguments
	 */
	XASSERT_NONVOID(InstancePtr != NULL);
	XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	return XDdr_mReadReg(InstancePtr->BaseAddress, XDDR_ECCCR_OFFSET);
}

/****************************************************************************/
/**
* Get the ECC Status Register contents of the DDR device. This function can
* be used to determine which errors have occurred for ECC mode.
*
* @param InstancePtr is a pointer to an XDdr instance to be worked on.
*
* @return
*
* The value read from the register which consists of constants named
* XDDR_ECCSR* for each bit field as specified in xddr_l.h.
*
* None.
*
* @note
*
* None.
*
*****************************************************************************/
u32 XDdr_GetStatus(XDdr * InstancePtr)
{
	/*
	 * Assert arguments
	 */
	XASSERT_NONVOID(InstancePtr != NULL);
	XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	return XDdr_mReadReg(InstancePtr->BaseAddress, XDDR_ECCSR_OFFSET);
}

/****************************************************************************/
/**
* Clear the ECC Status Register contents of the DDR device. This function can
* be used to clear errors in the status that have been processed.
*
* @param InstancePtr is a pointer to an XDdr instance to be worked on.
*
* @return
*
* None.
*
* @note
*
* None.
*
*****************************************************************************/
void XDdr_ClearStatus(XDdr * InstancePtr)
{
	/*
	 * Assert arguments
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/* Any value written causes the status to be cleared */

	XDdr_mWriteReg(InstancePtr->BaseAddress, XDDR_ECCSR_OFFSET, 0);
}
