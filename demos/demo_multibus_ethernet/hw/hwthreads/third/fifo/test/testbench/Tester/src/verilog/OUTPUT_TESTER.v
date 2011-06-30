//-----------------------------------------------------------------------------
//
//    File Name:  OUTPUT_TESTER.v
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
// OUTPUT_TESTER
// Author: Nigel Gulstone, Davy Huang
//
// Description: Monitors the output from the Tester RX interfaces and
//              compares the data it receives with reference data. The
//              reference data is typically the data that was given to
//              the TX interface of the receiving channel
//              partner. The output data and the reference data must match
//              for result good to be asserted.
//-----------------------------------------------------------------------------

`timescale 1 ns / 10 ps

module OUTPUT_TESTER(
    
    CLK,                    
    RST,                    
    
    
    //Dut LocalLink Interface
    RX_D,                                    
    RX_REM,                                
    RX_SOF_N,                            
    RX_EOF_N,                            
    RX_SRC_RDY_N,                    
    
    
    //Dut UFC Interface 
    UFC_RX_DATA,            
    UFC_RX_REM,                
    UFC_RX_SOF_N,
    UFC_RX_EOF_N,
    UFC_RX_SRC_RDY_N,
    
  
    //Reference LocalLink Interface
    RX_SOF_N_REF,                    
    RX_EOF_N_REF,                    
    RX_REM_REF,                           
    RX_DATA_REF,                            
    RX_SRC_RDY_N_REF,            
        
    
    //Reference UFC Interface 
    UFC_RX_DATA_REF,           
    UFC_RX_REM_REF,             
    UFC_RX_SOF_N_REF,
    UFC_RX_EOF_N_REF,
    UFC_RX_SRC_RDY_N_REF,
              

    //Comparison result
    WORKING,
    COMPARING,
    OVERFLOW,
    RESULT_GOOD,
    RESULT_GOOD_PDU,
    RESULT_GOOD_UFC
    
);


  // Parameter Declarations ********************************************
  parameter     GLOBALDLY = 1; 
  parameter     LL_DAT_BIT_WIDTH = 64; //16,32,64,128
  parameter     LL_REM_BIT_WIDTH  = 3; // 1, 2, 3,  4
  parameter     FIFO_DEPTH = 100;
  
  
  // Port Declarations ************************************************ 
  input             CLK;
  input             RST;
  
  
   //Dut LocalLink Interface
  input     [0:LL_DAT_BIT_WIDTH-1]  RX_D; 
  input     [0:LL_REM_BIT_WIDTH-1]  RX_REM;                                
  input             RX_SOF_N;                            
  input             RX_EOF_N;                            
  input             RX_SRC_RDY_N;                    
      
      
  //UFC Interface //Dut UFC Interface 
  input     [0:LL_DAT_BIT_WIDTH-1]  UFC_RX_DATA;           
  input     [0:LL_REM_BIT_WIDTH-1]   UFC_RX_REM;              
  input             UFC_RX_SOF_N;
  input             UFC_RX_EOF_N;
  input             UFC_RX_SRC_RDY_N;
      
    
  //Reference LocalLink Interface
  input             RX_SOF_N_REF;                    
  input             RX_EOF_N_REF;                    
  input     [0:LL_REM_BIT_WIDTH-1]   RX_REM_REF;                           
  input     [0:LL_DAT_BIT_WIDTH-1]  RX_DATA_REF;                            
  input             RX_SRC_RDY_N_REF;            
          
      
  //Reference UFC Interface 
  input     [0:LL_DAT_BIT_WIDTH-1]  UFC_RX_DATA_REF;          
  input     [0:LL_REM_BIT_WIDTH-1]   UFC_RX_REM_REF;            
  input             UFC_RX_SOF_N_REF;
  input             UFC_RX_EOF_N_REF;
  input             UFC_RX_SRC_RDY_N_REF;
                
  
  //Comparison result
  output            WORKING;
  output            COMPARING;
  output            OVERFLOW;
  output            RESULT_GOOD;
  output            RESULT_GOOD_PDU;
  output            RESULT_GOOD_UFC;
  
  // Signal Declarations ***********************************************   
  reg               WORKING;
  reg               COMPARING;
  reg               OVERFLOW;
  reg               RESULT_GOOD;
  reg               RESULT_GOOD_PDU;
  reg               RESULT_GOOD_UFC;
  
  integer           dut_index;
  integer           ref_index;
  integer           dut_ufc_index;
  integer           ref_ufc_index;
  integer           shuffle;
  reg       [0:LL_DAT_BIT_WIDTH+1]  dut_data_fifo [0:FIFO_DEPTH-1];
  reg       [0:LL_DAT_BIT_WIDTH+1]  ref_data_fifo [0:FIFO_DEPTH-1];
  reg       [0:LL_DAT_BIT_WIDTH+1]  dut_ufc_fifo  [0:FIFO_DEPTH-1];
  reg       [0:LL_DAT_BIT_WIDTH+1]  ref_ufc_fifo  [0:FIFO_DEPTH-1];
  reg       [0:LL_DAT_BIT_WIDTH+1]  dut_data;
  reg       [0:LL_DAT_BIT_WIDTH+1]  ref_data;

  wire      [0:LL_DAT_BIT_WIDTH-1]  dut_data_view;
  wire      [0:LL_DAT_BIT_WIDTH-1]  ref_data_view;

  reg       [0:LL_DAT_BIT_WIDTH+1]  dut_ufc_data;
  reg       [0:LL_DAT_BIT_WIDTH+1]  ref_ufc_data;
  reg               inframe;
  reg               inframe_ref;
 
  reg               clk_detect;
  reg               clk_detect_p;
  wire              clk_detected;
  
  integer           index1;
  integer           index2;
  integer           index3;
  integer           index4;

  wire     [0:256-LL_DAT_BIT_WIDTH] zeros;
  wire     [0:256]  RX_D_i;
  wire     [0:256]  UFC_RX_DATA_i;
  wire     [0:256]  RX_DATA_REF_i; 
  wire     [0:256]  UFC_RX_DATA_REF_i;
  
  assign zeros = 0;
  
  assign RX_D_i[0:LL_DAT_BIT_WIDTH-1] = RX_D;
  assign RX_D_i[LL_DAT_BIT_WIDTH:256] = 0;
  
  assign UFC_RX_DATA_i[0:LL_DAT_BIT_WIDTH-1] = UFC_RX_DATA;
  assign UFC_RX_DATA_i[LL_DAT_BIT_WIDTH:256] = 0;
  
  assign RX_DATA_REF_i[0:LL_DAT_BIT_WIDTH-1] = RX_DATA_REF;
  assign RX_DATA_REF_i[LL_DAT_BIT_WIDTH:256] = 0;
  
  assign UFC_RX_DATA_REF_i[0:LL_DAT_BIT_WIDTH-1] = UFC_RX_DATA_REF;
  assign UFC_RX_DATA_REF_i[LL_DAT_BIT_WIDTH:256] = 0;
  
  assign dut_data_view = dut_data[0:LL_DAT_BIT_WIDTH-1];
  assign ref_data_view = ref_data[0:LL_DAT_BIT_WIDTH-1];
  
  // Main Body of Code *************************************************

  initial
  fork
    ref_index           = 0;
    dut_index           = 0;
    ref_ufc_index       = 0;
    dut_ufc_index       = 0;
    RESULT_GOOD_PDU     = 1'b1;
    RESULT_GOOD_UFC     = 1'b1;
    WORKING             = 1'b0;
    COMPARING           = 1'b0;
    OVERFLOW            = 1'b0;
    clk_detect          = 1'b0;
    clk_detect_p        = 1'b0;
  join
  
  
  //A logic to detect wheather this tester starts working
  always @(posedge CLK)
    clk_detect <= ~clk_detect;

  always @(negedge CLK)
    clk_detect_p <= clk_detect;
  
  assign clk_detected = clk_detect ^ clk_detect_p;
  always @(negedge CLK)
   begin
    if (RST)   WORKING <= 1'b0; 
    else WORKING <= clk_detected; 
   end  
  
  //Inframe logic, for handling multicycle sof and eof
  always @(posedge CLK)
    if(RST)                 inframe     <= #GLOBALDLY 1'b0;
    else if(!inframe)       inframe     <= #GLOBALDLY !RX_SRC_RDY_N & !RX_SOF_N & RX_EOF_N;
    else if( inframe & !RX_SRC_RDY_N & !RX_EOF_N) 
                            inframe     <= #GLOBALDLY 1'b0;
  
  wire inframe_full; // for single data-beat frame
  assign inframe_full = inframe | !RX_SRC_RDY_N & !RX_SOF_N & !RX_EOF_N | !RX_SRC_RDY_N & !RX_SOF_N & RX_EOF_N;
  
  //Put dut data into dut Fifo
  always @(posedge CLK)
    if(!RST & !RX_SRC_RDY_N)
    begin
        if(RX_EOF_N) dut_data[0:LL_DAT_BIT_WIDTH-1] = RX_D;
        else
        begin
            dut_data = 0;
            dut_data[0:7] = RX_D[0:7];            
            for(index1 = 0; index1 < LL_DAT_BIT_WIDTH/8-1; index1 = index1 + 1) begin
               if(RX_REM>index1) begin
                 case (index1) 
                  0:  dut_data[8:15]  = RX_D_i[8:15];
                  1:  dut_data[16:23] = RX_D_i[16:23];
                  2:  dut_data[24:31] = RX_D_i[24:31];
                  3:  dut_data[32:39] = RX_D_i[32:39];
                  4:  dut_data[40:47] = RX_D_i[40:47];
                  5:  dut_data[48:55] = RX_D_i[48:55];
                  6:  dut_data[56:63] = RX_D_i[56:63];
                  7:  dut_data[64:71] = RX_D_i[64:71];
                  8:  dut_data[72:79] = RX_D_i[72:79];
                  9:  dut_data[72:79] = RX_D_i[72:79];
                  10:  dut_data[80:87] = RX_D_i[80:87];
                  11:  dut_data[88:95] = RX_D_i[88:95];
                  12:  dut_data[96:103] = RX_D_i[96:103];
                  13:  dut_data[104:111] = RX_D_i[104:111];
                  14:  dut_data[112:119] = RX_D_i[112:119];
                  15:  dut_data[120:127] = RX_D_i[120:127];
                 endcase
               end
            end
        end
        if(inframe_full)
        begin
            dut_data[LL_DAT_BIT_WIDTH]              = RX_SOF_N & !inframe_full;
            dut_data[LL_DAT_BIT_WIDTH+1]              = RX_EOF_N;
            dut_data_fifo[dut_index]  = dut_data;
            dut_index = dut_index+1;
        end
    end
  
  
  //Put ufc data into ufc Fifo
  always @(posedge CLK)
    if(!RST & !UFC_RX_SRC_RDY_N)
    begin
        if(!UFC_RX_EOF_N)
        begin
            //dut_ufc_data = 64'h0000000000000000;
            dut_ufc_data = 0;
            dut_ufc_data[0:15]                      = UFC_RX_DATA[0:15];
            for(index2 = 1; index2 < LL_DAT_BIT_WIDTH/8-1; index2 = index2 + 2) begin
               if(UFC_RX_REM>index2) begin
                 case (index2)
                   1: dut_ufc_data[16:31]    = UFC_RX_DATA_i[16:31];
                   3: dut_ufc_data[32:47]    = UFC_RX_DATA_i[32:47];
                   5: dut_ufc_data[48:63]    = UFC_RX_DATA_i[48:63];
                   7: dut_ufc_data[64:79]    = UFC_RX_DATA_i[64:79];
                   9: dut_ufc_data[80:95]    = UFC_RX_DATA_i[80:95];
                  11: dut_ufc_data[96:111]   = UFC_RX_DATA_i[96:111];
                  13: dut_ufc_data[112:127]  = UFC_RX_DATA_i[112:127]; 
                 endcase
               end
            end
        end
        else
        begin
            dut_ufc_data[0:LL_DAT_BIT_WIDTH-1] = UFC_RX_DATA;
        end
        dut_ufc_data[LL_DAT_BIT_WIDTH]                        = UFC_RX_SOF_N;
        dut_ufc_data[LL_DAT_BIT_WIDTH+1]                        = UFC_RX_EOF_N;
        dut_ufc_fifo[dut_ufc_index]             = dut_ufc_data;
        dut_ufc_index                           = dut_ufc_index + 1;
    end
  
  
  
  //Reference Inframe logic, for handling multicycle sof and eof
  always @(posedge CLK)
    if(RST)                 inframe_ref <= #GLOBALDLY 1'b0;
    else if(!inframe_ref)   inframe_ref <= #GLOBALDLY !RX_SRC_RDY_N_REF & !RX_SOF_N_REF & RX_EOF_N_REF;
    else if( inframe_ref & !RX_SRC_RDY_N_REF & !RX_EOF_N_REF) 
                            inframe_ref <= #GLOBALDLY 1'b0;
  

  wire inframe_ref_full; // for single data-beat frame
  assign inframe_ref_full = inframe_ref | !RX_SRC_RDY_N_REF & !RX_SOF_N_REF & !RX_EOF_N_REF | !RX_SRC_RDY_N_REF & !RX_SOF_N_REF & RX_EOF_N_REF;
  
  //Put reference data into reference Fifo
  always @(posedge CLK)
  begin
    if(!RST & !RX_SRC_RDY_N_REF)
    begin
        if(RX_EOF_N_REF) ref_data[0:LL_DAT_BIT_WIDTH-1] = RX_DATA_REF;
        else
        begin
            //ref_data = 64'h0000000000000000;
            ref_data = 0;
            ref_data[0:7]   = RX_DATA_REF[0:7];
            for(index3 = 0; index3 < LL_DAT_BIT_WIDTH/8-1; index3 = index3 + 1) begin
               if(RX_REM_REF>index3) begin
                 case (index3) 
                  0:  ref_data[8:15]  = RX_DATA_REF_i[8:15];
                  1:  ref_data[16:23] = RX_DATA_REF_i[16:23];
                  2:  ref_data[24:31] = RX_DATA_REF_i[24:31];
                  3:  ref_data[32:39] = RX_DATA_REF_i[32:39];
                  4:  ref_data[40:47] = RX_DATA_REF_i[40:47];
                  5:  ref_data[48:55] = RX_DATA_REF_i[48:55];
                  6:  ref_data[56:63] = RX_DATA_REF_i[56:63];
                  7:  ref_data[64:71] = RX_DATA_REF_i[64:71];
                  8:  ref_data[72:79] = RX_DATA_REF_i[72:79];
                  9:  ref_data[72:79] = RX_DATA_REF_i[72:79];
                  10:  ref_data[80:87] = RX_DATA_REF_i[80:87];
                  11:  ref_data[88:95] = RX_DATA_REF_i[88:95];
                  12:  ref_data[96:103] = RX_DATA_REF_i[96:103];
                  13:  ref_data[104:111] = RX_DATA_REF_i[104:111];
                  14:  ref_data[112:119] = RX_DATA_REF_i[112:119];
                  15:  ref_data[120:127] = RX_DATA_REF_i[120:127];
                 endcase
               end
            end
            
        end
        if(inframe_ref_full)
        begin
            ref_data[LL_DAT_BIT_WIDTH]                  = RX_SOF_N_REF & !inframe_ref_full;
            ref_data[LL_DAT_BIT_WIDTH+1]                  = RX_EOF_N_REF;
            ref_data_fifo[ref_index]      = ref_data;
            ref_index = ref_index+1;
        end
    end
  end
  
  
  //Put ufc data into ufc Fifo
  always @(posedge CLK)
    if(!RST & !UFC_RX_SRC_RDY_N_REF)
    begin
        if(!UFC_RX_EOF_N_REF)
        begin
            //ref_ufc_data = 64'h0000000000000000;
            ref_ufc_data = 0;
            ref_ufc_data[0:15]                          = UFC_RX_DATA_REF[0:15];
            for(index4 = 1; index4 < LL_DAT_BIT_WIDTH/8-1; index4 = index4 + 2) begin
               if(UFC_RX_REM_REF>index4) begin
                 case (index4)
                 1: ref_ufc_data[16:31]    = UFC_RX_DATA_REF_i[16:31];
                 3: ref_ufc_data[32:47]    = UFC_RX_DATA_REF_i[32:47];
                 5: ref_ufc_data[48:63]    = UFC_RX_DATA_REF_i[48:63];
                 7: ref_ufc_data[64:79]    = UFC_RX_DATA_REF_i[64:79];
                 9: ref_ufc_data[80:95]    = UFC_RX_DATA_REF_i[80:95];
                11: ref_ufc_data[96:111]   = UFC_RX_DATA_REF_i[96:111];
                13: ref_ufc_data[112:127]  = UFC_RX_DATA_REF_i[112:127]; 
                 endcase
               end
            end
            
        end
        else
        begin
            ref_ufc_data[0:LL_DAT_BIT_WIDTH-1] = UFC_RX_DATA_REF;
        end
        
        ref_ufc_data[LL_DAT_BIT_WIDTH]                        = UFC_RX_SOF_N_REF;
        ref_ufc_data[LL_DAT_BIT_WIDTH+1]                        = UFC_RX_EOF_N_REF;
        ref_ufc_fifo[ref_ufc_index]             = ref_ufc_data;
        ref_ufc_index                           = ref_ufc_index + 1;
    end
  

  
  //Compare the data from the 2 LocalLink Fifos
  always @(negedge CLK)
  begin
    if( ref_index >FIFO_DEPTH-1 | dut_index >FIFO_DEPTH-1 ) // overflow
    begin
        RESULT_GOOD_PDU = #GLOBALDLY 1'b0;
        COMPARING       = #GLOBALDLY 1'b0;  
        OVERFLOW        = #GLOBALDLY 1'b1;
    end
    else if( ref_index>0 & dut_index>0 )
    begin
        COMPARING       = #GLOBALDLY 1'b1;        
        dut_data = dut_data_fifo[0];
        ref_data = ref_data_fifo[0];
        if( dut_data != ref_data ) RESULT_GOOD_PDU = #GLOBALDLY 1'b0;
        else                       RESULT_GOOD_PDU = #GLOBALDLY 1'b1;
        
        for(shuffle=0;shuffle<dut_index;shuffle = shuffle + 1)
            dut_data_fifo[shuffle] = dut_data_fifo[shuffle+1];
            
        for(shuffle=0;shuffle<ref_index;shuffle = shuffle + 1)
            ref_data_fifo[shuffle] = ref_data_fifo[shuffle+1];
        
        dut_index = dut_index-1;
        ref_index = ref_index-1;
      end
    else if (ref_ufc_index ==0 | dut_ufc_index ==0)
    begin
        COMPARING = #GLOBALDLY 1'b0;
    end
  end
  
  
  //Compare the data from the 2 UFC Fifos
    always @(negedge CLK)
    begin
      if( ref_ufc_index >FIFO_DEPTH-1 | dut_ufc_index >FIFO_DEPTH-1 )
      begin
          RESULT_GOOD_UFC = #GLOBALDLY 1'b0;
        
      end
      else if( ref_ufc_index>0 & dut_ufc_index>0 )
      begin
          dut_ufc_data = dut_ufc_fifo[0];
          ref_ufc_data = ref_ufc_fifo[0];
          if( dut_ufc_data != ref_ufc_data )    RESULT_GOOD_UFC = #GLOBALDLY 1'b0;
          else                                  RESULT_GOOD_UFC = #GLOBALDLY 1'b1;
          
          for(shuffle=0;shuffle<dut_ufc_index;shuffle = shuffle + 1)
              dut_ufc_fifo[shuffle] = dut_ufc_fifo[shuffle+1];
              
          for(shuffle=0;shuffle<ref_ufc_index;shuffle = shuffle + 1)
              ref_ufc_fifo[shuffle] = ref_ufc_fifo[shuffle+1];
          
          dut_ufc_index = dut_ufc_index-1;
          ref_ufc_index = ref_ufc_index-1;
      end
  end
  
  
  always @(RESULT_GOOD_PDU or RESULT_GOOD_UFC)
  begin
    RESULT_GOOD = #GLOBALDLY RESULT_GOOD_UFC & RESULT_GOOD_PDU;
  end

endmodule


//-----------------------------------------------------------------------------
// History:
//   NG        5/15/03  Modified the USER_IF_TESTER to create this module
//   DH        6/12/03  Added COMPARING and WORKING outputs, Make it support
//                      16,32,64,128 data widths
//   DH        12/17/04 Fixed in_frame_full bug that omits the SOF data beat.
//-----------------------------------------------------------------------------
// $Revision: 1.2 $
// $Date: 2004/12/27 18:12:18 $
