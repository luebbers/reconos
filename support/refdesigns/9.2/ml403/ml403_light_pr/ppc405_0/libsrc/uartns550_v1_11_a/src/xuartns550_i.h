/* $Id: xuartns550_i.h,v 1.1 2007/04/04 18:35:36 wre Exp $ */
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
* @file xuartns550_i.h
*
* This header file contains internal identifiers, which are those shared
* between the files of the driver. It is intended for internal use only.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ecm  08/16/01 First release
* 1.00b jhl  03/11/02 Repartitioned driver for smaller files.
* 1.11a sv   03/20/07 Updated to use the new coding guidelines.
* </pre>
*
******************************************************************************/

#ifndef XUARTNS550_I_H /* prevent circular inclusions */
#define XUARTNS550_I_H /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xuartns550.h"

/************************** Constant Definitions *****************************/


/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/****************************************************************************
*
* This macro updates the status based upon a specified line status register
* value. The stats that are updated are based upon bits in this register. It
* also keeps the last errors instance variable updated. The purpose of this
* macro is to allow common processing between the modules of the component
* with less overhead than a function in the required module.
*
* @param	InstancePtr is a pointer to the XUartNs550 instance .
* @param	CurrentLsr contains the Line Status Register value to
*		be used for the update.
*
* @return 	None.
*
* @note
*
* Signature:
* void XUartNs550_mUpdateStats(XUartNs550 *InstancePtr, u8 CurrentLsr)
*
*****************************************************************************/
#define XUartNs550_mUpdateStats(InstancePtr, CurrentLsr)	\
{								\
	InstancePtr->LastErrors |= CurrentLsr;			\
								\
	if (CurrentLsr & XUN_LSR_OVERRUN_ERROR) {		\
		InstancePtr->Stats.ReceiveOverrunErrors++;	\
	}							\
	if (CurrentLsr & XUN_LSR_PARITY_ERROR) {		\
		InstancePtr->Stats.ReceiveParityErrors++;	\
	}							\
	if (CurrentLsr & XUN_LSR_FRAMING_ERROR) {		\
		InstancePtr->Stats.ReceiveFramingErrors++;	\
	}							\
	if (CurrentLsr & XUN_LSR_BREAK_INT) {			\
		InstancePtr->Stats.ReceiveBreakDetected++;	\
	}							\
}

/****************************************************************************
*
* This macro clears the statistics of the component instance. The purpose of
* this macro is to allow common processing between the modules of the
* component with less overhead than a function in the required module.
*
* @param	InstancePtr is a pointer to the XUartNs550 instance .
*
* @return	None.
*
* @note
*
* Signature: void XUartNs550_mClearStats(XUartNs550 *InstancePtr)
*
*****************************************************************************/
#define XUartNs550_mClearStats(InstancePtr)			\
{								\
	InstancePtr->Stats.TransmitInterrupts = 0UL;		\
	InstancePtr->Stats.ReceiveInterrupts = 0UL;		\
	InstancePtr->Stats.StatusInterrupts = 0UL;		\
	InstancePtr->Stats.ModemInterrupts = 0UL;		\
	InstancePtr->Stats.CharactersTransmitted = 0UL;		\
	InstancePtr->Stats.CharactersReceived = 0UL;		\
	InstancePtr->Stats.ReceiveOverrunErrors = 0UL;		\
	InstancePtr->Stats.ReceiveFramingErrors = 0UL;		\
	InstancePtr->Stats.ReceiveParityErrors = 0UL;		\
	InstancePtr->Stats.ReceiveBreakDetected = 0UL;		\
}

/************************** Function Prototypes ******************************/

int XUartNs550_SetBaudRate(XUartNs550 *InstancePtr, u32 BaudRate);

unsigned int XUartNs550_SendBuffer(XUartNs550 *InstancePtr);

unsigned int XUartNs550_ReceiveBuffer(XUartNs550 *InstancePtr);

/************************** Variable Definitions ****************************/

extern XUartNs550_Config XUartNs550_ConfigTable[];

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */

