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

#include "xuartns550_l.h"
#include "xutil.h"
#include "ddr_header.h"

//====================================================

int main (void) {


   XCache_EnableICache(0x80000001);
   XCache_EnableDCache(0x80000000);

   /* Initialize RS232 - Set baudrate and number of stop bits */
   XUartNs550_SetBaud(XPAR_RS232_BASEADDR, XPAR_XUARTNS550_CLOCK_HZ, 9600);
   XUartNs550_mSetLineControlReg(XPAR_RS232_BASEADDR, XUN_LCR_8_DATA_BITS);
   print("-- Entering main() --\r\n");

   /* 
    * MemoryTest routine will not be run for the memory at 
    * 0x81000000 (FLASH_8Mx16)
    * because it is a read-only memory
    */


   /* 
    * MemoryTest routine will not be run for the memory at 
    * 0x00000000 (DDR_SDRAM_1)
    * because it is being used to hold a part of this application program
    */


   /* 
    * MemoryTest routine will not be run for the memory at 
    * 0xfffff000 (plb_bram_if_cntlr_1)
    * because it is being used to hold a part of this application program
    */


   print("-- Exiting main() --\r\n");
   XCache_DisableDCache();
   XCache_DisableICache();
   return 0;
}

