#
# \file rsimguiAppDelegate.py
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

class rsimguiAppDelegate(NSObject):
    threadsWindow = IBOutlet()
    logWindow = IBOutlet()
    simulationWindow = IBOutlet()
    schedulingView = IBOutlet()
    # for multitplexing data source calls from two table views
    threadTableView = IBOutlet()
    coreTableView = IBOutlet()

    colorTable = (
        NSColor.redColor(),  
        NSColor.greenColor(),  
        NSColor.orangeColor(),  
        NSColor.blueColor(),  
        NSColor.yellowColor(), 
        NSColor.darkGrayColor(),  
        NSColor.cyanColor(),  
        NSColor.magentaColor(),  
        NSColor.purpleColor(),  
        NSColor.brownColor(),  
        NSColor.clearColor(),  
        NSColor.lightGrayColor(),  
        NSColor.whiteColor(),  
        NSColor.blackColor(),
        NSColor.grayColor()
    )  

    def applicationDidFinishLaunching_(self, sender):
        NSLog("Application did finish launching.")
		
    
    def init(self):
        self = super(rsimguiAppDelegate, self).init()
        if self is None:
            return None
    
        # dummy data
        A = Core(computationTime = 55,
                 color           = self.colorTable[0],
                 name            = 'Core A')

        B = Core(computationTime = 45,
                 color           = self.colorTable[1],
                 name            = 'Core B')

        C = Core(computationTime = 10,
                 color           = self.colorTable[2],
                 name            = 'Core C')
        
        A1 = Thread(core        = A,
                    priority    = 2,
                    releaseTime = 0,
                    name        = 'A1')

        B1 = Thread(core        = B,
                    priority    = 3,
                    releaseTime = 0,
                    name        = 'B1')

        C1 = Thread(core        = C,
                    priority    = 1,
                    releaseTime = 0,
                    deadline    = 60,           # executes after B1, so might not make B1s deadline
                    dependencies = [B1],
                    name        = 'C1')

        self.cores = [A, B, C]
        self.threads = [A1, C1, B1]

        self.time = -1
        self.eventLog = []
        
        self.lastAssignedCoreColor = -1

        NSLog("App initialized.")
        
        return self
    
    # functions for being an event logger
    def logEvent(self, event):
        # create default internal dictionary keys
        event['drawOtherEvents'] = False
        self.eventLog.append(event)


    # functions to implement the NSTableDataSource protocol (we are its data source)
    def numberOfRowsInTableView_(self, aTableView):
        NSLog(u'numberOfRows called from aTableView "' + str(aTableView) + '"')
        NSLog(u'self.threadTableView is "' + str(self.threadTableView) + '"')
        NSLog(u'self.coreTableView is "' + str(self.coreTableView) + '"')
        if aTableView is self.threadTableView:
            return len(self.threads)
        elif aTableView is self.coreTableView:
            return len(self.cores)
        return 0

    def tableView_objectValueForTableColumn_row_(self, aTableView, aTableColumn, rowIndex):
        if aTableView is self.threadTableView:
            model = self.threads
        elif aTableView is self.coreTableView:
            model = self.cores
        key = aTableColumn.identifier()
        if key in model[rowIndex].__dict__:
            return model[rowIndex].__dict__[key]
        else:
            return None
        
    def tableView_setObjectValue_forTableColumn_row_(self, aTableView, anObject, aTableColumn, rowIndex):
        if aTableView is self.threadTableView:
            model = self.threads
        elif aTableView is self.coreTableView:
            model = self.cores
        key = aTableColumn.identifier()
        if key == 'color':
            pass
        elif key in ('priority', 'period', 'computationTime', 'releaseTime'):
            model[rowIndex].__dict__[key] = int(anObject)
        else:
            model[rowIndex].__dict__[key] = anObject


    # handle table add/remove actions
    def addThread(self, coreIndex):
        self.threads.append(Thread(name='Thread #' + str(len(self.threads)), core=self.cores[coreIndex]))
        self.logWindow.write_("Added Thread '" + self.threads[len(self.threads)-1].name + "'\n")
        
    def removeThread(self, index):
        self.logWindow.write_("Removed Thread '" + self.threads[index].name + "'\n")
        self.threads.pop(index)
        

    # handle table add/remove actions
    def addCore(self):
        self.lastAssignedCoreColor = self.lastAssignedCoreColor + 1
        self.cores.append(Core(name='Core #' + str(len(self.cores)), color=self.colorTable[self.lastAssignedCoreColor]))
        self.logWindow.write_("Added Core '" + self.cores[len(self.cores)-1].name + "'\n")
        
    def removeCore(self, index):
        self.logWindow.write_("Removed Core '" + self.cores[index].name + "'\n")
        self.cores.pop(index)




    # implement SchedulingDiagramViewDataSource protocol
    def numberOfLinesInSchedulingView_(self, sender):
        return self.simulationWindow.numSlots()

    def schedulingView_endTime(self, sender):
        if self.time > 0:
            return self.time
        else:
            return 0

    def schedulingView_eventLog(self, sender):
        return self.eventLog

		
    # handle simulation buttons
    def resetSimulation(self):
        self.time = -1
        self.logWindow.write_("Simulation reset.\n")
        for t in self.threads:
            t.reset()
        self.eventLog = []
        self.threadsWindow.setEditingEnabled_(True)
        self.schedulingView.reloadData()

        
    def runSimulation(self, runtime, numSlots):
        if self.time >= 0:
            runUntil = self.time + runtime
        else:
            runUntil = runtime
    
        while (self.time < runUntil):
            if not self.stepSimulation(numSlots):
                NSLog("No more events scheduled.")
                break

        
    def stepSimulation(self, numSlots):
        # check if we just started, then initialize scheduler
        if self.time == -1:
            self.logWindow.write_("Starting simulation.\n")
            self.slots = [ Slot(num=i, name='S%d' % i) for i in range(numSlots) ]
            self.scheduler = Scheduler(self.slots, self.cores, self.threads, logger=self.logWindow, eventLogger=self)
            self.simulationWindow.setEditingEnabled_(False)
            self.threadsWindow.setEditingEnabled_(False)

        lastTime = self.time
        self.time = self.scheduler.doNext()
        
        if self.time == None:
            self.time = lastTime
            self.logWindow.write_("No more events scheduled.\n")
            self.simulationWindow.setRunButtonsEnabled_(False)
            self.schedulingView.reloadData()
            return False
        
        # print status
        self.scheduler.printStatus()
        self.schedulingView.reloadData()
        return True
