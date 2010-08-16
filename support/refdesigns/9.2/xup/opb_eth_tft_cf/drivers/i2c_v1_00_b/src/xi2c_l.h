#ifndef XI2C_L_H /* prevent circular inclusions */
#define XI2C_L_H /* by using protection macros */

/***************************** Include Files ********************************/

#include "xbasic_types.h"

/************************** Constant Definitions ****************************/

#define XIIC_MSB_OFFSET                3

#define XIIC_REG_OFFSET 0x100 + XIIC_MSB_OFFSET

/*
 * Register offsets in bytes from RegisterBase. Three is added to the
 * base offset to access LSB (IBM style) of the word
 */
#define XIIC_CR_REG_OFFSET   0x00+XIIC_REG_OFFSET   /* Control Register   */
#define XIIC_SR_REG_OFFSET   0x04+XIIC_REG_OFFSET   /* Status Register    */
#define XIIC_DTR_REG_OFFSET  0x08+XIIC_REG_OFFSET   /* Data Tx Register   */
#define XIIC_DRR_REG_OFFSET  0x0C+XIIC_REG_OFFSET   /* Data Rx Register   */
#define XIIC_ADR_REG_OFFSET  0x10+XIIC_REG_OFFSET   /* Address Register   */
#define XIIC_TFO_REG_OFFSET  0x14+XIIC_REG_OFFSET   /* Tx FIFO Occupancy  */
#define XIIC_RFO_REG_OFFSET  0x18+XIIC_REG_OFFSET   /* Rx FIFO Occupancy  */
#define XIIC_TBA_REG_OFFSET  0x1C+XIIC_REG_OFFSET   /* 10 Bit Address reg */
#define XIIC_RFD_REG_OFFSET  0x20+XIIC_REG_OFFSET   /* Rx FIFO Depth reg  */
#define XIIC_GPO_REG_OFFSET  0x24+XIIC_REG_OFFSET   /* Output Register    */

/* Control Register masks */

#define XIIC_CR_ENABLE_DEVICE_MASK        0x01  /* Device enable = 1      */
#define XIIC_CR_TX_FIFO_RESET_MASK        0x02  /* Transmit FIFO reset=1  */
#define XIIC_CR_MSMS_MASK                 0x04  /* Master starts Txing=1  */
#define XIIC_CR_DIR_IS_TX_MASK            0x08  /* Dir of tx. Txing=1     */
#define XIIC_CR_NO_ACK_MASK               0x10  /* Tx Ack. NO ack = 1     */
#define XIIC_CR_REPEATED_START_MASK       0x20  /* Repeated start = 1     */
#define XIIC_CR_GENERAL_CALL_MASK         0x40  /* Gen Call enabled = 1   */

/* Status Register masks */
#define XIIC_SR_GEN_CALL_MASK             0x01  /* 1=a mstr issued a GC   */
#define XIIC_SR_ADDR_AS_SLAVE_MASK        0x02  /* 1=when addr as slave   */
#define XIIC_SR_BUS_BUSY_MASK             0x04  /* 1 = bus is busy        */
#define XIIC_SR_MSTR_RDING_SLAVE_MASK     0x08  /* 1=Dir: mstr <-- slave  */
#define XIIC_SR_TX_FIFO_FULL_MASK         0x10  /* 1 = Tx FIFO full       */
#define XIIC_SR_RX_FIFO_FULL_MASK         0x20  /* 1 = Rx FIFO full       */
#define XIIC_SR_RX_FIFO_EMPTY_MASK        0x40  /* 1 = Rx FIFO empty      */
#define XIIC_SR_TX_FIFO_EMPTY_MASK        0x80  /* 1 = Tx FIFO empty      */

/* IPIF Interrupt Status Register masks    Interrupt occurs when...       */

#define XIIC_INTR_ARB_LOST_MASK           0x01  /* 1 = arbitration lost   */
#define XIIC_INTR_TX_ERROR_MASK           0x02  /* 1=Tx error/msg complete*/
#define XIIC_INTR_TX_EMPTY_MASK           0x04  /* 1 = Tx FIFO/reg empty  */
#define XIIC_INTR_RX_FULL_MASK            0x08  /* 1=Rx FIFO/reg=OCY level*/
#define XIIC_INTR_BNB_MASK                0x10  /* 1 = Bus not busy       */
#define XIIC_INTR_AAS_MASK                0x20  /* 1 = when addr as slave */
#define XIIC_INTR_NAAS_MASK               0x40  /* 1 = not addr as slave  */
#define XIIC_INTR_TX_HALF_MASK            0x80  /* 1 = TX FIFO half empty */

/* IPIF Device Interrupt Register masks */

#define XIIC_IPIF_IIC_MASK          0x00000004UL    /* 1=inter enabled */
#define XIIC_IPIF_ERROR_MASK        0x00000001UL    /* 1=inter enabled */
#define XIIC_IPIF_INTER_ENABLE_MASK  (XIIC_IPIF_IIC_MASK |  \
                                      XIIC_IPIF_ERROR_MASK)

#define XIIC_TX_ADDR_SENT             0x00
#define XIIC_TX_ADDR_MSTR_RECV_MASK   0x02

/* The following constants specify the depth of the FIFOs */

#define IIC_RX_FIFO_DEPTH         16   /* Rx fifo capacity               */
#define IIC_TX_FIFO_DEPTH         16   /* Tx fifo capacity               */

/* The following constants specify groups of interrupts that are typically
 * enabled or disables at the same time
 */
#define XIIC_TX_INTERRUPTS                                          \
            (XIIC_INTR_TX_ERROR_MASK | XIIC_INTR_TX_EMPTY_MASK |    \
             XIIC_INTR_TX_HALF_MASK)

#define XIIC_TX_RX_INTERRUPTS (XIIC_INTR_RX_FULL_MASK | XIIC_TX_INTERRUPTS)

/* The following constants are used with the following macros to specify the
 * operation, a read or write operation.
 */
#define XIIC_READ_OPERATION  1
#define XIIC_WRITE_OPERATION 0

/* The following constants are used with the transmit FIFO fill function to
 * specify the role which the IIC device is acting as, a master or a slave.
 */
#define XIIC_MASTER_ROLE     1
#define XIIC_SLAVE_ROLE      0

/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/

/******************************************************************************
*
* This macro reads a register in the IIC device using an 8 bit read operation.
* This macro does not do any checking to ensure that the register exists if the
* register may be excluded due to parameterization, such as the GPO Register.
*
* @param    BaseAddress of the IIC device.
*
* @param    RegisterOffset contains the offset of the register from the device
*           base address.
*
* @return
*
* The value read from the register.
*
* @note
*
* Signature: Xuint8 XIic_mReadReg(Xuint32 BaseAddress, int RegisterOffset);
*
******************************************************************************/
#define XI2c_mReadReg(BaseAddress, RegisterOffset) \
   XIo_In8((BaseAddress) + (RegisterOffset))

/******************************************************************************
*
* This macro writes a register in the IIC device using an 8 bit write operation.
* This macro does not do any checking to ensure that the register exists if the
* register may be excluded due to parameterization, such as the GPO Register.
*
* @param    BaseAddress of the IIC device
*
* @param    RegisterOffset contains the offset of the register from the device
*           base address
*
* @param    Data contains the data to be written to the register.
*
* @return
*
* None.
*
* @note
*
* Signature: void XIic_mWriteReg(Xuint32 BaseAddress, 
*                                int RegisterOffset, Xuint8 Data);
*
******************************************************************************/
#define XI2c_mWriteReg(BaseAddress, RegisterOffset, Data) \
   XIo_Out8((BaseAddress) + (RegisterOffset), (Data))

/************************** Function Prototypes *****************************/

Xuint8 XI2c_Recv(Xuint32 BaseAddress, Xuint8 SlaveAddress,
		 Xuint8 *BufferPtr, Xuint8 ByteCount);

Xuint8 XI2c_Send(Xuint32 BaseAddress, Xuint8 SlaveAddress,
		 Xuint8 *BufferPtr, Xuint8 ByteCount);

Xuint8 XI2c_RSRecv(Xuint32 BaseAddress, Xuint8 SlaveAddress,
		   Xuint8 StartAddress, Xuint8 *BufferPtr, 
		   Xuint8 ByteCount);

Xuint8 XI2c_RSSend(Xuint32 BaseAddress, Xuint8 SlaveAddress,
		   Xuint8 StartAddress, Xuint8 *BufferPtr, 
		   Xuint8 ByteCount);

Xuint8 XI2c_SlaveAccess(Xuint32 BaseAddress, Xuint8 SlaveAddress,
			Xuint8 *DataBuffer);

#endif            /* end of protection macro */
