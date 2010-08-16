/* $Id: xddr_stats.c,v 1.1 2007/04/04 18:24:18 wre Exp $ */
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
* @file xddr_stats.c
*
* The implementation of the XDdr component's functionality that is related
* to statistics. See xddr.h for more information about the component.
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
* Get the statistics of the DDR device including the Single Error Count,
* Double Error Count, and Parity Field Error Count.  The counts are all
* contained in registers of the DDR device.
*
* @param InstancePtr is a pointer to an XDdr instance to be worked on.
*
* @param StatsPtr contains a pointer to a XDdr_Stats data type. The function
*        puts the statistics of the device into the specified data structure.
*
* @return
*
* The statistics data type pointed to by input StatsPtr is modified.
*
* @note
*
* None.
*
*****************************************************************************/
void XDdr_GetStats(XDdr * InstancePtr, XDdr_Stats * StatsPtr)
{
	/*
	 * Assert arguments
	 */
	XASSERT_VOID(InstancePtr != NULL);
	XASSERT_VOID(StatsPtr != NULL);

	/* Read all the error count registers and save their values in the
	 * specified statistics area.
	 */
	StatsPtr->SingleErrorCount =
		(u16) XDdr_mReadReg(InstancePtr->BaseAddress,
				    XDDR_ECCSEC_OFFSET);
	StatsPtr->DoubleErrorCount =
		(u16) XDdr_mReadReg(InstancePtr->BaseAddress,
				    XDDR_ECCDEC_OFFSET);
	StatsPtr->ParityErrorCount =
		(u16) XDdr_mReadReg(InstancePtr->BaseAddress,
				    XDDR_ECCPEC_OFFSET);
}

/****************************************************************************/
/**
* Clear the statistics of the DDR device including the Single Error Count,
* Double Error Count, and Parity Field Error Count.  The counts are all
* contained in registers of the DDR device.
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
void XDdr_ClearStats(XDdr * InstancePtr)
{
	/*
	 * Assert arguments
	 */
	XASSERT_VOID(InstancePtr != NULL);

	/* Clear all the error count registers in the device.
	 */
	XDdr_mWriteReg(InstancePtr->BaseAddress, XDDR_ECCSEC_OFFSET, 0);
	XDdr_mWriteReg(InstancePtr->BaseAddress, XDDR_ECCDEC_OFFSET, 0);
	XDdr_mWriteReg(InstancePtr->BaseAddress, XDDR_ECCPEC_OFFSET, 0);
}
