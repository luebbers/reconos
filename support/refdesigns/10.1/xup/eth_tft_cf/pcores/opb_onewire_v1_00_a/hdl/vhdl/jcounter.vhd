-------------------------------------------------------------------------------
-- Title      : Parameterisable Johnson Counter 
-- Project    : 
-------------------------------------------------------------------------------
-- File       : jcounter.vhd
-- Author     : Davy Huang <Dai.Huang@Xilinx.com>
-- Company    : Xilinx Inc
-- Created    : 2001/01/31
-- Last update: 2001-04-18
-- Copyright  : (c) Xilinx Inc 2001
-------------------------------------------------------------------------------
-- Description: A parameterisable johnson counter
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001/01/31  1.0      Davy    Created
-- 2001/02/14  1.1      Davy    Add ASynReset generic
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity JCounter is
  generic (width : natural := 8;      -- number of bits int the counter
                                      -- n bits can count for 2n stages
        AsynReset: boolean := false); -- use asynchronous reset
  port (reset : in std_logic;         -- reset 
        clk : in std_logic;           -- input clock
        en : in std_logic;            -- enable
        q : out std_logic_vector( (width - 1) downto 0));  -- output
end JCounter;

architecture arch1 of JCounter is

signal qi : std_logic_vector ( (width -1) downto 0);
    
begin

  q <= qi;

  pro1  : if AsynReset = false generate 
    process (clk)
    begin
      if clk'event and clk = '1' then
          if reset = '1' then
            qi <= (others =>'0');
          elsif en = '1' then
            qi <= qi( (width - 2) downto 0) & (not qi(width -1));
          end if;
       end if;
    end process;
   end generate pro1;
   
  pro2  : if AsynReset = true generate 
    process (clk, reset)
    begin
      if reset = '1' then
         qi <= (others =>'0');
      elsif clk'event and clk = '1' then
          if en = '1' then
            qi <= qi( (width - 2) downto 0) & (not qi(width -1));
          end if;
       end if;
    end process;
   end generate pro2;

    
end arch1;
