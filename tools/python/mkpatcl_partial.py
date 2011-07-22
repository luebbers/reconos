#!/usr/bin/env python
#
# \file mkpatcl.py
#
# Create a TCL input file for building ReconOS systems with
# PlanAhead
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       15.07.2011
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

import sys, os, reconos.config, getopt, datetime, reconos.layout, slop

def usage():
    print '''
USAGE: %s -p project [-o output_file]

    -p project      ReconOS project file (*.rprj) for current project
    -o output_file  write resulting TCL script to output_file
                    (print to stdout if omitted)

''' % ( os.path.basename( sys.argv[ 0 ] ) )


def createTCL():
    '''create TCL script'''
    output = '''#
# ReconOS PlanAhead TCL script
# generated on %s using the command line
#     %s %s
#
''' % (datetime.date.today(), os.path.basename(sys.argv[0]), " ".join(sys.argv[1:]))
    return output

def createPAProject():
    '''create new PlanAhead project'''
    global paProjectName, paProjectDir, layout,paTopLevelNetlistFileName
    global paNetlistDir, paConstraintsFileName, paConfigNamePrefix
    output = """\
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
    return output

def openPAProject():
    output = """\
open_project %s/%s.ppr
""" % (paProjectDir, paProjectName)
    return output

def openNetlist():
    '''open the design's netlist'''
    output = "open_netlist_design -name netlist_1\n"
    return output

def addFirstReconfigModules():
    '''add the first reconfigurable modules (dynamic threads) for each 
    slot'''
    global layout, dynamicThreads, dynamicThreadsNetlistFileNames 
    output = ""
    for slotNum in range(layout.getNumSlots()):
        output += """\
add_reconfig_module -name {%s} -cell {%s} -file {%s}
save_design
""" % (dynamicThreads[0], "hw_task_" + str(slotNum),
        dynamicThreadsNetlistFileNames[0])
    return output

def addReconfigModules():
    '''add all reconfigurable modules (dynamic threads)'''
    global layout, dynamicThreads, dynamicThreadsNetlistFileNames 
    output = ""
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
    return output

def addOtherReconfigModules():
    # adds reconfigurable modules other than the dummy ones
    '''add other reconfigurable modules (dynamic threads) for an extensible
    design'''
    global layout, dynamicThreads, dynamicThreadsNetlistFileNames 
    output = ""
    for slotNum in range(layout.getNumSlots()):
        for threadNum in range(1, len(dynamicThreads)):
            output += "add_reconfig_module -name {%s} -cell {%s} -file {%s}\nsave_design\n" % (
                    dynamicThreads[threadNum], "hw_task_" + str(slotNum),
                    dynamicThreadsNetlistFileNames[threadNum])
    return output

def setPblockSizes():
    global layout
    output = ""
    for slotNum in range(layout.getNumSlots()):
        slot = layout.slots[slotNum]
        output += "resize_pblock pblock_hw_task_%d -add {%s" % (slotNum,
                slot.getSliceRange())
        for rangeType in slot.ranges.keys():
            output += " " + slot.ranges[rangeType]
        output += "} -locs keep_all -replace\n"
    return output

def saveDesign():
    output = "save_design\n"
    return output

def createPartialModuleRuns():
    global dynamicThreads, layout, paConfigNamePrefix
    output = ""
    for runNum in range(len(dynamicThreads)):
        if runNum > 0: # first run already exists, create only for higher runs
            output += "create_run -name %s -part %s -srcset sources_1 -constrset constrs_1 -flow {ISE 12} -strategy {ISE Defaults}\n" % (
                    paConfigNamePrefix + str(runNum + 1), layout.target.getPart())
        output += "config_partition -run {%s} -implement\n" % (paConfigNamePrefix + str(runNum + 1))
        for slotNum in range(layout.getNumSlots()):
            output += "config_partition -run {%s} -cell {%s} -reconfig_module {%s} -implement\n" % (
                    paConfigNamePrefix + str(runNum + 1), "hw_task_" + str(slotNum),
                    dynamicThreads[runNum])
    return output

def createOtherPartialModuleRuns():
    global dynamicThreads, layout, paConfigNamePrefix
    output = ""
    for runNum in range(1, len(dynamicThreads)):
        output += "create_run -name %s -part %s -srcset sources_1 -constrset constrs_1 -flow {ISE 12} -strategy {ISE Defaults}\n" % (
                    paConfigNamePrefix + str(runNum + 1), layout.target.getPart())
        output += "config_partition -run {%s} -implement\n" % (paConfigNamePrefix + str(runNum + 1))
        for slotNum in range(layout.getNumSlots()):
            output += "config_partition -run {%s} -cell {%s} -reconfig_module {%s} -implement\n" % (
                    paConfigNamePrefix + str(runNum + 1), "hw_task_" + str(slotNum),
                    dynamicThreads[runNum])
    return output

def runPRDRC():
    output = "report_drc results_2 -rules {PRSL PRPR PRRM PROL PRGL PRGB PRIL PRAG PRCC PRLO PRRC PRSC PRLL}\n"
    return output

def launchFirstRun():
    global paProjectName, paConfigNamePrefix, numJobs, paProjectDir
    output = "launch_runs -runs %s -jobs %d -dir %s\n" % (
            paConfigNamePrefix + '1', numJobs, paProjectDir + '/' + paProjectName + ".runs")
    output += "wait_on_run %s\n" % (paConfigNamePrefix + '1')
    return output

def promotePartitions():
    global paConfigNamePrefix, layout
    output = "promote_run -run {%s} -partition_names { {system}" % (paConfigNamePrefix + '1')
    for slotNum in range(layout.getNumSlots()):
        output += " {%s}" % ("hw_task_" + str(slotNum))
    output += " }\n"
    return output

def launchOtherRuns():
    global dynamicThreads, paConfigNamePrefix, numJobs, paProjectDir, paProjectName
    output = "launch_runs -runs"
    for runNum in range(1, len(dynamicThreads)):
        output += ' ' + paConfigNamePrefix + str(runNum + 1)
    output += " -jobs %d -dir %s\n" % (
            numJobs, paProjectDir + '/' + paProjectName + ".runs")
    for runNum in range(1, len(dynamicThreads)):
        output += 'wait_on_run ' + paConfigNamePrefix + str(runNum + 1) + "\n"
    return output

def verifyConfigurations():
    global dynamicThreads, paConfigNamePrefix, hwDir
    output = "verify_config -runs {"
    for runNum in range(0, len(dynamicThreads)):
        output += ' {' + paConfigNamePrefix + str(runNum + 1) + '}'
    output += " } -file {" + hwDir + "/pr_verify.log}\n"
    return output

def verifyFirstConfiguration():
    global dynamicThreads, paConfigNamePrefix, hwDir
    output = "verify_config -runs " + paConfigNamePrefix + "1 -file {" + hwDir + "/pr_verify.log}\n"
    return output

def generateFirstBitstreams():
    global dynamicThreads, paConfigNamePrefix, paProjectDir, paProjectName
    output = 'set_property add_step Bitgen [get_runs ' + paConfigNamePrefix + "1]\n"
    output += "launch_runs -runs " + paConfigNamePrefix + "1 -jobs %d -dir %s\n" % (
            numJobs, paProjectDir + '/' + paProjectName + ".runs")
    output += 'wait_on_run ' + paConfigNamePrefix + "1\n"
    return output

def generateOtherBitstreams():
    global dynamicThreads, paConfigNamePrefix, paProjectDir, paProjectName
    output = ""
    if len(dynamicThreads) < 2:
        print "Not enough dynamic threads (minimum 2). Check your project file."
        sys.exit(2)
    for runNum in range(1, len(dynamicThreads)):
        output += 'set_property add_step Bitgen [get_runs ' + paConfigNamePrefix + str(runNum + 1) + "]\n"
    output += "launch_runs -runs {"
    for runNum in range(1, len(dynamicThreads)):
        output += ' {' + paConfigNamePrefix + str(runNum + 1) + '}'
    output += " } -jobs %d -dir %s\n" % (
            numJobs, paProjectDir + '/' + paProjectName + ".runs")
    for runNum in range(1, len(dynamicThreads)):
        output += 'wait_on_run ' + paConfigNamePrefix + str(runNum + 1) + "\n"
    return output

def generateAllBitstreams():
    global dynamicThreads, paConfigNamePrefix, paProjectDir, paProjectName
    output = ""
    for runNum in range(0, len(dynamicThreads)):
        output += 'set_property add_step Bitgen [get_runs ' + paConfigNamePrefix + str(runNum + 1) + "]\n"
    output += "launch_runs -runs {"
    for runNum in range(0, len(dynamicThreads)):
        output += ' {' + paConfigNamePrefix + str(runNum + 1) + '}'
    output += " } -jobs %d -dir %s\n" % (
            numJobs, paProjectDir + '/' + paProjectName + ".runs")
    for runNum in range(0, len(dynamicThreads)):
        output += 'wait_on_run ' + paConfigNamePrefix + str(runNum + 1) + "\n"
    return output

def removeOtherRuns():
    global dynamicThreads
    output = ""
    for runNum in range(1, len(dynamicThreads)):
        output += "delete_run -noclean_dir -run config_" + str(runNum + 1) + "\n"
    return output

def removeOtherReconfigModules():
    global dynamicThreads, layout
    output = ""
    for slotNum in range(layout.getNumSlots()):
        output += "load_reconfig_modules -reconfig_modules {hw_task_%i:%s}\n" % (slotNum, dynamicThreads[0])
        for threadNum in range(1, len(dynamicThreads)):
            output += "delete_reconfig_module -reconfig_module {hw_task_%i:%s}\n" % (slotNum, dynamicThreads[threadNum])
    return output

def exitPA():
    output = "exit\n"
    return output




#---------------------------------------------------------
# MAIN
#---------------------------------------------------------

if __name__ == "__main__":

    global paProjectName, paProjectDir, layout, paTopLevelNetlistFileName
    global paNetlistDir, paConstraintsFileName, paConfigNamePrefix
    global layout, dynamicThreads, dynamicThreadsNetlistFileNames, numJobs
    global hwDir

    # define recipes and their steps
    recipes = {
        "complete" : {
            "description" : 
"""Build and implement a complete ReconOS partially configurable design
with all dynamic threads. Results in static and dynamic bistreams.""",
            "betweenSteps" : [ ("save_design", saveDesign) ],
            "steps" : [
                ("add_reconfig_modules", addReconfigModules),
                ("set_pblock_sizes", setPblockSizes),
                ("create_runs", createPartialModuleRuns),
                ("run_pr_drc", runPRDRC),
                ("launch_first_run", launchFirstRun),
                ("promote_partitions", promotePartitions),
                ("launch_other_runs", launchOtherRuns),
                ("verify_configurations", verifyConfigurations),
                ("generate_bitstreams", generateAllBitstreams)
            ],
            "canCreate" : True
        },
        "extensible-base" : {
            "description" : 
"""Build an extensible ReconOS base design which allows to add and build
hardware threads even after creating an initial set of bitstreams.""",
            "betweenSteps" : [ ("save_design", saveDesign) ],
            "steps" : [
                ("add_first_reconfig_modules", addFirstReconfigModules),
                ("set_pblock_sizes", setPblockSizes),
                ("run_pr_drc", runPRDRC),
                ("launch_first_run", launchFirstRun),
#                ("verify_first_configuration", verifyFirstConfiguration),
                ("generate_first_bitstreams", generateFirstBitstreams),
            ],
            "canCreate" : True
        },
        "extensible-threads" : {
            "description" : 
"""Build partial bitstreams for an extensible ReconOS design.""",
            "betweenSteps" : [ ("save_design", saveDesign) ],
            "steps" : [
                ("add_other_reconfig_modules", addOtherReconfigModules),
                ("promote_partitions", promotePartitions),
                ("create_other_runs", createOtherPartialModuleRuns),
                ("launch_runs", launchOtherRuns),
                ("verify_configurations", verifyConfigurations),
                ("generate_other_bitstreams", generateOtherBitstreams),
                ("remove_other_runs", removeOtherRuns),
                ("remove_other_reconfig_modules", removeOtherReconfigModules)
            ],
            "canCreate" : False
        }
    }

    # parse command line arguments
    opts, args = slop.parse([
        ("p", "reconos_project", "ReconOS project file (*.rprj)", True, {"optional" : False}),
        ("P", "pa_project", "PlanAhead project name (directory)", True, {"default" : "project_reconos_1"}),
        ("o", "output", "Output TCL script (omit for stdout)", True),
        ("l", "list", "List all available steps and recipes and exit"),
        ("r", "recipe", "Recipe (aka workflow) to execute", True, {"default" : "complete"}),
        ("b", "begin", "Open existing project and begin with step BEGIN (omit to create a new project)", True),
        ("e", "end", "Only execute up to (and including) step END", True)
    ], banner="%prog [options] -p <project>")

    projectFileName = opts["reconos_project"]
    outputFileName = opts["output"]
    firstStep = opts["begin"]
    lastStep = opts["end"]
    paProjectName = opts["pa_project"]
    recipeName = opts["recipe"]

    if opts.list:
        # list all available recipes
        for r in recipes.keys():
            print "Recipe '" + r + "'"
            print recipes[r]["description"]
            stepNames = [ x[0] for x in recipes[r]["steps"] ]
            stepFuncs = [ x[1] for x in recipes[r]["steps"] ]
            # list all available steps
            print "Available steps:"
            for s in stepNames:
                print "    " + s
            print
        sys.exit(0)

    # check arguments for plausibility
    if len(projectFileName) < 6 or projectFileName[-5:] != ".rprj":
        print "no valid project file (use -p)"
        sys.exit(2)
    if recipeName not in recipes.keys():
        print "'%s' not a valid recipe" % recipeName
        sys.exit(2)
    steps = recipes[recipeName]["steps"] 
    betweenSteps = recipes[recipeName]["betweenSteps"] 
    stepNames = [ x[0] for x in steps ]
    stepFuncs = [ x[1] for x in steps ]
    if firstStep == None:
        firstStep = stepNames[0]
    if lastStep == None:
        lastStep = stepNames[-1]
    if firstStep not in stepNames:
        print "'%s' not a valid step in recipe '%s'" % (firstStep, recipeName)
        sys.exit(2)
    if lastStep not in stepNames:
        print "'%s' not a valid step in recipe '%s'" % (lastStep, recipeName)
        sys.exit(2)
    if stepNames.index(firstStep) > stepNames.index(lastStep):
        print "'%s' comes before '%s' in recipe '%s'" % (lastStep, firstStep, recipeName)
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
    output = createTCL()

    # open or create pa project
    # open if -b was specified or current recipe can't create projects,
    # otherwise create a new one
    if not recipes[recipeName]["canCreate"] or opts.begin:
        output += openPAProject()
    else:
        output += createPAProject()

    # open netlist
    output += openNetlist()

    # do selected steps
    firstIndex = stepNames.index(firstStep)
    lastIndex = stepNames.index(lastStep)
    for i in range(firstIndex, lastIndex+1):
        output += steps[i][1]()
        for b in betweenSteps:
            output += b[1]()

    # exit PA
    output += exitPA()

    # write output
    if opts.output:
        fout = open(outputFileName, "w")
        fout.write(output)
        fout.close()
    else:
        print output


    
