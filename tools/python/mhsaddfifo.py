#!/usr/bin/env python
#
# \file mhsaddfifo.py
#
# add hardware FIFO to a mhs file
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       21.11.2008
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
# \file mhsaddfifo.py

import sys
import reconos.mhs


def exitUsage():
	sys.stderr.write("Usage: %s <mhs_file> <write_slot_num> <read_slot_num>\n" % sys.argv[0])
        sys.stderr.write("       <write_slot_num>  number of OSIF slot writing to FIFO\n")
        sys.stderr.write("       <read_slot_num>   number of OSIF slot reading from FIFO\n")
	sys.exit(1)
	
	
if __name__ == "__main__":
	
	if len(sys.argv) < 4: exitUsage()
		
	mhs_orig = sys.argv[1]
        write_slot_num = int(sys.argv[2])
        read_slot_num = int(sys.argv[3])
	
	# parse mhs file
	a = reconos.mhs.MHS(mhs_orig)
	
	# get the number of reconos slots already present in the design
	current_slots = len(a.getPcores("osif"))
	
	# output a warning in case we have not enough slots
	if current_slots-1 < max((write_slot_num, read_slot_num)):
            sys.stderr.write("ERROR: not enough slots present in MHS!\n")
            sys.exit(1)

        write_slot = a.getPcore("osif_" + str(write_slot_num))
        read_slot = a.getPcore("osif_" + str(read_slot_num))

        # add write FIFO connection
        assert write_slot != None
        if write_slot.getValue("FIFO_WRITE"):
            sys.stderr.write("ERROR: osif_%s's FIFO_WRITE bus already connected!\n" % write_slot_num)
            sys.exit(1)
        write_slot.addEntry("BUS_INTERFACE", "FIFO_WRITE",
                            "osif_%s_FIFO_WRITE" % write_slot_num)
	
        # add read FIFO connection
        assert read_slot != None
        if read_slot.getValue("FIFO_READ"):
            sys.stderr.write("ERROR: osif_%s's FIFO_READ bus already connected!\n" % read_slot_num)
            sys.exit(1)
        read_slot.addEntry("BUS_INTERFACE", "FIFO_READ",
                            "osif_%s_FIFO_READ" % read_slot_num)

        # add FIFO core
        fifo_core = reconos.mhs.MHSPCore("mbox_fifo")
        num_fifos = len(a.getPcores("mbox_fifo"))
        fifo_core.instance_name = "mbox_fifo_%i" % num_fifos
        fifo_core.addEntry("PARAMETER", "HW_VER", "1.00.a")
        fifo_core.addEntry("BUS_INTERFACE", "FIFO_WRITE",
                            "osif_%s_FIFO_WRITE" % write_slot_num)
        fifo_core.addEntry("BUS_INTERFACE", "FIFO_READ",
                            "osif_%s_FIFO_READ" % read_slot_num)
        a.pcores.append(fifo_core)
	
	# output resulting mhs file to stdout
	print a


