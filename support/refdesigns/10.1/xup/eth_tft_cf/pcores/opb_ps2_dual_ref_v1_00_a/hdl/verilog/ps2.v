//////////////////////////////////////////////////////////////////////////////
//
//     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
//     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR
//     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION
//     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION
//     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS
//     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
//     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
//     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
//     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
//     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
//     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//     FOR A PARTICULAR PURPOSE.
//     
//     (c) Copyright 2004 Xilinx, Inc.
//     All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////
// Filename:        ps2.v
//
// Description:     PS2 controller
//////////////////////////////////////////////////////////////////////////////
// Structure:       ps2.v
//                     - ps2_sie.v
//                     - ps2_reg.v
//////////////////////////////////////////////////////////////////////////////
//
// History:
//   wph        10/10/01
//
//////////////////////////////////////////////////////////////////////////////
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      Rst signals:                            "rst", "rst_n" 
//      generics:                               "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      processes:                              "*_PROCESS" 
//      component instantiations:               "<ENTITY_>I_<#|FUNC>
//////////////////////////////////////////////////////////////////////////////

module ps2 (
  Clk,             // I
  Rst,             // I
  Bus2IP_RegCE,    // I [0:7] 
  Bus2IP_Data,     // I [0:7]
  Bus2IP_RdReq,    // I
  Bus2IP_WrReq,    // I
  IP2Bus_Data,     // O [0:7]
  IP2Bus_Error,    // O 
  IP2Bus_RdAck,    // O
  IP2Bus_Retry,    // O
  IP2Bus_ToutSup,  // O
  IP2Bus_WrAck,    // O
  IP2Bus_Intr,     // O 
  Clkin,           // I  PS2 Bi-di Clock in
  Clkpd,           // O  PS2 Bi-di Clock Pull down
  Rx,              // I  PS2 Bi-di serial data in
  Txpd             // O  PS2 Bi-di serial data out pull down 
);

  ///////////////////////////////////////////////////////////////////////////////
  // Port Declarations
  ///////////////////////////////////////////////////////////////////////////////
input         Clk;             // I
input         Rst;             // I
input  [0:7]  Bus2IP_RegCE;    // I [0:7]
input  [0:7]  Bus2IP_Data;     // I [0:7]
input         Bus2IP_RdReq;    // I
input         Bus2IP_WrReq;    // I
output [0:7]  IP2Bus_Data;     // O [0:7]
output        IP2Bus_Error;    // O
output        IP2Bus_RdAck;    // O
output        IP2Bus_Retry;    // O
output        IP2Bus_ToutSup;  // O
output        IP2Bus_WrAck;    // O
output        IP2Bus_Intr;     // O

input  Clkin;
output Clkpd;
input  Rx;
output Txpd;

  ///////////////////////////////////////////////////////////////////////////////
  // Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////
  // signal Declarations
  ///////////////////////////////////////////////////////////////////////////////

  wire        srst          ; 
  wire        rx_full_sta   ; 
  wire        rx_full_set   ; 
  wire        rx_err_set    ; 
  wire        rx_ovf_set    ; 
  wire        tx_full_sta   ; 
  wire        tx_full_clr   ; 
  wire        tx_ack_set    ; 
  wire        tx_noack_set  ; 
  wire        wdt_tout_set  ;
  wire [0:7]  tx_data       ;
  wire [0:7]  rx_data       ;
 
  ///////////////////////////////////////////////////////////////////////////////
  // begin
  ///////////////////////////////////////////////////////////////////////////////

ps2_sie ps2_sie_I (
  .Clk            (Clk),             // I  system clock
  .Rst            (srst),            // I  system reset + software reset (offset)
  .Clkin          (Clkin),           // I  PS2 Bi-di Clock in
  .Clkpd          (Clkpd),           // O  PS2 Bi-di Clock Pull down
  .Rx             (Rx),              // I  PS2 Bi-di serial data in
  .Txpd           (Txpd),            // O  PS2 Bi-di serial data out pull down
  .rx_full_sta    (rx_full_sta),     // I
  .rx_full_set    (rx_full_set),     // O
  .rx_err_set     (rx_err_set),      // O
  .rx_ovf_set     (rx_ovf_set),      // O
  .tx_full_sta    (tx_full_sta),     // I
  .tx_full_clr    (tx_full_clr),     // O
  .tx_ack_set     (tx_ack_set),      // O
  .tx_noack_set   (tx_noack_set),    // O
  .wdt_tout_set   (wdt_tout_set),    // O
  .tx_data        (tx_data),         // I
  .rx_data        (rx_data)          // O
 
);


ps2_reg ps2_reg_I(
  .Clk            (Clk),             // I  system clock
  .Rst            (Rst),             // I  system reset
  .Bus2IP_RegCE   (Bus2IP_RegCE),    // I [0:7] 
  .Bus2IP_Data    (Bus2IP_Data),     // I [0:7]
  .Bus2IP_RdReq   (Bus2IP_RdReq),    // I
  .Bus2IP_WrReq   (Bus2IP_WrReq),    // I
  .IP2Bus_Data    (IP2Bus_Data),     // O [0:7]
  .IP2Bus_Error   (IP2Bus_Error),    // O
  .IP2Bus_RdAck   (IP2Bus_RdAck),    // O
  .IP2Bus_Retry   (IP2Bus_Retry),    // O
  .IP2Bus_ToutSup (IP2Bus_ToutSup),  // O
  .IP2Bus_WrAck   (IP2Bus_WrAck),    // O
  .IP2Bus_Intr    (IP2Bus_Intr),     // O 

  .srst           (srst),            // O global rest + software reset, send to ps2_sie
  .rx_full_sta    (rx_full_sta),     // O
  .rx_full_set    (rx_full_set),     // I
  .rx_err_set     (rx_err_set),      // I
  .rx_ovf_set     (rx_ovf_set),      // I
  .tx_full_sta    (tx_full_sta),     // O
  .tx_full_clr    (tx_full_clr),     // I
  .tx_ack_set     (tx_ack_set),      // I
  .tx_noack_set   (tx_noack_set),    // I
  .wdt_tout_set   (wdt_tout_set),    // I 
  .tx_data        (tx_data),         // O [0:7]
  .rx_data        (rx_data)          // I [0:7]
  
);
 

endmodule
