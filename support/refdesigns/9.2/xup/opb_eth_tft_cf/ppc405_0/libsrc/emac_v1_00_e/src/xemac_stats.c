/* $Id: xemac_stats.c,v 1.1 2004/04/06 16:49:36 robertm Exp $ */
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
*       (c) Copyright 2003 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xemac_stats.c
*
* Contains functions to get and clear the XEmac driver statistics.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a rpm  07/31/01 First release
* 1.00b rpm  02/20/02 Repartitioned files and functions
* 1.00c rpm  12/05/02 New version includes support for simple DMA
* 1.00d rpm  09/26/03 New version includes support PLB Ethernet and v2.00a of
*                     the packet fifo driver.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xbasic_types.h"
#include "xemac_i.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/


/************************** Variable Definitions *****************************/


/*****************************************************************************/
/**
*
* Get a copy of the XEmacStats structure, which contains the current
* statistics for this driver. The statistics are only cleared at initialization
* or on demand using the XEmac_ClearStats() function.
*
* The DmaErrors and FifoErrors counts indicate that the device has been or
* needs to be reset. Reset of the device is the responsibility of the upper
* layer software.
*
* @param InstancePtr is a pointer to the XEmac instance to be worked on.
* @param StatsPtr is an output parameter, and is a pointer to a stats buffer
*        into which the current statistics will be copied.
*
* @return
*
* None.
*
* @note
*
* None.
*
******************************************************************************/
void XEmac_GetStats(XEmac *InstancePtr, XEmac_Stats *StatsPtr)
{
    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(StatsPtr != XNULL);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    StatsPtr->XmitFrames = InstancePtr->Stats.XmitFrames;
    StatsPtr->XmitBytes = InstancePtr->Stats.XmitBytes;
    StatsPtr->XmitLateCollisionErrors = InstancePtr->Stats.XmitLateCollisionErrors;
    StatsPtr->XmitExcessDeferral = InstancePtr->Stats.XmitExcessDeferral;
    StatsPtr->XmitOverrunErrors = InstancePtr->Stats.XmitOverrunErrors;
    StatsPtr->XmitUnderrunErrors = InstancePtr->Stats.XmitUnderrunErrors;
    StatsPtr->RecvFrames = InstancePtr->Stats.RecvFrames;
    StatsPtr->RecvBytes = InstancePtr->Stats.RecvBytes;
    StatsPtr->RecvFcsErrors = InstancePtr->Stats.RecvFcsErrors;
    StatsPtr->RecvAlignmentErrors = InstancePtr->Stats.RecvAlignmentErrors;
    StatsPtr->RecvOverrunErrors = InstancePtr->Stats.RecvOverrunErrors;
    StatsPtr->RecvUnderrunErrors = InstancePtr->Stats.RecvUnderrunErrors;
    StatsPtr->RecvMissedFrameErrors = InstancePtr->Stats.RecvMissedFrameErrors;
    StatsPtr->RecvCollisionErrors = InstancePtr->Stats.RecvCollisionErrors;
    StatsPtr->RecvLengthFieldErrors = InstancePtr->Stats.RecvLengthFieldErrors;
    StatsPtr->RecvShortErrors = InstancePtr->Stats.RecvShortErrors;
    StatsPtr->RecvLongErrors = InstancePtr->Stats.RecvLongErrors;
    StatsPtr->DmaErrors = InstancePtr->Stats.DmaErrors;
    StatsPtr->FifoErrors = InstancePtr->Stats.FifoErrors;
    StatsPtr->RecvInterrupts = InstancePtr->Stats.RecvInterrupts;
    StatsPtr->XmitInterrupts = InstancePtr->Stats.XmitInterrupts;
    StatsPtr->EmacInterrupts = InstancePtr->Stats.EmacInterrupts;
    StatsPtr->TotalIntrs = InstancePtr->Stats.TotalIntrs;
}

/*****************************************************************************/
/**
*
* Clear the XEmacStats structure for this driver.
*
* @param InstancePtr is a pointer to the XEmac instance to be worked on.
*
* @return
*
* None.
*
* @note
*
* None.
*
******************************************************************************/
void XEmac_ClearStats(XEmac *InstancePtr)
{
    XASSERT_VOID(InstancePtr != XNULL);

    XEmac_mClearStruct(&InstancePtr->Stats, sizeof(XEmac_Stats));
}
