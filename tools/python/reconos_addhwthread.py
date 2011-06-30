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

import reconos.tools, sys, os, string, shutil, slop


def main(arguments):
	
    opts, args = slop.parse([
        ("l", "link", "link files instead of copying"),
        ("g", "generic", "set generic of hw thread", True, 
            {"as" : "array", "default" : []}),
        ("p", "parameter", "set parameter for hw thread WRAPPER. "
            "NOTE: use '=' instead of '=>'.", True,
            {"as" : "array", "default" : []}),
        ("a", "architecture", "target FPGA architecture (default:"
            "virtex6)", True, {"default" : "virtex6"})],
        banner = "%prog [options] <hwthread_name> <user_logic_entity> "
        "[<first file> <second_file> ...]")

    generics = opts["generic"]
    parameters = opts["parameter"]
    link = opts["link"]
    arch = opts["architecture"]

    if len(args) < 2:
        print "not enough arguments"
        opts.help()
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
        ('\$template:generics\$', "\"" + ",".join(generics) + "\""),
        ('\$template:wrapper_parameters\$', "\"" + ",".join(parameters) + "\"")
    ]
    templ_name = os.environ['RECONOS'] + '/tools/makefiles/templates/Makefile_hw_hwthreads_thread.template'
    makefile_name = os.path.join(hwthread_name, 'Makefile')
    reconos.tools.make_file_from_template(templ_name, makefile_name, subst)


if __name__ == '__main__':
	main(sys.argv[1:])
