--
-- \file conv_filter3x3.vhd
--
-- Implements a configurable 3x3 convolution kernel
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

entity conv_filter3x3 is
    Port (
			  clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           ien : in  STD_LOGIC;
           shift_in : in  STD_LOGIC_VECTOR (23 downto 0);
           shift_out : out  STD_LOGIC_VECTOR (7 downto 0);
           kernel : in  STD_LOGIC_VECTOR (80 downto 0) -- 9x9
	 );
end conv_filter3x3;

architecture Behavioral of conv_filter3x3 is

	type t_state is ( STATE_ADD,
	                  STATE_SHIFT_OUT);
	
	signal state : t_state;

	signal row_a  : std_logic_vector(23 downto 0);
	signal row_b  : std_logic_vector(23 downto 0);
	signal row_c  : std_logic_vector(23 downto 0);
	signal pixels : std_logic_vector(71 downto 0); -- 9 pixels x 8 bit
	signal p0,p1,p2,p3,p4,p5,p6,p7,p8 : std_logic_vector(7 downto 0);
	signal k0,k1,k2,k3,k4,k5,k6,k7,k8 : std_logic_vector(8 downto 0);
	signal m0,m1,m2,m3,m4,m5,m6,m7,m8 : std_logic_vector(15 downto 0);

	function my_sum(sign  : std_logic_vector(8 downto 0);
	             m0 : std_logic_vector(15 downto 0);
					 m1 : std_logic_vector(15 downto 0);
					 m2 : std_logic_vector(15 downto 0);
					 m3 : std_logic_vector(15 downto 0);
					 m4 : std_logic_vector(15 downto 0);
					 m5 : std_logic_vector(15 downto 0);
					 m6 : std_logic_vector(15 downto 0);
					 m7 : std_logic_vector(15 downto 0);
					 m8 : std_logic_vector(15 downto 0)) return std_logic_vector is
		variable s : std_logic_vector(19 downto 0);
		variable s0 : std_logic_vector(19 downto 0);
		variable s1 : std_logic_vector(19 downto 0);
		variable s2 : std_logic_vector(19 downto 0);
		variable s3 : std_logic_vector(19 downto 0);
		variable s4 : std_logic_vector(19 downto 0);
		variable s5 : std_logic_vector(19 downto 0);
		variable result : std_logic_vector(7 downto 0);
	begin
		s0 := X"20000";
		s1 := X"20000";
		s2 := X"20000";
		s3 := X"20000";
		if sign(0) = '0' then s0 := s0 + m0(15 downto 4);
		else                  s0 := s0 - m0(15 downto 4); end if;
		if sign(1) = '0' then s0 := s0 + m1(15 downto 4);
		else                  s0 := s0 - m1(15 downto 4); end if;
		if sign(2) = '0' then s1 := s1 + m2(15 downto 4);
		else                  s1 := s1 - m2(15 downto 4); end if;
		if sign(3) = '0' then s1 := s1 + m3(15 downto 4);
		else                  s1 := s1 - m3(15 downto 4); end if;
		if sign(4) = '0' then s2 := s2 + m4(15 downto 4);
		else                  s2 := s2 - m4(15 downto 4); end if;
		if sign(5) = '0' then s2 := s2 + m5(15 downto 4);
		else                  s2 := s2 - m5(15 downto 4); end if;
		if sign(6) = '0' then s3 := s3 + m6(15 downto 4);
		else                  s3 := s3 - m6(15 downto 4); end if;
		if sign(7) = '0' then s3 := s3 + m7(15 downto 4);
		else                  s3 := s3 - m7(15 downto 4); end if;
		if sign(8) = '0' then s3 := s3 + m8(15 downto 4);
		else                  s3 := s3 - m8(15 downto 4); end if;	
		
		s4 := s0 + s1;
		s5 := s2 + s3;
		s := s4 + s5;
		
		if s > X"800FF" then
			result := X"FF";
		elsif s < X"80000" then
			result := X"00";
		else
			result := s(7 downto 0);
		end if;
		
		return result;
	end function;
					 
	
begin
	
	pixels <= row_a & row_b & row_c;
	
	p0 <= pixels(1*8-1 downto 0*8);
	p1 <= pixels(2*8-1 downto 1*8);
	p2 <= pixels(3*8-1 downto 2*8);
	p3 <= pixels(4*8-1 downto 3*8);
	p4 <= pixels(5*8-1 downto 4*8);
	p5 <= pixels(6*8-1 downto 5*8);
	p6 <= pixels(7*8-1 downto 6*8);
	p7 <= pixels(8*8-1 downto 7*8);
	p8 <= pixels(9*8-1 downto 8*8);
	
	k0 <= kernel(1*9-1 downto 0*9);
	k1 <= kernel(2*9-1 downto 1*9);
	k2 <= kernel(3*9-1 downto 2*9);
	k3 <= kernel(4*9-1 downto 3*9);
	k4 <= kernel(5*9-1 downto 4*9);
	k5 <= kernel(6*9-1 downto 5*9);
	k6 <= kernel(7*9-1 downto 6*9);
	k7 <= kernel(8*9-1 downto 7*9);
	k8 <= kernel(9*9-1 downto 8*9);
	
	shift : process(clk, rst)
		variable sum : std_logic_vector(15 downto 0);
	begin
		if rising_edge(clk) then
			if ien = '1' then
				row_a <= shift_in;
				row_b <= row_a;
				row_c <= row_b;
			end if;
			
			m0 <= p0*k0(7 downto 0);
			m1 <= p1*k1(7 downto 0);
			m2 <= p2*k2(7 downto 0);
			m3 <= p3*k3(7 downto 0);
			m4 <= p4*k4(7 downto 0);
			m5 <= p5*k5(7 downto 0);
			m6 <= p6*k6(7 downto 0);
			m7 <= p7*k7(7 downto 0);
			m8 <= p8*k8(7 downto 0);
			
			shift_out <= my_sum(k0(8)&k1(8)&k2(8)&k3(8)&k4(8)&k5(8)&k6(8)&k7(8)&k8(8),
								  m0   ,m1   ,m2   ,m3   ,m4   ,m5   ,m6   ,m7   ,m8);
		end if;
	end process;
	
end Behavioral;

