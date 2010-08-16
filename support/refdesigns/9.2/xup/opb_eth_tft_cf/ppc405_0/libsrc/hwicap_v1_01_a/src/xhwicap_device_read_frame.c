/* $Header:
/devl/xcs/repo/env/Databases/ip2/processor/software/devel/hwicap/v1_00_a/src/xhw
icap_device_read_frame.c,v 1.3 2003/12/10 00:03:53 brandonb Exp $ */
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
*       (c) Copyright 2003-2007 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xhwicap_device_read_frame.c
*
* This file contains the function that reads a specified frame from the
* device (ICAP) and stores it in the bram storage buffer.
*
* @note none.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a bjb  11/20/03 First release
* 1.01a nps  04/10/06 V4 Support
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xhwicap_i.h"
#include "xhwicap.h"
#include <xbasic_types.h>
#include <xstatus.h>

/************************** Constant Definitions ****************************/


/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/

#if XHI_FAMILY == XHI_DEV_FAMILY_V2 /* If V2/V2P device */
/****************************************************************************/
/**
*
* Reads one frame from the device and puts it in the storage buffer.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Block - Block Address (XHI_FAR_CLB_BLOCK,
*           XHI_FAR_BRAM_BLOCK, XHI_FAR_BRAM_INT_BLOCK)
* @param    MajorFrame - selects the column
* @param    MinorFrame - selects frame inside column
*
* @return   XST_SUCCESS, XST_BUFFER_TOO_SMALL or XST_INVALID_PARAM.
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_DeviceReadFrame(XHwIcap *InstancePtr, Xint32 Block,
                                Xint32 MajorFrame, Xint32 MinorFrame)
{

     Xint32 Packet;
     Xint32 Data;
     Xint32 TotalWords;
     XStatus Status;

    /* Make sure we aren't trying to read more than what we have room
     * for. */
    if (InstancePtr->BytesPerFrame >
            (XHI_MAX_BUFFER_BYTES-XHI_HEADER_BUFFER_BYTES))
    {
        return XST_BUFFER_TOO_SMALL;
    }

    /* DUMMY and SYNC */
    XHwIcap_StorageBufferWrite(InstancePtr, 0, XHI_DUMMY_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 1, XHI_SYNC_PACKET);

    /* Setup CMD register to read configuration */
    Packet = XHwIcap_Type1Write(XHI_CMD) | 1;
    Data = XHI_CMD_RCFG;
    XHwIcap_StorageBufferWrite(InstancePtr, 2,Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 3,Data);

    /* Setup FAR register. */
    Packet = XHwIcap_Type1Write(XHI_FAR) | 1;
    Data = XHwIcap_SetupFar(Block, MajorFrame, MinorFrame);
    XHwIcap_StorageBufferWrite(InstancePtr, 4,Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 5,Data);

    /* Setup read data packet header. */
    TotalWords = InstancePtr->WordsPerFrame << 1; /* mult by 2 */

    /* Create Type one packet */
    Packet = XHwIcap_Type1Read(XHI_FDRO) | TotalWords;
    XHwIcap_StorageBufferWrite(InstancePtr, 6,Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 7,0);  /* flush */
    XHwIcap_StorageBufferWrite(InstancePtr, 8,0);  /* flush */

    /* Write To ICAP. */
    Status = XHwIcap_DeviceWrite(InstancePtr, 0, 9);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

    /* Read pad frame (skip header). */
    Status = XHwIcap_DeviceRead(InstancePtr, XHI_HEADER_BUFFER_WORDS,
                                InstancePtr->WordsPerFrame);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

    /* Read data on top of pad frame (skip header). */
    Status = XHwIcap_DeviceRead(InstancePtr, XHI_HEADER_BUFFER_WORDS,
           InstancePtr->WordsPerFrame);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

    /* send DESYNC command */
    Status = XHwIcap_CommandDesync(InstancePtr);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

   return XST_SUCCESS;
};

#else /* If V4 device */
/****************************************************************************/
/**
*
* Reads one frame from the device and puts it in the storage buffer.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Top - top (0) or bottom (1) half of device
* @param    Block - Block Address (XHI_FAR_CLB_BLOCK,
*           XHI_FAR_BRAM_BLOCK, XHI_FAR_BRAM_INT_BLOCK)
* @param    HClkRow - selects the HClk Row
* @param    MajorFrame - selects the column
* @param    MinorFrame - selects frame inside column
*
* @return   XST_SUCCESS, XST_BUFFER_TOO_SMALL or XST_INVALID_PARAM.
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_DeviceReadFrameV4(XHwIcap *InstancePtr, Xint32 Top,
                                Xint32 Block, Xint32 HClkRow,
                                Xint32 MajorFrame, Xint32 MinorFrame)
{

     Xint32 Packet;
     Xint32 Data;
     Xint32 TotalWords;
     XStatus Status;

    /* Make sure we aren't trying to read more than what we have room
     * for. */
    if (InstancePtr->BytesPerFrame >
            (XHI_MAX_BUFFER_BYTES-XHI_HEADER_BUFFER_BYTES))
    {
        return XST_BUFFER_TOO_SMALL;
    }

    /* DUMMY and SYNC */
    XHwIcap_StorageBufferWrite(InstancePtr, 0, XHI_DUMMY_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 1, XHI_SYNC_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 2, XHI_NOOP_PACKET);  /* flush */
    XHwIcap_StorageBufferWrite(InstancePtr, 3, XHI_NOOP_PACKET);  /* flush */

    /* Reset CRC */
    Packet = XHwIcap_Type1Write(XHI_CMD) | 1;
    XHwIcap_StorageBufferWrite(InstancePtr, 4, Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 5, XHI_CMD_RCRC);
    XHwIcap_StorageBufferWrite(InstancePtr, 6, XHI_NOOP_PACKET);  /* flush */
    XHwIcap_StorageBufferWrite(InstancePtr, 7, XHI_NOOP_PACKET);  /* flush */

    /* Setup CMD register to read configuration */
    Packet = XHwIcap_Type1Write(XHI_CMD) | 1;
    XHwIcap_StorageBufferWrite(InstancePtr, 8, Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 9, XHI_CMD_RCFG);
    XHwIcap_StorageBufferWrite(InstancePtr, 10, XHI_NOOP_PACKET);  /* flush */
    XHwIcap_StorageBufferWrite(InstancePtr, 11, XHI_NOOP_PACKET);  /* flush */
    XHwIcap_StorageBufferWrite(InstancePtr, 12, XHI_NOOP_PACKET);  /* flush */

    /* Setup FAR register. */
    Packet = XHwIcap_Type1Write(XHI_FAR) | 1;
    Data = XHwIcap_SetupFarV4(Top, Block, HClkRow,  MajorFrame, MinorFrame);
    XHwIcap_StorageBufferWrite(InstancePtr, 13, Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 14, Data);

    /* Setup read data packet header. */
    /* The frame will be preceeded by a dummy frame, and we need to read one
       extra word - see Configuration Guide Chapter 8 */
    TotalWords = (InstancePtr->WordsPerFrame << 1) + 1;

    /* Create Type one packet */
    Packet = XHwIcap_Type1Read(XHI_FDRO) | TotalWords;
    XHwIcap_StorageBufferWrite(InstancePtr, 15, Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 16, XHI_NOOP_PACKET);  /* flush */
    XHwIcap_StorageBufferWrite(InstancePtr, 17, XHI_NOOP_PACKET);  /* flush */

    /* Write To ICAP. */
    Status = XHwIcap_DeviceWrite(InstancePtr, 0, 18);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }


    /* Read pad frame (skip header). */
/*
    Status = XHwIcap_DeviceRead(InstancePtr, XHI_HEADER_BUFFER_WORDS,
                                InstancePtr->WordsPerFrame);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

 */

    /* In previous versions we could read the pad frame and the real frame
       in two steps. However the behaviour of the opb_hwicap peripheral
       has changed, such that the first byte out of the ICAP port is
       always ignored. If we perform a read in two steps we will lose a
       byte in the middle - so we must read in one go.
    */

    /* Read data on top of pad frame (skip header). */
    Status = XHwIcap_DeviceRead(InstancePtr, XHI_HEADER_BUFFER_WORDS,
           TotalWords);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

    /* send DESYNC command */
    Status = XHwIcap_CommandDesync(InstancePtr);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

   return XST_SUCCESS;
};
#endif

