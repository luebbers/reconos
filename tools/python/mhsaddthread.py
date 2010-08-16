#!/usr/bin/env python
#
# \file mhsaddthread.py
#
# Add hw_threads to a mhs file
#
# Each task gets connected to its corresponding reconos slot. 
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

import sys, getopt, os
import reconos.mhs

def exit_usage():
    sys.stderr.write("Usage: %s [-o osif_clk] [-c thread_clk] [ -n task_num ] <mhs_file>\n" % os.path.basename(sys.argv[0]))
    sys.stderr.write("       -o     use a separate OSIF clock\n" +
                     "              If -c is not specified, this is also used as the thread clock.\n")
    sys.stderr.write("       -c     use a thread clock different from the OSIF's sys_clk.\n")
    # sys.stderr.write("       -n     specifiy task num (starting at 1)\n")
    # sys.stderr.write("       Use the optional task_num argument to point all slots to the same pcore\n")
    sys.exit(1)
    
    
def main(argv): 

    args = None
    try:
        opts, args = getopt.getopt(argv, "o:c:h")
        # opts, args = getopt.getopt(argv, "o:c:n:h")
    except getopt.GetoptError:
        exit_usage()

    thread_clk = None
    osif_clk = None
    current_task_num = -1

    for opt, arg in opts:
        if opt == "-c":
            thread_clk = arg
        if opt == "-o":
            osif_clk = arg
        # if opt == "-n":
        #     current_task_num = int(arg)
        #     if current_task_num < 0:
        #         raise "error: task_num must be >= 0"
        if opt == "-h":
            exit_usage()

    if len(args) != 1: exit_usage()
    
    mhs_orig = args[0]
    
    
    # parse mhs file
    a = reconos.mhs.MHS(mhs_orig)
    
    # get the number of reconos slots
    num_slots = len(a.getPcores("osif"))
    num_slots += len(a.getPcores("plb_osif"))
    num_slots += len(a.getPcores("xps_osif"))
    
    # we need at least one slot
    if num_slots == 0:
        raise "error: no reconos slot in file '%s'" % mhs_orig
    
    # abort if there are already hw_tasks in the design
    if len(a.getPcores("hw_task")) > 0:
        raise "error: file '%s' already contains %i hw_task instances" % (mhs_orig,len(a.getPcores("hw_task")))
    
    # add tasks
    # if current_task_num < 0:
    for i in range(num_slots):
        task = reconos.mhs.createReconosTask(i,i + 1,task_clk = thread_clk, osif_clk = osif_clk)
        a.pcores.append(task)
    # else:
    #     for i in range(num_slots):
    #         task = reconos.mhs.createReconosTask(i,current_task_num,task_clk = thread_clk, osif_clk = osif_clk)
    #         a.pcores.append(task)
        
    # ouput resulting mhs file
    print a
        
        
if __name__ == "__main__":
    main(sys.argv[1:])
    
    
    
    

