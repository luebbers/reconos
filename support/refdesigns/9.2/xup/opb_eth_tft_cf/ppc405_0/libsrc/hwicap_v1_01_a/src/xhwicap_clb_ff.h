/* $Header:
/devl/xcs/repo/env/Databases/ip2/processor/software/devel/hwicap/v1_00_a/src/xhw
icap_clb_ff.h,v 1.6 2005/09/26 20:05:54 trujillo Exp $ */
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
* @file xhwicap_clb_ff.h
*
* This header file contains bit information about the CLB FF resource.
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

#ifndef XHWICAP_CLB_FF_H_  /* prevent circular inclusions */
#define XHWICAP_CLB_FF_H_  /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/************************** Constant Definitions ****************************/

/** Index into the CONTENTS and SRMODE for XQ Register. */
#define XHI_CLB_XQ 0
/** Index into the CONTENTS and SRMODE for YQ Register. */
#define XHI_CLB_YQ 1

/**************************** Type Definitions ******************************/

typedef struct
{

    /* MODE values. */
    const Xuint8 LATCH[1];  /* Value to put register into LATCH mode. */
    const Xuint8 FF[1];     /* Value to put register into FF mode. */

    /* CONTENTS values. */
    const Xuint8 INIT0[1];  /* Value to initialize register CONTENTS to 0.  */
    const Xuint8 INIT1[1];  /* Value to initialize register CONTENTS to 1.  */
    const Xuint8 ZERO[1];   /* Same as INIT0 */
    const Xuint8 ONE[1];    /* Same as INIT1 */

    /* SRMODE values. */
    const Xuint8 SRLOW[1];  /* When SR is asserted register goes to 0 (resets).
    */
    const Xuint8 SRHIGH[1]; /* When SR is asserted register goes to 1 (sets). */

    /* SYNCMODE values. */
    const Xuint8 SYNC[1]; /* Puts both XQ and YQ in synchronous set/reset
                           mode. */
    const Xuint8 ASYNC[1]; /* Puts both XQ and YQ in asynchronous
                            set/reset mode. */

    /* LATCH or FF mode.  Indexed by slice (0-3) only.  It affects both
     * XQ and YQ registers. */
    const Xuint8 MODE[4][1][2];

    /** SYNC or ASYNC mode.  Indexed by slice (0-3) only.  It affects
     * both  XQ and YQ registers. */
    const Xuint8 SYNCMODE[4][1][2];

    /* INIT0, INIT1, ONE, or ZERO.  Indexed by the slice basis (0-3).
     * And then indexed by the element (XHI_CLB_XQ or XHI_CLB_YQ).
     * INIT0 and ZERO are equivalent as well as INIT1 and ONE.  There
     * are two values there only as to not confuse the values given in
     * FPGA_EDITOR which are INIT0 and INIT1.  They both can either
     * initialize or directly set the Register contents (assuming a
     * GRESTORE packet command is used after doing a configuration on a
     * device). */
    const Xuint8 CONTENTS[4][2][1][2];

    /* SRHIGH or SRLOW.  Indexed by the slice (0-3).
     * And then indexed by the element (XHI_CLB_XQ or XHI_CLB_YQ)
     */
    const Xuint8 SRMODE[4][2][1][2];

} XHwIcap_ClbFf;

/***************** Macros (Inline Functions) Definitions ********************/


/************************** Function Prototypes *****************************/


/************************** Variable Definitions ****************************/

/***************************************************************************/
/**
*  This structure defines the bits associated with a Flip Flop in a CLB
*  tile. Note that there are 8 FFs, the XQ and YQ Registers in
*  Slice 0, 1, 2 and 3.
*/

#if XHI_FAMILY == XHI_DEV_FAMILY_V4 /* Virtex4 */

const XHwIcap_ClbFf XHI_CLB_FF =
{
   /* LATCH*/
   {1},
   /* FF*/
   {0},
   /* INIT0*/
   {1},
   /* INIT1*/
   {0},
   /* ZERO*/
   {1},
   /* ONE*/
   {0},
   /* SRLOW*/
   {1},
   /* SRHIGH*/
   {0},
   /* SYNC*/
   {1},
   /* ASYNC*/
   {0},
   /* MODE*/
   {
      /* Slice 0. */
      {
         {10, 20}
      },
      /* Slice 1. */
      {
         {50, 20}
      },
      /* Slice 2. */
      {
         {22, 20}
      },
      /* Slice 3. */
      {
         {62, 20}
      }
   },
   /* SYNCMODE*/
   {
      /* Slice 0. */
      {
         {26, 20}
      },
      /* Slice 1. */
      {
         {66, 20}
      },
      /* Slice 2. */
      {
         {25, 20}
      },
      /* Slice 3. */
      {
         {65, 20}
      }
   },
   /* CONTENTS*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {6, 20}
         },
         /* LE 1. */
         {
            {34, 20}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {46, 20}
         },
         /* LE 1. */
         {
            {74, 20}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
            {5, 20}
         },
         /* LE 1. */
         {
            {33, 20}
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
            {45, 20}
         },
         /* LE 1. */
         {
            {73, 20}
         }
      }
   },
   /* SRMODE*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {0, 20}
         },
         /* LE 1. */
         {
            {30, 20}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {42, 20}
         },
         /* LE 1. */
         {
            {70, 20}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
            {1, 20}
         },
         /* LE 1. */
         {
            {29, 20}
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
            {41, 20}
         },
         /* LE 1. */
         {
            {69, 20}
         }
      }
   },

};

#else /* Virtex2 and Virtex2Pro */

const XHwIcap_ClbFf XHI_CLB_FF =
{
   /* LATCH*/
   {1},
   /* FF*/
   {0},
   /* INIT0*/
   {1},
   /* INIT1*/
   {0},
   /* ZERO*/
   {1},
   /* ONE*/
   {0},
   /* SRLOW*/
   {1},
   /* SRHIGH*/
   {0},
   /* SYNC*/
   {1},
   /* ASYNC*/
   {0},
   /* MODE*/
   {
      /* Slice 0. */
      {
         {4, 0}
      },
      /* Slice 1. */
      {
         {44, 0}
      },
      /* Slice 2. */
      {
         {35, 0}
      },
      /* Slice 3. */
      {
         {75, 0}
      }
   },
   /* SYNCMODE*/
   {
      /* Slice 0. */
      {
         {16, 0}
      },
      /* Slice 1. */
      {
         {56, 0}
      },
      /* Slice 2. */
      {
         {23, 0}
      },
      /* Slice 3. */
      {
         {63, 0}
      }
   },
   /* CONTENTS*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {17, 1}
         },
         /* LE 1. */
         {
            {17, 2}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {57, 1}
         },
         /* LE 1. */
         {
            {57, 2}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
            {19, 1}
         },
         /* LE 1. */
         {
            {19, 2}
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
            {59, 1}
         },
         /* LE 1. */
         {
            {59, 2}
         }
      }
   },
   /* SRMODE*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {0, 0}
         },
         /* LE 1. */
         {
            {15, 0}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {40, 0}
         },
         /* LE 1. */
         {
            {55, 0}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
            {39, 0}
         },
         /* LE 1. */
         {
            {24, 0}
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
            {79, 0}
         },
         /* LE 1. */
         {
            {64, 0}
         }
      }
   },

};

#endif

#ifdef __cplusplus
}
#endif

#endif

