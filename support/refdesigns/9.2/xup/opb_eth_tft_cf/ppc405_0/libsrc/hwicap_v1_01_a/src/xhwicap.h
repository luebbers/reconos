/* $Header:
/devl/xcs/repo/env/Databases/ip2/processor/software/devel/hwicap/v1_00_a/src/xhw
icap.h,v 1.14 2005/09/26 20:05:54 trujillo Exp $ */
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
*       (c) Copyright 2003-2007 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xhwicap.h
*
* This file contains the software API definition of the Xilinx Hardware
* ICAP (hwicap) component.
*
* The Xilinx Hardware ICAP controller is designed to allow
* reconfiguration of select FPGA resources as well as loading partial
* bitstreams from system memory through the Internal Configuration
* Access Port (ICAP).
*
* The source code for the XHwIcap_SetClbBits and XHwIcap_GetClbBits
* functions  are not included.  These functions are delivered as .o
* files.  Libgen uses the appropriate .o files for the target processor.
* This is specified by the hwicap_v2_1_0.tcl file in the data directory.
*
* @note
*
* There are a few items to be aware of when using this driver:
* 1) Only Virtex 2, Virtex 2 Pro and Virtex 4 devices are supported.
* 2) The ICAP port is disabled when the configuration mode, via the MODE pins,
* is set to Boundary Scan/JTAG. The ICAP is enabled in all other configuration
* modes and it is possible to configure the device via JTAG in all
* configuration modes.
* 3) Reading or writing to columns containing SRL16's or LUT RAM's can cause
* corruption of data in those elements. Avoid reading or writing to columns
* containing SRL16's or LUT RAM's.
*
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a bjb  11/17/03 First release
* 1.00a sv   08/31/05 Changed the data type of the variable I from Xint32 to
*                     Xuint32 to match the pass by value of the parameter Size
*                     in the source file xhwicap_set_configuration.c
* 1.01a bjb  04/10/06 V4 Support
* </pre>
*
*****************************************************************************/

#ifndef XHWICAP_H_ /* prevent circular inclusions */
#define XHWICAP_H_ /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files ********************************/

#include "xhwicap_i.h"
#include "xhwicap_l.h"
#include <xstatus.h>

/************************** Constant Definitions ****************************/

/* General purpose device ID.  The actual ID gets read from the ICAP port. */
#define XHI_READ_DEVICEID_FROM_ICAP    0x0000000UL

/* Virtex 2 Device constants. The IDCODE for this device. */
#define XHI_XC2V40      0x01008093UL
#define XHI_XC2V80      0x01010093UL
#define XHI_XC2V250     0x01018093UL
#define XHI_XC2V500     0x01020093UL
#define XHI_XC2V1000    0x01028093UL
#define XHI_XC2V1500    0x01030093UL
#define XHI_XC2V2000    0x01038093UL
#define XHI_XC2V3000    0x01040093UL
#define XHI_XC2V4000    0x01050093UL
#define XHI_XC2V6000    0x01060093UL
#define XHI_XC2V8000    0x01070093UL

/* Virtex2 Pro Device constants. The IDCODE for this device. */
#define XHI_XC2VP2      0x01226093UL
#define XHI_XC2VP4      0x0123E093UL
#define XHI_XC2VP7      0x0124A093UL
#define XHI_XC2VP20     0x01266093UL
#define XHI_XC2VP30     0x0127E093UL
#define XHI_XC2VP40     0x01292093UL
#define XHI_XC2VP50     0x0129E093UL
#define XHI_XC2VP70     0x012BA093UL
#define XHI_XC2VP100    0x012D6093UL
#define XHI_XC2VP125    0x012F2093UL

/* Virtex 4 */
#define XHI_XC4VLX15    0x01658093UL
#define XHI_XC4VLX25    0x0167C093UL
#define XHI_XC4VLX40    0x016A4093UL
#define XHI_XC4VLX60    0x016B4093UL
#define XHI_XC4VLX80    0x016D8093UL
#define XHI_XC4VLX100   0x01700093UL
#define XHI_XC4VLX160   0x01718093UL
#define XHI_XC4VLX200   0x01734093UL

#define XHI_XC4VSX25    0x02068093UL
#define XHI_XC4VSX35    0x02088093UL
#define XHI_XC4VSX55    0x020B0093UL

#define XHI_XC4VFX12    0x01E58093UL
#define XHI_XC4VFX20    0x01E64093UL
#define XHI_XC4VFX40    0x01E8C093UL
#define XHI_XC4VFX60    0x01EB4093UL
#define XHI_XC4VFX100   0x01EE4093UL
#define XHI_XC4VFX140   0x01F14093UL


/* ERROR Codes - if needed */

/************************** Type Definitions ********************************/

/**
* This typedef contains configuration information for the device.
*/
typedef struct
{
    Xuint16 DeviceId;          /**< Unique ID  of device */
    Xuint32 BaseAddress;       /**< Register base address */

} XHwIcap_Config;

/**
* The XHwIcap driver instance data.  The user is required to allocated a
* variable of this type for every opb_hwicap device in the system. A
* pointer to a variable of this type is then passed to the driver API
* functions.
*
* Note - Virtex2/Pro devices only have one ICAP port so there should
* be at most only one opb_hwicap instantiated (per FPGA) in a system.
*/
typedef struct
{
    Xuint32 BaseAddress;    /* Base address of this component */
    Xuint32 IsReady;        /* Device is initialized and ready */
    Xuint32 DeviceIdCode;   /* IDCODE of targeted device */
    Xuint16 DeviceId;       /* User assigned ID for this component */
    Xuint32 Rows;           /* Number of CLB rows */
    Xuint32 Cols;           /* Number of CLB cols */
    Xuint32 BramCols;       /* Number of BRAM cols */
    Xuint32 BytesPerFrame;  /* Number of Bytes per minor Frame */
    Xuint32 WordsPerFrame;  /* Number of Words per minor Frame */
    Xuint32 ClbBlockFrames; /* Number of CLB type minor Frames */
    Xuint32 BramBlockFrames;     /* Number of Bram type minor Frames */
    Xuint32 BramIntBlockFrames;  /* Number of BramInt type minor Frames */
    /* Virtex 4 extensions */
    Xuint8  HClkRows;       /* Number of HClk cols */
    Xuint8  DSPCols;        /* Number of DSP cols */
    Xuint8  IOCols;         /* Number of IO cols */
    Xuint8  MGTCols;        /* Number of MGT cols */
    Xuint16 *SkipCols;      /* Columns to skip during CLB Col calculation */
} XHwIcap;




/***************** Macro (Inline Functions) Definitions *********************/

/****************************************************************************/
/**
*
* Converts a CLB SliceX coordinate to a column coordinate used by the
* XHwIcap_GetClbBits and XHwIcap_SetClbBits functions.
*
* @param    X - the SliceX coordinate to be converted
*
* @return   Column
*
* @note     C-style Signature:
*           Xuint32 XHwIcap_mSliceX2Col(Xuint32 X);
*
*****************************************************************************/
#define XHwIcap_mSliceX2Col(X) \
    ( (X >> 1) + 1)

/****************************************************************************/
/**
*
* Converts a CLB SliceY coordinate to a row coordinate used by the
* XHwIcap_GetClbBits and XHwIcap_SetClbBits functions.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Y - the SliceY coordinate to be converted
* @return   Row
*
* @note     C-style Signature:
*           Xuint32 XHwIcap_mSliceY2Row(XHwIcap *InstancePtr, Xuint32 Y);
*
*****************************************************************************/
#define XHwIcap_mSliceY2Row(InstancePtr, Y) \
    ( (InstancePtr)->Rows - (Y >> 1) )

/****************************************************************************/
/**
*
* Figures out which slice in a CLB is targeted by a given
* (SliceX,SliceY) pair.  This slice value is used for indexing in
* resource arrays.
*
* @param    X - the SliceX coordinate to be converted
* @param    Y - the SliceY coordinate to be converted
*
* @return   Slice index
*
* @note     C-style Signature:
*           Xuint32 XHwIcap_mSliceXY2Slice(Xuint32 X, Xuint32 Y);
*
*****************************************************************************/
#define XHwIcap_mSliceXY2Slice(X,Y) \
    ( ((X % 2) << 1) + (Y % 2) )

/************************** Function Prototypes *****************************/


/* These functions are the ones defined in the lower level
 * Self-Reconfiguration Platform (SRP) API.
 */

/* Initializes a XHwIcap instance.. */
XStatus XHwIcap_Initialize(XHwIcap *InstancePtr,  Xuint16 DeviceId,
                           Xuint32 DeviceIdCode);

/* Reads integers from the device into the storage buffer. */
XStatus XHwIcap_DeviceRead(XHwIcap *InstancePtr, Xuint32 Offset,
                           Xuint32 NumInts);

/* Writes integers to the device from the storage buffer. */
XStatus XHwIcap_DeviceWrite(XHwIcap *InstancePtr, Xuint32 Offset,
                            Xuint32 NumInts);

/* Writes word to the storage buffer. */
void XHwIcap_StorageBufferWrite(XHwIcap *InstancePtr, Xuint32 Address,
                                Xuint32 Data);

/* Reads word from the storage buffer. */
Xuint32 XHwIcap_StorageBufferRead(XHwIcap *InstancePtr, Xuint32 Address);

#if XHI_FAMILY == XHI_DEV_FAMILY_V2 /* If V2/V2P device */

/* Reads one frame from the device and puts it in the storage buffer. */
XStatus XHwIcap_DeviceReadFrame(XHwIcap *InstancePtr, Xint32 Block,
                               Xint32 MajorFrame, Xint32 MinorFrame);
#else /* If V4 device */
/* Reads one frame from the device and puts it in the storage buffer. */
XStatus XHwIcap_DeviceReadFrameV4(XHwIcap *InstancePtr, Xint32 Top,
                                Xint32 Block, Xint32 HClkRow,
                                Xint32 MajorFrame, Xint32 MinorFrame);
#endif

#if XHI_FAMILY == XHI_DEV_FAMILY_V2 /* If V2/V2P device */

/* Writes one frame from the storage buffer and puts it in the device. */
XStatus XHwIcap_DeviceWriteFrame(XHwIcap *InstancePtr, Xint32 Block,
                                Xint32 MajorFrame, Xint32 MinorFrame);
#else /* If V4 device */
/* Writes one frame from the storage buffer and puts it in the device. */
XStatus XHwIcap_DeviceWriteFrameV4(XHwIcap *InstancePtr, Xint32 Top,
                                Xint32 Block, Xint32 HClkRow,
                                 Xint32 MajorFrame, Xint32 MinorFrame);
#endif
/* Loads a partial bitstream from system memory. */
XStatus XHwIcap_SetConfiguration(XHwIcap *InstancePtr, Xuint32 *Data,
                                Xuint32 Size);

/* Sends a DESYNC command to the ICAP */
XStatus XHwIcap_CommandDesync(XHwIcap *InstancePtr);

/* Sends a CAPTURE command to the ICAP */
XStatus XHwIcap_CommandCapture(XHwIcap *InstancePtr);

/* Returns the value of the specified configuration register */
Xuint32 XHwIcap_GetConfigReg(XHwIcap *InstancePtr, Xuint32 ConfigReg);

#if XHI_FAMILY == XHI_DEV_FAMILY_V2 /* If V2/V2P device */
#define XHwIcap_SetClbBits XHwIcap_SetClbBitsV2
#define XHwIcap_GetClbBits XHwIcap_GetClbBitsV2
#else /* If V4 device */
#define XHwIcap_SetClbBits XHwIcap_SetClbBitsV4
#define XHwIcap_GetClbBits XHwIcap_GetClbBitsV4
#endif
/****************************************************************************/
/**
*
* Sets bits contained in a Center tile specified by the CLB row and col
* coordinates.  The coordinate system lables the upper left CLB as
* (1,1).  There are four slices per CLB.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Row - CLB row. (1,1) is the upper left CLB.
* @param    Col - CLB col. (1,1) is the upper left CLB.
* @param    Resource - Target bits (first dimension length will be the number of
*                      bits to set and must match the numBits parameter)
*                      (second dimension contains two value -- one for
*                      minor row and one for col information from within
*                      the Center tile targetted by the above row and
*                      col coords).
* @param    Value - Values to set each of the targets bits to.  The size
*                   of this array must be euqal to NumBits.
* @param    NumBits - The number of Bits to change in this method.
*
* @return   XST_SUCCESS, XST_BUFFER_TOO_SMALL or XST_INVALID_PARAM.
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_SetClbBits(XHwIcap *InstancePtr, Xint32 Row, Xint32 Col,
      const Xuint8 Resource[][2], const Xuint8 Value[], Xint32 NumBits);

/****************************************************************************/
/**
*
* Gets bits contained in a Center tile specified by the CLB row and col
* coordinates.  The coordinate system lables the upper left CLB as
* (1,1).  There are four slices per CLB.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Row - CLB row. (1,1) is the upper left CLB.
* @param    Col - CLB col. (1,1) is the upper left CLB.
* @param    Resource - Target bits (first dimension length will be the number of
*                      bits to set and must match the numBits parameter)
*                      (second dimension contains two value -- one for
*                      minor row and one for col information from within
*                      the Center tile targetted by the above row and
*                      col coords).
* @param    Value - Values to store each of the target bits into.  The size
*                   of this array must be equal to numBits.
* @param    NumBits - The number of Bits to change in this method.
*
* @return   XST_SUCCESS, XST_BUFFER_TOO_SMALL or XST_INVALID_PARAM.
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_GetClbBits(XHwIcap *InstancePtr, Xint32 Row, Xint32 Col,
      const Xuint8 Resource[][2], Xuint8 Value[], Xint32 NumBits);


/* Pointer to a function that returns XHwIcap_Config info. */
XHwIcap_Config *XHwIcap_LookupConfig(Xuint16 DeviceId);


/************************** Variable Declarations ***************************/

/* the configuration table */
extern XHwIcap_Config XHwIcap_ConfigTable[];

#ifdef __cplusplus
}
#endif

#endif

