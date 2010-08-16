#!/usr/bin/env python
#
# \file mkbfmsim.py
#
# creates a BFM simulation model from a user task
#
# \author     Enno Luebbers <luebbers@reconos.de>
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

import getopt
import os
import re
import reconos.vhdl
import shutil
import sys

reconos_version = os.environ["RECONOS_VER"];
ram_version = reconos_version;

supportedPLBVersions =      ('34', '46')
bfmsimTemplateDir =         {'34': "/support/templates/bfmsim_plb_osif_v2_01_a",
                             '46': "/support/templates/bfmsim_xps_osif_" + reconos_version}
bfmsimTestbenchTemplate =   {'34': "bfmsim/pcores/osif_tb_v1_00_c/simhdl/vhdl/osif_tb.vhd.template",
                             '46': "bfmsim/pcores/xps_osif_tb_" + reconos_version + "/simhdl/vhdl/xps_osif_tb.vhd.template"}
bfmsimTestbench =           {'34': "bfmsim/pcores/osif_tb_v1_00_c/simhdl/vhdl/osif_tb.vhd",
                             '46': "bfmsim/pcores/xps_osif_tb_" + reconos_version + "/simhdl/vhdl/xps_osif_tb.vhd"}
bfmsimBFMSystemDoTemplate = {'34': "bfmsim/simulation/behavioral/bfm_system.do.template",
                             '46': "bfmsim/simulation/behavioral/bfm_system.do.template"}
bfmsimBFMSystemDo =         {'34': "bfmsim/simulation/behavioral/bfm_system.do",
                             '46': "bfmsim/simulation/behavioral/bfm_system.do"}
bfmsimTestbenchEntity =     {'34': "osif_tb_v1_00_c",
                             '46': "xps_osif_tb_" + reconos_version}

# the order is important!
slotVhdFiles = {'34': ("fifo_mgr.vhd", "bus_master.vhd", "bus_slave_regs.vhd", "dcr_slave_regs.vhd", "command_decoder.vhd", "user_logic.vhd", "mem_plb34.vhd", "osif.vhd"),
                '46': ("fifo_mgr.vhd", "dcr_slave_regs.vhd", "command_decoder.vhd", "user_logic.vhd", "mem_plb46.vhd", "xps_osif.vhd")}


#----------------------------------------------------
# exitUsage: prints usage
#----------------------------------------------------
def exitUsage():
    scriptName = os.path.basename(sys.argv[0])
    sys.stderr.write("Usage: %s -e thread_entity [-v] [ -X ise_simlib_dir ]\\\n" % scriptName)
    sys.stderr.write("       %s [ -E edk_simlib_dir ] [-V PLB version] vhdl_files...\n\n" % (" "*len(scriptName)))
    sys.stderr.write("           -e user_logic_entity   Name of thread entity to simulate\n")
    sys.stderr.write("           -X ise_simlib_dir      Location of ISE simulation libraries\n")
    sys.stderr.write("                                      (Default: $ISE_LIB)\n")
    sys.stderr.write("           -E edk_simlib_dir      Location of EDK simulation libraries\n")
    sys.stderr.write("                                      (Default: $EDK_LIB)\n")
    sys.stderr.write("           -V PLB version         Version of PLB to use for simulation\n")
    sys.stderr.write("                                      (Default: 46)\n")
    sys.stderr.write("                                      Possible values: " + str(supportedPLBVersions) + "\n")
    sys.stderr.write("           -v                     Verbose output\n")
    sys.exit(1)


#----------------------------------------------------
# main program
#----------------------------------------------------
if __name__ == "__main__":
    
    if not ("RECONOS" in os.environ):
        sys.stderr.write("RECONOS environment variable not set.\n")
        sys.exit(1)
    
    # parse command line arguments
    args = None
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hve:X:E:V:", ["--help"])
    except getopt.GetoptError:
        exitUsage()
        
    # get standard simulation directories from environment
    try:
        ISELib = os.environ["ISE_LIB"]
    except KeyError:
        ISELib = None

    try:
        EDKLib = os.environ["EDK_LIB"]
    except KeyError:
        EDKLib = None

    # set other defaults
    userLogicName = None
    PLBVersion = '46'
    verbose = False
    
    # retrieve options from parsed arguments
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            exitUsage()
        if opt == '-e':
            userLogicName = arg
        if opt == '-X':
            ISELib = arg
        if opt == '-E':
            EDKLib = arg
        if opt == '-V':
            PLBVersion = arg
        if opt == '-v':
            verbose = True
    
    # remaining arguments are task VHDL files
    taskVhdFiles = args

    # check options for plausibility
    if not os.path.isdir(ISELib):
        sys.stderr.write("ISELib dir '%s' is not a directory (argument -X).\n" % ISELib)
        sys.exit(1)
    if not os.path.isdir(EDKLib):
        sys.stderr.write("EDKLib dir '%s' is not a directory (argument 3).\n" % EDKLib)
        sys.exit(1)
    if userLogicName == None:
        sys.stderr.write("No user logic entity name given.\n")
        exitUsage()
    if len(taskVhdFiles) == 0:
        sys.stderr.write("No user thread VHDL files given.\n")
        exitUsage()
    if PLBVersion not in supportedPLBVersions:
        sys.stderr.write("PLB version " + PLBVersion + " not supported. Possible Values:\n")
        sys.stderr.write("    " + str(supportedPLBVersions) + "\n")
       
    # print options, if verbose 
    if verbose:
        sys.stderr.write("Using the following options:\n")
        sys.stderr.write("    ISELib: " + ISELib + "\n")
        sys.stderr.write("    EDKLib: " + EDKLib + "\n")
        sys.stderr.write("    PLB version: " + PLBVersion + "\n")
        sys.stderr.write("    User logic entity: " + userLogicName + "\n")
        sys.stderr.write("    Task VHDL files: " + str(taskVhdFiles) + "\n")
            
    # generate BFM simulation
    userTaskString = """
    task_0_inst: entity work.%s
    generic map (
        C_BURST_AWIDTH => 12,
        C_BURST_DWIDTH => 32
    )
    port map (
        clk => task_clk,
        reset => task_reset,
        i_osif => task_os2task,
        o_osif => task_task2os,
        o_RAMAddr => task2burst_Addr,
        o_RAMData => task2burst_Data,
        i_RAMData => burst2task_Data,
        o_RAMWE => task2burst_WE
    );
""" % userLogicName
    
    # copy template bfmsim directory structure
    print "Copying simulation support files to ./bfmsim ..."
    shutil.copytree(os.environ["RECONOS"] + bfmsimTemplateDir[PLBVersion], "bfmsim")
    
    # insert user task instantiation into testbench
    print "Creating testbench..."
    testbenchTemplate = open(bfmsimTestbenchTemplate[PLBVersion], "r")
    testbenchFile = open(bfmsimTestbench[PLBVersion], "w")
    expUserTask = re.compile("-- %%%USER_TASK%%%");
    for line in testbenchTemplate.readlines():
        if expUserTask.match(line):
            testbenchFile.write(userTaskString)
        else:
            testbenchFile.write(line)
    
    # insert library mappings and source files into simulation script
    print "Modifying simulation script..."
    bfmSystemDoTemplate = open(bfmsimBFMSystemDoTemplate[PLBVersion], "r")
    bfmSystemDoFile = open(bfmsimBFMSystemDo[PLBVersion], "w")
    expSlotLib = re.compile("#%%%LIB_OSIF%%%");
    expTestLib = re.compile("#%%%LIB_TEST%%%");
    expSlotVhd = re.compile("#%%%VHD_OSIF%%%");
    expTestVhd = re.compile("#%%%VHD_TEST%%%");
    expTaskVhd = re.compile("#%%%VHD_HW_TASK%%%");
    expISELib = re.compile("%%%ISE_SIMLIB%%%");
    expEDKLib = re.compile("%%%EDK_SIMLIB%%%");
    for line in bfmSystemDoTemplate.readlines():
        if expSlotLib.match(line):
            print "\tInserting slot libraries..."
            bfmSystemDoFile.write("vlib osif_%s\n" % reconos_version)
            bfmSystemDoFile.write("vmap osif_%s osif_%s\n" % (reconos_version,reconos_version) )
            bfmSystemDoFile.write("vlib reconos_%s\n" % reconos_version)
            bfmSystemDoFile.write("vmap reconos_%s reconos_%s\n" % (reconos_version, reconos_version) )
        # elif expTestLib.match(line):
        #     print "\tInserting testbench libraries..."
        #     bfmSystemDoFile.write("vlib burst_ram_%s\n" % ram_version)
        #     bfmSystemDoFile.write("vmap burst_ram_%s burst_ram_%s\n" % (ram_version,ram_version) )
        elif expSlotVhd.match(line):
            print "\tInserting slot HDL files..."
            bfmSystemDoFile.write("vcom -93 -work reconos_%s " % reconos_version + 
                              os.environ["RECONOS"] + 
                              "/hw/pcores/reconos_%s/hdl/vhdl/reconos_pkg.vhd\n" % reconos_version)
            for f in slotVhdFiles:
                bfmSystemDoFile.write(("vcom -93 -work osif_%s " % reconos_version) + 
                              os.environ["RECONOS"] + 
                              ("/hw/pcores/osif_%s/hdl/vhdl/" % reconos_version) + 
                              f + "\n")
        elif expTestVhd.match(line):
            print "\tInserting additional testbench HDL files..."
            # for f in ramVhdFiles:
            #     bfmSystemDoFile.write("vcom -93 -work burst_ram_" + ram_version + 
            #                   " " + os.environ["RECONOS"] + 
            #                   "/hw/pcores/burst_ram_" + ram_version + 
            #                   "/hdl/vhdl/" + f + "\n")
            bfmSystemDoFile.write("vcom -93 -work " + bfmsimTestbenchEntity[PLBVersion] + " " + 
                              os.environ["RECONOS"] + 
                              "/hw/templates/coregen/fifo/fifo.vhd\n")
        elif expTaskVhd.match(line):
            print "\tInserting thread HDL files..."
            for f in taskVhdFiles:
                if (f[0] == '/') or (f[0] == "~"):  # absolute path
                    bfmSystemDoFile.write("vcom -93 -work " + bfmsimTestbenchEntity[PLBVersion] + " " + 
                              f + "\n")
                else:
                    bfmSystemDoFile.write("vcom -93 -work " + bfmsimTestbenchEntity[PLBVersion] + " " + 
                                  "../../../" + f + "\n")
        elif expISELib.search(line):
            bfmSystemDoFile.write(expISELib.sub(ISELib, line))
        elif expEDKLib.search(line):
            bfmSystemDoFile.write(expEDKLib.sub(EDKLib, line))
        else:
            bfmSystemDoFile.write(line)
    
    print """
Simulation setup done. You now have all BFL simulation files under the
'bfmsim' directory. You may change your task HDL files"""
    for f in taskVhdFiles:
        print "\t" + os.path.basename(f)
    print """at any time without having to regenerate the directory.
However, if you add files to your task, rerun this script with all HDL files
on the command line.

Before you can run the simulation, set up your OS stimuli by editing the
bfmsim/scripts/sample.sst file. Then, use update_tb.sh to update the testbench
with that file:
    cd bfmsim/scripts
    ./update_tb.sh

If you want to specify the contents of the simulated RAM, more work is required.
See the ReconOS wiki for details.

Finally, you might want to adjust the default simulation run time in 
bfmsim/scripts/run.do.

Run the simulation:
    cd bfmsim/simulation/behavioral
    vsim -do ../../scripts/run.do
"""
