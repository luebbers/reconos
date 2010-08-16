/* $Header:
/devl/xcs/repo/env/Databases/ip2/processor/software/devel/hwicap/v1_00_a/src/xhw
icap_set_configuration.c,v 1.4 2004/11/01 17:48:26 meinelte Exp $ */
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
*       (c) Copyright 2003-2005 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
*   xhwicap_set_configuration.c
*
* This file contains the function that loads a partial bitstream located
* in system memory into the device (ICAP).
*
* @note none.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a bjb  11/20/03 First release
* 1.00a sv   08/31/05 Changed the data type of the variable I from Xint32 to
*                     Xuint32 to match the pass by value of parameter Size
*
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xhwicap_i.h"
#include "xhwicap.h"
#include <xbasic_types.h>
#include <xstatus.h>

/************************** Constant Definitions ****************************/

#define XHI_BUFFER_START 0

/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/

/****************************************************************************
*
* Loads a partial bitstream from system memory.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Data - Address of the data representing the partial bitstream
* @param    Size - the size of the partial bitstream in 32 bit words.
*
* @return   XST_SUCCESS, XST_BUFFER_TOO_SMALL or XST_INVALID_PARAM.
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_SetConfiguration(XHwIcap *InstancePtr, Xuint32 *Data,
                                 Xuint32 Size)
{
    XStatus Status;
    Xint32 BufferCount=0;
    Xint32 NumWrites=0;
    Xboolean Dirty=XFALSE;
    Xuint32 I;

    /* Loop through all the data */
    for (I=0,BufferCount=0;I<Size;I++)
    {

        /* Copy data to bram */
        XHwIcap_StorageBufferWrite(InstancePtr, BufferCount, Data[I]);
        Dirty=XTRUE;

        if (BufferCount == XHI_MAX_BUFFER_INTS-1)
        {
            /* Write data to ICAP */
            Status = XHwIcap_DeviceWrite(InstancePtr, XHI_BUFFER_START,
                                         XHI_MAX_BUFFER_INTS);
            if (Status != XST_SUCCESS)
            {
                return Status;
            }

            BufferCount=0;
            NumWrites++;
            Dirty=XFALSE;
        } else
        {
         BufferCount++;
        }
    }

   /* Write unwritten data to ICAP */
   if (Dirty==XTRUE)
   {
      /* Write data to ICAP */
      Status = XHwIcap_DeviceWrite(InstancePtr, XHI_BUFFER_START,
                                    BufferCount+1);
      return Status;
   }

   return XST_SUCCESS;
};


