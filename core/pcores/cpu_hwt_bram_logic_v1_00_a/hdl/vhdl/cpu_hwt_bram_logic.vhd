--
-- \file cpu_hwt_bram_logic.vhd
--
-- BRAM control logic for CPU-HW threads
--
-- This BRAM is used to store the CPU reset vectors for switching software 
-- threads.
--
-- \author     Robert Meiche <rmeiche@gmx.de>
-- \date       22.09.2009
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

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cpu_hwt_bram_logic is
generic (
        BRAM_DWIDTH         :     integer          := 64;
        BRAM_AWIDTH         :     integer          := 32;
        CPU_DWIDTH          :     integer          := 32
        );
port (
   clk             : in std_logic;
   reset           : in std_logic;
   --CPU Ports
   CPU0_boot_sect_ready        : out std_logic;
   CPU0_set_boot_sect          : in std_logic;
   CPU0_boot_sect_data         : in std_logic_vector(CPU_DWIDTH-1 downto 0);
   CPU1_boot_sect_ready        : out std_logic;
   CPU1_set_boot_sect          : in std_logic;
   CPU1_boot_sect_data         : in std_logic_vector(CPU_DWIDTH-1 downto 0);
   --BRAM Ports
    BRAM_Rst        : out  std_logic;
    BRAM_CLK        : out  std_logic;
    BRAM_EN         : out  std_logic;
    BRAM_WEN        : out  std_logic_vector(0 to BRAM_DWIDTH/8-1); --Qualified WE
    BRAM_Addr       : out  std_logic_vector(0 to BRAM_AWIDTH-1);
    BRAM_Dout       : out std_logic_vector(0 to BRAM_DWIDTH-1);
    BRAM_Din        : in  std_logic_vector(0 to BRAM_DWIDTH-1)
 ); 
     
end cpu_hwt_bram_logic;

architecture synth of cpu_hwt_bram_logic is
   signal write_bootcode : std_logic;
   signal bram_boot_data : std_logic_vector(0 to CPU_DWIDTH-1);
   signal bram_boot_addr : std_logic_vector(0 to BRAM_AWIDTH-1);
   signal ready_sigs: std_logic_vector(0 to 1); --connects the ready signals 
   signal set_sigs: std_logic_vector(0 to 1); --connects the set signals
   
   --------------- state machine states
   type SM_TYPE is (IDLE, WRITE, READY, WAIT_UNTIL_SET_ZERO);
   signal state               : SM_TYPE; 
   
begin
   
   CPU0_boot_sect_ready <= ready_sigs(0);
   CPU1_boot_sect_ready <= ready_sigs(1);
   
   set_sigs <= CPU0_set_boot_sect & CPU1_set_boot_sect;
   
   BRAM_Rst <= reset;
   BRAM_CLK <= clk;
   
   BRAMWRITE: process(clk)
   begin
      if rising_edge(clk) then
         if write_bootcode = '1' then
            BRAM_EN <= '1';
            BRAM_WEN <= "00001111";
            BRAM_Dout <= X"deadbeef" & bram_boot_data;
            BRAM_Addr <= bram_boot_addr;
         else
            BRAM_EN <= '0';
            BRAM_WEN <= "00000000";
            BRAM_Dout <= (others =>'0');
            BRAM_Addr <= (others =>'0');
         end if; --write_bootcode   
      end if;
   end process;   
   
   BRAM_LOGIC_SM: process(clk, reset)
      variable bootcode : std_logic_vector(CPU_DWIDTH-1 downto 0);
      variable whichCPU : integer;
   begin
      if reset = '1' then
         bram_boot_addr <= (others =>'0');
         bram_boot_data <= (others =>'0');
         write_bootcode <= '0';
         state <= IDLE;
         
      elsif rising_edge(clk) then
         
         case state is
            
            when IDLE =>
               write_bootcode <= '0';
               if CPU0_set_boot_sect = '1' then
                  bootcode:= CPU0_boot_sect_data;
                  whichCPU:= 0;
                  state <= WRITE;
               elsif CPU1_set_boot_sect = '1' then
                  bootcode:= CPU1_boot_sect_data;
                  whichCPU:= 1;
                  state <= WRITE;
               end if;
               
            when WRITE =>
               write_bootcode <= '1';
               bram_boot_data <= bootcode;
               bram_boot_addr <= X"FFFFFFFC";
               state <= READY;
               
            when READY =>
               write_bootcode <= '1';
               ready_sigs(whichCPU) <= '1';
               state <= WAIT_UNTIL_SET_ZERO;
               
            when WAIT_UNTIL_SET_ZERO =>
               write_bootcode <= '0';
               --after the ready signal for the corresponding CPU is set, the state machine
               --waits that the cpu set its set-signal back to zero (then the cpu has booted correctly
               -- and another CPU can now have the bootaddress 0xFFFFFFFC)
               if set_sigs(whichCPU) = '0' then
                  ready_sigs(whichCPU) <= '0';
                  state <= IDLE;
               else
                  ready_sigs(whichCPU) <= '1';
                  state <= WAIT_UNTIL_SET_ZERO;
               end if;
               
            when others => 
               state <= IDLE;
         end case;
      end if;
   end process;
end synth;
