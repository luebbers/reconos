#!/usr/bin/env python
"""
Python simulation classes for ReconOS cooperative multithreading
"""
#
# \file coop.py
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       21.08.2009
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

import operator, sys
from heapq import heappush, heappop



class Scheduler(object):
    
    def __init__(self, slots, threads=None):
        self.slots = slots
        self.threads = threads
        self.eventQueue = []        # a heap
        self.time = -1              # last time an event occurred
        
        if threads:
            for t in threads:
                self.addEvent(t.firstReleaseTime)
    
    def addEvent(self, when):
        """Adds a timed event (just the time) to the scheduling queue,
        if there is no event scheduled yet for that time."""
        assert when > self.time             # only schedule events in the future
        if when not in self.eventQueue:
            heappush(self.eventQueue, when)
        
    def doNext(self):

        if self.eventQueue:
            now = heappop(self.eventQueue)
        else:
            return None
            
        # update all thread data structures
        for t in self.threads:
            t.update(now)
            
        # naive scheduling:
        # start first runnable thread, if there are free slots
        for t in self.threads:
            if t.state == 'ready':
                s = self.findFreeSlot()
                if s:
                    t.start(now, s)
            
        self.time = now
        
        return now


    def findFreeSlot(self):
        """returns free slot for thread, or None"""

        for s in self.slots:
            if s.state == 'available':
                return s

        return None

    def printStatus(self):

        n = len(self.slots)
        w = 140 / n

        print "%5d   " % (self.time),

        for s in self.slots:
            output = []
            if s.thread:
                output.append('Thread %s  %-8s[%3d] ' % (s.thread.name, s.thread.state, s.thread.timeRemaining))
    #            for r in s.thread.current_resources:
    #                output.append(r.name + ' ')
            else:
                output.append('---')

            print ('%-' + str(w) + 's') % (' '.join(output)),

        print ''
    #    print '\t\t',
    #    for t in threads:
    #        print 'Thread %s  %-8s[%3d]  ' % (t.name, t.state, t.time_this), 
    #
    #    print ''


    
# create global scheduler
scheduler = None



class Thread(object):
    
    def __init__(self, priority, period, computationTime, firstReleaseTime=0, isPeriodic=False, name='unnamed'):
        # thread parameters
        self.name = name
        self.isPeriodic = isPeriodic
        self.priority = priority
        self.period = period                        # also the maximum runtime for non-periodic tasks (time between start and deadline)
        self.computationTime = computationTime      # necessary execution time to complete task for one period
        self.firstReleaseTime = firstReleaseTime    # first time an instance of this thread is released
        
        # current thread state
        self.deadline = None                # absolute deadline time of current period
        self.releaseTime = firstReleaseTime # absolute start time of current period
        self.startTime = None               # absolute time at which thread actually started executing
        self.finishingTime = None           # absolute time at which thread will finish executing
        self.timeRunning = 0                # time elapsed in current period
        self.timeRemaining = computationTime       # time remaining in current period
        self.slot = None
        self.state = 'idle'           # can be 'idle', 'ready', 'running', 'terminated'


    def deadlineMissed(self):
        print("Thread '" + self.name + "' missed its deadline.")
        

    def update(self, now):
        if self.state == 'running':
            self.timeRunning = now - self.startTime
            self.timeRemaining = self.computationTime - self.timeRunning
            # check for missed deadline
            if now > self.deadline:
                self.deadlineMissed()
            if self.timeRemaining == 0:
                self.terminate(now)
        if self.state == 'idle':        # i.e. waiting to be released
            assert self.releaseTime >= now
            if self.releaseTime == now:
                self.release(now)
            

    def terminate(self, now):
        """set thread to be done computing.
        for periodic threads, also schedule next release"""
        
        global scheduler

        assert self.timeRemaining == 0
        self.slot.stop()
        self.slot = None
        # schedule next period's start
        if self.isPeriodic:
            self.releaseTime = self.releaseTime + self.period
            assert self.releaseTime >= now
            if self.releaseTime > now:
                scheduler.addEvent(self.releaseTime)
            self.state = 'idle'         # i.e. will wait for next release
        else:
            self.state = 'terminated'   # i.e. will not run again
            


    def release(self, now):
        """set thread to be ready"""
        assert self.releaseTime == now
        assert self.computationTime > 0
        assert self.period >= self.computationTime

        self.deadline = self.releaseTime + self.period
        self.state = 'ready'
#        print("Thread '" + self.name + "' released.\n")


    def start(self, now, slot):
        """actually start executing"""
        
        global scheduler

        assert self.computationTime > 0
        assert self.period >= self.computationTime
        assert self.releaseTime <= now
        assert slot.state == 'available'
        
        self.startTime = now
        self.timeRunning = 0
        self.timeRemaining = self.computationTime
        self.finishingTime = now + self.computationTime
        self.state = 'running'
        self.slot = slot
        slot.start(self)
        # schedule end of execution
        scheduler.addEvent(self.finishingTime)
#        print("Thread '" + self.name + "' started. Will execute until t = " + str(self.finishingTime) + "\n")
        
        

#----------------------------------------------------------------------------

class Slot:
    def __init__(self, name='unnamed'):
        self.name = name
        self.state = 'available'
        self.thread = None
        
    def start(self, thread):
        self.state = 'active'
        self.thread = thread
        
    def stop(self):
        self.state = 'available'
        self.thread = None



#----------------------------------------------------------------------------





def runSimulation(threads, slots, runtime):

    global scheduler

    time = 0
    
    while (time < runtime):
        
        time = scheduler.doNext()

        if time == None:
            print "No more events scheduled."
            break
        
        # print status
        scheduler.printStatus()
        

#----------------------------------------------------------------------------

if __name__ == "__main__":

    num_slots = 2
    
    A = Thread(2,
            70, 
            55,
            name = 'A')

    B = Thread(3,
            40, 
            20,
            name = 'B')

    C = Thread(1,
            50,
            10,
            isPeriodic = True,
            name = 'C')

    threads = [A, C, B]

    slots = [ Slot('S%d' % i) for i in range(num_slots) ]
    
    scheduler = Scheduler(slots, threads)

    runSimulation(threads, slots, 150)
