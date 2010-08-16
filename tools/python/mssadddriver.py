#!/usr/bin/env python
#
# \file mssadddriver.py
#
# add generic osif drivers to a mss file
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
import reconos.mhs


def exitUsage():
	sys.stderr.write("Usage: %s <mss_file> num_osifs\n" % sys.argv[0])
	sys.exit(1)
	
	
if __name__ == "__main__":
	
	if len(sys.argv) < 3: exitUsage()
		
	mss_orig = sys.argv[1]
	num_slots = int(sys.argv[2])
	
	mss_file = open(mss_orig,"r")
	
	while 1:
		line = mss_file.readline()
		if not line:
			break
		
		sys.stdout.write(line)
		
	for i in range(num_slots):
		s = """BEGIN DRIVER
 PARAMETER DRIVER_NAME = generic
 PARAMETER DRIVER_VER = 1.00.a
 PARAMETER HW_INSTANCE = osif_%d
END

""" % i
		sys.stdout.write(s)


