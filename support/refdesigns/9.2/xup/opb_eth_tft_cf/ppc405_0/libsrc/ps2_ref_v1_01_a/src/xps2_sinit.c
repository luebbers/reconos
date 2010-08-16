/* $Id: xps2_sinit.c,v 1.1 2006/02/16 23:45:09 moleres Exp $ */
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
*       (c) Copyright 2005 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xps2_sinit.c
*
* The implementation of the XPs2 component's static initialzation functionality.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.01a jvb  10/13/05 First release
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xstatus.h"
#include "xparameters.h"
#include "xps2_i.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

/****************************************************************************/
/**
*
* Looks up the device configuration based on the unique device ID. A table
* contains the configuration info for each device in the system.
*
* @param    DeviceId contains the ID of the device to look up the configuration
*           for.
*
* @return
*
* A pointer to the configuration found or XNULL if the specified device ID was
* not found.
*
* @note
*
* None.
*
******************************************************************************/
XPs2_Config *XPs2_LookupConfig(Xuint16 DeviceId)
{
    XPs2_Config *CfgPtr = XNULL;

    int i;

    for (i=0; i < XPAR_XPS2_NUM_INSTANCES; i++)
    {
        if (XPs2_ConfigTable[i].DeviceId == DeviceId)
        {
            CfgPtr = &XPs2_ConfigTable[i];
        }
    }

    return CfgPtr;
}

/****************************************************************************/
/**
*
* Initializes a specific PS/2 instance such that it is ready to be used.
* The default operating mode of the driver is polled mode.
*
* @param    InstancePtr is a pointer to the XPs2 instance to be worked on.
* @param    DeviceId is the unique id of the device controlled by this
*           XPs2 instance. Passing in a device id associates the generic
*           XPs2 instance to a specific device, as chosen by the caller
*           or application developer.
*
* @return
*
* - XST_SUCCESS if initialization was successful
* - XST_DEVICE_NOT_FOUND if the device ID could not be found in the
*           configuration table
*
* @note
*
* None.
*
*****************************************************************************/
XStatus XPs2_Initialize(XPs2 *InstancePtr, Xuint16 DeviceId)
{
    XPs2_Config *ConfigPtr;

    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);

    /*
     * Lookup the device configuration in the temporary CROM table. Use this
     * configuration info down below when initializing this component.
     */
    ConfigPtr = XPs2_LookupConfig(DeviceId);

    if (ConfigPtr == (XPs2_Config *)XNULL)
    {
       return XST_DEVICE_NOT_FOUND;
    }

    return XPs2_CfgInitialize(InstancePtr, ConfigPtr, ConfigPtr->BaseAddress);
}
