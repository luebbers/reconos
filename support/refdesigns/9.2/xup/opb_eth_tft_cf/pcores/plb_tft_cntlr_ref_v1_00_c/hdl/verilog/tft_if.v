//----------------------------------------------------------------------------
// TFT INTERFACE - Sub Level Module
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
// Filename:     tft_if.v
// 
// Description:    
//      This module takes as input, the TFT input signals and registers them.
//  Therefore all signals going to the TFT hardware is registered in the 
//      IOBs.
//
// Design Notes:
//      Wrapper type file to register all the inputs to the TFT hardware.
//   
//-----------------------------------------------------------------------------
// Structure:   
//              -- tft_if.v
//-----------------------------------------------------------------------------
// Author:              CJN
// History:
//      CJN, MM 3/02    -- First Release
//      CJN                             -- Second Release
//
//   
//
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 ps
module tft_if(
        clk,                    // I
        rst,                    // I
        HSYNC,                  // I
        VSYNC,                  // I
        DE,                     // I
        R0,                     // I
        R1,                     // I
        R2,                     // I
        R3,                     // I
        R4,                     // I
        R5,                     // I
        G0,                     // I
        G1,                     // I                                    
        G2,                     // I
        G3,                     // I
        G4,                     // I
        G5,                     // I
        B0,                     // I
        B1,                     // I
        B2,                     // I
        B3,                     // I
        B4,                     // I    
        B5,                     // I
        TFT_LCD_HSYNC,          // O
        TFT_LCD_VSYNC,          // O
        TFT_LCD_DE,             // O
        TFT_LCD_CLK,            // O
        TFT_LCD_R0,             // O
        TFT_LCD_R1,             // O
        TFT_LCD_R2,             // O 
        TFT_LCD_R3,             // O 
        TFT_LCD_R4,             // O 
        TFT_LCD_R5,             // O
        TFT_LCD_G0,             // O 
        TFT_LCD_G1,             // O 
        TFT_LCD_G2,             // O 
        TFT_LCD_G3,             // O 
        TFT_LCD_G4,             // O 
        TFT_LCD_G5,             // O
        TFT_LCD_B0,             // O 
        TFT_LCD_B1,             // O 
        TFT_LCD_B2,             // O 
        TFT_LCD_B3,             // O 
        TFT_LCD_B4,             // O 
        TFT_LCD_B5              // O
);

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
        input                   clk;
        input                   rst;
        input                   HSYNC;                          
        input                   VSYNC;                          
        input                   DE;     
        input                   R0;
        input                   R1;
        input                   R2;
        input                   R3;
        input                   R4;
        input                   R5;
        input                   G0;
        input                   G1;                             
        input                   G2;
        input                   G3;
        input                   G4;
        input                   G5;
        input                   B0;
        input                   B1;
        input                   B2;
        input                   B3;
        input                   B4;
        input                   B5;
        output                  TFT_LCD_HSYNC;
        output                  TFT_LCD_VSYNC;
        output                  TFT_LCD_DE;
        output                  TFT_LCD_CLK;
        output                  TFT_LCD_R0;
        output                  TFT_LCD_R1; 
        output                  TFT_LCD_R2; 
        output                  TFT_LCD_R3; 
        output                  TFT_LCD_R4; 
        output                  TFT_LCD_R5;
        output                  TFT_LCD_G0; 
        output                  TFT_LCD_G1; 
        output                  TFT_LCD_G2; 
        output                  TFT_LCD_G3; 
        output                  TFT_LCD_G4; 
        output                  TFT_LCD_G5;
        output                  TFT_LCD_B0; 
        output                  TFT_LCD_B1; 
        output                  TFT_LCD_B2; 
        output                  TFT_LCD_B3; 
        output                  TFT_LCD_B4; 
        output                  TFT_LCD_B5;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
                
        ////////////////////////////////////////////////////////////////////////////
        // FDRE COMPONENT INSTANTIATION FOR IOB OUTPUT REGISTERS
        // -- All output to TFT/tft are registered
        ////////////////////////////////////////////////////////////////////////////
        FDRE FDRE_HSYNC (.Q(TFT_LCD_HSYNC), .C(clk), .CE(1'b1), .R(rst), .D(HSYNC))     /* synthesis syn_useioff = 1 */; 
        FDRE FDRE_VSYNC (.Q(TFT_LCD_VSYNC), .C(clk), .CE(1'b1), .R(rst), .D(VSYNC))     /* synthesis syn_useioff = 1 */;
        FDRE FDRE_DE    (.Q(TFT_LCD_DE),        .C(clk), .CE(1'b1), .R(rst), .D(DE))    /* synthesis syn_useioff = 1 */;
        assign TFT_LCD_CLK = clk;
//        ODDR TFT_CLK_ODDR (.Q(TFT_LCD_CLK), .C(clk), .CE(1'b1), .R(1'b0), .D1(1'b0), .D2(1'b1), .S(1'b0));
        FD FD_R0        (.Q(TFT_LCD_R0), .C(clk), .D(R0))       /* synthesis syn_useioff = 1 */;
        FD FD_R1        (.Q(TFT_LCD_R1), .C(clk), .D(R1))       /* synthesis syn_useioff = 1 */;
        FD FD_R2        (.Q(TFT_LCD_R2), .C(clk), .D(R2))       /* synthesis syn_useioff = 1 */;
        FD FD_R3        (.Q(TFT_LCD_R3), .C(clk), .D(R3))       /* synthesis syn_useioff = 1 */;
        FD FD_R4        (.Q(TFT_LCD_R4), .C(clk), .D(R4))       /* synthesis syn_useioff = 1 */;
        FD FD_R5        (.Q(TFT_LCD_R5), .C(clk), .D(R5))       /* synthesis syn_useioff = 1 */;
        FD FD_G0        (.Q(TFT_LCD_G0), .C(clk), .D(G0))       /* synthesis syn_useioff = 1 */;
        FD FD_G1        (.Q(TFT_LCD_G1), .C(clk), .D(G1))       /* synthesis syn_useioff = 1 */;
        FD FD_G2        (.Q(TFT_LCD_G2), .C(clk), .D(G2))       /* synthesis syn_useioff = 1 */;
        FD FD_G3        (.Q(TFT_LCD_G3), .C(clk), .D(G3))       /* synthesis syn_useioff = 1 */;
        FD FD_G4        (.Q(TFT_LCD_G4), .C(clk), .D(G4))       /* synthesis syn_useioff = 1 */;
        FD FD_G5        (.Q(TFT_LCD_G5), .C(clk), .D(G5))       /* synthesis syn_useioff = 1 */;
        FD FD_B0        (.Q(TFT_LCD_B0), .C(clk), .D(B0))       /* synthesis syn_useioff = 1 */;
        FD FD_B1        (.Q(TFT_LCD_B1), .C(clk), .D(B1))       /* synthesis syn_useioff = 1 */;
        FD FD_B2        (.Q(TFT_LCD_B2), .C(clk), .D(B2))       /* synthesis syn_useioff = 1 */;
        FD FD_B3        (.Q(TFT_LCD_B3), .C(clk), .D(B3))       /* synthesis syn_useioff = 1 */;
        FD FD_B4        (.Q(TFT_LCD_B4), .C(clk), .D(B4))       /* synthesis syn_useioff = 1 */;
        FD FD_B5        (.Q(TFT_LCD_B5), .C(clk), .D(B5))       /* synthesis syn_useioff = 1 */;
endmodule
