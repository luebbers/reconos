#!/usr/bin/env python
#
# \file makeucf.py
#
# Generates ucf for partially reconfigurable designs
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

import sys, getopt
from reconos.vhdl import *
from reconos.layout import *

# FIXME: this works only for up to two slots!
# and both slots need to be in different quadrants
# of the device!
bufgmux_locations_xc2vp = ["BUFGMUX0P", "BUFGMUX1S", "BUFGMUX2P", "BUFGMUX3S"]
# for virtex4 just use all 32 BUFGCTRLs in ascending order
bufgmux_locations_xc4v = ["BUFGCTRL_X0Y%d" % x for x in range(0,32)]
bufgmux_locations = {"xc2vp": bufgmux_locations_xc2vp, "xc4v": bufgmux_locations_xc4v}

def main(argv):

        # Parse command line arguments
        try:
                opts, args = getopt.getopt(argv, "hso:l:t:", ["help","static"])
        except getopt.GetoptError:
                usage()
                sys.exit(2)
        layout = None
        outputFileName = None
        topFileName = None
        static = False;
        for opt, arg in opts:
                if opt == "-o":
                        outputFileName = arg
                if opt == "-l":
                        layout = LayoutParser.read(open(arg,"r"))
                if opt == "-t":
                        topFileName = arg
                if opt in ("-s", "--static"):
                        static = True;
                if opt in ("-h", "--help"):
                        usage()
                        sys.exit(2)
        if not layout or not topFileName or len(args) != 1:
                print args
                usage()
                sys.exit(2)
                
        inputFileName = args[0]

        # open UCF file and read in the lines
        ucfFile = open(inputFileName, "r")
        ucfLines = ucfFile.readlines()
	ucfFile.close()

        # open VHDL file and read in the lines
        vhdlFile = open(topFileName, "r")
        vhdlLines = vhdlFile.readlines()
        vhdlFile.close()

	makeucf(ucfLines, vhdlLines, outputFileName, layout, static)


def makeucf(ucfLines, vhdlLines, outputFileName, layout, static):
        instList = parseInstantiations(vhdlLines)     
   
	# Array to hold contraints for UCF file
	constraints = []
	
	# Arrays to hold component/instantiation names
	instantiations = []
	entities = []
	busMacros = []
	bufgs = []

	# Pull out component/instantiation names
        for i in instList:
		compName = i.componentName
		instName = i.name

		# Filter out all "*BUF*'s" and busMacros
		if ("macro" in compName):
			# Bus macros are stored separately
			busMacros.append(instName)
		elif (compName == "BUFG"):
			# Store this for later reference to area group it and LOC it
			bufgs.append(instName)
		elif not(
			(compName == "IBUF") or
			(compName == "OBUF") or
			(compName == "IOBUF") or
			(compName == "IBUFG") or
			(compName == "OBUFG") or
			(compName == "IOBUFG")
		):
			# Store all other instantiations besides the ones listed above
			instantiations.append(instName)
			entities.append(compName)

	
	# Slice boundaries (FIXME, these should be inputted by the user)
	#sliceLowX = "0"
	#sliceLowY = "4"
	#sliceHighX = "50"
	#sliceHighY = "89"
	
	# Flag to signal that reconModule was found
	found = False

	# Create area constraints for each module
	constraints.append("# **** PR Constraints ****")
	constraints.append("# Area group constraints - base system (static)")
	for i in range(len(instantiations)):
		# Check to see if this is the reconfigurable module
		if (instantiations[i] in layout.getSlotNames()):
			slot = layout.getSlotByName(instantiations[i])
			found = True

			# Insert special constraints for reconfigurable module
			constraints.append("\n# Area group constraints - reconfigurable module (dynamic)")
			constraints.append("INST \""+instantiations[i]+"\" AREA_GROUP = \"" + slot.getAGName() + "\";")
			constraints.append("AREA_GROUP \"" + slot.getAGName() + "\" RANGE = " + slot.getSliceRange() + ";")
			constraints.append("AREA_GROUP \"" + slot.getAGName() + "\" RANGE = " + slot.getBRAMRange() + ";")
                        # FIXME: this is dependent on the device family!
                        Mult18x18Range = slot.getMult18x18Range()
                        if Mult18x18Range:
    			        constraints.append("AREA_GROUP \"" + slot.getAGName() + "\" RANGE = " + slot.getMult18x18Range() + ";")
                        # FIXME: this is dependent on the device family!
                        DSP48Range = slot.getRange("DSP48")
                        if DSP48Range:
    			        constraints.append("AREA_GROUP \"" + slot.getAGName() + "\" RANGE = " + DSP48Range + ";")

			if static :
				constraints.append("AREA_GROUP \"" + slot.getAGName() + "\" GROUP = CLOSED;")
				constraints.append("AREA_GROUP \"" + slot.getAGName() + "\" PLACE = CLOSED;")
			else:
				constraints.append("AREA_GROUP \"" + slot.getAGName() + "\" MODE = RECONFIG;")
			for bm in slot.getBusMacros():
				constraints.append("INST \"" + bm.getName() + "\" LOC = SLICE_" + bm.getLocation() + ";")
		else:
			# Otherwise, put in "normal" constraints
			constraints.append("INST \""+instantiations[i]+"\" AREA_GROUP = \"AG_system\";")
	
	# Check to make sure that reconModule was found
	if (not found):
		print "\nNo reconfigurable module instantiation (" + str(layout.getSlotNames()) + ") was found!! Aborting..."
		sys.exit(3)

	# Add in BUFG LOC constraints
	constraints.append("# BUFG constraints")
	bufgNum = 0
	for bf in bufgs:
		constraints.append("INST \""+bf+"\" AREA_GROUP = \"AG_system\";")
		constraints.append("INST \""+bf+"\" LOC = \"" + bufgmux_locations[layout.target.getFamily()][bufgNum] + "\";")
		bufgNum += 1
	
	# Add is bus macro LOC constraints
#	xCoord = int(sliceLowX)
#	yCoord = int(sliceLowY)
#	constraints.append("# BM (Bus Macro) constraints")
#	for bm in busMacros:
#		constraints.append("INST \""+bm+"\" LOC = \"SLICE_X"+str(xCoord)+"Y"+str(yCoord)+"\";")
#		#xCoord = xCoord + 2
#		yCoord = yCoord + 2
		
	# Concatenate constraints to the inputted UCF file
	for con in constraints:
		ucfLines.append(con)

	# Store results (display to STDOUT if no output file is defined)
	if (outputFileName == None):
		for l in ucfLines:
			print l
	else:
		outputUcfFile = open(outputFileName,'w')
		for l in ucfLines:
			outputUcfFile.write(l+'\n')
		outputUcfFile.close()

	return constraints
 
def usage():
        print "USAGE:"
        print sys.argv[0] + " [-h] | [--static] [-o <out.ucf>] -l <layout.lyt> -t <top.vhd> <in.ucf>"
        print "\t-h | --help       Display this help"
        print "\t-s | --static     Generate UCF file for the static design"
        print "\t-o <out.ucf>      Output UCF file. Omit for stdout."
        print "\t-l <layout.lyt>   Name of layout file"
        print "\t-t <top.vhd>      Top level UCF (after addition of bus macros etc.)"
        print "\t<in.ucf>          Input UCF file (from EDK, e.g. system.ucf)"




if __name__ == "__main__":
        main(sys.argv[1:])
