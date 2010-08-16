-------------------------------------------------------------------------------
-- Title      : Parameterisable Bit Register
-- Project    : 
-------------------------------------------------------------------------------
-- File       : bitreg.vhd
-- Author     : Davy Huang <Dai.Huang@Xilinx.com>
-- Company    : Xilinx Inc
-- Created    : 2001/01/31
-- Last update: 2001-04-18
-- Copyright  : (c) Xilinx Inc 2001
-------------------------------------------------------------------------------
-- Description: A parameterisable register, loaded by the bits
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001/01/31  1.0      davy    Created
-- 2001/02/14  1.1      davy    Change to asyn. reset
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity BitReg is
  
  generic ( numBits : integer := 8);    -- the number of bits to be held

  port (
    clk   : in  std_logic;              -- input clock
    reset : in  std_logic;              -- asynchronous reset
    din   : in  std_logic;              -- input data (bit)
    en    : in  std_logic_vector( (numBits - 1) downto 0);  -- enables for register
    dout  : out std_logic_vector( (numBits - 1) downto 0) );  -- output data

end BitReg;

architecture arch1 of BitReg is

begin  -- arch1

  gen0: for i in 0 to numBits - 1 generate

    lpl: process (reset, clk)
    begin  -- process lpl
      if reset = '1' then
        dout(i) <= '0';
      elsif clk'event and clk = '1' then
        if en(i) = '1' then
          dout(i) <= din;
        end if;
      end if;
    end process lpl;
    
  end generate gen0;

end arch1;
