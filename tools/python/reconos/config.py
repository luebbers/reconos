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

import os, sys


class ProjectConfig:
    '''Contains project configuration data as a dictionary.'''

    data = {}

    def __init__(self, fileName):
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
        return self.data[key]

    def __setitem__(self, key, value):
        self.data[key] = value

    def __str__(self):
        s = ""
        for k in self.data.keys():
            s = s + (str(k + ' = ' + str(self.data[k])) + os.linesep)
        return s

if __name__ == '__main__':
    p = ProjectConfig(sys.argv[1])

    print p

