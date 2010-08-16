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
*       (c) Copyright 2002 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xps2_l.c
*
* This file contains low-level driver functions that can be used to access the
* device.  The user should refer to the hardware device specification for more
* details of the device operation.
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

/***************************** Include Files *********************************/

#include "xps2_l.h"

/************************** Constant Definitions *****************************/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

/****************************************************************************/
/**
*
* This function sends a data byte to PS/2. This function operates in the
* polling mode and blocks until the data has been put into the transmit
* holding register.
*
* @param    BaseAddress contains the base address of the PS/2 port.
* @param    Data contains the data byte to be sent.
*
* @return   None.
*
* @note     None.
*
*****************************************************************************/

void XPs2_SendByte(Xuint32 BaseAddress, Xuint8 Data)
{
    while (XPs2_mIsTransmitFull(BaseAddress))
    {
    }

    XIo_Out8(BaseAddress + XPS2_TX_REG_OFFSET, Data);
}

/****************************************************************************/
/**
*
* This function receives a byte from PS/2. It operates in the polling mode
* and blocks until a byte of data is received.
*
* @param    BaseAddress contains the base address of the PS/2 port.
*
* @return   The data byte received by PS/2.
*
* @note     None.
*
*****************************************************************************/
Xuint8 XPs2_RecvByte(Xuint32 BaseAddress)
{
    while (XPs2_mIsReceiveEmpty(BaseAddress))
    {
    }

    return (Xuint8)XIo_In8(BaseAddress + XPS2_RX_REG_OFFSET);
}
