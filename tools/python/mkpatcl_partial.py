#!/usr/bin/env python
#
# \file mkpatcl_partial.py
#
# Create a TCL input file for building ReconOS partial bitstreams with
# PlanAhead
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       16.06.2011
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# 
# This file is part of ReconOS (http://www.reconos.de).
# Copyright (c) 2006-2011 The ReconOS Project and contributors (see AUTHORS).
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

import sys, os, reconos.config, getopt, datetime, reconos.layout

def usage():
    print '''
USAGE: %s -p project [-o output_file]

    -p project      ReconOS project file (*.rprj) for current project
    -o output_file  write resulting TCL script to output_file
                    (print to stdout if omitted)

''' % ( os.path.basename( sys.argv[ 0 ] ) )


if __name__ == "__main__":

    # parse command line arguments
    try:
        opts, args = getopt.getopt(sys.argv[1:], "p:o:", ["--project=",
        "--output="])
    except getopt.GetoptError, err:
            print str(err)
            usage()
            sys.exit(2)

    projectFileName = ""
    outputFileName = ""

    for o, a in opts:
        if o in ("-p", "--project"):
            projectFileName = str(a)
        elif o in ("-o", "--output"):
            outputFileName = str(a)
        else:
            assert False, "unhandled option '" + o + "'"

    # check arguments for plausibility
    if projectFileName[-5:] != ".rprj":
        print "no valid project file (use -p)"
        sys.exit(2)

    # read project file
    pc = reconos.config.ProjectConfig(projectFileName)

    # derive paths and filenames
    projectRoot = os.path.dirname(os.path.realpath(projectFileName))
    hwDir = projectRoot + '/' + pc["HW_DIR"]
    swDir = projectRoot + '/' + pc["SW_DIR"]
    layoutFileName = projectRoot + '/' + pc["LAYOUT"]
    hwThreadDir = projectRoot + '/' + pc["HW_THREAD_DIR"]
    staticThreads = pc["STATIC_THREADS"].split()
    dynamicThreads = pc["DYNAMIC_THREADS"].split()
    dynamicThreadsNetlistFileNames = [ hwThreadDir + "/" + t + ".ngc" for t in
            dynamicThreads ]
    if "NUM_JOBS" in pc.data.keys():
        numJobs = int(pc["NUM_JOBS"])
    else:
        numJobs = 2
    paProjectName = "project_reconos_1"
    paProjectDir = hwDir + "/" + paProjectName
    paTopLevelNetlistFileName = hwDir + "/edk-static/synthesis/system.ngc"
    paNetlistDir = hwDir + "/edk-static/implementation"
    paConstraintsFileName = hwDir + "/edk-static/data/system.ucf"
    paConfigNamePrefix = "config_"


    # read layout file
    layoutFile = open(layoutFileName)
    layout = reconos.layout.LayoutParser.read(layoutFile)
    layoutFile.close()

    # create TCL script
    output = '''#
# ReconOS PlanAhead TCL script for generating partial bitstreams
# generated on %s using the command line
#     %s %s
#
''' % (datetime.date.today(), os.path.basename(sys.argv[0]), " ".join(sys.argv[1:]))

    # create PlanAhead project
    output += """\
create_project %s %s -part %s -force
set_property design_mode GateLvl [get_property srcset [current_run]]
set_property edif_top_file %s [get_property srcset [current_run]]
add_files -norecurse %s
add_files -fileset [get_property constrset [current_run]] -norecurse %s
set_property target_ucf %s [get_property constrset [current_run]]
set_property name %s [current_run]
set_property is_partial_reconfig true [current_project]
""" % (paProjectName, paProjectDir, layout.target.getPart(),
       paTopLevelNetlistFileName,
       paNetlistDir,
       paConstraintsFileName,
       paConstraintsFileName,
       paConfigNamePrefix + '1')

    # open netlist
    output += "open_netlist_design -name netlist_1\n"

    # add reconfigurable modules
    for slotNum in range(layout.getNumSlots()):
        output += """\
add_reconfig_module -name {%s} -cell {%s} -file {%s}
save_design
""" % (dynamicThreads[0], "hw_task_" + str(slotNum),
        dynamicThreadsNetlistFileNames[0])
        for threadNum in range(1, len(dynamicThreads)):
            output += "add_reconfig_module -name {%s} -cell {%s} -file {%s}\n" % (
                    dynamicThreads[threadNum], "hw_task_" + str(slotNum),
                    dynamicThreadsNetlistFileNames[threadNum])

    # set pblock areas
    for slotNum in range(layout.getNumSlots()):
        slot = layout.slots[slotNum]
        output += "resize_pblock pblock_hw_task_%d -add {%s" % (slotNum,
                slot.getSliceRange())
        for rangeType in slot.ranges.keys():
            output += " " + slot.ranges[rangeType]
        output += "} -locs keep_all -replace\n"
    output += "save_design\n"

    # create runs (TODO: make it possible not to have all threads for all
    # slots)
    for runNum in range(len(dynamicThreads)):
        if runNum > 0: # first run already exists, create only for higher runs
            output += "create_run -name %s -part %s -srcset sources_1 -constrset constrs_1 -flow {ISE 12} -strategy {ISE Defaults}\n" % (
                    paConfigNamePrefix + str(runNum + 1), layout.target.getPart())
        output += "config_partition -run {%s} -implement\n" % (paConfigNamePrefix + str(runNum + 1))
        for slotNum in range(layout.getNumSlots()):
            output += "config_partition -run {%s} -cell {%s} -reconfig_module {%s} -implement\n" % (
                    paConfigNamePrefix + str(runNum + 1), "hw_task_" + str(slotNum),
                    dynamicThreads[runNum])

    # run design rule checks for partial reconfiguration
    output += "report_drc results_2 -rules {PRSL PRPR PRRM PROL PRGL PRGB PRIL PRAG PRCC PRLO PRRC PRSC PRLL}\n"

    # launch first run
    output += "launch_runs -runs %s -jobs %d -dir %s\n" % (
            paConfigNamePrefix + '1', numJobs, paProjectDir + '/' + paProjectName + ".runs")
    output += "wait_on_run %s\n" % (paConfigNamePrefix + '1')

    # promote partitions
    output += "promote_run -run {%s} -partition_names { {system}" % (paConfigNamePrefix + '1')
    for slotNum in range(layout.getNumSlots()):
        output += " {%s}" % ("hw_task_" + str(slotNum))
    output += " }\n"

    # launch other runs
    output += "launch_runs -runs"
    for runNum in range(1, len(dynamicThreads)):
        output += ' ' + paConfigNamePrefix + str(runNum + 1)
    output += " -jobs %d -dir %s\n" % (
            numJobs, paProjectDir + '/' + paProjectName + ".runs")
    for runNum in range(1, len(dynamicThreads)):
        output += 'wait_on_run ' + paConfigNamePrefix + str(runNum + 1) + "\n"

    # verify configurations
    output += "verify_config -runs {"
    for runNum in range(0, len(dynamicThreads)):
        output += ' {' + paConfigNamePrefix + str(runNum + 1) + '}'
    output += " } -file {" + hwDir + "/pr_verify.log}\n"

    # generate bitstreams
    for runNum in range(0, len(dynamicThreads)):
        output += 'set_property add_step Bitgen [get_runs ' + paConfigNamePrefix + str(runNum + 1) + "]\n"

    output += "launch_runs -runs {"
    for runNum in range(0, len(dynamicThreads)):
        output += ' {' + paConfigNamePrefix + str(runNum + 1) + '}'
    output += " } -jobs %d -dir %s\n" % (
            numJobs, paProjectDir + '/' + paProjectName + ".runs")

    for runNum in range(0, len(dynamicThreads)):
        output += 'wait_on_run ' + paConfigNamePrefix + str(runNum + 1) + "\n"

    output += "exit\n"

    # write output
    if outputFileName == "":
        print output
    else:
        fout = open(outputFileName, "w")
        fout.write(output)
        fout.close()


    
