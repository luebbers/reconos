/* $Header:
/devl/xcs/repo/env/Databases/ip2/processor/software/devel/hwicap/v1_00_a/src/xhw
icap_clb_srinv.h,v 1.6 2005/09/26 20:05:54 trujillo Exp $ */
/*****************************************************************************
*
*       XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
*       AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND
*       SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,
*       OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
*       APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION
*       THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF
*       INFRINGEMENT,
*       AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
*       FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
*       WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
*       IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
*       REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
*       INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*       FOR A PARTICULAR PURPOSE.
*
*       (c) Copyright 2003-2007 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xhwicap_clb_srinv.h
*
* This header file contains bit information about the CLB SRINV resource.
* This header file can be used with the XHwIcap_GetClbBits() and
* XHwIcap_SetClbBits() functions.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a bjb  11/14/03 First release
* 1.01a bjb  04/10/06 V4 Support
* </pre>
*
*****************************************************************************/

#ifndef XHWICAP_CLB_SRINV_H_  /* prevent circular inclusions */
#define XHWICAP_CLB_SRINV_H_  /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/************************** Constant Definitions ****************************/


/**************************** Type Definitions ******************************/

typedef struct
{
    /* SRINV Resource values. */
    const Xuint8 SR_B[1];  /* Invert SR Line. */
    const Xuint8 SR[1];    /* Do not Invert SR line. */

    /** Configure the SRINV mux (SR_B or SR).  This array indexed by
     * slice  (0-3). */
    const Xuint8 RES[4][1][2];
} XHwIcap_ClbSrinv;

/***************** Macros (Inline Functions) Definitions ********************/


/************************** Function Prototypes *****************************/


/************************** Variable Definitions ****************************/

/**
* This structure defines the SRINV mux
*/

#if XHI_FAMILY == XHI_DEV_FAMILY_V4 /* Virtex4 */

const XHwIcap_ClbSrinv XHI_CLB_SRINV =
{
   /* SR_B*/
   {0},
   /* SR*/
   {1},
   /* RES*/
   {
      /* Slice 0. */
      {
         {24, 18}
      },
      /* Slice 1. */
      {
         {23, 18}
      },
      /* Slice 2. */
      {
         {26, 18}
      },
      /* Slice 3. */
      {
         {25, 18}
      }
   },

};

#else /* Virtex2 and Virtex2Pro */

const XHwIcap_ClbSrinv XHI_CLB_SRINV =
{
   /* SR_B*/
   {0},
   /* SR*/
   {1},
   /* RES*/
   {
      /* Slice 0. */
      {
         {1, 4}
      },
      /* Slice 1. */
      {
         {16, 4}
      },
      /* Slice 2. */
      {
         {7, 4}
      },
      /* Slice 3. */
      {
         {10, 4}
      }
   },

};

#endif

#ifdef __cplusplus
}
#endif

#endif

