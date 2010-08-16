#!/usr/bin/env python
#
# ****************************************************************************
# Script:	findModuleNames.py
# Purpose:	Pull out all of the modules names from a top-level design (.mhs)
# Usage:	./findModuleNames.py <mhsFile>
# ****************************************************************************
#
import sys, os, re

def main():

	# Check command line argument
	if len(sys.argv) > 1:
		# Save filename
		FILE = sys.argv[1]
	else:
		# Insufficient number of args, exit with error
		print "Incorrect argument usage!! Aborting..."
		print "Correct usage :\n    ./findModuleNames.py <mhsFile>\n"
		sys.exit(2)
	
	
	# Setup regular expression patterns
	entitySearch = re.compile('BEGIN (.*)\r')
	instantiationSearch = re.compile('PARAMETER INSTANCE = (.*)\r')
	
	# Open up the file and read in the lines
	infile = open(FILE,"r")
	lines = infile.readlines()
	
	# Counter for number of entities/instantiation
	numEntities = 0
	numInstantiations = 0
	
	# Arrays to hold entity and instantation names
	entities = []
	instantiations = []
	
	# Check all of the lines for instantiations
	for line in lines:
		# Check to see if an instantiation name is on this line
		m = instantiationSearch.search(line)
		n = entitySearch.search(line)
	
		# If an instantiation is found, store it
		if m > -1:
			instantiations.append(m.group(1))
			numInstantiations = numInstantiations + 1
	
		# If an entity is found, store it
		if n > -1:
			entities.append(n.group(1))
			numEntities = numEntities + 1
	
	# Display Findings
	print '**** ( Entity -- Instantitation) ****\n'
	for i in range(len(entities)):
		print '(%s -- %s)' % (entities[i], instantiations[i])

	return (entities, instantiations)

if __name__ == "__main__":
    main()	
