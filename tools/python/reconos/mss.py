#!/usr/bin/env python
#
# \file mss.py
#
# API for parsing and manipulating mss files
#
# \author     Robert Meiche <rmeiche@gmx.de>
# \date       04.20.2007
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

import string
import sys

class MSSLine:
        """
This class represents a single line of a mss file
fields: self.content: list containing key/value pairs
        no type field, because in mss files exist only type PARAMETER
"""
        
        def __init__(self, line, line_num = 0):
                s = line.split()
                
                s = " ".join(s[1:])
                s = s.split(",")
                
                self.content = []
                
                self.line_num = line_num
                
                for x in s:
                        y = map(lambda x: x.strip(), x.split("="))
                        if not len(y) == 2:
                                raise "parse error at line %i" % line_num
                        self.content.append((y[0],y[1]))
                        
        def __str__(self):
                s = "PARAMETER " + self.content[0][0] + " = " + str(self.content[0][1])
                for k in self.content[1:]:
                        s += ", " + k[0] + " = " + k[1]
                return s
                
class MSSElement:
        """
This class represents a pcore instance
fields: self.msstype
        self.instance_name
        self.content       : list of lines 
"""
        def __init__(self, msstype):
                self.msstype = msstype
                self.content = []
                self.instance_name = "" #some elements like LIBRARY or OS don't have a Parameter HW_INSTANCE so instance_name has to be initialized
                
        def addLine(self,line):
                if line.content[0][0] == "HW_INSTANCE":
                        self.instance_name = line.content[0][1]
                        return
                self.content.append(line)
                
        def getValue(self,key):
                for line in self.content:
                        if line.content[0][0].lower() == key.lower():   # MHS files are case insensitive
                                return line.content[0][1]
                return None
                                
        def setValue(self,key,value):
                for line in self.content:
                        if line.content[0][0] == key:
                                line.content[0] = (line.content[0][0],value)

        def addEntry(self,key,value):
                self.addLine(MSSLine("PARAMETER " + key + " = " + value))
                                
        def __str__(self):
                result = "BEGIN " + self.msstype + "\n"
                if self.instance_name != "":
                    result += "\tPARAMETER HW_INSTANCE = " + self.instance_name + "\n"
                for k in self.content:
                        result += "\t" + str(k) + "\n"
                result += "END\n"
                return result               
                
class MSS:
        """
This class represents a mhs file.
fields: self.elements   : list of MSSDriver elements (OS, DRIVER, PROCESSOR)
        self.toplevel   : list of MSSLine objects
"""
        def __init__(self, filename = None):
                self.elements = []
                self.toplevel = [MSSLine("PARAMETER VERSION = 2.2.0",0)]
                if filename:
                        self.parse(filename)
                
        def isComment(self,line_trimmed):
                return line_trimmed[0] == '#'
                
        def parse(self,filename):
                STATE_TOPLEVEL = 0
                STATE_ELEMENT = 1
                
                state = STATE_TOPLEVEL
                line_count = 0
                
                fin = open(filename,"r")
                
                self.elements = []
                self.toplevel = []
                
                element = None
                
                while True:
                        line_count += 1
                        line = fin.readline()
                        if not line:
                                if state == STATE_ELEMENT:
                                        raise "unexpected end of file: '%s' at line %i" % (filename,line_count)
                                break
                                        
                        line = line.strip()
                        
                        if not line: continue
                        
                        if self.isComment(line): continue
                        
                        s = line.split()
                        name = s[0]
                        s = " ".join(s[1:])
                        
                        if state == STATE_TOPLEVEL:
                                if name == "BEGIN":
                                        state = STATE_ELEMENT
                                        element = MSSElement(s)    
                                        continue
                                else:
                                        self.toplevel.append(MSSLine(line,line_count))
                                        continue
                        else:
                                if name == "END":
                                        state = STATE_TOPLEVEL
                                        self.elements.append(element)
                                        continue
                                else:
                                        element.addLine(MSSLine(line,line_count))
                                        continue
                                        
        def __str__(self):
                result = ""
                for k in self.toplevel:
                        result += str(k) + "\n"
                                
                for element in self.elements:
                        result += "\n" + str(element)
                        
                return result
                        
        def getElements(self,msstype):
                result = []
                for element in self.elements:
                        if element.msstype == msstype:
                                result.append(element)
                return result
        
        #This function only returns elements, which have an HW_INSTANCE Parameter 
        #For other elements like OS use the corresponding functions e.g getOS        
        def getElement(self,instance_name):
                for element in self.elements:
                        if element.instance_name == instance_name:
                                return element
                return None
                
        #Returns an OS element
        #instance_name is the name of the corresponding processor
        def getOS(self, instance_name):
                os_elements = self.getElements("OS")
                for element in os_elements:
                        if element.getValue("PROC_INSTANCE") == instance_name:
                                return element
                return None
            
        def delElement(self, instance_name):
                del_obj = self.getElement(instance_name)
                self.elements.remove(del_obj)
