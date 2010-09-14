--
-- \file cpu_osif_adapter.vhd
--
-- Connects a PowerPC core to an OSIF
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

library cpu_osif_adapter_v1_04_a;
use cpu_osif_adapter_v1_04_a.ALL;

entity cpu_osif_adapter is 
generic (
        C_BASEADDR 			:     std_logic_vector := "1111111111";
        C_HIGHADDR 			:     std_logic_vector := "0000000000";     
        C_DCR_AWIDTH   		:     integer          := 10;
        C_DCR_DWIDTH  		:     integer          := 32;
        COMMANDREG_WIDTH	: 	   integer		     := 5;
        DATAREG_WIDTH		: 	   integer		     := 32;
        DONEREG_WIDTH		: 	   integer		     := 1;
        CPU_RESET_CYCLES   :     integer          := 8;
        CPU_DWIDTH         :     integer          := 32;
        C_BOOT_SECT_DATA     : std_logic_vector :=X"4bffd004"
        );
port (
    clk			    : in	  std_logic;  
    reset          : in  std_logic;
    --dcr signals for Main CPU
    o_dcrAck       : out std_logic;
    o_dcrDBus      : out std_logic_vector(0 to C_DCR_DWIDTH-1);
    i_dcrABus      : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
    i_dcrDBus      : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
    i_dcrRead      : in  std_logic;
    i_dcrWrite     : in  std_logic;
    --signals to osif
    i_osif         : in osif_os2task_t;
    o_osif         : out osif_task2os_t;
    --signal to CPU
    cpu_reset      : out std_logic;
    --debug signals
    debug_idle_state       : out std_logic;
    debug_busy_state       : out std_logic;
    debug_reconos_ready    : out std_logic;
    --signal to/from bram_logic
    boot_sect_ready        : in std_logic;
    set_boot_sect          : out std_logic;
    boot_sect_data         : out std_logic_vector(CPU_DWIDTH-1 downto 0)
    ); 
     
end cpu_osif_adapter;     
        

architecture synth of cpu_osif_adapter is
    
   -- registers
   signal cpu2os_commandreg		: std_logic_vector(COMMANDREG_WIDTH-1 downto 0);
   signal cpu2os_datareg		: std_logic_vector(DATAREG_WIDTH-1 downto 0);
   signal cpu2os_donereg		: std_logic_vector(DONEREG_WIDTH-1 downto 0);
   signal cpu2os_addrreg        : std_logic_vector(DATAREG_WIDTH-1 downto 0);
   
   signal toCPU_newcommand    : std_logic := '1'; --signals the cpu to write a new command when is '1'
   signal toCPU_debugreg	: std_logic_vector(DATAREG_WIDTH-1 downto 0);
   signal os2cpu_datareg		: std_logic_vector(DATAREG_WIDTH-1 downto 0);
   signal os2cpu_donereg		: std_logic_vector(DONEREG_WIDTH-1 downto 0);
   
   ----------------------Signals for CPU
   --help signals
   signal cpu_dcrAck     : std_logic;
   signal cpu_addresshit : std_logic;
   signal cpu_regAddr    : std_logic_vector(0 to 1);
   signal cpu_readCE     : std_logic_vector(0 to 3);
   signal cpu_writeCE    : std_logic_vector(0 to 3);
   -- to cpu
   signal to_cpu_reset   : std_logic;
   
   --------------- general signals
   signal cpu_boot_ready : std_logic;
   signal cpu_sw_reset : std_logic;
              
begin  

   cpu_addresshit <= '1' when i_dcrABus(0 to C_DCR_AWIDTH-3) = C_BASEADDR(0 to C_DCR_AWIDTH-3) else '0';
   cpu_regAddr    <= i_dcrABus(C_DCR_AWIDTH-2 to C_DCR_AWIDTH-1);
   
   cpu_reset <= to_cpu_reset;
   ---------------------------- PROCESSES  ---------------------------------------------
   
    --CPU  READ/WRITE CE generation
    ce_gen : process(cpu_addresshit, i_dcrRead, i_dcrWrite,
                     cpu_regAddr)
    begin
        -- clear all chip enables by default
        for i in 0 to 3 loop
            cpu_readCE(i)  <= '0';
            cpu_writeCE(i) <= '0';
        end loop;

        -- decode register address and set
        -- corresponding chip enable signal
        if cpu_addresshit = '1' then
            if i_dcrRead = '1' then
                cpu_readCE(TO_INTEGER(unsigned(cpu_regAddr)))  <= '1';
            elsif i_dcrWrite = '1' then
                cpu_writeCE(TO_INTEGER(unsigned(cpu_regAddr))) <= '1';
            end if;
        end if;
    end process;
   
   
   --CPU process for acknowledge signal
   gen_ack_proc : process(reset, clk)
    begin
        if reset = '1' then
            cpu_dcrAck <= '0';
        elsif rising_edge(clk) then 
            cpu_dcrAck <= (i_dcrWrite or i_dcrRead) AND cpu_addresshit;
        end if;
    end process;

    o_dcrAck <= cpu_dcrAck;
    
    
   -- CPU write process
   writereg: process(clk)
   begin
      if clk'EVENT AND clk = '1' then
         if reset = '1' OR cpu_sw_reset = '1' then
            cpu2os_commandreg <= (others => '0');
            cpu2os_addrreg    <= (others => '0');
            cpu2os_datareg    <= (others => '0');
            cpu2os_donereg    <= (others => '0');
         else
            if cpu_dcrAck = '0' then
               case cpu_writeCE(0 to 3) is
                  when "1000"  =>   --commandreg
                     cpu2os_commandreg <= i_dcrDBus((C_DCR_DWIDTH-COMMANDREG_WIDTH) to C_DCR_DWIDTH-1);
                  when "0100"  =>   --datareg
                     cpu2os_datareg <= i_dcrDBus;
                  when "0010"  =>   --donereg
                     cpu2os_donereg <= i_dcrDBus((C_DCR_DWIDTH-1)-(DONEREG_WIDTH-1) to C_DCR_DWIDTH-1);
                  when "0001" =>  --addr_reg
                     cpu2os_addrreg <= i_dcrDBus;
                  when others => NULL;
               end case;
            end if;
         end if;
      end if;
   end process;
   
   
   --CPU read process
    readreg: process (cpu_readCE, i_dcrABus, toCPU_debugreg, os2cpu_datareg, os2cpu_donereg, toCPU_newcommand)
     variable test: std_logic_vector(C_DCR_DWIDTH-4 downto 0):= (others => '0');    begin      case cpu_readCE(0 to 3) is
          when "1000"  =>   --debugreg
             o_dcrDBus <= toCPU_debugreg;
          when "0100"  =>   --datareg
             o_dcrDBus <= os2cpu_datareg;
          when "0010"  =>   --donereg
             o_dcrDBus <= (others => '0');
            when "0001" => --newcommandreg
               o_dcrDBus <= X"0000000" & "000" & toCPU_newcommand;
          when others => NULL;
       end case;    end process;
   
   ---------------- COMPONENTS  ------------------
   COMMANDS: entity cpu_osif_adapter_v1_04_a.osif_cmd_decoder
         generic map (
            COMMANDREG_WIDTH   => COMMANDREG_WIDTH,
            DATAREG_WIDTH      => DATAREG_WIDTH,
            DONEREG_WIDTH      => DONEREG_WIDTH
         )
         port map (
            clk                  => clk,  
            reset                => reset,
            --cpu2os registers
            cpu2os_commandreg    => cpu2os_commandreg,
            cpu2os_datareg       => cpu2os_datareg,
            cpu2os_addrreg         => cpu2os_addrreg,
            cpu2os_donereg       => cpu2os_donereg,
            --to cpu regs
            toCPU_newcommand     => toCPU_newcommand,
            toCPU_debugreg       => toCPU_debugreg,
            os2cpu_datareg       => os2cpu_datareg,
            --special signals
            cpu_boot_ready       => cpu_boot_ready,
            cpu_sw_reset         => cpu_sw_reset,
            --signal to osif
            cpu2os_osif_cmd      => o_osif,
            os2cpu_osif_cmd      => i_osif,
            --debug signals
            debug_idle_state     => debug_idle_state,
            debug_busy_state     => debug_busy_state,
            debug_reconos_ready  => debug_reconos_ready       
         );
         
   CPU_RST: entity cpu_osif_adapter_v1_04_a.reset_logic
         generic map(
            RESET_CYCLES => CPU_RESET_CYCLES,
            C_BOOT_SECT_DATA => C_BOOT_SECT_DATA
         )
         port map (
            clk            => clk,
            reset          => reset,
            cpu_boot_ready => cpu_boot_ready,
            cpu_sw_reset   => cpu_sw_reset,
            i_osif         => i_osif,
            --reset signal to CPU
            cpu_reset      => to_cpu_reset,
            --signals to/from bram_logic
            set_boot_sect  => set_boot_sect,
            boot_sect_data => boot_sect_data,
            boot_sect_ready => boot_sect_ready
         );
         
end synth;








