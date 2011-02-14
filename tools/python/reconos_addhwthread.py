#!/usr/bin/env python
"""
Creates a new hardware thread inside a ReconOS project
"""
#
# \file reconos_addhwthread.py
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       11.04.2008
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
# \file reconos_addhwthread.py

import reconos.tools, sys, os, string, shutil, getopt

def usage():
    sys.stderr.write('USAGE: ' + os.path.basename(sys.argv[0]) + ' [-g "GENERIC=>1"] [-l] <hwthread_name> <user_logic_entity> [<first_file> <second_file> ...]\n')
    sys.stderr.write('   -g "GENERIC => 1"   set generic of hw thread\n')
    sys.stderr.write('   -l                  link files instead of copying\n')
    sys.stderr.write('If you don\'t specify any files, you\'ll have to manually copy them\ninto the created directory and add them to the top of the Makefile.\n')
    sys.stderr.write('Actually, that is what you have to do if you want to add netlists (.ngc/.edn) to your hardware thread.\n')
	

def main(arguments):
	
    try:
        opts, args = getopt.getopt(arguments, "lg:a:", ["link", "generic=", "architecture="])
    except getopt.GetoptError, err:
        print str(err)
        usage()
        sys.exit(2)

    generics = []
    link = False
    arch = "virtex6"

    for o, a in opts:
        if o in ("-g", "--generic"):
            # parse generic statement, e.g.
            # addthread -g "C_THREAD_NUM : integer := 2" ...
            # TODO: catch invalid generics?
            generics.append(a)
        elif o in ("-l", "--link"):
            link = True
        elif o in ("-a", "--architecture"):
            arch = a;
        else:
            assert False, "unhandled option"
			
    if len(args) < 2:
        print "not enough arguments"
        usage()
        sys.exit(2)

    # unpack cmd line arguments
    hwthread_name, user_logic_entity = args[0:2]
    if len(args) > 2:
        files = args[2:]
    else:
        files = []

    # create hw thread directory
    os.mkdir(hwthread_name)

    # copy or link thread files
    for f in files:
        if link:
            os.symlink(os.path.abspath(f), hwthread_name + "/" + os.path.basename(f))
        else:
            shutil.copy(f, hwthread_name)

    # set up substitutions for Makefile template
    subst = [ 
        ('\$template:vhdl_files\$', string.join([ os.path.basename(f) for f in files ], ' ')),
        ('\$template:user_logic_entity\$', user_logic_entity),
        ('\$template:architecture\$', arch),
		('\$template:generics\$', "\"" + ",".join(generics) + "\"")
    ]
    templ_name = os.environ['RECONOS'] + '/tools/makefiles/templates/Makefile_hw_hwthreads_thread.template'
    makefile_name = os.path.join(hwthread_name, 'Makefile')
    reconos.tools.make_file_from_template(templ_name, makefile_name, subst)


if __name__ == '__main__':
	main(sys.argv[1:])