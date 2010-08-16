/******************************************************************************
*     $Date: 2005/02/17 20:26:25 $
*     $RCSfile: xtft.h,v $
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
#ifndef XTFT_H /* prevent circular inclusions */
#define XTFT_H /* by using protection macros */

/***************************** Include Files ********************************/

#include "xbasic_types.h"
#include "xstatus.h"
// #include "xps2_l.h"

/************************** Constant Definitions ****************************/

/**************************** Type Definitions ******************************/

typedef struct
{
    Xuint32 BaseAddress;
    Xuint32 X;
    Xuint32 Y;
    Xuint32 FgColor;
    Xuint32 BgColor;
    Xuint32 IsReady;
} XTft;

typedef struct
{
    Xuint16 DeviceId;       /* Unique ID  of device */
    Xuint32 BaseAddress;    /* Base address of device */
} XTft_Config;

/***************** Macros (Inline Functions) Definitions ********************/

/************************** Function Prototypes *****************************/

XStatus XTft_Initialize(XTft *InstancePtr, Xuint16 DeviceId);

XTft_Config *XTft_LookupConfig(Xuint16 DeviceId);

XStatus XTft_Write(XTft *InstancePtr, Xint8 val);
XStatus XTft_SetPixel(XTft *InstancePtr, Xuint32 x, Xuint32 y, Xuint32 color);
XStatus XTft_GetPixel(XTft *InstancePtr, Xuint32 x, Xuint32 y, Xuint32 *color);
XStatus XTft_ClearScreen(XTft *InstancePtr);
XStatus XTft_Scroll(XTft *InstancePtr);
XStatus XTft_SetPos(XTft *InstancePtr, Xuint32 x, Xuint32 y);
XStatus XTft_SetColor(XTft *InstancePtr, Xuint32 fgColor, Xuint32 bgColor);

#endif
