//-----------------------------------------------------------------------------
// TFT Controller - Top Level Module
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
// Filename:     tft_top.v
// 
// Description:    
//
// Design Notes:
//   
//-----------------------------------------------------------------------------
// Structure:   
// 
//   -- plb_tft_cntlr.v
//      -- dcr_if.v
//      -- plb_if.v  
//        -- trans_control.v
//        -- color_control.v
//        -- line_control.v
//        -- pixel_control.v
//        -- plb_xfer_control.v
//      -- h_sync.v
//      -- v_sync.v
//      -- RGB_BRAM.v
//      -- tft_if.v                
//
//-----------------------------------------------------------------------------
// Author:    CJN
// History:
//   CJN
//
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 ps
module plb_tft_cntlr_ref (

  // PLB GLOBAL SIGNALS
  SYS_plbClk,        // I  100MHz
  SYS_plbReset,      // I 

  // REQUEST QUALIFIERS INPUTS
  PLB_MnAddrAck,     // I
  PLB_MnRearbitrate, // I
  PLB_Mnssize,       // I [0:1]
  PLB_MnBusy,        // I
  PLB_MnErr,         // I
  PLB_pendReq,       // I
  PLB_pendPri,       // I [0:1]
  PLB_reqPri,        // I [0:1]    
  Mn_request,        // O
  Mn_priority,       // O [0:1]
  Mn_busLock,        // O 
  Mn_RNW,            // O
  Mn_BE,             // O [0:7]
  Mn_size,           // O [0:3]
  Mn_type,           // O [0:2]

  Mn_msize,          // O [0:1]          
  Mn_compress,       // O        
  Mn_guarded,        // O
  Mn_lockErr,        // O
  Mn_ordered,        // O
  Mn_abort,          // O
  Mn_ABus,           // O [0:31]

  // PLB WRITE DATA BUS
  PLB_MnWrDAck,      // I       
  PLB_MnWrBTerm,     // I
  Mn_wrBurst,        // O
  Mn_wrDBus,         // O [0:63]

  // PLB READ DATA BUS              
  PLB_MnRdDAck,      // I
  PLB_MnRdBTerm,     // I
  PLB_MnRdWdAddr,    // I [0:3]
  PLB_MnRdDBus,      // I [0:63]       
  Mn_rdBurst,        // O


  // DCR BUS
  SYS_dcrClk,        // I
  DCR_ABus,          // I [0:9]
  DCR_DBusIn,        // I [0:31]
  DCR_Read,          // I
  DCR_Write,         // I
  DCR_Ack,           // O
  DCR_DBusOut,       // O [0:31]
  
  // TFT SIGNALS OUT TO HW
  SYS_tftClk,        // I
  TFT_LCD_HSYNC,     // O    
  TFT_LCD_VSYNC,     // O
  TFT_LCD_DE,        // O
  TFT_LCD_CLK,       // O
  TFT_LCD_DPS,       // O
  TFT_LCD_R,         // O [5:0]
  TFT_LCD_G,         // O [5:0]
  TFT_LCD_B,         // O [5:0]
  TFT_LCD_BLNK  	   // 0
  );

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

  // PLB GLOBAL SIGNALS
  input        SYS_plbClk;
  input        SYS_plbReset;

  // PLB REQUEST QUALIFIERS INPUTS
  input         PLB_MnAddrAck;
  input         PLB_MnRearbitrate;
  input  [0:1]  PLB_Mnssize;
  input         PLB_MnBusy;
  input         PLB_MnErr;
  input         PLB_pendReq;
  input  [0:1]  PLB_pendPri;
  input  [0:1]  PLB_reqPri;     
  output        Mn_request;
  output [0:1]  Mn_priority;
  output        Mn_busLock;
  output        Mn_RNW;
  output [0:7]  Mn_BE;
  output [0:3]  Mn_size;        
  output [0:2]  Mn_type;
  output [0:1]  Mn_msize;                
  output        Mn_compress;              
  output        Mn_guarded;    
  output        Mn_ordered;     
  output        Mn_lockErr;      
  output        Mn_abort;      
  output [0:31] Mn_ABus;

  // PLB WRITE DATA BUS
  input         PLB_MnWrDAck;       
  input         PLB_MnWrBTerm;      
  output        Mn_wrBurst;          
  output [0:63] Mn_wrDBus;          

  // PLB READ DATA BUS
  input         PLB_MnRdDAck;     
  input         PLB_MnRdBTerm;      
  input [0:3]   PLB_MnRdWdAddr;
  input [0:63]  PLB_MnRdDBus;        
  output        Mn_rdBurst;      

  // DCR BUS SIGNALS 
  input         SYS_dcrClk;
  input [0:9]   DCR_ABus;
  input [0:31]  DCR_DBusIn;
  input         DCR_Read;
  input         DCR_Write;
  output        DCR_Ack;
  output [0:31] DCR_DBusOut;      

  // TFT SIGNALS
  input         SYS_tftClk;
  output        TFT_LCD_HSYNC;
  output        TFT_LCD_VSYNC;
  output        TFT_LCD_DE;
  output        TFT_LCD_CLK;
  output        TFT_LCD_DPS;
  output [5:0]  TFT_LCD_R;
  output [5:0]  TFT_LCD_G; 
  output [5:0]  TFT_LCD_B;
  output        TFT_LCD_BLNK;
///////////////////////////////////////////////////////////////////////////////
// PARAMETER DECLARATION
///////////////////////////////////////////////////////////////////////////////
  parameter C_DCR_BASEADDR = 10'b00_1000_0000;
  parameter C_DCR_HIGHADDR  = 10'b00_1000_0001;
  parameter C_DEFAULT_TFT_BASE_ADDR = 11'b000_0000_0000;
  parameter C_DPS_INIT = 1'b1;
  parameter C_ON_INIT = 1'b1;
  parameter C_PIXCLK_IS_BUSCLK_DIVBY4  = 1'b1; // when set to one bypasses  SYS_tftClk, and uses a DCM to divide sys clock by 4

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////

  // PLB_IF to RGB_BRAM  
  wire [0:63] PLB_BRAM_data_i;
  wire [0:1]  PLB_BRAM_addr_lsb_i;
  wire        PLB_BRAM_addr_en_i;
  wire        PLB_BRAM_we_i;

  // HSYNC and VSYNC to TFT_IF
  wire        HSYNC_i;
  wire        VSYNC_i;

  // DE GENERATION
  wire        H_DE_i;
  wire        V_DE_i;
  wire        DE_i;

  // RGB_BRAM to TFT_IF
  wire        R0_i;
  wire        R1_i;
  wire        R2_i;
  wire        R3_i;
  wire        R4_i;
  wire        R5_i;
  wire        G0_i;
  wire        G1_i;
  wire        G2_i;
  wire        G3_i;
  wire        G4_i;
  wire        G5_i;
  wire        B0_i;
  wire        B1_i;
  wire        B2_i;
  wire        B3_i;
  wire        B4_i;
  wire        B5_i;

  // VSYNC RESET
  wire         vsync_rst;

  // TFT READ FROM BRAM
  wire         BRAM_TFT_rd;
  wire         BRAM_TFT_oe;

  wire         h_bp_cnt_tc;
  wire         h_bp_cnt_tc2;  
  wire         h_pix_cnt_tc;
  wire         h_pix_cnt_tc2;

  // get line pulse
  reg          get_line;

  // DCR Regs
  wire [0:10]  tft_base_addr_i;
  wire         tft_on_reg;

  wire         v_bp_cnt_tc;
  wire         get_line_start;
  reg          get_line_start_d1;
  reg          get_line_start_d2;
  reg          get_line_start_d3;
  wire         v_l_cnt_tc;

   // Clock wires
  wire         plb_clk;
  wire         tft_clk;
  wire         dcr_clk;
  
  // Reset wires
  wire         tft_rst;  //synthesis syn_keep = 1
  wire         tft_rst1;  //synthesis syn_keep = 1
  wire         tft_rst2;  //synthesis syn_keep = 1
  wire         tft_rst3;  //synthesis syn_keep = 1


  wire buffered_pixel_clock;
  wire CLKDV;
  wire CLK0;
///////////////////////////////////////////////////////////////////////////////
// Constant Assignment for unused PLB outputs
///////////////////////////////////////////////////////////////////////////////

  assign Mn_busLock  = 1'b0;
  assign Mn_compress = 1'b0;
  assign Mn_guarded  = 1'b0;
  assign Mn_ordered  = 1'b0;
  assign Mn_lockErr  = 1'b0;
  assign Mn_abort    = 1'b0;  
  assign Mn_wrBurst  = 1'b0;
  assign Mn_wrDBus   = 64'b0;          
  assign Mn_rdBurst  = 1'b0;

///////////////////////////////////////////////////////////////////////////////
// Signal Assignment
///////////////////////////////////////////////////////////////////////////////

// BRAM_TFT_rd and BRAM_TFT_oe start the read process. These are constant
// signals through out a line read.  
assign BRAM_TFT_rd = ((DE_i ^ h_bp_cnt_tc ^ h_bp_cnt_tc2 ) & V_DE_i);
assign BRAM_TFT_oe = ((DE_i ^ h_bp_cnt_tc) & V_DE_i);

// Generate DE for HW
assign DE_i = (H_DE_i & V_DE_i);

// get line start logic
assign get_line_start = ((h_pix_cnt_tc && v_bp_cnt_tc) || // 1st get line
                         (h_pix_cnt_tc && DE_i) &&        // 2nd,3rd,...get line
                         (~v_l_cnt_tc));                  // No get_line on last line  

// CLOCK wires
assign plb_clk = SYS_plbClk;
assign dcr_clk = SYS_dcrClk;
// FOR VGA interfaces with blank overide
assign TFT_LCD_BLNK	 = 1'b1;

///////////////////////////////////////////////////////////////////////////////
// TOP LEVEL COMPONENT INSTANTIATIONS
///////////////////////////////////////////////////////////////////////////////

  FD  FD_TFT_RST1 (.Q(tft_rst1), .C(tft_clk), .D(SYS_plbReset));

  FDS FD_TFT_RST2 (.Q(tft_rst2), .C(tft_clk), .S(tft_rst1), .D(1'b0));
  FDS FD_TFT_RST3 (.Q(tft_rst3), .C(tft_clk), .S(tft_rst1), .D(tft_rst2));
  FDS FD_TFT_RST4 (.Q(tft_rst4), .C(tft_clk), .S(tft_rst1), .D(tft_rst3));
  FDS FD_TFT_RST (.Q(tft_rst),  .C(tft_clk), .S(tft_rst1), .D(tft_rst4));

////////////////////////////////////////////////////////////////////////////
// DCR_IF COMPONENT INSTANTIATION
////////////////////////////////////////////////////////////////////////////
  dcr_if #(C_DCR_BASEADDR, C_DEFAULT_TFT_BASE_ADDR,
           C_DPS_INIT, C_ON_INIT) DCR_IF_U6 (
    .clk(dcr_clk),
    .rst(SYS_plbReset),
    .DCR_ABus(DCR_ABus),         
    .DCR_DBusIn(DCR_DBusIn),     
    .DCR_Read(DCR_Read),         
    .DCR_Write(DCR_Write),       
    .DCR_Ack(DCR_Ack),    
    .DCR_DBusOut(DCR_DBusOut), 
    .tft_base_addr(tft_base_addr_i),
    .tft_dps_reg(TFT_LCD_DPS),
    .tft_on_reg(tft_on_reg)
  );

////////////////////////////////////////////////////////////////////////////
// PLB_IF COMPONENT INSTANTIATION
////////////////////////////////////////////////////////////////////////////
  plb_if PLB_IF_U1 (
    .clk(plb_clk),
    .rst(SYS_plbReset),
    .PLB_MnAddrAck(PLB_MnAddrAck),
    .Mn_request(Mn_request),
    .Mn_priority(Mn_priority),
    .Mn_RNW(Mn_RNW),
    .Mn_BE(Mn_BE),    
    .Mn_size(Mn_size),     
    .Mn_type(Mn_type),    
    .Mn_MSize(Mn_msize),                
    .Mn_ABus(Mn_ABus),    
    .PLB_MnRdDAck(PLB_MnRdDAck),       
    .PLB_MnRdWdAddr(PLB_MnRdWdAddr),
    .PLB_MnRdDBus(PLB_MnRdDBus),         
    .PLB_BRAM_data(PLB_BRAM_data_i),
    .PLB_BRAM_addr_en(PLB_BRAM_addr_en_i),
    .PLB_BRAM_addr_lsb(PLB_BRAM_addr_lsb_i),
    .PLB_BRAM_we(PLB_BRAM_we_i),
    .get_line(get_line),
    .tft_base_addr(tft_base_addr_i),
    .tft_on_reg(tft_on_reg)
  );

///////////////////////////////////////////////////////////////////////////////
// RGB_BRAM COMPONENT INSTANTIATION
///////////////////////////////////////////////////////////////////////////////

  rgb_bram RGB_BRAM_U4(
    .tft_on_reg(tft_on_reg),
    .tft_clk(tft_clk),
    .tft_rst(SYS_plbReset),
    .plb_clk(plb_clk),
    .plb_rst(SYS_plbReset),
    .BRAM_TFT_rd(BRAM_TFT_rd), 
    .BRAM_TFT_oe(BRAM_TFT_oe), 
    .PLB_BRAM_data(PLB_BRAM_data_i),
    .PLB_BRAM_addr_en(PLB_BRAM_addr_en_i),
    .PLB_BRAM_addr_lsb(PLB_BRAM_addr_lsb_i),
    .PLB_BRAM_we(PLB_BRAM_we_i),
    .R0(R0_i),.R1(R1_i),.R2(R2_i),.R3(R3_i),.R4(R4_i),.R5(R5_i), 
    .G0(G0_i),.G1(G1_i),.G2(G2_i),.G3(G3_i),.G4(G4_i),.G5(G5_i),
    .B0(B0_i),.B1(B1_i),.B2(B2_i),.B3(B3_i),.B4(B4_i),.B5(B5_i)
  );

///////////////////////////////////////////////////////////////////////////////
//HSYNC COMPONENT INSTANTIATION
///////////////////////////////////////////////////////////////////////////////

  h_sync HSYNC_U2 (
    .clk(tft_clk), 
    .rst(tft_rst), 
    .vsync_rst(vsync_rst), 
    .HSYNC(HSYNC_i), 
    .H_DE(H_DE_i), 
    .h_bp_cnt_tc(h_bp_cnt_tc),    
    .h_bp_cnt_tc2(h_bp_cnt_tc2), 
    .h_pix_cnt_tc(h_pix_cnt_tc),  
    .h_pix_cnt_tc2(h_pix_cnt_tc2) 
  );

///////////////////////////////////////////////////////////////////////////////
// VSYNC COMPONENT INSTANTIATION
///////////////////////////////////////////////////////////////////////////////

  v_sync VSYNC_U3 (
    .clk(tft_clk),
    .clk_stb(~HSYNC_i), 
    .rst(vsync_rst), 
    .VSYNC(VSYNC_i), 
    .V_DE(V_DE_i),
    .v_bp_cnt_tc(v_bp_cnt_tc),
    .v_l_cnt_tc(v_l_cnt_tc)
  );

///////////////////////////////////////////////////////////////////////////////
// TFT_IF COMPONENT INSTANTIATION
///////////////////////////////////////////////////////////////////////////////

  tft_if TFT_IF_U5 (
    .clk(tft_clk),
    .rst(SYS_plbReset),
    .HSYNC(HSYNC_i),
    .VSYNC(VSYNC_i),
    .DE(DE_i),
    .R0(R0_i),
    .R1(R1_i),
    .R2(R2_i),
    .R3(R3_i),
    .R4(R4_i),
    .R5(R5_i), 
    .G0(G0_i),
    .G1(G1_i),
    .G2(G2_i),
    .G3(G3_i),
    .G4(G4_i),
    .G5(G5_i),
    .B0(B0_i),  
    .B1(B1_i),
    .B2(B2_i),
    .B3(B3_i),
    .B4(B4_i),  
    .B5(B5_i),
    .TFT_LCD_HSYNC(TFT_LCD_HSYNC),
    .TFT_LCD_VSYNC(TFT_LCD_VSYNC),
    .TFT_LCD_DE(TFT_LCD_DE),
    .TFT_LCD_CLK(TFT_LCD_CLK),
    .TFT_LCD_R0(TFT_LCD_R[0]),
    .TFT_LCD_R1(TFT_LCD_R[1]), 
    .TFT_LCD_R2(TFT_LCD_R[2]), 
    .TFT_LCD_R3(TFT_LCD_R[3]), 
    .TFT_LCD_R4(TFT_LCD_R[4]), 
    .TFT_LCD_R5(TFT_LCD_R[5]),
    .TFT_LCD_G0(TFT_LCD_G[0]), 
    .TFT_LCD_G1(TFT_LCD_G[1]), 
    .TFT_LCD_G2(TFT_LCD_G[2]), 
    .TFT_LCD_G3(TFT_LCD_G[3]), 
    .TFT_LCD_G4(TFT_LCD_G[4]), 
    .TFT_LCD_G5(TFT_LCD_G[5]),
    .TFT_LCD_B0(TFT_LCD_B[0]), 
    .TFT_LCD_B1(TFT_LCD_B[1]), 
    .TFT_LCD_B2(TFT_LCD_B[2]), 
    .TFT_LCD_B3(TFT_LCD_B[3]), 
    .TFT_LCD_B4(TFT_LCD_B[4]), 
    .TFT_LCD_B5(TFT_LCD_B[5])
  );

///////////////////////////////////////////////////////////////////////////////
// TOP LEVEL GLUE LOGIC
///////////////////////////////////////////////////////////////////////////////

// GET LINE State Machine to generate on get_line for the PLB clock domain 
// from TFT clock domain.
  always @(posedge tft_clk)
    if (SYS_plbReset)
      get_line_start_d1 <= 1'b0;
    else
      get_line_start_d1 <= get_line_start;

  always @(posedge plb_clk)
  begin
    get_line_start_d2 <= get_line_start_d1;
    get_line_start_d3 <= get_line_start_d2;
    get_line <= get_line_start_d2 & ~get_line_start_d3;
  end
///////////////////////////////////////////////////////////////////////////////
// Genertes for supporting 1/4 plb clk as tft clock /pixel clock
///////////////////////////////////////////////////////////////////////////////

generate
   if (C_PIXCLK_IS_BUSCLK_DIVBY4) begin : BUFG_pixclk 
     BUFG BUFG_pixclk(
     .O(buffered_pixel_clock),
     .I(CLKDV)
     );
   end
endgenerate

generate
   if (C_PIXCLK_IS_BUSCLK_DIVBY4) begin : DCM_pixclk 
   DCM DCM_pixclk(
      .CLK0(CLK0),     // 0 degree DCM CLK ouptput
      .CLK180(), // 180 degree DCM CLK output
      .CLK270(), // 270 degree DCM CLK output
      .CLK2X(),   // 2X DCM CLK output
      .CLK2X180(), // 2X, 180 degree DCM CLK out
      .CLK90(),   // 90 degree DCM CLK output
      .CLKDV(CLKDV),   // Divided DCM CLK out (CLKDV_DIVIDE)
      .CLKFX(),   // DCM CLK synthesis out (M/D)
      .CLKFX180(), // 180 degree CLK synthesis out
      .LOCKED(), // DCM LOCK status output
      .PSDONE(), // Dynamic phase adjust done output
      .STATUS(), // 8-bit DCM status bits output
      .CLKFB(CLK0),   // DCM clock feedback
      .CLKIN(SYS_plbClk),   // Clock input (from IBUFG, BUFG or DCM)
      .PSCLK(),   // Dynamic phase adjust clock input
      .PSEN(),     // Dynamic phase adjust enable input
      .PSINCDEC(PSINCDEC), // Dynamic phase adjust increment/decrement
      .RST(SYS_plbReset)        // DCM asynchronous reset input
   );
   defparam DCM_pixclk.CLKDV_DIVIDE = 4.0;  // Divide by: 4.0
   defparam DCM_pixclk.CLKFX_DIVIDE = 1;
   defparam DCM_pixclk.CLKFX_MULTIPLY = 4;
   defparam DCM_pixclk.CLKIN_DIVIDE_BY_2 = "FALSE";
   defparam DCM_pixclk.CLKIN_PERIOD = 10.0;  //  period of input clock
   defparam DCM_pixclk.CLKOUT_PHASE_SHIFT = "NONE"; // phase shift of NONE
   defparam DCM_pixclk.CLK_FEEDBACK = "1X";  // feedback of NONE, 1X 
   defparam DCM_pixclk.DFS_FREQUENCY_MODE = "LOW";  // LOW frequency mode for frequency synthesis
   defparam DCM_pixclk.DLL_FREQUENCY_MODE = "LOW";  // LOW frequency mode for DLL
   defparam DCM_pixclk.DUTY_CYCLE_CORRECTION = "TRUE"; // Duty cycle correction, TRUE
   defparam DCM_pixclk.PHASE_SHIFT = 0;     // Amount of fixed phase shift from -255 to 255
   defparam DCM_pixclk.STARTUP_WAIT = "FALSE";   // Delay configuration DONE until DCM LOCK FALSE
   end
endgenerate

generate
    if (C_PIXCLK_IS_BUSCLK_DIVBY4 ) begin : wire_buf
      assign tft_clk = buffered_pixel_clock;
    end
    else begin : no_wire_buf
      assign tft_clk = SYS_tftClk;
    end
endgenerate


endmodule
   
