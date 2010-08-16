#!/usr/bin/env python
"""
Python simulation classes for ReconOS task preemption
"""
#
# \file preempt.py
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       15.04.2008
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

class Thread:
    def __init__(self, priority, period, exec_time, res, name='unnamed'):
        self.priority = priority
        self.period = period
        self.exec_time = exec_time
        self.resources = res
        self.name = name
        self.time_this = 0          # time elapsed in current period
        self.slot = None
        self.state = 'terminated'         # can be 'ready', 'running', 'terminated', 'blocking', 'preempted'
        self.current_resources = []  # resources currently held by this thread


#----------------------------------------------------------------------------

class Slot:
    def __init__(self, name='unnamed'):
        self.name = name

    state = 'available'
    thread = None

#----------------------------------------------------------------------------

class Resource:
    def __init__(self, number, name='unnamed'):
        self.number = number        # number of available resources
        self.name = name


#----------------------------------------------------------------------------

def find_slot(slots, thread):
    """returns suitable slot for thread, or None
    
    Assumes that preemption is allowed."""

    minimum = 9999

    # first, try to find a free slot (and remember the minimum)
    for s in slots:
        if s.state == 'available':
            return s
        if s.thread.priority < minimum:
            minimum = s.thread.priority
            x = s

    # if that fails, return the slot with the lowest
    # priority, if it is lower than the priority of 'thread'
    if minimum < thread.priority:
        return x
    else:
        return None 

#----------------------------------------------------------------------------

def find_free_slot(slots, thread):
    """returns free slot for thread, or None"""

    for s in slots:
        if s.state == 'available':
            return s

    return None

#----------------------------------------------------------------------------

def print_status(threads, slots, time):

    n = len(slots)
    w = 140 / n
        
    print "%5d   " % (time),

    for s in slots:
        output = []
        if s.thread:
            output.append('Thread %s  %-8s[%3d] ' % (s.thread.name, s.thread.state, s.thread.time_this))
            for r in s.thread.current_resources:
                output.append(r.name + ' ')
        else:
            output.append('---')

        print ('%-' + str(w) + 's') % (' '.join(output)),

    print ''
#    print '\t\t',
#    for t in threads:
#        print 'Thread %s  %-8s[%3d]  ' % (t.name, t.state, t.time_this), 
#
#    print ''


#----------------------------------------------------------------------------



def run_simulation_step(threads, slots):
    threads[:] = sorted(threads, key=operator.attrgetter('priority'),reverse=True)

    # check for completed threads
    for t in threads:
        if t.state == 'running':
            if t.time_this >= t.exec_time:
                t.state = 'terminated'
                t.time_this = 0
                t.slot.state = 'available'
                t.slot.thread = None
                t.slot = None

    # check for resource usage
    for t in threads:
        if t.state == 'running' or t.state == 'blocking':
            for r, times in t.resources:
                if t.time_this in times:
                    if times.index(t.time_this) % 2 == 0:   # even index -> request
                        # request
                        if r.number > 0:
                            # resource is available, use it
                            r.number = r.number - 1
                            t.current_resources.append(r)
                            if t.state == 'blocking':
                                t.state = 'ready'
                        else:
                            # resource is unavailable, block (and make slot available)!
                            if t.slot:
                                t.slot.state = 'available'
                                t.slot.thread = None
                                t.slot = None
                            t.state = 'blocking'
                    else:   # odd index -> release
                        # release
                        assert t.state == 'running'
                        t.current_resources.remove(r)
                        r.number = r.number + 1

    # check for threads that want to run
    for t in threads:
        if t.state == 'ready' or t.state == 'preempted':
            # find slot for thread
            s = find_free_slot(slots, t)
            if s:
                # TODO: reconfiguration time
                if s.thread:
                    # preempt thread currently running in s
                    s.thread.state = 'preempted'
                    s.thread.slot = None
                t.slot = s
                s.thread = t
                t.state = 'running'
                s.state = 'active'

    # increment running time for running threads
    for t in threads:
        if t.state == 'running':
            t.time_this = t.time_this + 1



#----------------------------------------------------------------------------

def run_simulation(threads, slots, runtime):

    time = 0
    
    while (time < runtime):
        # check for newly starting threads
        for t in threads:
            if time % t.period == 0:
                if t.state != 'terminated':
                    print "Deadline of thread %s missed!" % t.name
                    sys.exit(1)
                t.state = 'ready'

        run_simulation_step(threads, slots)

        # increment simulation time
        time = time + 1

        # print status
        print_status(threads, slots, time)


#----------------------------------------------------------------------------

if __name__ == "__main__":

    num_slots = 3
    
    R1 = Resource(1, 'R1')
    R2 = Resource(1, 'R2')

    resources = (R1, R2)

    A = Thread(2,
            70, 
            29,
            (   ( R1, [10, 22, 30, 35]),      # resource 1 held between t = (10, 20) and (30, 35)
                ( R2, [15, 17])      # resource 2 held between t = (15, 17)
            ),
            'A')

    B = Thread(3,
            40, 
            20,
            ( ( R1, [5, 10]),
              ( R2, [1, 17]),
            ),
            'B')

    C = Thread(1,
            50,
            10,
            ( ( R1, [5, 7]), ),
            'C')

    threads = [A, B, C]

    slots = [ Slot('S%d' % i) for i in range(num_slots) ]

    run_simulation(threads, slots, 150)

