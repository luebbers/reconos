//----------------------------------------------------------------------------
// PLB INTERFACE - Sub Level Module
//-----------------------------------------------------------------------------
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
//----------------------------------------------------------------------------
// Filename:     plb_if.v
// 
// Description:    
// 
//
// Design Notes:
//   
//-----------------------------------------------------------------------------
// Structure:   
// 
//-----------------------------------------------------------------------------
// Author:              CJN
// History:
//      CJN, MM 3/02    -- First Release
//      CJN                             -- Second Release
//
//
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 ps
module plb_if(
  // PLB GLOBAL SIGNALS
  clk,               // I  100MHz
  rst,               // I 

   // REQUEST QUALIFIERS INPUTS
  PLB_MnAddrAck,     // I
  Mn_request,        // O
  Mn_priority,       // O [0:1]
  Mn_RNW,            // O
  Mn_BE,             // O [0:7]
  Mn_size,           // O [0:3]
  Mn_type,           // O [0:2]
  Mn_MSize,          // O [0:1]          
  Mn_ABus,           // O [0:31]

  // PLB READ DATA BUS              
  PLB_MnRdDAck,      // I
  PLB_MnRdWdAddr,    // I
  PLB_MnRdDBus,      // I [0:63]       

  // PLB_BRAM CONTROL AND DATA
  PLB_BRAM_data,     // O [0:63]
  PLB_BRAM_addr_lsb, // O [0:1]
  PLB_BRAM_addr_en,  // O 
  PLB_BRAM_we,       // O 

  // GET_LINE PULSE
  get_line,          // I
  line_cnt_rst,       // I
  
  // BASE ADDRESS
  tft_base_addr,     // I [0:10]
  tft_on_reg         // I
  );

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

  // PLB GLOBAL SIGNALS
  input          clk;
  input          rst;

  // REQUEST QUALIFIERS INPUTS
  input          PLB_MnAddrAck;
  output         Mn_request;
  output [0:1]   Mn_priority;
  output         Mn_RNW;
  output [0:7]   Mn_BE;
  output [0:3]   Mn_size;        
  output [0:2]   Mn_type;
  output [0:1]   Mn_MSize;                 
  output [0:31]  Mn_ABus;

  // PLB READ DATA BUS
  input          PLB_MnRdDAck;     
  input [0:3]    PLB_MnRdWdAddr;
  input [0:63]   PLB_MnRdDBus;        
        
  // PLB_BRAM CONTROL AND DATA
  output [0:63]  PLB_BRAM_data;
  output [0:1]   PLB_BRAM_addr_lsb;
  output         PLB_BRAM_addr_en;
  output         PLB_BRAM_we;

  // GET LINE PULSE
  input          get_line;
  input          line_cnt_rst;
  input [0:10]   tft_base_addr;
  input          tft_on_reg;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////

  reg  [0:6]  trans_cnt;
  reg  [0:6]  trans_cnt_i;
  wire        trans_cnt_ce;
  wire        trans_cnt_tc;

  reg  [0:8]  line_cnt;
  reg  [0:8]  line_cnt_i;
  wire        line_cnt_ce;

  wire        end_xfer;
  wire        end_xfer_p1;

  reg  [0:63] PLB_BRAM_data;
  reg  [0:1]  PLB_BRAM_addr_lsb;
  reg         PLB_BRAM_we;
  reg  [0:10] tft_base_addr_i;

  wire        skip_line;
  reg         skip_line_d1;
  reg         skip_plb_xfer;
  reg         skip_plb_xfer_d1;
  reg         skip_plb_xfer_d2;
  reg         skip_plb_xfer_d3;
  reg         skip_plb_xfer_d4;
  reg         dummy_rd_ack;
  wire        mn_request_set;
  reg  [0:3]  data_xfer_shreg;
  reg         data_xfer_shreg1_d1;

  ////////////////////////////////////////////////////////////////////////////
  // Tie off Constants
  ////////////////////////////////////////////////////////////////////////////

  assign Mn_MSize     = 2'b01;             // 64 Bit PLB Xfers 
  assign Mn_priority  = 2'b11;             // Set priority to 3
  assign Mn_size      = 4'b0010;           // Transfer 8-word line 
  assign Mn_type      = 3'b000;            // Memory type transfer
  assign Mn_RNW       = 1'b1;              // Always read
  assign Mn_BE        = 8'b00000000;       // Ignored on Line xfers
  assign Mn_ABus[0:10]  = tft_base_addr_i; // 11-bits
  assign Mn_ABus[11:19] = line_cnt_i;
  assign Mn_ABus[20:26] = trans_cnt_i;
  assign Mn_ABus[27:31] = 5'b00000;
  
  assign mn_request_set = tft_on_reg & (  (get_line & (trans_cnt == 0))
                                        | (end_xfer & (trans_cnt != 0)));
  FDRSE FDRS_MN_REQUEST_DLY (.Q(Mn_request),.CE(1'b0),.C(clk),.D(1'b0),
                             .R(PLB_MnAddrAck | rst), .S(mn_request_set));

  always @(posedge clk)
     begin
       skip_plb_xfer <= ~tft_on_reg & (  (get_line & (trans_cnt == 0))
                                       | (end_xfer & (trans_cnt != 0)));
       skip_plb_xfer_d1 <= skip_plb_xfer;
       skip_plb_xfer_d2 <= skip_plb_xfer_d1;
       skip_plb_xfer_d3 <= skip_plb_xfer_d2;
       skip_plb_xfer_d4 <= skip_plb_xfer_d3;
       dummy_rd_ack     <= skip_plb_xfer_d4 | skip_plb_xfer_d3 | skip_plb_xfer_d2 | skip_plb_xfer_d1;
     end

  always @(posedge clk)
    if (mn_request_set) begin
      tft_base_addr_i <= tft_base_addr;
      line_cnt_i      <= line_cnt;
      trans_cnt_i     <= trans_cnt;
    end             

  always @(posedge clk)
  begin
    PLB_BRAM_data     <= PLB_MnRdDBus;
    PLB_BRAM_addr_lsb <= PLB_MnRdWdAddr[1:2];
    PLB_BRAM_we       <= PLB_MnRdDAck | dummy_rd_ack;
  end

  assign PLB_BRAM_addr_en = end_xfer;

  always @(posedge clk)
    if (rst | end_xfer)
      data_xfer_shreg <= (end_xfer & (PLB_MnRdDAck | dummy_rd_ack))? 4'b0001 : 4'b0000;
    else if (PLB_MnRdDAck | dummy_rd_ack)
      data_xfer_shreg <= {data_xfer_shreg[1:3], 1'b1};

  assign end_xfer = data_xfer_shreg[0];

  always @(posedge clk)
    data_xfer_shreg1_d1 <= data_xfer_shreg[1];

  assign end_xfer_p1 = data_xfer_shreg[1] & ~data_xfer_shreg1_d1;

///////////////////////////////////////////////////////////////////////////////
// Transaction Counter - Counts 0-79 (d)
///////////////////////////////////////////////////////////////////////////////      

  assign trans_cnt_ce = end_xfer_p1;
  assign trans_cnt_tc = (trans_cnt == 7'd79);

  always @(posedge clk)
    if(rst | line_cnt_rst)
      trans_cnt = 7'b0;
    else if (trans_cnt_ce) begin
      if (trans_cnt_tc)
        trans_cnt = 7'b0;
      else 
        trans_cnt = trans_cnt + 1;
      end

///////////////////////////////////////////////////////////////////////////////
// Line Counter - Counts 0-479 (d)
///////////////////////////////////////////////////////////////////////////////      

  // increment line cnt if getline missed because prev plb xfers not complete
  assign skip_line = get_line & (trans_cnt != 0);
  always @(posedge clk)
    skip_line_d1 <= skip_line & line_cnt_ce;

  assign line_cnt_ce = end_xfer_p1 & trans_cnt_tc;

  always @(posedge clk)
    if (rst | line_cnt_rst)
      line_cnt = 9'b0;
    else if (line_cnt_ce | skip_line | skip_line_d1) begin
      if (line_cnt == 9'd479)
        line_cnt = 9'b0;
      else
        line_cnt = line_cnt + 1;
    end

endmodule
