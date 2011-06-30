//-----------------------------------------------------------------------------
//
//    File Name:  FILEREAD_TESTER.v
//      Project:  $PROJECT_NAME
//      Version:  1.2
//         Date:  2005-06-29
//
//      Company:  Xilinx, Inc.
//  Contributor:  Wen Ying Wei, Davy Huang
//
//   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
//                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
//                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
//                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
//                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
//                APPLICATION OR STANDARD, XILINX IS MAKING NO
//                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
//                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
//                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
//                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
//                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
//                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
//                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
//                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
//                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//                PURPOSE.
//                
//                (c) Copyright 2005 Xilinx, Inc.
//                All rights reserved.
//
//-----------------------------------------------------------------------------
// Aurora FILEREAD_TESTER
// Author: Nigel Gulstone, Davy Huang
//
// Description: Drives the LocalLink, NFC and UFC interfaces and the other
//              User signals using vectors from a file...
//-----------------------------------------------------------------------------



`timescale 1 ns / 10 ps
module FILEREAD_TESTER
(
      CLK,
      TV,

      //LocalLink Interface
      TX_SOF_N,
      TX_EOF_N,
      TX_D,
      TX_REM,
      TX_SRC_RDY_N,

      //NFC Interface//Native Flow Control Interface
      NFC_NB,
      NFC_REQ_N,

      //UFC Interface//User Flow Control Interface
      UFC_TX_REQ_N,
      UFC_TX_MS,

      //Control Vector Signals
      CTRL
);

  // Parameter Declarations ********************************************
  parameter     GLOBALDLY = 1;
  parameter     TV_WIDTH  = 8; // test vector width: 4,8,12,16, etc.
  parameter     CV_WIDTH  = 4; // control vector width: 4,8,12,16, etc.
  parameter     LL_DAT_BIT_WIDTH = 64; //8,16,32,64,128,256
  parameter     LL_REM_BIT_WIDTH  = 3; //0,1 ,2, 3, 4,  5
  parameter     REM_VECTOR_WIDTH  = 3; //3 (if LL_REM_BIT_WIDTH <=3) or 7 (if LL_REM_BIT_WIDTH >3)

  // Port Declarations ************************************************

  input             CLK;
  input     [0:TV_WIDTH-1]           TV;

  //LocalLink Interface
  output            TX_SOF_N;
  output            TX_EOF_N;
  output    [0:LL_DAT_BIT_WIDTH-1]  TX_D;
  output    [0:LL_REM_BIT_WIDTH-1]   TX_REM;
  output            TX_SRC_RDY_N;


  //NFC Interface
  output    [0:3]   NFC_NB;
  output            NFC_REQ_N;


  //UFC Interface
  output            UFC_TX_REQ_N;
  output    [0:3]   UFC_TX_MS;

  //Clock Correction Interface
  output    [0:CV_WIDTH-1]    CTRL;


  // Signal Declarations ***********************************************


  reg       [LL_DAT_BIT_WIDTH + 4 + 4 + 1+1+1+1+1+REM_VECTOR_WIDTH+CV_WIDTH+16+TV_WIDTH:1] stim [0:65535];
  integer           index;
  reg       [LL_DAT_BIT_WIDTH + 4 + 4 + 1+1+1+1+1+REM_VECTOR_WIDTH+CV_WIDTH:1] vector;
  reg       [LL_DAT_BIT_WIDTH + 4 + 4 + 1+1+1+1+1+REM_VECTOR_WIDTH+CV_WIDTH:1] vector_dummy;
  wire              dummy;
  reg       [0:15]  repeat_count_i;
  reg       [0:15]  repeat_count_dummy;
  reg       [TV_WIDTH-1:0]   testvec;     
  reg       [TV_WIDTH-1:0]   testvec_dummy;     

  reg      [0:3]   i;

  wire     [0:REM_VECTOR_WIDTH-1]  TX_REM_i;
  reg      [0:LL_REM_BIT_WIDTH-1]   TX_REM;
  
  parameter TX_D_BOUND = LL_DAT_BIT_WIDTH + 4 + 4 + 1+1+1+1+1+REM_VECTOR_WIDTH+CV_WIDTH;
  
  
// Main Body of Code *************************************************



  initial
  begin
    index <= 0;
    repeat_count_i <= 16'h0000;
    $readmemh("user_data_packets.vec",stim);
    testvec <= 0;
    vector <= 0;
  end

  //       64,    4 ,     4,       1,        1,         1,          1,        1,           3,   cv_width
  assign {TX_D,NFC_NB,UFC_TX_MS,NFC_REQ_N,UFC_TX_REQ_N,TX_SOF_N,TX_SRC_RDY_N,TX_EOF_N,  TX_REM_i,CTRL} = vector;


  always @(TX_REM_i)
    begin
      for (i=0;i<LL_REM_BIT_WIDTH;i=i+1)
        TX_REM[i] = TX_REM_i[REM_VECTOR_WIDTH-LL_REM_BIT_WIDTH+i];
  end



  always @(posedge CLK)
    if( repeat_count_i > 0  )
        repeat_count_i <= #GLOBALDLY repeat_count_i - 1;
    else if( testvec != 0)
    begin
        for (i=0;i<TV_WIDTH;i=i+1)
          if (TV[i])  testvec[TV_WIDTH-1-i] = 1'b0;

        if(testvec == 0 && index < 65535)
        begin
            {vector_dummy,repeat_count_dummy,testvec_dummy} = stim[index];
            if (vector_dummy[TX_D_BOUND:TX_D_BOUND-15] == 16'hDEAD) begin
                {vector,repeat_count_i,testvec} = #GLOBALDLY stim[0];
                index = 1;                
               end
            else begin
               {vector,repeat_count_i,testvec} = #GLOBALDLY stim[index];
               index = index + 1;
               end
        end
    end
    else if( index < 65535 )
    begin
            {vector_dummy,repeat_count_dummy,testvec_dummy} = stim[index]; 
            if (vector_dummy[TX_D_BOUND:TX_D_BOUND-15] == 16'hDEAD) begin
                {vector,repeat_count_i,testvec} = #GLOBALDLY stim[0];
                index = 1;                
               end
            else begin
               {vector,repeat_count_i,testvec} = #GLOBALDLY stim[index];
               index = index + 1;
               end
    end
endmodule

//-----------------------------------------------------------------------------
// History:
//   NG       05/15/03  Begin Coding
//   NG       05/16/03  Add test vector
//   NG       05/21/03  Generic Test Vectors 
//   DH       06/12/03  Make it support generic data width
//   DH       10/19/03  Generic Control Vectors
//   DH       08/30/04  Added "end of vector file" flag to repeat the test
//-----------------------------------------------------------------------------
// $Revision: 1.2 $
// $Date: 2004/12/27 18:12:18 $

