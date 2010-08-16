----------------------------------------------------------------------------------
-- Company: University of Paderborn
-- Engineer: Markus Happe
-- 
-- Create Date:    11:55:17 02/11/2008 
-- Design Name: 
-- Module Name:    pseudo_random - Behavioral 
-- Project Name:   Parallelization and HW/SW Codesign of Particle Filters
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-----------------------------------------------------------------
-- 
--  PSEUDO RANDOM NUMBER GENERATOR
--
--  source: 'VHDL - Eine Einfuehrung' by P. Molitor and J. Ritter,
--          Pearson Studium, 2004, Munich
--
------------------------------------------------------------------

entity pseudo_random is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           enable : in  STD_LOGIC;
           load : in  STD_LOGIC;
           seed : in  STD_LOGIC_VECTOR(31 downto 0);
           pseudoR : out  STD_LOGIC_VECTOR(31 downto 0));
			  
	 begin
	 -- synthesis off
	 assert seed /= X"ffffffff"
    report "pseudoRandom: Startwert darf nicht nur aus Einsen bestehen"
    severity failure;	 
	 -- synthesis on
end pseudo_random;

architecture Structure of pseudo_random is
   signal sreg : STD_LOGIC_VECTOR(31 downto 0);
begin
   pseudoRandomNumbers: process(reset, clk)
	begin
	if reset = '1' then
	    sreg<=(others=>'0');
	elsif rising_edge(clk) then
	   if enable='1' then
		   if load='1' then
			   sreg<=seed;
			else
			   sreg<=(sreg(1) xnor sreg(0)) & sreg(31 downto 1);
			end if;
	    end if;
	end if;
end process;
	
pseudoR <= sreg;

end Structure;

