#
# \file SchedulingView.py
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

class SchedulingView(NSView):
    dataSource = IBOutlet()

    defaultDrawingAttributes = {
        'yOffset': 50,
        'boxHeight': 10,
        'eventHeight': 20,
        'height' : 20,
        'xBorder': 30,
        'yBorder': 30,
        'arrowHeadWidth': 10,
        'arrowHeadHeight': 7,
        'axisColor': NSColor.grayColor(),
        'arrowColor': NSColor.blackColor(),
        'borderColor': NSColor.blackColor()
    }

    def initWithFrame_(self, frame):
        self = super(SchedulingView, self).initWithFrame_(frame)
        if self:
            self.numberOfLines = 0
            self.endTime = 500
            self.execEvents = []
            self.otherEvents = []
            self.showAllEvents = False
            
            # set tracking area
            self.trackingArea = NSTrackingArea.alloc().initWithRect_options_owner_userInfo_(
                frame, 
                NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect, 
                self, 
                None
            )
            self.addTrackingArea_(self.trackingArea)
        return self

    # use a flipped coordinate system (0,0 is in the top left corner)
    def isFlipped(self):
        return YES

    
    # handle MouseMoved events to display thread information
    def mouseMoved_(self, event):
        p = self.convertPoint_fromView_(event.locationInWindow(), objc.nil)
        exEv = self.execEventAtPoint(p)
        if exEv:
            NSLog(str(exEv))


    def setShowAllEvents_(self, sender):
        if sender.state() == NSOnState:
            self.showAllEvents = True
        else:
            self.showAllEvents = False
        self.setNeedsDisplay_(YES)
            
    
    # find slot line occupying a point in the view
    def lineAtPoint(self, aPoint, attributes=defaultDrawingAttributes):
        if self.numberOfLines <= 0: return None

        # get attributes
        yBorder = attributes['yBorder']
        yOffset = attributes['yOffset']
        height = attributes['height']

        y = aPoint[1]

        # check whether we're in the border areas
        if y < yBorder or y > (self.numberOfLines-1)*yOffset + yBorder + height:
            return None
        
        return int((y - yBorder) / yOffset)
    
            
    # find exec event in view coordinates
    def execEventAtPoint(self, aPoint, attributes=defaultDrawingAttributes):

        # get attributes
        xBorder = attributes['xBorder']

        # get coordinates as (time, line)
        line = self.lineAtPoint(aPoint)
        time = aPoint[0] - xBorder
        
        # look at all events in the pointed-at line
        for e in filter(lambda x:x['slot'] == line, self.execEvents):
            if e['start'] <= time and e['finish'] >= time:
                return e

        return None
        

    def drawRect_(self, rect):

        # get attributes
        attributes = SchedulingView.defaultDrawingAttributes
        yBorder = attributes['yBorder']
        yOffset = attributes['yOffset']
    
        # draw white background
        NSColor.whiteColor().set()
        NSRectFill(self.bounds())
        
        for i in range(self.numberOfLines):
            self.drawHorizontalAxis(i, attributes)
            
        for execEvent in self.execEvents:
            self.drawExecution(execEvent['slot'], execEvent['start'], execEvent['finish'], execEvent['thread'].core.color)
            # draw 'other' events, such as release and deadline times
            # these typically are not associated with a specific slot, so we use our execEvent's slot
            if self.showAllEvents or execEvent['drawOtherEvents']:
                otherEvents = filter(lambda x:x['thread'] is execEvent['thread'], self.otherEvents)
                for otherEvent in otherEvents:
                    if otherEvent['type'] == 'release':
                        self.drawRelease(execEvent['slot'], otherEvent['time'], color=otherEvent['thread'].core.color)
                    elif otherEvent['type'] == 'deadline':
                        self.drawDeadline(execEvent['slot'], otherEvent['time'], color=otherEvent['thread'].core.color)


    # determine y coordinate of baseline of line 'line'
    def baseY(self, line, attributes=defaultDrawingAttributes):
        yOffset = attributes['yOffset']
        yBorder = attributes['yBorder']
        height = attributes['height']
        return line*yOffset + yBorder + height     # baseline of this line


        
    def drawHorizontalAxis(self, line, attributes=defaultDrawingAttributes):
        xBorder = attributes['xBorder']
        y = self.baseY(line, attributes)
        
        attributes['axisColor'].set()
        path = NSBezierPath.bezierPath()
        path.moveToPoint_((xBorder, y))
        path.lineToPoint_((self.endTime + xBorder, y))
        path.closePath()
        path.stroke()
        self.drawRightArrowHead(self.endTime + xBorder, y, attributes)
        
        
    def drawRelease(self, line, time, attributes=defaultDrawingAttributes, color=None):
        xBorder = attributes['xBorder']
        eventHeight = attributes['eventHeight']
        y = self.baseY(line, attributes)
        x = time + xBorder
        
        attributes['arrowColor'].set()
        path = NSBezierPath.bezierPath()
        path.moveToPoint_((x, y-eventHeight))
        path.lineToPoint_((x, y))
        path.closePath()
        path.stroke()
        self.drawDownArrowHead(x, y, attributes, color)
        

    def drawDeadline(self, line, time, attributes=defaultDrawingAttributes, color=None):
        xBorder = attributes['xBorder']
        eventHeight = attributes['eventHeight']
        y = self.baseY(line, attributes)
        x = time + xBorder
        
        attributes['arrowColor'].set()
        path = NSBezierPath.bezierPath()
        path.moveToPoint_((x, y-eventHeight))
        path.lineToPoint_((x, y))
        path.closePath()
        path.stroke()
        self.drawUpArrowHead(x, y-eventHeight, attributes, color)

        
        
    def drawRightArrowHead(self, x, y, attributes=defaultDrawingAttributes):
        w = attributes['arrowHeadWidth']
        h = attributes['arrowHeadHeight']
        path = NSBezierPath.bezierPath()
        path.moveToPoint_((x-w, y-h/2))
        path.lineToPoint_((x, y))
        path.lineToPoint_((x-w, y+h/2))
        path.closePath()
        path.setLineJoinStyle_(NSMiterLineJoinStyle)
        path.fill()
        path.stroke()

    def drawDownArrowHead(self, x, y, attributes=defaultDrawingAttributes, color=None):
        w = attributes['arrowHeadWidth']
        h = attributes['arrowHeadHeight']
        path = NSBezierPath.bezierPath()
        path.moveToPoint_((x-h/2, y-w))
        path.lineToPoint_((x, y))
        path.lineToPoint_((x+h/2, y-w))
        path.closePath()
        path.setLineJoinStyle_(NSMiterLineJoinStyle)
        if color:
            color.set()
        path.fill()
        attributes['arrowColor'].set()
        path.stroke()

    def drawUpArrowHead(self, x, y, attributes=defaultDrawingAttributes, color=None):
        w = attributes['arrowHeadWidth']
        h = attributes['arrowHeadHeight']
        path = NSBezierPath.bezierPath()
        path.moveToPoint_((x-h/2, y+w))
        path.lineToPoint_((x, y))
        path.lineToPoint_((x+h/2, y+w))
        path.closePath()
        path.setLineJoinStyle_(NSMiterLineJoinStyle)
        if color:
            color.set()
        path.fill()
        attributes['arrowColor'].set()
        path.stroke()


    def drawExecution(self, line, start, finish, fillColor, open=False, attributes=defaultDrawingAttributes):
        boxHeight = attributes['boxHeight']
        xBorder = attributes['xBorder']
        y = self.baseY(line, attributes)
        x1 = start + xBorder
        x2 = finish + xBorder
        strokeColor = attributes['borderColor']
        
        fillColor.set()
        path = NSBezierPath.bezierPath()
        path.moveToPoint_((x2, y-boxHeight))
        path.lineToPoint_((x1, y-boxHeight))
        path.lineToPoint_((x1, y))
        path.lineToPoint_((x2, y))
        if not open:
            path.closePath()
        path.fill()
        strokeColor.set()
        path.stroke()


        
    def reloadData(self):
        attributes = SchedulingView.defaultDrawingAttributes
    
        # get data from datasource
        self.endTime = self.dataSource.schedulingView_endTime(self)
        self.numberOfLines = self.dataSource.numberOfLinesInSchedulingView_(self)
        self.eventLog = self.dataSource.schedulingView_eventLog(self)
        
        # filter relevant events
        self.execEvents = filter(lambda y:y['type'] == 'exec', self.eventLog)
        self.otherEvents = filter(lambda y:y['type'] in ('release', 'deadline'), self.eventLog)
        
        # get attributes
        xBorder = attributes['xBorder']
        yBorder = attributes['yBorder']
        yOffset = attributes['yOffset']
        height  = attributes['height']
        
        # determine size of graph
        if self.numberOfLines > 0 and self.endTime > 0:
            size = (self.endTime + 2*xBorder, (self.numberOfLines-1)*yOffset + 2*yBorder + height)
        else:
            size = (0.0, 0.0)
        self.setFrameSize_(size)
        self.setBoundsSize_(size)
    
        self.setNeedsDisplay_(YES)
