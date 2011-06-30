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

import sys, slop, os
import reconos.mhs

    
def main(argv): 

    opts, args = slop.parse([
        ("o", "osif_clk", "use a separate OSIF clock. " 
                          "If -c is not specified, this is also used as the thread clock.", True),
        ("c", "thread_clk", "use a thread clock different from the OSIF's sys_clk.", True)], 
        args=argv, banner="%prog [options] mhs_file")

    thread_clk = opts["thread_clk"]
    osif_clk = opts["osif_clk"]

    if len(args) != 1:
        opts.help()
        sys.exit(2)
    
    mhs_orig = args[0]
    
    
    # parse mhs file
    a = reconos.mhs.MHS(mhs_orig)
    
    # get the number of reconos slots
    num_slots = len(a.getPcores("osif"))
    num_slots += len(a.getPcores("plb_osif"))
    num_slots += len(a.getPcores("xps_osif"))
    
    # we need at least one slot
    if num_slots == 0:
		print "error: no reconos slot in file '%s'" % mhs_orig
		sys.exit(2)
    
    # abort if there are already hw_tasks in the design
    if len(a.getPcores("hw_task")) > 0:
		print "error: file '%s' already contains %i hw_task instances" % (mhs_orig,len(a.getPcores("hw_task")))
		sys.exit(3)
    
    # add tasks
    # if current_task_num < 0:
    for i in range(num_slots):
        task = reconos.mhs.createReconosTask(i,i + 1,task_clk = thread_clk, osif_clk = osif_clk)
        a.pcores.append(task)
        
    # ouput resulting mhs file
    print a
        
        
if __name__ == "__main__":
	main(sys.argv[1:])
    
    
    
    

