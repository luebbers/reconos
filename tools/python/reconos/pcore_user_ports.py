#!/usr/bin/env python
#
# \file pcore.py
#
# creates ReconOS hardware threads
#
# \author     Andreas Agne <agne@upb.de>
# \date       04.10.2007
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# 
# This file is part of ReconOS (http://www.reconos.de).
# Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
# All rights reserved.
# 
# ReconOS is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
# 
# ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along
# with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
# 
# %%%RECONOS_COPYRIGHT_END%%%
#---------------------------------------------------------------------------
#

import os
import shutil

def createPCore(user_logic_name,task_number,user_port_decl_file, vhdl_files,task_name,netlist_files,header=""):
        
        pcore_name = (task_name + "_v1_%02i_b") % task_number
        reconos_version = "v2_01_a"
        ram_version = "v2_01_a"

#create user port declarations 
        #and signal mappings
        signals = []
        lines = []
        port_maps = []
        directions = []
        port_mpds = []
        starts = []
        ends = []
        is_vectors = []

        infile = open(user_port_decl_file, "r")
        line = infile.readline()

        while line:
                sig = line.partition(':')[0]
                type = line.partition(':')[2]
                type = type.lstrip()
                direction = type.partition(' ')[0]
                type = type.partition(' ')[2]
                dimension = type.partition("vector")[2]
                if dimension != "":
                        is_vector = 1
                        v_index = dimension.partition('(')[2]
                        v_to = v_index.partition(" to ")[1]
                        if v_to != "":
                                v_start = v_index.partition(" to ")[0]
                                v_index = v_index.partition(" to ")[2]
                        else:
                                v_start = v_index.partition(" downto ")[0]
                                v_index = v_index.partition(" downto ")[2]
                        v_end = v_index.partition(')')[0]
                else:
                        is_vector = 0
                        v_start = ""
                        v_end = ""


                #print 'line= %(line)s' % vars()
                #print 'sig= %(sig)s' % vars()
                #print 'type= %(type)s' % vars()
                #print 'direction= %(direction)s' % vars()
                #print 'dimension= %(dimension)s' % vars()
                #print 'start = %(start)s' %vars()
                #print 'end = %(end)s' %vars()

                lines.append(line)
		signals.append(sig)
                directions.append(direction)
                starts.append(v_start)
                ends.append(v_end)
                is_vectors.append(is_vector)

                line = infile.readline()
        
        user_port_decl = ''.join(lines)
        for element in signals:
                port_map = '%(element)s => %(element)s,\n' %vars()
                port_maps.append(port_map)
        user_port_map = ''.join(port_maps)

        i=0
        for element in signals:
                tmp = directions[i]
                if is_vectors[i] == 1:
                        v_start = starts[i]
                        v_end = ends[i]
                        port_mpd = 'PORT %(element)s = "%(element)s", DIR = %(tmp)s, VEC = [%(v_start)s:%(v_end)s], ASSIGNMENT=REQUIRE \n' %vars()
                else:
                        port_mpd = 'PORT %(element)s = "%(element)s", DIR = %(tmp)s, ASSIGNMENT=REQUIRE\n' %vars()
                port_mpds.append(port_mpd)
                i = i+1
        user_port_mpd_str = ''.join(port_mpds)
        #print  'user_port_mpd_str= \n%(user_port_mpd_str)s' % vars()   
        #print 'signals= %(signals)s' % vars()  
        #print 'line_str= \n%(lines_str)s' % vars()     
        #print  'port_map_str= \n%(port_map_str)s' % vars()     


        #################

        bbd = """
#####
# Black-Box Description file.
# %s
#####
Files
""" % header
        #################
        
        pao = """
#####
# Peripheral Analyze Order file.
# %s
#####
lib reconos_%s reconos_pkg vhdl
lib burst_ram_%s bram_wrapper vhdl
lib burst_ram_%s ram_single vhdl
lib burst_ram_%s burst_ram vhdl
""" % (header, reconos_version,
        ram_version, ram_version, ram_version)
# pcore top level entity must be last in pao file
#lib %s %s vhdl
#""" % (pcore_name,task_name)

        #################
        mpd = """
############
# Microprocessor Peripheral Description
# %s
############

BEGIN %s

## Peripheral Options
OPTION IPTYPE = PERIPHERAL
OPTION IMP_NETLIST = TRUE
OPTION HDL = VHDL
OPTION STYLE = MIX
OPTION IP_GROUP = PPC:USER
OPTION CORE_STATE = DEVELOPMENT


## Generics for VHDL or Parameters for Verilog
PARAMETER C_BUS_BURST_AWIDTH = 14, DT = INTEGER
PARAMETER C_BUS_BURST_DWIDTH = 64, DT = INTEGER
PARAMETER C_TASK_BURST_AWIDTH = 11, DT = INTEGER
PARAMETER C_TASK_BURST_DWIDTH = 32, DT = INTEGER
PARAMETER C_REGISTER_OSIF_PORTS = 0, DT = INTEGER
PARAMETER C_DEDICATED_CLK = 0, DT = INTEGER

## Bus Interfaces
BUS_INTERFACE BUS = OSIF, BUS_TYPE = TARGET, BUS_STD = OSIF_STD

## Ports
PORT clk = "clk", DIR = I, SIGIS = Clk, BUS = OSIF
PORT reset = "reset", DIR = I, SIGIS = Rst, BUS = OSIF
PORT i_osif_flat = "osif_os2task_vec", DIR = I, VEC = [0:46], BUS = OSIF
PORT o_osif_flat = "osif_task2os_vec", DIR = O, VEC = [0:50], BUS = OSIF
PORT i_threadClk = "", DIR = I, SIGIS = Clk

##user ports
%s

#PORT TXP = "TXP", DIR = O
#PORT TXN = "TXN", DIR = O
#PORT RXP = "RXP", DIR = I
#PORT RXN = "RXN", DIR = I
#PORT MGTCLK_P = "MGTCLK_P", DIR = I
#PORT MGTCLK_N = "MGTCLK_N", DIR = I
#PORT PRE_PHY_RESET = "sys_reset_s", DIR = I
#PORT PHY_RESET = "PHY_RESET", DIR = O

# Burst RAM interface
PORT i_burstAddr = "burstAddr", DIR = I, VEC = [0:C_BUS_BURST_AWIDTH-1], BUS = OSIF
PORT i_burstData = "burstWrData", DIR = I, VEC = [0:C_BUS_BURST_DWIDTH-1], BUS = OSIF
PORT o_burstData = "burstRdData", DIR = O, VEC = [0:C_BUS_BURST_DWIDTH-1], BUS = OSIF
PORT i_burstWE = "burstWE", DIR = I, BUS = OSIF
PORT i_burstBE = "burstBE", DIR = I, VEC = [0:C_BUS_BURST_DWIDTH/8-1], BUS = OSIF

END
""" % (header,task_name, user_port_mpd_str)

        #################
        
        vhdl = """
------------
-- pcore top level wrapper
-- %s
------------
        
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_%s;
use reconos_%s.reconos_pkg.ALL;

library burst_ram_%s;
use burst_ram_%s.ALL;

library %s;
use %s.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity %s is
        generic (
                C_BUS_BURST_AWIDTH : integer := 15;      -- Note: This addresses bytes
                C_BUS_BURST_DWIDTH : integer := 64;
                C_TASK_BURST_AWIDTH : integer := 12;     -- this addresses 32Bit words
                C_TASK_BURST_DWIDTH : integer := 32;
                C_REGISTER_OSIF_PORTS : integer := 0;    -- insert registers into OSIF ports
                C_DEDICATED_CLK     : integer := 0      -- use dedicated clock input (i_threadClk) for hardware thread
        );

        port (
		%s
		--TXP                      : out std_logic;
		--TXN                      : out std_logic;
		--RXP                      : in  std_logic;
		--RXN                      : in  std_logic;

		-- SGMII-transceiver reference clock buffer input
		--MGTCLK_P                 : in  std_logic;
		--MGTCLK_N                 : in  std_logic;

		-- Asynchronous reset
		--PRE_PHY_RESET                    : in  std_logic;
		--PHY_RESET                : out std_logic;
										
                clk : in std_logic;
                reset : in std_logic;
                i_osif_flat : in std_logic_vector;
                o_osif_flat : out std_logic_vector;
                
                -- burst mem interface
                i_burstAddr : in std_logic_vector(0 to C_BUS_BURST_AWIDTH-1);
                i_burstData : in std_logic_vector(0 to C_BUS_BURST_DWIDTH-1);
                o_burstData : out std_logic_vector(0 to C_BUS_BURST_DWIDTH-1);
                i_burstWE   : in std_logic;
                i_burstBE   : in std_logic_vector(0 to C_BUS_BURST_DWIDTH/8-1);

                i_threadClk : in std_logic
        );
        
end %s;

architecture structural of %s is

        constant C_GND_TASK_DATA : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');
        constant C_GND_TASK_ADDR : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
        
        signal o_osif_flat_i : std_logic_vector(0 to C_OSIF_TASK2OS_REC_WIDTH-1);
        signal i_osif_flat_i : std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
        signal o_osif : osif_task2os_t;
        signal i_osif : osif_os2task_t;
        
        signal task2burst_Addr : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
        signal task2burst_Data : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
        signal burst2task_Data : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
        signal task2burst_WE   : std_logic;
        signal task2burst_Clk  : std_logic;

 	signal task2burst_Addr_x : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
	signal task2burst_Data_x : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
 	signal burst2task_Data_x : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
 	signal task2burst_WE_x   : std_logic;
 	signal task2burst_Clk_x  : std_logic;

        signal busy_local : std_logic;
        signal threadClk : std_logic;
        
        attribute keep_hierarchy : string;
        attribute keep_hierarchy of structural: architecture is "true";


begin

        dont_use_separate_clock : if C_DEDICATED_CLK = 0 generate
            threadClk <= clk;
        end generate;

        use_separate_clock : if C_DEDICATED_CLK /= 0 generate
            threadClk <= i_threadClk;
        end generate;

        -- connect top level signals
        dont_register_osif_ports : if C_REGISTER_OSIF_PORTS = 0 generate
            o_osif_flat <= o_osif_flat_i;
            i_osif_flat_i <= i_osif_flat;
        end generate;

        register_osif_ports : if C_REGISTER_OSIF_PORTS /= 0 generate
            register_osif_ports_proc: process(clk)
            begin
                if rising_edge(clk) then
                    o_osif_flat <= o_osif_flat_i;
                    i_osif_flat_i <= i_osif_flat;
                end if;
            end process;
        end generate;
        
        -- (un)flatten osif records
        o_osif_flat_i <= to_std_logic_vector(o_osif);
        -- overlay busy with local busy signal
        i_osif <= to_osif_os2task_t(i_osif_flat_i or (X"0000000000" & busy_local & "000000"));
        
        -- instantiate user task
        %s_i : entity %s.%s
        generic map (
            C_BURST_AWIDTH => C_TASK_BURST_AWIDTH,
            C_BURST_DWIDTH => C_TASK_BURST_DWIDTH
        )
        port map (
		%s
		--TXP => TXP,
		--TXN => TXN,
		--RXP => RXP,
		--RXN => RXN,
		--MGTCLK_P => MGTCLK_P,
		--MGTCLK_N => MGTCLK_N,
		--PRE_PHY_RESET => PRE_PHY_RESET,
		--PHY_RESET => PHY_RESET,
                clk => threadClk,
                reset => reset,
                i_osif => i_osif,
                o_osif => o_osif,
                o_RAMAddr => task2burst_Addr,
                o_RAMData => task2burst_Data,
                i_RAMData => burst2task_Data,
                o_RAMWE => task2burst_WE,
                o_RAMClk => task2burst_Clk,
		o_RAMAddr_x => task2burst_Addr_x,
		o_RAMData_x => task2burst_Data_x,
		i_RAMData_x => burst2task_Data_x,
		o_RAMWE_x => task2burst_WE_x,
		o_RAMClk_x => task2burst_Clk_x
        );
                                 
        burst_ram_i : entity burst_ram_%s.burst_ram
                generic map (
                        G_PORTA_AWIDTH => C_TASK_BURST_AWIDTH,
                        G_PORTA_DWIDTH => C_TASK_BURST_DWIDTH,
                        G_PORTA_PORTS  => 2,
                        G_PORTB_AWIDTH => C_BUS_BURST_AWIDTH-3,
                        G_PORTB_DWIDTH => C_BUS_BURST_DWIDTH,
                        G_PORTB_USE_BE => 0
                )
                port map (
                        addra => task2burst_Addr,
                        addrax => task2burst_Addr_x,
                        addrb => i_burstAddr(0 to C_BUS_BURST_AWIDTH-1 -3),             -- RAM is addressing 64Bit values
                        clka => task2burst_Clk,
                        clkax => task2burst_Clk_x,
                        clkb => clk,
                        dina => task2burst_Data,
                        dinax => task2burst_Data_x,
                        dinb => i_burstData,
                        douta => burst2task_Data,
                        doutax => burst2task_Data_x,
                        doutb => o_burstData,
                        wea => task2burst_WE,
                        weax => task2burst_WE_x,
                        web => i_burstWE,
                        ena => '1',
                        enax => '1',
                        enb => '1',
                        beb => i_burstBE
                );

        -- infer latch for local busy signal
        -- needed for asynchronous communication between thread and OSIF
        busy_local_gen : process(reset, o_osif.request, i_osif.ack)
        begin
            if reset = '1' then
                busy_local <= '0';
            elsif o_osif.request = '1' then
                busy_local <= '1';
            elsif i_osif.ack = '1' then
                busy_local <= '0';
            end if;
        end process;

end structural;
""" % (header,reconos_version,reconos_version,ram_version,ram_version,pcore_name, pcore_name,task_name,user_port_decl,task_name,task_name,user_logic_name,pcore_name,user_logic_name,user_port_map, ram_version)

        # create directory tree 
        os.mkdir(pcore_name)
        os.mkdir(pcore_name + "/data")
        os.mkdir(pcore_name + "/devl")
        os.mkdir(pcore_name + "/hdl")
        os.mkdir(pcore_name + "/hdl/vhdl")
        os.mkdir(pcore_name + "/netlist")
        
        # write template files
        pao_file = pcore_name + "/data/" + task_name + "_v2_1_0.pao"
        mpd_file = pcore_name + "/data/" + task_name + "_v2_1_0.mpd"
        bbd_file = pcore_name + "/data/" + task_name + "_v2_1_0.bbd"
        pcore_top_vhd_file = pcore_name + "/hdl/vhdl/" + task_name + ".vhd"
        open(pao_file, "w").write(pao)
        open(mpd_file, "w").write(mpd)
        open(bbd_file, "w").write(bbd)
        open(pcore_top_vhd_file, "w").write(vhdl)
        
        # link vhdl files and add entries to pao file
        for f in vhdl_files:
#               content = open(f,"r").read()
                name = os.path.basename(f)
#               open(pcore_name + "/hdl/vhdl/" + name,"w").write(content)
                if name[-4:] != ".vhd":
                        raise "error: filename '%s' does not end with '.vhd'" % name
                #os.symlink(os.path.abspath(f), pcore_name + "/hdl/vhdl/" + name)
                #os.cp(f, pcore_name + "/hdl/vhdl/" + name)
                open(pcore_name + "/hdl/vhdl/" + name,"w").write(open(f,"r").read())


                line = "lib %s %s vhdl\n" % (pcore_name,name[:-4])
                open(pao_file,"a").write(line)

        # add pcore top level wrapper to the end of pao file
        line = "lib %s %s vhdl" % (pcore_name,task_name)
        open(pao_file, "a").write(line)
        
        # copy netlists to netlist directory and add entries to bbd file
        for f in netlist_files:
                name = os.path.basename(f)
                shutil.copy(f, pcore_name + "/netlist/");
#               os.symlink(f, pcore_name + "/netlist/" + name)
                name = os.path.basename(f)
                if name[-4:] != ".edn" and name[-4:] != ".ngc":
                        raise "error: filename '%s' does not end with '.edn' or '.ngc'" % name
                line = "%s\n" % name
                open(bbd_file, "a").write(line)
        
