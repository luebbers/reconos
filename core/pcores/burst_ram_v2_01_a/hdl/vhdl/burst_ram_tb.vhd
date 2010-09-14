--
-- \file burst_ram_tb.vhd
--
-- Test bench for ReconOS hardware thread burst RAMs
--
-- \author     Enno Luebbers <luebbers@reconos.de>
-- \date       10.10.2008
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

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity burst_ram_tb is
    generic (
        G_PORTA_AWIDTH : integer := 12;
        G_PORTA_DWIDTH : integer := 32;			-- this is fixed!
        G_PORTA_PORTS  : integer := 1;
        G_PORTB_AWIDTH   : integer := 11;
        G_PORTB_DWIDTH   : integer := 64;		-- this is fixed!
      G_PORTB_USE_BE   : integer := 1
    );
end burst_ram_tb;

architecture Behavioral of burst_ram_tb is

    constant CLK_T : time := 10 ns;

    component burst_ram is
        generic (
            -- address and data widths, THREAD-side and OSIF-side
            G_PORTA_AWIDTH : integer := 12;
            G_PORTA_DWIDTH : integer := 32;			-- this is fixed!
            G_PORTA_PORTS  : integer := 1;
            G_PORTB_AWIDTH   : integer := 11;
            G_PORTB_DWIDTH   : integer := 64;		-- this is fixed!
                        G_PORTB_USE_BE   : integer := 1
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
            enax  : in  std_logic;
            enb   : in  std_logic;
            beb   : in  std_logic_vector(G_PORTB_DWIDTH/8-1 downto 0)
        );
    
    end component;


    signal addra : std_logic_vector(G_PORTA_AWIDTH-1 downto 0) := (others => '0');
    signal addrax: std_logic_vector(G_PORTA_AWIDTH-1 downto 0) := (others => '0');
    signal addrb : std_logic_vector(G_PORTB_AWIDTH-1 downto 0) := (others => '0');
    signal clka  : std_logic := '0';
    signal clkax : std_logic := '0';
    signal clkb  : std_logic := '0';
    signal dina  : std_logic_vector(G_PORTA_DWIDTH-1 downto 0) := (others => '0');
    signal dinax : std_logic_vector(G_PORTA_DWIDTH-1 downto 0) := (others => '0');
    signal dinb  : std_logic_vector(G_PORTB_DWIDTH-1 downto 0) := (others => '0');
    signal douta : std_logic_vector(G_PORTA_DWIDTH-1 downto 0) := (others => '0');
    signal doutax: std_logic_vector(G_PORTA_DWIDTH-1 downto 0) := (others => '0');
    signal doutb : std_logic_vector(G_PORTB_DWIDTH-1 downto 0) := (others => '0');
    signal wea   : std_logic := '0';
    signal weax  : std_logic := '0';
    signal web   : std_logic := '0';
    signal ena   : std_logic := '0';
    signal enax   : std_logic := '0';
    signal enb   : std_logic := '0';
    signal beb   : std_logic_vector(7 downto 0) := (others => '1');

    signal expecteda : std_logic_vector(G_PORTA_DWIDTH-1 downto 0);
    signal expectedax : std_logic_vector(G_PORTA_DWIDTH-1 downto 0);
    signal expectedb : std_logic_vector(G_PORTB_DWIDTH-1 downto 0);
    
begin

    dut : burst_ram
        generic map (
            G_PORTA_AWIDTH => G_PORTA_AWIDTH,
            G_PORTA_DWIDTH => G_PORTA_DWIDTH,
            G_PORTA_PORTS => G_PORTA_PORTS,
            G_PORTB_AWIDTH => G_PORTB_AWIDTH,
            G_PORTB_DWIDTH => G_PORTB_DWIDTH
        )
        port map (
            addra => addra,
            addrax => addrax,
            addrb => addrb,
            clka => clka,
            clkax => clkax,
            clkb => clkb,
            dina => dina,
            dinax => dinax,
            dinb => dinb,
            douta => douta,
            doutax => doutax,
            doutb => doutb,
            wea => wea,
            weax => weax,
            web => web,
            ena => ena,
            enax => enax,
            enb => enb,
            beb => beb
        );

    clock_gen : process
    begin
        wait for CLK_T/2;
        clka <= not clka;
    end process;
    clkax <= clka;
    clkb <= clka;
    
    test_proc : process
        variable checka : std_logic_vector(G_PORTA_DWIDTH-1 downto 0);
        variable checkax : std_logic_vector(G_PORTA_DWIDTH-1 downto 0);
        variable checkb : std_logic_vector(G_PORTB_DWIDTH-1 downto 0);
    begin

        -- write each 8-bitmemory cell on PORTA(X) with it's address
        for i in 0 to 2**G_PORTA_AWIDTH-1 loop
            wait until rising_edge(clka);
            addra <= std_logic_vector(to_unsigned(i, G_PORTA_AWIDTH));
            for j in 0 to G_PORTA_DWIDTH/8-1 loop
                dina((j+1)*8-1 downto j*8) <= std_logic_vector(to_unsigned((i*G_PORTA_DWIDTH/8+j) mod 256, 8));
            end loop;
            ena <= '1';
            wea <= '1';
            if G_PORTA_PORTS = 2 then
                addrax <= std_logic_vector(to_unsigned(i, G_PORTA_AWIDTH));
                for j in 0 to G_PORTA_DWIDTH/8-1 loop
                    dinax((j+1)*8-1 downto j*8) <= std_logic_vector(to_unsigned((i*G_PORTA_DWIDTH/8+j+2**G_PORTA_AWIDTH) mod 256, 8));
                end loop;
                enax <= '1';
                weax <= '1';
            end if;
        end loop;
        wait until rising_edge(clka);
        wea <= '0';
        weax <= '0';
        ena <= '0';
        enax <= '0';
        
        
        -- read each 8-bit memory cell on PORTB and check it for correctness
        for i in 0 to 2**G_PORTB_AWIDTH-1 loop
            wait until rising_edge(clkb);
            addrb <= std_logic_vector(to_unsigned(i, G_PORTB_AWIDTH));
            enb <= '1';
            for j in 0 to G_PORTB_DWIDTH/8-1 loop
                checkb((j+1)*8-1 downto j*8) := std_logic_vector(to_unsigned((i*G_PORTB_DWIDTH/8+j) mod 256, 8));
                expectedb <= checkb;
            end loop;
            wait until rising_edge(clkb);
            wait until rising_edge(clkb);
            assert checkb = doutb report "Read data mismatch on port B" severity WARNING;
        end loop;
        wait until rising_edge(clka);
        enb <= '0';
        

        -- write each 8-bit memory cell on PORTB with it's address (inverted)


        -- check each 8-bit memory cell on PORTA(X) with it's address (inverted)
        for i in 0 to 2**G_PORTA_AWIDTH-1 loop
            wait until rising_edge(clka);
            addra <= std_logic_vector(to_unsigned(i, G_PORTA_AWIDTH));
            ena <= '1';
            for j in 0 to G_PORTA_DWIDTH/8-1 loop
                checka((j+1)*8-1 downto j*8) := std_logic_vector(to_unsigned((i*G_PORTA_DWIDTH/8+j) mod 256, 8));
                expecteda <= checka;
            end loop;
            wait until rising_edge(clka);
            wait until rising_edge(clka);
            assert checka = douta report "Read data mismatch on port A" severity WARNING;

            if G_PORTA_PORTS = 2 then
                addrax <= std_logic_vector(to_unsigned(i, G_PORTA_AWIDTH));
                enax <= '1';
                for j in 0 to G_PORTA_DWIDTH/8-1 loop
                    checkax((j+1)*8-1 downto j*8) := std_logic_vector(to_unsigned((i*G_PORTA_DWIDTH/8+j+2**G_PORTA_AWIDTH) mod 256, 8));
                    expectedax <= checkax;
                end loop;
                wait until rising_edge(clka);
                wait until rising_edge(clka);
                assert checka = douta report "Read data mismatch on port AX" severity WARNING;
            end if;
        end loop;
        wait until rising_edge(clka);
        ena <= '0';
        enax <= '0';
        


        
    end process;
    
    
end Behavioral;

