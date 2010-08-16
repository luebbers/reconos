/******************************************************************************
*     $Date: 2005/02/17 20:26:25 $
*     $RCSfile: xtft_l.h,v $
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
#ifndef XTFT_L_H  /* prevent circular inclusions */
#define XTFT_L_H  /* by using protection macros  */

/***************************** Include Files ********************************/

#include "xbasic_types.h"
#include "xio.h"

/************************** Constant Definitions ****************************/

/*
 * physical screen dimensions 
 */
#define XTFT_DISPLAY_WIDTH         640
#define XTFT_DISPLAY_HEIGHT        480
/*
 * software representation of screen
 */
#define XTFT_DISPLAY_BUFFER_WIDTH  1024

/**************************** Type Definitions ******************************/

/***************** Macros (Inline Functions) Definitions ********************/

#define XTft_mClearScreen(BaseAddress, color)     \
         XTft_FillScreen(BaseAddress, 0, 0,      \
                         XTFT_DISPLAY_WIDTH,      \
                         XTFT_DISPLAY_HEIGHT,      \
                         color);

#define XTft_mGetColor(r, g, b)                  \
         ((r) << 16 + (g) << 8 + (b))

#define XTft_mSetPixel(BaseAddress, x, y, color) \
         XIo_Out32((BaseAddress) + \
                   4 * ((y) * XTFT_DISPLAY_BUFFER_WIDTH + x), color)

#define XTft_mGetPixel(BaseAddress, x, y) \
         XIo_In32((BaseAddress) + \
                  4 * ((y) * XTFT_DISPLAY_BUFFER_WIDTH + x))

/************************** Variable Definitions ****************************/

/************************** Function Prototypes *****************************/

void XTft_FillScreen(Xuint32 BaseAddress, Xuint32 xu, Xuint32 yu, 
                     Xuint32 xl, Xuint32 yl, Xuint32 color);

void XTft_WriteChar(Xuint32 BaseAddress, Xint8 ch, Xuint32 xu, Xuint32 yu,
                    Xuint32 fgColor, Xuint32 bgColor);

/****************************************************************************/

#endif
