#define TESTAPP_GEN

/* $Id: xsysace_selftest_example.c,v 1.1 2006/02/17 21:52:36 moleres Exp $ */
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
*       (c) Copyright 2005 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xsysace_selftest_example.c
*
* This file contains a design example using the SystemACE driver.
*
* @note
*
* None
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- ---------------------------------------------------------
* 1.00a ecm  01/25/05 First release for TestApp integration
* 1.00a sv   06/06/05 Minor changes to comply to Doxygen and coding guidelines
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xparameters.h"
#include "xstatus.h"
#include "xsysace.h"

/************************** Constant Definitions *****************************/

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#ifndef TESTAPP_GEN
#define SYSACE_DEVICE_ID            XPAR_SYSACE_DEVICE_ID
#endif


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

XStatus SysAceSelfTestExample(Xuint16 DeviceId);

/************************** Variable Definitions *****************************/

XSysAce SysAce;                            /* an instance of the device */

/****************************************************************************/
/**
*
* This function is the main function of the Self Test Example.
*
* @param    None
*
* @return   XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note     None
*
*****************************************************************************/
#ifndef TESTAPP_GEN
int main(void)
{
    XStatus Status;

    Status = SysAceSelfTestExample(SYSACE_DEVICE_ID);

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
* An example of using the System ACE high-level driver interface to run
* selftest after initializont the driver
*
* @param    DeviceId is the XPAR_<system_ace>_DEVICE_ID value from
*           xparameters.h
*
* @return   XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note     None.
*
******************************************************************************/
XStatus SysAceSelfTestExample(Xuint16 DeviceId)
{
    XStatus Status;

    /*
     * Initialize the instance. The device defaults to polled mode.
     */
    Status = XSysAce_Initialize(&SysAce, DeviceId);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }


    /*
     * Run the selftest as the example.
     */
    Status = XSysAce_SelfTest(&SysAce);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }

    return XST_SUCCESS;
}

