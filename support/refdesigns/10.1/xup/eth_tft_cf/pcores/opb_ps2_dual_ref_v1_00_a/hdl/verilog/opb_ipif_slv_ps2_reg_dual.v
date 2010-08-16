//-------------------------------------------------------------------------
// OPB Slave IPIF with PS2 Control Register Protocol Interface - Module
//-------------------------------------------------------------------------
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
//-------------------------------------------------------------------------
// Filename:     opb_ipif_slv_ps2_reg_dual.v
// 
// Description:    
//   This module implements an IPIF with a slave simple Control Register 
//   interface.  
//
// Design Notes:
//   The IP interface has a 32 bit data path with a 32 bit address bus.
//   This design pipelines the signals going into or out of the IP to
//   provide better timing and allow higher clock frequencies at the
//   expense of greater access latency. 
//
//-------------------------------------------------------------------------
// Structure: 
// -- opb_ipif_slv_ps2_reg_dual.v
//
//-------------------------------------------------------------------------
// Author:      KD
// History:
//   KD        5/15/01 -- EA 2 Release
//   BF        5/17/01 -- Modified for IIC Control Register IPIF
//   WPH      10/10/01 -- Modified for PS2 Control Register IPIF
// 
//-------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                    "*_n"
//      clock signals:                         "clk", "clk_div#", "clk_#x" 
//      reset signals:                         "rst", "rst_n" 
//      generics/parameters:                   "C_*" 
//      user defined types:                    "*_TYPE" 
//      state machine next state:              "*_ns" 
//      state machine current state:           "*_cs" 
//      combinatorial signals:                 "*_com" 
//      pipelined or register delay signals:   "*_d#" 
//      counter signals:                       "*cnt*"
//      clock enable signals:                  "*_ce" 
//      internal version of output port        "*_i"
//      device pins:                           "*_pin" 
//      ports:                                 - Names begin w/ Uppercase 
//      processes:                             "*_PROCESS" 
//      component instantiations:              "<ENTITY_>I_<#|FUNC>
//-------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////

module opb_ipif_slv_ps2_reg_dual (
  // OPB Slave Signals
  OPB_ABus,        // I [0:31]
  OPB_BE,          // I [0:3]
  OPB_Clk,         // I
  OPB_DBus,        // I [0:31]
  OPB_RNW,         // I
  OPB_Rst,         // I
  OPB_select,      // I
  OPB_seqAddr,     // I
  Sl_DBus,         // O [0:31]
  Sl_DBusEn,       // O
  Sl_errAck,       // O
  Sl_retry,        // O
  Sl_toutSup,      // O
  Sl_xferAck,      // O
  Sys_Intr1,       // O 
  Sys_Intr2,       // O 
  // IP Related Signals
  IP2Bus_Data,     // I [0:7]
  IP2Bus_Error,    // I
  IP2Bus_RdAck,    // I
  IP2Bus_Retry,    // I
  IP2Bus_ToutSup,  // I
  IP2Bus_WrAck,    // I
  IP2Bus_Intr1,    // I 
  IP2Bus_Intr2,    // I 
  Bus2IP_Addr,     // O [0:31]
  Bus2IP_RegCE,    // O [0:15] 
  Bus2IP_Data,     // O [0:7]
  Bus2IP_RdReq,    // O
  Bus2IP_WrReq     // O
  );
   

///////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////

  // OPB Slave Signals
  input  [0:31] OPB_ABus;
  input  [0:3]  OPB_BE;
  input         OPB_Clk;
  input  [0:31] OPB_DBus;
  input         OPB_RNW;
  input         OPB_Rst;
  input         OPB_select;
  input         OPB_seqAddr;
  output [0:31] Sl_DBus;
  output        Sl_DBusEn;
  output        Sl_errAck;
  output        Sl_retry;
  output        Sl_toutSup;
  output        Sl_xferAck;
  output        Sys_Intr1;
  output        Sys_Intr2;
  // IP Related Signals
  input  [0:7] IP2Bus_Data;      
  input         IP2Bus_Error;
  input         IP2Bus_RdAck;
  input         IP2Bus_Retry;
  input         IP2Bus_ToutSup;
  input         IP2Bus_WrAck;
  input         IP2Bus_Intr1;
  input         IP2Bus_Intr2;
  output [0:31] Bus2IP_Addr;
  output [0:15] Bus2IP_RegCE;          
  output [0:7]  Bus2IP_Data;           
  output        Bus2IP_RdReq;
  output        Bus2IP_WrReq;


///////////////////////////////////////////////////////////////////////////
// Parameter Declarations
///////////////////////////////////////////////////////////////////////////

  parameter     C_PS2_BAR         = 32'ha900_0000;


///////////////////////////////////////////////////////////////////////////
// Signal Declarations
///////////////////////////////////////////////////////////////////////////

   wire        addr_decode_hit;
   reg         addr_hit;
   wire        addr_hit_clear;
   reg  [0:31] Bus2IP_Addr;
   reg  [0:3]  Bus2IP_BE;
   reg  [0:7]  Bus2IP_Data;
   reg  [0:15] Bus2IP_RegCE;
   reg         gen_xfer_ack;
   reg         ip_retry_req;
   reg         ip_tout_sup_req;
   reg         opb_req_clr;
   reg         opb_rnw_d1;
   reg         reg_ce_d1;
   reg  [0:7]  Sl_DBus_int;
   reg         Sl_errAck;

///////////////////////////////////////////////////////////////////////////
// Main Body of Code
///////////////////////////////////////////////////////////////////////////

// logic to decode addresses.
assign addr_decode_hit = (OPB_ABus[0:18]  == C_PS2_BAR[31:13]) & // PS2 #1 access offset 0 or
                         (OPB_ABus[20:25] == C_PS2_BAR[11:6]);   // PS2 #2 access offset 0x1000

// Address decode use 1 extra cycle
assign addr_hit_clear = ~OPB_select | Sl_xferAck | Sl_retry | OPB_Rst;
                          
always @(posedge OPB_Clk)
  if (addr_hit_clear)
    addr_hit <= 1'b0;
  else
    addr_hit <= addr_decode_hit;

always @(posedge OPB_Clk)
  opb_rnw_d1 <= OPB_RNW;

// Generate OPB Slave xferAck
assign Sl_xferAck = gen_xfer_ack;

// Send Back toutSup or Retry if IP requests it
assign Sl_toutSup = ip_tout_sup_req;
assign Sl_retry   = ip_retry_req;
      
always @(posedge OPB_Clk)
begin
  Bus2IP_Addr <= OPB_ABus;
  Bus2IP_BE   <= OPB_BE;
  Bus2IP_Data <= OPB_DBus[0:7];  // Hard coded 8 bit regs, params later
end

// Pipeline response signals from IP to OPB - organize for 1 level of logic max
always @(posedge OPB_Clk)
  if (OPB_Rst | ~OPB_select | ~addr_hit | opb_req_clr) begin
    gen_xfer_ack    <= 1'b0;
    ip_tout_sup_req <= 1'b0;
    ip_retry_req    <= 1'b0;
    opb_req_clr     <= 1'b0;
  end
  else begin
    gen_xfer_ack    <= ((opb_rnw_d1)? IP2Bus_RdAck : IP2Bus_WrAck) & addr_decode_hit;
    ip_tout_sup_req <= IP2Bus_ToutSup;
    ip_retry_req    <= IP2Bus_Retry & addr_decode_hit;
    opb_req_clr     <= ((opb_rnw_d1)? IP2Bus_RdAck : IP2Bus_WrAck)
                     | IP2Bus_Retry;
  end

// Decode PS2 Controller Registers
always @(posedge OPB_Clk)
  begin
    Bus2IP_RegCE[0]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h0;
    Bus2IP_RegCE[1]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h1;
    Bus2IP_RegCE[2]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h2;
    Bus2IP_RegCE[3]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h3;
    Bus2IP_RegCE[4]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h4;
    Bus2IP_RegCE[5]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h5;
    Bus2IP_RegCE[6]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h6;
    Bus2IP_RegCE[7]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h7;
    Bus2IP_RegCE[8]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h8;
    Bus2IP_RegCE[9]  <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'h9;
    Bus2IP_RegCE[10] <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'hA;
    Bus2IP_RegCE[11] <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'hB;
    Bus2IP_RegCE[12] <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'hC;
    Bus2IP_RegCE[13] <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'hD;
    Bus2IP_RegCE[14] <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'hE;
    Bus2IP_RegCE[15] <= {OPB_ABus[19], OPB_ABus[27:29]} == 4'hF;
  end

always @(posedge OPB_Clk)
  reg_ce_d1 <= addr_hit & ~opb_req_clr;

// Process Rd/Wr Requests
assign Bus2IP_RdReq = addr_hit & ~opb_req_clr &  opb_rnw_d1 & ~reg_ce_d1;
assign Bus2IP_WrReq = addr_hit & ~opb_req_clr & ~opb_rnw_d1 & ~reg_ce_d1;

// ML align to 0:7, MB aling to 24:31
// Read Data Return  
always @(posedge OPB_Clk)
  if ( ~IP2Bus_RdAck | OPB_Rst)
    Sl_DBus_int[0:7] <= 8'h00;
  else
    Sl_DBus_int[0:7] <= IP2Bus_Data[0:7]; 
 
assign Sl_DBus = {Sl_DBus_int, 24'h0};

// Since Sl_DBus is already gated off when not active, Sl_DBusEn is
// set to 1 so it can be optimized away if it is AND'ed with Sl_DBus
assign Sl_DBusEn = 1'b1;

// ErrAck Return
always @(posedge OPB_Clk)
  if (OPB_Rst | ((opb_rnw_d1)? ~IP2Bus_RdAck : ~IP2Bus_WrAck))
    Sl_errAck <= 1'b0;
  else 
    Sl_errAck <= addr_hit & ~opb_req_clr & IP2Bus_Error;

// Pass along interrupts
assign Sys_Intr1 = IP2Bus_Intr1;
assign Sys_Intr2 = IP2Bus_Intr2;

endmodule

