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
* @file xps2_stats.c
*
* This file contains the statistics functions for the PS/2 driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ch   06/24/02 First release
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xps2.h"
#include "xps2_i.h"

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
* @param    InstancePtr is a pointer to the XPs2 instance to be worked on.
* @param    StatsPtr is a pointer to a XPs2Stats structure to where the
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
void XPs2_GetStats(XPs2 *InstancePtr, XPs2Stats *StatsPtr)
{
    /*
     * Assert validates the input arguments
     */
    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(StatsPtr != XNULL);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    StatsPtr->TransmitInterrupts = InstancePtr->Stats.TransmitInterrupts;
    StatsPtr->ReceiveInterrupts = InstancePtr->Stats.ReceiveInterrupts;
    StatsPtr->CharactersTransmitted = InstancePtr->Stats.CharactersTransmitted;
    StatsPtr->CharactersReceived = InstancePtr->Stats.CharactersReceived;
    StatsPtr->ReceiveErrors = InstancePtr->Stats.ReceiveErrors;
    StatsPtr->ReceiveOverflowErrors = InstancePtr->Stats.ReceiveOverflowErrors;
    StatsPtr->TransmitErrors = InstancePtr->Stats.TransmitErrors;
}

/****************************************************************************/
/**
*
* This function zeros the statistics for the given instance.
*
* @param    InstancePtr is a pointer to the XPs2 instance to be worked on.
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
void XPs2_ClearStats(XPs2 *InstancePtr)
{
    /*
     * Assert validates the input arguments
     */
    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* Use the macro to clear the stats so that there is common code for
     * this operation
     */
    XPs2_mClearStats(InstancePtr);
}
