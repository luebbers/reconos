--
-- \file burst_ram.vhd
--
-- Highly parametrizable local RAM block for hardware threads
--
-- Port A is thread-side, port AX is optional thread-side, port b is osif-side.
-- If configured for two thread-side ports, each port will access one half of
-- the total burst RAM.
--
-- Possible combinations of generics:
--
-- G_PORTA_DWIDTH = 32	(fixed)
-- G_PORTB_DWIDTH = 64  (fixed)
--
--  G_PORTA_PORTS | G_PORTA_AWIDTH | G_PORTB_AWIDTH | size
-- ---------------+----------------+----------------+-----
--       1        |       10       |       9        |  4kB
--       1        |       11       |      10        |  8kB
--       1        |       12       |      11        | 16kB
--       1        |       13       |      12        | 32kB
--       1        |       14       |      13        | 64kB
--       2        |       10       |      10        |  8kB
--       2        |       11       |      11        | 16kB
--       2        |       12       |      12        | 32kB
--       2        |       13       |      13        | 64kB
--
-- \author     Enno Luebbers <luebbers@reconos.de>
-- \date       08.05.2007
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
use IEEE.NUMERIC_STD.ALL;

--library reconos_v1_02_a;
--use reconos_v1_02_a.reconos_pkg.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity burst_ram is
	generic (
		-- address and data widths, THREAD-side and OSIF-side
		G_PORTA_AWIDTH : integer := 10;
		G_PORTA_DWIDTH : integer := 32;			-- this is fixed!
		G_PORTA_PORTS  : integer := 2;
		G_PORTB_AWIDTH   : integer := 10;
		G_PORTB_DWIDTH   : integer := 64;		-- this is fixed!
                G_PORTB_USE_BE   : integer := 0 -- use byte-enable on Port B
	);
	port (
		-- A is thread-side, AX is secondary thread-side, B is OSIF-side
		addra : in  std_logic_vector(G_PORTA_AWIDTH-1 downto 0);
		addrax: in  std_logic_vector(G_PORTA_AWIDTH-1 downto 0);
		addrb : in  std_logic_vector(G_PORTB_AWIDTH-1 downto 0);
		clka  : in  std_logic;
		clkax : in  std_logic;
		clkb  : in  std_logic;
		dina  : in  std_logic_vector(G_PORTA_DWIDTH-1 downto 0);		-- these widths are fixed
		dinax : in  std_logic_vector(G_PORTA_DWIDTH-1 downto 0);		--
		dinb  : in  std_logic_vector(G_PORTB_DWIDTH-1 downto 0);		--
		douta : out std_logic_vector(G_PORTA_DWIDTH-1 downto 0);		--
		doutax: out std_logic_vector(G_PORTA_DWIDTH-1 downto 0);		--
		doutb : out std_logic_vector(G_PORTB_DWIDTH-1 downto 0);		--
		wea   : in  std_logic;
		weax  : in  std_logic;
		web   : in  std_logic;
		ena   : in  std_logic;
		enax   : in  std_logic;
		enb   : in  std_logic;
                beb   : in std_logic_vector(G_PORTB_DWIDTH/8-1 downto 0)
	);

end burst_ram;

architecture Behavioral of burst_ram is

	--== DERIVED CONSTANTS ==--
	-- RAM size derived from Port A
	constant C_PORTA_SIZE_BYTES : natural := 2**G_PORTA_AWIDTH * (G_PORTA_DWIDTH/8) * G_PORTA_PORTS;
	-- RAM size derived from Port B
	constant C_PORTB_SIZE_BYTES : natural := 2**G_PORTB_AWIDTH * (G_PORTB_DWIDTH/8);
	
	constant C_RAM_SIZE_KB : natural := C_PORTA_SIZE_BYTES / 1024;
--	constant C_OSIF_AWIDTH : natural := log2(C_RAM_SIZE_BYTES);
--	constant C_THREAD_AWIDTH : natural := C_OSIF_AWIDTH - 2 - log2(G_THREAD_PORTS);
	
	-- number of BRAM blocks
	constant C_NUM_BRAMS : natural := C_RAM_SIZE_KB / 2;
	-- thread-side data width of a single BRAM block
	constant C_PORTA_BRAM_DWIDTH : natural := G_PORTA_DWIDTH * G_PORTA_PORTS / C_NUM_BRAMS;
	constant C_PORTB_BRAM_DWIDTH : natural := C_PORTA_BRAM_DWIDTH * 2;

	-- ratio of data widths
	constant C_BRAM_DWIDTH_RATIO : natural := C_PORTB_BRAM_DWIDTH / C_PORTA_BRAM_DWIDTH;		-- always 2

   -- RAM primitive component declaration
	component ram_single is
		generic (
			-- address and data widths, THREAD-side and OSIF-side
			G_PORTA_AWIDTH : integer := 10;
			G_PORTA_DWIDTH : integer := 32;			-- this is fixed!
			G_PORTB_AWIDTH   : integer := 10;
			G_PORTB_DWIDTH   : integer := 64;		-- this is fixed!
                        G_PORTB_USE_BE   : integer := 0 -- use byte-enable on Port B
		);
		port (
			-- A is thread-side, AX is secondary thread-side, B is OSIF-side
			addra : in  std_logic_vector(G_PORTA_AWIDTH-1 downto 0);
			addrb : in  std_logic_vector(G_PORTB_AWIDTH-1 downto 0);
			clka  : in  std_logic;
			clkb  : in  std_logic;
			dina  : in  std_logic_vector(G_PORTA_DWIDTH-1 downto 0);		-- these widths are fixed
			dinb  : in  std_logic_vector(G_PORTB_DWIDTH-1 downto 0);		--
			douta : out std_logic_vector(G_PORTA_DWIDTH-1 downto 0);		--
			doutb : out std_logic_vector(G_PORTB_DWIDTH-1 downto 0);		--
			wea   : in  std_logic;
			web   : in  std_logic;
			ena   : in  std_logic;
			enb   : in  std_logic;
                        beb   : in std_logic_vector(G_PORTB_DWIDTH/8-1 downto 0)
		);
	end component;

	type mux_vec_array_t is array (G_PORTA_PORTS-1 downto 0) of std_logic_vector(G_PORTB_DWIDTH-1 downto 0);

	-- helper signals for PORTB multiplexer
	signal sel : std_logic;
	signal doutb_tmp : mux_vec_array_t;
	signal web_tmp : std_logic_vector(G_PORTA_PORTS-1 downto 0);		-- 1 is upper RAM (lower addresses)
																							-- 0 is lower RAM (higher addresses)

begin
	-- check generics for feasibility
	assert G_PORTA_DWIDTH = 32
		report "thread-side (PORTA) data width must be 32"
		severity failure;
		
	assert G_PORTB_DWIDTH = 64
		report "OSIF-side (PORTB) data width must be 64"
		severity failure;
		
	-- this will not catch two-port/14 bit, which is not supported)
	assert (G_PORTA_AWIDTH >= 10) and (G_PORTA_AWIDTH <= 14)
		report "PORTA must have address width between 10 and 14 bits"
		severity failure;

	-- this will not catch two-port/9 bit, which is not supported)
	assert (G_PORTB_AWIDTH >= 9) and (G_PORTA_AWIDTH <= 13)
		report "PORTB must have address width between 9 and 13 bits"
		severity failure;
		
	assert (G_PORTA_PORTS <= 2) and (G_PORTA_PORTS > 0)
		report "only one or two thread-side (PORTA) ports supported"
		severity failure;

	assert C_PORTA_SIZE_BYTES = C_PORTB_SIZE_BYTES
		report "combination of data and address widths impossible"
		severity failure;

	assert (G_PORTB_USE_BE = 0) or (C_PORTB_BRAM_DWIDTH <= 8)
		report "port B byte enables cannot be used with this memory size"
		severity failure;

------------------------ SINGLE PORT ---------------------------------------------

	single_port: if G_PORTA_PORTS = 1 generate		-- one thread-side port => no multiplexers
			
		ram_inst: ram_single
			generic map (
				G_PORTA_AWIDTH => G_PORTA_AWIDTH,
				G_PORTA_DWIDTH =>	G_PORTA_DWIDTH,
				G_PORTB_AWIDTH =>	G_PORTB_AWIDTH,
				G_PORTB_DWIDTH =>	G_PORTB_DWIDTH,
                                G_PORTB_USE_BE =>       G_PORTB_USE_BE
			)
			port map (
				addra => addra,
				addrb => addrb,
				clka  => clka,
				clkb  => clkb,
				dina  => dina,
				dinb  => dinb,
				douta => douta,
				doutb => doutb,
				wea   => wea,
				web   => web,
				ena   => ena,
				enb   => enb,
                                beb   => beb
			);

		doutax <= (others => '0');

	end generate;	-- single_port
	
	
------------------------ MULTI PORT ---------------------------------------------
	
	multi_ports: if G_PORTA_PORTS = 2 generate
--		assert false report "multiple ports not yet implemented!" severity failure;

		-- PORTA RAM
		ram_porta: ram_single
			generic map (
				G_PORTA_AWIDTH => G_PORTA_AWIDTH,
				G_PORTA_DWIDTH =>	G_PORTA_DWIDTH,
				G_PORTB_AWIDTH =>	G_PORTB_AWIDTH-1,
				G_PORTB_DWIDTH =>	G_PORTB_DWIDTH,
                                G_PORTB_USE_BE =>       G_PORTB_USE_BE
			)
			port map (
				addra => addra,
				addrb => addrb(G_PORTB_AWIDTH-2 downto 0),
				clka  => clka,
				clkb  => clkb,
				dina  => dina,
				dinb  => dinb,
				douta => douta,
				doutb => doutb_tmp(1),
				wea   => wea,
				web   => web_tmp(1),
				ena   => ena,
				enb   => enb,
                                beb   => beb
			);

		-- PORTAX RAM
		ram_portax: ram_single
			generic map (
				G_PORTA_AWIDTH => G_PORTA_AWIDTH,
				G_PORTA_DWIDTH =>	G_PORTA_DWIDTH,
				G_PORTB_AWIDTH =>	G_PORTB_AWIDTH-1,
				G_PORTB_DWIDTH =>	G_PORTB_DWIDTH,
                                G_PORTB_USE_BE =>       G_PORTB_USE_BE
			)
			port map (
				addra => addrax,
				addrb => addrb(G_PORTB_AWIDTH-2 downto 0),
				clka  => clkax,
				clkb  => clkb,
				dina  => dinax,
				dinb  => dinb,
				douta => doutax,
				doutb => doutb_tmp(0),
				wea   => weax,
				web   => web_tmp(0),
				ena   => enax,
				enb   => enb,
                                beb   => beb
			);

		-- multiplexer
		sel <= addrb(G_PORTB_AWIDTH-1);
		doutb <= doutb_tmp(1) when sel = '0' else doutb_tmp(0);
		web_tmp(1 downto 0) <= (web and not sel) & (web and sel);

	end generate;
		
end Behavioral;

