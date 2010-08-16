/* $Id: xmpmc_hw.h,v 1.3 2007/06/04 15:17:03 mta Exp $ */
/******************************************************************************
*
*       XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
*       AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND
*       SOLUTIONS FOR XILINX DEVICES. BY PROVIDING THIS DESIGN, CODE,
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
*       (c) Copyright 2007 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xmpmc_hw.h
*
* This header file contains identifiers and basic driver functions for the
* XMpmc device driver.
*
* @note		None.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a mta  02/24/07 First release
* </pre>
*
******************************************************************************/

#ifndef XMPMC_HW_H		/* prevent circular inclusions */
#define XMPMC_HW_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xbasic_types.h"
#include "xio.h"

/************************** Constant Definitions *****************************/

/** @name Register offsets
 * @{
 */
#define XMPMC_ECCCR_OFFSET	0x0  /**< Control Register */
#define XMPMC_ECCSR_OFFSET	0x4  /**< Status Register */
#define XMPMC_ECCSEC_OFFSET	0x8  /**< Single Error Count Register */
#define XMPMC_ECCDEC_OFFSET	0xC  /**< Double Error Count Register */
#define XMPMC_ECCPEC_OFFSET	0x10 /**< Parity Field Error Count Register */
#define XMPMC_ECCADDR_OFFSET	0x14 /**< Error Address Register */
#define XMPMC_DGIE_OFFSET	0x1C /**< Device Global Interrupt Enable Reg */
#define XMPMC_IPISR_OFFSET	0x20 /**< IP Interrupt Status Register */
#define XMPMC_IPIER_OFFSET	0x24 /**< IP Interrupt Enable Register */
/*@}*/

/** @name ECC Control Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_ECCCR_FORCE_PE_MASK 	0x10 /**< Force parity error */
#define XMPMC_ECCCR_FORCE_DE_MASK 	0x08 /**< Force double bit error */
#define XMPMC_ECCCR_FORCE_SE_MASK 	0x04 /**< Force single bit error */
#define XMPMC_ECCCR_RE_MASK		0x02 /**< ECC read enable */
#define XMPMC_ECCCR_WE_MASK		0x01 /**< ECC write enable */
/*@}*/

/** @name ECC Status Register bitmaps and masks
 *
 * @{
 */
#define XMPMC_ECCSR_ERR_SIZE_MASK	0xF000 /**< Error Transaction Size */
#define XMPMC_ECCSR_ERR_RNW_MASK	0x0800 /**< Error Transaction Rd/Wr */
#define XMPMC_ECCSR_SE_SYND_MASK	0x07F8 /**< Single bit error syndrome */
#define XMPMC_ECCSR_PE_MASK		0x0004 /**< Parity field bit error */
#define XMPMC_ECCSR_DE_MASK		0x0002 /**< Double bit error */
#define XMPMC_ECCSR_SE_MASK		0x0001 /**< Single bit error */
/*@}*/

/** @name Device Global Interrupt Enable Register bitmaps and masks
 *
 * Bit definitions for the global interrupt enable register.
 * @{
 */
#define XMPMC_DGIE_GIE_MASK		0x80000000  /**< Global Intr Enable */
/*@}*/

/** @name Interrupt Status and Enable Register bitmaps and masks
 *
 * Bit definitions for the interrupt status register and interrupt enable
 * registers.
 * @{
 */
#define XMPMC_IPIXR_PE_IX_MASK		0x4 /**< Parity field error interrupt */
#define XMPMC_IPIXR_DE_IX_MASK		0x2 /**< Double bit error interrupt */
#define XMPMC_IPIXR_SE_IX_MASK		0x1 /**< Single bit error interrupt */
/*@}*/

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/****************************************************************************/
/**
*
* Write a value to a MPMC register. A 32 bit write is performed.
*
* @param	BaseAddress is the base address of the MPMC device.
* @param	RegOffset is the register offset from the base to write to.
* @param	Data is the data written to the register.
*
* @return	None.
*
* @note		C-style signature:
*		void XMpmc_mWriteReg(u32 BaseAddress, unsigned RegOffset,
					u32 Data);
*
****************************************************************************/
#define XMpmc_mWriteReg(BaseAddress, RegOffset, Data) \
			(XIo_Out32((BaseAddress) + (RegOffset), (u32)(Data)))

/****************************************************************************/
/**
*
* Read a value from a MPMC register. A 32 bit read is performed.
*
* @param	BaseAddress is the base address of the MPMC device.
* @param	Register is the register offset from the base to read from.
*
* @return	The value read from the register.
*
* @note		C-style signature:
*		u32 XMpmc_mReadReg(u32 BaseAddress, unsigned RegOffset);
*
****************************************************************************/
#define XMpmc_mReadReg(BaseAddress, RegOffset) \
					(XIo_In32((BaseAddress) + (RegOffset)))

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
