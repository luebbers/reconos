//----------------------------------------------------------------------------
// RGB Block Ram - Sub Level Module
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
// Filename:     rgb_bram.v
// 
// Description: 
//    -- This module is contains 3 RAMB16_S9_S18 for line storage.
//    -- The RGB BRAMs hold one line of the 480 lines required for 640x480
//       resolution.
//    -- 1 RAMB16_S9_S18 for RED Pixels
//    -- 1 RAMB16_S9_S18 GREEN Pixels
//    -- 1 RAMB16_S9_S18 BLUE Pixels
//    -- RED PLB TRANSFER   [1,5] -> RED   RAMB16_S9_S18 PORT B
//    -- GREEN PLB TRANSFER  [2,6] -> GREEN   RAMB16_S9_S18 PORT B
//    -- BLUE PLB TRANSFER  [3,7] -> BLUE    RAMB16_S9_S36 PORT B
//    -- Data is written to the B PORTS of the BRAM by the PLB bus.
//    -- Data is read from the A PORTS of the BRAM by the TFT 
//
// Design Notes:
//  TFT READ LOGIC    
//    -- BRAM_TFT_rd is generated two clock cycles early wrt DE      
//    -- BRAM_TFT_oe is generated one clock cycles early wrt DE
//    -- These two signals control the TFT side read from BRAM to HW
//  PLB WRITE LOGIC
//    -- Enables and Write Enables for BRAM are controlled by the plb_if.v
//    -- module.  The R_en,G_en,B_en,R_we,G_we,B_we are trigger on the same
//    -- clock edge.  Enables for RGB BRAM may need to be adjusted for timing.
//
//      
//-----------------------------------------------------------------------------
// Structure:   
//       -- RGB_BRAM.v                
//
//-----------------------------------------------------------------------------
// Author:    CJN
// History:
//   CJN, MM  3/02  -- First Release
//   CJN        -- Second Release
//               -- PLB Side Update
//              
//
//
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/ 100 ps
module rgb_bram(
        tft_on_reg,  // I
  // BRAM_TFT READ PORT A clock and reset
  tft_clk,           // I 
  tft_rst,           // I

  // PLB_BRAM WRITE PORT B clock and reset
  plb_clk,           // I
  plb_rst,           // I

  // BRAM_TFT READ Control
  BRAM_TFT_rd,       // I  
  BRAM_TFT_oe,       // I  

  // PLB_BRAM Write Control
  PLB_BRAM_data,     // I [0:63]
  PLB_BRAM_addr_en,  // I
  PLB_BRAM_addr_lsb, // I [0:1]
  PLB_BRAM_we,       // I

  // RGB Outputs
  R0,R1,R2,R3,R4,R5, // O 
  G0,G1,G2,G3,G4,G5, // O
  B0,B1,B2,B3,B4,B5  // O
);
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////

  input        tft_on_reg;
  input        tft_clk;
  input        tft_rst;
  input        plb_clk;
  input        plb_rst;
  input        BRAM_TFT_rd;
  input        BRAM_TFT_oe;
  input [0:63] PLB_BRAM_data;
  input [0:1]  PLB_BRAM_addr_lsb;
  input        PLB_BRAM_addr_en;
  input        PLB_BRAM_we;
  output       R0,R1,R2,R3,R4,R5;
  output       G0,G1,G2,G3,G4,G5;
  output       B0,B1,B2,B3,B4,B5;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
  
  wire [0:1]  nc0,nc1,nc2,nc3,nc4,nc5;
  wire [5:0]  BRAM_TFT_R_data;
  wire [5:0]  BRAM_TFT_G_data;
  wire [5:0]  BRAM_TFT_B_data;  
  reg         R0,R1,R2,R3,R4,R5;
  reg         G0,G1,G2,G3,G4,G5;
  reg         B0,B1,B2,B3,B4,B5;
  reg  [0:9]  BRAM_TFT_addr;
  reg  [0:6]  PLB_BRAM_addr;
  reg         tc;

///////////////////////////////////////////////////////////////////////////////
// READ Logic BRAM Address Generator TFT Side
///////////////////////////////////////////////////////////////////////////////

  // BRAM_TFT_addr Counter (0-639d)
  always @(posedge tft_clk)
  begin
    if (tft_rst | ~BRAM_TFT_rd) begin
      BRAM_TFT_addr = 10'b0;
      tc = 1'b0;
    end
    else begin
      if (BRAM_TFT_rd & tc == 0) begin
        if (BRAM_TFT_addr == 10'd639) begin
          BRAM_TFT_addr = 10'b0;
          tc = 1'b1;
        end
        else begin
          BRAM_TFT_addr = BRAM_TFT_addr + 1;
          tc = 1'b0;
        end
      end
    end
  end

///////////////////////////////////////////////////////////////////////////////
// WRITE Logic for the BRAM PLB Side
///////////////////////////////////////////////////////////////////////////////

  // BRAM_TFT_addr Counter (0-79d)
  always @(posedge plb_clk)
  begin
    if (plb_rst) begin
      PLB_BRAM_addr = 7'b0;
    end
    else begin
      if (PLB_BRAM_addr_en) begin
        if (PLB_BRAM_addr == 7'd79) begin
          PLB_BRAM_addr = 7'b0;
        end
        else begin
          PLB_BRAM_addr = PLB_BRAM_addr + 1;
        end
      end
    end
  end

///////////////////////////////////////////////////////////////////////////////
// BRAM
///////////////////////////////////////////////////////////////////////////////

RAMB16_S18_S36 RGB_BRAM (
  // TFT Side Port A
  .ADDRA (BRAM_TFT_addr),                                            // I [9:0]
  .CLKA  (tft_clk),                                                  // I
  .DIA   (16'b0),                                                    // I [15:0]
  .DIPA  (2'b0),                                                     // I [1:0]
  .DOA   ({BRAM_TFT_R_data, BRAM_TFT_G_data, BRAM_TFT_B_data[5:2]}), // O [15:0]
  .DOPA  (BRAM_TFT_B_data[1:0]),                                     // O [1:0]
  .ENA   (BRAM_TFT_rd),                                              // I
  .SSRA  (~tft_on_reg | tft_rst | ~BRAM_TFT_rd), // | ~BRAM_TFT_oe   // I 
  .WEA   (1'b0),                                                     // I
  // PLB Side Port B
  .ADDRB ({PLB_BRAM_addr,PLB_BRAM_addr_lsb}), // I [8:0]
  .CLKB  (plb_clk),                           // I
  .DIB   ({PLB_BRAM_data[40:45], PLB_BRAM_data[48:53], PLB_BRAM_data[56:59],
           PLB_BRAM_data[8:13],  PLB_BRAM_data[16:21], PLB_BRAM_data[24:27]}), // I [31:0]
  .DIPB  ({PLB_BRAM_data[60:61], PLB_BRAM_data[28:29]}),                       // I [3:0]
  .DOB   (),             // O [31:0]
  .DOPB  (),             // O [3:0]
  .ENB   (PLB_BRAM_we),  // I
  .SSRB  (1'b0),         // I
  .WEB   (PLB_BRAM_we)   // I
  );

///////////////////////////////////////////////////////////////////////////////
// Register RGB BRAM output data
///////////////////////////////////////////////////////////////////////////////

  always @(posedge tft_clk)
    if (!BRAM_TFT_oe)
    begin
      R0 = 1'b0;
      R1 = 1'b0;
      R2 = 1'b0;
      R3 = 1'b0;
      R4 = 1'b0;
      R5 = 1'b0;

      G0 = 1'b0;
      G1 = 1'b0;
      G2 = 1'b0;
      G3 = 1'b0;
      G4 = 1'b0;
      G5 = 1'b0;

      B0 = 1'b0;
      B1 = 1'b0;
      B2 = 1'b0;
      B3 = 1'b0;
      B4 = 1'b0;
      B5 = 1'b0;
    end
    else
    begin
      R0 = BRAM_TFT_R_data[0];
      R1 = BRAM_TFT_R_data[1];
      R2 = BRAM_TFT_R_data[2];
      R3 = BRAM_TFT_R_data[3];
      R4 = BRAM_TFT_R_data[4];
      R5 = BRAM_TFT_R_data[5];

      G0 = BRAM_TFT_G_data[0];
      G1 = BRAM_TFT_G_data[1];
      G2 = BRAM_TFT_G_data[2];
      G3 = BRAM_TFT_G_data[3];
      G4 = BRAM_TFT_G_data[4];
      G5 = BRAM_TFT_G_data[5];

      B0 = BRAM_TFT_B_data[0];
      B1 = BRAM_TFT_B_data[1];
      B2 = BRAM_TFT_B_data[2];
      B3 = BRAM_TFT_B_data[3];
      B4 = BRAM_TFT_B_data[4];
      B5 = BRAM_TFT_B_data[5];
    end      

endmodule

