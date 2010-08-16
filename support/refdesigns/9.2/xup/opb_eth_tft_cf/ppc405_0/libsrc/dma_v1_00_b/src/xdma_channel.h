/* $Id: xdma_channel.h,v 1.6 2006/07/18 17:56:33 xduan Exp $ */
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
* @file xdma_channel.h
*
* <b>Description</b>
*
* This file contains the DMA channel component implementation. This component
* supports a distributed DMA design in which each device can have it's own
* dedicated DMA channel, as opposed to a centralized DMA design.
* A device which uses DMA typically contains two DMA channels, one for
* sending data and the other for receiving data.
*
* This component is designed to be used as a basic building block for
* designing a device driver. It provides registers accesses such that all
* DMA processing can be maintained easier, but the device driver designer
* must still understand all the details of the DMA channel.
*
* The DMA channel allows a CPU to minimize the CPU interaction required to move
* data between a memory and a device.  The CPU requests the DMA channel to
* perform a DMA operation and typically continues performing other processing
* until the DMA operation completes.  DMA could be considered a primitive form
* of multiprocessing such that caching and address translation can be an issue.
*
* <b>Scatter Gather Operations</b>
*
* The DMA channel may support scatter gather operations. A scatter gather
* operation automates the DMA channel such that multiple buffers can be
* sent or received with minimal software interaction with the hardware.  Buffer
* descriptors, contained in the XBufDescriptor component, are used by the
* scatter gather operations of the DMA channel to describe the buffers to be
* processed.
*
* <b>Scatter Gather List Operations</b>
*
* A scatter gather list may be supported by each DMA channel.  The scatter
* gather list allows buffer descriptors to be put into the list by a device
* driver which requires scatter gather.  The hardware processes the buffer
* descriptors which are contained in the list and modifies the buffer
* descriptors to reflect the status of the DMA operations.  The device driver
* is notified by interrupt that specific DMA events occur including scatter
* gather events.  The device driver removes the completed buffer descriptors
* from the scatter gather list to evaluate the status of each DMA operation.
*
* The scatter gather list is created and buffer descriptors are inserted into
* the list.  Buffer descriptors are never removed from the list after it's
* creation such that a put operation copies from a temporary buffer descriptor
* to a buffer descriptor in the list.  Get operations don't copy from the list
* to a temporary, but return a pointer to the buffer descriptor in the list.
* A buffer descriptor in the list may be locked to prevent it from being
* overwritten by a put operation.  This allows the device driver to get a
* descriptor from a scatter gather list and prevent it from being overwritten
* until the buffer associated with the buffer descriptor has been processed.
*
* <b>Typical Scatter Gather Processing</b>
*
* The following steps illustrate the typical processing to use the
* scatter gather features of a DMA channel.
*
* 1. Create a scatter gather list for the DMA channel which puts empty buffer
*    descriptors into the list.<br>
* 2. Create buffer descriptors which describe the buffers to be filled with
*       receive data or the buffers which contain data to be sent.<br>
* 3. Put buffer descriptors into the DMA channel scatter list such that scatter
*    gather operations are requested.<br>
* 4. Commit the buffer descriptors in the list such that they are ready to be
*    used by the DMA channel hardware.<br>
* 5. Start the scatter gather operations of the DMA channel.<br>
* 6. Process any interrupts which occur as a result of the scatter gather
*    operations or poll the DMA channel to determine the status.
*
* <b>Interrupts</b>
*
* Each DMA channel has the ability to generate an interrupt.  This component
* does not perform processing for the interrupt as this processing is typically
* tightly coupled with the device which is using the DMA channel.  It is the
* responsibility of the caller of DMA functions to manage the interrupt
* including connecting to the interrupt and enabling/disabling the interrupt.
*
* <b>Critical Sections</b>
*
* It is the responsibility of the device driver designer to use critical
* sections as necessary when calling functions of the DMA channel.  This
* component does not use critical sections and it does access registers using
* read-modify-write operations.  Calls to DMA functions from a main thread
* and from an interrupt context could produce unpredictable behavior such that
* the caller must provide the appropriate critical sections.
*
* <b>Address Translation</b>
*
* All addresses of data structures which are passed to DMA functions must
* be physical (real) addresses as opposed to logical (virtual) addresses.
*
* <b>Caching</b>
*
* The memory which is passed to the function which creates the scatter gather
* list must not be cached such that buffer descriptors are non-cached.  This
* is necessary because the buffer descriptors are kept in a ring buffer and
* not directly accessible to the caller of DMA functions.
*
* The caller of DMA functions is responsible for ensuring that any data
* buffers which are passed to the DMA channel are cache-line aligned if
* necessary.
*
* The caller of DMA functions is responsible for ensuring that any data
* buffers which are passed to the DMA channel have been flushed from the cache.
*
* The caller of DMA functions is responsible for ensuring that the cache is
* invalidated prior to using any data buffers which are the result of a DMA
* operation.
*
* <b>Memory Alignment</b>
*
* The addresses of data buffers which are passed to DMA functions must be
* 32 bit word aligned since the DMA hardware performs 32 bit word transfers.
*
* <b>Mutual Exclusion</b>
*
* The functions of the DMA channel are not thread safe such that the caller
* of all DMA functions is responsible for ensuring mutual exclusion for a
* DMA channel.  Mutual exclusion across multiple DMA channels is not
* necessary.
*
* @note
*
* Many of the provided functions which are register accessors don't provide
* a lot of error detection. The caller is expected to understand the impact
* of a function call based upon the current state of the DMA channel.  This
* is done to minimize the overhead in this component.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a xd   10/27/04 Doxygenated for inclusion in API documentation
* 1.00b ecm  10/31/05 Updated for the check sum offload changes.
* 1.00b xd   03/22/06 Fixed a multi-descriptor packet related bug that sgdma
*                     engine is restarted in case no scatter gather disabled
*                     bit is set yet
* </pre>
*
******************************************************************************/

#ifndef XDMA_CHANNEL_H    /* prevent circular inclusions */
#define XDMA_CHANNEL_H    /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xversion.h"
#include "xbuf_descriptor.h"
#include "xdma_channel_i.h"     /* constants shared with buffer descriptor */

/************************** Constant Definitions *****************************/

/** @name DMA control register bit fields
 *
 * the following constants provide access to the bit fields of the DMA control
 * register (DMACR)
 * @{
 */
#define XDC_DMACR_SOURCE_INCR_MASK   0x80000000UL /**< increment source address */
#define XDC_DMACR_DEST_INCR_MASK     0x40000000UL /**< increment dest address */
#define XDC_DMACR_SOURCE_LOCAL_MASK  0x20000000UL /**< local source address */
#define XDC_DMACR_DEST_LOCAL_MASK    0x10000000UL /**< local dest address */
#define XDC_DMACR_SG_DISABLE_MASK    0x08000000UL /**< scatter gather disable */
#define XDC_DMACR_GEN_BD_INTR_MASK   0x04000000UL /**< descriptor interrupt */
#define XDC_DMACR_LAST_BD_MASK       XDC_CONTROL_LAST_BD_MASK /**< last buffer
                                                                   descriptor */
#define XDC_DMACR_DRE_MODE_MASK      0x01000000UL /**< DRE/normal mode */

#define XDC_DMACR_TX_CS_INIT_MASK    0x0000FFFFUL /**< Initial value for TX
                                                       CS offload */
#define XDC_DMACR_CS_OFFLOAD_MASK    0x00800000UL /**< Enable CS offload */
/* @} */

/** @name DMA status register bit fields
 *
 * the following constants provide access to the bit fields of the DMA status
 * register (DMASR)
 * @{
 */
#define XDC_DMASR_BUSY_MASK          0x80000000UL /**< channel is busy */
#define XDC_DMASR_BUS_ERROR_MASK     0x40000000UL /**< bus error occurred */
#define XDC_DMASR_BUS_TIMEOUT_MASK   0x20000000UL /**< bus timeout occurred */
#define XDC_DMASR_LAST_BD_MASK       XDC_STATUS_LAST_BD_MASK /**< last buffer
                                                                  descriptor */
#define XDC_DMASR_SG_BUSY_MASK       0x08000000UL /**< scatter gather is busy */

#define XDC_DMACR_RX_CS_RAW_MASK     0xFFFF0000UL /**< RAW CS value for RX data */
/* @} */

/** @name DMA destination address register bit fields when checksum offload is
 * used
 *
 * the following constants provide access to the bit fields of the
 * Destination Address Register (DAREG)
 * @{
 */
#define XDC_DAREG_CS_BEGIN_MASK      0xFFFF0000UL /**< byte position to begin
                                                       checksum calculation*/
#define XDC_DAREG_CS_INSERT_MASK     0x0000FFFFUL /**< byte position to place
                                                       calculated checksum */
/** @name Interrupt Status/Enable Register bit fields
 *
 * the following constants provide access to the bit fields of the interrupt
 * status register (ISR) and the interrupt enable register (IER), bit masks
 * match for both registers such that they are named IXR
 * @{
 */
#define XDC_IXR_DMA_DONE_MASK       0x1UL  /**< dma operation done */
#define XDC_IXR_DMA_ERROR_MASK      0x2UL  /**< dma operation error */
#define XDC_IXR_PKT_DONE_MASK       0x4UL  /**< packet done */
#define XDC_IXR_PKT_THRESHOLD_MASK  0x8UL  /**< packet count threshold */
#define XDC_IXR_PKT_WAIT_BOUND_MASK 0x10UL /**< packet wait bound reached */
#define XDC_IXR_SG_DISABLE_ACK_MASK 0x20UL /**< scatter gather disable
                                                acknowledge occurred */
#define XDC_IXR_SG_END_MASK         0x40UL /**< last buffer descriptor
                                                disabled scatter gather */
#define XDC_IXR_BD_MASK             0x80UL /**< buffer descriptor done */
/* @} */

/**************************** Type Definitions *******************************/

/**
 * the following structure contains data which is on a per instance basis
 * for the XDmaChannel component
 */
typedef struct XDmaChannelTag
{
    XVersion Version;               /**< version of the driver */
    Xuint32 RegBaseAddress;         /**< base address of registers */
    Xuint32 IsReady;                /**< device is initialized and ready */

    XBufDescriptor *PutPtr;         /**< keep track of where to put into list */
    XBufDescriptor *GetPtr;         /**< keep track of where to get from list */
    XBufDescriptor *CommitPtr;      /**< keep track of where to commit in list */
    XBufDescriptor *LastPtr;        /**< keep track of the last put in the list */
    Xuint32 TotalDescriptorCount;   /**< total # of descriptors in the list */
    Xuint32 ActiveDescriptorCount;  /**< # of descriptors pointing to buffers
                                         in the buffer descriptor list */
    Xuint32 ActivePacketCount;      /**< # of packets that have been put into
                                         the list and transmission confirmation
                                         have not been received by the driver */
    Xboolean Committed;             /**< CommitPuts is called? */

} XDmaChannel;

/***************** Macros (Inline Functions) Definitions *********************/


/************************** Function Prototypes ******************************/

/**
 * Standard functions
 */
XStatus XDmaChannel_Initialize(XDmaChannel *InstancePtr,
                               Xuint32 BaseAddress);
Xboolean XDmaChannel_IsReady(XDmaChannel *InstancePtr);
XVersion *XDmaChannel_GetVersion(XDmaChannel *InstancePtr);
XStatus XDmaChannel_SelfTest(XDmaChannel *InstancePtr);
void XDmaChannel_Reset(XDmaChannel *InstancePtr);

/**
 * Control functions
 */
Xuint32 XDmaChannel_GetControl(XDmaChannel *InstancePtr);
void XDmaChannel_SetControl(XDmaChannel *InstancePtr, Xuint32 Control);

/**
 * Status functions
 */
Xuint32 XDmaChannel_GetStatus(XDmaChannel *InstancePtr);
void XDmaChannel_SetIntrStatus(XDmaChannel *InstancePtr, Xuint32 Status);
Xuint32 XDmaChannel_GetIntrStatus(XDmaChannel *InstancePtr);
void XDmaChannel_SetIntrEnable(XDmaChannel *InstancePtr, Xuint32 Enable);
Xuint32 XDmaChannel_GetIntrEnable(XDmaChannel *InstancePtr);

/**
 * DMA without scatter gather functions
 */
void XDmaChannel_Transfer(XDmaChannel *InstancePtr,
                          Xuint32 *SourcePtr,
                          Xuint32 *DestinationPtr,
                          Xuint32 ByteCount);

/**
 * Scatter gather functions
 */
XStatus XDmaChannel_SgStart(XDmaChannel *InstancePtr);
XStatus XDmaChannel_SgStop(XDmaChannel *InstancePtr,
                           XBufDescriptor **BufDescriptorPtr);
XStatus XDmaChannel_CreateSgList(XDmaChannel *InstancePtr,
                                 Xuint32 *MemoryPtr,
                                 Xuint32 ByteCount);
Xboolean XDmaChannel_IsSgListEmpty(XDmaChannel *InstancePtr);

XStatus XDmaChannel_PutDescriptor(XDmaChannel *InstancePtr,
                                  XBufDescriptor *BufDescriptorPtr);
XStatus XDmaChannel_CommitPuts(XDmaChannel *InstancePtr);
XStatus XDmaChannel_GetDescriptor(XDmaChannel *InstancePtr,
                                  XBufDescriptor** BufDescriptorPtr);

/**
 * Packet functions for interrupt coalescing
 */
Xuint32 XDmaChannel_GetPktCount(XDmaChannel *InstancePtr);
void XDmaChannel_DecrementPktCount(XDmaChannel *InstancePtr);
XStatus XDmaChannel_SetPktThreshold(XDmaChannel *InstancePtr,
                                    Xuint8 Threshold);
Xuint8 XDmaChannel_GetPktThreshold(XDmaChannel *InstancePtr);
void XDmaChannel_SetPktWaitBound(XDmaChannel *InstancePtr,
                                 Xuint32 WaitBound);
Xuint32 XDmaChannel_GetPktWaitBound(XDmaChannel *InstancePtr);


#ifdef __cplusplus
}
#endif

#endif              /* end of protection macro */
