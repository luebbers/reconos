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
import getopt



def exitUsage():
    sys.stderr.write('USAGE: ' + os.path.basename(sys.argv[0]) + ' -n hwthread_name -t CPUTYPE [-i include dir] [-a address -s size] [-e ecos_size] <source_file(s)> \n')
    sys.stderr.write("          -n hwthread_name        the name of the hw-task dir in HWTHREADS\n")
    sys.stderr.write("          -t cpu_type             which kind of CPU (PPC405|MICROBLAZE) \n")
    sys.stderr.write("          -i include dir          if there is another include dir except of the sw-dir use this option\n")
    sys.stderr.write("          -a address -s size      With these args you can specifiy the location in RAM and the size reserved in RAM \n")
    sys.stderr.write("                                  for the CPU_HWTHREAD program(HEX-VALS: e.g. 0x02000000). By default the first 32MB are\n")
    sys.stderr.write("                                  for ecos and 4MB for each CPU_HWTHREAD program are reserved. If you add\n") 
    sys.stderr.write("                                  these args, you have to check manually for overlapping regions with other programs!!!\n")
    sys.stderr.write("          -e ecos_size          if eCos should be greater than 32MB define the size in HEX\n")
    sys.stderr.write("          -p platform           Which FPGA: virtex4 \n")
    sys.stderr.write("                                This Parameter is for the PPC405. If virtex4 is used then use \"-p virtex4\"\n")
    sys.stderr.write("                                In case of virtex2 no parameter has to be set, this is used as standard\n")
    sys.stderr.write("          source_file(s)         the sourcefile(s)(only the c file(s)) which are used by the cpu-hwt\n")
    sys.exit(1)

def main(args):
            
    if os.environ["RECONOS"] == "":
        sys.stderr.write("RECONOS environment variable not set.\n")
        sys.exit(1)
    
    #parsing args
    try:
        opts, args = getopt.getopt(args, "n:t:i:a:s:e:p:")
    except getopt.GetoptError, err:
        # print help information and exit:
        print str(err) # will print something like "option -a not recognized"
        exitUsage()

    hwthread_name = None
    cpu_type = None
    files = args
    #optional args
    include_dir = None
    thread_addr = None
    thread_size = None
    ecos_size = None
    platform = None
    for o, a in opts:
        if o == "-n":
            hwthread_name = a
        elif o in ("-h", "--help"):
            exitUsage()
        elif o == "-t":
            cpu_type = a
        elif o == "-i":
            include_dir = a
        elif o == "-a":
            thread_addr = a
        elif o == "-s":
            thread_size = a
        elif o == "-e":
            ecos_size = a
        elif o == "-p":
            platform = a
            
            
    #check if needed args are set
    if hwthread_name == None:
        sys.stderr.write("No hwthread name!\n")
        exitUsage()
    if cpu_type == None:
        sys.stderr.write("No CPU_TYPE!\n")
        exitUsage()
    if (files == None) or (len(files) == 0):
        sys.stderr.write("No Sourcefile!\n")
        exitUsage()
    #check if size AND addr arg are set
    if ( (thread_addr == None) ^ (thread_size == None) ):
       sys.stderr.write("Arguments for thread_size and address are not set correctly\n")
       exitUsage() 
    #check platform argument
    if(platform != None):
        if (platform != "virtex4"):
            sys.stderr.write("Unknown platform\n")
            exitUsage() 
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
