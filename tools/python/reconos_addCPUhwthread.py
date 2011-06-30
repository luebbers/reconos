#!/usr/bin/env python
"""
Creates a new hardware thread inside a ReconOS project
"""
#
# \file reconos_addCPUhwthread.py
#
# \author     Robert Meiche   <rmeiche@gmx.de>
# \date       30.07.2009
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

import reconos.tools, sys, os, string, shutil
import slop

def main(args):
            
    if os.environ["RECONOS"] == "":
        sys.stderr.write("RECONOS environment variable not set.\n")
        sys.exit(1)
    
    #parsing args
    opts, args = slop.parse([
        ("n", "name",        "the name of the hw-task dir in HWTHREADS",                             True , {"optional" : False}),
        ("t", "cpu_type",    "which kind of CPU (PPC405|MICROBLAZE)",                                True , {"optional" : False}),
        ("i", "include_dir", "if there is another include dir except of the sw-dir use this option", True ),
        ("a", "address",     "address for CPU_HWTHREAD program",                                     True ),
        ("s", "size",        "size for CPU_HWTHREAD program. "
        "With these args you can specifiy the location in RAM and the size reserved in RAM "
        "for the CPU_HWTHREAD program(HEX-VALS: e.g. 0x02000000). By default the first 32MB are "
        "for ecos and 4MB for each CPU_HWTHREAD program are reserved. If you add "
        "these args, you have to check manually for overlapping regions with other programs!!!",     True ),
        ("e", "ecos_size",   "if eCos should be greater than 32MB define the size in HEX",           True ),
        ("p", "platform",    "which FPGA. "
        "This Parameter is for the PPC405. If virtex4 is used then use \"-p virtex4\" "
        "In case of virtex2 no parameter has to be set, this is used as standard.",                  True )],
        banner="%prog [options] -n <name> -t <cpu_type> <source_file(s)>", args=args)

    hwthread_name = opts["name"]
    cpu_type = opts["cpu_type"]
    files = args
    #optional args
    include_dir = opts["include_dir"]
    thread_addr = opts["address"]
    thread_size = opts["size"]
    ecos_size = opts["ecos_size"]
    platform = opts["platform"]
            
    #check if needed args are set
    if hwthread_name == None:
        sys.stderr.write("No hwthread name!\n")
        opts.help()
	sys.exit(2)
    if cpu_type == None:
        sys.stderr.write("No CPU_TYPE!\n")
        opts.help()
	sys.exit(2)
    if (files == None) or (len(files) == 0):
        sys.stderr.write("No Sourcefile!\n")
        opts.help()
	sys.exit(2)
    #check if size AND addr arg are set
    if ( (thread_addr == None) ^ (thread_size == None) ):
        sys.stderr.write("Arguments for thread_size and address are not set correctly\n")
        opts.help() 
	sys.exit(2)
    #check platform argument
    if(platform != None):
        if (platform != "virtex4"):
            sys.stderr.write("Unknown platform\n")
            opts.help() 
	    sys.exit(2)
    else:
        platform = "virtex2"

    # create hw thread directory
    os.mkdir(hwthread_name)
   
    # identify cpu type
    if cpu_type == 'PPC405':
        if (platform == "virtex2"):
            cpuhwt_pcore = 'ppc405_v2_00_d'
        elif (platform == "virtex4"):
            cpuhwt_pcore = 'ppc405_virtex4_v1_01_d'
    else:
        sys.stderr.write('Wrong CPUTYPE! CPUTYPES are: PPC405\n')
        sys.exit(1)
    #set optional args string
    opt_args = ''
    if include_dir != None:
        opt_args += "-i " + include_dir +" "
    if thread_addr != None:
        opt_args += "-a " + thread_addr + " -s " + thread_size +" "
    if ecos_size != None:
        opt_args += "-e " + ecos_size + " "
        
    # copy sourcecode files
    #for f in files:
    #    shutil.copy(f, hwthread_name)

    # set up substitutions for Makefile template
    subst = [ 
        ('\$template:source_files\$', string.join([ os.path.basename(f) for f in files ], ' ')), 
        ('\$template:architecture\$', platform),
        ('\$template:cpuhwt_type\$', cpu_type),
        ('\$template:cpuhwt_pcore\$', cpuhwt_pcore), 
        ('\$template:opt_args\$', opt_args)
        
    ]
    templ_name = os.environ['RECONOS'] + '/tools/makefiles/templates/Makefile_hw_cpuhwthreads_thread.template'
    makefile_name = os.path.join(hwthread_name, 'Makefile')
    reconos.tools.make_file_from_template(templ_name, makefile_name, subst)

if __name__ == '__main__':
    main(sys.argv[1:])
