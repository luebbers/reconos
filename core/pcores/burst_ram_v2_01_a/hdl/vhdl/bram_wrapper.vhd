--
-- \file bram_wrapper.vhd
--
-- Parametrizable BRAM wrapper for use in burst_ram.vhd
--
-- Instantiates RAMB16_Sn_Sm blocks based on generics.
-- The genrics G_PORTA_AWIDTH and G_PORTB_AWIDTH must be set so that together
-- with the selected data width the RAM will hold 16384 bits. That is,
-- the following equations must be true:
--
-- G_PORTA_DWIDTH = 2**(14-G_PORTA_AWIDTH);
-- G_PORTB_DWIDTH = 2**(14-G_PORTB_AWIDTH);
--
-- See table below for address width (in parentheses).
--
-- Currently supported generic combinations:
--
-- G_PORTA_DWIDTH (AWIDTH) | G_PORTB_DWIDTH (AWIDTH) | instantiated BRAM
-- ---------------------------------------------------------------------
--           1 (14)        |          2 (13)         |    RAMB16_S1_S2
--           2 (13)        |          4 (12)         |    RAMB16_S2_S4
--           4 (12)        |          8 (11)         |    RAMB16_S4_S9
--           8 (11)        |         16 (10)         |    RAMB16_S9_S18
--          16 (10)        |         32  (9)         |    RAMB16_S18_S36
--
--           1 (14)        |          1 (14)         |    RAMB16_S1_S1
--           2 (13)        |          2 (13)         |    RAMB16_S2_S2
--           4 (12)        |          4 (12)         |    RAMB16_S4_S4
--           8 (11)        |          8 (11)         |    RAMB16_S9_S9
--          16 (10)        |         16 (10)         |    RAMB16_S18_S18
--          32  (9)        |         32  (9)         |    RAMB16_S36_S36

--
-- RAMB16 generics are left at their defaults. No parity bits are supported.
--
-- \author     Enno Luebbers <luebbers@reconos.de>
-- \date       09.05.2007
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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity bram_wrapper is
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
end bram_wrapper;

architecture Behavioral of bram_wrapper is

    -- derived constants
    constant C_PORTA_DWIDTH : natural := 2**(14-G_PORTA_AWIDTH);
    constant C_PORTB_DWIDTH : natural := 2**(14-G_PORTB_AWIDTH);

begin
    -- check generics
    assert C_PORTA_DWIDTH = G_PORTA_DWIDTH
        report "PORTA parameters don't match"
        severity failure;

    assert C_PORTB_DWIDTH = G_PORTB_DWIDTH
        report "PORTB parameters don't match"
        severity failure;

    -- instantiate BRAM
    s1_s2: if (G_PORTA_DWIDTH = 1) and (G_PORTB_DWIDTH = 2) generate
        bram_inst : RAMB16_S1_S2
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB );
    end generate;

    s2_s4: if (G_PORTA_DWIDTH = 2) and (G_PORTB_DWIDTH = 4) generate
        bram_inst : RAMB16_S2_S4
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB );
    end generate;

    s4_s9: if (G_PORTA_DWIDTH = 4) and (G_PORTB_DWIDTH = 8) generate
        bram_inst : RAMB16_S4_S9
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB, DIPB => "0" );
    end generate;

    s9_s18: if (G_PORTA_DWIDTH = 8) and (G_PORTB_DWIDTH = 16) generate
        bram_inst : RAMB16_S9_S18
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB, DIPA => "0", DIPB => "00" );
    end generate;

    s18_s36: if (G_PORTA_DWIDTH = 16) and (G_PORTB_DWIDTH = 32) generate
        bram_inst : RAMB16_S18_S36
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB, DIPA => "00", DIPB => "0000" );
    end generate;

    s1_s1: if (G_PORTA_DWIDTH = 1) and (G_PORTB_DWIDTH = 1) generate
        bram_inst : RAMB16_S1_S1
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB );
    end generate;

    s2_s2: if (G_PORTA_DWIDTH = 2) and (G_PORTB_DWIDTH = 2) generate
        bram_inst : RAMB16_S2_S2
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB );
    end generate;

    s4_s4: if (G_PORTA_DWIDTH = 4) and (G_PORTB_DWIDTH = 4) generate
        bram_inst : RAMB16_S4_S4
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB );
    end generate;

    s9_s9: if (G_PORTA_DWIDTH = 8) and (G_PORTB_DWIDTH = 8) generate
        bram_inst : RAMB16_S9_S9
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB, DIPA => "0", DIPB => "0" );
    end generate;

    s18_s18: if (G_PORTA_DWIDTH = 16) and (G_PORTB_DWIDTH = 16) generate
        bram_inst : RAMB16_S18_S18
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB, DIPA => "00", DIPB => "00" );
    end generate;

    s36_s36: if (G_PORTA_DWIDTH = 32) and (G_PORTB_DWIDTH = 32) generate
        bram_inst : RAMB16_S36_S36
            port map (DOA => DOA, DOB => DOB, ADDRA => ADDRA, ADDRB => ADDRB,
                      CLKA => CLKA, CLKB => CLKB, DIA => DIA, DIB => DIB,
                         ENA => ENA, ENB => ENB, SSRA => SSRA, SSRB => SSRB,
                         WEA => WEA, WEB => WEB, DIPA => "0000", DIPB => "0000" );
    end generate;

end Behavioral;

