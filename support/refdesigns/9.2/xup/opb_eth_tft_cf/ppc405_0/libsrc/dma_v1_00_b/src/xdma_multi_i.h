/* $Id: xdma_multi_i.h,v 1.2 2006/06/02 21:43:44 meinelte Exp $ */
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
* @file xdma_multi_i.h
*
* <b>Description</b>
*
* This file contains data which is shared internal data for the multichannel DMA
* component. It is also shared with the buffer descriptor component which is
* very tightly coupled with the multichannel DMA component.
*
* @note
*
* The last buffer descriptor constants must be located here to prevent a
* circular dependency between the multichannel DMA component and the buffer
* descriptor component.
*
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
******************************************************************************/

#ifndef XDMA_MULTI_I_H    /* prevent circular inclusions */
#define XDMA_MULTI_I_H    /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif


/***************************** Include Files *********************************/

#include "xbasic_types.h"
#include "xstatus.h"

/************************** Constant Definitions *****************************/

/**
 * The following constant provides access to the bit fields of the DMA control
 * register (DMACR) which must be shared between the multichannel DMA component
 * and the buffer descriptor component.
 */
#define XDM_CONTROL_LAST_BD_MASK   0x02000000UL /**< last buffer descriptor */

/**
 * The following constant provides access to the bit fields of the DMA status
 * register (DMASR) which must be shared between the multichannel DMA component
 * and the buffer descriptor component.
 */
#define XDM_STATUS_LAST_BD_MASK    0x10000000UL /**< last buffer descriptor */

/** @name Global Register Offsets
 *
 * The following constants provide access to each of the Global Registers for
 * the multichannel DMA.
 * @{
 */
#define XDM_GMIR_REG_OFFSET    0x1010   /**< Global Module Id Register */
#define XDM_GCSR_REG_OFFSET    0x1014   /**< Global Control/Status Register */
#define XDM_GEFIFO_OFFSET      0x1018   /**< Global Event FIFO */
/* @} */

/** @name Channel Specific Multichannel DMA Register Offsets
 *
 * The following constants provide access to each of the Channel Specific
 * multichannel DMA Registers.
 * @{
 */
#define XDM_SYS_REG_OFFSET     0   /**< System register */
#define XDM_DMACR_REG_OFFSET   4   /**< DMA control register */
#define XDM_SA_REG_OFFSET      8   /**< source address register */
#define XDM_DA_REG_OFFSET      12  /**< destination address register */
#define XDM_LEN_REG_OFFSET     16  /**< length register */
#define XDM_DMAS_REG_OFFSET    20  /**< DMA status register */
#define XDM_BDA_REG_OFFSET     24  /**< buffer descriptor address register */
#define XDM_SWCR_REG_OFFSET    28  /**< software control register */
/* @} */

/**
 * The following constant is the shift value for the Packet Wait Bound.
 */
#define XDM_SWCR_PWB_SHIFT      10 /**< Packet Wait Bound shift value*/

/**
 * The following constant is the shift value for the Event Channel Field.
 */
#define XDM_GEFIFO_CHAN_SHIFT      12   /**< DMA Channel Event shift value */

/**
 * The following constant is the shift value for the Event Channel Field.
 */
#define XDM_SYS_REG_ANCY_SHIFT      10  /**< Occupancy/Vacancy shift value */

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

#define CHANNEL_DATA (InstancePtr->SgDataTablePtr[Channel])

#define CHANNEL_REGS (InstancePtr->AddrTablePtr[Channel])

/************************** Function Prototypes ******************************/


#ifdef __cplusplus
}
#endif

#endif              /* end of protection macro */
