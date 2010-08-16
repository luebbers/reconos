-------------------------------------------------------------------------------
-- $Id: bram_fifo.vhd,v 1.1 2005/02/17 20:29:35 crh Exp $
-------------------------------------------------------------------------------
-- srl_fifo.vhd
-------------------------------------------------------------------------------
--
--                  ****************************
--                  ** Copyright Xilinx, Inc. **
--                  ** All rights reserved.   **
--                  ****************************
--
-------------------------------------------------------------------------------
-- Filename:        srl_fifo.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              srl_fifo.vhd
--
-------------------------------------------------------------------------------
-- Author:          goran
-- Revision:        $Revision: 1.1 $
-- Date:            $Date: 2005/02/17 20:29:35 $
--
-- History:
--   goran  2001-06-12    First Version
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity BRAM_FIFO is
  generic (
    C_DATA_BITS : integer := 32;
    C_ADDR_BITS : integer := 9
    );
  port (
    Clk         : in  std_logic;
    Reset       : in  std_logic;
    Clear_FIFO  : in  std_logic;
    FIFO_Write  : in  std_logic;
    Data_In     : in  std_logic_vector(0 to C_DATA_BITS-1);
    FIFO_Read   : in  std_logic;
    Data_Out    : out std_logic_vector(0 to C_DATA_BITS-1);
    FIFO_Level  : out std_logic_vector(0 to C_ADDR_BITS);
    Full        : out std_logic;
    HalfFull    : out std_logic;
    HalfEmpty   : out std_logic;
    Overflow    : out std_logic;    
    Underflow   : out std_logic;    
    Empty : out std_logic
    );

end entity BRAM_FIFO;

library UNISIM;
use UNISIM.all;

architecture IMP of BRAM_FIFO is

  component RAMB16_S36_S36 
    port(
      DOA   : out std_logic_vector(31 downto 0);
      DOB   : out std_logic_vector(31 downto 0);
      DOPA  : out std_logic_vector(3 downto 0);
      DOPB  : out std_logic_vector(3 downto 0);
      ADDRA : in  std_logic_vector(8 downto 0);
      ADDRB : in  std_logic_vector(8 downto 0);
      CLKA  : in  std_ulogic;
      CLKB  : in  std_ulogic;
      DIA   : in  std_logic_vector(31 downto 0);
      DIB   : in  std_logic_vector(31 downto 0);
      DIPA  : in  std_logic_vector(3 downto 0);
      DIPB  : in  std_logic_vector(3 downto 0);
      ENA   : in  std_ulogic;
      ENB   : in  std_ulogic;
      SSRA  : in  std_ulogic;
      SSRB  : in  std_ulogic;
      WEA   : in  std_ulogic;
      WEB   : in  std_ulogic
      );
  end component; 

  signal in_address, out_address : unsigned(9 downto 0) := (others => '0');
  signal addra, addrb : std_logic_vector(9 downto 0);
  signal addr_diff : unsigned(9 downto 0);
  signal overflow_i, underflow_i : std_logic;
  signal empty_i, full_i : std_logic;
  
begin  -- architecture IMP

  addra <= CONV_STD_LOGIC_VECTOR(in_address,in_address'length);
  addrb <= CONV_STD_LOGIC_VECTOR(out_address,out_address'length);

  U1: RAMB16_S36_S36 
    port map(
      DOA   => open,
      DOB   => Data_Out,
      DOPA  => open,
      DOPB  => open,
      ADDRA => addra(8 downto 0),
      ADDRB => addrb(8 downto 0),
      CLKA  => Clk,
      CLKB  => Clk,
      DIA   => Data_In,
      DIB   => (others => '0'),
      DIPA  => (others => '0'),
      DIPB  => (others => '0'),
      ENA   => '1',
      ENB   => '1',
      SSRA  => Reset,
      SSRB  => Reset,
      WEA   => FIFO_Write,
      WEB   => '0'
      );

  in_address_PROCESS: process (Clk,FIFO_Write)
  begin
    if Reset = '1' then
      in_address <= (others => '0');
    elsif (Clk'event and Clk='1') then
      if (FIFO_Write = '1' and Clear_FIFO = '0') then
        in_address <= in_address + 1;
      elsif (Clear_FIFO = '1') then
        in_address <= (others => '0');
      end if;
    end if;
  end process;

  out_address_PROCESS: process (Clk)
  begin
    if Reset = '1' then
      out_address <= (others => '1');
    elsif (Clk'event and Clk='1') then
      if (FIFO_Read = '1' and Clear_FIFO = '0') then
        out_address <= out_address + 1;
      elsif (Clear_FIFO = '1') then
        out_address <= (others => '1');
      end if;
    end if;
  end process;
  
  overflow_PROCESS: process (Clk)
  begin
    if (Clk'event and Clk='1') then
      if (Clear_FIFO = '1') then
        overflow_i <= '0';
      elsif Full_i = '1' and FIFO_Write = '1' then
        overflow_i <= '1';
      end if;        
    end if;
  end process;
  overflow <= overflow_i;

  underflow_PROCESS: process (Clk)
  begin
    if (Clk'event and Clk='1') then
      if (Clear_FIFO = '1') then
        underflow_i <= '0';
      elsif Empty_i = '1' and FIFO_Read = '1' then
        underflow_i <= '1';
      end if;        
    end if;
  end process;
  underflow <= underflow_i;
  
  addr_diff <= in_address - out_address - 1;
  FIFO_Level <= CONV_STD_LOGIC_VECTOR(addr_diff,addr_diff'length);
  
  HalfFull <= addr_diff(8);
  HalfEmpty <= not addr_diff(8);

  Empty_i <= '1' when addr_diff = 0 else '0';
  Full_i <= '1' when (addr_diff = 512) else '0';
  Empty <= Empty_i;
  Full <= Full_i;
  
end architecture IMP;
