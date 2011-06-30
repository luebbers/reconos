---------------------------------------------------------------------------
--                                                                       
--  Module      : DRAM_macro.vhd        
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--    
--  Project     : Parameterizable LocalLink FIFO
--
--  Description : Distributed RAM Macro 
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
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_bit.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.fifo_u.all;
use work.DRAM_fifo_pkg.all;

entity DRAM_macro is

   generic (
        DRAM_DEPTH      : integer := 16;    -- FIFO depth, default is 16,
                                            -- allowable values are 16, 32, 
                                             -- 64, 128.
   
        WR_DWIDTH       :       integer := 32;    --FIFO write data width. 
                                                  --Allowed: 8, 16, 32, 64
        RD_DWIDTH       :       integer := 32;    --FIFO read data width.
                                                  --Allowed: 8, 16, 32, 64
        WR_REM_WIDTH    :       integer := 2;     --log2(WR_DWIDTH/8)
        RD_REM_WIDTH    :       integer := 2;     --log2(RD_DWIDTH/8)
        
        RD_ADDR_MINOR_WIDTH :   integer := 1;
        RD_ADDR_WIDTH   :       integer := 9;
        
        WR_ADDR_MINOR_WIDTH  :  integer := 1;
        WR_ADDR_WIDTH   :       integer := 9;
        
        CTRL_WIDTH:             integer := 3;

        glbtm           :       time := 1 ns );
        
   port (
         -- Reset
         fifo_gsr:           in  std_logic;
          
         -- clocks
         wr_clk:             in  std_logic;
         rd_clk:             in  std_logic;
                  
         rd_allow:           in  std_logic;
         rd_allow_minor:     in  std_logic;
         rd_addr:            in  std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
         rd_addr_minor:      in  std_logic_vector(RD_ADDR_MINOR_WIDTH-1 downto 0);
         rd_data:            out std_logic_vector(RD_DWIDTH -1 downto 0);
         rd_rem:             out std_logic_vector(RD_REM_WIDTH-1 downto 0);
         rd_sof_n:           out std_logic;
         rd_eof_n:           out std_logic;
         
                  
         wr_allow:           in  std_logic;
         wr_allow_minor:     in  std_logic;
         wr_allow_minor_p:   in  std_logic;         
         wr_addr:            in  std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
         wr_addr_minor:      in  std_logic_vector(WR_ADDR_MINOR_WIDTH-1 downto 0);
         wr_data:            in  std_logic_vector(WR_DWIDTH-1 downto 0);
         wr_rem:             in  std_logic_vector(WR_REM_WIDTH-1 downto 0);
         wr_sof_n:           in  std_logic;
         wr_eof_n:           in  std_logic;
         wr_sof_n_p:         in  std_logic;
         wr_eof_n_p:         in  std_logic;
         ctrl_wr_buf:        out std_logic_vector(CTRL_WIDTH-1 downto 0)
         );
         
end DRAM_macro;


architecture DRAM_macro_hdl of DRAM_macro is

-- Constants Related to FIFO Width parameters for Data
constant MEM_IDX : integer := SQUARE2(DRAM_DEPTH);
constant MAX_WIDTH: integer := GET_MAX_WIDTH(RD_DWIDTH, WR_DWIDTH);
constant WRDW_div_RDDW: integer := GET_WRDW_div_RDDW(RD_DWIDTH, WR_DWIDTH);

--Constants Related to FIFO Width parameters for Control
constant REM_SEL_HIGH_VALUE : integer := GET_HIGH_VALUE(RD_REM_WIDTH,WR_REM_WIDTH);  
type rd_data_vec_type is array(0 to 2**RD_ADDR_MINOR_WIDTH-1) of std_logic_vector(RD_DWIDTH-1 downto 0);
type rd_rem_vec_type is array(0 to 2**RD_ADDR_MINOR_WIDTH-1) of std_logic_vector(RD_REM_WIDTH-1 downto 0);
constant RD_MINOR_HIGH : integer := POWER2(RD_ADDR_MINOR_WIDTH);
constant REM_SEL_HIGH1 : integer := POWER2(REM_SEL_HIGH_VALUE);
constant WR_MINOR_HIGH : integer := POWER2(WR_ADDR_MINOR_WIDTH);
constant LEN_IFACE_SIZE: integer := 16;         -- Length count is a std_logic_vec
                                        -- of 16 bits by default.       
                                        -- User may change size. 

 constant LEN_COUNT_SIZE: integer := 14;

    -- length control constants
    constant LEN_BYTE_RATIO: integer := WR_DWIDTH/8;

    signal rd_en:               std_logic;
    signal wr_en:               std_logic;
    -- Control RAM signals --
    signal rd_rem_p:            rd_rem_vec_type;
    signal rd_sof_n_p:          std_logic_vector(RD_MINOR_HIGH-1 downto 0);
    signal rd_eof_n_p:          std_logic_vector(RD_MINOR_HIGH-1 downto 0);
    signal ctrl_rd_buf:         std_logic_vector(CTRL_WIDTH-1 downto 0);
    signal ctrl_wr_buf_i:       std_logic_vector(CTRL_WIDTH-1 downto 0);
    signal ctrl_rd_temp:        std_logic_vector(CTRL_WIDTH-1 downto 0);
    signal ctrl_rd_buf_p:       std_logic_vector((RD_REM_WIDTH+2)*(WRDW_div_RDDW)-1 downto 0);
    -------------------------

    --  Temp signals  --
    signal rd_temp:             std_logic_vector(MAX_WIDTH-1 downto 0);
    signal rd_buf:              std_logic_vector(MAX_WIDTH-1 downto 0);
    signal rd_data_p:           rd_data_vec_type;
    signal wr_buf:              std_logic_vector(MAX_WIDTH-1 downto 0);
    signal min_addr1:           integer := 0;
    signal min_addr2:           integer := 0;
    signal rem_sel1 :           integer := 0;
    signal rem_sel2:            integer := 0;

    signal gnd:                 std_logic;
    signal pwr:                 std_logic;
    

 begin


----------------------------------------------------------------------------------
-- SOF, EOF, REM mapping
----------------------------------------------------------------------------------
   
   
rd_switch_gen1: if (WR_DWIDTH > RD_DWIDTH) generate
    min_addr1 <= slv2int(rd_addr_minor);
   
    -- Data mapping --
    rd_gen: for i in 0 to RD_MINOR_HIGH-1 generate 
        rd_data_p(i) <= rd_buf(i * RD_DWIDTH + RD_DWIDTH - 1 downto i * RD_DWIDTH);  
        rd_rem_p(i) <= ctrl_rd_buf_p(i*(2+RD_REM_WIDTH) + RD_REM_WIDTH-1 downto i*(2+RD_REM_WIDTH));
        rd_sof_n_p(i) <= ctrl_rd_buf_p(i*(2+RD_REM_WIDTH) + RD_REM_WIDTH);
        rd_eof_n_p(i) <= ctrl_rd_buf_p(i*(2+RD_REM_WIDTH) + RD_REM_WIDTH+1);   
    end generate rd_gen;

    ctrl_gen1a: if RD_DWIDTH /= 8 generate                        -- if read data width is 8 then there is no rem signal
        -- SOF mapping
        ctrl_rd_buf_p(RD_REM_WIDTH) <= '0' when ctrl_rd_buf(WR_REM_WIDTH) = '0' else '1';            
        sof_gen_for: for k in 1 to REM_SEL_HIGH1-1 generate
            ctrl_rd_buf_p(k*(2+RD_REM_WIDTH)+RD_REM_WIDTH) <= '1';            
        end generate sof_gen_for;

        rem_sel1 <= slv2int(ctrl_rd_buf(WR_REM_WIDTH-1 downto RD_REM_WIDTH));
        ctrl_gen1b: if RD_DWIDTH = 16 generate
            -- REM mapping
            rem_gen_for1: for i in 0 to REM_SEL_HIGH1-1 generate
                ctrl_rd_buf_p(i*(2+RD_REM_WIDTH)) <= ctrl_rd_buf(0) when rem_sel1 = i else '0';  --rem
            end generate rem_gen_for1;
  
            -- EOF mapping
            eof_gen_for1: for j in 0 to REM_SEL_HIGH1-1 generate
                ctrl_rd_buf_p(j*(2+RD_REM_WIDTH)+2) <= ctrl_rd_buf(WR_REM_WIDTH +1) when rem_sel1 = j else '1'; 
            end generate eof_gen_for1;
        end generate ctrl_gen1b;

        rem_gen1c: if RD_DWIDTH > 16 generate
            -- REM mapping
            rem_gen_for2: for i in 0 to REM_SEL_HIGH1-1 generate
                ctrl_rd_buf_p(i*(2+RD_REM_WIDTH)+RD_REM_WIDTH-1 downto i*(2+RD_REM_WIDTH)) <= ctrl_rd_buf(RD_REM_WIDTH-1 downto 0) when 
                rem_sel1 = i else (others => 'X') ; 
            end generate rem_gen_for2;
         
            -- EOF mapping
            eof_gen_for2: for j in 0 to REM_SEL_HIGH1-1 generate
                ctrl_rd_buf_p(j*(2+RD_REM_WIDTH)+RD_REM_WIDTH+1) <= ctrl_rd_buf(WR_REM_WIDTH+1) when rem_sel1 = j else '1';
            end generate eof_gen_for2;         
        end generate rem_gen1c;
    end generate ctrl_gen1a;
   
    ctrl_gen1b: if RD_DWIDTH = 8 generate
        -- SOF mapping
        ctrl_rd_buf_p(RD_REM_WIDTH) <= '0' when ctrl_rd_buf(WR_REM_WIDTH) = '0' else '1';            
        sof_gen_for: for k in 1 to WR_DWIDTH/RD_DWIDTH-1 generate
            ctrl_rd_buf_p(k*(2+RD_REM_WIDTH)+RD_REM_WIDTH) <= '1';            
        end generate sof_gen_for;

        rem_sel2 <= slv2int(ctrl_rd_buf(WR_REM_WIDTH-1 downto 0));
      
        eof_gen_for2: for k in 0 to WR_DWIDTH/RD_DWIDTH-1 generate
            ctrl_rd_buf_p(k*(2+RD_REM_WIDTH)+2) <= ctrl_rd_buf(WR_REM_WIDTH+1) when rem_sel2 = k else '1';
        end generate eof_gen_for2;  
    end generate ctrl_gen1b;

    rd_rem_gen0: if RD_DWIDTH = 8 generate
            rd_process1: process (rd_clk, fifo_gsr)
            begin
                rd_rem <= (others => '0');
                
                if (fifo_gsr = '1') then
                    rd_data <= (others => '0');
                    rd_sof_n <= '1'; 
                    rd_eof_n <= '1';
                elsif rd_clk'EVENT and rd_clk = '1' then
                   if rd_allow_minor = '1' then
                    rd_data <= rd_data_p(min_addr1) after glbtm;   
                    rd_sof_n <= rd_sof_n_p(min_addr1) after glbtm;
                    rd_eof_n <= rd_eof_n_p(min_addr1) after glbtm;
                   end if;
                end if;
            end process rd_process1;
    end generate;
    
    rd_rem_gen1: if RD_DWIDTH /= 8 generate
            rd_process1: process (rd_clk, fifo_gsr)
            begin
                if (fifo_gsr = '1') then
                    rd_data <= (others => '0');
                    rd_rem <= (others => '0');
                    rd_sof_n <= '1'; 
                    rd_eof_n <= '1';
                elsif rd_clk'EVENT and rd_clk = '1' then
                   if rd_allow_minor = '1' then
                    rd_data <= rd_data_p(min_addr1) after glbtm;   
                    rd_rem <= rd_rem_p(min_addr1) after glbtm;
                    rd_sof_n <= rd_sof_n_p(min_addr1) after glbtm;
                    rd_eof_n <= rd_eof_n_p(min_addr1) after glbtm;
                   end if;
                end if;
            end process rd_process1;
    end generate;
    
    
end generate rd_switch_gen1;

rd_switch_gen2:  if (WR_DWIDTH <= RD_DWIDTH) generate
  rd_rem_gen0: if RD_DWIDTH = 8 generate
    rd_process2: process (rd_clk, fifo_gsr)
    begin
        rd_rem <= (others => '0');
        
        if (fifo_gsr = '1') then
            rd_data <= (others => '0');
            rd_sof_n <= '1'; 
            rd_eof_n <= '1';
        elsif rd_clk'EVENT and rd_clk = '1' then
           if rd_allow = '1' then
            rd_data <= rd_buf after glbtm;  
            rd_sof_n <= ctrl_rd_buf(RD_REM_WIDTH) after glbtm;
            rd_eof_n <= ctrl_rd_buf(RD_REM_WIDTH+1) after glbtm;
           end if;
        end if;
    end process rd_process2;    
  end generate;
  
  rd_rem_gen1: if RD_DWIDTH /= 8 generate
    rd_process2: process (rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            rd_data <= (others => '0');
            rd_rem <= (others => '0');
            rd_sof_n <= '1'; 
            rd_eof_n <= '1';
        elsif rd_clk'EVENT and rd_clk = '1' then
           if rd_allow = '1' then
            rd_data <= rd_buf after glbtm;  
            rd_rem <= ctrl_rd_buf(RD_REM_WIDTH-1 downto 0) after glbtm;
            rd_sof_n <= ctrl_rd_buf(RD_REM_WIDTH) after glbtm;
            rd_eof_n <= ctrl_rd_buf(RD_REM_WIDTH+1) after glbtm;
           end if;
        end if;
    end process rd_process2;    
   end generate;
    
end generate rd_switch_gen2;
 
-------------------------------------------------------------------------------
-- The write format is as follows: for WR_DWIDTH <= RD_DWIDTH
-- wr_data_1 + wr_data_2 + ... + wr_data_n  --> wr_buf --> DRAM
-- wr_buf:
--
-- MSB                                    LSB
--  ___________      ___________ __________
-- | wr_data_n |--- | wr_data_2 |wr_data_1 |
--  -----------      ----------- ----------
--
-- wr_sof_n + wr_eof_n + wr_rem --> ctrl_wr_buf_i --> DRAM
-- ctrl_wr_buf_i:
--
-- MSB                 LSB
--  _______ _______ _____
-- | eof_n | sof_n | rem |
--  ------- ------- ----- 
-------------------------------------------------------------------------------
wr_switch_gen1: if WR_DWIDTH < RD_DWIDTH generate 
    min_addr2 <= slv2int(wr_addr_minor);
    data_proc: process (wr_clk, fifo_gsr)
    begin
        if fifo_gsr = '1' then
            wr_buf <= (others => '0');
            ctrl_wr_buf_i <= (others => '0');
        elsif wr_clk'EVENT and wr_clk = '1' then
            if wr_allow_minor = '1' then
                wr_buf(min_addr2 * WR_DWIDTH + WR_DWIDTH -1 downto min_addr2 * WR_DWIDTH) <= wr_data after glbtm;
            
                -- SOF
                if min_addr2 = 0 then
                    ctrl_wr_buf_i(RD_REM_WIDTH) <= wr_sof_n after glbtm;
                end if;
            
                -- EOF
                ctrl_wr_buf_i(RD_REM_WIDTH+1) <= wr_eof_n after glbtm; 
    
                -- REM
                if wr_eof_n = '0' then
                    if WR_DWIDTH = 8 then
                        ctrl_wr_buf_i(RD_REM_WIDTH-1 downto 0) <= wr_addr_minor  after glbtm;
                    else
                        ctrl_wr_buf_i(RD_REM_WIDTH-1 downto 0) <= wr_addr_minor & wr_rem after glbtm;
                    end if;
                end if;
            end if;
        end if;
    end process data_proc;
        
end generate wr_switch_gen1;
      
wr_switch_gen2:if (WR_DWIDTH >= RD_DWIDTH) generate
    wr_buf <= wr_data;
    ctrl_wr_buf_i(WR_REM_WIDTH-1 downto 0) <= wr_rem;
    ctrl_wr_buf_i(WR_REM_WIDTH) <= wr_sof_n;
    ctrl_wr_buf_i(WR_REM_WIDTH + 1) <= wr_eof_n;
end generate wr_switch_gen2;

ctrl_wr_buf <= ctrl_wr_buf_i;

-------------------------------------------------------------------------------
----------------------Distributed SelectRAM port mapping-----------------------  
--  It uses up to 512 deep RAM, in which 64 and lower are horizontally       --
--  cascaded primitives and 128 and up are macro of 64 deep RAM.             --
-------------------------------------------------------------------------------

DRAMgen1: if DRAM_DEPTH = 16 generate
begin
    gen11: if WR_DWIDTH > RD_DWIDTH generate   
        -- Data RAM --
        DRAM11gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM16X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),     
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM11gen;
         
         -- LL Control RAM --
        DRAM11agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM16X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),     
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM11agen;        
    end generate gen11;
   
    gen12: if WR_DWIDTH < RD_DWIDTH generate
        -- Data RAM --
        DRAM12gen: for i in 0 to RD_DWIDTH-1 generate
            D_RAM1: RAM16X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM12gen;
      
        -- Control RAM --
        DRAM12agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM16X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM12agen;   
    end generate gen12;
   
    gen13: if WR_DWIDTH = RD_DWIDTH generate   
        -- Data RAM --
        DRAM13gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM16X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),     
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM13gen;
    
        -- Control RAM --
        DRAM13agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM16X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),     
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM13agen;            
    end generate gen13;   

end generate DRAMgen1;

DRAMgen2: if DRAM_DEPTH = 32 generate
begin
    gen21: if WR_DWIDTH > RD_DWIDTH generate
        -- Data RAM --
        DRAM21gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM32X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM21gen;
      
        -- Control RAM --
        DRAM21agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM32X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM21agen;
    end generate gen21;
   
    gen22: if WR_DWIDTH < RD_DWIDTH generate
        -- Data RAM --
        DRAM22gen: for i in 0 to RD_DWIDTH-1 generate
            D_RAM1: RAM32X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM22gen;
      
        -- Controal FIFO --
        DRAM22agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM32X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM22agen;
    end generate gen22;
   
    gen23: if WR_DWIDTH = RD_DWIDTH generate   
        -- Data RAM --
        DRAM23gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM32X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),  
                DPRA4   =>      rd_addr(4),
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM23gen;
      
        -- Control RAM --
        DRAM23agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM32X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),  
                DPRA4   =>      rd_addr(4),
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM23agen;
    end generate gen23;
         
end generate DRAMgen2;

DRAMgen3: if DRAM_DEPTH = 64 generate
begin
    gen31: if WR_DWIDTH > RD_DWIDTH generate
        -- Data RAM --
        DRAM31gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM64X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                A5      =>      wr_addr(5),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPRA5   =>      rd_addr(5),
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM31gen;
      
        -- Control RAM --
        DRAM31agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM64X1D port map (
                D       =>      ctrl_wr_buf_i(i), 
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                A5      =>      wr_addr(5),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPRA5   =>      rd_addr(5),
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM31agen;
    end generate gen31;

    gen32: if WR_DWIDTH < RD_DWIDTH generate  
        -- Data RAM --
        DRAM32gen: for i in 0 to RD_DWIDTH-1 generate
            D_RAM1: RAM64X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                A5      =>      wr_addr(5),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPRA5   =>      rd_addr(5),
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM32gen;
      
        -- Control RAM --
        DRAM32agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM64X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                A5      =>      wr_addr(5),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),
                DPRA4   =>      rd_addr(4),
                DPRA5   =>      rd_addr(5),
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM32agen;
    end generate gen32; 
   
    gen33: if WR_DWIDTH = RD_DWIDTH generate   
        -- Data RAM --
        DRAM33gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM64X1D port map (
                D       =>      wr_buf(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                A5      =>      wr_addr(5),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),  
                DPRA4   =>      rd_addr(4),
                DPRA5   =>      rd_addr(5),
                DPO     =>      rd_buf(i),
                SPO     =>      rd_temp(i));
        end generate DRAM33gen;
      
        -- Control RAM --
        DRAM33agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM64X1D port map (
                D       =>      ctrl_wr_buf_i(i),
                WE      =>      wr_allow,
                WCLK    =>      wr_clk,
                A0      =>      wr_addr(0),
                A1      =>      wr_addr(1),
                A2      =>      wr_addr(2),
                A3      =>      wr_addr(3),
                A4      =>      wr_addr(4),
                A5      =>      wr_addr(5),
                DPRA0   =>      rd_addr(0),
                DPRA1   =>      rd_addr(1),
                DPRA2   =>      rd_addr(2),
                DPRA3   =>      rd_addr(3),  
                DPRA4   =>      rd_addr(4),
                DPRA5   =>      rd_addr(5),
                DPO     =>      ctrl_rd_buf(i),
                SPO     =>      ctrl_rd_temp(i));
        end generate DRAM33agen;
    end generate gen33;

end generate DRAMgen3;

DRAMgen4: if DRAM_DEPTH = 128 generate
begin
    gen41: if WR_DWIDTH > RD_DWIDTH generate
        -- Data RAM --
        DRAM41gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(2, 7)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(6 downto 0),
                DRA     =>      rd_addr(6 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
            end generate DRAM41gen;
      
        -- Control RAM --
        DRAM41agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(2, 7)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(6 downto 0),
                DRA     =>      rd_addr(6 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM41agen;
    end generate gen41;
   
    gen42: if WR_DWIDTH < RD_DWIDTH generate  
        -- Data RAM --
        DRAM42gen: for i in 0 to RD_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(2, 7)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(6 downto 0),
                DRA     =>      rd_addr(6 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM42gen;
      
        -- Control RAM --
        DRAM42agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(2, 7)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(6 downto 0),
                DRA     =>      rd_addr(6 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM42agen;
    end generate gen42;
   
    gen43: if WR_DWIDTH = RD_DWIDTH generate   
        -- Data RAM --
        DRAM43gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(2, 7)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(6 downto 0),
                DRA     =>      rd_addr(6 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM43gen;
     
        -- Control RAM --
        DRAM43agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(2, 7)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(6 downto 0),
                DRA     =>      rd_addr(6 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM43agen;
    end generate gen43; 
end generate DRAMgen4;

DRAMgen5: if DRAM_DEPTH = 256 generate
begin
    gen51: if WR_DWIDTH > RD_DWIDTH generate
        -- Data RAM --
        DRAM51gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(4, 8)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(7 downto 0),
                DRA     =>      rd_addr(7 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM51gen;
      
        -- Control RAM --
        DRAM51agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(4, 8)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(7 downto 0),
                DRA     =>      rd_addr(7 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM51agen;
    end generate gen51;
   
    gen52: if WR_DWIDTH < RD_DWIDTH generate  
        -- Data RAM --
        DRAM52gen: for i in 0 to RD_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(4, 8)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(7 downto 0),
                DRA     =>      rd_addr(7 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM52gen;
      
        -- Control RAM --
        DRAM52agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(4, 8)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(7 downto 0),
                DRA     =>      rd_addr(7 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM52agen;
    end generate gen52; 

    gen53: if WR_DWIDTH = RD_DWIDTH generate   
        -- Data RAM --
        DRAM53gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(4, 8)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(7 downto 0),
                DRA     =>      rd_addr(7 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM53gen;
      
        -- Control RAM --
        DRAM53agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(4, 8)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(7 downto 0),
                DRA     =>      rd_addr(7 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM53agen;
    end generate gen53; 
    
end generate DRAMgen5;

DRAMgen6: if DRAM_DEPTH = 512 generate
begin
    gen61: if WR_DWIDTH > RD_DWIDTH generate
        -- Data RAM --
        DRAM61gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(8, 9)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(8 downto 0),
                DRA     =>      rd_addr(8 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM61gen;
      
        -- Control RAM --
        DRAM61agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(8, 9)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(8 downto 0),
                DRA     =>      rd_addr(8 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM61agen;
    end generate gen61;
   
    gen62: if WR_DWIDTH < RD_DWIDTH generate  
        -- Data RAM --
        DRAM62gen: for i in 0 to RD_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(8, 9)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(8 downto 0),
                DRA     =>      rd_addr(8 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM62gen;
      
        -- Control RAM --
        DRAM62agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(8, 9)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(8 downto 0),
                DRA     =>      rd_addr(8 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM62agen;
    end generate gen62; 

    gen63: if WR_DWIDTH = RD_DWIDTH generate  
        -- Data RAM --
        DRAM63gen: for i in 0 to WR_DWIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(8, 9)
            port map (
                DI      =>      wr_buf(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(8 downto 0),
                DRA     =>      rd_addr(8 downto 0),
                DO      =>      rd_buf(i),
                SO      =>      rd_temp(i));
        end generate DRAM63gen;
      
        -- Control RAM --
        DRAM63agen: for i in 0 to CTRL_WIDTH-1 generate
            D_RAM1: RAM_64nX1 
            generic map(8, 9)
            port map (
                DI      =>      ctrl_wr_buf_i(i),
                WEn     =>      wr_allow,
                WCLK    =>      wr_clk,
                Ad      =>      wr_addr(8 downto 0),
                DRA     =>      rd_addr(8 downto 0),
                DO      =>      ctrl_rd_buf(i),
                SO      =>      ctrl_rd_temp(i));
        end generate DRAM63agen;
    end generate gen63; 
        
end generate DRAMgen6;

end DRAM_macro_hdl;

