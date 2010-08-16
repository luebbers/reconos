/******************************************************************************
*     $Date: 2005/02/17 20:26:25 $
*     $RCSfile: xtft_l.c,v $
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

#include "xtft_l.h"
#include "xtft_charcode.h"

/************************** Constant Definitions ****************************/



void XTft_FillScreen(void * BaseAddress, Xuint32 xu, Xuint32 yu, Xuint32 xl, 
                Xuint32 yl, Xuint32 col)
{
    Xuint32 x;
    Xuint32 y;

    for(x = xu; x <= xl; x++)
    {
        for(y = yu; y <= yl; y++)
        {
            XTft_mSetPixel(BaseAddress, x, y, col);
        }
    }
}

void XTft_WriteChar(
  void * BaseAddress,
  Xint8 ch,
  Xuint32 xu,
  Xuint32 yu,
  Xuint32 fgColor,
  Xuint32 bgColor)
{
  Xuint32 col, x, y;
  Xuint8 val;

  for (y = 0; y < XTFT_CHAR_HEIGHT; y++)
  {
    val = XTft_vidChars[(Xuint32) ch][y];
    for (x = 0; x < XTFT_CHAR_WIDTH; x++)
    {
      if (val & (1 << (XTFT_CHAR_WIDTH - x - 1)))
        col = fgColor;
      else
        col = bgColor;
      
      XTft_mSetPixel(BaseAddress, xu+x, yu+y, col);
    }
  }
}




