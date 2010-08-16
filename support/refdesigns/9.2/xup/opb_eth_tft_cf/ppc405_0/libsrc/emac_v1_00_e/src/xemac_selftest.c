/* $Id: xemac_selftest.c,v 1.1 2004/04/06 16:49:36 robertm Exp $ */
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
* @file xemac_selftest.c
*
* Self-test and diagnostic functions of the XEmac driver.
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
#include "xio.h"
#include "xipif_v1_23_b.h"      /* Uses v1.23b of the IPIF */

/************************** Constant Definitions *****************************/

/*
 * Set some reset state defines for use in the self-test
 */
#define XEM_ECR_RESET_STATE         (XEM_ECR_XMIT_RESET_MASK |       \
                                     XEM_ECR_RECV_RESET_MASK |       \
                                     XEM_ECR_PHY_ENABLE_MASK |       \
                                     XEM_ECR_XMIT_PAD_ENABLE_MASK |  \
                                     XEM_ECR_XMIT_FCS_ENABLE_MASK |  \
                                     XEM_ECR_XMIT_ADDR_INSERT_MASK | \
                                     XEM_ECR_XMIT_ADDR_OVWRT_MASK |  \
                                     XEM_ECR_UNICAST_ENABLE_MASK |   \
                                     XEM_ECR_BROAD_ENABLE_MASK)
#define XEM_IFGP_RESET_STATE        0x82000000UL
#define XEM_SAH_RESET_STATE         0UL
#define XEM_SAL_RESET_STATE         0UL
#define XEM_MGTCR_RESET_STATE       XEM_MGTCR_RW_NOT_MASK
#define XEM_MGTDR_RESET_STATE       0UL

/*
 * Constants used for the loopback test
 */
#define XEM_MAX_FRAME_SIZE_IN_WORDS ((XEM_MAX_FRAME_SIZE / sizeof(Xuint32)) + 1)

#define XEM_LOOP_SEND_FRAME_SIZE    70
#define XEM_LOOP_RECV_FRAME_SIZE    (XEM_LOOP_SEND_FRAME_SIZE + XEM_TRL_SIZE)
#define XEM_LOOP_DATA_SIZE          (XEM_LOOP_SEND_FRAME_SIZE - XEM_HDR_SIZE)


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

static XStatus LoopbackTest(XEmac *InstancePtr);


/************************** Variable Definitions *****************************/

/* Buffer used for loopback */
static Xuint32 SendFrame[XEM_MAX_FRAME_SIZE_IN_WORDS];
static Xuint32 RecvFrame[XEM_MAX_FRAME_SIZE_IN_WORDS];


/*****************************************************************************/
/**
*
* Performs a self-test on the Ethernet device.  The test includes:
*   - Run self-test on DMA channel, FIFO, and IPIF components
*   - Reset the Ethernet device, check its registers for proper reset values,
*     and run an internal loopback test on the device. The internal loopback
*     uses the device in polled mode.
*
* This self-test is destructive. On successful completion, the device is reset
* and returned to its default configuration. The caller is responsible for
* re-configuring the device after the self-test is run, and starting it when
* ready to send and receive frames.
*
* It should be noted that data caching must be disabled when this function is
* called because the DMA self-test uses two local buffers (on the stack) for
* the transfer test.
*
* @param InstancePtr is a pointer to the XEmac instance to be worked on.
*
* @return
*
* <pre>
*   XST_SUCCESS                    Self-test was successful
*   XST_PFIFO_BAD_REG_VALUE        FIFO failed register self-test
*   XST_DMA_TRANSFER_ERROR         DMA failed data transfer self-test
*   XST_DMA_RESET_REGISTER_ERROR   DMA control register value was incorrect
*                                  after a reset
*   XST_REGISTER_ERROR             Ethernet failed register reset test
*   XST_LOOPBACK_ERROR             Internal loopback failed
*   XST_IPIF_REG_WIDTH_ERROR       An invalid register width was passed into
*                                  the function
*   XST_IPIF_RESET_REGISTER_ERROR  The value of a register at reset was invalid
*   XST_IPIF_DEVICE_STATUS_ERROR   A write to the device status register did
*                                  not read back correctly
*   XST_IPIF_DEVICE_ACK_ERROR      A bit in the device status register did not
*                                  reset when acked
*   XST_IPIF_DEVICE_ENABLE_ERROR   The device interrupt enable register was not
*                                  updated correctly by the hardware when other
*                                  registers were written to
*   XST_IPIF_IP_STATUS_ERROR       A write to the IP interrupt status
*                                  register did not read back correctly
*   XST_IPIF_IP_ACK_ERROR          One or more bits in the IP status
*                                  register did not reset when acked
*   XST_IPIF_IP_ENABLE_ERROR       The IP interrupt enable register
*                                  was not updated correctly when other
*                                  registers were written to
* </pre>
*
* @note
*
* This function makes use of options-related functions, and the XEmac_PollSend()
* and XEmac_PollRecv() functions.
* <br><br>
* Because this test uses the PollSend function for its loopback testing, there
* is the possibility that this function will not return if the hardware is
* broken (i.e., it never sets the status bit indicating that transmission is
* done). If this is of concern to the user, the user should provide protection
* from this problem - perhaps by using a different timer thread to monitor the
* self-test thread.
*
******************************************************************************/
XStatus XEmac_SelfTest(XEmac *InstancePtr)
{
    XStatus Result;
    Xuint32 Register;

    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /*
     * Run self-test on the DMA (if configured) and FIFO channels
     */
    if (XEmac_mIsDma(InstancePtr))
    {
        Result = XDmaChannel_SelfTest(&InstancePtr->RecvChannel);
        if (Result != XST_SUCCESS)
        {
            return Result;
        }

        Result = XDmaChannel_SelfTest(&InstancePtr->SendChannel);
        if (Result != XST_SUCCESS)
        {
            return Result;
        }
    }

    Result = XPacketFifoV200a_SelfTest(&InstancePtr->RecvFifo, XPF_V200A_READ_FIFO_TYPE);
    if (Result != XST_SUCCESS)
    {
        return Result;
    }

    Result = XPacketFifoV200a_SelfTest(&InstancePtr->SendFifo, XPF_V200A_WRITE_FIFO_TYPE);
    if (Result != XST_SUCCESS)
    {
        return Result;
    }

    /*
     * Run the IPIF self-test
     */
    Result = XIpIfV123b_SelfTest(InstancePtr->BaseAddress, XEM_IPIF_IP_INTR_COUNT);
    if (Result != XST_SUCCESS)
    {
        return Result;
    }

    /*
     * Reset the Ethernet MAC to leave it in a known good state
     */
    XEmac_Reset(InstancePtr);

    /*
     * All the MAC registers should be in their default state right now. The
     * registers we care about are the non-zero reset values and the
     * station addresses.
     */
    Register = XIo_In32(InstancePtr->BaseAddress + XEM_ECR_OFFSET);
    if (Register != XEM_ECR_RESET_STATE)
    {
        return XST_REGISTER_ERROR;
    }

    Register = XIo_In32(InstancePtr->BaseAddress + XEM_IFGP_OFFSET);
    if (Register != XEM_IFGP_RESET_STATE)
    {
        return XST_REGISTER_ERROR;
    }

    Register = XIo_In32(InstancePtr->BaseAddress + XEM_SAH_OFFSET);
    if (Register != XEM_SAH_RESET_STATE)
    {
        return XST_REGISTER_ERROR;
    }

    Register = XIo_In32(InstancePtr->BaseAddress + XEM_SAL_OFFSET);
    if (Register != XEM_SAL_RESET_STATE)
    {
        return XST_REGISTER_ERROR;
    }

    Register = XIo_In32(InstancePtr->BaseAddress + XEM_MGTCR_OFFSET);
    if (Register != XEM_MGTCR_RESET_STATE)
    {
        return XST_REGISTER_ERROR;
    }

    Register = XIo_In32(InstancePtr->BaseAddress + XEM_MGTDR_OFFSET);
    if (Register != XEM_MGTDR_RESET_STATE)
    {
        return XST_REGISTER_ERROR;
    }

    /*
     * Run an internal loopback test on the MAC.
     */
    Result = LoopbackTest(InstancePtr);
    if (Result != XST_SUCCESS)
    {
        return Result;
    }

    /*
     * Reset the Ethernet MAC to leave it in a known good state
     */
    XEmac_Reset(InstancePtr);

    return XST_SUCCESS;
}

/*****************************************************************************/
/*
*
* Run an internal loopback test on the MAC. This is done in polled mode with
* a small (60-byte) Ethernet frame. The FCS inserted by the hardware adds four
* bytes to make the total size of the frame 64 bytes.
*
* @param InstancePtr is a pointer to the XEmac instance to be worked on.
*
* @return
*
* - XST_SUCCESS if loopback was performed successfully
* - XST_LOOPBACK_ERROR if loopback failed
*
* @note
*
* None.
*
******************************************************************************/
static XStatus LoopbackTest(XEmac *InstancePtr)
{
    Xuint32 RecvFrameLength;
    Xuint8 *FramePtr;
    int Index;
    Xuint32 Options;
    XStatus Result;

    /*
     * Assemble the frame with a destination address (the station address)
     * and a bogus source address (the MAC overwrites it). An Ethernet frame
     * has a 14 byte header that contains a 6-byte destination address
     * followed by a 6-byte source address, followed by a 2-byte type/length
     * field. The frame data follows the header and can be anywhere from
     * 46 bytes to 1500 bytes. Following the data is a 4-byte FCS (CRC), which
     * is currently appended by the MAC.
     */
    FramePtr = (Xuint8 *)SendFrame;
    XEmac_GetMacAddress(InstancePtr, FramePtr);
    FramePtr += XEM_MAC_ADDR_SIZE;  /* get past dest address */
    FramePtr += XEM_MAC_ADDR_SIZE;  /* get past source address (bogus) */

    /* Set up the type/length field to a length of XEM_LOOPBACK_DATA_SIZE */

    *FramePtr++ = 0;
    *FramePtr++ = XEM_LOOP_DATA_SIZE;

    /*
     * Now fill in the data field with known values so we can verify them
     * on receive.
     */
    for (Index = 0; Index < XEM_LOOP_DATA_SIZE; Index++)
    {
        *FramePtr++ = (Xuint8)Index;
    }

    /*
     * Configure the device for loopback and polled mode
     */
    (void)XEmac_Stop(InstancePtr);

    Options = XEmac_GetOptions(InstancePtr);
    Options |= (XEM_POLLED_OPTION | XEM_LOOPBACK_OPTION);
    (void)XEmac_SetOptions(InstancePtr, Options);

    (void)XEmac_Start(InstancePtr);

    /*
     * Now send the frame, then receive it and verify its contents
     */
    Result = XEmac_PollSend(InstancePtr, (Xuint8 *)SendFrame,
                                     XEM_LOOP_SEND_FRAME_SIZE);
    if (Result == XST_SUCCESS)
    {
        RecvFrameLength = XEM_MAX_FRAME_SIZE;

        /*
         * Receive the frame. We assume the frame is already in the
         * receive FIFO by this time. Otherwise we would need to loop
         * on the PollRecv call since it is non-blocking.
         */
        Result = XEmac_PollRecv(InstancePtr, (Xuint8 *)RecvFrame,
                                     &RecvFrameLength);
        if (Result == XST_SUCCESS)
        {
            /* Verify the length */
            if (RecvFrameLength != XEM_LOOP_RECV_FRAME_SIZE)
            {
                return XST_LOOPBACK_ERROR;
            }

            /* Verify the frame contents */
            FramePtr = (Xuint8 *)RecvFrame;
            FramePtr += XEM_HDR_SIZE;    /* get past the header */
            for (Index = 0; Index < XEM_LOOP_DATA_SIZE; Index++)
            {
                if (*FramePtr++ != (Xuint8)Index)
                {
                    return XST_LOOPBACK_ERROR;
                }
            }
        }
    }

    /*
     * Test is finished, return the result (do not bother restoring the
     * device state to what it was before the test started, since this is
     * called from self-test anyway, and a reset occurs at the end.
     */
    return Result;
}
