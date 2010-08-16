#!/usr/bin/env python
"""
Creates a new ReconOS project
"""
#
# \file reconos_mkprj.py
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
# \file reconos_mkprj.py

import os, sys, shutil, re, string, reconos.tools

template_dir = os.environ['RECONOS'] + '/tools/makefiles/templates'
project_name = ''

def make_dirs():
    """Creates the basic directories"""

    if os.path.exists(project_name):
        sys.stderr.write('ERROR: ' + project_name + ' already exists.\n')
        sys.exit(1)

    print 'Creating directories:'

    print '    ' + project_name + '/'
    os.mkdir(project_name)

    print '    ' + project_name + '/sw'
    os.mkdir(project_name + '/sw')

    print '    ' + project_name + '/hw'
    os.mkdir(project_name + '/hw')
    print '    ' + project_name + '/hw/hwthreads'
    os.mkdir(project_name + '/hw/hwthreads')


def make_project_file():
    """Creates a template project file which the user should edit"""

    src = os.path.join(template_dir, 'project.rprj.template')
    dst = os.path.join(project_name, project_name + '.rprj')
    subst = [ ('\$template:layout\$', project_name + '.lyt') ]

    print 'Creating project file:\n    ' + dst + '       <- EDIT THIS TO FIT YOUR NEEDS!'

    reconos.tools.make_file_from_template(src, dst, subst)
   

def make_layout_file():
    """Creates a template layout file which the user should edit"""

    src = os.path.join(template_dir, 'project.lyt.template')
    dst = os.path.join(project_name, 'hw', project_name + '.lyt')

    print 'Creating layout file:\n    ' + dst + '       <- EDIT THIS TO FIT YOUR NEEDS!'
    shutil.copy(src, dst)

   

def make_settings_sh():
    """Create the settings.sh file to set up the environment"""

    print 'Creating settings file:'

    settings_file = os.path.join(project_name, 'settings.sh')
    print '    ' + settings_file
    f = open(settings_file, 'w')
    try:
        f.write('export HW_DESIGN=' + os.path.join(os.getcwd(), project_name, 'hw', 'edk-static') + '\n')
    finally:
        f.close()



def make_makefiles():
    """Creates the Makefiles"""

    project_file = project_name + '.rprj'

    print 'Creating Makefiles:'

    makefiles = (
            # dst,      src,                        substitutions
            ( '',       'Makefile_top.template',    None ),
            ( 'sw',     'Makefile_sw.template',     None ),
            ( 'hw',     'Makefile_hw.template', [    
                ( '\$template:project_file\$', os.path.join('..', project_file) )
            ] ),
            ( 'hw/hwthreads', 'Makefile_hw_hwthreads.template', None )
    )
    
    for dst, src, subst in makefiles:
        makefile_name = os.path.join(project_name, dst, 'Makefile')
        templ_name = os.path.join(template_dir, src)
        print '    ' + makefile_name
        reconos.tools.make_file_from_template(templ_name, makefile_name, subst)


if __name__ == '__main__':
    if os.environ["RECONOS"] == "":
        sys.stderr.write("RECONOS environment variable not set.\n")
        sys.exit(1)

    if (len(sys.argv) < 2):
        sys.stderr.write('USAGE: ' + os.path.basename(sys.argv[0]) + ' <project_name>\n')
        sys.exit(1)

    project_name = sys.argv[1]

    make_dirs()
    make_project_file()
    make_settings_sh()
    make_layout_file()
    make_makefiles()

    print '\nDon\'t forget to add your hardware threads using "reconos_addhwthread.py"\nin the ' + project_name + '/hw/hwthreads directory!'
    print 'You should source this file when working on this project:'
    print '    . ' + project_name + '/settings.sh'
    print 'Also, you will need to setup up the top of the sw/Makefile.'

