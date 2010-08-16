--
-- \file osif_cmd_decoder.vhd
--
-- Decodes OSIF commands for the CPU-OSIF adapter
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

entity osif_cmd_decoder is 
generic (
        COMMANDREG_WIDTH	: 	  integer		   := 5;
        DATAREG_WIDTH		: 	  integer		   := 32;
        DONEREG_WIDTH		: 	  integer		   := 1
        );
port (
    clk			    	      : in	  std_logic;  
    reset          		   : in  std_logic;
    --cpu2os registers
    cpu2os_commandreg      : in  std_logic_vector(COMMANDREG_WIDTH-1 downto 0);
    cpu2os_datareg         : in  std_logic_vector(DATAREG_WIDTH-1 downto 0);
    cpu2os_addrreg         : in  std_logic_vector(DATAREG_WIDTH-1 downto 0);
    cpu2os_donereg		   : in  std_logic_vector(DONEREG_WIDTH-1 downto 0);
    toCPU_newcommand       : out std_logic;
    toCPU_debugreg         : out std_logic_vector(DATAREG_WIDTH-1 downto 0);
    os2cpu_datareg         : out std_logic_vector(DATAREG_WIDTH-1 downto 0);
    cpu_boot_ready         : out std_logic;
    cpu_sw_reset           : out std_logic;
    --signal to osif
    cpu2os_osif_cmd    	   : out osif_task2os_t;
    os2cpu_osif_cmd        : in osif_os2task_t;
    --debug signals
    debug_idle_state       : out std_logic;
    debug_busy_state       : out std_logic;
    debug_reconos_ready    : out std_logic
    ); 
     
end osif_cmd_decoder;     
        

architecture synth of osif_cmd_decoder is
      
   function bool_to_logic(boolval : boolean) return std_logic is
   begin
     if boolval then
       return '1';
     else
       return '0';
     end if;
   end;
   --------------- state machine states
   type SM_TYPE is (IDLE, BUSY, WAIT_FOR_DONEREG);
   signal state               : SM_TYPE;   
   --------------- help signals
   signal to_osif_command     : osif_task2os_t;
   signal from_osif_command   : osif_os2task_t;
   --------------- data signals
   signal init_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
               
begin  
   
   os2cpu_datareg    <= init_data;
   cpu2os_osif_cmd   <= to_osif_command;
   from_osif_command <= os2cpu_osif_cmd;
   
   ---------------------------- PROCESSES  ---------------------------------------------
   readCommand: process(clk, reset)
      variable data : std_logic_vector(DATAREG_WIDTH-1 downto 0);
      variable addr : std_logic_vector(DATAREG_WIDTH-1 downto 0);
      variable command : std_logic_vector((COMMANDREG_WIDTH-1) downto 0);
      variable done : boolean:= true;
      variable success : boolean:= true;
      variable reconos_state : reconos_state_enc_t;
   begin
      if reset = '1' then
         reconos_reset(to_osif_command, from_osif_command);
         toCPU_newcommand <= '1';
         cpu_boot_ready   <= '0';
         cpu_sw_reset <= '0';
         toCPU_debugreg   <= (others => '0');
         debug_idle_state <= '0';
         debug_busy_state <= '0';
         debug_reconos_ready <= '0';
         state <= IDLE;
      elsif rising_edge(clk) then
         
         reconos_begin(to_osif_command, from_osif_command);
         
         if reconos_ready(from_osif_command) then
            debug_reconos_ready <= '1';
            
            case state is
               
               when IDLE =>
                  debug_idle_state <= '1';
                  debug_busy_state <= '0';
                  toCPU_debugreg <= X"dead0"& '0' & to_osif_command.error & to_osif_command.request &from_osif_command.blocking & from_osif_command.busy & from_osif_command.ack & bool_to_logic(done) & bool_to_logic(success) & "0001";
                  cpu_boot_ready <= '0';
                  cpu_sw_reset <= '0';
                  
                  if cpu2os_donereg = "1" then
                     data := cpu2os_datareg;
                     command := cpu2os_commandreg;
                     addr:= cpu2os_addrreg;
                     toCPU_newcommand <= '0';
                     state <= BUSY;
                  -- test for direct commands without handshake(set donereg='1', wait until toCPU_newcommand, set donereg='0')
                  elsif cpu2os_commandreg = "00110" then
                      --BOOT_READY which indicates that the CPU has arrived the main
                      -- function. Now the cpu_boot_ready signal is set to signal this to the bram_logic
                      cpu_boot_ready <= '1';
                      state <= IDLE;
                  elsif cpu2os_commandreg = "00111" then
                      cpu_sw_reset <= '1';
                      state <= IDLE;
                  else
                     toCPU_newcommand <= '1';
                     state <= IDLE;
                  end if;
               
               when BUSY =>
                  debug_idle_state <= '0';
                  debug_busy_state <= '1';
                  cpu_boot_ready   <= '0';
                  cpu_sw_reset <= '0';
                  --check which command
                  case command(4 downto 0) is
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(1, COMMANDREG_WIDTH)) =>
                       reconos_get_init_data_s (done, to_osif_command, from_osif_command, init_data);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(2, COMMANDREG_WIDTH)) =>
                       --reconos_write(done, to_osif_command, from_osif_command, addr, data);
                        reconos_mutex_release(to_osif_command, from_osif_command, addr);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(3, COMMANDREG_WIDTH)) =>
                       --reconos_read_s(done, to_osif_command, from_osif_command, addr, init_data);
                       reconos_mutex_trylock(done, success, to_osif_command, from_osif_command, addr);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(4, COMMANDREG_WIDTH)) =>
                       reconos_mutex_lock (done, success, to_osif_command, from_osif_command, addr);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(5, COMMANDREG_WIDTH)) =>
                       reconos_mutex_unlock (to_osif_command, from_osif_command, addr);
                    -- 6 is reserved for BOOT_READY
                    -- 7 is reserved for CPU_HWT softwarereset
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(8, COMMANDREG_WIDTH)) =>
                       reconos_sem_post(to_osif_command, from_osif_command, addr); 
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(9, COMMANDREG_WIDTH)) =>
                       reconos_sem_wait(to_osif_command, from_osif_command, addr);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(10, COMMANDREG_WIDTH)) =>
                      reconos_cond_signal(to_osif_command, from_osif_command, addr);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(11, COMMANDREG_WIDTH)) =>
                      reconos_cond_broadcast(to_osif_command, from_osif_command, addr);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(12, COMMANDREG_WIDTH)) =>
                      reconos_cond_wait(done, success, to_osif_command, from_osif_command, addr);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(13, COMMANDREG_WIDTH)) =>
                       reconos_mbox_get_s(done, success, to_osif_command, from_osif_command, addr, init_data);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(14, COMMANDREG_WIDTH)) =>
                       reconos_mbox_put(done, success, to_osif_command, from_osif_command, addr, data);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(15, COMMANDREG_WIDTH)) =>
                      reconos_mbox_tryget_s(done, success, to_osif_command, from_osif_command, addr, init_data);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(16, COMMANDREG_WIDTH)) =>
                      reconos_mbox_tryput(done, success, to_osif_command, from_osif_command, addr, data);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(17, COMMANDREG_WIDTH)) =>
                      reconos_thread_resume(done, success, to_osif_command, from_osif_command, reconos_state);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(18, COMMANDREG_WIDTH)) =>
                      reconos_thread_exit(to_osif_command, from_osif_command, data);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(19, COMMANDREG_WIDTH)) =>
                      reconos_thread_delay(to_osif_command, from_osif_command, data);
                    when STD_LOGIC_VECTOR(TO_UNSIGNED(20, COMMANDREG_WIDTH)) =>
                      reconos_thread_yield(to_osif_command, from_osif_command, data);
                    when others => NULL; 
                  end case; --command
                  
               if done and success then
                  toCPU_debugreg <= X"dead0"& '0' & to_osif_command.error & to_osif_command.request &from_osif_command.blocking & from_osif_command.busy & from_osif_command.ack& bool_to_logic(done) & bool_to_logic(success) & "0011";
                  state <= WAIT_FOR_DONEREG;
               else
                  toCPU_debugreg <= X"dead0"& '0' & to_osif_command.error & to_osif_command.request &from_osif_command.blocking & from_osif_command.busy & from_osif_command.ack & bool_to_logic(done) & bool_to_logic(success) & "0100";
                   toCPU_newcommand <= '0';
                   state <= BUSY;
               end if;
               
               --CPU reads the toCPU_newcommand and then sets the donereg to '0'
               --After that the statemachine goes to IDLE state to be ready for
               --new commands
               when WAIT_FOR_DONEREG =>
                  cpu_boot_ready   <= '0';
                  cpu_sw_reset <= '0';
                  debug_idle_state <= '0';
                  debug_busy_state <= '0';
                  toCPU_debugreg <= X"dead0"& '0' & to_osif_command.error & to_osif_command.request &from_osif_command.blocking & from_osif_command.busy & from_osif_command.ack & bool_to_logic(done) & bool_to_logic(success) & "1000";
                  toCPU_newcommand <= '1';
                  if cpu2os_donereg = "0" then
                     state <= IDLE;
                  else
                     state <= WAIT_FOR_DONEREG;
                  end if;
               
               when others =>
                  --null;
                  toCPU_debugreg <= X"deadffff";
                  
            end case; --state
            
         else
            debug_reconos_ready <= '0';
         end if; --reconos_ready
      end if; --reset or rising_edge
   end process;
    
   
end synth;








