/* $Header:
/devl/xcs/repo/env/Databases/ip2/processor/software/devel/hwicap/v1_00_a/src/xhw
icap_clb_lut.h,v 1.5 2005/09/26 20:05:54 trujillo Exp $ */
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
* @file xhwicap_clb_lut.h
*
* This header file contains bit information about the CLB LUT resource.
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

#ifndef XHWICAP_CLB_LUT_H_  /* prevent circular inclusions */
#define XHWICAP_CLB_LUT_H_  /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/************************** Constant Definitions ****************************/

/** Index into SLICE and MODE for F LUT. */
#define XHI_CLB_LUT_F 0
/** Index into SLICE and MODE for G LUT. */
#define XHI_CLB_LUT_G 1

/**************************** Type Definitions ******************************/

typedef struct
{
    /* MODE resource values. */
    const Xuint8 LUT_MODE[1];  /* Set MODE to LUT mode */
    const Xuint8 ROM_MODE[1];  /* Set MODE to ROM mode. (Same as LUT mode) */
    const Xuint8 RAM_MODE[1];  /* Set MODE to RAM mode. */


    /* CONFIG resource values. */
    const Xuint8 SHIFT_CONFIG[2]; /* Set CONFIG to shfiter. */
    const Xuint8 RAM_CONFIG[2];   /* Set CONFIG to ram. */
    const Xuint8 LUT_CONFIG[2];   /* Set CONFIG to LUT. */

    /* RAM_MODE, ROM_MODE, or LUT_MODE.  Indexed by the slice (0-3).  If
     * only one LUT is in RAM or SHIFT mode, it MUST be the G LUT.
     */
    const Xuint8 MODE[4][1][2];

    /* SHIFT_CONFIG, RAM_CONFIG, or LUT_CONFIG.  Indexed by the slice
     * (0-3).  And then indexed by the logic element (LUT.F or LUT.G).
     * Note that if the F LUT is in any sort of ram or shifter modes,
     * the G LUT must also be in ram or shifter mode.  Also, be sure to
     * set the MODE bit appropriately. */
    const Xuint8 CONFIG[4][2][2][2];

    /* LUT memory contents. Indexed by slice first (0-3) and by
     * XHI_CLB_LUT_F or XHI_CLB_LUT_G second.  **/
    const Xuint8 CONTENTS[4][2][16][2];

} XHwIcap_ClbLut;


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Function Prototypes *****************************/


/************************** Variable Definitions ****************************/

/****************************************************************************/
/**
*  This structure defines the Look Up Tables, or <em>LUTs</em>.
*  in the Virtex2/Pro CLB.  Note that there are 8 16-bit
*  LUTs, the F and G LUTs in Slice 0, 1, 2 and 3.  These
*  LUTs can take any arbitrary bit pattern.
*
*  <p>
*
*  Note, that DUAL_PORT mode cannot be configured here.  Thats because
*  it is essentially always in effect. But, it can only be used in the top
*  two slices (2 and 3) using the address lines from the bottom
*  two slices (0 and 1) for the write address. Although you can technically
*  put the bottom two slice LUTs in dual port mode in the fpga_editor,
*  the read and write addresses will always be the same.  This is
*  different from the Virtex where the two LUTs in a slice were
*  combined to make a dual port RAM.  In Virtex 2, every LUT is
*  dual ported, but only the top two have different read/write
*  addresses.
*
***************************************************************************/

#if XHI_FAMILY == XHI_DEV_FAMILY_V4 /* Virtex4 */

const XHwIcap_ClbLut XHI_CLB_LUT =
{
   /* LUT_MODE*/
   {0},
   /* ROM_MODE*/
   {0},
   /* RAM_MODE*/
   {1},
   /* SHIFT_CONFIG*/
   {0,1},
   /* RAM_CONFIG*/
   {1,0},
   /* LUT_CONFIG*/
   {0,0},
   /* MODE*/
   {
      /* Slice 0. */
      {
         {38, 20}
      },
      /* Slice 1. */
      {
         {79, 20}
      },
      /* Slice 2. */
      {
          /* No MODE for SLICE_L's, LUT only. */
      },
      /* Slice 3. */
      {
          /* No MODE for SLICE_L's, LUT only. */
      }
   },
   /* CONFIG*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {8, 20}, {37, 20}
         },
         /* LE 1. */
         {
            {7, 20}, {36, 20}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {48, 20}, {78, 20}
         },
         /* LE 1. */
         {
            {40, 20}, {78, 20}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
          /* No CONFIG for SLICE_L's, LUT only. */
         },
         /* LE 1. */
         {
          /* No CONFIG for SLICE_L's, LUT only. */
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
          /* No CONFIG for SLICE_L's, LUT only. */
         },
         /* LE 1. */
         {
          /* No CONFIG for SLICE_L's, LUT only. */
         }
      }
   },
   /* CONTENTS*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {15, 21}, {14, 21}, {13, 21}, {12, 21}, {11, 21}, {10, 21},
            {9, 21}, {8, 21}, {7, 21}, {6, 21}, {5, 21}, {4, 21},
            {3, 21}, {2, 21}, {1, 21}, {0, 21}
         },
         /* LE 1. */
         {
            {38, 21}, {37, 21}, {36, 21}, {35, 21}, {34, 21}, {33, 21},
            {32, 21}, {31, 21}, {30, 21}, {29, 21}, {28, 21}, {27, 21},
            {26, 21}, {25, 21}, {24, 21}, {23, 21}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {55, 21}, {54, 21}, {53, 21}, {52, 21}, {51, 21}, {50, 21},
            {49, 21}, {48, 21}, {47, 21}, {46, 21}, {45, 21}, {44, 21},
            {43, 21}, {42, 21}, {41, 21}, {40, 21}
         },
         /* LE 1. */
         {
            {78, 21}, {77, 21}, {76, 21}, {75, 21}, {74, 21}, {73, 21},
            {72, 21}, {71, 21}, {70, 21}, {69, 21}, {68, 21}, {67, 21},
            {66, 21}, {65, 21}, {64, 21}, {63, 21}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
            {15, 19}, {14, 19}, {13, 19}, {12, 19}, {11, 19}, {10, 19},
            {9, 19}, {8, 19}, {7, 19}, {6, 19}, {5, 19}, {4, 19},
            {3, 19}, {2, 19}, {1, 19}, {0, 19}
         },
         /* LE 1. */
         {
            {38, 19}, {37, 19}, {36, 19}, {35, 19}, {34, 19}, {33, 19},
            {32, 19}, {31, 19}, {30, 19}, {29, 19}, {28, 19}, {27, 19},
            {26, 19}, {25, 19}, {24, 19}, {23, 19}
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
            {55, 19}, {54, 19}, {53, 19}, {52, 19}, {51, 19}, {50, 19},
            {49, 19}, {48, 19}, {47, 19}, {46, 19}, {45, 19}, {44, 19},
            {43, 19}, {42, 19}, {41, 19}, {40, 19}
         },
         /* LE 1. */
         {
            {78, 19}, {77, 19}, {76, 19}, {75, 19}, {74, 19}, {73, 19},
            {72, 19}, {71, 19}, {70, 19}, {69, 19}, {68, 19}, {67, 19},
            {66, 19}, {65, 19}, {64, 19}, {63, 19}
         }
      }
   },

};

#else /* Virtex2 and Virtex2Pro */

const XHwIcap_ClbLut XHI_CLB_LUT =
{
   /* LUT_MODE*/
   {0},
   /* ROM_MODE*/
   {0},
   /* RAM_MODE*/
   {1},
   /* SHIFT_CONFIG*/
   {0,1},
   /* RAM_CONFIG*/
   {1,0},
   /* LUT_CONFIG*/
   {0,0},
   /* MODE*/
   {
      /* Slice 0. */
      {
         {22, 1}
      },
      /* Slice 1. */
      {
         {62, 1}
      },
      /* Slice 2. */
      {
         {22, 2}
      },
      /* Slice 3. */
      {
         {62, 2}
      }
   },
   /* CONFIG*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {18, 1}, {16, 1}
         },
         /* LE 1. */
         {
            {20, 1}, {21, 1}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {58, 1}, {56, 1}
         },
         /* LE 1. */
         {
            {60, 1}, {61, 1}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
            {18, 2}, {16, 2}
         },
         /* LE 1. */
         {
            {20, 2}, {21, 2}
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
            {58, 2}, {56, 2}
         },
         /* LE 1. */
         {
            {60, 2}, {61, 2}
         }
      }
   },
   /* CONTENTS*/
   {
      /* Slice 0. */
      {
         /* LE 0. */
         {
            {15, 1}, {14, 1}, {13, 1}, {12, 1}, {11, 1}, {10, 1},
            {9, 1}, {8, 1}, {7, 1}, {6, 1}, {5, 1}, {4, 1},
            {3, 1}, {2, 1}, {1, 1}, {0, 1}
         },
         /* LE 1. */
         {
            {24, 1}, {25, 1}, {26, 1}, {27, 1}, {28, 1}, {29, 1},
            {30, 1}, {31, 1}, {32, 1}, {33, 1}, {34, 1}, {35, 1},
            {36, 1}, {37, 1}, {38, 1}, {39, 1}
         }
      },
      /* Slice 1. */
      {
         /* LE 0. */
         {
            {55, 1}, {54, 1}, {53, 1}, {52, 1}, {51, 1}, {50, 1},
            {49, 1}, {48, 1}, {47, 1}, {46, 1}, {45, 1}, {44, 1},
            {43, 1}, {42, 1}, {41, 1}, {40, 1}
         },
         /* LE 1. */
         {
            {64, 1}, {65, 1}, {66, 1}, {67, 1}, {68, 1}, {69, 1},
            {70, 1}, {71, 1}, {72, 1}, {73, 1}, {74, 1}, {75, 1},
            {76, 1}, {77, 1}, {78, 1}, {79, 1}
         }
      },
      /* Slice 2. */
      {
         /* LE 0. */
         {
            {15, 2}, {14, 2}, {13, 2}, {12, 2}, {11, 2}, {10, 2},
            {9, 2}, {8, 2}, {7, 2}, {6, 2}, {5, 2}, {4, 2},
            {3, 2}, {2, 2}, {1, 2}, {0, 2}
         },
         /* LE 1. */
         {
            {24, 2}, {25, 2}, {26, 2}, {27, 2}, {28, 2}, {29, 2},
            {30, 2}, {31, 2}, {32, 2}, {33, 2}, {34, 2}, {35, 2},
            {36, 2}, {37, 2}, {38, 2}, {39, 2}
         }
      },
      /* Slice 3. */
      {
         /* LE 0. */
         {
            {55, 2}, {54, 2}, {53, 2}, {52, 2}, {51, 2}, {50, 2},
            {49, 2}, {48, 2}, {47, 2}, {46, 2}, {45, 2}, {44, 2},
            {43, 2}, {42, 2}, {41, 2}, {40, 2}
         },
         /* LE 1. */
         {
            {64, 2}, {65, 2}, {66, 2}, {67, 2}, {68, 2}, {69, 2},
            {70, 2}, {71, 2}, {72, 2}, {73, 2}, {74, 2}, {75, 2},
            {76, 2}, {77, 2}, {78, 2}, {79, 2}
         }
      }
   },

};

#endif

#ifdef __cplusplus
}
#endif

#endif

