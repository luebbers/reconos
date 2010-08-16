#define TESTAPP_GEN

/* $Id: xemac_intr_fifo_example.c,v 1.7 2006/06/26 22:38:24 somn Exp $ */
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
*       (c) Copyright 2004-2005 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
* @file xemac_intr_fifo_example.c
*
* This file can be used as a standalone example of how to use the XEmac driver
* directly or by the TestAppGen utility to include a test for Emac interrupt in
* direct FIFO mode.
*
* The example here shows using the driver/device in interrupt mode with direct
* FIFO I/O.  This mode is typically not used when the device is configured with
* DMA. Standalone, this example works with a PPC405 processor. Refer the example
* of Interrupt Controller (XIntc) for using an Interrupt Controller with
* Microblaze processor.
*
* @note
*
* None
*
* <pre>
*
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- ---------------------------------------------------------
* 1.00a rbm  11/23/04 Initial release
* 1.00a sv   06/09/05 Minor changes to comply to Doxygen and coding guidelines
* 1.01a sn   05/09/06 Modified to be used by TestAppGen to include test for
*                     interrupts.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xparameters.h"
#include "xemac.h"
#include "xintc.h"
#ifndef __MICROBLAZE__
#include "xexception_l.h"
#endif
/************************** Constant Definitions *****************************/

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#ifndef TESTAPP_GEN
#define EMAC_DEVICE_ID          XPAR_ETHERNET_MAC_DEVICE_ID
#define INTC_DEVICE_ID          XPAR_OPB_INTC_0_DEVICE_ID
#define EMAC_IRPT_INTR          XPAR_OPB_INTC_0_ETHERNET_MAC_IP2INTC_IRPT_INTR
#endif

#define XEM_MAX_FRAME_SIZE_IN_WORDS ((XEM_MAX_FRAME_SIZE / sizeof(Xuint32)) + 1)

#define DEFAULT_OPTIONS      (XEM_UNICAST_OPTION | XEM_INSERT_PAD_OPTION | \
                              XEM_INSERT_FCS_OPTION | XEM_INSERT_ADDR_OPTION | \
                              XEM_OVWRT_ADDR_OPTION)

/*
 * The size of the Test Frame in Bytes
 */
#define EMAC_TEST_FRAME_SIZE       200

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

XStatus EmacIntrExample(XIntc *IntcInstancePtr,
                        XEmac *EmacInstancePtr,
                        Xuint16 EmacDeviceId,
                        Xuint16 EmacIntrId);

static XStatus LoopbackFrame(XEmac *EmacInstancePtr, Xuint32 PayloadSize);

static XStatus SendFrame(XEmac *EmacInstancePtr, Xuint32 PayloadSize,
                         Xuint8 *DestAddress);

static void FifoRecvHandler(void *CallBackRef);

static void FifoSendHandler(void *CallBackRef);

static void ErrorHandler(void *CallBackRef, XStatus Code);

static XStatus EmacSetupIntrSystem(XIntc *IntcInstancePtr,
                                   XEmac *EmacInstancePtr,
                                   Xuint16 EmacDeviceId,
                                   Xuint16 EmacIntrId);

static void EmacDisableIntrSystem(XIntc *IntcInstancePtr, Xuint16 EmacIntrId);

/************************** Variable Definitions *****************************/

/*
 * Set up valid local MAC address. The loopback test will use the
 * LocalAddress both as source and destination.
 */
static Xuint8 LocalAddress[XEM_MAC_ADDR_SIZE] =
{
    0x06, 0x05, 0x04, 0x03, 0x02, 0x01
};


static XEmac Emac;                  /*  An instance of the XEmac driver */
static XIntc InterruptController;   /*  An instance of the XIntc driver */
/*
 * These buffers need to be 32-bit aligned
 */
static Xuint32 TxFrame[XEM_MAX_FRAME_SIZE_IN_WORDS];
static Xuint32 RecvBuffer[XEM_MAX_FRAME_SIZE_IN_WORDS];

/*
 * Shared variables used to test the callbacks with the send/receive
 */
static int SentPayloadSize;             /* Outstanding frame length */
static XStatus LoopbackError;           /* Asynchronous error occurred */
volatile static Xboolean RecvDone;      /* Received a frame */
volatile static Xboolean SendDone;      /* Sent a frame */


/*****************************************************************************/
/**
* Main function to call the Emac Interrupt-FIFO example.
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
     * Run the Emac Interrupt-FIFO example , specify the Device ID that is
     * generated in xparameters.h
     */
    
    Status = EmacIntrExample(&InterruptController,
                             &Emac,
                             EMAC_DEVICE_ID,
                             EMAC_IRPT_INTR);
    
    
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
    
    return XST_SUCCESS;
    
}
#endif //TESTAPP_GEN

/******************************************************************************/
/**
*
* The main entry point for showing the XEmac driver in interrupt mode with
* FIFOs. The example configures the device for internal loopback mode, then
* sends an Ethernet frame and receives the same Ethernet frame.
*
* @param    IntcInstancePtr is the pointer to the instance of the INTC
*           component.
* @param    EmacInstancePtr is the pointer to the instance of the EMAC
*           component.
* @param    EmacDeviceId is the XPAR_<emac_instance>_DEVICE_ID value from
*           xparameters.h for EMAC
* @param    EmacIntrId is XPAR_<INTC_instance>_<EMAC_instance>_IP2INTC_IRPT_INTR 
*           value from xparameters.h   
* @return   XST_SUCCESS if successful, otherwise XST_FAILURE
*
* @note     None.
*
******************************************************************************/

XStatus EmacIntrExample(XIntc *IntcInstancePtr, 
                        XEmac *EmacInstancePtr,
                        Xuint16 EmacDeviceId,
                        Xuint16 EmacIntrId)
{

    XStatus Status;
    Xuint32 Options;
    XEmac_Config *ConfigPtr;

    /*
     * We change the configuration of the device to indicate no DMA just in
     * case it was built with DMA. In order for this example to work, you
     * either need to do this or, better yet, build the hardware without DMA.
     */
    ConfigPtr = XEmac_LookupConfig(EmacDeviceId);
    ConfigPtr->IpIfDmaConfig = XEM_CFG_NO_DMA;

    /*
     * Initialize the XEmac component. The device ID chosen should be
     * configured without DMA (see the xemac_g.c file)
     */
    Status = XEmac_Initialize(EmacInstancePtr, EmacDeviceId);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * We can check to be sure the device is confgured without DMA before
     * going on with the example.
     */
    if (XEmac_mIsDma(EmacInstancePtr))
    {
        /*
         * OOPS! it has DMA
         */
        return XST_FAILURE;
    }

    /*
     * Run self-test on the device, which verifies basic sanity of the
     * device and the driver.
     */
    Status = XEmac_SelfTest(EmacInstancePtr);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * First configure the device into loopback mode.  We also configure it
     * for unicast and broadcast addressing.
     */
    Options = (DEFAULT_OPTIONS | XEM_BROADCAST_OPTION | XEM_LOOPBACK_OPTION);
    Status = XEmac_SetOptions(EmacInstancePtr, Options);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * Set the MAC address.
     */
    Status = XEmac_SetMacAddress(EmacInstancePtr, LocalAddress);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }


    /*
     * Connect to the interrupt controller and enable interrupts
     */
    Status = EmacSetupIntrSystem(IntcInstancePtr,
                                 EmacInstancePtr,
                                 EmacDeviceId,
                                 EmacIntrId);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * Set the FIFO callbacks and error handler. These callbacks are invoked
     * by the driver during interrupt processing.
     */
    XEmac_SetFifoSendHandler(EmacInstancePtr, EmacInstancePtr, FifoSendHandler);
    XEmac_SetFifoRecvHandler(EmacInstancePtr, EmacInstancePtr, FifoRecvHandler);
    XEmac_SetErrorHandler(EmacInstancePtr, EmacInstancePtr, ErrorHandler);


    /*
     * Start the device, which enables the transmitter and receiver
     */
    Status = XEmac_Start(EmacInstancePtr);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    /*
     * We clear the driver statistics so we can look at them later
     */
    XEmac_ClearStats(EmacInstancePtr);

    /*
     * Loopback a 200-byte frame (214 with the Ethernet header).
     */
    Status = LoopbackFrame(EmacInstancePtr, EMAC_TEST_FRAME_SIZE);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

	
    /* 
     * Disable the EMAC interrupt 
     */
    EmacDisableIntrSystem(IntcInstancePtr, EmacIntrId);

    return XST_SUCCESS;
}


/*****************************************************************************/
/**
*
* This function loopbacks a frame of given size. This function assumes interrupt
* mode and loopback mode and sends the frame. The FifoRecvHandler is expected to
* handle the received frame.
*
* @param    EmacInstancePtr is the pointer to the instance of the EMAC
*           component.
* @param    PayloadSize is the size of the frame to create. The size only
*           reflects the payload size, it does not include the Ethernet header
*           size (14 bytes) nor the Ethernet CRC size (4 bytes).
*
* @return   XST_SUCCESS if successful, otherwise XST_FAILURE
*
* @note     None.
*
******************************************************************************/
static XStatus LoopbackFrame(XEmac *EmacInstancePtr, Xuint32 PayloadSize)
{
    XStatus Status;

    SendDone = XFALSE;
    RecvDone = XFALSE;
    LoopbackError = XST_SUCCESS;

    SentPayloadSize = PayloadSize;

    Status = SendFrame(EmacInstancePtr, PayloadSize, LocalAddress);
    if (Status == XST_SUCCESS)
    {
        /*
         * Wait here until both send and receive have been completed
         */
        while (!SendDone || !RecvDone);

        /*
         * Check for errors found in the callbacks
         */
        if (LoopbackError != XST_SUCCESS)
        {
            return XST_FAILURE;
        }

        return XST_SUCCESS;
    }

    return XST_FAILURE;
}

/*****************************************************************************/
/**
* This functions sends an Ethernet frame of given size
*
* @param    EmacInstancePtr is the pointer to the instance of the EMAC
*           component.
* @param    PayloadSize is the size of the frame to create. The size only
*           reflects the payload size, it does not include the Ethernet header
*           size (14 bytes) nor the Ethernet CRC size (4 bytes).
* @param    DestAddress is the Destination Address
*
* @return   XST_SUCCESS if successful, else XST_FAILURE
*
* @note     None.
*
******************************************************************************/
static XStatus SendFrame(XEmac *EmacInstancePtr, Xuint32 PayloadSize,
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
     * Now send the frame (payload and header)
     */
    return XEmac_FifoSend(EmacInstancePtr, (Xuint8 *)TxFrame,
                          PayloadSize + XEM_HDR_SIZE);
}


/*****************************************************************************/
/**
* This is the Callback function (called from driver) to handle frames received
* in direct memory-mapped I/O mode.  This function is called once per frame
* received. It notifies me that there is data to be retrieved from the driver.
* The driver's receive function is called to get the data.
*
* @param    CallBackRef is the callback reference passed from the driver, which
*           in our case is a pointer to a DriverInfo structure.
*
* @return   None.
*
* @note     This function is called by the driver within interrupt context.
*
******************************************************************************/
static void FifoRecvHandler(void *CallBackRef)
{
    XEmac *EmacPtr = (XEmac *)CallBackRef;
    Xuint32 FrameLen;
    XStatus Status;
    int Index;
    Xuint8 *FramePtr;

    /*
     * Retrieve the frame from the EMAC
     */
    FrameLen = XEM_MAX_FRAME_SIZE;
    Status = XEmac_FifoRecv(EmacPtr, (Xuint8 *)RecvBuffer, &FrameLen);
    if (Status != XST_SUCCESS)
    {
        LoopbackError = Status;
        RecvDone = XTRUE;
        return;
    }

    /*
     * Verify the frame is the correct length. SentPayloadSize is a shared
     * variable.
     */
    if (FrameLen != (SentPayloadSize + XEM_HDR_SIZE + XEM_TRL_SIZE))
    {
        LoopbackError = XST_LOOPBACK_ERROR;
        RecvDone = XTRUE;
        return;
    }

    /*
     * Verify the frame contents
     */
    FramePtr = (Xuint8 *)RecvBuffer;
    FramePtr += XEM_HDR_SIZE;    /* get past the header */
    for (Index = 0; Index < SentPayloadSize; Index++)
    {
        if (*FramePtr++ != (Xuint8)Index)
        {
            LoopbackError = XST_LOOPBACK_ERROR;
            break;
        }
    }

    RecvDone = XTRUE;
}


/*****************************************************************************/
/**
* This is the Callback function (called from driver) to handle confirmation of
* transmit events when in direct memory-mapped I/O mode.
*
* @param    CallBackRef is the callback reference passed from the driver, which
*           in our case is a pointer the driver instance.
*
* @return   None.
*
* @note     None.
*
******************************************************************************/
static void FifoSendHandler(void *CallBackRef)
{
    XEmac *EmacPtr = (XEmac *)CallBackRef;
    XEmac_Stats Stats;

    /*
     * Check stats for transmission errors (overrun or underrun errors are
     * caught by the asynchronous error handler).
     */
    XEmac_GetStats(EmacPtr, &Stats);
    if (Stats.XmitLateCollisionErrors || Stats.XmitExcessDeferral)
    {
        LoopbackError = XST_LOOPBACK_ERROR;
    }

    SendDone = XTRUE;
}

/*****************************************************************************/
/**
*
* This function is the Callback function (called from driver) to handle
* asynchronous errors. These errors are usually bad and require a reset of the
* device.  Here is an example of how to recover (albeit data will be lost during
* the reset)
*
* @param    CallBackRef is the callback reference passed from the driver, which
*           in our case is a pointer the driver instance.
* @param    Code is the Error Status
*
* @return   None.
*
* @note     None.
*
******************************************************************************/
static void ErrorHandler(void *CallBackRef, XStatus Code)
{
    XEmac *EmacPtr = (XEmac *)CallBackRef;

    LoopbackError = Code;   /* Set the shared variable */

    /*
     * Most if not all asynchronous errors returned by the XEmac driver are
     * serious.  The usual remedy is to reset the device.  The user will need
     * to re-configure the driver/device after the reset, so if you don't know
     * how it is configured, be sure to retrieve its options and configuration
     * (e.g., using the XEmac_Get... functions) before the reset.
     */
    if (Code == XST_RESET_ERROR)
    {
        /*
         * May want to set a breakpoint here during debugging
         */
        XEmac_Reset(EmacPtr);

        (void)XEmac_SetMacAddress(EmacPtr, LocalAddress);
        (void)XEmac_SetOptions(EmacPtr, DEFAULT_OPTIONS);

        (void)XEmac_Start(EmacPtr);
    }
}

/*****************************************************************************/
/**
*
* This function setups the interrupt system so interrupts can occur for the
* EMAC.  This function is application-specific since the actual system may or
* may not have an interrupt controller.  The EMAC could be directly connected
* to a processor without an interrupt controller.  The user should modify this
* function to fit the application.
*
* @param    IntcInstancePtr is the pointer to the instance of the INTC
*           component.
* @param    EmacInstancePtr is the pointer to the instance of the EMAC
*           component which is going to be connected to the interrupt
*           controller.
* @param    EmacDeviceId is the XPAR_<emac_instance>_DEVICE_ID value from
*           xparameters.h for EMAC
* @param    EmacIntrId is XPAR_<INTC_instance>_<EMAC_instance>_IP2INTC_IRPT_INTR 
*           value from xparameters.h
*
* @return   XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note     None
*
******************************************************************************/

static XStatus EmacSetupIntrSystem(XIntc *IntcInstancePtr,
                                   XEmac *EmacInstancePtr,
                                   Xuint16 EmacDeviceId,
                                   Xuint16 EmacIntrId)
{
    XStatus Status;

#ifndef TESTAPP_GEN
    /*
     * Initialize the interrupt controller driver so that it is ready to use.
     */
    Status = XIntc_Initialize(IntcInstancePtr, INTC_DEVICE_ID);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
#endif
    /*
     * Connect the device driver handler that will be called when an interrupt
     * for the device occurs, the device driver handler performs the specific
     * interrupt processing for the device
     */
    Status = XIntc_Connect(IntcInstancePtr,
                           EmacIntrId,
                           (XInterruptHandler)XEmac_IntrHandlerFifo,
                           EmacInstancePtr);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

#ifndef TESTAPP_GEN
    /*
     * Start the interrupt controller so interrupts are enabled for all
     * devices that cause interrupts. Specify real mode so that the EMAC
     * can cause interrupts through the interrupt controller.
     */
    Status = XIntc_Start(IntcInstancePtr, XIN_REAL_MODE);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
#endif
    /*
     * Enable the interrupt for the EMAC
     */
    XIntc_Enable(IntcInstancePtr, EmacIntrId);

#ifndef TESTAPP_GEN
    /*
     * Initialize the PPC405 exception table
     */
    XExc_Init();

    /*
     * Register the interrupt controller handler with the exception table
     */
    XExc_RegisterHandler(XEXC_ID_NON_CRITICAL_INT,
                         (XExceptionHandler)XIntc_InterruptHandler,
                         IntcInstancePtr);

    /*
     * Enable non-critical exceptions
     */
    XExc_mEnableExceptions(XEXC_NON_CRITICAL);
#endif

    return XST_SUCCESS;
}


/*****************************************************************************/
/**
*
* This function disables the interrupts that occur for the EMAC.  
*
* @param    IntrInstancePtr is the pointer to the instance of the INTC
*           component.
* @param    IntrMask is the interrupt vector for EMAC Interrupt.
*
* @return   None
*
* @note     None
*
******************************************************************************/
static void EmacDisableIntrSystem(XIntc *IntrInstancePtr, Xuint16 IntrMask)
{
    
    /*
     * Disconnect and disable the interrupt for the EMAC
     */
    XIntc_Disconnect(IntrInstancePtr, IntrMask);

}


