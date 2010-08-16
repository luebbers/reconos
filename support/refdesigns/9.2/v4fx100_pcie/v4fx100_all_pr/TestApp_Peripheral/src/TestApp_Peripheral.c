/*
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * Xilinx EDK 9.1 EDK_J.19
 *
 * This file is a sample test application
 *
 * This application is intended to test and/or illustrate some 
 * functionality of your system.  The contents of this file may
 * vary depending on the IP in your system and may use existing
 * IP driver functions.  These drivers will be generated in your
 * XPS project when you run the "Generate Libraries" menu item
 * in XPS.
 *
 * Your XPS project directory is at:
 *    /home/luebbers/work/reconos/trunk/hw/refdesigns/9.1/v4fx100_pcie/v4fx100_all/
 */


// Located in: ppc405_0/include/xparameters.h
#include "xparameters.h"

#include "xcache_l.h"

#include "stdio.h"

#include "xintc.h"
#include "xexception_l.h"
#include "intc_header.h"
#include "xuartns550_l.h"
#include "xbasic_types.h"
#include "xgpio.h"
#include "gpio_header.h"
#include "gpio_intr_header.h"
#include "xemac.h"
#include "emac_header.h"
#include "emac_intr_header.h"
#include "xsysace.h"
#include "sysace_header.h"

#define GPIO_CHANNEL1 1

//====================================================

int main (void) {


   static XIntc intc;

   XCache_EnableICache(0x80000001);
   XCache_EnableDCache(0x80000000);

   /* Initialize RS232 - Set baudrate and number of stop bits */
   XUartNs550_SetBaud(XPAR_RS232_BASEADDR, XPAR_XUARTNS550_CLOCK_HZ, 9600);
   XUartNs550_mSetLineControlReg(XPAR_RS232_BASEADDR, XUN_LCR_8_DATA_BITS);
   static XGpio DIP_Switches_8Bit_Gpio;
   static XGpio Push_Buttons_3Bit_Gpio;
   static XEmac Ethernet_MAC_Emac;
   print("-- Entering main() --\r\n");


   {
      XStatus status;
      
      print("\r\n Runnning IntcSelfTestExample() for opb_intc_0...\r\n");
      
      status = IntcSelfTestExample(XPAR_OPB_INTC_0_DEVICE_ID);
      
      if (status == 0) {
         print("IntcSelfTestExample PASSED\r\n");
      }
      else {
         print("IntcSelfTestExample FAILED\r\n");
      }
   } 
	
   {
       XStatus Status;

       Status = IntcInterruptSetup(&intc, XPAR_OPB_INTC_0_DEVICE_ID);
       if (Status == 0) {
          print("Intc Interrupt Setup PASSED\r\n");
       } 
       else {
         print("Intc Interrupt Setup FAILED\r\n");
      } 
   }

   /*
    * Peripheral SelfTest will not be run for RS232
    * because it has been selected as the STDOUT device
    */



   {
      Xuint32 status;
      
      print("\r\nRunning GpioOutputExample() for LEDs_8Bit...\r\n");

      status = GpioOutputExample(XPAR_LEDS_8BIT_DEVICE_ID,8);
      
      if (status == 0) {
         print("GpioOutputExample PASSED.\r\n");
      }
      else {
         print("GpioOutputExample FAILED.\r\n");
      }
   }


   {
      Xuint32 status;
      
      print("\r\nRunning GpioInputExample() for DIP_Switches_8Bit...\r\n");

      Xuint32 DataRead;
      
      status = GpioInputExample(XPAR_DIP_SWITCHES_8BIT_DEVICE_ID, &DataRead);
      
      if (status == 0) {
         xil_printf("GpioInputExample PASSED. Read data:0x%X\r\n", DataRead);
      }
      else {
         print("GpioInputExample FAILED.\r\n");
      }
   }
   {
      
      XStatus Status;
        
      Xuint32 DataRead;
      
      print(" Press button to Generate Interrupt\r\n");
      
      Status = GpioIntrExample(&intc, &DIP_Switches_8Bit_Gpio, \
                               XPAR_DIP_SWITCHES_8BIT_DEVICE_ID, \
                               XPAR_OPB_INTC_0_DIP_SWITCHES_8BIT_IP2INTC_IRPT_INTR, \
                               GPIO_CHANNEL1, &DataRead);
	
      if (Status == 0 ){
             if(DataRead == 0)
                print("No button pressed. \r\n");
             else
                print("Gpio Interrupt Test PASSED. \r\n"); 
      } 
      else {
         print("Gpio Interrupt Test FAILED.\r\n");
      }
	
   }


   {
      Xuint32 status;
      
      print("\r\nRunning GpioInputExample() for Push_Buttons_3Bit...\r\n");

      Xuint32 DataRead;
      
      status = GpioInputExample(XPAR_PUSH_BUTTONS_3BIT_DEVICE_ID, &DataRead);
      
      if (status == 0) {
         xil_printf("GpioInputExample PASSED. Read data:0x%X\r\n", DataRead);
      }
      else {
         print("GpioInputExample FAILED.\r\n");
      }
   }
   {
      
      XStatus Status;
        
      Xuint32 DataRead;
      
      print(" Press button to Generate Interrupt\r\n");
      
      Status = GpioIntrExample(&intc, &Push_Buttons_3Bit_Gpio, \
                               XPAR_PUSH_BUTTONS_3BIT_DEVICE_ID, \
                               XPAR_OPB_INTC_0_PUSH_BUTTONS_3BIT_IP2INTC_IRPT_INTR, \
                               GPIO_CHANNEL1, &DataRead);
	
      if (Status == 0 ){
             if(DataRead == 0)
                print("No button pressed. \r\n");
             else
                print("Gpio Interrupt Test PASSED. \r\n"); 
      } 
      else {
         print("Gpio Interrupt Test FAILED.\r\n");
      }
	
   }


   {
      XStatus status;
      
      print("\r\nRunning EmacPolledExample() for Ethernet_MAC...\r\n");
      status = EmacPolledExample(XPAR_ETHERNET_MAC_DEVICE_ID);
      if (status == 0) {
         print("EmacPolledExample PASSED\r\n");
      }
      else {
         print("EmacPolledExample FAILED\r\n");
      }
   }
   {

#ifdef CACHE_H
       XCache_DisableDCache();
       XCache_DisableICache();
#endif

      XStatus Status;

      print("\r\nRunning EmacIntrExample() for Ethernet_MAC...\r\n");
      Status = EmacIntrExample(&intc, &Ethernet_MAC_Emac, \
                               XPAR_ETHERNET_MAC_DEVICE_ID, \
                               XPAR_OPB_INTC_0_ETHERNET_MAC_IP2INTC_IRPT_INTR);
      if(Status == 0) {
         print("Emac Interrupt Test PASSED.\r\n");
      } 
      else {
         print("Emac Interrupt Test FAILED.\r\n");
      }

   }


   {
      XStatus status;
      
      print("\r\nRunning SysAceSelfTestExample() for SysACE_CompactFlash...\r\n");
      status = SysAceSelfTestExample(XPAR_SYSACE_COMPACTFLASH_DEVICE_ID);
      if (status == 0) {
         print("SysAceSelfTestExample PASSED\r\n");
      }
      else {
         print("SysAceSelfTestExample FAILED\r\n");
      }
   }

   print("-- Exiting main() --\r\n");
   XCache_DisableDCache();
   XCache_DisableICache();
   return 0;
}

