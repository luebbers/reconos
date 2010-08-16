#!/usr/bin/python
"""
Dumps Xilinx FPGA bitstreams with annotations
"""
#
# \file bitdump.py
#
# \author Enno Luebbers <luebbers@reconos.de>
# \date   27.10.2009
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

import sys, array

# configuration
skipdata = True        # skip raw configuration data



def removeHeader(s):
    i = 0
    while(i < len(s)-3):
        if s[i:i+4].tolist() == [ 0xAA, 0x99, 0x55, 0x66 ]:
            return s[i:]
        i = i + 1
    return None
    
    
def switchendianess(a):
    i = 0
    while (i < len(a)):
        (a[i], a[i+1], a[i+2], a[i+3]) = (a[i+3], a[i+2], a[i+1], a[i])
        i = i + 4
    return a
    
opcodeStr = [ 'NOP', 'read', 'write', 'reserved']

registers = [ 'CRC',
              'FAR',
              'FDRI',
              'FDRO',
              'CMD',
              'CTL',
              'MASK',
              'STAT',
              'LOUT',
              'COR',
              'MFWR',
              'CBC',
              'IDCODE',
              'AXSS' ]
              
IDcodes = { 0x01658093 : 'XC4VLX15',
            0x0167C093 : 'XC4VLX25',
            0x016A4093 : 'XC4VLX40',
            0x016B4093 : 'XC4VLX60',
            0x016D8093 : 'XC4VLX80',
            0x01700093 : 'XC4VLX100',
            0x01718093 : 'XC4VLX160',
            0x01734093 : 'XC4VLX200',
            0x02068093 : 'XC4VSX25',
            0x02088093 : 'XC4VSX35',
            0x020B0093 : 'XC4VSX55',
            0x01E58093 : 'XC4VFX12',
            0x01E64093 : 'XC4VFX20',
            0x01E8C093 : 'XC4VFX40',
            0x01EB4093 : 'XC4VFX60',
            0x01EE4093 : 'XC4VFX100',
            0x01F14093 : 'XC4VFX140'  }
            
commands = {  0 : 'NULL    : null command',
              1 : 'WCFG    : write configuration data',
              2 : 'MFWR    : multiple frame write',
              3 : 'LFRM    : last frame',
              4 : 'RCFG    : read configuration data',
              5 : 'START   : begin startup sequence',
              6 : 'RCAP    : reset capture',
              7 : 'RCRC    : reset CRC',
              8 : 'AGHIGH  : assert GHIGH_B',
              9 : 'SWITCH  : switch CCLK frequency',
             10 : 'GRESTORE: pulse GRESTORE',
             11 : 'SHUTDOWN: begin shutdown sequence',
             12 : 'GCAPTURE: pulse GCAPTURE',
             13 : 'DESYNC  : reset DALIGN' }
             

# returns a tuple (skip, meaning, lookup)
#   skip:    how many words to skip until next decodable word
#   meaning: string describing current word
#   lookup:  dictionary to look up next word (e.g. IDCODE)
def decode(word):
    if word == 0xAA995566:
        return (0, "sync word", None)
        
    header    = (word & 0xE0000000) >> 29
    opcode    = (word & 0x18000000) >> 27

    if header == 1:
        register  = (word & 0x07FFE000) >> 13
        reserved  = (word & 0x00001800) >> 11
        wordcount = (word & 0x000007FF)
        
        if opcode == 0:
            return (wordcount, "NOP", None)

        if register == 0:   # CRC
            return (wordcount, opcodeStr[opcode] + " CRC register", None)
        if register == 1:   # FAR
            pass
        if register == 2:   # FDRI
            pass
        if register == 3:   # FDRO
            pass
        if register == 4:   # CMD
            return (wordcount, opcodeStr[opcode] + " command register", commands)
        if register == 5:   # CTL
            pass
        if register == 6:   # MASK
            pass
        if register == 7:   # STAT
            pass
        if register == 8:   # LOUT
            pass
        if register == 9:   # COR
            pass
        if register == 10:  # MFWR
            pass
        if register == 11:  # CBC
            pass
        if register == 12:  # IDCODE
            return (wordcount, opcodeStr[opcode] + " IDCODE register", IDcodes)
        if register == 13:  # AXSS
            pass
        
        return (wordcount, "%s %s register (%d word(s))" % (opcodeStr[opcode], registers[register], wordcount), None)
    
    if header == 2:
        wordcount = (word & 0x07FFFFFF)
        return (wordcount, "Type 2 data frame (%d word(s))" % (wordcount), None)
        
    return (0, "Unknown", None)
    

# read file
filename = sys.argv[1]
infile = open(filename, "rb")
raw = infile.read()
infile.close()

# remove header
bytes = array.array('B', raw)
bytes = removeHeader(bytes)
if not bytes:
    print "not a bitfile"
    sys.exit(-1)

# remove trailing bytes
if (len(bytes) % 4) != 0:
    bytes = bytes[:-(len(bytes) % 4)]       # cut trailing bytes

# convert to ints    
data = array.array('L', switchendianess(bytes).tostring())

i = 0
while i < len(data):
    (skip, meaning, lookup) = decode(data[i])
    print         "%8d: 0x%08X     %s" % (i, data[i], meaning)
    if skip > 0:
        if lookup:
            for j in range(skip):
                print "%8d: 0x%08X         %s" % (i+j+1, data[i+j+1], lookup[data[i+j+1]])
        elif skipdata:
            if skip > 1:
                unit = "words"
            else:
                unit = "word"
            print "\t... %d %s ..." % (skip, unit)
        else:
            for j in range(skip):
                print "%8d: 0x%08X" % (i+j+1, data[i+j+1])
                
    i = i + 1 + skip
    
