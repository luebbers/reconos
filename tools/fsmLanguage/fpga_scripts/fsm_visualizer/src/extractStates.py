#!/usr/bin/env python
#
# ****************************************************************************
# Author:	Jason Agron
# Script:	extractStates.py
# Purpose:	Pull out all of the modules names from a VHDL state machine (.vhd)
#			and generates a DOT file
# Usage:	./extractStates.py <vhdFile> <dotFile> <fsmSig>
# ****************************************************************************
#
import sys, os, re
from stack import *

def main():

	# ********************************************
	# Check command line argument
	# ********************************************
	if len(sys.argv) > 4:
		# Save filename
		FILE		= sys.argv[1]
		DOT_FILE	= sys.argv[2]
		CUR_SIG		= sys.argv[3]
		FSM_SIG		= sys.argv[4]
	else:
		# Insufficient number of args, exit with error
		print "Incorrect argument usage!! Aborting..."
		print "Correct usage :\n    ./extractStates.py <vhdFile> <dotFile> <curSig> <fsmSig>"
		print "Where:"
		print " <vhdFile> is the name of the VHDL file to parse"
		print " <dotFile> is the name of the DOT file to export"
		print " <curSig> is the VHDL signal used to represent current FSM state (current state)"
		print " <fsmSig> is the VHDL signal used to control FSM transitions (next state)"
		sys.exit(2)
	
	
	# *************************************************************
	# Setup regular expression patterns
	# *************************************************************
	# Used to search for the beginning of an FSM type definition (enumerated type)
	#	Of the form: "type <typeName> is"
	fsmTypeDefSearch = re.compile('type (.*) is')

	# Used to search for the end of an FSM type definition
	#	Of the form: ");"
	endTypeDefSearch = re.compile('\);')

	# Used to search for each name of an enumerated type
	#	Of the form: " <enum>,"
	fsmTypeSearch = re.compile('\s*(\w*)\,?')

	# Used to search for a beginning parentheses on a line
	#	Of the form: "("
	beginParenSearch = re.compile('\((\s)*')

	# Used to search for a blank line
	blankLineSearch = re.compile('(^|\r\n)\s*(\r\n|$)')

	# Used to search for the beginning of a state (when clause)
	#	Of the form: "when <stateName> => "
	stateSearch = re.compile('when\s*(\w*)\s*=>')

	# Used to search for a transition definition
	#	Of the form: "<FSM_SIG> <= <NEXT_STATE>;"
	transitionSearch = re.compile(FSM_SIG+'\s*<=\s*(\w*);')

	# Used to search for the beginning of an FSM (case statement)
	#	Of the form: "case (<sig>) is"
	fsmBeginSearch = re.compile('case\s*\((.*)\)\s*is')

	# Used to search for the end of an FSM (case statement)
	#	Of the form: "end case;"
	fsmEndSearch = re.compile('end case;')
	
	# ***************************************************************
	# Open up the VHDL file and read in the lines
	# ***************************************************************
	infile = open(FILE,"r")
	lines = infile.readlines()
	infile.close()
	
	# ********************************************
	# Initialize program state
	# ********************************************
	# Flag to signal when the FSM has been found
	fsmFound = 0

	# Counter for the number of states encountered
	numStates = 0

	# Counter for the number of type-definition states found (for an enumeration)
	num_tdef_states = 0

	# Flag to signal when the type-definition has been found
	tdef_flag = 0

	# Counter for the current line number
	lineCount = 0

	# Variable to hold the last state that has been encountered (so any transitions are coming from this state)	
	lastState = -999
	
	# Array to hold states encountered
	states = []

	# Array to hold type-definition states that have been encountered
	tdef_states = []

	# Array to hold the source of all transitions
	transitions_from = []

	# Array to hold the destination of all transitions
	transitions_to = []

	# Array to hold the line number of each transition (line number in the source program)
	transitions_lineNum = []

	# Stack of encountered case statements
	caseStack = stack()
	
	# ********************************************
	# Parse VHDL line by line
	# ********************************************
	for line in lines:
		lineCount = lineCount + 1

		# Parse the VHDL file
		if tdef_flag == 0:

			# Check pertinent reg-ex's
			m = stateSearch.search(line)
			tdef = fsmTypeDefSearch.search(line)
			trans = transitionSearch.search(line)
			fsm = fsmBeginSearch.search(line)
			fsm_end = fsmEndSearch.search(line)

			# If the beginning of a case statement is found, check if it is the one corresponding to the FSM
			if fsm > -1:
				caseStack.push(fsm.group(1))

			# If the end of a case statement is found
			if fsm_end > -1:
				if (caseStack.num_elements() > 0):
					el = caseStack.pop()
		
			# If a new state is found
			if m > -1:
				# Only update last state if the current "case" scope is that of the FSM and not just some conditional logic
				if (caseStack.num_elements() > 0):
					if (caseStack.top() == CUR_SIG):
						if (fsmFound == 0):
							print "FSM Found, enabling state extraction..."
							fsmFound = 1
						lastState = m.group(1)
						states.append(m.group(1))
						numStates = numStates + 1

			# If a transition is found, store it
			if trans > -1:
				# Wait until FSM has been found
				if fsmFound:
					transitions_from.append(lastState)
					transitions_to.append(trans.group(1))
					transitions_lineNum.append(lineCount)
	
			# If an type definition is found, set the flag to capture it
			if tdef > -1:
				tdef_flag = 1
		else:
		# Parse the FSM type definition

			# Do all the reg-ex searches
			bp = beginParenSearch.search(line)
			bl = blankLineSearch.search(line)
			t = fsmTypeSearch.search(line)
			et = endTypeDefSearch.search(line)

			# If blank line, ignore
			if bl > -1:
				tdef_flag = 1
			# If beginning parentheses, ignore
			elif bp > -1:
				tdef_flag = 1
			# If end of type definition, exit
			elif et > -1:
				tdef_flag = 0
			# Otherwise, grab the state name
			else:
				tdef_states.append(t.group(1))
				num_tdef_states = num_tdef_states + 1
				tdef_flag = 1

	# If while looping the FSM was never found then exit with an error
	if (not fsmFound):
		raise "Error", "FSM Not Found!!!"

	# ********************************************
	# Create DOT file
	# ********************************************
	print "Creating DOT file..."

	# Initialize data structure that will become the DOT file
	dotArray = []
	dotArray.append("digraph G {")
	
	# Add all transitions
	for i in range(len(transitions_from)):
		newLine = "	"+transitions_from[i]+" -> "+transitions_to[i] + " [label =\"Line#"+str(transitions_lineNum[i])+"\"]"
		dotArray.append(newLine)		

	# Add in the last line of the DOT file
	dotArray.append("}")

	# Write output file
	outFile = open(DOT_FILE, "w")
	for line in dotArray:
		outFile.write(line+"\n")
	outFile.close()

	print "State extraction complete."

if __name__ == "__main__":
    main()	

