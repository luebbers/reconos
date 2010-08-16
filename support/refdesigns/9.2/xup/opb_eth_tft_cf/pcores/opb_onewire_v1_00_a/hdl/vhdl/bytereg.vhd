-------------------------------------------------------------------------------
-- Title      : Parameterisable Byte Register
-- Project    : 
-------------------------------------------------------------------------------
-- File       : bytereg.vhd
-- Author     : Davy Huang <Dai.Huang@Xilinx.com>
-- Company    : Xilinx Inc
-- Created    : 2001/03/15
-- Last update: 2001-04-18
-- Copyright  : (c) Xilinx Inc 2001
-------------------------------------------------------------------------------
-- Description: A parameterisable register, loaded by the bytes
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001/03/15  1.0      davy    Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ByteReg is
  
  generic ( numBytes : integer := 6);    -- the number of bytes to be held

  port (
    clk   : in  std_logic;              -- input clock
    reset : in  std_logic;              -- asynchronous reset
    din   : in  std_logic_vector(7 downto 0);              -- input data (byte)
    en    : in  std_logic_vector((numBytes - 1) downto 0); -- enables for the reg
    dout  : out std_logic_vector((numBytes *8 -1) downto 0) ); -- parallel output

end ByteReg;

architecture arch1 of ByteReg is

begin  -- arch1

  gen0: for i in 0 to numBytes - 1 generate

    lpl: process (reset, clk)
    begin  -- process lpl
      if reset = '1' then
        dout((i+1)*8 -1  downto i*8) <= (others =>'0');
      elsif clk'event and clk = '1' then
        if en(i) = '1' then
          dout((i+1)*8 -1  downto i*8) <= din;
        end if;
      end if;
    end process lpl;
    
  end generate gen0;

end arch1;
