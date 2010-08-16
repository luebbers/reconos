/* $Header:
/devl/xcs/repo/env/Databases/ip2/processor/software/devel/hwicap/v1_00_a/src/xhw
icap_srp.c,v 1.14 2005/09/26 20:06:37 trujillo Exp $ */
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
* @file xhwicap_srp.c
*
* This file contains SRP (self reconfigurable platform) driver
* functions.
*
* The SRP contains functions that allow low level access to
* configuration memory through the ICAP port.  This API provide methods
* for reading and writing data, frames, and partial bitstreams to the
* ICAP port.
*
* @note
*
* Only Virtex2, Virtex2Pro and Virtex4 devices are supported.
*
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00a bjb  11/17/03 First release
*       bjs  03/10/04 Fixed bug with XHI_READ_DEVICEID_FROM_ICAP
* 1.00b nps  17 Feb 05 Changed offset to be in bytes
* 1.00c tjb  10/24/05  Modified for 32-bit device read and write,
*                      V4 information added
* 1.00d bjb  05/27/06  Write to RESET register at end of Initialization.
* 1.01a sv   03/03/07  V4 Updates.
* </pre>
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include <xparameters.h>
#include <xbasic_types.h>
#include <xstatus.h>
#include "xhwicap_i.h"
#include "xhwicap.h"

/************************** Constant Definitions ****************************/

/* This is a list of arrays that contain information about columns interspersed
 * into the CLB columns.  These are DSP, IOB, DCM, and clock tiles.  When these
 * are crossed, the frame address must be incremeneted by an additional count
 * from the CLB column index.  The center tile is skipped twice because it
 * contains both a DCM and a GCLK tile that must be skipped. */
Xuint16 XHI_EMPTY_SKIP_COLS[] = {0xFFFF};
Xuint16 XHI_XC4VLX15_SKIP_COLS[] = {8, 12, 12, 0xFFFF};
Xuint16 XHI_XC4VLX25_SKIP_COLS[] = {8, 14, 14, 0xFFFF};
Xuint16 XHI_XC4VLX40_SKIP_COLS[] = {8, 18, 18, 0xFFFF};
Xuint16 XHI_XC4VLX60_SKIP_COLS[] = {12, 26, 26, 0xFFFF};
Xuint16 XHI_XC4VLX80_SKIP_COLS[] = {12, 28, 28, 0xFFFF};
Xuint16 XHI_XC4VLX100_SKIP_COLS[] = {12, 32, 32, 0xFFFF};
Xuint16 XHI_XC4VLX160_SKIP_COLS[] = {12, 44, 44, 0xFFFF};
Xuint16 XHI_XC4VLX200_SKIP_COLS[] = {12, 58, 58, 0xFFFF};
Xuint16 XHI_XC4VSX25_SKIP_COLS[] = {6, 14, 20, 20, 26, 34, 0xFFFF};
Xuint16 XHI_XC4VSX35_SKIP_COLS[] = {6, 14, 20, 20, 26, 34, 0xFFFF};
Xuint16 XHI_XC4VSX55_SKIP_COLS[] = {6, 10, 14, 18, 24, 24, 30, 34, 38,
                                  42, 0xFFFF};
Xuint16 XHI_XC4VFX12_SKIP_COLS[] = {12, 12, 16, 0xFFFF};
Xuint16 XHI_XC4VFX20_SKIP_COLS[] = {6, 18, 18, 22, 30, 0xFFFF};
Xuint16 XHI_XC4VFX40_SKIP_COLS[] = {6, 26, 26, 38, 46, 0xFFFF};
Xuint16 XHI_XC4VFX60_SKIP_COLS[] = {6, 18, 26, 26, 34, 46, 0xFFFF};
Xuint16 XHI_XC4VFX100_SKIP_COLS[] = {6, 22, 34, 34, 46, 62, 0xFFFF};
Xuint16 XHI_XC4VFX140_SKIP_COLS[] = {6, 22, 42, 42, 62, 78, 0xFFFF};


/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Variable Definitions ****************************/


/************************** Function Prototypes *****************************/


/****************************************************************************/
/**
*
* Initialize a XHwIcap instance..
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    BaseAddress - Base Address of the instance of this
*                         component.
* @param    DeviceId - User defined ID for the instance of this
*                      component.
* @param    DeviceIdCode - IDCODE of the FPGA device.  Examples of
* constants that can be used: XHI_XC2V40, XHI_XC2VP7 etc.  The constant
* XHI_READ_DEVICEID_FROM_ICAP can be used instead of specifying the
* IDCODE directly.
*
* @return   XST_SUCCESS, XST_INVALID_PARAM, or the invalid status from
*           CommandDesync when using XHI_READ_DEVICEID_FROM_ICAP.
*
* @note     Virtex2/Pro devices only have one ICAP port so there should
*           only be one opb_hwicap instantiated (per FPGA) in a system.
*
*****************************************************************************/
XStatus XHwIcap_Initialize(XHwIcap *InstancePtr, Xuint16 DeviceId,
        					Xuint32 DeviceIdCode)
{
    XHwIcap_Config *HwIcapConfigPtr;
    Xuint32 Rows;
    Xuint32 Cols;
    Xuint32 BramCols;
    Xuint8  DSPCols;
    Xuint8  IOCols;
    Xuint8  MGTCols;
    Xuint8  HClkRows;
    Xuint16 *SkipCols;
    XStatus Status;
    Xuint32 TempDevId;
    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);

    /*
     * If the device is ready, disallow the initialize and return a status
     * indicating it is started.  This allows the user to stop the device
     * and reinitialize, but prevents a user from inadvertently initializing.
     */
    if (InstancePtr->IsReady == XCOMPONENT_IS_READY) {
        return XST_DEVICE_IS_STARTED;
    }

    /* Default value until component is ready */
    InstancePtr->IsReady = 0;

    /*
     * Lookup the device configuration in the configuration table. Use this
     * configuration info when initializing this component.
     */
    HwIcapConfigPtr = XHwIcap_LookupConfig(DeviceId);
    if (HwIcapConfigPtr == (XHwIcap_Config *)XNULL){
        return XST_DEVICE_NOT_FOUND;
    }

    InstancePtr->BaseAddress = HwIcapConfigPtr->BaseAddress;

    /*
     * Dummy Read as the first data read has to be discarded.
     */
    InstancePtr->IsReady = XCOMPONENT_IS_READY;
    TempDevId = XHwIcap_GetConfigReg(InstancePtr, XHI_IDCODE);
    InstancePtr->IsReady = 0;

#ifdef __KERNEL__ /* Linux Kernel */
    extern int XHwIcap_init_remap_baseaddress(XHwIcap *);
    if (XHwIcap_init_remap_baseaddress(InstancePtr)) {
        return XST_FAILURE;
    }
#endif

    /* Read the IDCODE from ICAP if specified. */
    if (DeviceIdCode == XHI_READ_DEVICEID_FROM_ICAP) {

	/*
	 * Setting the IsReady of the driver temporarily so that
	 * we can read the IdCode of the device.
	 */
        InstancePtr->IsReady = XCOMPONENT_IS_READY;

	/* Mask out the version section of the DeviceIdCode */
	DeviceIdCode = XHwIcap_GetConfigReg(InstancePtr, XHI_IDCODE);
	DeviceIdCode = DeviceIdCode & 0x0FFFFFFF;



        Status = XHwIcap_CommandDesync(InstancePtr);
        InstancePtr->IsReady = 0;
        if (Status != XST_SUCCESS) {
            return Status;
        }
    }

    Rows = 16;  /* Default to 16 for Virtex 4 */
    Cols = 0;
    BramCols = 0;
    DSPCols = 0;
    IOCols = 0;
    MGTCols = 0;
    HClkRows = 0;
    SkipCols = XHI_EMPTY_SKIP_COLS;
    switch (DeviceIdCode)
    {
        case XHI_XC2V40:
            Rows = 8;
            Cols = 8;
            BramCols = 2;
            break;
        case XHI_XC2V80:
            Rows = 16;
            Cols = 8;
            BramCols = 2;
            break;
        case XHI_XC2V250:
            Rows = 24;
            Cols = 16;
            BramCols = 4;
            break;
        case XHI_XC2V500:
            Rows = 32;
            Cols = 24;
            BramCols = 4;
            break;
        case XHI_XC2V1000:
            Rows = 40;
            Cols = 32;
            BramCols = 4;
            break;
        case XHI_XC2V1500:
            Rows = 48;
            Cols = 40;
            BramCols = 4;
            break;
        case XHI_XC2V2000:
            Rows = 56;
            Cols = 48;
            BramCols = 4;
            break;
        case XHI_XC2V3000:
            Rows = 64;
            Cols = 56;
            BramCols = 6;
            break;
        case XHI_XC2V4000:
            Rows = 80;
            Cols = 72;
            BramCols = 6;
            break;
        case XHI_XC2V6000:
            Rows = 96;
            Cols = 88;
            BramCols = 6;
            break;
        case XHI_XC2V8000:
            Rows = 112;
            Cols = 104;
            BramCols = 6;
            break;
        case XHI_XC2VP2:
            Rows = 16;
            Cols = 22;
            BramCols = 4;
            break;
        case XHI_XC2VP4:
            Rows = 40;
            Cols = 22;
            BramCols = 4;
            break;
        case XHI_XC2VP7:
            Rows = 40;
            Cols = 34;
            BramCols = 6;
            break;
        case XHI_XC2VP20:
            Rows = 56;
            Cols = 46;
            BramCols = 8;
            break;
        case XHI_XC2VP30:
            Rows = 80;
            Cols = 46;
            BramCols = 8;
            break;
        case XHI_XC2VP40:
            Rows = 88;
            Cols = 58;
            BramCols = 10;
            break;
        case XHI_XC2VP50:
            Rows = 88;
            Cols = 70;
            BramCols = 12;
            break;
        case XHI_XC2VP70:
            Rows = 104;
            Cols = 82;
            BramCols = 14;
            break;
        case XHI_XC2VP100:
            Rows = 120;
            Cols = 94;
            BramCols = 16;
            break;
        case XHI_XC2VP125:
            Rows = 136;
            Cols = 106;
            BramCols = 18;
            break;
        case XHI_XC4VLX15:     //24,  64,  3,  1, 3, 0, 4
            Cols = 24;
            Rows = 64;
            BramCols = 3;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 4;
            SkipCols = XHI_XC4VLX15_SKIP_COLS;
            break;
        case XHI_XC4VLX25:  //28,  96,  3,  1, 3, 0, 6
            Cols = 28;
            Rows = 96;
            BramCols = 3;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 6;
            SkipCols = XHI_XC4VLX25_SKIP_COLS;
            break;
        case XHI_XC4VLX40:   //36,  128, 3,  1, 3, 0, 8
            Cols = 36;
            Rows = 128;
            BramCols = 3;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 8;
            SkipCols = XHI_XC4VLX40_SKIP_COLS;
            break;
        case XHI_XC4VLX60:   //52,  128, 5,  1, 3, 0, 8
            Cols = 52;
            Rows = 128;
            BramCols = 5;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 8;
            SkipCols = XHI_XC4VLX60_SKIP_COLS;
            break;
        case XHI_XC4VLX80:   //56,  160, 5,  1, 3, 0, 10
            Cols = 56;
            Rows = 160;
            BramCols = 5;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 10;
            SkipCols = XHI_XC4VLX80_SKIP_COLS;
            break;
        case XHI_XC4VLX100:  //64,  192, 5,  1, 3, 0, 12
            Cols = 64;
            Rows = 192;
            BramCols = 5;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 12;
            SkipCols = XHI_XC4VLX100_SKIP_COLS;
            break;
        case XHI_XC4VLX160:   //88,  192, 6,  1, 3, 0, 12
            Cols = 88;
            Rows = 192;
            BramCols = 6;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 12;
            SkipCols = XHI_XC4VLX160_SKIP_COLS;
            break;
        case XHI_XC4VLX200:   //116, 192, 7,  1, 3, 0, 12
            Cols = 116;
            Rows = 192;
            BramCols = 7;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 12;
            SkipCols = XHI_XC4VLX200_SKIP_COLS;
            break;

        case XHI_XC4VSX25:    //40,  64,  8,  4, 3, 0, 4
            Cols = 40;
            Rows = 64;
            BramCols = 8;
            DSPCols = 4;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 4;
            SkipCols = XHI_XC4VSX25_SKIP_COLS;
            break;
        case XHI_XC4VSX35:    //40,  96,  8,  4, 3, 0, 6
            Cols = 40;
            Rows = 96;
            BramCols = 8;
            DSPCols = 4;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 6;
            SkipCols = XHI_XC4VSX35_SKIP_COLS;
            break;
        case XHI_XC4VSX55:    //48,  128, 10, 8, 3, 0, 8
            Cols = 48;
            Rows = 128;
            BramCols = 10;
            DSPCols = 8;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 8;
            SkipCols = XHI_XC4VSX55_SKIP_COLS;
            break;

        case XHI_XC4VFX12:    //24,  64,  3,  1, 3, 0, 4
            Cols = 24;
            Rows = 64;
            BramCols = 3;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 0;
            HClkRows = 4;
            SkipCols = XHI_XC4VFX12_SKIP_COLS;
            break;
        case XHI_XC4VFX20:    //36,  64,  5,  1, 3, 2, 4
            Cols = 36;
            Rows = 64;
            BramCols = 5;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 2;
            HClkRows = 4;
            SkipCols = XHI_XC4VFX20_SKIP_COLS;
            break;
        case XHI_XC4VFX40:   //44,  96,  7,  1, 3, 2, 6
            Cols = 52;
            Rows = 96;
            BramCols = 7;
            DSPCols = 1;
            IOCols = 3;
            MGTCols = 2;
            HClkRows = 6;
            SkipCols = XHI_XC4VFX40_SKIP_COLS;
            break;
        case XHI_XC4VFX60:   //52,  128, 8,  2, 3, 2, 8
            Cols = 52;
            Rows = 128;
            BramCols = 8;
            DSPCols = 2;
            IOCols = 3;
            MGTCols = 2;
            HClkRows = 8;
            SkipCols = XHI_XC4VFX60_SKIP_COLS;
            break;
        case XHI_XC4VFX100:  //68,  160, 10, 2, 3, 2, 10
            Cols = 68;
            Rows = 160;
            BramCols = 10;
            DSPCols = 2;
            IOCols = 3;
            MGTCols = 2;
            HClkRows = 10;
            SkipCols = XHI_XC4VFX100_SKIP_COLS;
            break;
        case XHI_XC4VFX140:   //84,  192, 12, 2, 3, 2, 12
            Cols = 84;
            Rows = 192;
            BramCols = 12;
            DSPCols = 2;
            IOCols = 3;
            MGTCols = 2;
            HClkRows = 12;
            SkipCols = XHI_XC4VFX140_SKIP_COLS;
            break;
        default :
             return XST_INVALID_PARAM;
         break;
    }

    InstancePtr->DeviceId = DeviceId;
    InstancePtr->DeviceIdCode = DeviceIdCode;

    InstancePtr->Rows = Rows;
    InstancePtr->Cols = Cols;
    InstancePtr->BramCols = BramCols;

    InstancePtr->DSPCols = DSPCols;
    InstancePtr->IOCols = IOCols;
    InstancePtr->MGTCols = MGTCols;

    InstancePtr->HClkRows = HClkRows;
    InstancePtr->SkipCols = SkipCols;

#if XHI_FAMILY == XHI_DEV_FAMILY_V4 /* Virtex4 */
    InstancePtr->BytesPerFrame = 164;
#else /* Virtex2 and Virtex2Pro */
    InstancePtr->BytesPerFrame = ((96*2+80*Rows)/8);
#endif
    InstancePtr->WordsPerFrame = (InstancePtr->BytesPerFrame/4);
    InstancePtr->ClbBlockFrames = (4 +22*2 + 4*2 + 22*Cols);
    InstancePtr->BramBlockFrames = (64*BramCols);
    InstancePtr->BramIntBlockFrames = (22*BramCols);

    InstancePtr->IsReady = XCOMPONENT_IS_READY;

    return XST_SUCCESS;
} /* end XHwIcap_Initialize() */

/****************************************************************************/
/**
*
* Stores data in the storage buffer at the specified address.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Address - bram word address
* @param    Data - data to be stored at address
*
* @return   None.
*
* @note     None.
*
*****************************************************************************/
void XHwIcap_StorageBufferWrite(XHwIcap *InstancePtr, Xuint32 Address,
                                Xuint32 Data)
{
    /*
     * Assert validates the input arguments
     */
    XASSERT_VOID(InstancePtr != XNULL);
    XASSERT_VOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* Check range of address. */
    XASSERT_VOID(Address<XHI_MAX_BUFFER_INTS);

    /* Write data to storage buffer. */
    XHwIcap_mSetBram(InstancePtr->BaseAddress, Address, Data);

}

/****************************************************************************/
/**
*
* Read data from the specified address in the storage buffer..
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Address - bram word address
* @return   Data.
*
* @note     None.
*
*****************************************************************************/
Xuint32 XHwIcap_StorageBufferRead(XHwIcap *InstancePtr, Xuint32 Address)
{
    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* Check range of address. */
    XASSERT_NONVOID(Address<XHI_MAX_BUFFER_INTS);

    /* Read data from address. Multiply Address by 4 since 4 bytes per
     * word.*/
    return XHwIcap_mGetBram(InstancePtr->BaseAddress, Address);
}

/****************************************************************************/
/**
*
* Reads bytes from the device (ICAP) and puts it in the storage buffer.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Offset - The storage buffer start address.
* @param    NumInts - The number of words (32 bit) to read from the
*           device (ICAP).
*
* @return   XStatus - XST_SUCCESS or XST_DEVICE_BUSY or XST_INVALID_PARAM
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_DeviceRead(XHwIcap *InstancePtr, Xuint32 Offset,
                           Xuint32 NumInts)

{

    Xint32 Retries = 0;

    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* Check range of address. */
    XASSERT_NONVOID((Offset+NumInts)<=XHI_MAX_BUFFER_INTS);

    if ((Offset+NumInts)<=XHI_MAX_BUFFER_INTS)
    {
        /* setSize NumInts*4 to get bytes. */
        XHwIcap_mSetSizeReg((InstancePtr->BaseAddress),(NumInts<<2));
        XHwIcap_mSetOffsetReg((InstancePtr->BaseAddress), Offset);
        XHwIcap_mSetRncReg((InstancePtr->BaseAddress), XHI_READBACK);

        while (XHwIcap_mGetDoneReg(InstancePtr->BaseAddress)==XHI_NOT_FINISHED)
        {
            Retries++;
            if (Retries > XHI_MAX_RETRIES)
            {
                return XST_DEVICE_BUSY;
            }
        }
    } else
    {
        return XST_INVALID_PARAM;
    }
    return XST_SUCCESS;

};


/****************************************************************************/
/**
*
* Writes bytes from the storage buffer and puts it in the device (ICAP).
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
* @param    Offset - The storage buffer start address.
* @param    NumInts - The number of words (32 bit) to read from the
*           device (ICAP).
*
* @return   XStatus - XST_SUCCESS or XST_DEVICE_BUSY or XST_INVALID_PARAM
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_DeviceWrite(XHwIcap *InstancePtr, Xuint32 Offset,
                            Xuint32 NumInts)
{

    Xint32 Retries = 0;

    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* Check range of address. */
    XASSERT_NONVOID((Offset+NumInts)<=XHI_MAX_BUFFER_INTS);

    if ((Offset+NumInts)<=XHI_MAX_BUFFER_INTS)
    {
        /* setSize NumInts*4 to get bytes.  */
        XHwIcap_mSetSizeReg((InstancePtr->BaseAddress),NumInts<<2);
        XHwIcap_mSetOffsetReg((InstancePtr->BaseAddress), Offset);
        XHwIcap_mSetRncReg((InstancePtr->BaseAddress), XHI_CONFIGURE);

        while (XHwIcap_mGetDoneReg(InstancePtr->BaseAddress)==XHI_NOT_FINISHED)
        {
            Retries++;
            if (Retries > XHI_MAX_RETRIES)
            {
                return XST_DEVICE_BUSY;
            }
        }
    } else
    {
        return XST_INVALID_PARAM;
    }
    return XST_SUCCESS;

};


/****************************************************************************/
/**
*
* Sends a DESYNC command to the ICAP port.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
*
* @return   XStatus - XST_SUCCESS or XST_DEVICE_BUSY or XST_INVALID_PARAM
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_CommandDesync(XHwIcap *InstancePtr)
{
    XStatus Status;

    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    XHwIcap_StorageBufferWrite(InstancePtr, 0,
                        (XHwIcap_Type1Write(XHI_CMD) | 1));
    XHwIcap_StorageBufferWrite(InstancePtr, 1, XHI_CMD_DESYNCH);
    XHwIcap_StorageBufferWrite(InstancePtr, 2, XHI_DUMMY_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 3, XHI_DUMMY_PACKET);
    Status = XHwIcap_DeviceWrite(InstancePtr, 0, 4);  /* send four words */

    XASSERT_NONVOID(Status == XST_SUCCESS);

    return Status;
}

/****************************************************************************/
/**
*
* Sends a CAPTURE command to the ICAP port.  This command caputres all
* of the flip flop states so they will be available during readback.
* One can use this command instead of enabling the CAPTURE block in the
* design.
*
* @param    InstancePtr - a pointer to the XHwIcap instance to be worked on.
*
* @return   XStatus - XST_SUCCESS or XST_DEVICE_BUSY or XST_INVALID_PARAM
*
* @note     None.
*
*****************************************************************************/
XStatus XHwIcap_CommandCapture(XHwIcap *InstancePtr)
{
    XStatus Status;

    /*
     * Assert validates the input arguments
     */
    XASSERT_NONVOID(InstancePtr != XNULL);
    XASSERT_NONVOID(InstancePtr->IsReady == XCOMPONENT_IS_READY);

    /* DUMMY and SYNC */
    XHwIcap_StorageBufferWrite(InstancePtr, 0, XHI_DUMMY_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 1, XHI_SYNC_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 2,
                        (XHwIcap_Type1Write(XHI_CMD) | 1));
    XHwIcap_StorageBufferWrite(InstancePtr, 3, XHI_CMD_GCAPTURE);
    XHwIcap_StorageBufferWrite(InstancePtr, 4, XHI_DUMMY_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 5, XHI_DUMMY_PACKET);
    Status = XHwIcap_DeviceWrite(InstancePtr, 0, 6);  /* send six words */

    XASSERT_NONVOID(Status == XST_SUCCESS);

    return Status;
}

/****************************************************************************/
/**
 *
 * This function returns the value of the specified configuration
 * register.
 *
 * @param    InstancePtr - a pointer to the XHwIcap instance to be worked
 *           on.
 * @param    ConfigReg  - A constant which represents the configuration
 *           register value to be returned. Constants specified in xhwicap_i.h.
 * 	     Examples:  XHI_IDCODE, XHI_FLR.
 *
 * @return   The value of the specified configuration register.
 *
 *****************************************************************************/

Xuint32 XHwIcap_GetConfigReg(XHwIcap *InstancePtr, Xuint32 ConfigReg)
{
    Xuint32 Packet;
    XStatus Status;

    /* Write bitstream to bram */
    Packet = XHwIcap_Type1Read(ConfigReg) | 1;
    XHwIcap_StorageBufferWrite(InstancePtr, 0, XHI_DUMMY_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 1, XHI_SYNC_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 2, Packet);
    XHwIcap_StorageBufferWrite(InstancePtr, 3, XHI_NOOP_PACKET);
    XHwIcap_StorageBufferWrite(InstancePtr, 4, XHI_NOOP_PACKET);

    /* Transfer Bitstream from Bram to ICAP */
    Status = XHwIcap_DeviceWrite(InstancePtr, 0, 5);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

    /* Now readback one word into bram position
     * XHI_EX_BITSTREAM_LENGTH*/
    Status = XHwIcap_DeviceRead(InstancePtr, 5, 1);
    if (Status != XST_SUCCESS)
    {
        return Status;
    }

    /* Return the Register value */
    return XHwIcap_StorageBufferRead(InstancePtr, 5);
}


/****************************************************************************
*
* Looks up the device configuration based on the unique device ID.  The table
* HwIcapConfigTable contains the configuration info for each device in the
* system.
*
* @param DeviceId is the unique device ID to match on.
*
* @return
*
* A pointer to the configuration data for the device, or XNULL if no match
* was found.
*
* @note    None.
*
******************************************************************************/
XHwIcap_Config *XHwIcap_LookupConfig(Xuint16 DeviceId)
{
    XHwIcap_Config *CfgPtr = XNULL;
    int i;

    for (i=0; i < XPAR_XHWICAP_NUM_INSTANCES; i++)
    {
        if (XHwIcap_ConfigTable[i].DeviceId == DeviceId)
        {
            CfgPtr = &XHwIcap_ConfigTable[i];
            break;
        }
    }

    return CfgPtr;
}


