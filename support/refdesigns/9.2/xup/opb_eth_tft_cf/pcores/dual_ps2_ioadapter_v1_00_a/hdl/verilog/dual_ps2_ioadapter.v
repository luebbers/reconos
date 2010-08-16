/////////////////////////////////////////////////////////////////////////
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
/////////////////////////////////////////////////////////////////////////

module dual_ps2_ioadapter (
  ps2_clk_rx_1,     // O
  ps2_clk_rx_2,     // O
  ps2_clk_tx_1,     // I
  ps2_clk_tx_2,     // I
  ps2_d_rx_1,       // O
  ps2_d_rx_2,       // O
  ps2_d_tx_1,       // I
  ps2_d_tx_2,       // I
  ps2_mouse_clk_I,  // I
  ps2_mouse_clk_O,  // O
  ps2_mouse_clk_T,  // O
  ps2_mouse_data_I, // I
  ps2_mouse_data_O, // O
  ps2_mouse_data_T, // O
  ps2_keyb_clk_I,   // I
  ps2_keyb_clk_O,   // O
  ps2_keyb_clk_T,   // O
  ps2_keyb_data_I,  // I
  ps2_keyb_data_O,  // O
  ps2_keyb_data_T   // O
  );

  output ps2_clk_rx_1;
  output ps2_clk_rx_2;
  input  ps2_clk_tx_1;
  input  ps2_clk_tx_2;
  output ps2_d_rx_1;
  output ps2_d_rx_2;
  input  ps2_d_tx_1;
  input  ps2_d_tx_2;
  input  ps2_mouse_clk_I;
  output ps2_mouse_clk_O;
  output ps2_mouse_clk_T;
  input  ps2_mouse_data_I;
  output ps2_mouse_data_O;
  output ps2_mouse_data_T;
  input  ps2_keyb_clk_I;
  output ps2_keyb_clk_O;
  output ps2_keyb_clk_T;
  input  ps2_keyb_data_I;
  output ps2_keyb_data_O;
  output ps2_keyb_data_T;

  // PS/2 Assignments
  assign ps2_clk_rx_1 = ps2_mouse_clk_I;
  assign ps2_clk_rx_2 = ps2_keyb_clk_I;
  assign ps2_d_rx_1   = ps2_mouse_data_I;
  assign ps2_d_rx_2   = ps2_keyb_data_I;

  assign ps2_mouse_clk_O  = 1'b0;
  assign ps2_mouse_clk_T  = ~ps2_clk_tx_1;
  assign ps2_mouse_data_O = 1'b0;
  assign ps2_mouse_data_T = ~ps2_d_tx_1;
  assign ps2_keyb_clk_O   = 1'b0;
  assign ps2_keyb_clk_T   = ~ps2_clk_tx_2;
  assign ps2_keyb_data_O  = 1'b0;
  assign ps2_keyb_data_T  = ~ps2_d_tx_2;

endmodule // dual_ps2_ioadapter 

