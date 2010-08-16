--
-- \file reset_logic.vhd
--
-- Used to reset the PowerPC core after loading a new thread
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

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity reset_logic is 
generic (    RESET_CYCLES     : integer := 8;
    CPU_DWIDTH       : integer := 32;
    C_BOOT_SECT_DATA   : std_logic_vector :=X"4bffd004");
port (
    clk			    : in	std_logic;  
    reset          : in std_logic;
    cpu_boot_ready : in std_logic;
    cpu_sw_reset   : in std_logic;
    i_osif         : in osif_os2task_t;
    --reset signal to CPU
    cpu_reset      : out std_logic;
    --signals to/from bram_logic
    set_boot_sect  : out std_logic;
    boot_sect_data : out std_logic_vector(CPU_DWIDTH-1 downto 0);
    boot_sect_ready: in std_logic
    
    ); 
end reset_logic;
    
architecture synth of reset_logic is
   
   signal set_reset : std_logic;
   
   --------------- state machine states
   type SM_TYPE is (IDLE, CPU_RST, WAIT_UNTIL_CPU_READY, WAIT_TO_WRITE_BOOTCODE);
   signal state               : SM_TYPE;   

begin
   
   --SET_RESET creation
   setReset: process(reset, clk, cpu_sw_reset)
      variable reset_active : boolean:= false;
   begin
      if rising_edge(clk) then
          if (reset = '1' OR cpu_sw_reset = '1') AND reset_active= false then
             set_reset <= '1';
             reset_active:= true;
          else
             if reset_active= true then
                if reconos_ready(i_osif) then --if system ready, CPU can start
                   set_reset <= '0';
                   reset_active:= false;
                else
                   set_reset <= '1';
                end if;-- reconos_ready
             else
                set_reset <= '0';
             end if; -- reset_active
          end if; --reset
      end if; --clk
   end process;

   rstLogic: process(clk, reset)
      variable counter : integer := 0;
   begin
      if reset = '1' then
         cpu_reset <= '0';
         state <= IDLE;
         set_boot_sect <= '0';
      elsif rising_edge(clk) then
         case state is
            
            when IDLE =>
               set_boot_sect <= '0';
               boot_sect_data <= (others => '0');
               if set_reset = '1' then
                  cpu_reset <= '1';
                  counter:= 1;
                  state <= WAIT_TO_WRITE_BOOTCODE; 
               else
                  cpu_reset <= '0';
                  state <= IDLE;
               end if;
            
            when WAIT_TO_WRITE_BOOTCODE =>
               if set_reset = '1' then
                  set_boot_sect <= '0';
                  boot_sect_data <= (others => '0');
                  counter:= counter + 1;
                  cpu_reset <= '1';
                  state <= WAIT_TO_WRITE_BOOTCODE;
               else
                  set_boot_sect <= '1'; --Now bram_logic writes bootcode and waits until value is set to '0' (in this time no other bootcode for another cpu is written)
                  boot_sect_data <= C_BOOT_SECT_DATA;
                  counter:= counter + 1;
                  cpu_reset <= '1';
                  state <= CPU_RST;
               end if;
               
            when CPU_RST =>
               set_boot_sect <= '1';
                  if counter > RESET_CYCLES AND boot_sect_ready = '1' then
                     cpu_reset <= '0';
                     state <= WAIT_UNTIL_CPU_READY;
                  else
                     cpu_reset <= '1';
                     counter:= counter + 1;
                     state <= CPU_RST;
                  end if; -- counter > RESET_CYCLES
            
            when WAIT_UNTIL_CPU_READY =>
                  if cpu_boot_ready = '1' then
                     set_boot_sect <= '0'; 
                     state <= IDLE;
                  else
                     set_boot_sect <= '1';
                     state <= WAIT_UNTIL_CPU_READY;
                  end if;
            
            when others =>
               null;
               
         end case;
      
      end if; --reset / rising_edge
   end process;

end synth;
