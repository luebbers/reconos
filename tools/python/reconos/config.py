#!/usr/bin/env python
"""
ReconOS configuration-related classes and functions.

Contains tools for reading configuration files.
"""
#
# \file config.py
#
# \author Enno Luebbers <luebbers@reconos.de>
# \date   15.06.2011
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# 
# This file is part of ReconOS (http://www.reconos.de).
# Copyright (c) 2006-2011 The ReconOS Project and contributors (see AUTHORS).
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

import os, sys, re
import reconos.layout

def replEnv(m):
        if m.group(2) != None:
            var = m.group(2)
        elif m.group(3) != None:
            var = m.group(3)
        else:
            assert False, "weird match"

        if var in os.environ:
            return os.environ[var]
        else:
            error("environment variable not found: %s" % var)


def expandEnv(s):
    """Expands any environmental variable in s with their values and returns
    the expanded string.
    Recognizes variables either as $VAR or $(VAR)"""
    return re.sub("\$(\((\w+)\)|(\w+))", replEnv, s)



class ProjectConfig:
    '''Contains project configuration data as a dictionary.'''

    data = {}
    parentDir = None

    def __init__(self, fileName):
        self.parentDir = os.path.abspath(os.path.dirname(fileName))
        inFile = open(fileName, "r")
        lines = inFile.read().split(os.linesep)
        inFile.close()
        # filter out empty lines and comments
        stmts = [line for line in lines if line != '' and line[0] != '#']
        # fill data dictionary
        for s in stmts:
            (key, value) = s.split('=')
            self.data[key.strip()] = value.strip()

    def __getitem__(self, key):
        """Returns value for key (after expansion of environment variables)"""
        return expandEnv(self.data[key])

    def __setitem__(self, key, value):
        self.data[key] = value

    def __str__(self):
        s = ""
        for k in self.data.keys():
            s = s + (str(k + ' = ' + str(self.data[k])) + os.linesep)
        return s

    def getNumSlots(self, type="all"):
        """Return number of slots present in project

        Optional argument: type
            Can be "all" for all slots, "dynamic" for the number of
            dynamic slots, and "static" for the number of static slots.
            Returns -1 for any other type."""

        # retrieve number of static slots (coming from the number of static
        # threads)
        if not "STATIC_THREADS" in self.data.keys():
            numStaticSlots = 0
        else:
            numStaticSlots =  len(self.data["STATIC_THREADS"].split())

        # if we want to know only the static slots, we're done here
        if type == "static":
            return numStaticSlots

        # retrive the number of dynamic slots (from the layout file if there
        # are any dynamic threads)
        if not "DYNAMIC_THREADS" in self.data.keys():
            numDynamicSlots = 0
        else:
            # retrieve layout file
            assert "LAYOUT" in self.data.keys(), "no layout found in project '%s'" % projectFile
            layoutFile = self.parentDir + "/" + self.data["LAYOUT"]
            f = open(layoutFile)
            l = reconos.layout.LayoutParser.read(f)
            f.close()
            numDynamicSlots = len(l.slots)

        if type == "dynamic":
            return numDynamicSlots

        if type == "all":
            return numDynamicSlots + numStaticSlots

        return -1


if __name__ == '__main__':
    p = ProjectConfig(sys.argv[1])

    print p

