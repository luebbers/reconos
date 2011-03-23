
-------------------------------------------------------------------------------
--                                                                           --
--  Module      : RAM_64nX1.vhd        Last Update:                          --
--                                                                           --
--  Description : This parameterizable module cascade Distributed 	     --
--                RAM primitive to build a larger macro with different data  --
--		  widths and depths for the LocalLink FIFO.	             --
--                                                                           --                                                                      --
--  Designer    : Wen Ying Wei                                               --
--                                                                           --
--  Company     : Xilinx, Inc.                                               --
--                                                                           --
--  Disclaimer  : THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY        --
--                WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY           --
--                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR         --
--                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.             --
--                THEY ARE ONLY INTENDED TO BE USED BY XILINX                --
--                CUSTOMERS, AND WITHIN XILINX DEVICES.                      --
--                                                                           --
--                Copyright (c) 2003 Xilinx, Inc.                            --
--                All rights reserved                                        --
--                                                                           --
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.fifo_u.all;

entity RAM_64nX1 is
    generic (
        RAM_NUM     :       integer;  -- 4, 8
        ADDR_WIDTH  :       integer   -- equal to ceiling[log2(RAM_NUM * 64)] 
        );
    port (
        DI      :       in std_logic;
        WEn     :       in std_logic;
        WCLK    :       in std_logic;
        Ad      :       in std_logic_vector(ADDR_WIDTH-1 downto 0);
        DRA     :       in std_logic_vector(ADDR_WIDTH-1 downto 0);
        DO      :       out std_logic;
        SO      :       out std_logic); 
    end RAM_64nX1;

architecture RAM_64nX1_hdl of RAM_64nX1 is

signal wr_en    :       std_logic_vector(RAM_NUM-1 downto 0);
signal dp       :       std_logic_vector(RAM_NUM-1 downto 0);
signal sp       :       std_logic_vector(RAM_NUM-1 downto 0);
signal wr_ram_sel  :    std_logic_vector(RAM_NUM-1 downto 0);
signal rd_ram_sel  :    std_logic_vector(RAM_NUM-1 downto 0);

component RAM64X1D
    port (
        D       :       in std_logic;
        WE      :       in std_logic;
        WCLK    :       in std_logic;
        A0      :       in std_logic;
        A1      :       in std_logic;
        A2      :       in std_logic;
        A3      :       in std_logic;
        A4      :       in std_logic;
        A5      :       in std_logic;
        DPRA0   :       in std_logic;
        DPRA1   :       in std_logic;
        DPRA2   :       in std_logic;
        DPRA3   :       in std_logic;
        DPRA4   :       in std_logic;
        DPRA5   :       in std_logic;
        DPO     :       out std_logic;
        SPO     :       out std_logic);
end component;

begin
-- binary to one-hot
wr_ram_sel_gen1 : if RAM_NUM = 1 generate
    wr_ram_sel(0) <= '1';
end generate;

wr_ram_sel_gen2 : if RAM_NUM > 1 generate
    wr_ram_sel <=  conv_std_logic_vector(POWER2(conv_integer(Ad(ADDR_WIDTH-1 downto 6) )), RAM_NUM);
end generate;

wr_en_gen: for i in 0 to RAM_NUM-1 generate
    wr_en(i) <= WEn and wr_ram_sel(i);
end generate;

-- binary to one-hot
rd_ram_sel_gen1 : if RAM_NUM = 1 generate
    rd_ram_sel(0) <= '1';
end generate;

rd_ram_sel_gen2 : if RAM_NUM > 1 generate
     rd_ram_sel <=  conv_std_logic_vector(POWER2(conv_integer(DRA(ADDR_WIDTH-1 downto 6))), RAM_NUM);
end generate;

--data output mux
do_gen1: if RAM_NUM = 1 generate
    DO <= dp(0);
end generate;

do_gen2: if RAM_NUM = 2 generate
    DO <= dp(0) when rd_ram_sel = "01" else dp(1);
end generate;

do_gen4: if RAM_NUM = 4 generate  --depth is 256
    DO <= dp(0) when rd_ram_sel = "0001" 
             else dp(1) when rd_ram_sel = "0010"
             else dp(2) when rd_ram_sel = "0100"
             else dp(3);
end generate;

do_gen8: if RAM_NUM = 8 generate   --depth is 512
    DO <= dp(0) when rd_ram_sel = "00000001" 
             else dp(1) when rd_ram_sel = "00000010"
             else dp(2) when rd_ram_sel = "00000100"
             else dp(3) when rd_ram_sel = "00001000"
             else dp(4) when rd_ram_sel = "00010000"
             else dp(5) when rd_ram_sel = "00100000"
             else dp(6) when rd_ram_sel = "01000000"
             else dp(7);
end generate;

so_gen1: if RAM_NUM = 1 generate
    SO <= sp(0);
end generate;

so_gen2: if RAM_NUM = 2 generate
    SO <= sp(0) when rd_ram_sel = "01" else sp(1);
end generate;

so_gen4: if RAM_NUM = 4 generate
    SO <= sp(0) when rd_ram_sel = "0001" 
             else sp(1) when rd_ram_sel = "0010"
             else sp(2) when rd_ram_sel = "0100"
             else sp(3);
end generate;

so_gen8: if RAM_NUM = 8 generate
    SO <= sp(0) when rd_ram_sel = "00000001" 
             else sp(1) when rd_ram_sel = "00000010"
             else sp(2) when rd_ram_sel = "00000100"
             else sp(3) when rd_ram_sel = "00001000"
             else sp(4) when rd_ram_sel = "00010000"
             else sp(5) when rd_ram_sel = "00100000"
             else sp(6) when rd_ram_sel = "01000000"
             else sp(7);
end generate;

dram_gen: for i in 0 to RAM_NUM-1 generate
    DRAM64x1: RAM64X1D port map (
        D       =>      DI,
        WE      =>      wr_en(i),
        WCLK    =>      WCLK,
        A0      =>      Ad(0),
        A1      =>      Ad(1),
        A2      =>      Ad(2),
        A3      =>      Ad(3),
        A4      =>      Ad(4),
        A5      =>      Ad(5),
        DPRA0   =>      DRA(0),
        DPRA1   =>      DRA(1),
        DPRA2   =>      DRA(2),
        DPRA3   =>      DRA(3),
        DPRA4   =>      DRA(4),
        DPRA5   =>      DRA(5),
        DPO     =>      dp(i),
        SPO     =>      sp(i));
end generate;
        
end RAM_64nX1_hdl;
