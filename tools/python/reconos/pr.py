#!/usr/bin/env python
#
# \file pr.py
#
# Functions for partial reconfiguration
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

import re
from reconos.tools import *
from reconos.vhdl import *
from reconos.layout import *

# NOTE: This assumes that all busmacros in 'busMacros' are the same type, e.g.
# input, synchronous; output, synchronous; input, asynchronous; output, asynchronous
def instantiateBusMacrosForSignals(busMacros, signals, suffix, reconosSlot, threadClock, osifClock):

        bmInstList = []
        bitCount = 0
        bmCount = 0

        assert len(busMacros) > 0, "No busmacros to consider"

        # get direction from first bus macro
        if busMacros[0].isInput():
            staticSide = "input"
            dynamicSide = "output"
            if osifClock == threadClock:
                n, r = separateNameFromRange(threadClock)
                bmClock = n + suffix + r
            else:
                bmClock = osifClock # input macros use static side clock
        else:
            staticSide = "output"
            dynamicSide = "input"
            n, r = separateNameFromRange(threadClock)
            bmClock = n + suffix + r # add suffix so that the module clock is used

        # generate string for assertion
        bmType = staticSide
        if busMacros[0].isSynchronous():
            bmType = "synchronous " + bmType
        else:
            bmType = "asynchronous " + bmType

        assert len(busMacros) == (len(signals) + 7)/8, "Number of " + bmType + " bus macros in layout does not match design.\n\tFound: %d, expected: %d." % (len(busMacros), (len(signals) + 7) / 8)

        for s in signals:
                if bitCount % 8 == 0:
                        bm = Instantiation()
                        bm.portMap = {}
                        bm.name = busMacros[bmCount].getName()
                        bm.componentName = busMacros[bmCount].getType()
                        bmInstList.append(bm)
                        if busMacros[0].isSynchronous():
                            for i in range(0, 4):
                                bm.portMap["clk" + str(i)] = bmClock
                                bm.portMap["ce" + str(i)] = "'1'"
                        bmCount = bmCount + 1
                bm.portMap[staticSide + str(bitCount % 8)] = s
                if "(" in s:
                        bm.portMap[dynamicSide + str(bitCount % 8)] = s[:s.index("(")] + suffix + s[s.index("("):]
                else:
                        bm.portMap[dynamicSide + str(bitCount % 8)] = s + suffix
                if busMacros[0].isOutput():
                        bm.portMap["enable" + str(bitCount % 8)] = "bm_enable_" + reconosSlot.getName().lower() # FIXME! this is not yet defined
                bitCount = bitCount + 1
             
        # pad/connect unused ports on last busmacro                
        while bitCount % 8 != 0:
                bm.portMap["input" + str(bitCount % 8)] = "'0'"
                bm.portMap["output" + str(bitCount % 8)] = "open"
                if busMacros[0].isOutput():
                        bm.portMap["enable" + str(bitCount % 8)] = "'0'"
                bitCount = bitCount + 1

        return bmInstList


def generateBusMacros(portTuples, suffix, signalList, reconosSlot, threadClock, osifClock):       # portTuples = list of (port object, signal name)
        
        bitSignalsIn_async = []              # list of 1 bit wide input signals
        bitSignalsOut_async = []             # list of 1 bit wide output signals
        bitSignalsIn_sync = []              # list of 1 bit wide input signals (synchronous)
        bitSignalsOut_sync = []             # list of 1 bit wide output signals (synchronous)
        bmInstList = []                # initialize bus macro instantiation list
        
        # compile regular expressions
        expRange = re.compile("(\w+)\s*\((\d+)\s+(to|downto)\s+(\d+)\)")
        

        # flatten out signal vectors        
        for t in portTuples:                 # for every signal (one or more bits wide)
                (p, s) = t         # unpack tuple
                newSignals = []    # list of signal to add for this port
                
#                print p.name + " => " + s
                
                m = expRange.match(s)
                if m:           # range of a bit vector
                        name = m.group(1)
                        rangeStart = m.group(2)
                        rangeEnd = m.group(4)
                        for i in range(int(rangeStart), int(rangeEnd)+1):         # append bit after bit
                                newSignals.append(name + "(" + str(i) + ")")

                elif "std_logic_vector" in p.datatype.lower():          # complete bit vector
                        signal = getObjectByName(signalList, s)         # find signal in global list
                        m = expRange.match(signal.datatype)             # and extract vector range
                        rangeStart = m.group(2)
                        rangeEnd = m.group(4)
                        for i in range(int(rangeStart), int(rangeEnd)+1):         # append bit after bit
                                newSignals.append(s + "(" + str(i) + ")")
                                        
                else:           # single std_logic or single bit of a vector
                        newSignals.append(s)            # just append
                                
                if p.direction == "in":
                        if "burst" in p.name:
                                bitSignalsIn_async = bitSignalsIn_async + newSignals
                        else:
                                bitSignalsIn_sync = bitSignalsIn_sync + newSignals
                elif p.direction == "out":
                        if "burst" in p.name:
                                bitSignalsOut_async = bitSignalsOut_async + newSignals
                        else:
                                bitSignalsOut_sync = bitSignalsOut_sync + newSignals
                else:
                        print "ERROR: busmacros do not support pins of mode INOUT! (" + name + ")"
                

        # instantiate bus macros
        bmIn_sync = reconosSlot.getSyncInputBusMacros()      # this is a list of Layout.BusMacro objects
        bmIn_async = reconosSlot.getAsyncInputBusMacros()      # this is a list of Layout.BusMacro objects
        bmOut_sync = reconosSlot.getSyncOutputBusMacros()      # this is a list of Layout.BusMacro objects
        bmOut_async = reconosSlot.getAsyncOutputBusMacros()      # this is a list of Layout.BusMacro objects
        # check for matching layout
        fail = False
        for m, s, msg in ((bmIn_sync,   bitSignalsIn_sync, "synchronous input"), 
                     (bmIn_async,  bitSignalsIn_async, "asynchronous input"),
                     (bmOut_sync,  bitSignalsOut_sync, "synchronous output"), 
                     (bmOut_async, bitSignalsOut_async, "asynchronous output")):
            if (len(m) != (len(s) + 7) / 8):
                print "\tNumber of " + msg + " bus macros in layout (" + str(len(m)) + ") does not match design (needs " + str((len(s) + 7) / 8) + ")!"
                fail = True
        if fail:
            sys.exit(-1)
        bmInstList = bmInstList + instantiateBusMacrosForSignals(bmIn_sync, bitSignalsIn_sync, suffix, reconosSlot, threadClock, osifClock)
        bmInstList = bmInstList + instantiateBusMacrosForSignals(bmIn_async, bitSignalsIn_async, suffix, reconosSlot, threadClock, osifClock)
        bmInstList = bmInstList + instantiateBusMacrosForSignals(bmOut_sync, bitSignalsOut_sync, suffix, reconosSlot, threadClock, osifClock)
        bmInstList = bmInstList + instantiateBusMacrosForSignals(bmOut_async, bitSignalsOut_async, suffix, reconosSlot, threadClock, osifClock)

        return bmInstList


def generateClockBuffers(clockName, suffix, slot):
	"Returns a list of clock buffer instances connecting clockNames with their '_module' counterparts"
	
	bufgInstList = []
	
	c = clockName
        n, r = separateNameFromRange(c)
	bufgInst = Instantiation(name = "clockbuffer_" + slot.getName().lower() + "_" + n, 
				 componentName = "BUFG",
				 portMap = {"I" : c, "O" : n + suffix + r})
	bufgInstList.append(bufgInst)
	
	return bufgInstList
