-------------------------------------------------------------------------------
-- Title      : Parameterisable Shift Register 
-- Project    : 
-------------------------------------------------------------------------------
-- File       : shreg.vhd
-- Author     : Hamish Fallside
-- Company    : Xilinx Inc
-- Created    : 2000/05/11
-- Last update: 2001-04-18
-- Copyright  : (c) Xilinx Inc 1999, 2000
-------------------------------------------------------------------------------
-- Description: A parameterisable shift register
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2000/05/11  1.1      hamish  Created
-- 2001/02/14  1.2      Davy    Add AsynReset generic
-------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SHReg is
  generic (width : natural    := 8;       -- sr width
         AsynReset  : boolean := false;   -- use asynchronous reset if true
           circular : boolean := false);  -- q(0) <= q(w - 1) if true
  port (reset : in std_logic;             -- reset lsb <= 1, ~lsb <= 0
        clk : in std_logic;               -- input clock
        en : in std_logic;                -- enable
        q : out std_logic_vector(width - 1 downto 0));  -- output
end SHReg;

architecture arch1 of SHReg is

    signal qt : std_logic_vector(width - 1 downto 0);
    
begin

  q <= qt;
  
  
  pro1  : if AsynReset = false generate 

   rArray : for i in 0 to width - 1 generate
    lsb : if i = 0 generate
      lsbff : process (clk, reset)
      begin
        if clk'event and clk = '1' then
          if reset = '1' then
            qt(i) <= '1';
          elsif en = '1' then
            if circular then
              qt(i) <= qt(width - 1);
            else
              qt(i) <= '0';
            end if;
          end if;
        end if;
      end process lsbff;
    end generate lsb;

    othersb : if i /= 0 generate
      otherff : process (clk, reset)
      begin
        if clk'event and clk = '1' then
          if reset = '1' then
            qt(i) <= '0';
          elsif en = '1' then
            qt(i) <= qt(i - 1);
          end if;
        end if;
      end process otherff;
      end generate othersb;
    end generate rArray;

  end generate pro1;
  
  
  pro2  : if AsynReset = true generate 

   rArray : for i in 0 to width - 1 generate
    lsb : if i = 0 generate
      lsbff : process (clk, reset)
      begin
        if reset = '1' then
          qt(i) <= '1';
        elsif clk'event and clk = '1' then
          if en = '1' then
            if circular then
              qt(i) <= qt(width - 1);
            else
              qt(i) <= '0';
            end if;
          end if;
        end if;
      end process lsbff;
    end generate lsb;

    othersb : if i /= 0 generate
      otherff : process (clk, reset)
      begin
        if reset = '1' then
           qt(i) <= '0';
        elsif clk'event and clk = '1' then
          if en = '1' then
            qt(i) <= qt(i - 1);
          end if;
        end if;
      end process otherff;
      end generate othersb;
    end generate rArray;

  end generate pro2;

    
end arch1;
