--
-- \file rank_filter3x3.vhd
--
-- Configurable 3x3 rank filter
--
-- \author     Andreas Agne <agne@upb.de>
-- \date       21.11.2007
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of ReconOS (http://www.reconos.de).
-- Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
-- All rights reserved.
-- 
-- ReconOS is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
-- 
-- ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rank_filter3x3 is
    Port (
	      shift_in : in  STD_LOGIC_VECTOR (23 downto 0);
         shift_out : out  STD_LOGIC_VECTOR (7 downto 0);
         clk : in  STD_LOGIC;
		   ien : in std_logic;
         rst : in  STD_LOGIC;
         i : in  STD_LOGIC_VECTOR (3 downto 0)
	);
end entity;

architecture Behavioral of rank_filter3x3 is
	signal row_a  : std_logic_vector(23 downto 0);
	signal row_b  : std_logic_vector(23 downto 0);
	signal row_c  : std_logic_vector(23 downto 0);
	signal pixels : std_logic_vector(71 downto 0); -- 9 pixels x 8 bit
	
	-- instant sorting
	function get_pixel( pixels   : std_logic_vector(71 downto 0);
	                    rank     : std_logic_vector(3 downto 0)) return std_logic_vector
	is
		variable s       : std_logic_vector(3 downto 0);
		variable pixel_j : std_logic_vector(7 downto 0);
		variable pixel_k : std_logic_vector(7 downto 0);
	begin
		for j in 0 to 8 loop -- for each pixel j
		
			s := X"0";
			pixel_j := pixels(j*8 + 7 downto j*8);
			
			for k in 0 to 8 loop -- for each pixel k
			
				pixel_k := pixels(k*8 + 7 downto k*8);
				
				if    k < j and pixel_k >= pixel_j then
					s := s + 1;
				elsif k > j and pixel_k >  pixel_j then
					s := s + 1;
				end if;
				
			end loop;
			
			if s = rank then
				return pixel_j;
			end if;
			
		end loop;
		return X"00";
	end function;
	
begin

	pixels <= row_a & row_b & row_c;
	
	shift : process(clk, rst)
	begin
		if rst = '1' then
			row_a <= (others => '0');
			row_b <= (others => '0');
			row_c <= (others => '0');
		elsif rising_edge(clk) then
			if ien = '1' then
				row_a <= shift_in;
				row_b <= row_a;
				row_c <= row_b;
			end if;
			
			shift_out <= get_pixel(pixels, rank);
			
		end if;
	end process;

end Behavioral;
