--
-- \file ram_single.vhd
--
-- Single-Port parametrizable local RAM block
--
-- Port A is thread-side, port b is osif-side.
--
-- Possible combinations of generics:
--
-- G_PORTA_DWIDTH = 32	(fixed)
-- G_PORTB_DWIDTH = 64  (fixed)
--
--  G_PORTA_AWIDTH | G_PORTB_AWIDTH | size
-- ----------------+----------------+-----
--        10       |       9        |  4kB
--        11       |      10        |  8kB
--        12       |      11        | 16kB
--        13       |      12        | 32kB
--        14       |      13        | 64kB
--
-- To enable the use of byte enable signals from Port B, symmetric BRAM 
-- blocks must be used, which are then multiplexed on the read port of
-- Port A to realize the lower data bus width:
--
--                      _____                           ____               
--              _______|     |________           sel   |    |               
--             |  8    |_____|   8    |          ------| FF |<--- addra(0)   
--             |                      |          |     |____|
--             |         ...          |-------   |                             
--             |        _____         |   32 |   |                           
--             |_______|     |________|      |  |\                          
--             |  8    |_____|   8           |  | \                          
--        64   |                             ---|0|                         
--      -------|                                | |-------------> douta
--             |        _____                ---|1|                          
--             |_______|     |________       |  | /                         
--             |  8    |_____|   8    |      |  |/                           
--             |                      |      |                               
--             |         ...          |-------
--             |        _____         |   32                                 
--             |_______|     |________|                                     
--                8    |_____|   8                                           
--                                                                           
-- Note that the sel signal for the read multiplexer must be delayed to match
-- the read delay of the synchronous BRAMs.
--
-- \author     Enno Luebbers <luebbers@reconos.de>
-- \date       11.05.2007
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

entity ram_single is
	generic (
		-- address and data widths, THREAD-side and OSIF-side
		G_PORTA_AWIDTH : integer := 10;
		G_PORTA_DWIDTH : integer := 32;			-- this is fixed!
		G_PORTB_AWIDTH   : integer := 10;
		G_PORTB_DWIDTH   : integer := 64;		-- this is fixed!
                G_PORTB_USE_BE   : integer := 0         -- use BEs on port B
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

end ram_single;

architecture Behavioral of ram_single is

	--== DERIVED CONSTANTS ==--
	-- RAM size derived from Port A
	constant C_PORTA_SIZE_BYTES : natural := 2**G_PORTA_AWIDTH * (G_PORTA_DWIDTH/8);
	-- RAM size derived from Port B
	constant C_PORTB_SIZE_BYTES : natural := 2**G_PORTB_AWIDTH * (G_PORTB_DWIDTH/8);
	
	constant C_RAM_SIZE_KB : natural := C_PORTA_SIZE_BYTES / 1024;
	
	-- number of BRAM blocks
	constant C_NUM_BRAMS : natural := C_RAM_SIZE_KB / 2;
	-- thread-side data width of a single BRAM block
	constant C_PORTA_BRAM_DWIDTH : natural := G_PORTA_DWIDTH / C_NUM_BRAMS;
	constant C_PORTB_BRAM_DWIDTH : natural := G_PORTB_DWIDTH / C_NUM_BRAMS;

	-- ratio of data widths
	constant C_BRAM_DWIDTH_RATIO : natural := C_PORTB_BRAM_DWIDTH / C_PORTA_BRAM_DWIDTH;		-- always 2

	-- BRAM wrapper component
	component bram_wrapper is
		generic (
			G_PORTA_DWIDTH : natural := 8;
			G_PORTB_DWIDTH : natural := 16;
			G_PORTA_AWIDTH : natural := 11;
			G_PORTB_AWIDTH : natural := 10
		);
		port (
			DOA : out std_logic_vector(G_PORTA_DWIDTH-1 downto 0);
			DOB : out std_logic_vector(G_PORTB_DWIDTH-1 downto 0);
			ADDRA : in std_logic_vector(G_PORTA_AWIDTH-1 downto 0);
			ADDRB : in std_logic_vector(G_PORTB_AWIDTH-1 downto 0);
			CLKA : in std_logic;
			CLKB : in std_logic;
			DIA : in std_logic_vector(G_PORTA_DWIDTH-1 downto 0);
			DIB : in std_logic_vector(G_PORTB_DWIDTH-1 downto 0);
			ENA : in std_logic;
			ENB : in std_logic;
			SSRA : in std_logic;
			SSRB : in std_logic;
			WEA : in std_logic;
			WEB : in std_logic
		);
	end component;

	subtype bram_vec_array_t is std_logic_vector(G_PORTB_DWIDTH-1 downto 0);

	-- helper signals for BRAM connection
	signal dina_tmp     : bram_vec_array_t;
	signal douta_tmp    : bram_vec_array_t;
        signal ena_tmp      : std_logic_vector(C_NUM_BRAMS-1 downto 0);
        signal wea_tmp      : std_logic_vector(C_NUM_BRAMS-1 downto 0);
        signal enb_tmp      : std_logic_vector(C_NUM_BRAMS-1 downto 0);
        signal web_tmp      : std_logic_vector(C_NUM_BRAMS-1 downto 0);

        signal sel          : std_logic;   -- selector for PORTA BRAM multiplexer

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

        assert (G_PORTB_AWIDTH = G_PORTA_AWIDTH-1)
                report "PORTB must have an address width one greater than that of PORTA"
                severity failure;
		
	assert C_PORTA_SIZE_BYTES = C_PORTB_SIZE_BYTES
		report "combination of data and address widths impossible"
		severity failure;

	assert (G_PORTB_USE_BE = 0) or (C_PORTB_BRAM_DWIDTH <= 8)
		report "port B byte enables cannot be used with this memory size"
		severity failure;

        -- generate enable signals from byte enables for PORTB
        WITH_BE: if G_PORTB_USE_BE /= 0 generate
            PORTB: for i in C_NUM_BRAMS-1 downto 0 generate
                enb_tmp(i) <= beb(i/(8/C_PORTB_BRAM_DWIDTH)) and ENB;
                web_tmp(i) <= beb(i/(8/C_PORTB_BRAM_DWIDTH)) and WEB;
            end generate;
        end generate;
        WITHOUT_BE: if G_PORTB_USE_BE = 0 generate
            PORTB: for i in C_NUM_BRAMS-1 downto 0 generate
                enb_tmp(i) <= ENB;
                web_tmp(i) <= WEB;
            end generate;
        end generate;

        -- generate enable/write enable signals for PORTA
        TOP_HALF : for i in C_NUM_BRAMS-1 downto C_NUM_BRAMS/2 generate
            ena_tmp(i) <= ENA and addra(0);
            wea_tmp(i) <= WEA and addra(0);
        end generate;
        BOTTOM_HALF : for i in (C_NUM_BRAMS/2)-1 downto 0 generate
            ena_tmp(i) <= ENA and not addra(0);
            wea_tmp(i) <= WEA and not addra(0);
        end generate;

        -- delay multiplexer select signal for one cycle to match BRAM delay
        sel_delay_proc: process(clka)
        begin
            if rising_edge(clka) then
                sel <= addra(0);
            end if;
        end process;

        -- multiplex PORTA RAM output
        douta <= douta_tmp((G_PORTA_DWIDTH*2)-1 downto G_PORTA_DWIDTH) when sel = '1' else
                 douta_tmp( G_PORTA_DWIDTH   -1 downto 0);
        dina_tmp((G_PORTA_DWIDTH*2)-1 downto G_PORTA_DWIDTH) <= dina;
        dina_tmp( G_PORTA_DWIDTH   -1 downto              0) <= dina;

	-- instantiate RAMs
	rams: for i in C_NUM_BRAMS-1 downto 0 generate
		bram_inst : bram_wrapper
			generic map (
				G_PORTA_DWIDTH => C_PORTB_BRAM_DWIDTH,
				G_PORTA_AWIDTH => G_PORTB_AWIDTH,
				G_PORTB_DWIDTH => C_PORTB_BRAM_DWIDTH,
				G_PORTB_AWIDTH => G_PORTB_AWIDTH
			)
			port map (
				DOA => douta_tmp((i+1)*C_PORTB_BRAM_DWIDTH-1 downto i*C_PORTB_BRAM_DWIDTH),
--                                    douta((i+1)*C_PORTA_BRAM_DWIDTH-1 downto i*C_PORTA_BRAM_DWIDTH),
				DOB => doutb((i+1)*C_PORTB_BRAM_DWIDTH-1 downto i*C_PORTB_BRAM_DWIDTH),
				ADDRA => addra(G_PORTA_AWIDTH-1 downto 1),
				ADDRB => addrb,
				CLKA => clka,
				CLKB => clkb,
				DIA => dina_tmp((i+1)*C_PORTB_BRAM_DWIDTH-1 downto i*C_PORTB_BRAM_DWIDTH),
                                    -- dina((i+1)*C_PORTA_BRAM_DWIDTH-1 downto i*C_PORTA_BRAM_DWIDTH),
				DIB => dinb((i+1)*C_PORTB_BRAM_DWIDTH-1 downto i*C_PORTB_BRAM_DWIDTH),
				ENA => ena_tmp(i),
				ENB => enb_tmp(i),
				SSRA => '0',
				SSRB => '0',
				WEA => wea_tmp(i),
				WEB => web_tmp(i)
			);
			
	end generate; -- rams

end Behavioral;

