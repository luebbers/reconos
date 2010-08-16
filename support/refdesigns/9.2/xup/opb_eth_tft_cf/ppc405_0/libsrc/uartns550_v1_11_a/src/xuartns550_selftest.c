/* $Id: xuartns550_selftest.c,v 1.1 2007/04/04 18:35:36 wre Exp $ */
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
*       (c) Copyright 2002-2007 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xuartns550_selftest.c
*
* This file contains the self-test functions for the 16450/16550 UART driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date	 Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ecm  08/16/01 First release
* 1.00b jhl  03/11/02 Repartitioned driver for smaller files.
* 1.11a sv   03/20/07 Updated to use the new coding guidelines.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xstatus.h"
#include "xuartns550.h"
#include "xuartns550_i.h"
#include "xio.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/

#define XUN_TOTAL_BYTES 32

/************************** Variable Definitions *****************************/

static u8 TestString[XUN_TOTAL_BYTES + 1] =
					"abcdefghABCDEFGH0123456776543210";
static u8 ReturnString[XUN_TOTAL_BYTES + 1];

/************************** Function Prototypes ******************************/


/****************************************************************************/
/**
*
* This functions runs a self-test on the driver and hardware device. This self
* test performs a local loopback and verifies data can be sent and received.
*
* The statistics are cleared at the end of the test. The time for this test
* to execute is proportional to the baud rate that has been set prior to
* calling this function.
*
* @param	InstancePtr is a pointer to the XUartNs550 instance
*
* @return
*
* 		- XST_SUCCESS if the test was successful
* 		- XST_UART_TEST_FAIL if the test failed looping back the data
*
* @note 	This function can hang if the hardware is not functioning
*		properly.
*
******************************************************************************/
int XUartNs550_SelfTest(XUartNs550 *InstancePtr)
{
	int Status = XST_SUCCESS;
	u8 McrRegister;
	u8 LsrRegister;
	u8 IerRegister;
	u8 Index;

	/*
	 * Assert validates the input arguments
	 */
	XASSERT_NONVOID(InstancePtr != NULL);
	XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

	/*
	 * Setup for polling by disabling all interrupts in the interrupt enable
	 * register
	 */
	IerRegister = XIo_In8(InstancePtr->BaseAddress + XUN_IER_OFFSET);
	XIo_Out8(InstancePtr->BaseAddress + XUN_IER_OFFSET, 0);

	/*
	 * Setup for loopback by enabling the loopback in the modem control
	 * register
	 */
	McrRegister = XIo_In8(InstancePtr->BaseAddress + XUN_MCR_OFFSET);
	XIo_Out8(InstancePtr->BaseAddress + XUN_MCR_OFFSET,
			 McrRegister | XUN_MCR_LOOP);

	/*
	 * Send a number of bytes and receive them, one at a time so this
	 * test will work for 450 and 550
	 */
	for (Index = 0; Index < XUN_TOTAL_BYTES; Index++) {
		/*
		 * Send out the byte and if it was not sent then the failure
		 * will be caught in the compare at the end
		 */
		XUartNs550_Send(InstancePtr, &TestString[Index], 1);

		/*
		 * Wait til the byte is received such that it should be waiting
		 * in the receiver. This can hang if the HW is broken.
		 */
		do {
			LsrRegister = XIo_In8(InstancePtr->BaseAddress +
				  XUN_LSR_OFFSET);
		}
		while ((LsrRegister & XUN_LSR_DATA_READY) == 0);

		/*
		 * Receive the byte that should have been received because of
		 * the loopback, if it wasn't received then it will be caught
		 * in the compare at the end
		 */
		XUartNs550_Recv(InstancePtr, &ReturnString[Index], 1);
	}

	/*
	 * Clear the stats since they are corrupted by the test
	 */
	XUartNs550_mClearStats(InstancePtr);

	/*
	 * Compare the bytes received to the bytes sent to verify the exact data
	 * was received
	 */
	for (Index = 0; Index < XUN_TOTAL_BYTES; Index++) {
		if (TestString[Index] != ReturnString[Index]) {
			Status = XST_UART_TEST_FAIL;
		}
	}

	/*
	 * Restore the registers which were altered to put into polling and
	 * loopback modes so that this test is not destructive
	 */
	XIo_Out8(InstancePtr->BaseAddress + XUN_IER_OFFSET, IerRegister);
	XIo_Out8(InstancePtr->BaseAddress + XUN_MCR_OFFSET, McrRegister);

	return Status;
}

