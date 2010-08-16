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
// Filename:        ps2_reg.v
//
// Description:     PS/2 memory mapped registers
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


module ps2_reg(
  //global signal
  Clk,              // I  system clock
  Rst,              // I  system reset
  
  //IPIF Signals
  Bus2IP_RegCE,    // I [0:7] 
  Bus2IP_Data,     // I [0:7]
  Bus2IP_RdReq,    // I
  Bus2IP_WrReq,    // I
  IP2Bus_Data,     // O [0:7]
  IP2Bus_Error,    // O
  IP2Bus_RdAck,    // O
  IP2Bus_Retry,    // O
  IP2Bus_ToutSup,  // O
  IP2Bus_WrAck,    // O
  IP2Bus_Intr,     // O 


  //interface signal for memory mapped registers
  srst,             // O global rest + software reset, send to ps2_sie
  rx_full_sta,      // O
  rx_full_set,      // I
  rx_err_set,       // I
  rx_ovf_set,       // I
  tx_full_sta,      // O
  tx_full_clr,      // I
  tx_ack_set,       // I
  tx_noack_set,     // I
  wdt_tout_set,     // I 

  tx_data,          // O [0:7]
  rx_data           // I [0:7]
  
);

///////////////////////////////////////////////////////////////////////////////
//ports
///////////////////////////////////////////////////////////////////////////////
input          Clk;              // I  system clock
input          Rst;              // I  system reset
  
  //IPIF Signals
input [0:7]    Bus2IP_RegCE;    // I [0:7] 
input [0:7]    Bus2IP_Data;     // I [0:7]
input          Bus2IP_RdReq;    // I
input          Bus2IP_WrReq;    // I
output [0:7]   IP2Bus_Data;     // O [0:7]
output         IP2Bus_Error;    // O
output         IP2Bus_RdAck;    // O
output         IP2Bus_Retry;    // O
output         IP2Bus_ToutSup;  // O
output         IP2Bus_WrAck;    // O
output         IP2Bus_Intr;     // O


  //interface signal for memory mapped registers
output         srst;              // O global rest + software reset, send to ps2_sie

output         rx_full_sta;      // O
input          rx_full_set;      // I
input          rx_err_set;       // I
input          rx_ovf_set;       // I
output         tx_full_sta;      // O
input          tx_full_clr;      // I
input          tx_ack_set;       // I
input          tx_noack_set;     // I
 
input          wdt_tout_set;     // I

output  [0:7]  tx_data;          // O [0:7]
input   [0:7]  rx_data;          // I [0:7]

///////////////////////////////////////////////////////////////////////////////
//wires
///////////////////////////////////////////////////////////////////////////////
wire srst_ce;   
wire sta_ce;      
wire tx_data_ce;  
wire rx_data_ce;  
wire ints_ce;     
wire intc_ce ;    
wire intms_ce ;   
wire intmc_ce ;   

wire Bus2IP_Data_srst_d;
wire Bus2IP_Data_wdt_tout;  
wire Bus2IP_Data_tx_noack;  
wire Bus2IP_Data_tx_ack;  
wire Bus2IP_Data_rx_ovf;  
wire Bus2IP_Data_rx_err;  
wire Bus2IP_Data_rx_full;  

reg Bus2IP_RdReq_d1;  
reg Bus2IP_WrReq_d1;  
reg IP2Bus_RdAck;  
reg IP2Bus_WrAck;  
reg srst_q;  
reg [0:7] tx_data_q;  
reg [0:7] rx_data_q;  


wire rx_full_sta;
wire int_rx_full_q;
wire int_rx_err_q;
wire int_rx_ovf_q;
wire int_tx_ack_q;
wire int_tx_noack_q;
wire int_wdt_tout_q;
wire intm_rx_full_q;
wire intm_rx_err_q;
wire intm_rx_ovf_q;
wire intm_tx_ack_q;
wire intm_tx_noack_q;
wire intm_wdt_tout_q;


///////////////////////////////////////////////////////////////////////////////
//begin
///////////////////////////////////////////////////////////////////////////////

assign srst_ce    =   Bus2IP_RegCE[0];  // 00 R/W   SRST   (Soft Reset)         bit7
assign sta_ce     =   Bus2IP_RegCE[1];  // 04 R/W   STR    (Status Register)    bit6:7
assign rx_data_ce =   Bus2IP_RegCE[2];  // 08 R/(W) RXR    (RX Register bit)    bit0:7
assign tx_data_ce =   Bus2IP_RegCE[3];  // 0c R/W   TXR    (TX Register)        bit0:7
assign ints_ce    =   Bus2IP_RegCE[4];  // 10 R     INTSTA (Interrupt Status)   bit2:7
assign intc_ce    =   Bus2IP_RegCE[5];  // 14 R/W   INTCLR (Interrupt Clear)    bit2:7
assign intms_ce   =   Bus2IP_RegCE[6];  // 18 R/W   INTMSET(Interrupt Mask Set) bit2:7
assign intmc_ce   =   Bus2IP_RegCE[7];  // 1c R/W   INTMCLR(Interrupt Mask Clr) bit2:7

assign Bus2IP_Data_srst_d   = Bus2IP_Data[7];
// Interrupt bits
// rx_full, rx_err, rx_ovf, tx_ack, tx_noack, wdt_tout
//   2         3       4     5       6        7
assign Bus2IP_Data_wdt_tout = Bus2IP_Data[7];
assign Bus2IP_Data_tx_noack = Bus2IP_Data[6];
assign Bus2IP_Data_tx_ack   = Bus2IP_Data[5];
assign Bus2IP_Data_rx_ovf   = Bus2IP_Data[4];
assign Bus2IP_Data_rx_err   = Bus2IP_Data[3];
assign Bus2IP_Data_rx_full  = Bus2IP_Data[2];

assign IP2Bus_Data = (srst_ce)            ? {7'h0, srst_q} : 
                     (sta_ce)             ? {6'h0, tx_full_sta, rx_full_sta} :
                     (rx_data_ce)         ? rx_data_q:
                     (tx_data_ce)         ? tx_data_q:
                     (ints_ce | intc_ce)  ? {2'h0,int_rx_full_q,  int_rx_err_q,  
                                                 int_rx_ovf_q,   int_tx_ack_q,  
                                                 int_tx_noack_q, int_wdt_tout_q}:
                   
                     (intms_ce |intmc_ce) ? {2'h0,intm_rx_full_q, intm_rx_err_q,  
                                                  intm_rx_ovf_q,  intm_tx_ack_q,
                                                  intm_tx_noack_q,intm_wdt_tout_q}:
                     8'h00;

//Generate Ack signal after Req edge is detect
always @ (posedge Clk)
begin 
  if (Rst) begin Bus2IP_RdReq_d1 <= 0;
                 Bus2IP_WrReq_d1 <= 0;
           end
  else     begin Bus2IP_RdReq_d1 <= Bus2IP_RdReq;
                 Bus2IP_WrReq_d1 <= Bus2IP_WrReq;
           end
end

always @ (posedge Clk)
begin 
  if (Rst) begin IP2Bus_RdAck    <= 0;
                 IP2Bus_WrAck    <= 0;
           end
  else     begin IP2Bus_RdAck    <= (Bus2IP_RdReq & (~ Bus2IP_RdReq_d1) );
                 IP2Bus_WrAck    <= (Bus2IP_WrReq & (~ Bus2IP_WrReq_d1) );
           end
end

//------------------------------------------
//Signals not used
//------------------------------------------
assign IP2Bus_Error   = 1'b0;
assign IP2Bus_Retry   = 1'b0;
assign IP2Bus_ToutSup = 1'b0;
//------------------------------------------
//SRST
//Software Reset 
//------------------------------------------

always @ (posedge Clk)
begin 
  if (Rst)               srst_q <= 0;
  else if (srst_ce && Bus2IP_WrReq)      srst_q <= Bus2IP_Data_srst_d; 
end
            
assign srst = srst_q || Rst; 

//------------------------------------------
//TX_DATA
//TX data register and full
//------------------------------------------

//tx_data
//write by Host
always @ (posedge Clk)
begin 
  if (Rst)                               tx_data_q <= 0;
  else if (tx_data_ce && Bus2IP_WrReq)   tx_data_q <= Bus2IP_Data; 
end
assign tx_data = tx_data_q;

//could be memory mapped, but read-only
//tx_data full register
//set when host writes into TX_DATA register
//Cleared by ps2_sie when finished transmission
FDRE tx_data_fl_reg (
.C  (Clk),
.R  (srst || tx_full_clr),
.CE (tx_data_ce && Bus2IP_WrReq),
.D  (1'b1),
.Q  (tx_full_sta)
);

//------------------------------------------
//RX_DATA
//RX data register and full register
//------------------------------------------

//Written by ps2_sie after receiving a byte packet
//Or Written by Host if it wants (rare)
always @ (posedge Clk)
begin 
  if (Rst)                             rx_data_q <= 0;
  else if (rx_full_set)                rx_data_q <= rx_data; 
  else if (rx_data_ce && Bus2IP_WrReq) rx_data_q <= Bus2IP_Data;

end
         
 
//could be memory mapped, but read-only
//rx_data full register
//set when ps2_sie (host write into RX_DATA register won't change it!)
//cleared by when host reads RX_DATA
FDRE rx_data_fl_reg (
.C  (Clk),
.R  (srst || (rx_data_ce && Bus2IP_RdReq)),
//.CE (rx_full_set || (rx_data_ce && Bus2IP_WrReq)),
.CE (rx_full_set),
.D  (1'b1),
.Q  (rx_full_sta)
);


//------------------------------------------
//Interrupt  Register  (Set and Clear)
//rx_full, rx_err, rx_ovf, tx_ack, tx_noack, wdt_tout
//mask=1 interrupt enabled
//mask=0 interrupt disabled (PowerOn)
//------------------------------------------


FDRE int_rx_full_reg (
.C  (Clk),
.R  (srst || (intc_ce && Bus2IP_WrReq && Bus2IP_Data_rx_full)),
.CE (rx_full_set||(ints_ce && Bus2IP_WrReq && Bus2IP_Data_rx_full)),
.D  (1'b1),
.Q  (int_rx_full_q)
);


FDRE int_rx_err_reg (
.C  (Clk),
.R  (srst || (intc_ce && Bus2IP_WrReq && Bus2IP_Data_rx_err)),
.CE (rx_err_set||(ints_ce && Bus2IP_WrReq && Bus2IP_Data_rx_err)),
.D  (1'b1),
.Q  (int_rx_err_q)
);

FDRE int_rx_ovf_reg (
.C  (Clk),
.R  (srst || (intc_ce && Bus2IP_WrReq && Bus2IP_Data_rx_ovf)),
.CE (rx_ovf_set||(ints_ce && Bus2IP_WrReq && Bus2IP_Data_rx_ovf)),
.D  (1'b1),
.Q  (int_rx_ovf_q)
);


FDRE int_tx_ack_reg (
.C  (Clk),
.R  (srst || (intc_ce && Bus2IP_WrReq && Bus2IP_Data_tx_ack)),
.CE (tx_ack_set||(ints_ce && Bus2IP_WrReq && Bus2IP_Data_tx_ack)),
.D  (1'b1),
.Q  (int_tx_ack_q)
);

FDRE int_tx_noack_reg (
.C  (Clk),
.R  (srst || (intc_ce && Bus2IP_WrReq && Bus2IP_Data_tx_noack)),
.CE (tx_noack_set||(ints_ce && Bus2IP_WrReq && Bus2IP_Data_tx_noack)),
.D  (1'b1),
.Q  (int_tx_noack_q)
);

FDRE int_wdt_tout_reg (
.C  (Clk),
.R  (srst || (intc_ce && Bus2IP_WrReq && Bus2IP_Data_wdt_tout)),
.CE (wdt_tout_set||(ints_ce && Bus2IP_WrReq && Bus2IP_Data_wdt_tout)),
.D  (1'b1),
.Q  (int_wdt_tout_q)
);


//------------------------------------------
//Interrupt Mask Register  (Set and Clear)
//rx_full, rx_err, rx_ovf, tx_ack, tx_noack, wdt_tout
//mask=1 interrupt enabled
//mask=0 interrupt disabled (PowerOn)
//------------------------------------------


FDRE intm_rx_full_reg (
.C  (Clk),
.R  (Rst || (intmc_ce && Bus2IP_WrReq && Bus2IP_Data_rx_full)),
.CE (intms_ce && Bus2IP_WrReq && Bus2IP_Data_rx_full),
.D  (1'b1),
.Q  (intm_rx_full_q)
);


FDRE intm_rx_err_reg (
.C  (Clk),
.R  (Rst || (intmc_ce && Bus2IP_WrReq && Bus2IP_Data_rx_err)),
.CE (intms_ce && Bus2IP_WrReq && Bus2IP_Data_rx_err),
.D  (1'b1),
.Q  (intm_rx_err_q)
);

FDRE intm_rx_ovf_reg (
.C  (Clk),
.R  (Rst || (intmc_ce && Bus2IP_WrReq && Bus2IP_Data_rx_ovf)),
.CE (intms_ce && Bus2IP_WrReq && Bus2IP_Data_rx_ovf),
.D  (1'b1),
.Q  (intm_rx_ovf_q)
);


FDRE intm_tx_ack_reg (
.C  (Clk),
.R  (Rst || (intmc_ce && Bus2IP_WrReq && Bus2IP_Data_tx_ack)),
.CE (intms_ce && Bus2IP_WrReq && Bus2IP_Data_tx_ack),
.D  (1'b1),
.Q  (intm_tx_ack_q)
);

FDRE intm_tx_noack_reg (
.C  (Clk),
.R  (Rst || (intmc_ce && Bus2IP_WrReq && Bus2IP_Data_tx_noack)),
.CE (intms_ce && Bus2IP_WrReq && Bus2IP_Data_tx_noack),
.D  (1'b1),
.Q  (intm_tx_noack_q)
);

FDRE intm_wdt_tout_reg (
.C  (Clk),
.R  (Rst || (intmc_ce && Bus2IP_WrReq && Bus2IP_Data_wdt_tout)),
.CE (intms_ce && Bus2IP_WrReq && Bus2IP_Data_wdt_tout),
.D  (1'b1),
.Q  (intm_wdt_tout_q)
);




//------------------------------------------
//Interrupt signal
//rx_full, rx_err, rx_ovf, tx_ack, tx_noack, wdt_tout
//mask=1 interrupt enabled
//mask=0 interrupt disabled (PowerOn)
//------------------------------------------

assign IP2Bus_Intr =
(int_rx_full_q  &  intm_rx_full_q   ) |
(int_rx_err_q   &  intm_rx_err_q    ) |
(int_rx_ovf_q   &  intm_rx_ovf_q    ) |
(int_tx_ack_q   &  intm_tx_ack_q    ) |
(int_tx_noack_q &  intm_tx_noack_q  ) |
(int_wdt_tout_q &  intm_wdt_tout_q  );


endmodule
