#!/usr/bin/python
"""
Compares output of test case with expected result
"""
#
# \file compare.py
#
# \author Andreas Agne <agne@upb.de>
# \date   08.02.2008
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



import sys

fin = open(sys.argv[1],"r")

# strips '\n', '\r' and '\0' from string s and returns the result
def strip_junk(s):
	result = ""
	for c in s:
		if c in ['\n','\r',chr(0)]: continue
		result += c
	return result

expect = []
	
while True:
	l = sys.stdin.readline()
	if not l: break
	
	expect.append(strip_junk(l))

i = 0
while True:
	l = fin.readline()
	if not l:
		print "Expected %d more lines of output" % (len(expect - i))
		sys.exit(1)
	
	l = strip_junk(l)
	if not l == expect[i]:
		print "Error in line %d" % (i + 1)
		print "Expected: '" + expect[i] + "'"
		print "Received: '" + l + "'"
		sys.exit(1)

	i = i + 1
	if i == len(expect): break

sys.exit(0)

