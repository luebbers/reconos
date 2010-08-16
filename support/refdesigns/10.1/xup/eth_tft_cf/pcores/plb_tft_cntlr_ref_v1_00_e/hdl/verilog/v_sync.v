//----------------------------------------------------------------------------
//      VSYNC Generator - Sub-Level Module
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
//      Filename:     v_sync.v
// 
//      Description:    
//      This is the VSYNC signal generator.  It generates
//              the appropriate VSYNC signal for the target TFT display.  The core
//              of this module is a state machine that controls 4 counters and the 
//              VSYNC and V_DE signals.  
//
//      Design Notes:
//              -- Input clock is (~HSYNC)
//              -- Input rst is vsync_rst signal generated from the h_sync.v module
//              -- V_DE is and with H_DE to generate DE signal for the TFT display      
//              -- v_bp_cnt_tc is the terminal count of the back porch time counter.  Used to
//              -- generate get_line_start pulse.
//              -- v_l_cnt_tc is the terminal count of the line time counter.  Used to not 
//              -- generate get_line_start pulse.
//      
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
//
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Module Declaration
///////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/ 100 ps
module v_sync(
    clk,          // I 
    clk_stb,      // I
    rst,          // I
    VSYNC,        // O
    V_DE,         // O
    v_bp_cnt_tc,  // O
    v_l_cnt_tc);  // O

///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
        input                   clk;
        input                   clk_stb;
        input                   rst;     
        output                  VSYNC;
        output                  V_DE;
        output                  v_bp_cnt_tc;
        output                  v_l_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// Signal Declaration
///////////////////////////////////////////////////////////////////////////////
        reg                     V_DE;
        reg                     VSYNC;
        reg               [0:1] v_p_cnt;  // 2-bit counter (2   HSYNCs for pulse time)
        reg               [0:4] v_bp_cnt; // 5-bit counter (31  HSYNCs for back porch time)
        reg               [0:8] v_l_cnt;  // 9-bit counter (480 HSYNCs for line time)
        reg               [0:3] v_fp_cnt; // 4-bit counter (12  HSYNCs for front porch time) 
        reg                     v_p_cnt_ce;
        reg                     v_bp_cnt_ce;
        reg                     v_l_cnt_ce;
        reg                     v_fp_cnt_ce;
        reg                     v_p_cnt_clr;
        reg                     v_bp_cnt_clr;
        reg                     v_l_cnt_clr;
        reg                     v_fp_cnt_clr;
        reg                     v_p_cnt_tc;
        reg                     v_bp_cnt_tc;
        reg                     v_l_cnt_tc;
        reg                     v_fp_cnt_tc;

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - State Declaration
///////////////////////////////////////////////////////////////////////////////

        parameter [0:4] SET_COUNTERS    = 5'b00001;
        parameter [0:4] PULSE           = 5'b00010;
        parameter [0:4] BACK_PORCH      = 5'b00100;
        parameter [0:4] LINE            = 5'b01000;
        parameter [0:4] FRONT_PORCH     = 5'b10000;     

        reg [0:4]               VSYNC_cs  /*synthesis syn_encoding="onehot"*/;
        reg [0:4]               VSYNC_ns;

///////////////////////////////////////////////////////////////////////////////
// clock enable State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////

        reg clk_stb_d1;
        reg clk_ce_neg;
        reg clk_ce_pos;

        always @ (posedge clk)
    begin
          clk_stb_d1 <=  clk_stb;
          clk_ce_pos <=  clk_stb & ~clk_stb_d1;
          clk_ce_neg <= ~clk_stb & clk_stb_d1;
    end

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - Sequential Block
///////////////////////////////////////////////////////////////////////////////
        always @ (posedge clk)
        begin
                if (rst) VSYNC_cs = SET_COUNTERS;
                else if (clk_ce_pos) VSYNC_cs = VSYNC_ns;
        end

///////////////////////////////////////////////////////////////////////////////
// VSYNC State Machine - Combinatorial Block 
///////////////////////////////////////////////////////////////////////////////
        always @ (VSYNC_cs or v_p_cnt_tc or v_bp_cnt_tc or v_l_cnt_tc or v_fp_cnt_tc)
        begin 
                case (VSYNC_cs)
                /////////////////////////////////////////////////////////////////////////
                //      SET COUNTERS STATE
                // -- Clear and de-enable all counters on frame_start signal 
                /////////////////////////////////////////////////////////////////////////
                SET_COUNTERS: begin
                        v_p_cnt_ce = 0;
                v_p_cnt_clr = 1;
                        v_bp_cnt_ce = 0;
                        v_bp_cnt_clr = 1;
                        v_l_cnt_ce = 0;
                        v_l_cnt_clr = 1;
                        v_fp_cnt_ce = 0;
                        v_fp_cnt_clr = 1;
                        VSYNC  = 1;
                        V_DE = 0;                               
                        VSYNC_ns = PULSE;
                end
                /////////////////////////////////////////////////////////////////////////
                //      PULSE STATE
                // -- Enable pulse counter
                // -- De-enable others
                /////////////////////////////////////////////////////////////////////////
                PULSE: begin
                        v_p_cnt_ce = 1;
                v_p_cnt_clr = 0;
                        v_bp_cnt_ce = 0;
                        v_bp_cnt_clr = 1;
                        v_l_cnt_ce = 0;
                        v_l_cnt_clr = 1;
                        v_fp_cnt_ce = 0;
                        v_fp_cnt_clr = 1;
                        VSYNC = 0;
                        V_DE = 0;
                        if (v_p_cnt_tc == 0) VSYNC_ns = PULSE;                     
                        else VSYNC_ns = BACK_PORCH;
                end
                /////////////////////////////////////////////////////////////////////////
                //      BACK PORCH STATE
                // -- Enable back porch counter
                // -- De-enable others
                /////////////////////////////////////////////////////////////////////////
                BACK_PORCH: begin
                        v_p_cnt_ce = 0;
                        v_p_cnt_clr = 1;
                        v_bp_cnt_ce = 1;
                        v_bp_cnt_clr = 0;
                        v_l_cnt_ce = 0;
                v_l_cnt_clr = 1;
                        v_fp_cnt_ce = 0;
                        v_fp_cnt_clr = 1;
                        VSYNC = 1;
                        V_DE = 0;                               
                        if (v_bp_cnt_tc == 0) VSYNC_ns = BACK_PORCH;                                                       
                        else VSYNC_ns = LINE;
                end
                /////////////////////////////////////////////////////////////////////////
                //      LINE STATE
                // -- Enable line counter
                // -- De-enable others
                /////////////////////////////////////////////////////////////////////////
                LINE: begin
                        v_p_cnt_ce = 0;
                        v_p_cnt_clr = 1;
                        v_bp_cnt_ce = 0;
                        v_bp_cnt_clr = 1;
                        v_l_cnt_ce = 1;
                v_l_cnt_clr = 0;
                        v_fp_cnt_ce = 0;
                        v_fp_cnt_clr = 1;
                        VSYNC = 1;
                        V_DE = 1;  
                        if (v_l_cnt_tc == 0) VSYNC_ns = LINE;                                                      
                        else VSYNC_ns = FRONT_PORCH;
        end
                /////////////////////////////////////////////////////////////////////////
                //      FRONT PORCH STATE
                // -- Enable front porch counter
                // -- De-enable others
                // -- Wraps to PULSE state
                /////////////////////////////////////////////////////////////////////////
                FRONT_PORCH: begin
                        v_p_cnt_ce = 0;
                        v_p_cnt_clr = 1;
                        v_bp_cnt_ce = 0;
                        v_bp_cnt_clr = 1;
                        v_l_cnt_ce = 0;
                v_l_cnt_clr = 1;
                        v_fp_cnt_ce = 1;
                        v_fp_cnt_clr = 0;
                        VSYNC = 1;
                        V_DE = 0;       
                        if (v_fp_cnt_tc == 0) VSYNC_ns = FRONT_PORCH;                                                      
                        else VSYNC_ns = PULSE;
                end
                /////////////////////////////////////////////////////////////////////////
                //      DEFAULT STATE
                /////////////////////////////////////////////////////////////////////////
                default: begin
                        v_p_cnt_ce = 0;
                        v_p_cnt_clr = 1;
                        v_bp_cnt_ce = 0;
                        v_bp_cnt_clr = 1;
                        v_l_cnt_ce = 0;
                v_l_cnt_clr = 1;
                        v_fp_cnt_ce = 1;
                        v_fp_cnt_clr = 0;
                        VSYNC = 1;      
                        V_DE = 0;
                        VSYNC_ns = SET_COUNTERS;
                end
                endcase
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Pulse Counter - Counts 2 clocks(~HSYNC) for pulse time                                                                                                                                 
///////////////////////////////////////////////////////////////////////////////
        always @(posedge clk)
        begin
                if (v_p_cnt_clr) begin
                        v_p_cnt = 2'b0;
                        v_p_cnt_tc = 0;
                end
                else if (clk_ce_neg) begin
                        if (v_p_cnt_ce) begin
                                if (v_p_cnt == 1) begin
                                        v_p_cnt = v_p_cnt + 1;
                                        v_p_cnt_tc = 1;
                                end
                                else begin
                                        v_p_cnt = v_p_cnt + 1;
                                        v_p_cnt_tc = 0;
                                end
                        end
                end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Back Porch Counter - Counts 31 clocks(~HSYNC) for pulse time                                                                   
///////////////////////////////////////////////////////////////////////////////
        always @(posedge clk)
        begin
                if (v_bp_cnt_clr) begin
                        v_bp_cnt = 5'b0;
                        v_bp_cnt_tc = 0;
                end
                else if (clk_ce_neg) begin
                        if (v_bp_cnt_ce) begin
                                if (v_bp_cnt == 30) begin
                                        v_bp_cnt = v_bp_cnt + 1;
                                        v_bp_cnt_tc = 1;
                                end
                                else begin
                                        v_bp_cnt = v_bp_cnt + 1;
                                        v_bp_cnt_tc = 0;
                                end
                        end
                end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Line Counter - Counts 480 clocks(~HSYNC) for pulse time                                                                                                                                
///////////////////////////////////////////////////////////////////////////////                                                                                                                                 
        always @(posedge clk)
        begin
                if (v_l_cnt_clr) begin
                        v_l_cnt = 9'b0;
                        v_l_cnt_tc = 0;
                end
                else if (clk_ce_neg) begin
                        if (v_l_cnt_ce) begin
                                if (v_l_cnt == 479) begin
                                        v_l_cnt = v_l_cnt + 1;
                                        v_l_cnt_tc = 1;
                                end
                                else begin
                                        v_l_cnt = v_l_cnt + 1;
                                        v_l_cnt_tc = 0;
                                end
                        end
                end
        end

///////////////////////////////////////////////////////////////////////////////
//      Vertical Front Porch Counter - Counts 12 clocks(~HSYNC) for pulse time
///////////////////////////////////////////////////////////////////////////////
        always @(posedge clk)
        begin
                if (v_fp_cnt_clr) begin
                        v_fp_cnt = 4'b0;
                        v_fp_cnt_tc = 0;
                end
                else if (clk_ce_neg) begin
                        if (v_fp_cnt_ce) begin
                                if (v_fp_cnt == 11) begin
                                        v_fp_cnt = v_fp_cnt + 1;
                                        v_fp_cnt_tc = 1;
                                end
                                else begin
                                        v_fp_cnt = v_fp_cnt + 1;
                                        v_fp_cnt_tc = 0;
                                end
                        end
                end
        end
endmodule
