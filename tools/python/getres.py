#!/usr/bin/env python
#
# \file getres.py
#
# Retrieves resource usage from an EDK or XST/map/par implementation run
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       24.10.2008
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

import re, os, glob, datetime

# keys for default printing
defaultKeys = ['occupied Slices', '4 input LUTs (total)', 'Slice Flip Flops']
# print preference
printAll = False


def allFiles(pattern, searchPath, pathsep=os.pathsep):
    '''Yield all files matching a search pattern.
    From Martelli: Python Cookbook, Recipe 2.19'''
    
    for path in searchPath.split(pathsep):
        for match in glob.glob(os.path.join(path, pattern)):
            yield match


def parseMap(filename):
    '''Parse a *.map file for resource utilization metrics.
    Results are returned as a dictionary with the resource string
    acting as key.'''

    retval = {}
    r = re.compile(r'^\s*(Total )?Number (of )?(.+):\s*([0-9,]+)')
    f = open(filename)
    for l in f:
        m = r.match(l)
        if m:
            key = m.group(3)
            if m.group(1):  # string start with 'Total'
                key = key + ' (total)'
            if not m.group(2):  # string doesn't contain 'Number of'
                key = 'LUTs ' + key
            value = m.group(4)
            retval[key] = value

    return retval
    

def age(filename):
    '''Determine the age of a file in seconds, measured from its 
    modification time. Returns a datetime instance.'''
    modTime = datetime.datetime.fromtimestamp(os.stat(filename).st_mtime)
    currTime = datetime.datetime.now()
    deltaT = currTime - modTime
    return deltaT


def mywalk(dir, pattern):
    '''Recursively finds all files matching pattern.'''
    for root, dirs, files in os.walk(dir):
        for d in dirs:
            dPath = os.path.join(root, d)
            for match in glob.glob(os.path.join(dPath, pattern)):
                yield match
            mywalk(dPath, pattern)


for f in mywalk('.', '*.map'):
    print 'Parsing ' + f + ':'
    print '%79s' %(' age: ' +  str(age(f)))
    d = parseMap(f)
    if printAll:
        keysToPrint = d.keys()
    else:
        keysToPrint = defaultKeys
    for k in keysToPrint:
        if d.has_key(k):
            print '%30s: %10s ' %(k, d[k])
