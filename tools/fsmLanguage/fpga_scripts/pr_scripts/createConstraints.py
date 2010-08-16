#!/usr/bin/env python
#
# *************************************************************************************************************
# Script:	createConstraints.py
# Purpose:	Creates .ucf constraints for a system with a reconfigurable module
# Usage:	./createConstraints.py <mhsFile> <reconModuleInstName> <sliceLowX> <sliceLowY> <sliceHighX> <sliceHighY>
# *************************************************************************************************************
#
import sys, os, re
import findModuleNames

def main():

	# Check command line argument
	if len(sys.argv) > 6:
		# Save filename
		FILE = sys.argv[1]
		RECON = sys.argv[2]
		sliceLowX = sys.argv[3]
		sliceLowY = sys.argv[4]
		sliceHighX = sys.argv[5]
		sliceHighY = sys.argv[6]	
	else:
		# Insufficient number of args, exit with error
		print "Incorrect argument usage!! Aborting..."
		print "Correct usage :\n    ./createConstraints.py <mhsFile> <reconModuleInstName> <sliceLowX> <sliceLowY> <sliceHighX> <sliceHighY>\n"
		sys.exit(2)

	# Array to hold contraints for UCF file
	constraints = []

	# Find all of the modules in the system
	(entities,instantiations) = findModuleNames.main()

	# Flag to signal that reconModule was found
	found = False

	# Create area constraints for each module
	constraints.append("# Area group constraints - base system (static)")
	for i in range(len(instantiations)):
		# Check to see if this is the reconfigurable module
		if (instantiations[i] == RECON):
			found = True

			# Insert special constraints for reconfigurable module
			constraints.append("# Area group constraints - reconfigurable module (dynamic)")
			constraints.append("INST \""+instantiations[i]+"\" AREA_GROUP = \"AG_recon\";")
			constraints.append("AREA_GROUP \"AG_recon\" RANGE = SLICE_X"+sliceLowX+"Y"+sliceLowY+":SLICE_X"+sliceHighX+"Y"+sliceHighY+";")
			constraints.append("AREA_GROUP \"AG_recon\" MODE = RECONFIG;")
		else:
			# Otherwise, put in "normal" constraints
			constraints.append("INST \""+instantiations[i]+"\" AREA_GROUP = \"AG_system\";")
	
	# Check to make sure that reconModule was found
	if (not found):
		print "\nReconfigurable module instantiation ("+RECON+") was not found!! Aborting..."
		sys.exit(3)

	# Create constraints for bus macro placement (FIXME: BUFG placement as well?)
	constraints.append("# Location constraints - bus macros")		


	# Display results
	print "\n**** Extra UCF Constraints ****\n"
	for con in constraints:
		print con

	return constraints

if __name__ == "__main__":
    main()
