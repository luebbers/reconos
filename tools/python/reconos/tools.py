#!/usr/bin/env python
#
# \file tools.py
#
# miscellaneous tool functions for reconos package
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

import re, shutil, string

def searchRegexInList(regex, lst, options = 0):
        "Returns a list of indexes where regex matches in lst"
        
        retVal = []

        exp = re.compile(regex, options)
        i = 0
        
        for l in lst:
                m = exp.search(l)
                if m:
                        retVal.append(i)
                i = i + 1

        return retVal


def getObjectByName(l, n):
        "Retrieves a reconos.vhdl object (like Component, Port, Instantiation, or Signal) from within a list by its name"
        
        for i in l:
                if i.name == n:
                        return i
                        
        return None

def replaceRegexInString(regex, replacement, string, options):

        exp = re.compile(regex, options)
        return exp.sub(replacement, string)


def make_file_from_template(src, dst, subst):
    """Creates a file 'dst' from template 'src', with template
substitutions 'subst', which is a list of tuples, or None"""

    if subst: 
        dstfile = open(dst, 'w')
        srcfile = open(src, 'r')
        try:
            text = srcfile.read().splitlines()
            for pattern, substr in subst:
                text[:] = [ re.sub(pattern, substr, line) for line in text ]
            text = string.join(text, '\n')
            dstfile.write(text)
        finally:
            srcfile.close()
            dstfile.close()
    else:
        shutil.copy(src, dst)

