/* $Id: xemac_l.c,v 1.1 2004/04/06 16:49:36 robertm Exp $ */
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
* @file xemac_l.c
*
* This file contains low-level polled functions to send and receive Ethernet
* frames.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- ------------------------------------------------------
* 1.00b rpm  04/29/02 First release
* 1.00c rpm  12/05/02 New version includes support for simple DMA
* 1.00d rpm  09/26/03 New version includes support PLB Ethernet and v2.00a of
*                     the packet fifo driver.
* 1.00d rpm  10/22/03 Fixed the Level 0 functions to work with the PLB EMAC.
*                     These functions now make use of the packet fifo driver.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xemac_l.h"
#include "xpacket_fifo_l_v2_00_a.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

/*****************************************************************************/
/**
*
* Send an Ethernet frame. This size is the total frame size, including header.
* This function blocks waiting for the frame to be transmitted.
*
* @param BaseAddress is the base address of the device
* @param FramePtr is a pointer to a 32-bit aligned frame
* @param Size is the size, in bytes, of the frame
*
* @return
*
* None.
*
* @note
*
* An early return may occur if there is no room in the FIFO for the requested
* frame.
*
******************************************************************************/
void XEmac_SendFrame(Xuint32 BaseAddress, Xuint8 *FramePtr, int Size)
{
    XStatus Result;

    /*
     * Use the packet fifo driver write the FIFO
     */
    Result = XPacketFifoV200a_L0Write(BaseAddress + XEM_PFIFO_TXREG_OFFSET,
                                      BaseAddress + XEM_PFIFO_TXDATA_OFFSET,
                                      FramePtr, Size);

    /* No room in the FIFO, just return */
    if (Result != XST_SUCCESS)
    {
        return;
    }

    /*
     * The frame is in the Fifo, now send it
     */
    XIo_Out32(BaseAddress + XEM_TPLR_OFFSET, Size);

    /*
     * Loop on the status waiting for the transmit to be complete
     */
    while (!XEmac_mIsTxDone(BaseAddress));

    /* Need to read the Transmit Status Register to get rid of the status */
    (void)XIo_In32(BaseAddress + XEM_TSR_OFFSET);

    /*
     * Clear the status now so we're ready again next time
     */
    XIo_Out32(BaseAddress + XEM_ISR_OFFSET, XEM_EIR_XMIT_DONE_MASK);
}


/*****************************************************************************/
/**
*
* Receive a frame. Wait for a frame to arrive.
*
* @param BaseAddress is the base address of the device
* @param FramePtr is a pointer to a 32-bit aligned buffer where the frame will
*        be stored
*
* @return
*
* The size, in bytes, of the frame received.
*
* @note
*
* None.
*
******************************************************************************/
int XEmac_RecvFrame(Xuint32 BaseAddress, Xuint8 *FramePtr)
{
    int Length;

    /*
     * Wait for a frame to arrive
     */
    while (XEmac_mIsRxEmpty(BaseAddress));

    /*
     * Get the length of the frame that arrived
     */
    Length = XIo_In32(BaseAddress + XEM_RPLR_OFFSET);

    /*
     * Clear the status now that the length is read so we're ready again
     * next time
     */
    XIo_Out32(BaseAddress + XEM_ISR_OFFSET, XEM_EIR_RECV_DONE_MASK);

    /*
     * Use the packet fifo driver to read the FIFO. We assume the Length is
     * valid and there is enough data in the FIFO - so we ignore the return
     * code.
     */
    (void)XPacketFifoV200a_L0Read(BaseAddress + XEM_PFIFO_RXREG_OFFSET,
                                  BaseAddress + XEM_PFIFO_RXDATA_OFFSET,
                                  FramePtr, Length);

    return Length;
}
