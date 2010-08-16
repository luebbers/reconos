#!/usr/bin/env python
#
# ****************************************************************************
# Script:	modifyModuleInst.py
# Purpose:	Modify the reconfigurable module instantiation (add bus macros, etc.)
# Usage:	./modifyModuleInst.py <vhdlFile> <reconModuleInstName>
# ****************************************************************************
#
import sys, os, re

def main():

	# Check command line argument
	if len(sys.argv) > 2:
		# Save filename
		FILE = sys.argv[1]
		RECON = sys.argv[2]
	else:
		# Insufficient number of args, exit with error
		print "Incorrect argument usage!! Aborting..."
		print "Correct usage :\n    ./modifyModuleInst.py <vhdlFile> <reconModuleInstName>\n"
		sys.exit(2)
	
	
	# Setup regular expression patterns
	entitySearch = re.compile('(.*).vhd')
	moduleStart = re.compile('\s*'+RECON+'\s*:\s*(.*)\s*')
	signalConnection = re.compile('\s*(\S*)\s*=>\s*(.*)(,?)\s*')
	moduleEnd = re.compile('\s*\);\s*')

	# Check to see if it is a VHDL file
	m = entitySearch.search(FILE)
	if (m > -1):
		entityName = m.group(1)
	else:
		print "Incorrect file argument! File must be a .vhd file!!!"
		sys.exit(3)	

	# Open up the file and read in the lines
	infile = open(FILE,"r")
	lines = infile.readlines()

	# Flag for finding when search items have been found and when it has ended
	found = False
	ended = False

	# Array for holding original/modified instantiations of the module
	originalInst = []
	modifiedInst = []
	componentDef = []

	# Check all of the lines for the module's instantiation
	for line in lines:
		# Check to see if an instantiation name is on this line, until found
		if (not found):
			# Search for instantiation begin
			m = moduleStart.match(line)
	
			# If an instantiation is found, store it (and store entityName), and set flag
			if m > -1:
				found = True
				originalInst.append(line)
				entityName = m.group(1)		
	
		# Once found, take the rest of the instantiation, until the end of the inst.
		elif (not ended):
			# Search for instantiation end
			n = moduleEnd.match(line)
				
			# If found, then store the last line and set the flag
			if n > -1:
				ended = True
				originalInst.append(line)
			else:
				# Add the line, it is not quite the end
				originalInst.append(line)

	# Check to make sure that an instantiation was found
	if (found and ended):
		# If found, continue on
		print 'Instantiation found.  Modifing instantiation...'
	else:
		# If not found, abort program
		print 'Instantiation not found!!! Aborting...'
		sys.exit(4)

	# Now that the original instantiation has been found...
	#	* Add bus macros interface
	#		* Re-connect signals through bus macros
	#	* Add in BUFG for clock signals
	#		* Re-connect clocks signals through BUFGs

	# First, find the component definition...
	#	* Used to "look up" port widths and types

	# Setup regular expressions
	componentStart = re.compile('\s*component\s*'+entityName+'\s*is')
	portDefinition = re.compile('\s*(\S*)\s*:\s*(\S*)\s*(.*)(;?)\s*')
	componentEnd = re.compile('\s*end component;\s*')

	# Re-initialize search flags
	found = False
	ended = False

	# Check all of the lines for the module's component definition
	for line in lines:
		# Check to see if the component name is on this line, until found
		if (not found):
			# Search for component begin
			m = componentStart.match(line)
	
			# If the component is found, store it, and set flag
			if m > -1:
				found = True
				componentDef.append(line)
	
		# Once found, take the rest of the component defintion, until the end of the
		elif (not ended):
			# Search for component defintion  end
			n = componentEnd.match(line)
				
			# If found, then store the last line and set the flag
			if n > -1:
				ended = True
				componentDef.append(line)
			else:
				# Add the line, it is not quite the end
				componentDef.append(line)
			
	for i in componentDef:
		print i

	for i in componentDef:
		m = portDefinition.match(i)
		if m > -1:
			print '('+m.group(1)+') DIR '+m.group(2)+' TYPE ('+m.group(3)+')'	

if __name__ == "__main__":
    main()	
