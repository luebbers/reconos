#
# \file rsimguiMainWindowController.py
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       22.08.2009
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
from Foundation import *
from AppKit import *
from objc import YES, NO, IBAction, IBOutlet
from coop import *


class rsimguiMainWindowController (NSWindowController):
    application = IBOutlet()
    runButton = IBOutlet()
    stepButton = IBOutlet()
    numSlotsTextField = IBOutlet()
    runtimeTextField = IBOutlet()

        
    def setRunButtonsEnabled_(self, state):
        self.runButton.setEnabled_(state)
        self.stepButton.setEnabled_(state)
        
    def setEditingEnabled_(self, state):
        self.numSlotsTextField.setEnabled_(state)
        #self.runtimeTextField.setEnabled_(state)
        
        
    def runTime(self):
        return self.runtimeTextField.intValue()
        
    def numSlots(self):
        return self.numSlotsTextField.intValue()

    def resetSimulation_(self, sender):
        self.setRunButtonsEnabled_(True)
        self.setEditingEnabled_(True)
        self.application.resetSimulation()

    def runSimulation_(self, sender):
        runtime = self.runTime()
        numSlots = self.numSlots()
        self.application.runSimulation(runtime, numSlots)
        
    def stepSimulation_(self, sender):
        numSlots = self.numSlots()
        self.application.stepSimulation(numSlots)

        
