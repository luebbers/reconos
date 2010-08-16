/* $Id: xddr_selftest.c,v 1.1 2007/04/04 18:24:18 wre Exp $ */
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
* @file xddr_selftest.c
*
* The implementation of the XDdr component's functionality that is related
* to selftest. See xddr.h for more information about the component.
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

#include "xddr.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/

/****************************************************************************/
/**
* Perform a self-test on the DDR device. Self-test will read, write and verify
* that some of the registers of the device are functioning correctly. This
* function will restore the state of the device to state it was in prior to
* the function call.
*
* @param InstancePtr is the DDR component to operate on.
*
* @return
*
* - XST_SUCCESS     The self-test was successful.
* - XST_FAILURE     The self-test failed.
*
* @note
*
* None
*
*****************************************************************************/
int XDdr_SelfTest(XDdr * InstancePtr)
{
	int Status = XST_SUCCESS;
	u32 IeRegister;
	u32 GieRegister;

	/*
	 * Assert arguments
	 */
	XASSERT_NONVOID(InstancePtr != NULL);
	XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/* Save a copy of the global interrupt enable register and interrupt enable
	 * register before writing them so that they can be restored.
	 */
	GieRegister = XDdr_mReadReg(InstancePtr->BaseAddress,
				    XDDR_IPIF_OFFSET + XDDR_DGIE_OFFSET);
	IeRegister = XDdr_mReadReg(InstancePtr->BaseAddress,
				   XDDR_IPIF_OFFSET + XDDR_IPIER_OFFSET);

	/* Disable the global interrupt so that enabling the interrupts won't
	 * affect the user.
	 */

	XDdr_mWriteReg(InstancePtr->BaseAddress,
		       XDDR_IPIF_OFFSET + XDDR_DGIE_OFFSET, 0);

	/* Enable the Single Error interrupt and then verify that the register
	 * is reads back correct.
	 */
	XDdr_mWriteReg(InstancePtr->BaseAddress,
		       XDDR_IPIF_OFFSET + XDDR_IPIER_OFFSET,
		       XDDR_IPIXR_SE_IX_MASK);

	if (XDdr_mReadReg(InstancePtr->BaseAddress,
			  XDDR_IPIF_OFFSET + XDDR_IPIER_OFFSET) !=
	    XDDR_IPIXR_SE_IX_MASK) {
		Status = XST_FAILURE;
	}

	/* Restore the IP Interrupt Enable Register to the value before the
	 * test.
	 */
	XDdr_mWriteReg(InstancePtr->BaseAddress,
		       XDDR_IPIF_OFFSET + XDDR_IPIER_OFFSET, IeRegister);

	/* Restore the global interrupt to the value before the test. */

	XDdr_mWriteReg(InstancePtr->BaseAddress,
		       XDDR_IPIF_OFFSET + XDDR_DGIE_OFFSET, GieRegister);

	return Status;
}
