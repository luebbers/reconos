/* $Id: xmpmc.c,v 1.4 2007/06/07 07:56:01 svemula Exp $ */
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
/**
* @file xmpmc.c
*
* The implementation of the XMpmc component's basic functionality. See xmpmc.h
* for more information about the component.
*
* @note		None.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a mta  02/24/07 First release
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xmpmc.h"
#include "xstatus.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

/*****************************************************************************/
/**
*
* This function initializes a specific XMpmc instance.
*
* @param	InstancePtr is a pointer to the XMpmc instance.
* @param	ConfigPtr points to the XMpmc device configuration structure.
* @param	EffectiveAddr is the device base address in the virtual memory
*		address space. If the address translation is not used then the
*		physical address is passed.
*		Unexpected errors may occur if the address mapping is changed
*		after this function is invoked.
*
* @return
*		- XST_SUCCESS if successful.
*		- XST_FAILURE if ECC support is not configured in the device.
*
* @note		None.
*
******************************************************************************/
int XMpmc_CfgInitialize(XMpmc * InstancePtr, XMpmc_Config * ConfigPtr,
			u32 EffectiveAddr)
{
	XASSERT_NONVOID(InstancePtr != NULL);
	XASSERT_NONVOID(ConfigPtr != NULL);

	/*
	 * Set some default values.
	 */
	InstancePtr->IsReady = FALSE;


	/*
	 * Return an error if ECC Support is not present in the core.
	 */
	if (ConfigPtr->EccSupportPresent != TRUE){
		return XST_FAILURE;
	}



	/*
	 * Initialize the intance structure with
	 * device configuration data.
	 */
	InstancePtr->ConfigPtr->BaseAddress = EffectiveAddr;
	InstancePtr->ConfigPtr->EccSupportPresent =
				ConfigPtr->EccSupportPresent;
	InstancePtr->ConfigPtr->DeviceId = ConfigPtr->DeviceId;


	InstancePtr->IsReady = XCOMPONENT_IS_READY;

	return XST_SUCCESS;
}

/****************************************************************************/
/**
* Enable the ECC mode for both read and write operations in the MPMC device.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_EnableEcc(XMpmc * InstancePtr)
{
	u32 Register;

	/*
	 * Assert arguments.
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/* Set the bits to enable both the read and write ECC operations without
	 * altering any other bits of the register.
	 */
	Register = XMpmc_mReadReg(InstancePtr->ConfigPtr->BaseAddress,
				  XMPMC_ECCCR_OFFSET);
	XMpmc_mWriteReg(InstancePtr->ConfigPtr->BaseAddress, XMPMC_ECCCR_OFFSET,
			Register | (XMPMC_ECCCR_RE_MASK | XMPMC_ECCCR_WE_MASK));
}

/****************************************************************************/
/**
* Disable the ECC mode for both read and write operations in the MPMC device.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_DisableEcc(XMpmc * InstancePtr)
{
	u32 Register;

	/*
	 * Assert arguments.
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/*
	 * Clear the bits to disable both the read and write ECC operations
	 * without altering any other bits of the register.
	 */
	Register = XMpmc_mReadReg(InstancePtr->ConfigPtr->BaseAddress,
				  XMPMC_ECCCR_OFFSET);
	XMpmc_mWriteReg(InstancePtr->ConfigPtr->BaseAddress, XMPMC_ECCCR_OFFSET,
			Register & ~(XMPMC_ECCCR_RE_MASK |
				     XMPMC_ECCCR_WE_MASK));
}

/****************************************************************************/
/**
* Set the ECC Control Register of the MPMC device to the specified value. This
* function can be used to individually enable/disable read or write ECC and
* force specific types of ECC errors to occur.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
* @param	Control contains the value to be written to the register and
*		consists of constants named XMPMC_ECCCR* for each bit field as
*		specified in xmpmc_hw.h.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_SetControl(XMpmc * InstancePtr, u32 Control)
{
	/*
	 * Assert arguments.
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/*
	 * Set the control register without any concern for destructiveness.
	 */
	XMpmc_mWriteReg(InstancePtr->ConfigPtr->BaseAddress, XMPMC_ECCCR_OFFSET,
			Control);
}

/****************************************************************************/
/**
* Get the ECC Control Register contents of the MPMC device. This function can
* be used to determine which features are enabled in the device.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	The value read from the register which consists of constants
*		named XMPMC_ECCCR* for each bit field as specified in
*		xmpmc_hw.h.
*
* @note		None.
*
*****************************************************************************/
u32 XMpmc_GetControl(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	XASSERT_NONVOID(InstancePtr != NULL);
	XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	return XMpmc_mReadReg(InstancePtr->ConfigPtr->BaseAddress,
			      XMPMC_ECCCR_OFFSET);
}

/****************************************************************************/
/**
* Get the ECC Status Register contents of the MPMC device. This function can
* be used to determine which errors have occurred for ECC mode.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	The value read from the register which consists of constants
*		named XMPMC_ECCSR* for each bit field as specified in
*		xmpmc_hw.h.
*
* @note		None.
*
*****************************************************************************/
u32 XMpmc_GetStatus(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	XASSERT_NONVOID(InstancePtr != NULL);
	XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	return XMpmc_mReadReg(InstancePtr->ConfigPtr->BaseAddress,
			      XMPMC_ECCSR_OFFSET);
}

/****************************************************************************/
/**
* Clear the ECC Status Register contents of the MPMC device. This function can
* be used to clear errors in the status that have been processed.
*
* @param	InstancePtr is a pointer to an XMpmc instance to be worked on.
*
* @return	None.
*
* @note		None.
*
*****************************************************************************/
void XMpmc_ClearStatus(XMpmc * InstancePtr)
{
	/*
	 * Assert arguments.
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/*
	 * Any value written causes the status to be cleared.
	 */
	XMpmc_mWriteReg(InstancePtr->ConfigPtr->BaseAddress,
			XMPMC_ECCSR_OFFSET, 0);
}
