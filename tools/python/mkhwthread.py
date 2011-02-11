#!/usr/bin/env python
#
# \file mkhwthread.py
#
# create a hw_task pcore
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

import sys
import os
import os.path
import reconos.pcore
import datetime
import getopt


task_name = "hw_task"

def exitUsage():
    sys.stderr.write("Usage: %s user_logic_entity [ -g \"SOME_GENERIC => 42\" ] thread_num [ vhdl_files... ] [ netlist_files... ]\n" % os.path.basename(sys.argv[0]))
    sys.stderr.write("\nNOTE: thread numbers start at 1!\n")
    sys.stderr.write("        If your generic's value includes quotes (e.g. X\"DEADBEEF\"),\n")
    sys.stderr.write("        you need to escape it twice: '-g SOME_GENERIC => X\\\\\\\"DEADBEEF\\\\\\\"'\n")
    sys.exit(1)

def main(arguments):
    
    try:
        opts, args = getopt.getopt(arguments, "g:", ["generic="])
    except getopt.GetoptError, err:
        print str(err)
        usage()
        sys.exit(2)

    generics = []

    for o, a in opts:
        if o in ("-g", "--generic"):
            # parse generic statement, e.g.
            # addthread -g "C_THREAD_NUM : integer := 2" ...
            # TODO: catch invalid generics?
            generics.append(a)
        else:
            assert False, "unhandled option"
        
    if len(args) < 2: exitUsage()
    
    if os.environ["RECONOS"] == "":
        sys.stderr.write("RECONOS environment variable not set.\n")
        sys.exit(1)
    
    user_logic_name = args[0]
    task_number = int(args[1])
    files = args[2:]
    vhdl_files = filter(lambda x: x[-4:] == ".vhd", files)
    # FIXME: this matches all files _containing_ .edn or .ngc, not just the suffixes (lazy me)
    netlist_files = filter(lambda x: x[-4:] == ".edn" or x[-4:] ==".ngc", files)
    pcore_name = task_name + "_v1_%02i_b" % task_number
    header = "generated at " + datetime.datetime.today().isoformat(" ") + " by '%s %s %s" % (os.path.basename(sys.argv[0]), user_logic_name, task_number)
    for i in vhdl_files:
        header = header + " " + i
    for n in netlist_files:
        header = header + " " + n
    header = header + "'" 
    
    reconos.pcore.createPCore(user_logic_name,task_number,vhdl_files,task_name,[os.environ["RECONOS"] + "/support/templates/coregen/burst_ram/burst_ram.edn"] + netlist_files,header,generics)

    print "pcore generated."
    print "Don't forget to put any additional user logic files into the %s directory." % (pcore_name + "/hdl/vhdl")
    print "Add a line in %s/data/%s_v2_1_0.pao for each file (before the last %s line)." % (pcore_name,task_name,task_name)

    
if __name__ == "__main__":
    main(sys.argv[1:])
    
