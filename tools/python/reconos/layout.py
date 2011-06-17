#!/usr/bin/env python
#
# \file layout.py
#
# Parse ReconOS *.lyt layout files
#
# \author     Andreas Agne <agne@upb.de>
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

import sys
from pyparsing import Word, alphas, alphanums, nums, OneOrMore, Literal, Keyword, pythonStyleComment, ZeroOrMore

# GRAMMAR DEFINITION ========================================================
#
# Note: you cannot use setParseAction on a grammar element that
#       has a ResultsName attached, because setResultsName()
#       returns a _copy_ (that is then used in the grammar tree)
#       but the registered ParseAction operates on the _original_.
#       You might get away with setting the parse action on the
#       copy like:
#
#           someSymbol = KEYWORD + otherSymbol("otSym").setParseAction(someAction) + OTHER_KEYWORD
#
#       but that gets really ugly really quickly.
#

# terminal symbols
IDENT       = Word(alphas, alphanums + "_" + "-")
INT         = Word(nums)
DSP48       = Literal("DSP48")
RAMB16      = Literal("RAMB16")
RAMB18      = Literal("RAMB18")
RAMB36      = Literal("RAMB36")
FIFO16      = Literal("FIFO16")
MULT18x18   = Literal("MULT18x18")
DSP48       = Literal("DSP48")
PMVBRAM     = Literal("PMVBRAM")
SLICE       = Literal("SLICE")
UNDERSCORE  = Literal("_")
MINUS       = Literal("-")
COLON       = Literal(":")
X           = Literal("X")
Y           = Literal("Y")
END         = Keyword("end")
DEVICE      = Keyword("device")
PART        = Keyword("part")
FAMILY      = Keyword("family")
SLICE_RANGE = Keyword("slice_range")
RANGE       = Keyword("range")
TYPE        = Keyword("type")
LOC         = Keyword("loc")
BUSMACRO    = Keyword("busmacro")
SLOT        = Keyword("slot")
TARGET      = Keyword("target")

resource_str      = (DSP48 ^ RAMB16 ^ FIFO16 ^ MULT18x18 ^ RAMB18 ^
        RAMB36 ^ PMVBRAM)
location          = X + OneOrMore(INT) + Y + OneOrMore(INT)
resource_location = (resource_str ^ SLICE) + UNDERSCORE + location
range_str         = resource_location + COLON + resource_location

# clauses
device_clause         = DEVICE + IDENT("device")
part_clause           = PART + IDENT("part")
family_clause         = FAMILY + IDENT("family")
slice_range_clause    = SLICE_RANGE + range_str("range")
range_clause          = RANGE + resource_str("res") + range_str("range")
type_clause           = TYPE + IDENT("type")
loc_clause            = LOC + location("loc")

# blocks
busmacro_block  = BUSMACRO + type_clause + loc_clause + END
slot_block      = SLOT + IDENT("name") + slice_range_clause("slice_range") + ZeroOrMore(range_clause.setResultsName("res_range", listAllMatches=True)) + ZeroOrMore(busmacro_block) + END
target_block    = TARGET + device_clause + part_clause + family_clause + END

# root node
layout_file = target_block + OneOrMore(slot_block)

# CLASS HIERARCHY ===========================================================

#----------------------------------------------------------------------------
# Class BusMacro 
#----------------------------------------------------------------------------
class BusMacro(object):
    def __init__(self, slot, num = "unknown"):
        self.type = "unknown"
        self.loc = "unknown"
        self.slot = slot
        self.num = num     # TODO: ???
        
    def getLocation(self):
        return self.loc
        
    def isAsynchronous(self):
        return "_async" in self.type

    def isSynchronous(self):
        return "_sync" in self.type

    def isInput(self):
        return not self.isOutput()
        
    def isOutput(self):
        """Returns true if this busmacros has an 'enable' signal."""
        return "enable" in self.type
        
    def getName(self):
        return "busmacro_" + self.slot.getName() + "_" + str(self.num);
        
    def getType(self):
        return "busmacro_" + self.slot.layout.target.family.lower() + "_" + self.type

        
    def __str__(self):
        s = ""
        s += "    busmacro\n"
        s += "        type " + self.type + "\n"
        s += "        loc " + self.loc + "\n"
        s += "    end\n"
        return s



#----------------------------------------------------------------------------
# Class Slot 
#----------------------------------------------------------------------------
class Slot(object):
    """Represents a reconfigurable slot in a ReconOS system."""


    def __init__(self, layout):
        self.layout = layout
        self.name = "unknown"
        self.sliceRange = "unknown"
        self.ranges = {}
        self.busMacros = []
    
    def getSliceRange(self):
        return self.sliceRange
        
    def getRange(self, rangeType):
        if rangeType in self.ranges.keys():
            return self.ranges[rangeType]
        else:
            return None

    def getBRAMRange(self):
        return self.getRange("RAMB16")
    
    def getMult18x18Range(self):
        return self.getRange("MULT18x18")
        
    def read(self,fin):
        print "Reading not yet supported."
        sys.exit(-1)
            
    def getInputBusMacros(self):
        return filter(lambda x: x.isInput(), self.busMacros)
        
    def getOutputBusMacros(self):
        return filter(lambda x: x.isOutput(), self.busMacros)
        
    def getAsyncInputBusMacros(self):
        return filter(lambda x: x.isInput() and x.isAsynchronous(), self.busMacros)
        
    def getAsyncOutputBusMacros(self):
        return filter(lambda x: x.isOutput() and x.isAsynchronous(), self.busMacros)

    def getSyncInputBusMacros(self):
        return filter(lambda x: x.isInput() and x.isSynchronous(), self.busMacros)
        
    def getSyncOutputBusMacros(self):
        return filter(lambda x: x.isOutput() and x.isSynchronous(), self.busMacros)

    def getBusMacros(self):
        return self.busMacros
        
    def getName(self):
        return self.name
        
    def getAGName(self):
        return "AG_" + self.name
        
    def getOSIFInstName(self):
        tmp = self.getName().split("_")
        num = int(tmp[-1])
        return "osif_" + str(num)
        
    def __str__(self):
        s = ""
        s += "slot " + self.name + "\n"
        s += "    slice_range " + self.sliceRange + "\n"
        for k in self.ranges.keys():
            s += "    range   " + k + "   " + self.ranges[k] + "\n"
        
        s += "\n"

        for bm in self.busMacros:
            s += str(bm)

        s += "end\n\n"
            
        return s


#----------------------------------------------------------------------------
# Class Target 
#----------------------------------------------------------------------------
class Target(object):
    """Represents the target FPGA and family of a ReconOS Layout"""

    reconosVersion = "2.00.a"

    def __init__(self, device, part, family):
        self.device = device
        self.part = part
        self.family = family

    def __str__(self):
        s = "target\n"
        s += "    device          " + self.getDevice() + "\n"
        s += "    part            " + self.getPart() + "\n"
        s += "    family          " + self.getFamily() + "\n"
        s += "    reconos_version " + self.reconosVersion + "\n"
        s += "end\n\n"
        return s

    def getDevice(self):
        return self.device.lower()

    def getPart(self):
        return self.part.lower()

    def getFamily(self):
        return self.family.lower()



#----------------------------------------------------------------------------
# Class Layout 
#----------------------------------------------------------------------------
class Layout(object):
    """Represents the ReconOS system layout."""
    
    target = ""
    slots = []
        
    def getSlotNames(self):
        return map(lambda x: x.getName(), self.slots)
        
    def getSlotByName(self, name):
        return filter(lambda x: x.getName() == name, self.slots)[0]

    def getNumSlots(self):
        return len(self.slots)

    def getFPGA(self):
        print "ERROR: getFPGA is deprecated: use target.getDevice() instead!"
        return self.target.getDevice()
        
    def __str__(self):
        s = ""
        s += "# Reconos system layout file (version 3.1.0a)\n\n"
        
        s += str(self.target)

        for slot in self.slots:
            s += str(slot)
            
        return s


# UTILITY CLASSES and FUNCTIONS =============================================

#----------------------------------------------------------------------------
# Class LayoutParser 
#----------------------------------------------------------------------------
busmacroCount = 0       # FIXME: ugly global variable
haveSeenBusmacros = False
class LayoutParser(object):
    """Parses a .lyt file into a Layout object"""

    def on_busmacro(s, loc, toks):
        global haveSeenBusmacros
        if not haveSeenBusmacros:  # print only once
            print >> sys.stderr, "NOTE: 'busmacro' blocks are deprecated and will be ignored."
            haveSeenBusmacros = True

#        global busmacroCount
#        b = BusMacro(slot=None, num=busmacroCount)      # we set the slot later in on_slot()
#        busmacroCount = busmacroCount + 1
#        b.type = toks.type
#        # FIXME: is this the best way to get the location string?
#        b.loc = reduce(lambda x, y: str(x)+str(y), toks.loc)
#        return b


    def on_slot(s, loc, toks):
        sl = Slot(None)      # we set this later in read()
        sl.name = toks.name

        # extract slice range
        sl.sliceRange = reduce(lambda x, y: str(x)+str(y), toks.slice_range.range)

        # the res ranges can occur multiple times.
        # listAllMatches=True in the slot_block grammar definition
        # turns toks.res_range into a list
        for r in toks.res_range:
            sl.ranges[r.res] = reduce(lambda x, y: str(x)+str(y), r.range)    

        # collect all busmacros (that have already been parsed)
        sl.busMacros = filter(lambda x: type(x) == BusMacro, toks)

        # connect busmacros back with their slot
        for bm in sl.busMacros:
            bm.slot = sl

        return sl


    def on_target(s, loc, tocs):
        t = Target(tocs.device, tocs.part, tocs.family)
        return t

    # set parse actions
    busmacro_block.setParseAction(on_busmacro)
    slot_block.setParseAction(on_slot)
    target_block.setParseAction(on_target)


    @staticmethod
    def read(fin):
        """Read a .lyt file from 'fin'.
        Returns a Layout object on successful parse."""

        strng = fin.read()
        layout_file.ignore(pythonStyleComment)
        topObjects = layout_file.parseString(strng)
        l = Layout()
        # first parsed object is a Target
        l.target = topObjects[0]
        # all other objects are Slots
        l.slots = topObjects[1:]
        # connect slots back to their layout
        for s in l.slots:
            s.layout = l
        return l


# MAIN ======================================================================

if __name__ == "__main__":
    try:
        fin = open(sys.argv[1])
        l = LayoutParser.read(fin)
    except Exception, e:
        fin.close()
        print str(e)
        sys.exit(1)
    
    fin.close()
    
    print l
    
