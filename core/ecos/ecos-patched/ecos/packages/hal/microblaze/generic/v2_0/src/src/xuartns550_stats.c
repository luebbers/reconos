/* $Id: xuartns550_stats.c,v 1.1 2006/02/17 22:43:40 moleres Exp $ */
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
* @file xuartns550_stats.c
*
* This file contains the statistics functions for the 16450/16550 UART driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ecm  08/16/01 First release
* 1.00b jhl  03/11/02 Repartitioned driver for smaller files.
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xuartns550.h"
#include "xuartns550_i.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/


/****************************************************************************/
/**
*
* This functions returns a snapshot of the current statistics in the area
* provided.
*
* @param    InstancePtr is a pointer to the XUartNs550 instance to be worked on.
* @param    StatsPtr is a pointer to a XUartNs550Stats structure to where the
*           statistics are to be copied to.
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
void XUartNs550_GetStats(XUartNs550 *InstancePtr, XUartNs550Stats *StatsPtr)
{
    /*
     * Assert validates the input arguments
     */
    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(StatsPtr != XNULL);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    StatsPtr->TransmitInterrupts = InstancePtr->Stats.TransmitInterrupts;
    StatsPtr->ReceiveInterrupts = InstancePtr->Stats.ReceiveInterrupts;
    StatsPtr->StatusInterrupts = InstancePtr->Stats.StatusInterrupts;
    StatsPtr->ModemInterrupts = InstancePtr->Stats.ModemInterrupts;
    StatsPtr->CharactersTransmitted = InstancePtr->Stats.CharactersTransmitted;
    StatsPtr->CharactersReceived = InstancePtr->Stats.CharactersReceived;
    StatsPtr->ReceiveOverrunErrors = InstancePtr->Stats.ReceiveOverrunErrors;
    StatsPtr->ReceiveFramingErrors = InstancePtr->Stats.ReceiveFramingErrors;
    StatsPtr->ReceiveParityErrors = InstancePtr->Stats.ReceiveParityErrors;
    StatsPtr->ReceiveBreakDetected = InstancePtr->Stats.ReceiveBreakDetected;
}

/****************************************************************************/
/**
*
* This function zeros the statistics for the given instance.
*
* @param    InstancePtr is a pointer to the XUartNs550 instance to be worked on.
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
void XUartNs550_ClearStats(XUartNs550 *InstancePtr)
{
    /*
     * Assert validates the input arguments
     */
    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* Use the macro to clear the stats so that there is common code for
     * this operation
     */
    XUartNs550_mClearStats(InstancePtr);
}

