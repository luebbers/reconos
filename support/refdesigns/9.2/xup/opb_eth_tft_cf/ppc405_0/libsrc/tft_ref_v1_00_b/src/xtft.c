/******************************************************************************
*     $Date: 2005/02/17 20:26:25 $
*     $RCSfile: xtft.c,v $
*******************************************************************************

*******************************************************************************
*
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
*     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR
*     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION
*     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION
*     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS
*     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
*     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
*     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
*     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*     FOR A PARTICULAR PURPOSE.
*     
*     (c) Copyright 2004 Xilinx, Inc.
*     All rights reserved.
*
******************************************************************************/
/***************************** Include Files ********************************/

#include "xstatus.h"
#include "xparameters.h"
#include "xtft.h"
#include "xtft_l.h"
#include "xtft_i.h"
#include "xtft_charcode.h"
#include "xio.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

/****************************************************************************/

XStatus XTft_Write(XTft *InstancePtr, Xint8 val)
{
  XASSERT_NONVOID(InstancePtr != XNULL);
  XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

  switch (val)
  {
  case 0xd:  /* carriage return */
    XTft_SetPos(InstancePtr, 0, InstancePtr->Y);
    break;
  case 0xa:  /* line feed */
    XTft_SetPos(InstancePtr, 0, InstancePtr->Y+XTFT_CHAR_HEIGHT);
    break;
  default:
    XTft_SetPos(InstancePtr, InstancePtr->X, InstancePtr->Y);
    XTft_WriteChar(InstancePtr->FramebufferAddress, val,
                   InstancePtr->X, InstancePtr->Y,
                   InstancePtr->FgColor, InstancePtr->BgColor);
    InstancePtr->X += XTFT_CHAR_WIDTH;
    break;
  }
  return XST_SUCCESS;
}

XStatus XTft_SetPixel(XTft *InstancePtr, Xuint32 x, Xuint32 y, Xuint32 color)
{
  XASSERT_NONVOID(InstancePtr != XNULL);
  XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

  XTft_mSetPixel(InstancePtr->FramebufferAddress, x, y, color);
  
  return XST_SUCCESS;
}

XStatus XTft_GetPixel(XTft *InstancePtr, Xuint32 x, Xuint32 y, Xuint32 *color)
{
  XASSERT_NONVOID(InstancePtr != XNULL);
  XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

  *color = XTft_mGetPixel(InstancePtr->FramebufferAddress, x, y);
  
  return XST_SUCCESS;
}

XStatus XTft_ClearScreen(XTft *InstancePtr)
{
  XASSERT_NONVOID(InstancePtr != XNULL);
  XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

  XTft_mClearScreen(InstancePtr->FramebufferAddress, InstancePtr->BgColor);
  
  InstancePtr->X = 0;
  InstancePtr->Y = 0;

  return XST_SUCCESS;
}

XStatus XTft_Scroll(XTft *InstancePtr)
{
  Xuint32 col;
  Xuint32 x, y;

  XASSERT_NONVOID(InstancePtr != XNULL);
  XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

  for (y = 0; y < XTFT_DISPLAY_HEIGHT-XTFT_CHAR_HEIGHT; y++)
  {
    for (x = 0; x < XTFT_DISPLAY_WIDTH; x++)
    {
      col = XTft_mGetPixel(InstancePtr->FramebufferAddress, x, y+XTFT_CHAR_HEIGHT);
      XTft_mSetPixel(InstancePtr->FramebufferAddress, x, y, col);
    }
  }
  XTft_FillScreen(InstancePtr->FramebufferAddress,
                  0, XTFT_DISPLAY_HEIGHT-XTFT_CHAR_HEIGHT,
                  XTFT_DISPLAY_WIDTH, XTFT_DISPLAY_HEIGHT-1,
                  InstancePtr->BgColor);

   return XST_SUCCESS;
 }


 XStatus XTft_SetPos(XTft *InstancePtr, Xuint32 x, Xuint32 y)
 {
   XASSERT_NONVOID(InstancePtr != XNULL);
   XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

   if (x > XTFT_DISPLAY_WIDTH - XTFT_CHAR_WIDTH)
   {
     x = 0;
     y += XTFT_CHAR_HEIGHT;
   }
   while (y > XTFT_DISPLAY_HEIGHT - XTFT_CHAR_HEIGHT)
   {
     XTft_Scroll(InstancePtr);
     y = y - XTFT_CHAR_HEIGHT;
   }

   InstancePtr->X = x;
   InstancePtr->Y = y;

   return XST_SUCCESS;
 }

 XStatus XTft_SetColor(XTft *InstancePtr, Xuint32 fgColor, Xuint32 bgColor)
 {
   XASSERT_NONVOID(InstancePtr != XNULL);
   XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

   InstancePtr->BgColor = bgColor;
   InstancePtr->FgColor = fgColor;

  return XST_SUCCESS;
}

XStatus XTft_Initialize(XTft *InstancePtr, Xuint16 DeviceId)
{
    XTft_Config *TftConfigPtr;

    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);

    /*
     * Lookup the device configuration in the temporary CROM table. Use this
     * configuration info down below when initializing this component.
     */
    TftConfigPtr = XTft_LookupConfig(DeviceId);

    if (TftConfigPtr == (XTft_Config *)XNULL)
    {
       return XST_DEVICE_NOT_FOUND;
    }

    /*
     * Setup the data that is from the configuration information
     */
    InstancePtr->FramebufferAddress = (void*)TftConfigPtr->FramebufferAddress;
    
    /*
     * Initialize the instance data to some default values and setup a default
     * handler
     */
    InstancePtr->X     = 0;
    InstancePtr->Y     = 0;
    InstancePtr->FgColor = 0xffffffff;
    InstancePtr->BgColor = 0;

    XTft_mClearScreen(InstancePtr->FramebufferAddress, InstancePtr->BgColor);
    /*
     * Indicate the instance is now ready to use, initialized without error
     */
    InstancePtr->IsReady = XCOMPONENT_IS_READY;

    return XST_SUCCESS;
}

XTft_Config *XTft_LookupConfig(Xuint16 DeviceId)
{
    XTft_Config *CfgPtr = XNULL;

    int i;

    for (i=0; i < XPAR_XTFT_NUM_INSTANCES; i++)
    {
        if (XTft_ConfigTable[i].DeviceId == DeviceId)
        {
            CfgPtr = &XTft_ConfigTable[i];
        }
    }

    return CfgPtr;
}
