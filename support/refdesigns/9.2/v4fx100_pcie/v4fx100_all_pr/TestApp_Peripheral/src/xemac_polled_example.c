#define TESTAPP_GEN

/* $Id: xemac_polled_example.c,v 1.3 2005/07/25 15:18:06 svemula Exp $ */
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
*       (c) Copyright 2002-2005 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xemac_polled_example.c
*
* Contains an example of how to use the XEmac driver directly. This example
* shows the usage of driver/device in a polled mode.
*
* @note
*
* None.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- ----------------------------------------------------------
* 1.00a rpm  12/22/04 Created
* 1.00a sv   06/03/05 Minor changes to comply to Doxygen and coding guidelines.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xparameters.h"
#include "xemac.h"


/************************** Constant Definitions *****************************/

#define XEM_MAX_FRAME_SIZE_IN_WORDS ((XEM_MAX_FRAME_SIZE / sizeof(Xuint32)) + 1)

#define EMAC_TEST_FRAME_SIZE        200

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define EMAC_DEVICE_ID      XPAR_ETHERNET_MAC_DEVICE_ID

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

XStatus EmacPolledExample(Xuint16 DeviceId);

static XStatus LoopbackFrame(XEmac *InstancePtr, Xuint32 PayloadSize);

static XStatus SendFrame(XEmac *InstancePtr, Xuint32 PayloadSize,
                         Xuint8 *DestAddress);

static XStatus RecvFrame(XEmac *InstancePtr, Xuint32 PayloadSize);

/************************** Variable Definitions *****************************/

/*
 * The loopback test will use the LocalAddress both as source and destination
 * MAC address.
 */
static Xuint8 LocalAddress[XEM_MAC_ADDR_SIZE] =
{
    0x06, 0x05, 0x04, 0x03, 0x02, 0x01
};

/*
 * Frame buffers
 */
static Xuint32 TxFrame[XEM_MAX_FRAME_SIZE_IN_WORDS];    /* word aligned */
static Xuint32 RxFrame[XEM_MAX_FRAME_SIZE_IN_WORDS];    /* word aligned */


static XEmac Emac;             /* Driver instance of the EMAC device */

/*****************************************************************************/
/**
* Main function to call the example. This function is not included if the
* example is generated from the TestAppGen test tool.
*
* @param    None
*
* @return   XST_SUCCESS if successful, XST_FAILURE if unsuccessful
*
* @note     None
*
******************************************************************************/
#ifndef TESTAPP_GEN
int main(void)
{
    XStatus Status;


    /*
     * Run the Emac polled example , spcify the Device Id that
     * is generated in xparameters.h
     */
    Status = EmacPolledExample(EMAC_DEVICE_ID);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    return XST_SUCCESS;

}
#endif

/*****************************************************************************/
/**
*
* The entry point for showing the XEmac driver in polled mode. The example
* configures the device for internal loopback mode, then sends an Ethernet
* frame and receives the same Ethernet frame.
*
* @param    DeviceId is the XPAR_<emac_instance>_DEVICE_ID value from
*           xparameters.h
*
* @return   XST_SUCCESS if successful, XST_FAILURE if unsuccessful
*
* @note     None.
*
******************************************************************************/
XStatus EmacPolledExample(Xuint16 DeviceId)
{
    XEmac *InstancePtr = &Emac;
    XStatus Status;
    Xuint32 Options;

    /*
     * Initialize the XEmac component. The device ID chosen should be
     * configured without DMA (see the xemac_g.c file)
     */
    Status = XEmac_Initialize(InstancePtr, DeviceId);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * Run self-test on the device, which verifies basic sanity of the
     * device and the driver.
     */
    Status = XEmac_SelfTest(InstancePtr);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * First configure the device into loopback mode.  We also configure it
     * for unicast and broadcast addressing.
     */
    Options = XEmac_GetOptions(InstancePtr);
    Options |= (XEM_POLLED_OPTION | XEM_LOOPBACK_OPTION);

    Status = XEmac_SetOptions(InstancePtr, Options);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * Set the MAC Addrees
     */
    Status = XEmac_SetMacAddress(InstancePtr, LocalAddress);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * Start the device, which enables the transmitter and receiver
     */
    Status = XEmac_Start(InstancePtr);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * We clear the driver statistics so we can look at them later
     */
    XEmac_ClearStats(InstancePtr);


    /*
     * Loopback a 200-byte frame (218 with the Ethernet header/trailer)
     */
    Status = LoopbackFrame(InstancePtr, EMAC_TEST_FRAME_SIZE);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * Stop the device, which disables the transmitter and receiver
     */
    Status = XEmac_Stop(InstancePtr);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}


/*****************************************************************************/
/**
*
* Loopback a frame of a given size. This function assumes polled mode and
* loopback mode, sends the frame, then receives the frame and verifies its
* contents.
*
* @param    InstancePtr is a pointer to the driver instance
* @param    PayloadSize is the size of the frame to create. The size only
*           reflects the payload size, it does not include the Ethernet header
*           size (14 bytes) nor the Ethernet CRC size (4 bytes).
*
* @return   XST_SUCCESS if successful, otherwise XST_FAILURE
*
* @note     None.
*
******************************************************************************/
static XStatus LoopbackFrame(XEmac *InstancePtr, Xuint32 PayloadSize)
{
    XStatus Status;

    /*
     *  Send the frame
     */
    Status = SendFrame(InstancePtr, PayloadSize, LocalAddress);
    if (Status == XST_SUCCESS)
    {
        /*
         *  Receive the frame
         */
        Status = RecvFrame(InstancePtr, PayloadSize);
    }

    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}

/*****************************************************************************/
/**
* Send a frame of given size. This function assumes polled mode and sends the
* frame. The caller must be aware of FIFO depths when using this function.
*
* @param    InstancePtr is a pointer to the driver instance
* @param    PayloadSize is the size of the frame to create. The size only
*           reflects the payload size, it does not include the Ethernet header
*           size (14 bytes) nor the Ethernet CRC size (4 bytes).
* @param    DestAddress is the destination MAC address for the frame
*
* @return   XST_SUCCESS if successful, else a driver-specific return code
*
* @note     None.
*
******************************************************************************/
static XStatus SendFrame(XEmac *InstancePtr, Xuint32 PayloadSize,
                         Xuint8 *DestAddress)
{
    Xuint8 *FramePtr;
    Xuint8 *AddrPtr = DestAddress;
    int Index;

    /*
     * Assemble the frame with a destination address and a bogus source address
     * (the MAC overwrites it by default)
     */
    FramePtr = (Xuint8 *)TxFrame;

    *FramePtr++ = *AddrPtr++;
    *FramePtr++ = *AddrPtr++;
    *FramePtr++ = *AddrPtr++;
    *FramePtr++ = *AddrPtr++;
    *FramePtr++ = *AddrPtr++;
    *FramePtr++ = *AddrPtr++;

    FramePtr += XEM_MAC_ADDR_SIZE;  /* get past source address (bogus) */

    /*
     * Set up the type/length field - be sure its in network order
     */
    *((Xuint16 *)FramePtr) = PayloadSize;
    FramePtr++;
    FramePtr++;

    /*
     * Now fill in the data field with known values so we can verify them
     * on receive.
     */
    for (Index = 0; Index < PayloadSize; Index++)
    {
        *FramePtr++ = (Xuint8)Index;
    }

    /*
     * Now send the frame, then receive it and verify its contents
     */
    return XEmac_PollSend(InstancePtr, (Xuint8 *)TxFrame,
                          PayloadSize + XEM_HDR_SIZE);
}


/*****************************************************************************/
/**
* Receive a frame of given size. This function assumes polled mode, receives
* the frame and verifies its contents.
*
* @param    InstancePtr is a pointer to the driver instance
* @param    PayloadSize is the size of the frame to create. The size only
*           reflects the payload size, it does not include the Ethernet header
*           size (14 bytes) nor the Ethernet CRC size (4 bytes).
*
* @return   XST_SUCCESS if successful, otherwise XST_FAILURE
*
* @note     None.
*
******************************************************************************/
static XStatus RecvFrame(XEmac *InstancePtr, Xuint32 PayloadSize)
{
    Xuint8 *FramePtr;
    XStatus Status;
    Xuint32 RecvFrameLength;
    int Index;

    /*
     * This assumes MAC does not strip padding or crc
     */
    RecvFrameLength = XEM_MAX_FRAME_SIZE;

    Status = XEmac_PollRecv(InstancePtr, (Xuint8 *)RxFrame, &RecvFrameLength);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }


    /*
     * Verify length, which should be the payload plus overhead
     */
    if (RecvFrameLength != (PayloadSize + XEM_HDR_SIZE + XEM_TRL_SIZE))
    {
        return XST_FAILURE;
    }

    /*
     * Verify the frame contents
     */
    FramePtr = (Xuint8 *)RxFrame;
    FramePtr += XEM_HDR_SIZE;    /* get past the header */
    for (Index = 0; Index < PayloadSize; Index++)
    {
        if (*FramePtr++ != (Xuint8)Index)
        {
            return XST_FAILURE;
        }
    }


    return XST_SUCCESS;
}

