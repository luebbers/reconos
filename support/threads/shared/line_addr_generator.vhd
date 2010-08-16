--
-- \file line_addr_generator.vhd
--
-- Address generator for 3x3 kernel threads
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity line_addr_generator is
	generic (
		C_PIX_PER_LINE : integer := 320;
		C_LINES_PER_FRAME : integer := 240;
		C_PIX_AWIDTH : integer := 9;
		C_LINE_AWIDTH : integer := 9;
		C_BRAM_AWIDTH : integer := 11
	);
	
	Port (
		rst : in  std_logic;
		next_line : in  std_logic;
		line_sel : in  std_logic_vector (1 downto 0);
		pix_sel : in  std_logic_vector (C_PIX_AWIDTH - 1 downto 0);
		frame_offset : out  std_logic_vector (C_PIX_AWIDTH + C_LINE_AWIDTH - 1 downto 0);
		bram_addr : out std_logic_vector(C_BRAM_AWIDTH - 1 downto 0);
		last_line : out  std_logic;
		ready : out std_logic
	);
end line_addr_generator;

architecture Behavioral of line_addr_generator is

	constant C_FRAME_AWIDTH : integer := C_PIX_AWIDTH + C_LINE_AWIDTH;
	constant C_LINE_INVALID : integer := 3;

	signal last_line_dup : std_logic;
	signal line_number : integer range 0 to C_LINES_PER_FRAME;
	
	type t_state is ( LINE_INIT_A,
	                       LINE_INIT_B,
	                       LINE_INIT_C,
	                       LINE_REPLACE_A,
	                       LINE_REPLACE_B,
	                       LINE_REPLACE_C );
	signal state : t_state;
	
	function get_local_line(lstate : t_state;
			lsel : std_logic_vector (1 downto 0)) return integer is
	begin
		case lstate is
		when LINE_REPLACE_A =>
			case lsel is
				when B"00" => return 0;
				when B"01" => return 1;
				when B"10" => return 2;
				when others => return C_LINE_INVALID;
			end case;
		when LINE_REPLACE_B =>
			case lsel is
				when B"00" => return 1;
				when B"01" => return 2;
				when B"10" => return 0;
				when others => return C_LINE_INVALID;
			end case;
		when LINE_REPLACE_C =>
			case lsel is
				when B"00" => return 2;
				when B"01" => return 0;
				when B"10" => return 1;
				when others => return C_LINE_INVALID;
			end case;
		when others => return C_LINE_INVALID;
		end case;
		return C_LINE_INVALID;
	end function;
	
	function get_line_to_replace(lstate : t_state) return integer is
	begin
		case lstate is
			when LINE_REPLACE_A => return 0;
			when LINE_INIT_A    => return 0;
			when LINE_REPLACE_B => return 1;
			when LINE_INIT_B    => return 1;
			when LINE_REPLACE_C => return 2;
			when LINE_INIT_C    => return 2;
		end case;
		return C_LINE_INVALID;
	end function;
	
	function get_ready(lstate : t_state)
	return std_logic is
	begin
		case lstate is
			when LINE_INIT_A => return '0';
			when LINE_INIT_B => return '0';
			when LINE_INIT_C => return '0';
			when others => return '1';
		end case;
		return '0';
	end function;
	
	function get_next_state(lstate : t_state)
	return t_state is
	begin
		case lstate is
			when LINE_INIT_A => return LINE_INIT_B;
			when LINE_INIT_B => return LINE_INIT_C;
			when LINE_INIT_C => return LINE_REPLACE_A;
			when LINE_REPLACE_A => return LINE_REPLACE_B;
			when LINE_REPLACE_B => return LINE_REPLACE_C;
			when LINE_REPLACE_C => return LINE_REPLACE_A;
		end case;
	end function;
	
	procedure get_bram_addr(lstate : in t_state; writing : in std_logic;
	      lsel : in std_logic_vector (1 downto 0);
	      psel : in std_logic_vector (C_PIX_AWIDTH - 1 downto 0);
		  signal result : out std_logic_vector(C_BRAM_AWIDTH - 1 downto 0)) is
		  variable tmp : integer;
	begin
		if writing = '1' then
			tmp := get_line_to_replace(lstate)*C_PIX_PER_LINE + CONV_INTEGER(psel);
			result <= conv_std_logic_vector(tmp,C_BRAM_AWIDTH);	         
		else
			tmp := get_local_line(lstate, lsel)*C_PIX_PER_LINE + CONV_INTEGER(psel);
			result <= conv_std_logic_vector(tmp,C_BRAM_AWIDTH);     
		end if;
	end procedure;
	
begin
	
	frame_offset <= conv_std_logic_vector(line_number*C_PIX_PER_LINE, C_FRAME_AWIDTH);
	last_line <= last_line_dup;
	ready <= get_ready(state) or last_line_dup;
	get_bram_addr(state, next_line, line_sel, pix_sel,bram_addr);
	
	state_proc_falling: process(next_line, rst)
	begin
		if rst = '1' then
			last_line_dup <= '0';
			state <= LINE_INIT_A;
			line_number <= 0;
		elsif falling_edge(next_line) then
			if line_number = C_LINES_PER_FRAME - 1 then
				last_line_dup <= '1';
				state <= LINE_INIT_A;
			else
			   last_line_dup <= '0';
			   state <= get_next_state(state);
			end if;
			if last_line_dup = '1' then
				line_number <= 0;
			else
				line_number <= line_number + 1;
			end if;		
		end if;
	end process;

end Behavioral;

