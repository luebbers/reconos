#!/usr/bin/env python
#
# ****************************************************************************
# Script:	estimateSlices.py
# Purpose:	Estimates the slice count of a hardware module
# Usage:	./estimateSlices.py <vhdlFile> <fpgaArch>
# ****************************************************************************
#
import sys, os, re

def main():

	# Check command line argument
	if len(sys.argv) > 2:
		# Save filename
		FILE = sys.argv[1]
		ARCH = sys.argv[2]
	else:
		# Insufficient number of args, exit with error
		print "Incorrect argument usage!! Aborting..."
		print "Correct usage :\n    ./estimateSlices.py <vhdlFile> <fpgaArch>\n"
		print "<fpgaArch> = xc2vp30, xc5vfx70t.\n"
		sys.exit(2)


	# Output files names for SCR and PRJ (should be the same)
	scrName = "synthScript"
	prjName = "synthScript"

	# Setup regular expression patterns
	entitySearch = re.compile('(.*).vhd')
	sliceSearch = re.compile('Number of Slices:\s*(\d*)')

	# Check to see if it is a VHDL file
	m = entitySearch.search(FILE)
	if (m > -1):
		entityName = m.group(1)
	else:
		print "Incorrect file argument! File must be a .vhd file!!!"
		sys.exit(3)	

	# Array to hold lines of SCR and PRJ files
	scrArray = []
	prjArray = []

	# Setup SCR
	scrArray.append('run')	
	scrArray.append('-opt_mode speed')
	scrArray.append('-opt_level 1')
	scrArray.append('-p '+ARCH)
	scrArray.append('-top '+entityName)
	scrArray.append('-ifmt MIXED')
	scrArray.append('-ram_style BLOCK')
	scrArray.append('-ifn '+prjName+'.prj')
	scrArray.append('-ofn '+entityName+'.ngc')
	scrArray.append('-hierarchy_separator /')
	scrArray.append('-iobuf NO')
	scrArray.append('-sd {.}')

	# Setup PRJ
	prjArray.append('vhdl work ./'+FILE)

	# Write SCR file, line by line
	scr_file = open(scrName+'.scr',"w")
	for line in scrArray:
		scr_file.write(line+"\n")
	scr_file.close()

	# Write PRJ file, line by line
	prj_file = open(scrName+'.prj',"w")
	for line in prjArray:
		prj_file.write(line+"\n")
	prj_file.close()

	# Call synthesis routine
	status = os.system('xst -ifn '+scrName+'.scr')
	
	# Open up SRP (log) file
	logFile = open(scrName+'.srp',"r")
	lines = logFile.readlines()

	# Extract slice usage estimate
	for line in lines:
		n = sliceSearch.search(line)
		if (n > -1):
			sliceCount = n.group(1)
			print 'Slice count estimate = ~'+sliceCount+' slices'
			return sliceCount
		

if __name__ == "__main__":
    main()	
