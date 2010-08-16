/* $Id: xps2_options.c,v 1.1 2006/02/16 23:45:09 moleres Exp $ */
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
* @file xps2_options.c
*
* The implementation of the options functions for the PS/2 driver.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ch   06/24/02 First release.
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xps2.h"
#include "xio.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

/****************************************************************************/
/**
*
* This function returns the last errors that have occurred in the specified
* PS/2 port. It also clears the errors such that they cannot be retrieved again.
* The errors include parity error, receive overrun error, framing error, and
* break detection.
*
* The last errors is an accumulation of the errors each time an error is
* discovered in the driver. A status is checked for each received byte and
* this status is accumulated in the last errors.
*
* If this function is called after receiving a buffer of data, it will indicate
* any errors that occurred for the bytes of the buffer. It does not indicate
* which bytes contained errors.
*
* @param    InstancePtr is a pointer to the XPs2 instance to be worked on.
*
* @return
*
* The last errors that occurred. The errors are bit masks that are contained
* in the file xps2.h and named XPS2_ERROR_*.
*
* @note
*
* None.
*
*****************************************************************************/
Xuint8 XPs2_GetLastErrors(XPs2 *InstancePtr)
{
    Xuint8 Temp;

    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);

    Temp = InstancePtr->LastErrors;
    /* 
     * Clear the last errors and return the previous value 
     */
    InstancePtr->LastErrors = 0;

    /* 
     * Only return the bits that are reported errors which include
     * receive overrun, framing, parity and break detection, the last errors
     * variable holds an accumulation of the line status register bits which
     * have been set
     */
    return Temp; /* & XUN_LSR_ERROR_BREAK; */
}

/****************************************************************************/
/**
*
* This function determines if the specified PS/2 port is sending data. If the
* transmitter register is not empty, it is sending data.
*
* @param    InstancePtr is a pointer to the XPs2 instance to be worked on.
*
* @return
*
* A value of XTRUE if the transmitter is sending data, otherwise XFALSE.
*
* @note
*
* None.
*
*****************************************************************************/
Xboolean XPs2_IsSending(XPs2 *InstancePtr)
{
    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);

    /* 
     * If the transmitter is not empty then indicate that the transmitter
     * is still sending some data
     */
    return  XPs2_mIsTransmitFull(InstancePtr->BaseAddress);
}
