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
*       (c) Copyright 2002 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xps2_i.h
*
* This header file contains internal identifiers, which are those shared
* between the files of the driver. It is intended for internal use only.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ch   06/18/02 First release
* </pre>
*
******************************************************************************/
#ifndef XPS2_I_H /* prevent circular inclusions */
#define XPS2_I_H /* by using protection macros */

/***************************** Include Files ********************************/

#include "xps2.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/****************************************************************************
*
* This macro clears the statistics of the component instance. The purpose of
* this macro is to allow common processing between the modules of the
* component with less overhead than a function in the required module.
*
* @param    InstancePtr is a pointer to the XPs2 instance to be worked on.
*
* @return
*
* None.
*
* @note
*
* Signature: void XPs2_mClearStats(XPs2 *InstancePtr)
*
*****************************************************************************/
#define XPs2_mClearStats(InstancePtr)                             \
{                                                                       \
    InstancePtr->Stats.TransmitInterrupts = 0UL;                        \
    InstancePtr->Stats.ReceiveInterrupts = 0UL;                         \
    InstancePtr->Stats.CharactersTransmitted = 0UL;                     \
    InstancePtr->Stats.CharactersReceived = 0UL;                        \
    InstancePtr->Stats.ReceiveErrors = 0UL;                             \
    InstancePtr->Stats.ReceiveOverflowErrors = 0UL;                     \
    InstancePtr->Stats.TransmitErrors = 0UL;                            \
}

/************************** Variable Definitions ****************************/

extern XPs2_Config XPs2_ConfigTable[];

/************************** Function Prototypes *****************************/

unsigned int XPs2_SendBuffer(XPs2 *InstancePtr);
unsigned int XPs2_ReceiveBuffer(XPs2 *InstancePtr);

#endif
