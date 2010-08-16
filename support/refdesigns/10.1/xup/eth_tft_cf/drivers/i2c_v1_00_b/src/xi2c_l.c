#include "xbasic_types.h"
#include "xio.h"
#include "xipif_v1_23_b.h"
#include "xi2c_l.h"


/***************************** XI2c_mClearIisr *****************************
 *
 * This macro clears the specified interrupt in the IPIF interrupt status
 * register.  It is non-destructive in that the register is read and only the
 * interrupt specified is cleared.  Clearing an interrupt acknowledges it.
 *
 * @param    BaseAddress contains the IPIF registers base address.
 * @param    InterruptMask contains the interrupts to be disabled.
 *
 * @return   None.
 *
 * Signature: void XIic_mClearIisr(Xuint32 BaseAddress,Xuint32 InterruptMask);
 *
 ***************************************************************************/
#define XI2c_mClearIisr(BaseAddress, InterruptMask)                 \
    XIIF_V123B_WRITE_IISR((BaseAddress),                            \
        XIIF_V123B_READ_IISR(BaseAddress) & (InterruptMask))


#define XI2c_mClearTXFifo(BaseAddress)                                 \
    XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET,                         \
             XIIC_CR_ENABLE_DEVICE_MASK | XIIC_CR_TX_FIFO_RESET_MASK); \
    XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET,                         \
             XIIC_CR_ENABLE_DEVICE_MASK);

/***************************** XI2c_mSend7BitAddr **************************
*
* This macro sends the address for a 7 bit address during both read and write
* operations. It takes care of the details to format the address correctly.
* This macro is designed to be called internally to the drivers.
*
* @param    SlaveAddress contains the address of the slave to send to.
* @param    Operation indicates XIIC_READ_OPERATION or XIIC_WRITE_OPERATION
*
* @return   None.
*
* Signature: void XI2c_mSend7BitAddr(Xuint16 SlaveAddress, Xuint8 Operation);
*
******************************************************************************/
#define XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, Operation) {       \
  Xuint8 LocalAddr = (Xuint8)(SlaveAddress << 1);                           \
  LocalAddr = (LocalAddr & 0xFE) | (Operation);                             \
  XIo_Out8(BaseAddress + XIIC_DTR_REG_OFFSET, LocalAddr);                   \
}


/************************* XI2c_mSendStartAddress ***************************/
#define XI2c_mSendStartAddress(BaseAddress, StartAddress) {                 \
  XIo_Out8(BaseAddress + XIIC_DTR_REG_OFFSET, StartAddress);                \
} 


/************************** Function Prototypes ****************************/
static Xuint8 RecvData(Xuint32 BaseAddress, Xuint8 SlaveAddress, 
		       Xuint8 *BufferPtr, Xuint8 ByteCount);
static Xuint8 SendData(Xuint32 BaseAddress, Xuint8 SlaveAddress,
		       Xuint8 *BufferPtr, Xuint8 ByteCount);
static Xuint8 TXSuccess(Xuint32 BaseAddress);
static Xuint8 RXSuccess(Xuint32 BaseAddress);
static Xuint8 SlaveRecvData(Xuint32 BaseAddress, Xuint8 *BufferPtr);
static Xuint8 SlaveSendData(Xuint32 BaseAddress, Xuint8 *BufferPtr);
static void PrintStatus(Xuint32 BaseAddress);

/****************************** XI2c_Recv *********************************
 *
 * Receive data as a master on the IIC bus.  This function receives the data
 * using polled I/O and blocks until the data has been received.  It only
 * supports 7 bit addressing and non-repeated start modes of operation.  The
 * user is responsible for ensuring the bus is not busy if multiple masters
 * are present on the bus.
 *
 * @param    BaseAddress contains the base address of the IIC device.
 * @param    Address contains the 7 bit IIC address of the device to send the
 *           specified data to.
 * @param    BufferPtr points to the data to be sent.
 * @param    ByteCount is the number of bytes to be sent.
 *
 * @return   The number of bytes received.
 *
 ****************************************************************************/
Xuint8 XI2c_Recv(Xuint32 BaseAddress, Xuint8 SlaveAddress,
		   Xuint8 *BufferPtr, Xuint8 ByteCount) {
  Xuint8 CtrlReg;

  CtrlReg = XIIC_CR_ENABLE_DEVICE_MASK | XIIC_CR_MSMS_MASK;

  if( ByteCount == 1 ) {
    /** Set the rx_fifo depth to 1 (zero-based) **/
    XIo_Out8(BaseAddress + XIIC_RFD_REG_OFFSET, 0);
    
    /** Send the slave device address **/
    XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, XIIC_READ_OPERATION);

    /** Enable no-ack for the single byte transfer **/
    CtrlReg |= XIIC_CR_NO_ACK_MASK;
  }
  else if( ByteCount > 1 ) {
    /** Set the rx_fifo to 1 less than the byte count (zero-based) **/
    XIo_Out8(BaseAddress + XIIC_RFD_REG_OFFSET, ByteCount-2);
    
    /** Send the slave device address **/
    XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, XIIC_READ_OPERATION);
  }

  /** Enable the device and begin the data transfer **/
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);

  /** Clear this once the communication begins **/
  XI2c_mClearIisr(BaseAddress, XIIC_INTR_BNB_MASK);

  return RecvData(BaseAddress, SlaveAddress, BufferPtr, ByteCount);
  
} // XI2c_Recv()


Xuint8 XI2c_RSRecv(Xuint32 BaseAddress, Xuint8 SlaveAddress, 
		   Xuint8 StartAddress, Xuint8 *BufferPtr, 
		   Xuint8 ByteCount) {
  Xuint8 CtrlReg;

  /** Clear any ISR values that may need clearing **/
  XI2c_mClearIisr(BaseAddress, 
		  XIIC_INTR_BNB_MASK | XIIC_INTR_RX_FULL_MASK | 
		  XIIC_INTR_TX_EMPTY_MASK | XIIC_INTR_TX_ERROR_MASK |
		  XIIC_INTR_ARB_LOST_MASK);

  /** Send slave device address **/
  XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, XIIC_WRITE_OPERATION);
  XI2c_mSendStartAddress(BaseAddress, StartAddress);
  
  /** Enable device and indicate data transmission **/
  CtrlReg = XIIC_CR_MSMS_MASK | XIIC_CR_ENABLE_DEVICE_MASK |
    XIIC_CR_DIR_IS_TX_MASK;
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);
  
  /** Send the data **/
  XI2c_mClearIisr(BaseAddress, XIIC_INTR_BNB_MASK | XIIC_INTR_TX_ERROR_MASK);
  if( !TXSuccess(BaseAddress) ) {
    //print("XI2c_RSRecv : 1 : TXFailure\r\n");
    //PrintStatus(BaseAddress);
    return 0;
  }

  /** Enable the repeated start **/
  CtrlReg = XIIC_CR_ENABLE_DEVICE_MASK | XIIC_CR_MSMS_MASK |
    XIIC_CR_REPEATED_START_MASK;
  
  if( ByteCount == 1 ) {
    /** Set the rx_fifo depth to 1 (zero-based) **/
    XIo_Out8(BaseAddress + XIIC_RFD_REG_OFFSET, 0);

    /** Enable the no-ack for the single byte transfer **/
    CtrlReg |= XIIC_CR_NO_ACK_MASK;
  }
  else if( ByteCount > 1 ) {
    /** SEt the rx_fifo depth to 1 less than ByteCount (zero-based) **/
    XIo_Out8(BaseAddress + XIIC_RFD_REG_OFFSET, ByteCount-2); 
  }
  
  /** Enable the device and begin the data transfer **/
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);

  /** Send the slave device address **/
  XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, XIIC_READ_OPERATION);

  return RecvData(BaseAddress, SlaveAddress, BufferPtr, ByteCount);

} // end XI2c_Recv()


static Xuint8 RecvData(Xuint32 BaseAddress, Xuint8 SlaveAddress, 
		       Xuint8 *BufferPtr, Xuint8 ByteCount) {

  Xuint8 IntrStatus, CtrlReg;
  Xuint8 count = 0;

  if( ByteCount > 1 ) {

    /** Receive the data **/
    if( !RXSuccess(BaseAddress) ) {
      //print("RecvData : 1 : RXFailure\r\n");
      return 0;
    }

    /** Set no-ack for the last byte **/
    CtrlReg = XIo_In8(BaseAddress + XIIC_CR_REG_OFFSET) |
      XIIC_CR_NO_ACK_MASK;
    XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);

    /** Read in the data from the rx_fifo **/
    for( count = 0; count < (ByteCount-1); count++ ) {
      *(BufferPtr++) = XIo_In8(BaseAddress + XIIC_DRR_REG_OFFSET);
      //xil_printf("Data received: %d\r\n", *(BufferPtr-1));
    }

    /** Clear the rx_full flag **/
    XI2c_mClearIisr(BaseAddress, XIIC_INTR_RX_FULL_MASK);

    /** Set the rx_fifo depth to 1 (zero based) **/
    XIo_Out8(BaseAddress + XIIC_RFD_REG_OFFSET, 0);
  
  }

  /** Receive the data **/
  if( !RXSuccess(BaseAddress) ) {
    //print("RecvData : 2 : RXFailure\r\n");
    return 0;
  }

  /** Set up for a clean release of the iic bus **/
  CtrlReg = XIIC_CR_ENABLE_DEVICE_MASK;
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);

  /** Read in the data from the rx_fifo **/
  *BufferPtr = XIo_In8(BaseAddress + XIIC_DRR_REG_OFFSET);
  //xil_printf("Data received: %d\r\n", *BufferPtr); 

  /** Clear the rx_full mask **/
  XI2c_mClearIisr(BaseAddress, XIIC_INTR_RX_FULL_MASK);

  /* The receive is complete, disable the IIC device and return the number of
   * bytes that was received, we must wait for the bnb flag to properly
   * disable the device. THIS DOESN'T WORK RIGHT. */
/*    print("Waiting for bnb_high..."); */
/*    do { */
/*      IntrStatus = XIIF_V123B_READ_IISR(BaseAddress); */
/*    } while(!(IntrStatus & XIIC_INTR_BNB_MASK)); */
/*    print("done!\r\n"); */

  //XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, 0);
  
  /* Return the number of bytes that was received */
  return ++count;

} // end RecvData()


/******************************* XI2c_Send *********************************
 *  
 * Send data as a master on the IIC bus.  This function sends the data
 * using polled I/O and blocks until the data has been sent.  It only supports
 * 7 bit addressing and non-repeated start modes of operation.  The user is
 * responsible for ensuring the bus is not busy if multiple masters are 
 * present on the bus.
 *
 * @param    BaseAddress contains the base address of the IIC device.
 * @param    Address contains the 7 bit IIC address of the device to send the
 *           specified data to.
 * @param    BufferPtr points to the data to be sent.
 * @param    ByteCount is the number of bytes to be sent.
 *
 * @return   The number of bytes sent.
 *
 ****************************************************************************/
Xuint8 XI2c_Send(Xuint32 BaseAddress, Xuint8 SlaveAddress,
		 Xuint8 *BufferPtr, Xuint8 ByteCount) {

  Xuint8 CtrlReg;

  XI2c_mClearTXFifo(BaseAddress);

  /** Send the device address **/
  XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, XIIC_WRITE_OPERATION);

  /** Enable the device and begin transmitting **/
  CtrlReg = XIIC_CR_ENABLE_DEVICE_MASK | XIIC_CR_MSMS_MASK |
    XIIC_CR_DIR_IS_TX_MASK;
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);

  return SendData(BaseAddress, SlaveAddress, BufferPtr, ByteCount);

} // end XI2c_Send()


Xuint8 XI2c_RSSend(Xuint32 BaseAddress, Xuint8 SlaveAddress, 
		   Xuint8 StartAddress, Xuint8 *BufferPtr, 
		   Xuint8 ByteCount) {

  Xuint8 CtrlReg;

  XI2c_mClearTXFifo(BaseAddress);
  
  /* Put the address into the FIFO to be sent and indicate that the operation
   * to be performed on the bus is a write operation */
  XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, XIIC_WRITE_OPERATION);
  XI2c_mSendStartAddress(BaseAddress, StartAddress);  

  /* MSMS must be set after putting data into transmit FIFO, indicate the
   * direction is transmit, this device is master and enable the IIC device */
  CtrlReg = XIIC_CR_ENABLE_DEVICE_MASK | XIIC_CR_MSMS_MASK | 
    XIIC_CR_DIR_IS_TX_MASK;
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);
    
  /** Wait for tx_fifo empty **/
  XI2c_mClearIisr(BaseAddress, XIIC_INTR_BNB_MASK);
  if( !TXSuccess(BaseAddress) ) {
    //print("XI2c_RSSend : 1 : TXFailure\r\n");
    return 0;
  }
  
  /** Initiate the repeated start **/
  CtrlReg = CtrlReg | XIIC_CR_REPEATED_START_MASK;
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);

  /** Send the device address **/
  XI2c_mSend7BitAddress(BaseAddress, SlaveAddress, XIIC_WRITE_OPERATION);

  return SendData(BaseAddress, SlaveAddress, BufferPtr, ByteCount);

} // end XI2c_RSSend()



static Xuint8 SendData(Xuint32 BaseAddress, Xuint8 SlaveAddress, 
		       Xuint8 *BufferPtr, Xuint8 ByteCount) {

  Xuint8 IntrStatus, CtrlReg;
  Xuint8 count = 0;
  
  for( count = 0; count < ByteCount-1; count++ ) 
    XIo_Out8(BaseAddress + XIIC_DTR_REG_OFFSET, *(BufferPtr++));

  /** Wait for tx_fifo empty **/
  XI2c_mClearIisr(BaseAddress, XIIC_INTR_BNB_MASK | XIIC_INTR_TX_ERROR_MASK);

  if( !TXSuccess(BaseAddress) ) {
    //print("SendData : 1 : TXFailure\r\n");
    return 0;
  }

  /** Generate the stop condition **/
  CtrlReg = XIIC_CR_ENABLE_DEVICE_MASK | XIIC_CR_DIR_IS_TX_MASK;
  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, CtrlReg);

  /** Send the last byte **/
  XIo_Out8(BaseAddress + XIIC_DTR_REG_OFFSET, *BufferPtr);

  /** Wait for tx_fifo empty **/
  if( !TXSuccess(BaseAddress) ) {
    //print("SendData : 2 : TXFailure\r\n");
    return 0;
  }

  /* The receive is complete, disable the IIC device and return the number of
   * bytes that was received, we must wait for the bnb flag to properly
   * disable the device. */
  do {
    IntrStatus = XIIF_V123B_READ_IISR(BaseAddress);
  } while(!(IntrStatus & XIIC_INTR_BNB_MASK));

  XIo_Out8(BaseAddress + XIIC_CR_REG_OFFSET, 0);
  
  return ++count;

} // end SendData()


static Xuint8 TXSuccess(Xuint32 BaseAddress) {
  Xuint32 IntrStatus, ErrorMask;
  
  ErrorMask = XIIC_INTR_TX_ERROR_MASK | XIIC_INTR_ARB_LOST_MASK | 
    XIIC_INTR_BNB_MASK;

  do {
    IntrStatus = XIIF_V123B_READ_IISR(BaseAddress);

    if( IntrStatus & ErrorMask )
      return 0;

  } while(!(IntrStatus & XIIC_INTR_TX_EMPTY_MASK));

  return 1;

} // end RecvAck()


static Xuint8 RXSuccess(Xuint32 BaseAddress) {
  Xuint32 IntrStatus, ErrorMask;
  
  ErrorMask = XIIC_INTR_ARB_LOST_MASK | XIIC_INTR_BNB_MASK;
  
  /** Wait until the rx_fifo is full **/
  while(1) {
    IntrStatus = XIIF_V123B_READ_IISR(BaseAddress);
    
    if( IntrStatus & XIIC_INTR_RX_FULL_MASK ) {
      XI2c_mClearIisr(BaseAddress, XIIC_INTR_RX_FULL_MASK);
      return 1;
    }
    
    if( IntrStatus & ErrorMask )
      return 0;
  }
  
} // end RXSuccess()


Xuint8 XI2c_SlaveAccess(Xuint32 BaseAddress, Xuint8 SlaveAddress, 
			Xuint8 *BufferPtr) {
  
  Xuint8 CtrlReg, StatusReg, SlaveSendFlag, DeviceAddress;
  Xuint8 IntrStatus, count = 0;

  XI2c_mClearTXFifo(BaseAddress);

  /** Set the device slave address **/
  DeviceAddress = SlaveAddress << 1;
  XIo_Out8(BaseAddress + XIIC_ADR_REG_OFFSET, DeviceAddress);

  /** Wait until the device is addressed as slave **/
  do {
    IntrStatus = XIIF_V123B_READ_IISR(BaseAddress);
  } while(!(IntrStatus & XIIC_INTR_AAS_MASK));

  XIo_Out8(BaseAddress + XIIC_RFD_REG_OFFSET, 0);

  /** Clear the recieve-fifo interrupt register **/
  XI2c_mClearIisr(BaseAddress, XIIC_INTR_RX_FULL_MASK);

  /** Read the status register to see if we need to receive or send data **/
  StatusReg = XIo_In8(BaseAddress + XIIC_SR_REG_OFFSET);
  
  XI2c_mClearIisr(BaseAddress, XIIC_INTR_NAAS_MASK | XIIC_INTR_BNB_MASK);

  SlaveSendFlag = StatusReg & XIIC_SR_MSTR_RDING_SLAVE_MASK;

  if( SlaveSendFlag ) {
    SlaveSendData(BaseAddress, BufferPtr);
  }
  else {
    SlaveRecvData(BaseAddress, BufferPtr);
  }

  XI2c_mClearIisr(BaseAddress, XIIC_INTR_AAS_MASK); 
  
  return 1;

} // XI2c_SlaveAccess()


static Xuint8 SlaveRecvData(Xuint32 BaseAddress, Xuint8 *BufferPtr) {
  Xuint8 IntrStatus;

  while(1) {
    IntrStatus = XIIF_V123B_READ_IISR(BaseAddress);
    if( IntrStatus & XIIC_INTR_NAAS_MASK ) {
      //xil_printf("Recv complete: %02x\r\n", IntrStatus);
      break;
    }
    if( IntrStatus & XIIC_INTR_RX_FULL_MASK ) {
      *(BufferPtr++) = XIo_In8(BaseAddress + XIIC_DRR_REG_OFFSET);
      //xil_printf("Data received: %d\r\n", *(BufferPtr-1));
      XI2c_mClearIisr(BaseAddress, XIIC_INTR_RX_FULL_MASK);
    }
  }

} // end SlaveRecvData()


static Xuint8 SlaveSendData(Xuint32 BaseAddress, Xuint8 *BufferPtr) {
  Xuint8 IntrStatus;

  XI2c_mClearIisr(BaseAddress, XIIC_INTR_TX_ERROR_MASK);

  while(1) {

    do {
      IntrStatus = XIIF_V123B_READ_IISR(BaseAddress);

      if( IntrStatus & (XIIC_INTR_TX_ERROR_MASK | XIIC_INTR_NAAS_MASK) ) {
	//xil_printf("Send complete: %02x\r\n", IntrStatus);
	return;
      }

    } while( !(IntrStatus & XIIC_INTR_TX_EMPTY_MASK) );

    //xil_printf("Data sent: %d\r\n", *BufferPtr);
    XIo_Out8(BaseAddress + XIIC_DTR_REG_OFFSET, *(BufferPtr++));
    XI2c_mClearIisr(BaseAddress, XIIC_INTR_TX_EMPTY_MASK);
  }
  
} // end SlaveSendData()


static void PrintStatus(Xuint32 BaseAddress) {

  Xuint8 CtrlReg, StatusReg, IntrStatus, DevAddress;
  Xuint8 RxFifoOcy, TxFifoOcy, RxFifoDepth;
   
  CtrlReg = XIo_In8(BaseAddress + XIIC_CR_REG_OFFSET);
  StatusReg = XIo_In8(BaseAddress + XIIC_SR_REG_OFFSET);
  IntrStatus = XIIF_V123B_READ_IISR(BaseAddress);
  DevAddress = XIo_In8(BaseAddress + XIIC_ADR_REG_OFFSET);
  RxFifoOcy = XIo_In8(BaseAddress + XIIC_RFO_REG_OFFSET);
  TxFifoOcy = XIo_In8(BaseAddress + XIIC_TFO_REG_OFFSET);
  RxFifoDepth = XIo_In8(BaseAddress + XIIC_RFD_REG_OFFSET);

  xil_printf("\r\nControl Reg:\t\t 0x%02x\r\n", CtrlReg);
  xil_printf("Status Reg:\t\t 0x%02x\r\n", StatusReg);
  xil_printf("Interrupts:\t\t 0x%02x\r\n", IntrStatus);
  //xil_printf("Device Address:\t\t 0x%02x\r\n", DevAddress);
  //xil_printf("Rx Fifo Occupancy:\t 0x%02x\r\n", RxFifoOcy);
  //xil_printf("Tx Fifo Occupancy:\t 0x%02x\r\n", TxFifoOcy);
  //xil_printf("Rx Fifo Depth:\t\t 0x%02x\r\n", RxFifoDepth);

} // end PrintStatus()
