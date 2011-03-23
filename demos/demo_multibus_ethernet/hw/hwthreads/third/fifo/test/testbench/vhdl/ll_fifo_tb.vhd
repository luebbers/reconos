-------------------------------------------------------------------------------
--                                                                           
--  Module      : ll_fifo_tb.vhd 
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--                                                                           
--  Project     : Parameterizable LocalLink FIFO                             
--                                                                           
--  Description : Testbench of LocalLink FIFO
--                                                                           
--  Designer    : Wen Ying Wei, Davy Huang
--                                            
--  Company     : Xilinx, Inc.                
--                                            
--  Disclaimer  : XILINX IS PROVIDING THIS DESIGN, CODE, OR    
--                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
--                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
--                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
--                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
--                APPLICATION OR STANDARD, XILINX IS MAKING NO
--                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
--                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
--                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
--                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
--                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
--                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
--                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
--                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
--                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
--                PURPOSE.
--                
--                (c) Copyright 2005 Xilinx, Inc.
--                All rights reserved.
--                                            
-------------------------------------------------------------------------------
--
--  Testbench Block Diagram:
--
--
--    +---------+        +---------+
--    |         |        |         |
--    |  Tester |  ==>   | Egress  | ====+
--    |   (TX)  |        | LL_FIFO |     | 
--    |         |        |         |  +----------+
--    +---------+        +---------+  |Pipeline/ |
--    +---------+        +---------+  |Throttle  |
--    |         |        |         |  +----------+
--    |  Tester |  <==   | Ingress |     |
--    |   (RX)  |        | LL_FIFO |<====+
--    |         |        |         |
--    +---------+        +---------+
--                  ^                  ^  
--                  |                  |
--             TESTER I/F        LOOPBACK I/F
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.TESTER_pkg.all;
use work.ll_fifo_pkg.all;

entity ll_fifo_tb is
 generic (
        -- Set memory type and depth
        MEM_TYPE                : integer   :=0;      -- Select memory type(0: BRAM, 1: Distributed RAM)
        BRAM_MACRO_NUM          : integer   :=16;      -- Set memory depth if use BRAM
        DRAM_DEPTH              : integer   :=16;      -- Set memory depth if use Distributed RAM
         
        -- Set clock rate, data width at the tester interface
        TESTER_CLK_HALF_PERIOD  : time      :=12.50 ns; -- Set Tester clock speed
        TESTER_DWIDTH           : integer   :=64;     -- Set Tester data width:8, 16, 32, 64, 128
        TESTER_REM_WIDTH        : integer   :=3;      -- Set Tester remainder width:1, 1, 2, 3, 4
        TESTER_REM_VECTOR_WIDTH : integer   :=3;      -- Set rem width in test vector file
                                                      -- Use 3 if TESTER_DWIDTH <= 64
                                                      -- Use 7 if TESTER_DWIDTH = 128
        TESTER_FIFO_DEPTH       : integer   :=8192;   -- Set Tester FIFO depth (FIFO to buffer the traffic data)

        -- Set clock rate, data width at the loopback interface
        LOOPBACK_CLK_HALF_PERIOD: time      :=12.50 ns; -- Set Loopback clock speed
        LOOPBACK_DWIDTH         : integer   :=8;     -- Set Tester data width:8, 16, 32, 64, 128
        LOOPBACK_REM_WIDTH      : integer   :=1;      -- Set Loopback remainder width:1, 1, 2, 3, 4
        
        -- Other LocalLink FIFO options        
        EGRESS_USE_LENGTH       : boolean :=true;     -- Set if use Length Option on Egress FIFO
        INGRESS_USE_LENGTH      : boolean :=true;     -- Set if use Length Option on Ingress FIFO
        
        -- Global timing delay
        glbtm                   : time    :=0.5 ns  );-- Set global timing delay
end ll_fifo_tb;

architecture ll_fifo_tb_arch of ll_fifo_tb is

   signal rst           :  std_logic;        
   signal tester_clk     :  std_logic;        

  -- Loopback Interface signals
   signal loopback_clk      :  std_logic;        
   signal Eloopback_data      :  std_logic_vector(0 to LOOPBACK_DWIDTH-1);  
   signal Eloopback_rem       :  std_logic_vector(0 to LOOPBACK_REM_WIDTH-1);  
   signal Eloopback_sof_n     :  std_logic;
   signal Eloopback_eof_n     :  std_logic;
   signal Eloopback_src_rdy_n :  std_logic;
   signal Eloopback_dst_rdy_n   :  std_logic;         

   signal Iloopback_data      :  std_logic_vector(0 to LOOPBACK_DWIDTH-1);  
   signal Iloopback_rem       :  std_logic_vector(0 to LOOPBACK_REM_WIDTH-1);  
   signal Iloopback_sof_n     :  std_logic;
   signal Iloopback_eof_n     :  std_logic;
   signal Iloopback_src_rdy_n :  std_logic;
   signal Iloopback_dst_rdy_n   :  std_logic;         
   
   signal loopback_throttle_cnt : std_logic_vector(10 downto 0);
   signal loopback_throttle_th  : std_logic_vector(13 downto 0);
   signal loopback_throttle     : std_logic;

   signal Sloopback : std_logic;
   
   -- Tester interface signals
   signal tx_d          :  std_logic_vector(0 to TESTER_DWIDTH-1);
   signal tx_rem        :  std_logic_vector(0 to TESTER_REM_WIDTH-1);
   signal tx_sof_n      :  std_logic;
   signal tx_eof_n      :  std_logic;
   signal tx_src_rdy_n  :  std_logic;
   signal tx_dst_rdy_n  :  std_logic;
   signal tx_dst_rdy_n_i  :  std_logic;

   signal rx_d          :  std_logic_vector(0 to TESTER_DWIDTH-1);
   signal rx_rem        :  std_logic_vector(0 to TESTER_REM_WIDTH-1);
   signal rx_sof_n      :  std_logic;
   signal rx_eof_n      :  std_logic;
   signal rx_src_rdy_n  :  std_logic;

   -- Other LocalLink FIFO signals   
   signal egress_fifostatus :   std_logic_vector(0 to 3);
   signal egress_len_rdy_out:   std_logic;
   signal egress_len_out:       std_logic_vector(15 downto 0);
   signal egress_len_err_out:   std_logic;

   signal ingress_fifostatus :   std_logic_vector(0 to 3);
   signal ingress_len_rdy_out:   std_logic;
   signal ingress_len_out:       std_logic_vector(15 downto 0);
   signal ingress_len_err_out:   std_logic;

   --Reference Signals
   signal src_rdy_n_ref_i   :   std_logic;
                
   -- Tester signals
   signal WORKING:              std_logic;
   signal COMPARING:            std_logic;
   signal OVERFLOW:             std_logic;
   signal RESULT_GOOD:          std_logic;
   signal RESULT_GOOD_PDU:      std_logic;
   signal TV:                   std_logic_vector(0 to 7);
   
   -- Other signals
   signal GND:                  std_logic;
   signal VCC:                  std_logic;

   signal ufc_rx_d      :  std_logic_vector(0 to TESTER_DWIDTH-1);
   signal ufc_rx_rem    :  std_logic_vector(0 to TESTER_REM_WIDTH-1);
   
   

   
 begin
    GND   <= '0';
    VCC   <= '1';
    ufc_rx_d <= (others => '0');
    ufc_rx_rem <= (others => '0');
    
    TV(0) <= not rst; -- first test vector is reset
    TV(1) <= not tx_dst_rdy_n;
    tx_dst_rdy_n <= tx_dst_rdy_n_i when tx_src_rdy_n = '0'
           else '1' when egress_fifostatus >= "0000" and loopback_throttle_th(11 downto 9) = "111" and loopback_throttle_th(4) = '1'
           else tx_dst_rdy_n_i;
            -- second test vector is the destination ready signal 
                               -- from the Egress FIFO to the Tester
    TV(2 to 7) <= (others => '0'); -- other test vectors not used
    
   ---------------------------------------------------------------------------
   -- Instantiate the DUT : Egress FIFO and Ingress FIFO
   ---------------------------------------------------------------------------

   Egress_FIFO: ll_fifo 
   generic map (
        MEM_TYPE             =>      MEM_TYPE,
        BRAM_MACRO_NUM       =>      BRAM_MACRO_NUM,
        DRAM_DEPTH           =>      DRAM_DEPTH,
        WR_DWIDTH            =>      TESTER_DWIDTH,
        WR_REM_WIDTH         =>      TESTER_REM_WIDTH,
        RD_DWIDTH            =>      LOOPBACK_DWIDTH,
        RD_REM_WIDTH         =>      LOOPBACK_REM_WIDTH,
        USE_LENGTH           =>      EGRESS_USE_LENGTH,
        glbtm                =>      glbtm )
   port map (
        -- Reset
         areset_in           =>      rst,
         
        -- clocks
         write_clock_in      =>      tester_clk,
         read_clock_in       =>      loopback_clk,
         
        -- Tester Interface
         data_in             =>      tx_d,   
         rem_in              =>      tx_rem,
         sof_in_n            =>      tx_sof_n,
         eof_in_n            =>      tx_eof_n,
         src_rdy_in_n        =>      tx_src_rdy_n, 
         dst_rdy_out_n       =>      tx_dst_rdy_n_i, 

        -- Loopback Interface
         data_out            =>      Eloopback_data,
         rem_out             =>      Eloopback_rem,
         sof_out_n           =>      Eloopback_sof_n,
         eof_out_n           =>      Eloopback_eof_n,
         src_rdy_out_n       =>      Eloopback_src_rdy_n,  
         dst_rdy_in_n        =>      Eloopback_dst_rdy_n,  
      
        -- FIFO status signals
         fifostatus_out      =>      egress_fifostatus,
         
        -- Length Status
         len_rdy_out         =>      egress_len_rdy_out,
         len_out             =>      egress_len_out,
         len_err_out         =>      egress_len_err_out);
        
   Ingress_FIFO: ll_fifo 
   generic map (
        MEM_TYPE             =>      MEM_TYPE,
        BRAM_MACRO_NUM       =>      BRAM_MACRO_NUM,
        DRAM_DEPTH           =>      DRAM_DEPTH,
        WR_DWIDTH            =>      LOOPBACK_DWIDTH,
        WR_REM_WIDTH         =>      LOOPBACK_REM_WIDTH,
        RD_DWIDTH            =>      TESTER_DWIDTH,
        RD_REM_WIDTH         =>      TESTER_REM_WIDTH,
        USE_LENGTH           =>      INGRESS_USE_LENGTH,
        glbtm                =>      glbtm )
   port map (
        -- Reset
         areset_in           =>      rst,
         
        -- clocks
         write_clock_in      =>      loopback_clk,
         read_clock_in       =>      tester_clk,
         
        -- Loopback Interface
         data_in             =>      Iloopback_data,       
         rem_in              =>      Iloopback_rem,        
         sof_in_n            =>      Iloopback_sof_n,
         eof_in_n            =>      Iloopback_eof_n,
         src_rdy_in_n        =>      Iloopback_src_rdy_n,
         dst_rdy_out_n       =>      Iloopback_dst_rdy_n,

        -- Tester Interface
         data_out            =>      rx_d,
         rem_out             =>      rx_rem,
         sof_out_n           =>      rx_sof_n,
         eof_out_n           =>      rx_eof_n,
         src_rdy_out_n       =>      rx_src_rdy_n,  
         dst_rdy_in_n        =>      GND,   -- Tester always ready to accept data
      
        -- FIFO status signals
         fifostatus_out      =>      ingress_fifostatus,
         
        -- Length Status
         len_rdy_out         =>      ingress_len_rdy_out,
         len_out             =>      ingress_len_out,
         len_err_out         =>      ingress_len_err_out);


    ---------------------------------------------------------------------------
    -- Loopback I/F
    ---------------------------------------------------------------------------
   
    loopback_throttle_cnt_proc: process (rst, loopback_clk)
      begin
       if rst = '1'  then
         loopback_throttle_cnt <= (others => '0') after glbtm;
       elsif loopback_clk'event and loopback_clk = '1' then
         if loopback_throttle_cnt = loopback_throttle_th(13 downto 3) then
           loopback_throttle_cnt <= (others => '0') after glbtm;
         else
           loopback_throttle_cnt <= loopback_throttle_cnt + 1 after glbtm;
         end if;
       end if;
    end process;
    
    loopback_throttle_proc : process (rst, loopback_clk)
      begin
       if rst = '1' then
         loopback_throttle <= '0' after glbtm;
         loopback_throttle_th  <= "00011000000000" after glbtm;

       elsif loopback_clk'event and loopback_clk = '1' then
         if loopback_throttle_cnt = loopback_throttle_th(13 downto 3) then
           loopback_throttle <= not loopback_throttle after glbtm;
         end if;

         if loopback_throttle_cnt = loopback_throttle_th(13 downto 3) and loopback_throttle = '0' then
           loopback_throttle_th <= loopback_throttle_th - 73 after glbtm;

         end if;

       end if;
    end process;
    
    loopback_if_proc: process (rst, loopback_clk)
      begin
       if rst = '1' then
          Iloopback_data      <=      (others => '0') after glbtm;
          Iloopback_rem       <=      (others => '0') after glbtm;
          Iloopback_sof_n     <=      '1' after glbtm;
          Iloopback_eof_n     <=      '1' after glbtm;
          Iloopback_src_rdy_n <=      '1'  after glbtm;
          Eloopback_dst_rdy_n <=      '1' after glbtm;
          Sloopback           <=      '0' after glbtm;
       elsif loopback_clk'event and loopback_clk = '1' then

         if Iloopback_dst_rdy_n = '1' and Sloopback = '1' then -- Ingress FIFO not ready, storage is occupied
          -- latch the data, do nothing else
         else
          Iloopback_data      <=      Eloopback_data after glbtm;
          Iloopback_rem       <=      Eloopback_rem after glbtm;
          Iloopback_sof_n     <=      Eloopback_sof_n after glbtm;
          Iloopback_eof_n     <=      Eloopback_eof_n after glbtm;
          Iloopback_src_rdy_n <=      Eloopback_src_rdy_n or Eloopback_dst_rdy_n after glbtm;
          Sloopback           <=      not (Eloopback_src_rdy_n or Eloopback_dst_rdy_n) after glbtm;
         end if; 

         if loopback_throttle = '0' then
          Eloopback_dst_rdy_n <=      Iloopback_dst_rdy_n or Sloopback after glbtm; -- hold off Egress FIFO when
                                             -- there's data in the storage.
         else
          Eloopback_dst_rdy_n <=      '1' after glbtm;
         end if;
       end if;
    end process;
   
             
    ---------------------------------------------------------------------------
    -- Instantiate the Tester TX: FILEREAD_TESTER
    ---------------------------------------------------------------------------
    src_rdy_n_ref_i <= not (not tx_src_rdy_n and not tx_dst_rdy_n);

    fileread_tester_i: FILEREAD_TESTER 
    generic map
      ( GLOBALDLY        => 1,
        TV_WIDTH         => 8,
        CV_WIDTH         => 4,
        LL_DAT_BIT_WIDTH => TESTER_DWIDTH,   
        LL_REM_BIT_WIDTH => TESTER_REM_WIDTH,
        REM_VECTOR_WIDTH => TESTER_REM_VECTOR_WIDTH)
    port map  
    (   
        --Global Signals
        CLK => tester_clk,
        TV  => TV,
      
        --LocalLink Interface
        TX_SOF_N => tx_sof_n,                            --O
        TX_EOF_N => tx_eof_n,                            --O
        TX_D     => tx_d,                                --O
        TX_REM   => tx_rem,                              --O
        TX_SRC_RDY_N => tx_src_rdy_n,                    --O
         
        --Native Flow Control Interface (Not used)
        NFC_NB   => open,                                --O
        NFC_REQ_N => open,                               --O
         
        --User Flow Control Interface (Not used)
        UFC_TX_REQ_N => open,                            --O
        UFC_TX_MS => open,                               --O
        
        --Other User Signals    
        CTRL => open
    );
  
  
    ---------------------------------------------------------------------------
    -- Instantiate the Tester RX: OUTPUT_TESTER
    ---------------------------------------------------------------------------
    err_det_proc: process (rst, tester_clk)
      begin
       if rst = '1' then
    
       elsif tester_clk'event and tester_clk = '1' then
            assert (RESULT_GOOD = '1' or OVERFLOW = '1' )
                report "ERROR DETECTED!"  severity Error;
            assert (OVERFLOW = '0')
                report "TESTER OVERFLOW DETECTED!"  severity Error;
       end if;
    end process;
    
    
    
   DW_Sel_gen1: if TESTER_DWIDTH > 8 generate    

    output_tester_i: OUTPUT_TESTER 
    generic map
    ( GLOBALDLY => 1,
      LL_DAT_BIT_WIDTH => TESTER_DWIDTH,  
      LL_REM_BIT_WIDTH => TESTER_REM_WIDTH,
      FIFO_DEPTH       => TESTER_FIFO_DEPTH)
    port map    
    (
        CLK => tester_clk,                               --I  
        RST => rst,                                      --I                
      
      
        --Dut LocalLink Interface
        RX_D => rx_d,                                    --I  --0:63
        RX_REM => rx_rem,                                --I  --0:2
        RX_SOF_N => rx_sof_n,                            --I
        RX_EOF_N => rx_eof_n,                            --I
        RX_SRC_RDY_N => rx_src_rdy_n,                    --I
      
      
        --Dut UFC Interface (not used)
        UFC_RX_DATA => ufc_rx_d,                         --I            
        UFC_RX_REM  => ufc_rx_rem,                       --I              
        UFC_RX_SOF_N => VCC,                             --I
        UFC_RX_EOF_N => VCC,                             --I
        UFC_RX_SRC_RDY_N => VCC,                         --I
      
      
        --Reference LocalLink Interface 
        RX_SOF_N_REF => tx_sof_n,                        --I
        RX_EOF_N_REF => tx_eof_n,                        --I
        RX_REM_REF => tx_rem,                            --I
        RX_DATA_REF => tx_d,                             --I
        RX_SRC_RDY_N_REF => src_rdy_n_ref_i,             --I
      
      
        --Reference UFC Interface (not used)
        UFC_RX_DATA_REF => ufc_rx_d,                     --I          
        UFC_RX_REM_REF => ufc_rx_rem,                    --I          
        UFC_RX_SOF_N_REF => VCC,                         --I
        UFC_RX_EOF_N_REF => VCC,                         --I
        UFC_RX_SRC_RDY_N_REF => VCC,                     --I 
      
  
        --Comparison result
        WORKING => WORKING,                              --O
        COMPARING => COMPARING,
        OVERFLOW  => OVERFLOW,
        RESULT_GOOD => RESULT_GOOD,                      --O
        RESULT_GOOD_PDU => RESULT_GOOD_PDU,              --O
        RESULT_GOOD_UFC => open                          --O
    );
  end generate DW_Sel_gen1;

  DW_Sel_gen2: if TESTER_DWIDTH = 8 generate    
    output_tester_i: OUTPUT_TESTER_8_BIT
    generic map
    ( GLOBALDLY => 1,
      LL_DAT_BIT_WIDTH => TESTER_DWIDTH,  
      LL_REM_BIT_WIDTH => 0,
      FIFO_DEPTH       => TESTER_FIFO_DEPTH)
    port map    
    (
        CLK => tester_clk,                               --I  
        RST => rst,                                      --I                
      
      
        --Dut LocalLink Interface
        RX_D => rx_d,                                    --I  --0:63
        RX_REM => rx_rem(0),                             --I  --0:2
        RX_SOF_N => rx_sof_n,                            --I
        RX_EOF_N => rx_eof_n,                            --I
        RX_SRC_RDY_N => rx_src_rdy_n,                    --I
      
      
        --Dut UFC Interface (to tie)
        UFC_RX_DATA => ufc_rx_d,                         --I            
        UFC_RX_REM  => ufc_rx_rem(0),                    --I              
        UFC_RX_SOF_N => VCC,                             --I
        UFC_RX_EOF_N => VCC,                             --I
        UFC_RX_SRC_RDY_N => VCC,                         --I
      
      
        --Reference LocalLink Interface (don't touch)
        RX_SOF_N_REF => tx_sof_n,                        --I
        RX_EOF_N_REF => tx_eof_n,                        --I
        RX_REM_REF => tx_rem(0),                         --I
        RX_DATA_REF => tx_d,                             --I
        RX_SRC_RDY_N_REF => src_rdy_n_ref_i,             --I
      
      
        --Reference UFC Interface (to tie)
        UFC_RX_DATA_REF => ufc_rx_d,                     --I          
        UFC_RX_REM_REF => ufc_rx_rem(0),                 --I          
        UFC_RX_SOF_N_REF => VCC,                         --I
        UFC_RX_EOF_N_REF => VCC,                         --I
        UFC_RX_SRC_RDY_N_REF => VCC,                     --I
      
  
        --Comparison result
        WORKING => WORKING,                              --O
        COMPARING => COMPARING,
        OVERFLOW  => OVERFLOW,
        RESULT_GOOD => RESULT_GOOD,                      --O
        RESULT_GOOD_PDU => RESULT_GOOD_PDU,              --O
        RESULT_GOOD_UFC => open                          --O
    );
  end generate DW_Sel_gen2;
  
    ---------------------------------------------------------------------------
    -- Generate Tester clock and Loopback clock
    ---------------------------------------------------------------------------
   
    loopback_clkgen: process                    
    begin
        loopback_clk <= '0';
        wait for LOOPBACK_CLK_HALF_PERIOD;                                  
        loopback_clk <= '1';
        wait for LOOPBACK_CLK_HALF_PERIOD;                                 
    end process loopback_clkgen;

    tester_clkgen: process  
    begin
        tester_clk <= '0';
        wait for TESTER_CLK_HALF_PERIOD;
        tester_clk <= '1';
        wait for TESTER_CLK_HALF_PERIOD;
    end process tester_clkgen;

    ---------------------------------------------------------------------------
    -- Generate Global Reset
    ---------------------------------------------------------------------------

    reset_gen : process
    begin
        rst <= '1';
        wait for 55 ns;
        rst <= '0';
        wait; -- will wait forever
    end process reset_gen;
 
   

END ll_fifo_tb_arch;