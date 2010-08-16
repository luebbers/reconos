#!/usr/bin/env python
#
# \file vhdl.py
#
# Tools for parsing and manipulating VHDL files
#
# LIMITATIONS: Only recognizes std_logic and std_logic_vectors
#              Does not support direct instantiations without component statements
#              Does not support generics
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


class Port:
#        name = ""
#        direction = "in"
#        datatype = "std_logic"
        def __init__(self, name, direction, datatype):
                self.name = name
                self.direction = direction
                self.datatype = datatype
        def toString(self):
                return self.name + " : " + self.direction + " " + self.datatype


class Signal:
#        name = ""
#        datatype = "std_logic"
        def __init__(self, name, datatype):
                self.name = name
                self.datatype = datatype
        def toString(self):
                return "  signal " + self.name + " : " + self.datatype + ";"
        
class Component:
#        name = ""
#        ports = []
        def toLinesList(self):
                retVal = []
                retVal.append("  component " + self.name + " is\n")
                retVal.append("    port (\n")
                for p in self.ports:
                        retVal.append("      " + p.toString() +";\n")
                retVal[len(retVal)-1] = retVal[len(retVal)-1][:-2]    # remove last semicolon and newline
                retVal[len(retVal)-1] = retVal[len(retVal)-1] + "\n"
                retVal.append("    );\n")
                retVal.append("  end component;\n")
                return retVal
        
class Instantiation:
#        name = ""
#        componentName = ""
#        portMap = {}
        def __init__(self, name = None, componentName = None, portMap = None):
                self.name = name
                self.componentName = componentName
                self.portMap = portMap
        def toString(self):
                retVal = "  " + self.name + " : " + self.componentName + "\n    port map (\n"
                for k in self.portMap.keys():
                        retVal = retVal +  "      " + k + " => " + self.portMap[k] + ",\n"
                retVal = retVal[:-2]    # remove last comma and newline
                retVal = retVal + "\n    );"
                return retVal
        def toLineList(self):
                retVal = []
                retVal.append("  " + self.name + " : " + self.componentName + "\n")
                retVal.append("    port map (\n")
                for k in self.portMap.keys():
                        retVal.append("      " + k + " => " + self.portMap[k] + ",\n")
                retVal[len(retVal)-1] = retVal[len(retVal)-1][:-2]    # remove last comma and newline
                retVal[len(retVal)-1] = retVal[len(retVal)-1] + "\n    );\n"
                return retVal



def stripComments(line):
        "Strips all comments from VHDL in string-array 'lines'."
        
        expComment = re.compile("--.*$")
        return expComment.sub("", line)
                
        
                

def parseComponents(lines):
        "Creates a list of components in a VHDL file"
        
        compFound = 0;
        
        # iniialize empty list
        components = []
        
        # parse lines
        exp1 = re.compile("component\s+(\w+)\s+is")
        exp2 = re.compile("(\w+)\s*:\s*(\w+)\s+(\w+\((\d+\s+\w+\s+\d+\))|\w+)\s*")
        exp3 = re.compile("end\s+component\s*;")
        for l in lines:
                line = stripComments(l)
#                print "> " + line,
                m = exp1.search(line)
                if m:   # component found
                        c = Component()
                        c.name = m.group(1)
                        c.ports = []
                        compFound = True;
#                        print "===> Component found (" + c.name + ")"
                        continue
                m = exp2.search(line)
                if m:   # port found
                        if not compFound:
                                continue
                        p = Port(name=m.group(1), direction=m.group(2), datatype=m.group(3))
                        c.ports.append(p)
#                        print "===> Port found (" + c.name + "." + p.name + " of " + p.datatype + ")"
                        continue
                m = exp3.search(line)
                if m:   # end component
                        if compFound:
                                components.append(c)
                                compFound = False;
                        
        return components




def parseInstantiations(lines):
        "Creates a list of instantiations in a VHDL file"
        
        instFound = 0;
        
        # iniialize empty list
        instantiations = []
        
       
        # parse lines
        exp1 = re.compile("(\w+)\s*:\s*(\w+)\s*\n")      # instance
        exp2 = re.compile("(\w+)\s*=>\s*(\w+|\w+\((\d+|\d+\s+\w+\s+\d+)\))\s*,*\s*\n")   # port mapping
        exp3 = re.compile("\);")             # end of instance
        for l in lines:
#                print "> " + line,
                line = stripComments(l)
                m = exp1.search(line)
                if m:   # instance found
                        i = Instantiation(name = m.group(1), componentName = m.group(2), portMap = {})
#                        i.name = m.group(1)
#                        i.componentName = m.group(2)
#                        i.portMap = {}
                        instFound = True;
                        continue
                m = exp2.search(line)
                if m:   # port mapping found
#                        print "===> port mapping: '" + m.group(1) + "' => '" + m.group(2) + "'"
                        if not instFound:
                                continue
                        i.portMap[m.group(1)] = m.group(2)
                        continue
                m = exp3.search(line)
                if m:   # end instantiation
                        if instFound:
                                instantiations.append(i)
                                instFound = False
                        
        return instantiations



def parseSignals(lines):
        "Creates a list of signals in a VHDL file"
        
        # iniialize empty list
        signals = []
        
       
        # parse lines
        exp = re.compile("signal\s+(\w+)\s*:\s*(\w+|\w+\((\d+\s+\w+\s+\d+\)))\s*;")      # signal
        for l in lines:
                line = stripComments(l)
                m = exp.search(line)
                if m:   # instance found
                        s = Signal(name = m.group(1), datatype = m.group(2))
                        signals.append(s)
                        continue
                        
        return signals


def replaceInstantiation(lines, instNameToReplace, newInst, comment="Replaced instantiation"):

        retVal = []
        instFound = 0;

        # parse lines
        expBegin = re.compile(instNameToReplace + "\s*:\s*\w+\s*\n")      # instance
        expEnd = re.compile("\);")             # end of instance
        for line in lines:
                m = expBegin.search(line)
                if m:   # instance found
                        retVal.append("-- " + comment + "\n")
                        instFound = 1;
                if not instFound:
                        retVal.append(line)
                else:
                        retVal.append("-- " + line)
                m = expEnd.search(line)
                if m:   # end of instance found
                        if instFound:
                                retVal = retVal + newInst.toLineList()   # append new instantiation
                        instFound = 0;
                       
        return retVal


def insertSignals(lines, signals, comment="Inserted Signals"):
        
        retVal = lines[:]       # work on a copy
        mySignals = signals[:]  # work on a copy
       
        # find last signal statement
        indexes = searchRegexInList("signal\s+(\w+)\s*:\s*(\w+|\w+\((\d+\s+\w+\s+\d+\)))\s*;", lines)      # signal
        i = indexes[len(indexes)-1] + 1                 # insert here
        
        if i == 0:
                print "ERROR: no signals in file, I'm too dumb to insert signals."
                
        mySignals.reverse()     # reverse signal list
                
        # insert all signals
        for s in mySignals:
                retVal.insert(i, s.toString() + "\n")

        retVal.insert(i, "-- " + comment + "\n")
        retVal.insert(i, "\n")
        return retVal


def insertComponents(lines, components, comment="Inserted Component"):
        
        retVal = lines[:]       # work on a copy
        myComponents = components[:]
        myComponents.reverse()
       
        # find last signal statement
        indexes = searchRegexInList("end\s+component\s*;", lines)
        i = indexes[len(indexes)-1] + 1                 # insert here
        
        if i == 0:
                print "ERROR: no components in file, I'm too dumb to insert the first."
                
        # insert components
        for c in components:
                compLines = c.toLinesList()
                compLines.reverse()
                for l in compLines:
                        retVal.insert(i, l)

        retVal.insert(i, "-- " + comment + "\n")
        retVal.insert(i, "\n")
        return retVal


def insertInstantiations(lines, instList, comment="Inserted instantiation"):
        "Inserts instantiations in 'instList' at the end of the VHDL architecture in 'lines'"

        retVal = lines[:]
        myInstList = instList[:]
        myInstList.reverse()

        # find last end statement (NOTE: this could fail, if configurations follow the architecture)
        indexes = searchRegexInList("end", retVal)      # signal
        i = indexes[len(indexes)-1]                 # insert here

        for newInst in myInstList:         
                insertList = newInst.toLineList()
                insertList.reverse()       # reverse for insertion
                for l in insertList:
                        retVal.insert(i, l)
                       
        return retVal

def insertVHDL(lines, vhdl, comment="Inserted VHDL"):
        "Inserts arbitrary VHDL code into the architecture body"

        retVal = lines[:]
        # find last end statement (NOTE: this could fail, if configurations follow the architecture)
        indexes = searchRegexInList("end", retVal)      # signal
        i = indexes[len(indexes)-1]                 # insert here

        retVal.insert(i, vhdl)
        retVal.insert(i, "-- " + comment + "\n")

        return retVal


def separateNameFromRange(s):
        "Separates the name of a signal vector from its range"

        signalName = s
        signalRange = ""
        if "(" in signalName:                                           # seperate name and range
                signalRange = signalName[signalName.index("("):]
                signalName = signalName[:signalName.index("(")]

        return signalName, signalRange

