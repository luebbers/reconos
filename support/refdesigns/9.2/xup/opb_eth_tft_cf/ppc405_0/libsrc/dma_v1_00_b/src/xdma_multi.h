/* $Id: xdma_multi.h,v 1.2 2006/06/02 21:43:44 meinelte Exp $ */
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
*       (c) Copyright 2003-2004 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xdma_multi.h
*
* <b>Description</b>
*
* This file contains the multichannel DMA  implementation. This component
* supports a channelized DMA design in which each device can have it's own
* dedicated multichannel DMA, as opposed to a centralized DMA design.
* A device which uses DMA typically contains at least two channels of DMA,
* one for sending data and the other for receiving data.
*
* This component is designed to be used as a basic building block for
* designing a device driver. It provides register accesses such that all
* DMA processing can be maintained easier, but the device driver designer
* must still understand all the details of the multichannel DMA.
*
* The multichannel DMA allows a CPU to minimize the CPU interaction required
* to move data between a memory and a device.  The CPU requests the DMA hardware
* to perform a DMA operation and typically continues performing other
* processing until the DMA operation completes.  DMA could be considered a
* primitive form of multiprocessing such that caching and address translation
* can be an issue.
*
* <b>Scatter Gather Operations</b>
*
* The multichannel DMA may support scatter gather operations. A scatter gather
* operation automates the DMA operation such that multiple buffers can be
* sent or received with minimal software interaction with the hardware.  Buffer
* descriptors, contained in the XBufDescriptor component, are used by the
* scatter gather operations of the multichannel DMA to describe the buffers to be
* processed.
*
* <b>Scatter Gather List Operations</b>
*
* A scatter gather list may be supported by each channel of DMA.  The scatter
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
* scatter gather features of a multichannel DMA.
*
* 1. Create a scatter gather list for the each channel of DMA which puts empty
*    buffer descriptors into the list.<br>
* 2. Create buffer descriptors which describe the buffers to be filled with
*    receive data or the buffers which contain data to be sent.<br>
* 3. Put buffer descriptors into the multichannel DMA scatter list such that scatter
*    gather operations are requested.<br>
* 4. Commit the buffer descriptors in the list such that they are ready to be
*    used by the multichannel DMA hardware.<br>
* 5. Start the scatter gather operations of the multichannel DMA.<br>
* 6. Process any interrupts which occur as a result of the scatter gather
*    operations or poll the each channel of DMA to determine the status.
*
* <b>Interrupts</b>
*
* Each channel of the DMA has the ability to generate an interrupt.  This component
* does not perform processing for the interrupt as this processing is typically
* tightly coupled with the device which is using the multichannel DMA.  It is the
* responsibility of the caller of DMA functions to manage the interrupt
* including connecting to the interrupt and enabling/disabling the interrupt.
*
* <b>Critical Sections</b>
*
* It is the responsibility of the device driver designer to use critical
* sections as necessary when calling functions of the multichannel DMA.  This
* component does not protect critical sections and it does access registers using
* read-modify-write operations.  Calls to DMA functions from a main thread
* and from an interrupt context could produce unpredictable behavior such that
* the caller must provide the appropriate protection.
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
* buffers which are passed to the multichannel DMA are cache-line aligned if
* necessary.
*
* The caller of DMA functions is responsible for ensuring that any data
* buffers which are passed to the multichannel DMA have been flushed from the
* cache.
*
* The caller of DMA functions is responsible for ensuring that the cache is
* invalidated prior to using any data buffers which are the result of a DMA
* operation.
*
* <b>Memory Alignment</b>
*
* The addresses of data buffers which are passed to DMA functions must be
* 32 bit word aligned if the peripheral is on the OPB bus and must be
* 64-bit word aligned if the peripheral is on the PLB bus since the DMA
* hardware performs bus width word transfers. The alignment of the provided
* buffers is not checked by the driver.
*
* <b>Mutual Exclusion</b>
*
* The functions of the multichannel DMA are not thread safe such that the caller
* of all DMA functions is responsible for ensuring mutual exclusion for each
* channel of DMA.  Mutual exclusion across multiple instances of the
* multichannel DMAs is not necessary.
*
* <b>Asserts</b>
*
* Asserts are used within all Xilinx drivers to enforce constraints on argument
* values. Asserts can be turned off on a system-wide basis by defining, at compile
* time, the NDEBUG identifier.  By default, asserts are turned on and it is
* recommended that application developers leave asserts on during development.
*
* @note
*
* Many of the provided functions which are register accessors don't provide
* a lot of error detection. The caller is expected to understand the impact
* of a function call based upon the current state of the multichannel DMA.  This
* is done to minimize the overhead in this component.
* <br><br>
* In the following diagram, arrows are used to illustrate addresses or pointers
* such that this diagram is aimed for illustration purposes rather than a literal
* implementation.
* <br><br>
* The user memory block is passed in and used by the device driver. The user
* memory is partitioned into two parts with the 1st part being a table of
* addresses (indexed by the channel number) which contains the address of each
* channels registers.  The 2nd part of the memory is a table of structures
* (indexed by the channel number) which contains the scatter gather data for
* each channel.

* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ecm  09/16/03 First release
* 1.00a xd   10/27/04 Doxygenated for inclusion in API documentation
* 1.00b ecm  10/31/05 Updated for the check sum offload changes.
* </pre>
*
* @internal
*
* Diagram of memory allocation and usage
*
*
*     XDmaMulti
*     Instance                                           DMA Hardware
*  -------------------                                   -----------
* |  BaseAddress      |-------------------------------->|           |
* |                   |            User Memory          |  device   |
* |-------------------|         -----------------       | registers |
* |  AddrTablePtr     |-----|  |                 |      |-----------|
* |                   |     |  |    Channel      |      |           |
* |-------------------|     |  |    Address      |      |  channel  |
* |  SgDataTablePtr   |---| |  |    Table        |  |-->|     0     |
* |                   |   | |  |   ----------    |  |   | registers |
*  -------------------    | |---->|channel 0 |------|   |-----------|
*                         |    |  | address  |   |      |           |
*                         |    |  |----------|   |      |  channel  |
*                         |    |  |channel 1 |--------->|     1     |
*                         |    |  | address  |   |      | registers |
*                         |    |   ----------    |       -----------
*                         |    |                 |
*                         |    |    Scatter      |
*                         |    |    Gather       |
*                         |    |    Data Table   |
*                         |    |   ----------    |
*                         |------>| sg data  |   |
*                              |  |channel 0 |   |
*                              |  |----------|   |
*                              |  | sg data  |   |
*                              |  |channel 1 |   |
*                              |   ----------    |
*                               -----------------
*
*******************************************************************************/

#ifndef XDMA_MULTI_H    /* prevent circular inclusions */
#define XDMA_MULTI_H    /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif


/***************************** Include Files *********************************/

#include "xdma_multi_i.h" /* constants shared with buffer descriptor */
#include "xbasic_types.h"
#include "xstatus.h"
#include "xbuf_descriptor.h"

/************************** Constant Definitions *****************************/

#define XDM_CHANNEL_BASE_OFFSET        0x10000   /**< channel base offset */
#define XDM_CHANNEL_OFFSET      0x20  /**< interval spacing of DMA registers */

/** @name DMA Control Register bit fields
 *
 * The following constants provide access to the bit fields of the DMA control
 * register (DMACR).
 * @{
 */
#define XDM_DMACR_SOURCE_INCR_MASK  0x80000000UL /**< increment source address */
#define XDM_DMACR_DEST_INCR_MASK    0x40000000UL /**< increment dest address */
#define XDM_DMACR_SOURCE_LOCAL_MASK 0x20000000UL /**< local source address */
#define XDM_DMACR_DEST_LOCAL_MASK   0x10000000UL /**< local dest address */
#define XDM_DMACR_SG_STOP_MASK      0x08000000UL /**< scatter gather stop */
#define XDM_DMACR_LAST_BD_MASK      XDM_CONTROL_LAST_BD_MASK /**< last buffer
                                                                  descriptor  */
/* @} */

/** @name DMA Status Register bit fields
 *
 * The following constants provide access to the bit fields of the DMA status
 * register (DMASR).
 * @{
 */
#define XDM_DMASR_BUSY_MASK         0x80000000UL /**< Channel is busy */
#define XDM_DMASR_BUS_ERROR_MASK    0x40000000UL /**< Bus error occurred */
#define XDM_DMASR_BUS_TIMEOUT_MASK  0x20000000UL /**< Bus timeout occurred */
#define XDM_DMASR_LAST_BD_MASK      XDM_STATUS_LAST_BD_MASK /**< Last buffer
                                                                 descriptor  */
#define XDM_DMASR_SG_BUSY_MASK      0x08000000UL /**< Scatter gather is busy */
/* @} */

/** @name Software Control Register bit fields
 *
 * The following constants provide access to the bit fields of the Software
 * Control Register(SWCR).
 * @{
 */
#define XDM_SWCR_EESGEND_MASK       0x80000000UL /**< Enable SGEND Event */
#define XDM_SWCR_ESGDA_MASK         0x40000000UL /**< Enable SG Disable Ack Event */
#define XDM_SWCR_EPWBR_MASK         0x20000000UL /**< Enable Pkt Wait Bound Event */
#define XDM_SWCR_EPCTR_MASK         0x10000000UL /**< Enable Count Threshold Event */
#define XDM_SWCR_EPD_MASK           0x08000000UL /**< Enable Pkt Done Event */
#define XDM_SWCR_EDE_MASK           0x04000000UL /**< Enable DMA Error Event */
#define XDM_SWCR_EDD_MASK           0x02000000UL /**< Enable DMA done Event */
#define XDM_SWCR_BDAEL_MASK         0x01000000UL /**< BDA Explicitly Loaded */
#define XDM_SWCR_SGE_MASK           0x00800000UL /**< Enable SG */
#define XDM_SWCR_SGD_MASK           0x00400000UL /**< Disable SG */
#define XDM_SWCR_PWB_MASK           0x000FFC00UL /**< Packet Wait Bound */
#define XDM_SWCR_PCT_MASK           0x000003FFUL /**< Packet Count Threshold */
/* @} */

/** @name Global Control/Status Register bit fields
 *
 * The following constants provide access to the bit fields of the
 * Global Control/Status Register (GCSR).
 * @{
 */
#define XDM_GCSR_GLOBAL_ENABLE_MASK    0x80000000  /**< Global Enable */
#define XDM_GCSR_ENABLE_EFO_MASK       0x00000100  /**< Enable EFIFO overflow */
#define XDM_GCSR_EFO_STATUS_MASK       0x00000001  /**< EFIFO overflow Status */
/* @} */

/** @name Global Event FIFO event bit fields
 *
 * The following constants provide access to the bit fields of the
 * Global Event FIFO events (GEFIFO).
 * @{
 */
#define XDM_GEFIFO_SGEND_MASK      0x80000000  /**< SG Operation Finished Event */
#define XDM_GEFIFO_SGDA_MASK       0x40000000  /**< SG Disable Acknowledge Event */
#define XDM_GEFIFO_PWB_MASK        0x20000000  /**< Packet Wait Bound Event */
#define XDM_GEFIFO_PCT_MASK        0x10000000  /**< Pkt Count Threshold Event */
#define XDM_GEFIFO_PD_MASK         0x08000000  /**< Packet Done Event */
#define XDM_GEFIFO_DE_MASK         0x04000000  /**< DMA Error Event */
#define XDM_GEFIFO_DD_MASK         0x02000000  /**< DMA Done Event */
#define XDM_GEFIFO_CHAN_MASK       0x00FFF000  /**< DMA Channel Event occurred on */
#define XDM_GEFIFO_EVENT_MASK      0x00000FFF  /**< DMA Channel Event Parameter */
#define XDM_GEFIFO_ENABLE_MASK     0xFE000000  /**< DMA Event Bits Mask */

#define XDM_DMA_COMPLETE        (XDM_GEFIFO_SGEND_MASK  |   \
                                 XDM_GEFIFO_SGDA_MASK   |   \
                                 XDM_GEFIFO_PWB_MASK    |   \
                                 XDM_GEFIFO_PCT_MASK    |   \
                                 XDM_GEFIFO_PD_MASK)/*     |   \
                                 XDM_GEFIFO_DD_MASK)*/
/* @} */

/**************************** Type Definitions *******************************/

/**
 * The following structure contains data which is used to maintain the
 * buffer descriptor list.
 */
typedef struct
{
   XBufDescriptor *PutPtr;         /**< Keep track of where to put into list */
   XBufDescriptor *GetPtr;         /**< Keep track of where to get from list */
   XBufDescriptor *CommitPtr;      /**< Keep track of where to commit in list */
   XBufDescriptor *LastPtr;        /**< Keep track of the last put in the list */
   Xuint16 TotalDescriptorCount;    /**< Total # of descriptors in the list */
   Xuint16 ActiveDescriptorCount;   /**< # of descriptors pointing to buffers
                                         in the buffer descriptor list */
} XDmaMulti_SgData;

/**
 * The following structure contains data which is on a per instance basis
 * for the XDmaMulti component.
 */
typedef struct
{
   Xuint32  BaseAddress;        /**< Base address of channels */
   Xuint32  IntrFifoAddress;    /**< Interrupt FIFO address */
   Xuint32  IsReady;            /**< Device is initialized and ready */
   Xuint16  ChannelCount;       /**< Number of DMA channels on device */
   Xuint32 *AddrTablePtr;       /**< Beginning of Register address table */
   XDmaMulti_SgData *SgDataTablePtr; /**< Beginning of SGDMA data structures */
} XDmaMulti;

/**
 * XDmaMulti_mSizeNeeded is used to calculate the amount of memory needed
 * in the _Initialize call.
 * (sizeof(XDmaMulti_SgData) + sizeof(Xuint32)) is the size required for
 * one channel. The first number is the size of the structure needed
 * for each channel and the second is the address pointer table.
 * Transmit and Receive are individual channels, i.e. there are two
 * DMA channels associated with each Full Duplex Peripheral channel.
 */
#define XDM_BYTES_PER_CHANNEL   (sizeof(Xuint32) + sizeof(XDmaMulti_SgData))

/***************** Macros (Inline Functions) Definitions *********************/
/** @name Macro functions
 * @{
 */
/****************************************************************************/
/**
*
* Determine the size needed for the DMA channel structure.
*
* @param    NumChannels is the total number of DMA Channels configured
*           in the hardware.
*
* @return   The size of the structure in bytes. Includes array used
*           for addresses at the beginning of the data.
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mSizeNeeded(Xuint32 NumChannels);
*
*****************************************************************************/
#define XDmaMulti_mSizeNeeded(NumChannels)                                   \
    (Xuint32)((NumChannels) * XDM_BYTES_PER_CHANNEL)

/****************************************************************************/
/**
*
* Read the Global Control Register.
*
* @param    InstancePtr is the instance to be used.
*
* @return   The 32-bit value of the register.
*           <br><br>
* The control register contents of the DMA Hardware. One or more of the
* following values may be contained the register.  Each of the values are
* unique bit masks.See xdma_multi.h for a description of possible
* values. The return values are prefixed with XDM_GCSR_*.*
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetGlobalControl(XDmaMulti *InstancePtr);
*
*****************************************************************************/
#define XDmaMulti_mGetGlobalControl(InstancePtr)                            \
        XIo_In32((InstancePtr)->BaseAddress + XDM_GCSR_REG_OFFSET)

/****************************************************************************/
/**
*
* Write the Global Control Register.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Control is the 32-bit value to write to the register.
*
* @return   None
*           <br><br>
* Write the contents to the DMA Hardware. Use the XDM_GCSR_*
* constants defined in xdma_multi.h to create the bit-mask to be written to
* the register.
*
* @note
*
* C Signature: void XDmaMulti_mSetGlobalControl(XDmaMulti *InstancePtr,
*                                               Xuint32 Control);
*
*****************************************************************************/
#define XDmaMulti_mSetGlobalControl(InstancePtr, Control)                    \
        XIo_Out32((InstancePtr)->BaseAddress + XDM_GCSR_REG_OFFSET, (Control))

/****************************************************************************/
/**
*
* Read the Control Register of the given channel.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @return   The 32-bit value of the register
*           <br><br>
* The control register contents of the DMA channel. One or more of the
* following values may be contained the register. Each of the values are
* unique bit masks.See xdma_multi.h for a description of possible
* values. The return values are prefixed with XDM_DMACR_*.*
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetControl(XDmaMulti *InstancePtr,
*                                            unsigned Channel);
*
*****************************************************************************/
#define XDmaMulti_mGetControl(InstancePtr, Channel)                         \
        XIo_In32((InstancePtr)->AddrTablePtr[(Channel)] +                   \
                  XDM_DMACR_REG_OFFSET)

/****************************************************************************/
/**
*
* Set the Control Register of the given channel with the provided value.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @param    Control is the 32-bit value to write to the register.
*           <br><br>
* Control contains the value to be written to the control register of the DMA
* channel. One or more of the following values may be contained the register.
* Each of the values are unique bit masks such that they may be ORed together
* to enable multiple bits or inverted and ANDed to disable multiple bits.
* Use the XDM_DMACR_* constants defined in xdma_multi.h to create the bit-mask
* to be written to the register.
*
* @return   None.
*
* @note
*
* C Signature: void XDmaMulti_mSetControl(XDmaMulti *InstancePtr,
*                                         unsigned Channel,
*                                         Xuint32 Control);
*
*****************************************************************************/
#define XDmaMulti_mSetControl(InstancePtr, Channel, Control)                \
        XIo_Out32((InstancePtr)->AddrTablePtr[(Channel)] +                  \
                   XDM_DMACR_REG_OFFSET, (Control))

/****************************************************************************/
/**
*
* Set the Event Enable of the given channel with the provided value.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @param    Enable is the 32-bit value to write to the register.
*           <br><br>
* Enable contains the event enable register contents to be written
* in the DMA channel. One or more of the following values may be contained
* the register. Each of the values are unique bit masks such that they may be
* ORed together to enable multiple bits or inverted and ANDed to disable
* multiple bits. Use the XDM_SWCR_* constants defined in xdma_multi.h to
* create the bit-mask to be written to the register.
*
* @return   None.
*
* @note
*
* C Signature: void XDmaMulti_mSetEventEnable(XDmaMulti *InstancePtr,
*                                             unsigned Channel,
*                                             Xuint32 Enable);
*
*****************************************************************************/
#define XDmaMulti_mSetEventEnable(InstancePtr, Channel, Enable)             \
        XIo_Out32((InstancePtr)->AddrTablePtr[(Channel)] +                  \
        XDM_SWCR_REG_OFFSET,                                                \
        ((XDmaMulti_mGetEventEnable((InstancePtr), (Channel)) &             \
        ~(XDM_GEFIFO_ENABLE_MASK))) | (Enable))


/****************************************************************************/
/**
*
* Read the Event Enable Register of the given channel.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @return   The 32-bit value of the register.
*           <br><br>
* The interrupt enable of the DMA channel.  One or more of the following values
* may be contained the register. Each of the values are
* unique bit masks.See xdma_multi.h for a description of possible
* values. The return values are prefixed with XDM_SWCR_*.*
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetEventEnable(XDmaMulti *InstancePtr,
*                                                unsigned Channel);
*
*****************************************************************************/
#define XDmaMulti_mGetEventEnable(InstancePtr, Channel)                         \
        XIo_In32((InstancePtr)->AddrTablePtr[(Channel)] + XDM_SWCR_REG_OFFSET)

/****************************************************************************/
/**
*
* Read the Event FIFO Status Register of the Device.
*
* @param    InstancePtr is the instance to be used
*
* @return   The 32-bit value of the register
*           <br><br>
* The Event FIFO Status Register contents. This register is
* a FIFO and it can only be read once per event. Once it is
* read the event is discarded and the next event appears. The user
* must ensure that this FIFO is read only once per event to maintain
* synchronization with hardware.
* <br><br>
* One or more of the following values may be contained the register.
* Each of the values are unique bit masks.See xdma_multi.h for a description
* of possible values. The return values are prefixed with XDM_GEFIFO_*.*
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetEventStatus(XDmaMulti *InstancePtr);
*
*****************************************************************************/
#define XDmaMulti_mGetEventStatus(InstancePtr)                         \
        XIo_In32((InstancePtr)->BaseAddress + XDM_GEFIFO_OFFSET)

/****************************************************************************/
/**
*
* Determine the Channel Number of the provided Status/Event.
*
* @param    Status is the Status/Event read from Event FIFO.
*
* @return   The 32-bit value of Channel that caused the Status/Event.
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetEventChannel(Xuint32 Status);
*
*****************************************************************************/
#define XDmaMulti_mGetEventChannel(Status)                                   \
        ((Xuint32)(((Status) & XDM_GEFIFO_CHAN_MASK) >> XDM_GEFIFO_CHAN_SHIFT))

/****************************************************************************/
/**
*
* Determine the Event Parameter of the provided Status/Event.
*
* @param    Status is the Status/Event read from Event FIFO.
*
* @return   The 32-bit value of associated Event Parameter.
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetEventChannel(Xuint32 Status);
*
*****************************************************************************/
#define XDmaMulti_mGetEventParameter(Status)                                   \
        ((Xuint32)((Status) & XDM_GEFIFO_EVENT_MASK))

/****************************************************************************/
/**
*
* Read the Status Register of the given channel.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @return   The 32-bit value of the register.
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetStatus(XDmaMulti *InstancePtr,
*                                           unsigned Channel);
*
*****************************************************************************/
#define XDmaMulti_mGetStatus(InstancePtr, Channel)                         \
        XIo_In32((InstancePtr)->AddrTablePtr[(Channel)] + XDM_DMAS_REG_OFFSET)

/****************************************************************************/
/**
*
* Set the Packet Count Threshold Value for the given channel with the provided
* value.
*
* This function sets the value of the packet count threshold register of the
* DMA channel.  It reflects the number of packets that must be sent or
* received before generating an interrupt.  This value helps implement
* a concept called "interrupt coalescing", which is used to reduce the number
* of interrupts from devices with high data rates.
*
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @param    Threshold is the 10-bit value to write to the register.
*           Range is 0-1023, 0 is disabled.
*
* @return   None
*
* @note
*
* C Signature: void XDmaMulti_mSetPktThreshold(XDmaMulti *InstancePtr,
*                                              unsigned Channel,
*                                              Xuint32 Threshold);
*
*****************************************************************************/
#define XDmaMulti_mSetPktThreshold(InstancePtr, Channel, Threshold)         \
        XIo_Out32((InstancePtr)->AddrTablePtr[(Channel)] +                  \
        XDM_SWCR_REG_OFFSET, ((Threshold) |                                 \
         ((XIo_In32((InstancePtr)->AddrTablePtr[(Channel)] +                \
                     XDM_SWCR_REG_OFFSET)) & ~XDM_SWCR_PCT_MASK)))

/****************************************************************************/
/**
*
* Read the Packet Count Threshold of the given channel.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @return   The 10-bit value of the Packet Count Threshold.
*           Range is 0-1023, 0 is disabled.
*           <br><br>
* This function reads the value of the packet count threshold register of the
* DMA channel.  It reflects the number of packets that must be sent or
* received before generating an interrupt.
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetPktThreshold(XDmaMulti *InstancePtr,
*                                                 unsigned Channel);
*
*****************************************************************************/
#define XDmaMulti_mGetPktThreshold(InstancePtr, Channel)                    \
        ((XIo_In32((InstancePtr)->AddrTablePtr[(Channel)] +                 \
            XDM_SWCR_REG_OFFSET)) & XDM_SWCR_PCT_MASK)

/****************************************************************************/
/**
*
* Set the Packet Wait Bound Value for the given channel with the provided
* value.
*
* WaitBound is the value, in milliseconds, to be stored in the wait bound
* register of the DMA channel and is a value in the range 0  - 1023.  A value
* of 0 disables the packet wait bound timer.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @param    WaitBound is the 10-bit value to write to the Packet Wait Bound.
*           Range is 0-1023, 0 is disabled.
*
* @return   None.
*
* @note
*
* C Signature: void XDmaMulti_mSetPktWaitBound(XDmaMulti *InstancePtr,
*                                              unsigned Channel,
*                                              Xuint32 WaitBound);
*
*****************************************************************************/
#define XDmaMulti_mSetPktWaitBound(InstancePtr, Channel, WaitBound)         \
        XIo_Out32((InstancePtr)->AddrTablePtr[(Channel)] +                  \
        XDM_SWCR_REG_OFFSET, ((WaitBound << XDM_SWCR_PWB_SHIFT) |           \
         ((XIo_In32((InstancePtr)->AddrTablePtr[(Channel)] +                \
                     XDM_SWCR_REG_OFFSET)) & ~XDM_SWCR_PWB_MASK)))


/****************************************************************************/
/**
*
* Read the Packet Wait Bound of the given channel.
*
* @param    InstancePtr is the instance to be used.
*
* @param    Channel is the channel of interest, zero based.
*
* @return   The 10-bit value of the Packet Wait Bound.
*           Range is 0-1023, 0 is disabled.
*           <br><br>
* The packet wait bound register contents for the DMA channel.
*
* @note
*
* C Signature: Xuint32 XDmaMulti_mGetPktWaitBound(XDmaMulti *InstancePtr,
*                                                 unsigned Channel);
*
*****************************************************************************/
#define XDmaMulti_mGetPktWaitBound(InstancePtr, Channel)                    \
        (((XIo_In32((InstancePtr)->AddrTablePtr[(Channel)] +                \
          XDM_SWCR_REG_OFFSET)) & XDM_SWCR_PWB_MASK) >> XDM_SWCR_PWB_SHIFT)

/*@}*/


/************************** Function Prototypes ******************************/

/**
 * Standard functions
 */
XStatus XDmaMulti_Initialize(XDmaMulti *InstancePtr,
                             Xuint32 BaseAddress,
                             Xuint32 *UserMemoryPtr,
                             Xuint16 ChannelCount);
XStatus XDmaMulti_SelfTest(XDmaMulti *InstancePtr);
void    XDmaMulti_Reset(XDmaMulti *InstancePtr, unsigned Channel);

/**
 * DMA without scatter gather functions
 */
void XDmaMulti_Transfer(XDmaMulti *InstancePtr,
                        unsigned Channel,
                        Xuint32 *SourcePtr,
                        Xuint32 *DestinationPtr,
                        Xuint32 ByteCount);

/**
 * Scatter gather functions
 */
XStatus XDmaMulti_SgStart(XDmaMulti *InstancePtr, unsigned Channel);
XStatus XDmaMulti_SgStop(XDmaMulti *InstancePtr, unsigned Channel,
                         XBufDescriptor **BufDescriptorPtr);
XStatus XDmaMulti_CreateSgList(XDmaMulti *InstancePtr,
                               unsigned Channel,
                               Xuint32 *BdMemoryPtr,
                               Xuint32 ByteCount);
Xboolean XDmaMulti_IsSgListEmpty(XDmaMulti *InstancePtr, unsigned Channel);

XStatus XDmaMulti_PutDescriptor(XDmaMulti *InstancePtr, unsigned Channel,
                                XBufDescriptor *BufDescriptorPtr);
XStatus XDmaMulti_CommitPuts(XDmaMulti *InstancePtr, unsigned Channel);
XStatus XDmaMulti_GetDescriptor(XDmaMulti *InstancePtr, unsigned Channel,
                                XBufDescriptor** BufDescriptorPtr);


#ifdef __cplusplus
}
#endif

#endif              /* end of protection macro */
