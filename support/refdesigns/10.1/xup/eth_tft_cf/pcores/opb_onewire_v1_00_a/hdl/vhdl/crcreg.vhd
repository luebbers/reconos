-------------------------------------------------------------------------------
-- Title      : Parameterisable CRC Shift Register 
-- Project    : 
-------------------------------------------------------------------------------
-- File       : crcreg.vhd
-- Author     : Davy Huang <Dai.Huang@Xilinx.com>
-- Company    : Xilinx Inc
-- Created    : 2001/02/06
-- Last update: 2001-04-18
-- Copyright  : (c) Xilinx Inc 1999, 2000
-------------------------------------------------------------------------------
-- Description: A parameterisable shift register to caculate crc
--              Suppose the data width is w, this CRCSR can handle
--              any CRC caculation based on following polynomia 
--              Polynomial = X^(w) + X^(f1) + X^(f2) + 1
--              where f1 and f2 are two feedbacks.
--              For example: Polynomial = x^8 + x^5 + x^4 + 1, which is
--              used for Dallas One-wire Serial Number device
--              Please refer to iButton standard at:
--              http://www.ibutton.com/ibuttons/standard.pdf
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001/02/06  1.0      davy    Created
-- 2001/02/14  1.1      davy    Change to asyn. reset
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CRCReg is
  generic (width : natural := 8;      -- register width
           feedback1 : natural := 4;
           feedback2 : natural := 5);
  port (reset : in std_logic;         -- asynchronous reset
        clk : in std_logic;           -- input clock
        en : in std_logic;            -- enable
        d  : in std_logic;            -- data input (one bit)
        q : out std_logic_vector( (width - 1) downto 0));  -- output (crc value)
end CRCReg;

architecture arch1 of CRCReg is

    signal qt : std_logic_vector( (width - 1) downto 0);

    signal feedback : std_logic;    

begin

  q <= qt;
  
  feedback <= qt(0) xor d;

  
  rArray : for i in 0 to width - 1 generate
  
    -- caculate msb
    msb  : if i = (width -1) generate
      msbff : process (clk, reset)
      begin
        if reset = '1' then
            qt(i) <= '0';
        elsif clk'event and clk = '1' then
          if en = '1' then
              qt(i) <= feedback;
          end if;
        end if;
      end process msbff;
    end generate msb;
   
   
   -- caculate two feedback paths 
   feedbackb : if (i = (width - feedback1 -1 )) or (i = (width - feedback2 -1)) generate
      feedbackf : process (clk, reset)
      begin
        if reset = '1' then
           qt(i) <= '0';
        elsif clk'event and clk = '1' then
          if en = '1' then
            qt(i) <= qt(i + 1) xor feedback;
          end if;
        end if;
      end process feedbackf;
    end generate feedbackb;


    -- caculate other bits
    othersb : if (i /= (width -1)) and (i /= (width - feedback1 -1 )) and (i /= (width - feedback2 -1)) generate
      othersff : process (clk, reset)
      begin
        if reset = '1' then
           qt(i) <= '0';
        elsif clk'event and clk = '1' then
          if en = '1' then
            qt(i) <= qt(i+1);
          end if;
        end if;
      end process othersff;
    end generate othersb;
    
    
  end generate rArray;


    
end arch1;
