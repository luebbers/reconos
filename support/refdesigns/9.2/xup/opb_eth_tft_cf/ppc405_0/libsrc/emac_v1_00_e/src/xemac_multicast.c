/* $Id: xemac_multicast.c,v 1.1 2004/04/06 16:49:36 robertm Exp $ */
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
* @file xemac_multicast.c
*
* Contains functions to configure multicast addressing in the Ethernet MAC.
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

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/


/************************** Variable Definitions *****************************/


/*****************************************************************************/
/**
*
* Add a multicast address to the list of multicast addresses from which the
* EMAC accepts frames. The EMAC uses a hash table for multicast address
* filtering. Obviously, the more multicast addresses that are added reduces
* the accuracy of the address filtering. The upper layer software that
* receives multicast frames should perform additional filtering when accuracy
* must be guaranteed. There is no way to retrieve a multicast address or the
* multicast address list once added. The upper layer software should maintain
* its own list of multicast addresses. The device must be stopped before
* calling this function.
*
* @param InstancePtr is a pointer to the XEmac instance to be worked on.
* @param AddressPtr is a pointer to a 6-byte multicast address.
*
* @return
*
* - XST_SUCCESS if the multicast address was added successfully
* - XST_NO_FEATURE if the device is not configured with multicast support
* - XST_DEVICE_IS_STARTED if the device has not yet been stopped
*
* @note
*
* Not currently supported.
*
******************************************************************************/
XStatus XEmac_MulticastAdd(XEmac *InstancePtr, Xuint8 *AddressPtr)
{
    Xuint8 CurrentMacAddr[XEM_MAC_ADDR_SIZE];
    Xuint32 MultiAddr = 0;
    Xuint32 ControlReg;

    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(AddressPtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /*
     * Make sure the device has multicast hash table support
     */
    if (!InstancePtr->HasMulticastHash)
    {
        return XST_NO_FEATURE;
    }

    /*
     * The device must be stopped before adding a multicast address
     */
    if (InstancePtr->IsStarted == XCOMPONENT_IS_STARTED)
    {
        return XST_DEVICE_IS_STARTED;
    }

    /*
     * Save the current MAC address and restore it after the multicast
     * address is added.
     */
    XEmac_GetMacAddress(InstancePtr, CurrentMacAddr);

    /*
     * Set the device station address high and low registers
     */
    MultiAddr = (AddressPtr[0] << 8) | AddressPtr[1];
    XIo_Out32(InstancePtr->BaseAddress + XEM_SAH_OFFSET, MultiAddr);

    MultiAddr = (AddressPtr[2] << 24) | (AddressPtr[3] << 16) |
              (AddressPtr[4] << 8) | AddressPtr[5];
    XIo_Out32(InstancePtr->BaseAddress + XEM_SAL_OFFSET, MultiAddr);

    /*
     * Now set the control register to add a multicast address
     * TODO: new r/m/w here
     * TODO: does this self-clear?
     */
    ControlReg = XIo_In32(InstancePtr->BaseAddress + XEM_ECR_OFFSET);
    XIo_Out32(InstancePtr->BaseAddress + XEM_ECR_OFFSET,
              ControlReg | XEM_ECR_ADD_HASH_ADDR_MASK);

    /*
     * Restore the saved MAC address
     */
    (void)XEmac_SetMacAddress(InstancePtr, CurrentMacAddr);

    return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* Clear the hash table used by the EMAC for multicast address filtering. The
* entire hash table is cleared, meaning no multicast frames will be accepted
* after this function is called. If this function is used to delete one or
* more multicast addresses, the upper layer software is responsible for adding
* back those addresses still needed for address filtering. The device must be
* stopped before calling this function.
*
* @param InstancePtr is a pointer to the XEmac instance to be worked on.
*
* @return
*
* - XST_SUCCESS if the multicast address list was cleared
* - XST_NO_FEATURE if the device is not configured with multicast support
* - XST_DEVICE_IS_STARTED if the device has not yet been stopped
*
* @note
*
* Not currently supported.
*
******************************************************************************/
XStatus XEmac_MulticastClear(XEmac *InstancePtr)
{
    Xuint32 ControlReg;

    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /*
     * Make sure the device has multicast hash table support
     */
    if (!InstancePtr->HasMulticastHash)
    {
        return XST_NO_FEATURE;
    }

    /*
     * The device must be stopped before clearing the multicast hash table
     */
    if (InstancePtr->IsStarted == XCOMPONENT_IS_STARTED)
    {
        return XST_DEVICE_IS_STARTED;
    }

    /*
     * Now set the control register to add a multicast address
     * TODO: new r/m/w here
     * TODO: does this self-clear?
     * TODO: should we also disable multicast in ECR?
     */
    ControlReg = XIo_In32(InstancePtr->BaseAddress + XEM_ECR_OFFSET);
    XIo_Out32(InstancePtr->BaseAddress + XEM_ECR_OFFSET,
              ControlReg | XEM_ECR_CLEAR_HASH_MASK);

    return XST_SUCCESS;
}
