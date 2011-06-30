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

import sys, slop

def main(arguments):

    opts, args = slop.parse([
        ("p", "parameter", "parameter to set in hw thread wrapper", True,
            {"as" : "list", "default" : []})], 
        banner = "%prog [options] num_thread num_osifs [first_task_num]",
        args=arguments)

    parameters = opts["parameter"]

    if len(args) < 2:
        opts.help()
        sys.exit(2)
	
    first_task = 0
    if len(args) == 3:
        first_task = int(args[2])
    
    num_thread = int(args[0])
    num_osifs = int(args[1])
    
    print "PARAMETER VERSION = 2.1.0"
    print
    print
    for i in range(num_osifs):
	print "BEGIN hw_task"
        print "\tPARAMETER INSTANCE = hw_task_%d" % (i + first_task)
        print "\tPARAMETER HW_VER = 1.%02d.b" % num_thread
        for p in parameters:
            print "\tPARAMETER %s" % p
        print "END"
        print
    
    
if __name__ == "__main__":
    main(sys.argv[1:])

