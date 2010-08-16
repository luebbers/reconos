#!/usr/bin/env python
#
# \file mkprmhs.py
#
# short_description
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

def exitUsage():
	sys.stderr.write("Usage: %s num_thread num_osifs [first_task_num]\n" % sys.argv[0])
	sys.exit(1)

if __name__ == "__main__":
	if len(sys.argv) < 3: exitUsage()
	
	first_task = 0
	if len(sys.argv) == 4:
		first_task = int(sys.argv[3])
	
	num_thread = int(sys.argv[1])
	num_osifs = int(sys.argv[2])
	
	print "PARAMETER VERSION = 2.1.0"
	print
	print
	for i in range(num_osifs):
		print "BEGIN hw_task"
		print "\tPARAMETER INSTANCE = hw_task_%d" % (i + first_task)
		print "\tPARAMETER HW_VER = 1.%02d.b" % num_thread
		print "END"
		print

