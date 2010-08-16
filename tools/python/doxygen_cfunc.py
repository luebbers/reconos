#!/usr/bin/env python
"""
Generates a Doxygen header for a C/C++ function
"""

#
# \file doxygen_cfunc.py
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       10.4.2008
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

import sys, string, re

# read stdin into seperate lines not ending in '\n'
stdin = sys.stdin.read()
lines = stdin.splitlines()

# remove '//'-style comments 
lines[:] = [ re.sub('//.*$', '', l) for l in lines ]

# remove line endings (join into one string)
text = string.join(lines, " ")

# remove C-style ('/* ... */') comments. '*?' is a non-greedy matcher
text = re.sub('/\*.*?\*/', '', text)

# find first opening bracket and extract preceding identifier as function
# name, as well as what's between the brackets as parameters.
mobj = re.search('(\w*) ?(\w+) *\((.*?)\)', text)
if mobj:
    returntype = mobj.group(1)
    if returntype != 'void':
        returnstr = '/// @returns <+return value+>\n/// '
    else:
        returnstr = None
    funcname = mobj.group(2)
    # extract parameters
    if mobj.group(3):
        params = mobj.group(3).split(',')
        # extract parameter name
        params[:] = [ re.search('(\w+)\s*$', p).group(1) for p in params ]
        # find longest parameter and construct format string for params
        maxlen = max(map(len, params))
        paramstr = '/// @param %-' + str(maxlen) + 's <+description+>'
    else:
        params = []
    # print comments
    print '/// '
    print '/// <+short description for ' + funcname + '+>'
    print '/// '
    print '/// <+long description+>'
    print '/// '
    if len(params) > 0:
        for p in params:
            print paramstr % p
        print '/// '
    if returnstr:
        print returnstr
else:
    print "// No match."

print stdin

