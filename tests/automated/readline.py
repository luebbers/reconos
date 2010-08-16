#!/usr/bin/python
"""
Readline with timeout

Used for automated test case execution for ReconOS
"""
#
# \file readline.py
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

import os,fcntl,time,sys,select


def readlines(fin, timeout, max_lines):
	fd = fin.fileno()
	fl = fcntl.fcntl(fd, fcntl.F_GETFL)
	fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
	
	t = time.time()
	tend = t + timeout
	line = ""
	lines = []
	
	while time.time() < tend:
		try:
			if fin.closed: break
			a1,a2,a3 = select.select([fin],[],[],1)
			if len(a1) > 0:
				chunk = fin.read(1000000)
				if len(chunk) == 0: # EOF
					break
				for c in chunk:
					line += c
					if c == "\n":
						lines.append(line)
						line = ""
						if max_lines and len(lines) >= max_lines:
							return lines
			else:
				continue

		except IOError, err:
			print "IOERROR"
			continue
			
		if fin.closed:
			print "FIN.CLOSED"
			return lines
			
	if line: lines.append(line)
	return lines


if __name__ == "__main__":
	while True:
		line = readline(sys.stdin,5.0)
		if line == None:
			print "TIMEOUT!"
			sys.exit(1)
		elif not line:
			print "EOF"
			sys.exit(2)
			
		print "ECHO: '" + line + "'"


