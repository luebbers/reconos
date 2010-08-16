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
// Filename:        opb_ps2_dual_ref.v
//
// Description:     PS/2 memory mapped registers
//  
//////////////////////////////////////////////////////////////////////////////
// Structure:   opb_ps2_dual_ref.v 
//                  - opb_ipif_slv_ps2_reg_dual.v
//                  - ps2.v
//////////////////////////////////////////////////////////////////////////////
//
// History:
//   wph  10/10/01
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

module opb_ps2_dual_ref (
  OPB_BE,       // I [0:3]
  IPIF_Rst,     // I
  OPB_Select,   // I 
  OPB_DBus,     // I [0:31]
  OPB_Clk,      // I
  OPB_ABus,     // I [0:31]
  OPB_RNW,      // I
  OPB_seqAddr,  // I
  Sys_Intr1,    // O
  Sys_Intr2,    // O
  Sln_XferAck,  // O
  Sln_DBus,     // O [0:31]
  Sln_DBusEn,   // O
  Sln_errAck,   // O
  Sln_retry,    // O
  Sln_toutSup,  // O
  //PS2 #1 interface signal
  Clkin1,       // I  PS2 #1 Bi-di Clock in
  Clkpd1,       // O  PS2 #1 Bi-di Clock Pull down 
  Rx1,          // I  PS2 #1 Bi-di serial data in 
  Txpd1,        // O  PS2 #1 Bi-di serial data out pull down 
  //PS2 #2 interface signal
  Clkin2,       // I  PS2 #2 Bi-di Clock in
  Clkpd2,       // O  PS2 #2 Bi-di Clock Pull down 
  Rx2,          // I  PS2 #2 Bi-di serial data in 
  Txpd2         // O  PS2 #2 Bi-di serial data out pull down 
  );


///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

input [0:3]   OPB_BE;       // I [0:3]
input         IPIF_Rst;     // I
input         OPB_Select;   // I
input [0:31]  OPB_DBus;     // I [0:31]
input         OPB_Clk;      // I
input [0:31]  OPB_ABus;     // I [0:31]
input         OPB_RNW;      // I
input         OPB_seqAddr;  // I

output        Sys_Intr1;    // O
output        Sys_Intr2;    // O
output        Sln_XferAck;  // O
output [0:31] Sln_DBus;     // O [0:31]
output        Sln_DBusEn;   // O
output        Sln_errAck;   // O
output        Sln_retry;    // O
output        Sln_toutSup;  // O

//PS2 #1 interface signal
input         Clkin1;       // I  PS2 #1 Bi-di Clock in
output        Clkpd1;       // O  PS2 #1 Bi-di Clock Pull down
input         Rx1;          // I  PS2 #1 Bi-di serial data in
output        Txpd1;        // O  PS2 #1 Bi-di serial data out pull down
//PS2 #2 interface signal
input         Clkin2;       // I  PS2 #2 Bi-di Clock in
output        Clkpd2;       // O  PS2 #2 Bi-di Clock Pull down
input         Rx2;          // I  PS2 #2 Bi-di serial data in
output        Txpd2;        // O  PS2 #2 Bi-di serial data out pull down

///////////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////////

  parameter     C_BASEADDR  = 32'hA9000000;
  parameter     C_HIGHADDR  = 32'hA9001FFF;


///////////////////////////////////////////////////////////////////////////////
// Signal Declarations
///////////////////////////////////////////////////////////////////////////////

wire [0:31] Bus2IP_Addr;
wire [0:7]  Bus2IP_Data;
wire        Bus2IP_WrReq;
wire        Bus2IP_RdReq;
wire [0:15] Bus2IP_RegCE;
wire [0:7]  IP2Bus_Data;
wire [0:7]  IP2Bus_Data1;
wire [0:7]  IP2Bus_Data2;
wire        IP2Bus_Error;
wire        IP2Bus_Error1;
wire        IP2Bus_Error2;
wire        IP2Bus_RdAck;
wire        IP2Bus_RdAck1;
wire        IP2Bus_RdAck2;
wire        IP2Bus_Retry;
wire        IP2Bus_Retry1;
wire        IP2Bus_Retry2; 
wire        IP2Bus_ToutSup;
wire        IP2Bus_ToutSup1;
wire        IP2Bus_ToutSup2;
wire        IP2Bus_WrAck;
wire        IP2Bus_WrAck1;
wire        IP2Bus_WrAck2;
wire        IP2Bus_Intr;
wire        IP2Bus_Intr1;
wire        IP2Bus_Intr2;

///////////////////////////////////////////////////////////////////////////////
// Main Body of Code
///////////////////////////////////////////////////////////////////////////////

ps2 ps2_I1 ( 
  .Clk           (OPB_Clk),                         // I
  .Rst           (IPIF_Rst),                        // I
  .Bus2IP_RegCE  (Bus2IP_RegCE[0:7]),               // I [0:7]
  .Bus2IP_Data   (Bus2IP_Data),                     // I [0:7]
  .Bus2IP_RdReq  (Bus2IP_RdReq & ~Bus2IP_Addr[19]), // I
  .Bus2IP_WrReq  (Bus2IP_WrReq & ~Bus2IP_Addr[19]), // I
  .IP2Bus_Data   (IP2Bus_Data1),                    // O [0:7]
  .IP2Bus_Error  (IP2Bus_Error1),                   // O
  .IP2Bus_RdAck  (IP2Bus_RdAck1),                   // O
  .IP2Bus_Retry  (IP2Bus_Retry1),                   // O
  .IP2Bus_ToutSup(IP2Bus_ToutSup1),                 // O
  .IP2Bus_WrAck  (IP2Bus_WrAck1),                   // O
  .IP2Bus_Intr   (IP2Bus_Intr1),                    // O 
  .Clkin         (Clkin1),                          // I  PS2 Bi-di Clock in
  .Clkpd         (Clkpd1),                          // O  PS2 Bi-di Clock Pull down
  .Rx            (Rx1),                             // I  PS2 Bi-di serial data in
  .Txpd          (Txpd1)                            // O  PS2 Bi-di serial data out pull down
);

ps2 ps2_I2 (
  .Clk           (OPB_Clk),                         // I
  .Rst           (IPIF_Rst),                        // I
  .Bus2IP_RegCE  (Bus2IP_RegCE[8:15]),              // I [0:7]
  .Bus2IP_Data   (Bus2IP_Data),                     // I [0:7]
  .Bus2IP_RdReq  (Bus2IP_RdReq & Bus2IP_Addr[19]),  // I
  .Bus2IP_WrReq  (Bus2IP_WrReq & Bus2IP_Addr[19]),  // I
  .IP2Bus_Data   (IP2Bus_Data2),                    // O [0:7]
  .IP2Bus_Error  (IP2Bus_Error2),                   // O
  .IP2Bus_RdAck  (IP2Bus_RdAck2),                   // O
  .IP2Bus_Retry  (IP2Bus_Retry2),                   // O
  .IP2Bus_ToutSup(IP2Bus_ToutSup2),                 // O
  .IP2Bus_WrAck  (IP2Bus_WrAck2),                   // O
  .IP2Bus_Intr   (IP2Bus_Intr2),                    // O 
  .Clkin         (Clkin2),                          // I  PS2 Bi-di Clock in
  .Clkpd         (Clkpd2),                          // O  PS2 Bi-di Clock Pull down
  .Rx            (Rx2),                             // I  PS2 Bi-di serial data in
  .Txpd          (Txpd2)                            // O  PS2 Bi-di serial data out pull down
);
 
assign IP2Bus_Data[0:7] = Bus2IP_Addr[19]? IP2Bus_Data2[0:7] : IP2Bus_Data1[0:7];
assign IP2Bus_Error     = Bus2IP_Addr[19]? IP2Bus_Error2     : IP2Bus_Error1;
assign IP2Bus_RdAck     = Bus2IP_Addr[19]? IP2Bus_RdAck2     : IP2Bus_RdAck1;
assign IP2Bus_Retry     = Bus2IP_Addr[19]? IP2Bus_Retry2     : IP2Bus_Retry1;
assign IP2Bus_ToutSup   = Bus2IP_Addr[19]? IP2Bus_ToutSup2   : IP2Bus_ToutSup1;
assign IP2Bus_WrAck     = Bus2IP_Addr[19]? IP2Bus_WrAck2     : IP2Bus_WrAck1;

opb_ipif_slv_ps2_reg_dual #(C_BASEADDR) IPIF(
  // OPB Slave Signals
  .OPB_ABus       (OPB_ABus),       // I [0:31]
  .OPB_BE         (OPB_BE),         // I [0:3]
  .OPB_Clk        (OPB_Clk),        // I
  .OPB_DBus       (OPB_DBus),       // I [0:31]
  .OPB_RNW        (OPB_RNW),        // I
  .OPB_Rst        (IPIF_Rst),       // I
  .OPB_select     (OPB_Select),     // I
  .OPB_seqAddr    (OPB_seqAddr),    // I
  .Sl_DBus        (Sln_DBus),       // O [0:31]
  .Sl_DBusEn      (Sln_DBusEn),     // O
  .Sl_errAck      (Sln_errAck),     // O
  .Sl_retry       (Sln_retry),      // O
  .Sl_toutSup     (Sln_toutSup),    // O
  .Sl_xferAck     (Sln_XferAck),    // O
  .Sys_Intr1      (Sys_Intr1),      // O
  .Sys_Intr2      (Sys_Intr2),      // O
// IP Related Signals
  .IP2Bus_Data    (IP2Bus_Data),    // I  [0:7]
  .IP2Bus_Error   (IP2Bus_Error),   // I
  .IP2Bus_RdAck   (IP2Bus_RdAck),   // I
  .IP2Bus_Retry   (IP2Bus_Retry),   // I
  .IP2Bus_ToutSup (IP2Bus_ToutSup), // I
  .IP2Bus_WrAck   (IP2Bus_WrAck),   // I
  .IP2Bus_Intr1   (IP2Bus_Intr1),   // I 
  .IP2Bus_Intr2   (IP2Bus_Intr2),   // I 
  .Bus2IP_Addr    (Bus2IP_Addr),    // O [0:31]
  .Bus2IP_RegCE   (Bus2IP_RegCE),   // O [0:15] 
  .Bus2IP_Data    (Bus2IP_Data),    // O [0:7]
  .Bus2IP_RdReq   (Bus2IP_RdReq),   // O
  .Bus2IP_WrReq   (Bus2IP_WrReq)    // O
);

endmodule
