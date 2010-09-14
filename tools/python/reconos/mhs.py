#!/usr/bin/env python
#
# \file mhs.py
#
# API for parsing and manipulating mhs files
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

import string
import sys
import os

def get_reconos_ip_version():
	ver = os.environ["RECONOS_VER"]
	ver = ver[1:]
	ver = ver.replace("_",".")
	return ver

def get_osif_ip_version():
	ver = os.environ["OSIF_VER"]
	if ver == None:
		return get_reconos_ip_version()
	ver = ver[1:]
	ver = ver.replace("_",".")
	return ver


plb_if_types     = {'46' : 'MPLB', '34' : 'MSPLB'}
osif_ip_core = "plb_osif"
osif_inst_name = "osif"
osif_ip_version = get_osif_ip_version()
reconos_ip_version = get_reconos_ip_version()
reconos_base_addr = 0x20000000
reconos_size      = 0x10000
reconos_dcr_base_addr = 0
reconos_dcr_size      = 4


# return a binary representation of a number
# x: number
# n: number of binary digits
def ntob(x, n):
        s = "";
        for i in range(0, n):
                if (x << i) & (1 << n-1):
                        s += "1";
                else:
                        s += "0";
        return s;


class MHSLine:
        """
This class represents a single line of a mhs file
fields: self.type   : the first word on the line (eg. PARAMETER, PORT,...)
        self.content: list containing key/value pairs
"""
        
        def __init__(self, line, line_num = 0):
                s = line.split()
                self.type = s[0]
                
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
                s = self.type + " " + self.content[0][0] + " = " + str(self.content[0][1])
                for k in self.content[1:]:
                        s += ", " + k[0] + " = " + k[1]
                return s
        

class MHSPCore:
        """
This class represents a pcore instance
fields: self.ip_name
        self.instance_name
        self.content       : list of lines 
"""
        def __init__(self,ip_name):
                self.ip_name = ip_name
                self.content = []
                
        def addLine(self,line):
                if line.type == "PARAMETER" and line.content[0][0] == "INSTANCE":
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

        def addEntry(self,name,key,value):
                self.addLine(MHSLine(name + " " + key + " = " + value))
                                
        def __str__(self):
                result = "BEGIN " + self.ip_name + "\n"
                result += "\tPARAMETER INSTANCE = " + self.instance_name + "\n"
                for k in self.content:
                        result += "\t" + str(k) + "\n"
                result += "END\n"
                return result
                
class MHS:
        """
This class represents a mhs file.
fields: self.pcores   : list of MHSPCore objects
        self.toplevel : list of MHSLine objects
"""
        def __init__(self, filename = None):
                self.pcores = []
                self.toplevel = [MHSLine("PARAMETER VERSION = 2.1.0",0)]
                if filename:
                        self.parse(filename)
                
        def isComment(self,line_trimmed):
                return line_trimmed[0] == '#'
                
        def parse(self,filename):
                STATE_TOPLEVEL = 0
                STATE_PCORE = 1
                
                state = STATE_TOPLEVEL
                line_count = 0
                
                fin = open(filename,"r")
                
                self.pcores = []
                self.toplevel = []
                
                pcore = None
                
                while True:
                        line_count += 1
                        line = fin.readline()
                        if not line:
                                if state == STATE_PCORE:
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
                                        state = STATE_PCORE
                                        pcore = MHSPCore(s)
                                        continue
                                else:
                                        self.toplevel.append(MHSLine(line,line_count))
                                        continue
                        else:
                                if name == "END":
                                        state = STATE_TOPLEVEL
                                        self.pcores.append(pcore)
                                        continue
                                else:
                                        pcore.addLine(MHSLine(line,line_count))
                                        continue
                                        
        def __str__(self):
                result = ""
                for k in self.toplevel:
                        result += str(k) + "\n"
                                
                for pcore in self.pcores:
                        result += "\n" + str(pcore)
                        
                return result
                        
        def getPcores(self,ip_name):
                result = []
                for pcore in self.pcores:
                        if pcore.ip_name == ip_name:
                                result.append(pcore)
                return result
                
        def getPcore(self,instance_name):
                for pcore in self.pcores:
                        if pcore.instance_name == instance_name:
                                return pcore
                return None
                
        def delPcore(self, instance_name):
                pcore = self.getPcore(instance_name)
                self.pcores.remove(pcore)

                                        
def createReconosSlot(num, plb_name = "plb", dcr_name = "dcr", clock = "sys_clk_s", reset = "sys_bus_reset", ip_core = osif_ip_core, inst_name = osif_inst_name, ip_version = osif_ip_version, plb_ver = '34', connect = True):
        """create a reconos slot instance"""
        sys.stderr.write("reconos_ip_version = %s\n" % reconos_ip_version)
	sys.stderr.write("osif_ip_version    = %s\n" % osif_ip_version)
        pcore = MHSPCore(ip_core)
        pcore.instance_name = inst_name + "_%i" % num
        pcore.addEntry("PARAMETER","HW_VER",ip_version)
        pcore.addEntry("PARAMETER","C_DCR_BASEADDR","0b%s" % ntob(num*reconos_dcr_size + reconos_dcr_base_addr, 10))
        pcore.addEntry("PARAMETER","C_DCR_HIGHADDR","0b%s" % ntob((num + 1)*reconos_dcr_size + reconos_dcr_base_addr - 1, 10))
        if plb_ver in ('34'):      # only when we have a plb slave interface
            pcore.addEntry("PARAMETER","C_BASEADDR","0x%08X" % (num*reconos_size + reconos_base_addr))
            pcore.addEntry("PARAMETER","C_HIGHADDR","0x%08X" % ((num + 1)*reconos_size + reconos_base_addr - 1))
        pcore.addEntry("PORT", "sys_clk", clock)
        pcore.addEntry("PORT", "sys_reset", reset)
        pcore.addEntry("BUS_INTERFACE", plb_if_types[plb_ver], plb_name)
        pcore.addEntry("BUS_INTERFACE", "SDCR", dcr_name)
        
        if not connect:
                return pcore
        
        pcore.addEntry("BUS_INTERFACE", "OSIF", pcore.instance_name + "_OSIF")
        pcore.addEntry("PORT", "interrupt" ,pcore.instance_name + "_interrupt")
        
        return pcore
        
def createReconosTask(num_slot, num_task, task_name = "hw_task", task_clk = None, osif_clk = None, connect = True):
        """create a hw_task connected to a reconos slot"""
        pcore = MHSPCore(task_name)
        pcore.instance_name = task_name + "_%i" % num_slot
        pcore.addEntry("PARAMETER","HW_VER","1.%02i.b" % num_task)
        if task_clk:
            pcore.addEntry("PARAMETER", "C_DEDICATED_CLK", "1")
        
        if not connect:
                return pcore
                
        pcore.addEntry("BUS_INTERFACE", "OSIF" ,osif_inst_name + "_" + str(num_slot) + "_OSIF")

        if task_clk:
            pcore.addEntry("PORT", "i_threadClk", task_clk)
        if osif_clk:
            pcore.addEntry("PORT", "clk", osif_clk)
                
        return pcore


