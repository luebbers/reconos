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



def incName(s):
    '''Adds a numeric suffix (_1) to a string or increments that suffix, if
    it already exists. Used to create new Thread names from existing ones.'''
    # TODO: implement correctly!
    return s + "+"





class Scheduler(object):
    
    def __init__(self, slots, cores, threads, logger=None, eventLogger=None):
        self.slots = slots
        self.cores = []
        self.threads = []
        self.eventQueue = []        # a heap
        self.time = -1              # last time an event occurred
        if logger:
            self.logger = logger
        else:
            self.logger = self
        if eventLogger:
            self.eventLogger = eventLogger
        else:
            self.eventLogger = self
        
        if threads:
            for t in threads:
                self.addThread(t)
                
        if cores:
            for c in cores:
                self.cores.append(c)
                
    def addEvent(self, when):
        """Adds a timed event (just the time) to the scheduling queue,
        if there is no event scheduled yet for that time."""
        assert when > self.time             # only schedule events in the future
        if when not in self.eventQueue:
            heappush(self.eventQueue, when)
            
            
    def addThread(self, thread):
        '''Adds a new thread to be scheduled.'''
        if self.logger: self.logger.write("Adding Thread '" + thread.name + "' to scheduler.\n")

        self.threads.append(thread)
        self.addEvent(thread.releaseTime)
        thread.setEventLogger(self.eventLogger)
        thread.setTextLogger(self.logger)


    def doNext(self):

        if self.eventQueue:
            now = heappop(self.eventQueue)
        else:
            return None
            
        # update all thread data structures until no changes occur
        noMoreChanges = False
        self.delta = -1
        while not noMoreChanges:
            self.delta = self.delta + 1         # increment delta cycles (for logging only)
            noMoreChanges = True
            for t in self.threads:
                stateChanged, newThread = t.update(now)
                if stateChanged:
                    noMoreChanges = False
                if newThread != None:
                    if self.logger: self.logger.write("Rescheduling new thread '" + newThread.name + "'.\n")
                    self.addThread(newThread)
            
        # naive scheduling:
        # start first runnable thread, if there are free slots
        for t in self.threads:
            if t.state == 'ready':
                s = self.findFreeSlot()
                if s:
                    # start thread and add any resulting events to queue
                    newEvent = t.start(now, s)
                    if newEvent:
                        self.addEvent(newEvent)   
            
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

        self.logger.write("%5d %2d   " % (self.time, self.delta))

        for s in self.slots:
            output = []
            if s.thread:
                output.append('Thread %s  %-8s[%3d] ' % (s.thread.name, s.thread.state, s.thread.timeRemaining))
    #            for r in s.thread.current_resources:
    #                output.append(r.name + ' ')
            else:
                output.append('---')

            self.logger.write(('%-' + str(w) + 's') % (' '.join(output)))

        self.logger.write('\n')
    
    # implement functions for being a text logger
    def write(self, s):
        print s,
        
        
    # implement functions for being an event logger
    # ignore events by default
    # functions for being an event logger
    def logEvent(self, event):
        pass
        
#---------------------------------------------------------------------------------------------


class Core(object):
    ''' A core represents the code/hardware logic to execute a thread. It cannot be directly executed, but must
    be instantiated, which forms a new Thread.'''
    
    def __init__(self, computationTime=0, color=None, name='unnamed', textLogger=None, eventLogger=None):
        # thread parameters
        self.name = name
        self.computationTime = computationTime      # necessary execution time to complete task for one period

        self.logger = textLogger
        self.eventLogger = eventLogger

        self.color = color




class Thread(object):

    
    def __init__(self, core, priority=0, releaseTime=0, period=0, deadline=0, dependencies=[], isPeriodic=False, name='unnamed', textLogger=None, eventLogger=None):
        # thread parameters
        self.core = core
        self.dependencies = dependencies    # list of Thread objects that need to have been completed (='terminated')
                                            # for this Thread to run
        self.name = name
                
        self.logger = textLogger
        self.eventLogger = eventLogger

        # current thread state
        self.priority = priority
        self.period = period                        # also the maximum runtime for non-periodic tasks (time between start and deadline)
                                                    # set to 0 if not known/needed
        self.isPeriodic = isPeriodic        # whether this instance will spawn new tasks after termination (periodic)
        if deadline <= 0: 
            self.deadline = self.period     # deadline (= period after relase in which thread must finish)
        else:
            self.deadline = deadline
        self.releaseTime = releaseTime      # earliest absolute start time of current period. If there are dependencies, they have to be completed first
            
        self.reset()
            
    def reset(self):
        self.deadlineTime = self.releaseTime + self.deadline               # absolute deadline time
        self.startTime = None               # absolute time at which thread actually started executing
        self.finishingTime = None           # absolute time at which thread will finish executing
        self.timeRunning = 0                # time elapsed in current period
        self.timeRemaining = self.core.computationTime       # time remaining in current period
        self.slot = None
        self.state = 'idle'           # can be 'idle', 'ready', 'running', 'terminated'
        
        self.next = self        # 'next' thread to be released (for periodic threads)
        
        # TODO: enforce this in the GUI        
        if self.isPeriodic:
            assert self.period > 0
        else:
            assert self.period <= 0


    def setEventLogger(self, eventLogger):
        self.eventLogger = eventLogger

    def setTextLogger(self, textLogger):
        self.textLogger = textLogger
        
    def deadlineMissed(self):
        self.textLogger.write("Thread '" + self.name + "' missed its deadline!\n")
        self.eventLogger.logEvent(
            {'type' : 'deadlineMissed',
             'deadline': self.deadlineTime,
             'thread' : self})
        

    def update(self, now):
#        print("Updating Thread '" + self.name + "' at time " + str(now) + ".")
        newThread = None
        oldState = self.state
        if self.state == 'running':
            self.timeRunning = now - self.startTime
            self.timeRemaining = self.core.computationTime - self.timeRunning
            # check for missed deadline
            if self.deadline > 0:            # only if our core has a specified deadline
                if now > self.deadlineTime:
                    self.deadlineMissed()
            if self.timeRemaining == 0:
                self.terminate(now)
        if self.state == 'idle':        # i.e. waiting to be released
            if self.releaseTime <= now: # has our earliest release time passed?
                dependenciesDone = True # are all dependencies met (i.e. have executed)?
                if self.dependencies != None:
                    for d in self.dependencies:
                        if d.state != 'terminated':
                            dependenciesDone = False
                if dependenciesDone:
                    newThread = self.release(now)

        return oldState != self.state, newThread       # return whether our state changed and possible new release event time (from self.terminate())
            

    def terminate(self, now):
        """set thread to be done computing.
        for periodic threads, also return time for next release"""

        assert self.timeRemaining == 0

        if self.eventLogger: self.eventLogger.logEvent(
            {'type'   : 'exec', 
             'start'  : self.startTime,
             'finish' : now,
             'thread' : self,
             'slot'   : self.slot.num})

        self.slot.stop()
        self.slot = None
        self.state = 'terminated'   # i.e. this instance will not run again - but we might have create a new one on release()
        if self.textLogger: self.textLogger.write("Thread '" + self.name + "' terminated.\n")
        


    def release(self, now):
        '''Set thread to be ready. Will be called only after all dependencies have finished.'''
        assert self.releaseTime <= now, "self.releaseTime (%d) > now (%d)" % (self.releaseTime, now)
        assert self.core.computationTime > 0
        assert self.period <= 0 or self.period >= self.core.computationTime
        # check all dependencies
        if self.dependencies != None:
            for d in self.dependencies:
                assert d.state == 'terminated'

        if self.eventLogger: self.eventLogger.logEvent(
            {'type'   : 'release',
             'time'   : self.releaseTime,
             'thread' : self,
             'draw'   : True})

        # if our core has a deadline, we need to set a deadlineTime
        if self.deadline > 0:
            self.deadlineTime = self.releaseTime + self.deadline
            if self.eventLogger: self.eventLogger.logEvent(
                {'type'   : 'deadline',
                 'time'   : self.deadlineTime,
                 'thread' : self,
                 'draw'   : False})

        self.state = 'ready'
        if self.textLogger: self.textLogger.write("Thread '" + self.name + "' released.\n")

        # for periodic threads, schedule next release, too
        if self.isPeriodic:
            # TODO: copy constructor?
            newThread = Thread(core = self.core,
                               priority     = self.priority,
                               releaseTime  = self.releaseTime + self.period, 
                               period       = self.period, 
                               deadline     = self.deadline,
                               dependencies = [d.next for d in self.dependencies],    # this works because all threads we depend on have already spawned 'next' threads
                               isPeriodic   = self.isPeriodic, 
                               name         = incName(self.name),
                               textLogger   = self.textLogger,
                               eventLogger  = self.eventLogger)
                               
            self.next = newThread       # store reference to new thread (to resolve future dependencies)
            return self.next
        else:
            return None
        


    def start(self, now, slot):
        """actually start executing. returns finishing time."""
        
        assert self.core.computationTime > 0
        assert self.period <= 0 or self.period >= self.core.computationTime
        assert self.releaseTime <= now
        assert slot.state == 'available'
        
        self.startTime = now
        self.timeRunning = 0
        self.timeRemaining = self.core.computationTime
        self.finishingTime = now + self.core.computationTime
        self.state = 'running'
        self.slot = slot
        slot.start(self)
        # return time for event "end of execution"
        return self.finishingTime
#        print("Thread '" + self.name + "' started. Will execute until t = " + str(self.finishingTime) + "\n")
        
        

#----------------------------------------------------------------------------

class Slot:
    def __init__(self, num, name='unnamed'):
        self.name = name
        self.state = 'available'
        self.thread = None
        self.num = num
        
    def start(self, thread):
        self.state = 'active'
        self.thread = thread
        
    def stop(self):
        self.state = 'available'
        self.thread = None



#----------------------------------------------------------------------------





def runSimulation(scheduler, threads, slots, runtime):

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
    
#    A = Core(computationTime = 55,
#             color           = 0,
#             name            = 'Core A')

    B = Core(computationTime = 45,
             color           = 1,
             name            = 'Core B')

    C = Core(computationTime = 10,
             color           = 3,
             name            = 'Core C')
    
#    A1 = Thread(core        = A,
#                priority    = 2,
#                releaseTime = 0,
#                period      = 70,
#                name        = 'A1')

    B1 = Thread(core        = B,
                priority    = 3,
                releaseTime = 0,
                period      = 50,
                isPeriodic  = True,
                name        = 'B1')

    C1 = Thread(core        = C,
                priority    = 1,
                releaseTime = 0,
                isPeriodic  = True,
                period      = 50,
                deadline    = 60,           # executes after B1, so might not make B1s deadline
                dependencies = [B1],
                name        = 'C1')

#    threads = [A1, C1, B1]
    threads = [C1, B1]

    slots = [ Slot(i, 'S%d' % i) for i in range(num_slots) ]
    
    scheduler = Scheduler(slots, threads)

    runSimulation(scheduler, threads, slots, 150)
