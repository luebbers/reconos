//----------------------------------------------------------------------------
// HSYNC Generator - Sub-Level Module
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
// Filename:     h_sync.v
// 
//      Description:    
//      This is the HSYNC signal generator.  It generates
//              the appropriate HSYNC signal for the target TFT display.  The core
//              of this module is a state machine that controls 4 counters and the 
//              HSYNC and H_DE signals.  
//
// Design Notes:

//      Design Notes:
//              -- Input clock is SYS_tftClk
//              -- H_DE is anded with V_DE to generate DE signal for the TFT display    
//              -- h_bp_cnt_tc, h_bp_cnt_tc2, h_pix_cnt_tc, h_pix_cnt_tc2 are used to 
//              -- generate read and output enable signals for the tft side of the BRAM
//-----------------------------------------------------------------------------
//      Structure:   
//              -- v_sync.v
//
//-----------------------------------------------------------------------------
// Author:              CJN
// History:
//      CJN, MM 3/02    -- First Release
//      CJN                             -- Second Release
//
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/ 100 ps
module h_sync(
        clk,                    // I     
        rst,                    // I
        HSYNC,                  // O
        H_DE,                   // O
        vsync_rst,              // O 
        h_bp_cnt_tc,    // O
        h_bp_cnt_tc2,   // O
        h_pix_cnt_tc,   // O
        h_pix_cnt_tc2   // O
);
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
        input                   clk;
        input                   rst;
        output                  vsync_rst;
        output                  HSYNC;
        output                  H_DE;
        output                  h_bp_cnt_tc;
        output                  h_bp_cnt_tc2;
        output                  h_pix_cnt_tc;
        output                  h_pix_cnt_tc2; 

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
        reg                             vsync_rst;
        reg                             HSYNC;
        reg                             H_DE;
        reg [0:6]               h_p_cnt;        // 7-bit  counter (96  clocks for pulse time)
        reg [0:5]               h_bp_cnt;       // 6-bit  counter (48  clocks for back porch time)
        reg [0:10]              h_pix_cnt;      // 11-bit counter (640 clocks for pixel time)
        reg [0:3]               h_fp_cnt;       // 4-bit  counter (16  clocks fof front porch time)
        reg                             h_p_cnt_ce;
        reg                             h_bp_cnt_ce;
        reg                             h_pix_cnt_ce;
        reg                             h_fp_cnt_ce;
        reg                             h_p_cnt_clr;
        reg                             h_bp_cnt_clr;
        reg                             h_pix_cnt_clr;
        reg                             h_fp_cnt_clr;
        reg                             h_p_cnt_tc;
        reg                             h_bp_cnt_tc;
        reg                             h_bp_cnt_tc2;
        reg                             h_pix_cnt_tc;
        reg                             h_pix_cnt_tc2;
        reg                             h_fp_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - State Declaration
///////////////////////////////////////////////////////////////////////////////

        parameter [0:4] SET_COUNTERS = 5'b00001;
        parameter [0:4] PULSE            = 5'b00010;
        parameter [0:4] BACK_PORCH       = 5'b00100;
        parameter [0:4] PIXEL            = 5'b01000;
        parameter [0:4] FRONT_PORCH      = 5'b10000;

        reg [0:4]               HSYNC_cs /*synthesis syn_encoding="onehot"*/;
        reg [0:4]               HSYNC_ns;

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////
        always @(posedge clk) begin
                if (rst) begin
                        HSYNC_cs = SET_COUNTERS;
                        vsync_rst = 1;
                end
                else begin
                        HSYNC_cs = HSYNC_ns;
                        vsync_rst = 0;
                end
        end

///////////////////////////////////////////////////////////////////////////////
// HSYNC State Machine - Combinatorial Block 
///////////////////////////////////////////////////////////////////////////////
        always @(HSYNC_cs or h_p_cnt_tc or h_bp_cnt_tc or h_pix_cnt_tc or h_fp_cnt_tc) 
        begin 
                case (HSYNC_cs)
                /////////////////////////////////////////////////////////////////////////
                //      SET COUNTERS STATE
                /////////////////////////////////////////////////////////////////////////
                SET_COUNTERS: begin
                        h_p_cnt_ce = 0;
                        h_p_cnt_clr = 1;
                        h_bp_cnt_ce = 0;
                        h_bp_cnt_clr = 1;
                        h_pix_cnt_ce = 0;
                        h_pix_cnt_clr = 1;
                        h_fp_cnt_ce = 0;
                        h_fp_cnt_clr = 1;
                        HSYNC = 1;
                        H_DE = 0;
                        HSYNC_ns = PULSE;
                end
                /////////////////////////////////////////////////////////////////////////
                //      PULSE STATE
                // -- Enable pulse counter
                // -- De-enable others
                /////////////////////////////////////////////////////////////////////////
                PULSE: begin
                        h_p_cnt_ce = 1;
                h_p_cnt_clr = 0;
                        h_bp_cnt_ce = 0;
                        h_bp_cnt_clr = 1;
                        h_pix_cnt_ce = 0;
                h_pix_cnt_clr = 1;
                        h_fp_cnt_ce = 0;
                        h_fp_cnt_clr = 1;
                HSYNC = 0;
                        H_DE = 0;
                if (h_p_cnt_tc == 0) HSYNC_ns = PULSE;                     
                        else HSYNC_ns = BACK_PORCH;
                end
                /////////////////////////////////////////////////////////////////////////
                //      BACK PORCH STATE
                // -- Enable back porch counter
                // -- De-enable others
                /////////////////////////////////////////////////////////////////////////
                BACK_PORCH: begin
                        h_p_cnt_ce = 0;
                        h_p_cnt_clr = 1;
                        h_bp_cnt_ce = 1;
                        h_bp_cnt_clr = 0;
                        h_pix_cnt_ce = 0;
                h_pix_cnt_clr = 1;
                        h_fp_cnt_ce = 0;
                        h_fp_cnt_clr = 1;
                        HSYNC = 1;
                        H_DE = 0;
                        if (h_bp_cnt_tc == 0) HSYNC_ns = BACK_PORCH;                                                       
                        else HSYNC_ns = PIXEL;
                end
                /////////////////////////////////////////////////////////////////////////
                //      PIXEL STATE
                // -- Enable pixel counter
                // -- De-enable others
                /////////////////////////////////////////////////////////////////////////
                PIXEL: begin
                        h_p_cnt_ce = 0;
                        h_p_cnt_clr = 1;
                        h_bp_cnt_ce = 0;
                        h_bp_cnt_clr = 1;
                        h_pix_cnt_ce = 1;
                h_pix_cnt_clr = 0;
                        h_fp_cnt_ce = 0;
                        h_fp_cnt_clr = 1;
                        HSYNC = 1;
                        H_DE = 1;
                        if (h_pix_cnt_tc == 0) HSYNC_ns = PIXEL;                                                           
                        else HSYNC_ns = FRONT_PORCH;
        end
                /////////////////////////////////////////////////////////////////////////
                //      FRONT PORCH STATE
                // -- Enable front porch counter
                // -- De-enable others
                // -- Wraps to PULSE state
                /////////////////////////////////////////////////////////////////////////
                FRONT_PORCH: begin
                        h_p_cnt_ce = 0;
                        h_p_cnt_clr = 1;
                        h_bp_cnt_ce = 0;
                        h_bp_cnt_clr = 1;
                        h_pix_cnt_ce = 0;
                h_pix_cnt_clr = 1;
                        h_fp_cnt_ce = 1;
                        h_fp_cnt_clr = 0;
                        HSYNC = 1;      
                        H_DE = 0;
                        if (h_fp_cnt_tc == 0) HSYNC_ns = FRONT_PORCH;                                                      
                        else HSYNC_ns = PULSE;
                end
                /////////////////////////////////////////////////////////////////////////
                //      DEFAULT STATE
                /////////////////////////////////////////////////////////////////////////
                default: begin
                        h_p_cnt_ce = 0;
                        h_p_cnt_clr = 1;
                        h_bp_cnt_ce = 0;
                        h_bp_cnt_clr = 1;
                        h_pix_cnt_ce = 0;
                h_pix_cnt_clr = 1;
                        h_fp_cnt_ce = 1;
                        h_fp_cnt_clr = 0;
                        HSYNC = 1;      
                        H_DE = 0;
                        HSYNC_ns = SET_COUNTERS;
                end
                endcase
        end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pulse Counter - Counts 96 clocks for pulse time                                                                                                                              
///////////////////////////////////////////////////////////////////////////////
        always @(posedge clk)
        begin
                if (h_p_cnt_clr) begin
                        h_p_cnt = 7'b0;
                        h_p_cnt_tc = 0;
                end
                else begin
                        if (h_p_cnt_ce) begin
                                if (h_p_cnt == 94) begin
                                        h_p_cnt = h_p_cnt + 1;
                                        h_p_cnt_tc = 1;
                                end
                                else begin
                                        h_p_cnt = h_p_cnt + 1;
                                        h_p_cnt_tc = 0;
                                end
                        end
                end
        end
///////////////////////////////////////////////////////////////////////////////
//      Horizontal Back Porch Counter - Counts 48 clocks for back porch time                                                                    
///////////////////////////////////////////////////////////////////////////////                 
        always @(posedge clk )
        begin
                if (h_bp_cnt_clr) begin
                        h_bp_cnt = 6'b0;
                        h_bp_cnt_tc = 0;
                        h_bp_cnt_tc2 = 0;
                end
                else begin
                        if (h_bp_cnt_ce) begin
                                if (h_bp_cnt == 45) begin
                                        h_bp_cnt = h_bp_cnt + 1;
                                        h_bp_cnt_tc2 = 1;
                                        h_bp_cnt_tc = 0;
                                end
                                else if (h_bp_cnt == 46) begin
                                        h_bp_cnt = h_bp_cnt + 1;
                                        h_bp_cnt_tc = 1;
                                        h_bp_cnt_tc2 = 0;
                                end
                                else begin
                                        h_bp_cnt = h_bp_cnt + 1;
                                        h_bp_cnt_tc = 0;
                                        h_bp_cnt_tc2 = 0;

                                end
                        end
                end
        end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Pixel Counter - Counts 640 clocks for pixel time                                                                                                                     
///////////////////////////////////////////////////////////////////////////////                 
        always @(posedge clk)
        begin
                if (h_pix_cnt_clr) begin
                        h_pix_cnt = 11'b0;
                        h_pix_cnt_tc = 0;
                        h_pix_cnt_tc2 = 0;
                end
                else begin
                        if (h_pix_cnt_ce) begin
                                if (h_pix_cnt == 637) begin
                                        h_pix_cnt = h_pix_cnt + 1;
                                        h_pix_cnt_tc2 = 1;
                                end
                                else if (h_pix_cnt == 638) begin
                                        h_pix_cnt = h_pix_cnt + 1;
                                        h_pix_cnt_tc = 1;
                                end
                                else begin
                                        h_pix_cnt = h_pix_cnt + 1;
                                        h_pix_cnt_tc = 0;
                                        h_pix_cnt_tc2 = 0;
                                end
                        end     
                end
        end

///////////////////////////////////////////////////////////////////////////////
//      Horizontal Front Porch Counter - Counts 16 clocks for front porch time
///////////////////////////////////////////////////////////////////////////////                 
        always @(posedge clk)
        begin
                if (h_fp_cnt_clr) begin
                        h_fp_cnt = 5'b0;
                        h_fp_cnt_tc = 0;
                end
                else begin
                        if (h_fp_cnt_ce) begin
                                if (h_fp_cnt == 14) begin
                                        h_fp_cnt = h_fp_cnt + 1;
                                        h_fp_cnt_tc = 1;
                                end
                                else begin
                                        h_fp_cnt = h_fp_cnt + 1;
                                        h_fp_cnt_tc = 0;
                                end
                        end
                end
        end
endmodule
