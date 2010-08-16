/* $Id: xbuf_descriptor.c,v 1.1 2005/11/28 19:08:12 meinelte Exp $ */
/******************************************************************************
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
*       (c) Copyright 2001-2004 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xbuf_descriptor.c
*
* <b>Description</b>
*
* This file contains all processing for the buffer descriptor component.
* The buffer descriptor component is a passive component that only maps over
* a buffer descriptor data structure shared by the scatter gather DMA hardware
* and software. The component's primary purpose is to provide encapsulation of
* the buffer descriptor processing.
*
* A buffer descriptor is used by a DMA channel in scatter gather mode.  It
* describes a buffer which is to be transferred to or from a device.
* The processing is not implemented as a structure, but the following structure
* illustrates an example of a buffer descriptor.
*
*   struct
*   {
*       Xuint32 Control;
*       Xuint32 SourceAddress;
*       Xuint32 DestinationAddress;
*       Xuint32 Length;
*       Xuint32 Status;
*       Xuint32 DeviceStatus
*       Xuint32 NextPtr;
*       Xuint32 Id;
*       Xuint32 Flags;
*       Xuint32 RequestedLength;
*   }
*
* The control, source address, destination address, and length fields are
* copied into the respective registers of the DMA channel by the DMA channel
* when a buffer descriptor is processed.  Upon completion of processing for
* the buffer descriptor, the DMA channel copies it's status register and the
* device specific register back into the buffer descriptor.  These fields are
* used for interrupt processing by the device driver for the device.
*
* The buffer descriptor is tightly coupled with the DMA channel component
* since many of the fields of the buffer descriptor are put into or retrieved
* from the registers of a DMA channel.
*
* Some of the fields of a buffer descriptor are for software use only, such as
* the ID, flags, and requested length fields. The ID field is provided to
* allow a device driver to correlate the buffer descriptor to other data
* structures which may be operating system specific, such as a pointer to
* a higher level memory block.  The flags field currently only contains the
* locked flag.
*
* A buffer descriptor may be locked when it is retrieved from a scatter list.
* The affect of the lock is described in the DMA channel component. The buffer
* descriptor is unlocked at a later time when the buffer which the buffer
* descriptor points to has been completely processed.
*
* The requested length field allows the actual length of the DMA operation
* to be determined after it is complete.  The length field of the buffer
* descriptor is updated by the DMA channel hardware to indicate the number of
* bytes left to transfer.  The requested length field contains the original
* requested length such that the length field may be subtracted from it to
* get the actual length transferred.
*
* The buffer descriptor component is utilized together with a DMA channel.
* The DMA channel determines the restrictions which apply to the buffers
* pointed to by a buffer descriptor, such as alignment and caching.
*
* @note
*
* Most of the functions of this component are implemented as macros in order
* to optimize the processing.  Buffer descriptors are typically used heavily
* in an interrupt context such that execution time is critical.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a xd   10/27/04 Doxygenated for inclusion in API documentation
* 1.00b ecm  10/31/05 Updated for the check sum offload changes.
* </pre>
*
******************************************************************************/


/***************************** Include Files *********************************/

#include "xbuf_descriptor.h"

/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/
