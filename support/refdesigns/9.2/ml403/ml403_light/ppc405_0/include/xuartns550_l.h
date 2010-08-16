/* $Id: xuartns550_l.h,v 1.3.6.1 2007/11/13 23:53:36 moleres Exp $ */
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
*       (c) Copyright 2002-2007 Xilinx Inc.
*       All rights reserved.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xuartns550_l.h
*
* This header file contains identifiers and low-level driver functions (or
* macros) that can be used to access the device. The user should refer to the
* hardware device specification for more details of the device operation.
* High-level driver functions are defined in xuartns550.h.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date	 Changes
* ----- ---- -------- -----------------------------------------------
* 1.00b jhl  04/24/02 First release
* 1.11a sv   03/20/07 Updated to use the new coding guidelines.
* 1.11a rpm  11/13/07 Fixed bug in _mEnableIntr
* </pre>
*
******************************************************************************/

#ifndef XUARTNS550_L_H /* prevent circular inclusions */
#define XUARTNS550_L_H /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/

#include "xbasic_types.h"
#include "xio.h"

/************************** Constant Definitions *****************************/

/*
 * Offset from the device base address to the IP registers.
 */
#define XUN_REG_OFFSET 0x1000

/* 16450/16550 compatible UART, register offsets as byte registers */

#define XUN_RBR_OFFSET	(XUN_REG_OFFSET + 0x03) /* Receive buffer, read only */
#define XUN_THR_OFFSET	(XUN_REG_OFFSET + 0x03) /* Transmit holding register */
#define XUN_IER_OFFSET	(XUN_REG_OFFSET + 0x07) /* Interrupt enable */
#define XUN_IIR_OFFSET	(XUN_REG_OFFSET + 0x0B) /* Interrupt id, read only */
#define XUN_FCR_OFFSET	(XUN_REG_OFFSET + 0x0B) /* Fifo control, write only */
#define XUN_LCR_OFFSET	(XUN_REG_OFFSET + 0x0F) /* Line control register */
#define XUN_MCR_OFFSET	(XUN_REG_OFFSET + 0x13) /* Modem control register */
#define XUN_LSR_OFFSET	(XUN_REG_OFFSET + 0x17) /* Line status register */
#define XUN_MSR_OFFSET	(XUN_REG_OFFSET + 0x1B) /* Modem status register */
#define XUN_DRLS_OFFSET	(XUN_REG_OFFSET + 0x03) /* Divisor register LSB */
#define XUN_DRLM_OFFSET	(XUN_REG_OFFSET + 0x07) /* Divisor register MSB */

/*
 * The following constant specifies the size of the FIFOs, the size of the
 * FIFOs includes the transmitter and receiver such that it is the total number
 * of bytes that the UART can buffer
 */
#define XUN_FIFO_SIZE			16

/* Interrupt Enable Register bits */

#define XUN_IER_MODEM_STATUS		0x08 /* Modem status interrupt */
#define XUN_IER_RX_LINE			0x04 /* Receive status interrupt */
#define XUN_IER_TX_EMPTY		0x02 /* Transmitter empty interrupt */
#define XUN_IER_RX_DATA			0x01 /* Receiver data available */

/* Interrupt ID Register bits */

#define XUN_INT_ID_MASK			0x0F /* Only the interrupt ID */
#define XUN_INT_ID_FIFOS_ENABLED	0xC0 /* Only the FIFOs enable */

/* FIFO Control Register bits */

#define XUN_FIFO_RX_TRIG_MSB		0x80 /* Trigger level MSB */
#define XUN_FIFO_RX_TRIG_LSB		0x40 /* Trigger level LSB */
#define XUN_FIFO_TX_RESET		0x04 /* Reset the transmit FIFO */
#define XUN_FIFO_RX_RESET		0x02 /* Reset the receive FIFO */
#define XUN_FIFO_ENABLE			0x01 /* Enable the FIFOs */
#define XUN_FIFO_RX_TRIGGER		0xC0 /* Both trigger level bits */

/* Line Control Register bits */

#define XUN_LCR_DLAB			0x80 /* Divisor latch access */
#define XUN_LCR_SET_BREAK		0x40 /* Cause a break condition */
#define XUN_LCR_STICK_PARITY		0x20
#define XUN_LCR_EVEN_PARITY		0x10 /* 1 = even, 0 = odd parity */
#define XUN_LCR_ENABLE_PARITY		0x08
#define XUN_LCR_2_STOP_BITS		0x04 /* 1= 2 stop bits,0 = 1 stop bit */
#define XUN_LCR_8_DATA_BITS		0x03
#define XUN_LCR_7_DATA_BITS		0x02
#define XUN_LCR_6_DATA_BITS		0x01
#define XUN_LCR_LENGTH_MASK		0x03 /* Both length bits mask */
#define XUN_LCR_PARITY_MASK		0x18 /* Both parity bits mask */

/* Modem Control Register bits */

#define XUN_MCR_LOOP			0x10 /* Local loopback */
#define XUN_MCR_OUT_2			0x08 /* General output 2 signal */
#define XUN_MCR_OUT_1			0x04 /* General output 1 signal */
#define XUN_MCR_RTS			0x02 /* RTS signal */
#define XUN_MCR_DTR			0x01 /* DTR signal */

/* Line Status Register bits */

#define XUN_LSR_RX_FIFO_ERROR		0x80 /* An errored byte is in FIFO */
#define XUN_LSR_TX_EMPTY		0x40 /* Transmitter is empty */
#define XUN_LSR_TX_BUFFER_EMPTY		0x20 /* Transmit holding reg empty */
#define XUN_LSR_BREAK_INT		0x10 /* Break detected interrupt */
#define XUN_LSR_FRAMING_ERROR		0x08 /* Framing error on current byte */
#define XUN_LSR_PARITY_ERROR		0x04 /* Parity error on current byte */
#define XUN_LSR_OVERRUN_ERROR		0x02 /* Overrun error on receive FIFO */
#define XUN_LSR_DATA_READY		0x01 /* Receive data ready */
#define XUN_LSR_ERROR_BREAK		0x1E /* Errors except FIFO error and
						break detected */

#define XUN_DIVISOR_BYTE_MASK	   0xFF

/**************************** Type Definitions *******************************/


/***************** Macros (Inline Functions) Definitions *********************/


/*****************************************************************************
*
* Low-level driver macros.  The list below provides signatures to help the
* user use the macros.
*
* u8 XUartNs550_mReadReg(u32 BaseAddress. int RegOffset)
* void XUartNs550_mWriteReg(u32 BaseAddress, int RegOffset, u8 RegisterValue)
*
* u8 XUartNs550_mGetLineStatusReg(u32 BaseAddress)
* u8 XUartNs550_mGetLineControlReg(u32 BaseAddress)
* void XUartNs550_mSetLineControlReg(u32 BaseAddress, u8 RegisterValue)
*
* void XUartNs550_mEnableIntr(u32 BaseAddress)
* void XUartNs550_mDisableIntr(u32 BaseAddress)
*
* int XUartNs550_mIsReceiveData(u32 BaseAddress)
* int XUartNs550_mIsTransmitEmpty(u32 BaseAddress)
*
*****************************************************************************/

/****************************************************************************/
/**
* Read a UART register.
*
* @param	BaseAddress contains the base address of the device.
* @param	RegOffset contains the offset from the 1st register of the
*		device to select the specific register.
*
* @return	The value read from the register.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mReadReg(BaseAddress, RegOffset) \
	XIo_In8((BaseAddress) + (RegOffset))

/****************************************************************************/
/**
* Write to a UART register.
*
* @param	BaseAddress contains the base address of the device.
* @param	RegOffset contains the offset from the 1st register of the
*		device to select the specific register.
*
* @return	The value read from the register.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mWriteReg(BaseAddress, RegOffset, RegisterValue) \
	XIo_Out8((BaseAddress) + (RegOffset), (RegisterValue))

/****************************************************************************/
/**
* Get the UART Line Status Register.
*
* @param	BaseAddress contains the base address of the device.
*
* @return	The value read from the register.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mGetLineStatusReg(BaseAddress)   \
	XIo_In8((BaseAddress) + XUN_LSR_OFFSET)

/****************************************************************************/
/**
* Get the UART Line Status Register.
*
* @param	BaseAddress contains the base address of the device.
*
* @return	The value read from the register.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mGetLineControlReg(BaseAddress)  \
	XIo_In8((BaseAddress) + XUN_LCR_OFFSET)

/****************************************************************************/
/**
* Set the UART Line Status Register.
*
* @param	BaseAddress contains the base address of the device.
* @param	RegisterValue is the value to be written to the register.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mSetLineControlReg(BaseAddress, RegisterValue) \
	XIo_Out8((BaseAddress) + XUN_LCR_OFFSET, (RegisterValue))

/****************************************************************************/
/**
* Enable the transmit and receive interrupts of the UART.
*
* @param	BaseAddress contains the base address of the device.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mEnableIntr(BaseAddress)				\
	XIo_Out8((BaseAddress) + XUN_IER_OFFSET,			\
			 XIo_In8((BaseAddress) + XUN_IER_OFFSET) |	\
			 (XUN_IER_RX_LINE | XUN_IER_TX_EMPTY | XUN_IER_RX_DATA))

/****************************************************************************/
/**
* Disable the transmit and receive interrupts of the UART.
*
* @param	BaseAddress contains the base address of the device.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mDisableIntr(BaseAddress)				\
	XIo_Out8((BaseAddress) + XUN_IER_OFFSET,			\
			XIo_In8((BaseAddress) + XUN_IER_OFFSET) &	\
			~(XUN_IER_RX_LINE | XUN_IER_TX_EMPTY | XUN_IER_RX_DATA))

/****************************************************************************/
/**
* Determine if there is receive data in the receiver and/or FIFO.
*
* @param	BaseAddress contains the base address of the device.
*
* @return	TRUE if there is receive data, FALSE otherwise.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mIsReceiveData(BaseAddress)				\
	(XIo_In8((BaseAddress) + XUN_LSR_OFFSET) & XUN_LSR_DATA_READY)

/****************************************************************************/
/**
* Determine if a byte of data can be sent with the transmitter.
*
* @param	BaseAddress contains the base address of the device.
*
* @return	TRUE if a byte can be sent, FALSE otherwise.
*
* @note		None.
*
******************************************************************************/
#define XUartNs550_mIsTransmitEmpty(BaseAddress)			\
	(XIo_In8((BaseAddress) + XUN_LSR_OFFSET) & XUN_LSR_TX_BUFFER_EMPTY)

/************************** Function Prototypes ******************************/

void XUartNs550_SendByte(u32 BaseAddress, u8 Data);

u8 XUartNs550_RecvByte(u32 BaseAddress);

void XUartNs550_SetBaud(u32 BaseAddress, u32 InputClockHz, u32 BaudRate);

/************************** Variable Definitions *****************************/

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */

