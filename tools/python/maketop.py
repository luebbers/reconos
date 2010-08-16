#!/usr/bin/env python
#
# \file maketop.py
#
# Process EDK system.vhd for partial reconfiguration
#
# Turns an EDK-generated standalone system.vhd into a top.vhd suitable for partial reconfiguration
#
# Basic steps of operation:
#
# A: recognize PR module clock(s) and instantiate
#    clock buffers for them
#
# A.1: parse component statement of PR module and
#      find clock port name (either OPB_Clk or PLB_Clk)
#
# A.2: parse component instantiation of PR module
#      and find signal connected to clock port found in
#      A.1
#
# A.3: duplicate signal found in A.2, instantiate
#      BUFG and connect original and duplicate signals
#
# -----------
#
# B: instantiate bus macros and route PR module inputs
#    and outputs through it
#
# B.1: parse component statements of PR module and
#      get ports to be routed through bus macros
#      (all but the clock(s) found in A.1)
#
# B.2: parse component instatiation of PR module and
#      get signal names for ports found in B.1
#
# B.3: duplicate signals from B.3, instantiate bus
#      macros (in and out) and connect them
#
#
# => functions:
#      parse components       returns list of ports
#      parse instantiations   returns list of signals
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

import sys, re, datetime, copy, getopt
from reconos.vhdl import *
from reconos.pr import *
from reconos.tools import *
from reconos.layout import *


osifClockPortName = "clk"
threadClockPortName = "i_threadClk"


def renameEntity(newName, lines):
	"Replaces the name of an entity in a VHDL file."

	retVal = lines[:]       # work on a copy

	# remove comments
	noCommentLines = map(stripComments, retVal)

	# 1) FIND ENTITY DECLARATION
	indexes = searchRegexInList("entity\s+\w+", noCommentLines)
	if len(indexes) == 0:
		print "ERROR: no entity declarations found!"
		return None
	if len(indexes) > 1:
		print "ERROR: multiple entity declarations found!"
		return None
	line = retVal[indexes[0]]
		
	# extract entity name
	expEntityName = re.compile("entity\s+(\w+)")
	m = expEntityName.match(line)
	entityName = m.group(1)
		
	#replace entity name
	retVal[indexes[0]] = replaceRegexInString(entityName, newName, line, re.IGNORECASE)
		
	# 2) FIND END OF ENTITY DECLARATION
	indexes = searchRegexInList("end\s+(entity\s+)?" + entityName, noCommentLines, re.IGNORECASE)
	if len(indexes) == 0:
		print "ERROR: end of entity declaration matching " + entityName + " not found!"
		return None
	if len(indexes) > 1:
		print "ERROR: too many end of entity declarations found!"
		return None
	line = retVal[indexes[0]]
		
	#replace entity name                        
	retVal[indexes[0]] = replaceRegexInString(entityName, newName, line, re.IGNORECASE)
	      
	# 3) FIND ARCHITECTURE DECLARATION
	indexes = searchRegexInList("architecture\s+\w+\s+of\s+" + entityName, noCommentLines, re.IGNORECASE)
	if len(indexes) == 0:
		print "ERROR: architecture declaration for " + entityName + " not found!"
		return None
	if len(indexes) > 1:
		print "ERROR: too many architecture declarations found!"
		return None
	line = retVal[indexes[0]]
	
	#replace entity name                        
	retVal[indexes[0]] = replaceRegexInString(entityName, newName, line, re.IGNORECASE)
		
	return retVal



def maketop(fileName, PRInstName, outputEntityName, PRSignalSuffix, reconosSlot, doBufg = True):
	  
	# open target file
   #     if outputFileName:
  #              outfile = open(outputFileName, "w")
 #       else:
#                outfile = sys.stdout                
		
	# open VHDL file and read in the lines
	infile = open(fileName, "r")
	lines = infile.readlines()
	
	# parse components, instantiations, signals
	compList = parseComponents(lines)
	instList = parseInstantiations(lines)
	signalList = parseSignals(lines)
	staticSignals = []                      # list of (port object, signal name) tuples to be connected through bus macros
	staticClocks = []
	newInstantiations = []
	
	# connect busmacro enable signals
	slotInst = getObjectByName(instList, reconosSlot.getOSIFInstName())
	slotInst.portMap["bmEnable"] = "bm_enable_" + reconosSlot.getName().lower()
	
	# get instantiation of PR module
	PRInst = getObjectByName(instList, PRInstName)
	if not PRInst:
		print "ERROR: no instance of name " + PRInstName + " found."
		print instList
		sys.exit(3)
	PRComp = getObjectByName(compList, PRInst.componentName)        # component statement           
			
	# get PR signals and change port mappings in PR module instantiations
	PRSignals = []
        osifClock = None
        threadClock = None
	for k in PRInst.portMap.keys():
	
		expIgnore = re.compile("(open|net_gnd\d+|net_vcc\d+)")          # signal names not to route through BMs or BUFGs
		if expIgnore.search(PRInst.portMap[k].lower()):              # leave port mapping unchacnged
			continue

		# decide for clock buffer or bus macro
		if "clk" in k.lower():
			# FIXME: this is quite a generalization: anything with "clk" in it's port name is assumed
			#        to be a clock
			staticClocks.append(PRInst.portMap[k])
                        # save OSIF and thread clocks (hack: distinguished by name)
                        if k == osifClockPortName:
                            osifClock = PRInst.portMap[k]
                        if k == threadClockPortName:
                            threadClock = PRInst.portMap[k]
		else:        
			# save ports names for bus macros
			p = getObjectByName(PRComp.ports, k)
			staticSignals.append((p, PRInst.portMap[k]))    # save a tuple (port, signal name) in list
		
                signalName, signalRange = separateNameFromRange(PRInst.portMap[k])
	
		s = getObjectByName(signalList, signalName)                     # find signal in signalList
		if s:
			PRSignals.append(copy.copy(s))                                     # append it to PRSignals
		else:
			print "ERROR: signal " + PRInst.portMap[k] + " not found in file."

		PRInst.portMap[k] = signalName + PRSignalSuffix + signalRange
	

        if not osifClock:
            print "ERROR: no OSIF clock found"
            sys.exit(1)
        if not threadClock:
            print "NOTE: no thread clock found, using OSIF clock"
            threadClock = osifClock

	# rename PR signals (*_module)
	for s in PRSignals:
		s.name = s.name + PRSignalSuffix

	# append the bm_enable signal
	PRSignals.append(Signal(name = "bm_enable_" + reconosSlot.getName().lower(), datatype = "std_logic"))
	
	# insert PR signals
	tmpLines = insertSignals(lines, PRSignals)
	
	# replace PR module with new instantiation
	tmpLines2 = replaceInstantiation(tmpLines, PRInstName, PRInst)
	
	# replace osif with new instantiation
	tmpLines2 = replaceInstantiation(tmpLines2, reconosSlot.getOSIFInstName(), slotInst)
	
	# declare clock buffer component (even if we have "--no-slot-bufg",
        #                                 they don't hurt)
	bufgComp = getObjectByName(compList, "BUFG")
	if not bufgComp:	# only do, if no clock buffers defined yet
		bufgComp = Component()
		bufgComp.name = "BUFG"
		bufgComp.ports = [Port("I", "in", "std_logic"), Port("O", "out", "std_logic")]

	# declare bus macro component
	bmInComp = Component()
#        bmInComp.name = "busmacro_xc4v_l2r_async_narrow"		# for Virtex 4
	bmInComp.name = "busmacro_xc2vp_l2r_async_narrow"	# for Virtex 2 Pro
	bmInComp.ports = []
	bmOutComp = Component()
#        bmOutComp.name = "busmacro_xc4v_r2l_async_enable_narrow"
	bmOutComp.name = "busmacro_xc2vp_r2l_async_enable_narrow"
	bmOutComp.ports = []
	for i in range(0, 8):
		inP = Port(name="input" + str(i), direction="in", datatype="std_logic")
		outP = Port(name="output" + str(i), direction="out", datatype="std_logic")
		enableP = Port(name="enable" + str(i), direction="in", datatype="std_logic")
		bmInComp.ports.append(inP)
		bmInComp.ports.append(outP)
		bmOutComp.ports.append(inP)
		bmOutComp.ports.append(outP)
		bmOutComp.ports.append(enableP)
		
        # FIXME: we probably don't need the bus macro component declarations,
        # since they are already in the bus macro library package.
	# insert clock buffer and bus macro component declarations
#	deltaComp = filter(lambda x: not getObjectByName(compList, x.name), [bufgComp, bmInComp, bmOutComp])
	deltaComp = filter(lambda x: not getObjectByName(compList, x.name), [bufgComp])
	if len(deltaComp) > 0:
		tmpLines2 = insertComponents(tmpLines2, deltaComp)
	
	# instantiate clock buffers 
        for c in staticClocks:
                if doBufg:
                	newInstantiations = newInstantiations + generateClockBuffers(c, PRSignalSuffix, reconosSlot)
                else:
                        n, r = separateNameFromRange(c)
                        tmpLines2 = insertVHDL(tmpLines2, n + PRSignalSuffix + r + " <= " + c + ";\n", comment="Direct assignment instead of clock buffer")
                        
	
	# generate bus macros
	newInstantiations = newInstantiations + generateBusMacros(staticSignals, PRSignalSuffix, signalList, reconosSlot, threadClock = threadClock, osifClock = osifClock)
	
	# insert new instances (bus macros, clock buffers)
	tmpLines2 = insertInstantiations(tmpLines2, newInstantiations)
	
	# rename entity, if requested
	if outputEntityName:
		tmpLines2 = renameEntity(outputEntityName, tmpLines2)
		
	# print header
	infile.close()
	outfile = open(fileName, "w")
	print >> outfile, "-------------------------------------------------------------------"
	print >> outfile, "-- file automatically generated by " + sys.argv[0]
	print >> outfile, "-- at " + datetime.datetime.today().isoformat(" ")
	print >> outfile, "-------------------------------------------------------------------"

	# show output
	for l in tmpLines2:
		if not l.strip("\n"): continue
		print >> outfile,  l,


def usage():
	print "USAGE:"
	print sys.argv[0] + " [-h] | [-e <entitiy>] -l <layout.lyt> <in.vhd>"
	print "\t-h | --help       Display this help"
	print "\t-e <entity>       Change output entity name. Optional."
	#print "\t-p <PR instance>  Name of reconfigurable module"
	print "\t-l <layout.lyt>   Name of the layout file"
        print "\t--no-slot-bufg    Do not instantiate BUFGs for the slot's clocks."
	print "\t<in.vhd>          VHDL input file (e.g. system.vhd)"
	

def insertBusMacroLib(filename, layout):
	f = open(filename,"r")
	lines = []
	while True:
		l = f.readline()
		lines.append(l)
		if not l: break;
		
	f.close()
	f = open(filename,"w")
	parsing = True
	for l in lines:
		if parsing and l.strip().lower().startswith("entity"):
			family = layout.target.getFamily()
			print >> f, "library busmacro_" + family + ";"
			print >> f, "use busmacro_" + family + ".busmacro_" + family + "_pkg.ALL;"
			print >> f
			parsing = False
		print >> f, l

def main(argv):

	# Parse command line arguments
	args = None
	try:
		opts, args = getopt.getopt(argv, "h:e:l:", ["help", "no-slot-bufg"])
	except getopt.GetoptError:
		usage()
		sys.exit(2)
	layout = None
	PRInstName = None
	outputFileName = None
	outputEntityName = None
	PRSignalSuffix = "_module"
        doBufg = True
	for opt, arg in opts:
		if opt == "-e":
			outputEntityName = arg
		if opt == "-l":
			layout = LayoutParser.read(open(arg,"r"))
                if opt == "--no-slot-bufg":
                        doBufg = False
		if opt in ("-h", "--help"):
			usage()
			sys.exit(2)

	if not layout or len(args) != 1:
		usage()
		sys.exit(1)
			
	for s in layout.slots:
                print "Processing slot '" + s.name + "'..."
        	maketop(args[0], s.name, outputEntityName, PRSignalSuffix + "_" + s.name, s,
                        doBufg)

	insertBusMacroLib(args[0], layout)



if __name__ == "__main__":
	 main(sys.argv[1:])
		
