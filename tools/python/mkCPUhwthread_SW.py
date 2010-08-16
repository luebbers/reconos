#!/usr/bin/env python
#
# \file mkCPUhwthread_SW.py
#
# manipulates the ecos linkerscript and creates the opt file for xmd
#
# \author     Robert Meiche <rmeiche@gmx.de>
# \date       05.08.2009
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
import getopt

def main(args):
    #parsing args
    try:
        opts, args = getopt.getopt(args, "e:")
    except getopt.GetoptError, err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        exitUsage()
    
    ecos_size = "64m" #standardsize
    for o, a in opts:
        if o == "-e":  
            ecos_size = a
    
    ecos_ls = 'ecos_build/install/lib/target.ld'
    
    lscript = open(ecos_ls, "r")
    linecount = 0
    lines = lscript.readlines()
    lscript.close()
    
    i = 0
    for line in lines:
        t = line.strip()
        s = t.split()
        i += 1
        if not t: continue
        if s[0] == 'bram':
            lines[i-1] = "bram : ORIGIN = 0xffffe000, LENGTH = 8k - 4\n"
        elif s[0] == 'ram':
            lines[i-1] = "ram : ORIGIN = 0x00000000, LENGTH = " + ecos_size +"\n"
    
    lscript = open(ecos_ls, "w")
    for line in lines:
        lscript.write(str(line))
        
    lscript.close()  
    #after editing eCos linkerscript write options file for XMD
    #xmdopts = open("xmdopts", "w")
    #xmdopts.write("connect ppc hw\n")
    #for arg in args:
    #    xmdopts.write("dow " + arg + "\n")
    
    #xmdopts.close()
    

if __name__ == "__main__":
    main(sys.argv[1:])
