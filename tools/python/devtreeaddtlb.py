#!/usr/bin/env python

"""
Adds TLb entry to device tree.
"""
#
# \file bitdump.py
#
# \author Andreas Agne <agne@upb.de>
# \date   22.08.2010
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

def usage():
	print "usage: %s <dts-input-file> <mhs-file>" % sys.argv[0]

def count_tabs(line):
	tabs = 0
	for c in line:
		if c == "\t": tabs = tabs + 1
		else: break
	return tabs

def dts_entry(tlb,tabs):
	entry = []
	dcrn = int(tlb["PARAMETER C_DCR_BASEADDR"][2:],2)
	dcr_high = int(tlb["PARAMETER C_DCR_HIGHADDR"][2:],2)
	entry.append("\t"*tabs + tlb["PARAMETER INSTANCE"] + ": tlb@%x" % dcrn + " {\n")
	entry.append("\t"*(tabs + 1) + "compatible = \"xlnx,tlb\";\n")
	entry.append("\t"*(tabs + 1) + "dcr-parent = <&ppc405_0>;\n")
	entry.append("\t"*(tabs + 1) + "dcr-reg = < 0x%x 0x%x >;\n" % (dcrn,dcr_high - dcrn + 1))
	entry.append("\t"*tabs + "} ;\n")	
	return entry

if len(sys.argv) != 3 or sys.argv[1] == "--help" or sys.argv[1] == "-h":
	usage()
	sys.exit(0)


dts = open(sys.argv[1],"r")
mhs = open(sys.argv[2],"r")
dts = dts.readlines()
mhs = mhs.readlines()

i = 0
tlbs = []

while True:
	while i < len(mhs):
		if mhs[i].strip() == "BEGIN osif_tlb": break
		i = i + 1
	
	if i == len(mhs): break

	tlb = {}
	i = i + 1
	while not mhs[i].strip() == "END":
		s = mhs[i].split("=")
		tlb[s[0].strip()] = s[1].strip()
		i = i + 1
	
	tlbs.append(tlb)

#sys.stderr.write("Found %d TLBs\n" % len(tlbs))

i = 0
while i < len(dts):
	if dts[i].strip() == "dcr_v29_0: dcr@0 {": break
	i = i + 1

if i == len(dts):
	print "Error: Could not find entry 'dcr_v29_0' in file '%s'." % sys.argv[1]

i = i + 1
p = 0
while p >= 0:
	line = dts[i].strip()
	if len(line) == 0: continue
	if "{" in line: p = p + 1
	if "}" in line: p = p - 1
	i = i + 1

i = i - 1
tabs = count_tabs(dts[i]) + 1
entry = []
for tlb in tlbs:
	entry = entry + dts_entry(tlb,tabs)

dts = dts[:i] + entry + dts[i:]

for line in dts:
	sys.stdout.write(line)

