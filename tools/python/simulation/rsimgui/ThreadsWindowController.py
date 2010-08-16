#
# \file ThreadsWindowController.py
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

from objc import YES, NO, IBAction, IBOutlet
from Foundation import *
from AppKit import *

class ThreadsWindowController(NSWindowController):
    threadTableView = IBOutlet()
    coreTableView = IBOutlet()
    addThreadButton = IBOutlet()
    delThreadButton = IBOutlet()
    addCoreButton = IBOutlet()
    delCoreButton = IBOutlet()
    application = IBOutlet()
    
    # functions to react to changing selections in the table view (we are its delegate)
    def tableViewSelectionDidChange_(self, aNotification):
        if self.threadTableView.selectedRow() < 0:
            self.delThreadButton.setEnabled_(False)
        else:
            self.delThreadButton.setEnabled_(True)

        if self.coreTableView.selectedRow() < 0:
            self.delCoreButton.setEnabled_(False)
        else:
            self.delCoreButton.setEnabled_(True)


    def setEditingEnabled_(self, state):
        self.threadTableView.setEnabled_(state)
        self.coreTableView.setEnabled_(state)
        self.addThreadButton.setEnabled_(state)
        self.addCoreButton.setEnabled_(state)
        
        if self.threadTableView.selectedRow() < 0:
            self.delThreadButton.setEnabled_(False)
        else:
            self.delThreadButton.setEnabled_(state)

        if self.coreTableView.selectedRow() < 0:
            self.delCoreButton.setEnabled_(False)
        else:
            self.delCoreButton.setEnabled_(state)

    # handle table add/remove buttons
    def addThread_(self, sender):
        # if there are no cores, we can't add threads
        if not self.application.cores:
            alert = NSAlert.alloc().init()
            alert.addButtonWithTitle_(u'OK')
            alert.setMessageText_(u'You need to add Cores before you can add Threads.')
            alert.setAlertStyle_(NSWarningAlertStyle)
            alert.runModal()
        else:
            # if a core is selected, pass it to the addThread method
            # if no core is selected, use the first one
            row = self.coreTableView.selectedRow()
            if row < 0:
                row = 0
            self.application.addThread(row)
            self.threadTableView.reloadData()
        
    def removeThread_(self, sender):
        row = self.threadTableView.selectedRow()
        if row >= 0:
            self.application.removeThread(row)
            self.threadTableView.reloadData()


    def addCore_(self, sender):
        self.application.addCore()
        self.coreTableView.reloadData()
        
    def removeCore_(self, sender):
        row = self.coreTableView.selectedRow()
        if row >= 0:
            self.application.removeCore(row)
            self.coreTableView.reloadData()
