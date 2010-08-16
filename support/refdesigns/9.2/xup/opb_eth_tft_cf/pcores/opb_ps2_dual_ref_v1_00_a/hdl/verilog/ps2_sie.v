//////////////////////////////////////////////////////////////////////////////
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
//////////////////////////////////////////////////////////////////////////////
// Filename:        ps2_sie.v
//
// Description:     PS/2 Serial Interface Engine
//  
// Host2Device: Host changes data only when clock line is LOW
//              Device latches data at Rising edge
// Device2Host: Device changes data only when clock line is high
//              Host latches data at falling edge
// Restriction: System Clock (Clk) must be much faster than PS2Clk.
//              Typical usage is 1000x of PS2Clk(10kHz~20kHz). 
//////////////////////////////////////////////////////////////////////////////
// Structure:   
//              
//////////////////////////////////////////////////////////////////////////////
//
// History:
//   wph        10/10/01
//
//////////////////////////////////////////////////////////////////////////////
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      Rst signals:                            "rst", "rst_n" 
//      generics:                               "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      ports:                                  - Names begin with Uppercase 
//      processes:                              "*_PROCESS" 
//      component instantiations:               "<ENTITY_>I_<#|FUNC>
//////////////////////////////////////////////////////////////////////////////


module ps2_sie(
  //global signal
  Clk,              // I  system clock
  Rst,              // I  system reset + software reset (offset)
  
  //PS2 interface signal
  Clkin,            // I  PS2 Bi-di Clock in
  Clkpd,            // O  PS2 Bi-di Clock Pull down 
  Rx,               // I  PS2 Bi-di serial data in 
  Txpd,             // O  PS2 Bi-di serial data out pull down 

 
  //interface signal for memory mapped registers
  rx_full_sta,      // I
  rx_full_set,      // O
  rx_err_set,       // O
  rx_ovf_set,       // O

  tx_full_sta,      // I
  tx_full_clr,      // O
  tx_ack_set,       // O
  tx_noack_set,     // O
 
  wdt_tout_set,     // O 

  tx_data,          // I
  rx_data           // O
  
);


  ///////////////////////////////////////////////////////////////////////////////
  // Port Declarations
  //////////////////////////////////////////////////////////////////////////////

  //global signal
  input           Clk;              // I  system clock
  input           Rst;              // I  system reset + software reset (offset)
  
  //PS2 interface signal
  input           Clkin;            // I  PS2 Bi-di Clock in
  output          Clkpd;            // O  PS2 Bi-di Clock Pull down 
  input           Rx;               // I  PS2 Bi-di serial data in 
  output          Txpd;             // O  PS2 Bi-di serial data out pull down 

 
  //interface signal for memory mapped registers
  input           rx_full_sta;      // I
  output          rx_full_set;      // O
  output          rx_err_set;       // O
  output          rx_ovf_set;       // O

  input           tx_full_sta;      // I
  output          tx_full_clr;      // O
  output          tx_ack_set;       // O
  output          tx_noack_set;     // O  
 
  output          wdt_tout_set;      // O 

  input   [0:7]   tx_data;           // I
  output  [0:7]   rx_data;          // O



  ///////////////////////////////////////////////////////////////////////////////
  // Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////

// Tuning Timer Value
//REAL
parameter BIT_WDT_TMR_VALUE = 40000;     // 400 us
parameter BIT_WDT_TMR_BITS  = 15;    
parameter DBC_TMR_VALUE     = 370;       // 3.7us
parameter DBC_TMR_BITS      = 9;
parameter REQ_SND_VALUE     = 10000;     //at least 100us
parameter REQ_SND_BITS      = 15;

//testmode
//parameter BIT_WDT_TMR_VALUE = 400;     // 400 us
//parameter BIT_WDT_TMR_BITS  = 15;    
//parameter DBC_TMR_VALUE     = 10;      // 3.7us
//parameter DBC_TMR_BITS      = 9;
//parameter REQ_SND_VALUE     = 100;     //at least 100us
//parameter REQ_SND_BITS      = 15;



  ///////////////////////////////////////////////////////////////////////////////
  // Signal Declarations
  ///////////////////////////////////////////////////////////////////////////////

reg         clkin_1, clkin_2;
reg         rx_1,    rx_2;
reg  [0:10] q;
reg  [0:4]  rx_bit_count;
wire        bit_err1;
wire        rx_err_set;
wire [0:7]  rx_data;
wire        rx_full_set;
wire        rx_ovf_set;
reg         rx_full_sta_dly;
reg         Txpd;
reg         txpd_i;
reg         Clkpd;
wire        tx_ack_set;
wire        tx_noack_set;
wire        tx_full_clr;
 
wire        dbc_done;
wire        bit_wdt_done;
wire        wdt_tout_set;
wire        rts_cnt_done;

reg [0: DBC_TMR_BITS - 1]      dbc_counter;
reg [0: BIT_WDT_TMR_BITS - 1]  bit_wdt_counter;
reg [0: REQ_SND_BITS - 1]      rts_counter;

reg tx_ack_set_temp ;  
reg tx_noack_set_temp ;
reg tx_full_clr_temp ; 

 


  ///////////////////////////////////////////////////////////////////////////////
  // Sate Machine Declarations
  ///////////////////////////////////////////////////////////////////////////////

parameter DETECT_CLK_HIGH = 6'b000001;//5
parameter DETECT_CLK_FALL = 6'b000010;//4
parameter DETECT_CLK_FDBC = 6'b000100;//3
parameter DETECT_CLK_LOW  = 6'b001000;//2
parameter DETECT_CLK_RISE = 6'b010000;//1
parameter DETECT_CLK_RDBC = 6'b100000;//0
reg [0:5] detect_clk_cs, detect_clk_ns;
wire clk_fall, clk_rise;  
assign clk_fall = detect_clk_cs[4];
assign clk_rise = detect_clk_cs[1];

parameter RX_CTL_IDLE      = 6'b000001; //5
parameter RX_CTL_STARTCNT  = 6'b000010; //4
parameter RX_CTL_GETB1     = 6'b000100; //3
parameter RX_CTL_CHECKB1   = 6'b001000; //2
parameter RX_CTL_ERR1      = 6'b010000; //1 
parameter RX_CTL_USEB1     = 6'b100000; //0
reg [0:5] rx_ctl_cs, rx_ctl_ns;
wire rx_sta_idle, rx_sta_startcnt, rx_sta_err1, rx_sta_useb1;
assign rx_sta_idle      = rx_ctl_cs[5]; 
assign rx_sta_startcnt  = rx_ctl_cs[4]; 
assign rx_sta_err1      = rx_ctl_cs[1];
assign rx_sta_useb1     = rx_ctl_cs[0]; 


parameter TX_CTL_IDLE        = 16'b0000000000000001; //15
parameter TX_CTL_WAIT        = 16'b0000000000000010; //14
parameter TX_CTL_CLKPD       = 16'b0000000000000100; //13
parameter TX_CTL_DATAPD      = 16'b0000000000001000; //12
parameter TX_CTL_SND7        = 16'b0000000000010000; //11
parameter TX_CTL_SND6        = 16'b0000000000100000; //10
parameter TX_CTL_SND5        = 16'b0000000001000000; //9
parameter TX_CTL_SND4        = 16'b0000000010000000; //8
parameter TX_CTL_SND3        = 16'b0000000100000000; //7
parameter TX_CTL_SND2        = 16'b0000001000000000; //6
parameter TX_CTL_SND1        = 16'b0000010000000000; //5
parameter TX_CTL_SND0        = 16'b0000100000000000; //4
parameter TX_CTL_PRTY        = 16'b0001000000000000; //3
parameter TX_CTL_STOP        = 16'b0010000000000000; //2
parameter TX_CTL_WAITFEDGE   = 16'b0100000000000000; //1 
parameter TX_CTL_CHKACK      = 16'b1000000000000000; //0
reg [0:15] tx_ctl_cs, tx_ctl_ns;
wire tx_sta_idle,tx_busy,tx_sta_clkpd,tx_sta_datapd, 
     tx_sta_chkack, tx_sta_waitfedge, tx_sta_clkpd_next, tx_sta_idle_next;
wire tx_sta_wait;
assign tx_sta_wait = tx_ctl_cs[14];
assign tx_sta_idle = tx_ctl_cs[15];
assign tx_sta_idle_next = tx_ctl_ns[15];
assign tx_busy = (~ tx_ctl_cs[15]) && (~ tx_ctl_cs[14]);
assign tx_sta_clkpd = tx_ctl_cs[13];
assign tx_sta_clkpd_next = tx_ctl_ns[13];
assign tx_sta_datapd = tx_ctl_cs[12];
assign tx_sta_waitfedge = tx_ctl_cs[1];
assign tx_sta_chkack    = tx_ctl_cs[0];


///////////////////////////////////////////////////////////////////////////////
//begin
///////////////////////////////////////////////////////////////////////////////


//-----------------------------------------------------------------
//Receiving serial rx and Clkin,reisters to avoid metastability
//-----------------------------------------------------------------
always @(posedge Clk)
begin
  if (Rst)
    begin
    clkin_1 <= 1'b1;
    clkin_2 <= 1'b1;
    rx_1    <= 1'b1;
    rx_2    <= 1'b1;
    end
  else 
    begin
    clkin_1 <= Clkin;
    clkin_2 <= clkin_1 ;
    rx_1    <= Rx;
    rx_2    <= rx_1;
    end
end

//-----------------------------------------------------------------
// This State machine - Detect Clock basically detects 
// the clock edges and wait for debouncing done.
//-----------------------------------------------------------------
  
always @(posedge Clk)
begin 
  if (Rst) detect_clk_cs <= DETECT_CLK_HIGH;
  else     detect_clk_cs <= detect_clk_ns;
end

always @(detect_clk_cs or 
         clkin_2       or
         dbc_done   )
begin 
    case (detect_clk_cs)
  
    DETECT_CLK_HIGH:  begin
               if (~ clkin_2)    detect_clk_ns <= DETECT_CLK_FALL;
               else             detect_clk_ns <= DETECT_CLK_HIGH;
               end
      
    DETECT_CLK_FALL:            detect_clk_ns <= DETECT_CLK_FDBC;
 

     
    DETECT_CLK_FDBC:  begin
               if (dbc_done)    detect_clk_ns <= DETECT_CLK_LOW;
               else             detect_clk_ns <= DETECT_CLK_FDBC;
               end

    DETECT_CLK_LOW:  begin
               if (clkin_2)     detect_clk_ns <= DETECT_CLK_RISE;
               else             detect_clk_ns <= DETECT_CLK_LOW;
               end

    DETECT_CLK_RISE:            detect_clk_ns <= DETECT_CLK_RDBC;




    DETECT_CLK_RDBC:  begin
               if (dbc_done)    detect_clk_ns <= DETECT_CLK_HIGH;
               else             detect_clk_ns <= DETECT_CLK_RDBC;
               end

    default :                   detect_clk_ns <= DETECT_CLK_HIGH;



    endcase
end

//-----------------------------------------------------------------
//This statemachine performs RX flow control. 
//-----------------------------------------------------------------
//If Host is transmitting command (tx_busy), 
//RX statemachine has to be forced to be WAIT status.
always @(posedge Clk)
begin 
  if (Rst || tx_busy || bit_wdt_done || tx_sta_clkpd_next) 
                                      rx_ctl_cs <= RX_CTL_IDLE;   
  else                                rx_ctl_cs <= rx_ctl_ns ;
end

always @(rx_ctl_cs    or 
         clk_fall     or
         tx_sta_idle  or
         rx_bit_count or
         bit_err1 )
begin 
    case (rx_ctl_cs)
   
    RX_CTL_IDLE:  begin
               if (clk_fall && tx_sta_idle)       rx_ctl_ns <= RX_CTL_STARTCNT;
               else                               rx_ctl_ns <= RX_CTL_IDLE;
               end
    //IDLE -> STARTCNT reset rx_bit_count and q-reg

    //STARTCNT: (an intermediate state) start counting and register rx data
    RX_CTL_STARTCNT:                              rx_ctl_ns <= RX_CTL_GETB1;  

    RX_CTL_GETB1:  begin
               if (rx_bit_count == 11)            rx_ctl_ns <= RX_CTL_CHECKB1;
               else                               rx_ctl_ns <= RX_CTL_GETB1;
               end

    RX_CTL_CHECKB1:  begin
               if (bit_err1)                      rx_ctl_ns <= RX_CTL_ERR1;
               else                               rx_ctl_ns <= RX_CTL_USEB1;
               end

    RX_CTL_ERR1:                                  rx_ctl_ns <= RX_CTL_IDLE;

    RX_CTL_USEB1:                                 rx_ctl_ns <= RX_CTL_IDLE;

    default :                                     rx_ctl_ns <= RX_CTL_IDLE;


    endcase
end

//------------------
//RX shift register & bit counter
//------------------
//IDLE->RSTCNT: clear q-reg, clear rx_bit_count 
//delicate rx_bit_counter
always @(posedge Clk)
begin
  if (Rst || rx_sta_idle) begin                                  
            q             <= 0;
            rx_bit_count  <= 0; 
           end
  else if ( (clk_fall && ~ rx_sta_idle) || rx_sta_startcnt ) begin
            q             <= {rx_2,q[0:9]};
            rx_bit_count  <= rx_bit_count + 1;
            end
  else if (  bit_wdt_done || (clk_fall && rx_sta_idle )) begin
            q             <= 0;
            rx_bit_count  <= 0; 
            end
end

//-----------------------------------
//RX_CTL_CHECKB1 
//-----------------------------------
//Check start/stop/parity bit
//Notice the bit ordering in phsucal SReg is [0:10]
// b0   b1     b2~b9   b10   ; 
// STOP PARITY DATA  START 

assign bit_err1 =  ~  (  (q[10]  == 0)          // start        
                      && (q[0]   == 1)          // stop
                      && (q[1]   == ~^q[2:9])   // odd parity bit
                      );

//wire start_bit = q[10];
//wire stop_bit  = q[0];
//wire odd_parity= q[1];
//wire xnor_data = ~^q[2:9];

//-------------
//RX_CTL_ERR1
//-------------
assign rx_err_set    = rx_sta_err1;

//-------------
//RX_CTL_USEB1
//-------------
assign rx_data       = q[2:9];
assign rx_full_set   = rx_sta_useb1;


//check if previous data has been processed by host software,
//if not, then the new upcomming rx data will cause overflow.

assign rx_ovf_set    = rx_sta_useb1 & rx_full_sta_dly;

always @ (posedge Clk)
begin
  if (Rst)
       rx_full_sta_dly <= 0;
  else rx_full_sta_dly <= rx_full_sta;
  end

//-----------------------------------------------------------------
//This statemachine controls Transmission flow (TX_CTL)
//-----------------------------------------------------------------
always @(posedge Clk)
begin 
  if (Rst) tx_ctl_cs <= TX_CTL_IDLE;   
  else     tx_ctl_cs <= tx_ctl_ns ;
end
always @(posedge Clk)
begin 
  if (Rst)               Txpd      <= 0;
  else if ((clk_fall && tx_busy ) || tx_sta_datapd )     Txpd      <= txpd_i ;
end

always @(tx_ctl_cs    or
         tx_full_sta  or 
         rx_bit_count or 
         rts_cnt_done or 
         clk_fall or 
         tx_data or clk_rise)
begin 
    
    case (tx_ctl_cs )
  
    TX_CTL_IDLE   : begin
                                txpd_i <= 1'b0;
          if (tx_full_sta)      tx_ctl_ns <= TX_CTL_WAIT ;
          else                  tx_ctl_ns <= TX_CTL_IDLE ;
          end
    TX_CTL_WAIT   : begin
                                txpd_i <= 1'b0;
          if ( ~(rx_bit_count  == 10) && ~(rx_bit_count  == 11) )
                                tx_ctl_ns <= TX_CTL_CLKPD;
          else                  tx_ctl_ns <= TX_CTL_WAIT;
          end

    TX_CTL_CLKPD : begin
                                txpd_i <= 1'b0;
          if ( rts_cnt_done )   tx_ctl_ns <= TX_CTL_DATAPD; 
          else                  tx_ctl_ns <= TX_CTL_CLKPD;
          end

    TX_CTL_DATAPD : begin
                                txpd_i <= 1'b1;    //Start bit
                                tx_ctl_ns <= TX_CTL_SND7;
                    end

    TX_CTL_SND7  : begin         
                                txpd_i <= ~tx_data[7];    
                   if ( clk_fall ) begin
                                tx_ctl_ns <= TX_CTL_SND6;
                                end
                   else         begin
                              
                                tx_ctl_ns <= TX_CTL_SND7;
                                end
                   end
    TX_CTL_SND6  : begin         
                                txpd_i <= ~tx_data[6];    
                   if ( clk_fall ) begin
                                tx_ctl_ns <= TX_CTL_SND5;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_SND6;
                                end
                   end

    TX_CTL_SND5  : begin         
                                txpd_i <= ~tx_data[5];    
                   if ( clk_fall )begin
                                tx_ctl_ns <= TX_CTL_SND4;
                                end
                   else         begin
                                tx_ctl_ns <= TX_CTL_SND5;
                                end
                   end

    TX_CTL_SND4  : begin         
                                txpd_i <= ~tx_data[4];    
                   if ( clk_fall )begin 
                                tx_ctl_ns <= TX_CTL_SND3;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_SND4;
                                end
                   end

    TX_CTL_SND3  : begin         
                                txpd_i <= ~tx_data[3];    
                   if ( clk_fall )begin 
                                tx_ctl_ns <= TX_CTL_SND2;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_SND3;
                                end
                   end

    TX_CTL_SND2  : begin         
                                txpd_i <= ~tx_data[2];    
                   if ( clk_fall )begin 
                                tx_ctl_ns <= TX_CTL_SND1;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_SND2;
                                end
                   end

    TX_CTL_SND1  : begin         
                                txpd_i <= ~tx_data[1];    
                   if ( clk_fall )begin 
                                tx_ctl_ns <= TX_CTL_SND0;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_SND1;
                                end
                   end

    TX_CTL_SND0  : begin         
                                txpd_i <= ~tx_data[0];    
                   if ( clk_fall )begin 
                                tx_ctl_ns <= TX_CTL_PRTY  ;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_SND0;
                                end
                   end

    TX_CTL_PRTY  : begin         
                                txpd_i <= ^tx_data[0:7];    
                   if ( clk_fall )begin 
                                tx_ctl_ns <= TX_CTL_STOP  ;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_PRTY;
                                end
                   end

   TX_CTL_STOP  : begin         
                                txpd_i <= 1'b0;    
                   if ( clk_fall )begin 
                                tx_ctl_ns <= TX_CTL_WAITFEDGE  ;
                                end
                   else         begin 
                                tx_ctl_ns <= TX_CTL_STOP;
                                end
                   end

    TX_CTL_WAITFEDGE  : begin 
                                  txpd_i <= 1'b0;
          if ( clk_fall )
                                  tx_ctl_ns <= TX_CTL_CHKACK;             
          else                    tx_ctl_ns <= TX_CTL_WAITFEDGE;
          end

              
  
    TX_CTL_CHKACK:    begin       txpd_i <= 1'b0;
          if (clk_rise )                   
                                  tx_ctl_ns <= TX_CTL_IDLE;
          else                    tx_ctl_ns <= TX_CTL_CHKACK;
          end
  
    default:          begin       txpd_i <= 1'b0;
                                  tx_ctl_ns <= TX_CTL_IDLE;
                      end

   
  endcase
end

//-------------
//TX_CTL_CLKPD & TX_CTL_DATAPD
//-------------
//register this to avoid glitch
always @ (posedge Clk)
begin 
   if (Rst)
        Clkpd <= 0;
   else Clkpd <= tx_sta_clkpd || tx_sta_datapd;
end


//------------------
//TX_CTL_CHKACK
//------------------
//Delay tx status update. 
//tx status cannot be updated until state TX_CTL_CHKACK has completed 
always @(posedge Clk)
begin 
  if (Rst || tx_sta_idle) 
     begin 
       tx_ack_set_temp    <= 1'b0;
       tx_noack_set_temp  <= 1'b0;
       tx_full_clr_temp   <= 1'b0;
     end
  else if (tx_sta_waitfedge && clk_fall)
     begin
       tx_ack_set_temp    <= (~ rx_2);
       tx_noack_set_temp  <= (rx_2);
       tx_full_clr_temp   <= 1'b1;
     end
end

//assign tx_ack_set   = tx_sta_chkack & (~ rx_2);
//assign tx_noack_set = tx_sta_chkack & (rx_2);
//assign tx_full_clr  = tx_sta_chkack;
assign tx_ack_set   = ( tx_sta_chkack &&tx_sta_idle_next)? tx_ack_set_temp   :1'b0;
assign tx_noack_set = ( tx_sta_chkack &&tx_sta_idle_next)? tx_noack_set_temp :1'b0;
assign tx_full_clr  = ( tx_sta_chkack &&tx_sta_idle_next)? tx_full_clr_temp  :1'b0;

//----------------------------------------
// Misc counter sections
//----------------------------------------


//------------
// Debounce counter. DBC reset at clock edges
//------------

always @ (posedge Clk)
begin  
  if (Rst || clk_fall || clk_rise)
       dbc_counter <= 0;
  else dbc_counter <= dbc_counter + 1;
end
assign dbc_done = (dbc_counter == DBC_TMR_VALUE -1);

//------------
// WatchDog timer. WTD reset at clock edges
//------------
always @ (posedge Clk)
begin  
  if (Rst || clk_fall|| clk_rise || (rx_sta_idle && tx_sta_idle ))
       bit_wdt_counter <= 0;
  else bit_wdt_counter <= bit_wdt_counter + 1;
end
assign bit_wdt_done = (bit_wdt_counter == BIT_WDT_TMR_VALUE -1);
assign wdt_tout_set = bit_wdt_done ;

//------------
// Request-to-Send timer.
//------------
always @ (posedge Clk)
begin  
  if (Rst || (tx_sta_clkpd_next && tx_sta_wait) )
       rts_counter <= 0;
  else rts_counter <= rts_counter + 1;
end
assign rts_cnt_done = (rts_counter == REQ_SND_VALUE  -1);



endmodule
