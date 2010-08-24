/* $Id: xuartns550.h,v 1.1 2006/02/17 22:43:40 moleres Exp $ */
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
*       (c) Copyright 2002-2005 Xilinx Inc.
*       All rights reserved.
*
*****************************************************************************/
/****************************************************************************/
/**
*
* @file xuartns550.h
*
* This driver supports the following features in the Xilinx 16450/16550
* compatible UART.
*
* - Dynamic data format (baud rate, data bits, stop bits, parity)
* - Polled mode
* - Interrupt driven mode
* - Transmit and receive FIFOs (16 bytes each for the 16550)
* - Access to the external modem control lines and the two discrete outputs
*
* The only difference between the 16450 and the 16550 is the addition of
* transmit and receive FIFOs in the 16550.
*
* <b>Initialization & Configuration</b>
*
* The XUartNs550_Config structure is used by the driver to configure itself. This
* configuration structure is typically created by the tool-chain based on HW
* build properties.
*
* To support multiple runtime loading and initialization strategies employed
* by various operating systems, the driver instance can be initialized in one
* of the following ways:
*
*   - XUartNs550_Initialize(InstancePtr, DeviceId) - The driver looks up its own
*     configuration structure created by the tool-chain based on an ID provided
*     by the tool-chain.
*
*   - XUartNs550_CfgInitialize(InstancePtr, CfgPtr, EffectiveAddr) - Uses a
*     configuration structure provided by the caller. If running in a system
*     with address translation, the provided virtual memory base address
*     replaces the physical address present in the configuration structure.
*
* <b>Baud Rate</b>
*
* The UART has an internal baud rate generator that is clocked at a specified
* input clock frequency. Not all baud rates can be generated from some clock
* frequencies. The requested baud rate is checked using the provided clock for
* the system, and checked against the acceptable error range. An error may be
* returned from some functions indicating the baud rate was in error because
* it could not be generated.
*
* <b>Interrupts</b>
*
* The device does not have any way to disable the receiver such that the
* receive FIFO may contain unwanted data. The FIFOs are not flushed when the
* driver is initialized, but a function is provided to allow the user to reset
* the FIFOs if desired.
*
* The driver defaults to no interrupts at initialization such that interrupts
* must be enabled if desired. An interrupt is generated for any of the following
* conditions.
*
* - Transmit FIFO is empty
* - Data in the receive FIFO equal to the receive threshold
* - Data in the receiver when FIFOs are disabled
* - Any receive status error or break condition detected
* - Data in the receive FIFO for 4 character times without receiver activity
* - A change of a modem signal
*
* The application can control which interrupts are enabled using the SetOptions
* function.
*
* In order to use interrupts, it is necessary for the user to connect the driver
* interrupt handler, XUartNs550_InterruptHandler(), to the interrupt system of
* the application. This function does not save and restore the processor context
* such that the user must provide it. A handler must be set for the driver such
* that the handler is called when interrupt events occur. The handler is called
* from interrupt context and is designed to allow application specific processing
* to be performed.
*
* The functions, XUartNs550_Send() and XUartNs550_Recv(), are provided in the
* driver to allow data to be sent and received. They are designed to be used in
* polled or interrupt modes.
*
* @note
*
* The default configuration for the UART after initialization is:
*
* - 19,200 bps or XPAR_DEFAULT_BAUD_RATE if defined
* - 8 data bits
* - 1 stop bit
* - no parity
* - FIFO's are enabled with a receive threshold of 8 bytes
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date     Changes
* ----- ---- -------- -----------------------------------------------
* 1.00a ecm  08/16/01 First release
* 1.00b jhl  03/11/02 Repartitioned the driver for smaller files.
* 1.01a jvb  12/14/05 I separated dependency on the static config table and
*                     xparameters.h from the driver initialization by moving
*                     _Initialize and _LookupConfig to _sinit.c. I also added
*                     the new _CfgInitialize routine.
* </pre>
*
*****************************************************************************/

#ifndef XUARTNS550_H /* prevent circular inclusions */
#define XUARTNS550_H /* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files ********************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xuartns550_l.h"

/************************** Constant Definitions ****************************/

/* The following constants indicate the max and min baud rates and these
 * numbers are based only on the testing that has been done. The hardware
 * is capable of other baud rates.
 */
#define XUN_NS16550_MAX_RATE        115200
#define XUN_NS16550_MIN_RATE        300

/** @name Configuration options
 * @{
 */
/**
 * These constants specify the options that may be set or retrieved
 * with the driver, each is a unique bit mask such that multiple options
 * may be specified.  These constants indicate the function of the option
 * when in the active state.
 *
 * <pre>
 * XUN_OPTION_SET_BREAK         Set a break condition
 * XUN_OPTION_LOOPBACK          Enable local loopback
 * XUN_OPTION_DATA_INTR         Enable data interrupts
 * XUN_OPTION_MODEM_INTR        Enable modem interrupts
 * XUN_OPTION_FIFOS_ENABLE      Enable FIFOs
 * XUN_OPTION_RESET_TX_FIFO     Reset the transmit FIFO
 * XUN_OPTION_RESET_RX_FIFO     Reset the receive FIFO
 * XUN_OPTION_ASSERT_OUT2       Assert out2 signal
 * XUN_OPTION_ASSERT_OUT1       Assert out1 signal
 * XUN_OPTION_ASSERT_RTS        Assert RTS signal
 * XUN_OPTION_ASSERT_DTR        Assert DTR signal
 * </pre>
 */
#define XUN_OPTION_SET_BREAK        0x0400
#define XUN_OPTION_LOOPBACK         0x0200
#define XUN_OPTION_DATA_INTR        0x0100
#define XUN_OPTION_MODEM_INTR       0x0080
#define XUN_OPTION_FIFOS_ENABLE     0x0040
#define XUN_OPTION_RESET_TX_FIFO    0x0020
#define XUN_OPTION_RESET_RX_FIFO    0x0010
#define XUN_OPTION_ASSERT_OUT2      0x0008
#define XUN_OPTION_ASSERT_OUT1      0x0004
#define XUN_OPTION_ASSERT_RTS       0x0002
#define XUN_OPTION_ASSERT_DTR       0x0001
/*@}*/

/** @name Data format values
 * @{
 */
/**
 * These constants specify the data format that may be set or retrieved
 * with the driver.  The data format includes the number of data bits, the
 * number of stop bits and parity.
 *
 * <pre>
 * XUN_FORMAT_8_BITS            8 data bits
 * XUN_FORMAT_7_BITS            7 data bits
 * XUN_FORMAT_6_BITS            6 data bits
 * XUN_FORMAT_5_BITS            5 data bits
 * XUN_FORMAT_EVEN_PARITY       Even parity
 * XUN_FORMAT_ODD_PARITY        Odd parity
 * XUN_FORMAT_NO_PARITY         No parity
 * XUN_FORMAT_2_STOP_BIT        2 stop bits
 * XUN_FORMAT_1_STOP_BIT        1 stop bit
 * </pre>
 */
#define XUN_FORMAT_8_BITS          3
#define XUN_FORMAT_7_BITS          2
#define XUN_FORMAT_6_BITS          1
#define XUN_FORMAT_5_BITS          0

#define XUN_FORMAT_EVEN_PARITY     2
#define XUN_FORMAT_ODD_PARITY      1
#define XUN_FORMAT_NO_PARITY       0

#define XUN_FORMAT_2_STOP_BIT      1
#define XUN_FORMAT_1_STOP_BIT      0
/*@}*/

/** @name FIFO trigger values
 * @{
 */
/*
 * These constants specify receive FIFO trigger levels which specify
 * the number of bytes at which a receive data event (interrupt) will occur.
 *
 * <pre>
 * XUN_FIFO_TRIGGER_14          14 byte trigger level
 * XUN_FIFO_TRIGGER_08           8 byte trigger level
 * XUN_FIFO_TRIGGER_04           4 byte trigger level
 * XUN_FIFO_TRIGGER_01           1 byte trigger level
 * </pre>
 */
#define XUN_FIFO_TRIGGER_14         0xC0
#define XUN_FIFO_TRIGGER_08         0x80
#define XUN_FIFO_TRIGGER_04         0x40
#define XUN_FIFO_TRIGGER_01         0x00
/*@}*/

/** @name Modem status values
 * @{
 */
/**
 * These constants specify the modem status that may be retrieved
 * from the driver.
 *
 * <pre>
 * XUN_MODEM_DCD_DELTA_MASK         DCD signal changed state
 * XUN_MODEM_DSR_DELTA_MASK         DSR signal changed state
 * XUN_MODEM_CTS_DELTA_MASK         CTS signal changed state
 * XUN_MODEM_RINGING_MASK           Ring signal is active
 * XUN_MODEM_DSR_MASK               Current state of DSR signal
 * XUN_MODEM_CTS_MASK               Current state of CTS signal
 * XUN_MODEM_DCD_MASK               Current state of DCD signal
 * XUN_MODEM_RING_STOP_MASK         Ringing has stopped
 * </pre>
 */
#define XUN_MODEM_DCD_DELTA_MASK  0x80
#define XUN_MODEM_DSR_DELTA_MASK  0x02
#define XUN_MODEM_CTS_DELTA_MASK  0x01
#define XUN_MODEM_RINGING_MASK    0x40
#define XUN_MODEM_DSR_MASK        0x20
#define XUN_MODEM_CTS_MASK        0x10
#define XUN_MODEM_DCD_MASK        0x08
#define XUN_MODEM_RING_STOP_MASK  0x04
/*@}*/

/** @name Callback events
 * @{
 */
/**
 * These constants specify the handler events that are passed to
 * a handler from the driver.  These constants are not bit masks such that
 * only one will be passed at a time to the handler.
 *
 * <pre>
 * XUN_EVENT_RECV_DATA          Data has been received
 * XUN_EVENT_RECV_TIMEOUT       A receive timeout occurred
 * XUN_EVENT_SENT_DATA          Data has been sent
 * XUN_EVENT_RECV_ERROR         A receive error was detected
 * XUN_EVENT_MODEM              A change in modem status
 * </pre>
 */
#define XUN_EVENT_RECV_DATA       1
#define XUN_EVENT_RECV_TIMEOUT    2
#define XUN_EVENT_SENT_DATA       3
#define XUN_EVENT_RECV_ERROR      4
#define XUN_EVENT_MODEM           5
/*@}*/

/** @name Error values
 * @{
 */
/**
 * These constants specify the errors that may be retrieved from
 * the driver using the XUartNs550_GetLastErrors function. All of them are
 * bit masks, except no error, such that multiple errors may be specified.
 *
 * <pre>
 * XUN_ERROR_BREAK_MASK         Break detected
 * XUN_ERROR_FRAMING_MASK       Receive framing error
 * XUN_ERROR_PARITY_MASK        Receive parity error
 * XUN_ERROR_OVERRUN_MASK       Receive overrun error
 * XUN_ERROR_NONE               No error
 * </pre>
 */
#define XUN_ERROR_BREAK_MASK        0x10
#define XUN_ERROR_FRAMING_MASK      0x08
#define XUN_ERROR_PARITY_MASK       0x04
#define XUN_ERROR_OVERRUN_MASK      0x02
#define XUN_ERROR_NONE              0x00
/*@}*/

/**************************** Type Definitions ******************************/

/**
 * This typedef contains configuration information for the device.
 */
typedef struct
{
    Xuint16 DeviceId;        /**< Unique ID  of device */
    Xuint32 BaseAddress;     /**< Base address of device (IPIF) */
    Xuint32 InputClockHz;    /**< Input clock frequency */
    Xuint32 DefaultBaudRate; /**< Baud Rate in bps, ie 1200 */
} XUartNs550_Config;

/*
 * The following data type is used to manage the buffers that are handled
 * when sending and receiving data in the interrupt mode.
 */
typedef struct
{
    Xuint8 *NextBytePtr;
    unsigned int RequestedBytes;
    unsigned int RemainingBytes;
} XUartNs550Buffer;

/**
 * This data type allows the data format of the device to be set
 * and retrieved.
 */
typedef struct
{
    Xuint32 BaudRate;       /**< In bps, ie 1200 */
    Xuint32 DataBits;       /**< Number of data bits */
    Xuint32 Parity;         /**< Parity */
    Xuint8 StopBits;        /**< Number of stop bits */
} XUartNs550Format;

/**
 * This data type defines a handler which the application must define
 * when using interrupt mode.  The handler will be called from the driver in an
 * interrupt context to handle application specific processing.
 *
 * @param CallBackRef is a callback reference passed in by the upper layer
 *        when setting the handler, and is passed back to the upper layer when
 *        the handler is called.
 * @param Event contains one of the event constants indicating why the handler
 *        is being called.
 * @param EventData contains the number of bytes sent or received at the time of
 *        the call for send and receive events and contains the modem status for
 *        modem events.
 */
typedef void (*XUartNs550_Handler)(void *CallBackRef, Xuint32 Event,
                                   unsigned int EventData);

/**
 * UART statistics
 */
typedef struct
{
    Xuint16 TransmitInterrupts;         /**< Number of transmit interrupts */
    Xuint16 ReceiveInterrupts;          /**< Number of receive interrupts */
    Xuint16 StatusInterrupts;           /**< Number of status interrupts */
    Xuint16 ModemInterrupts;            /**< Number of modem interrupts */
    Xuint16 CharactersTransmitted;      /**< Number of characters transmitted */
    Xuint16 CharactersReceived;         /**< Number of characters received */
    Xuint16 ReceiveOverrunErrors;       /**< Number of receive overruns */
    Xuint16 ReceiveParityErrors;        /**< Number of receive parity errors */
    Xuint16 ReceiveFramingErrors;       /**< Number of receive framing errors */
    Xuint16 ReceiveBreakDetected;       /**< Number of receive breaks */
} XUartNs550Stats;

/**
 * The XUartNs550 driver instance data. The user is required to allocate a
 * variable of this type for every UART 16550/16450 device in the system.
 * A pointer to a variable of this type is then passed to the driver API
 * functions.
 */
typedef struct
{
    XUartNs550Stats Stats;      /* Component Statistics */
    Xuint32 BaseAddress;        /* Base address of device (IPIF) */
    Xuint32 InputClockHz;       /* Input clock frequency */
    Xuint32 IsReady;            /* Device is initialized and ready */
    Xuint32 BaudRate;           /* current baud rate of hw */
    Xuint8  LastErrors;         /* the accumulated errors */

    XUartNs550Buffer SendBuffer;
    XUartNs550Buffer ReceiveBuffer;

    XUartNs550_Handler Handler;
    void *CallBackRef;           /* Callback reference for control handler */
} XUartNs550;


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Function Prototypes *****************************/

/*
 * Initialization functions in xuartns550_sinit.c
 */
XStatus XUartNs550_Initialize(XUartNs550 *InstancePtr, Xuint16 DeviceId);
XUartNs550_Config *XUartNs550_LookupConfig(Xuint16 DeviceId);

/*
 * required functions in xuartns550.c
 */
XStatus XUartNs550_CfgInitialize(XUartNs550 *InstancePtr,
                                 XUartNs550_Config *Config,
                                 Xuint32 EffectiveAddr);
unsigned int XUartNs550_Send(XUartNs550 *InstancePtr, Xuint8 *BufferPtr,
                             unsigned int NumBytes);
unsigned int XUartNs550_Recv(XUartNs550 *InstancePtr, Xuint8 *BufferPtr,
                             unsigned int NumBytes);

/*
 * options functions in xuartns550_options.c
 */
XStatus XUartNs550_SetOptions(XUartNs550 *InstancePtr, Xuint16 Options);
Xuint16 XUartNs550_GetOptions(XUartNs550 *InstancePtr);

XStatus XUartNs550_SetFifoThreshold(XUartNs550 *InstancePtr,
                                    Xuint8 TriggerLevel);
Xuint8 XUartNs550_GetFifoThreshold(XUartNs550 *InstancePtr);

Xboolean XUartNs550_IsSending(XUartNs550 *InstancePtr);

Xuint8 XUartNs550_GetLastErrors(XUartNs550 *InstancePtr);

Xuint8 XUartNs550_GetModemStatus(XUartNs550 *InstancePtr);

/*
 * data format functions in xuartns550_format.c
 */
XStatus XUartNs550_SetDataFormat(XUartNs550 *InstancePtr,
                                 XUartNs550Format *Format);
void XUartNs550_GetDataFormat(XUartNs550 *InstancePtr,
                              XUartNs550Format *Format);
/*
 * interrupt functions in xuartns550_intr.c
 */
void XUartNs550_SetHandler(XUartNs550 *InstancePtr, XUartNs550_Handler FuncPtr,
                           void *CallBackRef);

void XUartNs550_InterruptHandler(XUartNs550 *InstancePtr);

/*
 * statistics functions in xuartns550_stats.c
 */
void XUartNs550_GetStats(XUartNs550 *InstancePtr, XUartNs550Stats *StatsPtr);
void XUartNs550_ClearStats(XUartNs550 *InstancePtr);

/*
 * self-test functions in xuartns550_selftest.c
 */
XStatus XUartNs550_SelfTest(XUartNs550 *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif            /* end of protection macro */

