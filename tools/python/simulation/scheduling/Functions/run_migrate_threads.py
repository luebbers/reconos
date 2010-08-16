#!/usr/bin/env python
"""\file run_migrate_threads.py

runs current time step for sw_threads

\author     Markus Happe   <markus.happe@upb.de>
\date       31.07.2009
"""
#
# This file is part of the ReconOS project <http://www.reconos.de>.
# University of Paderborn, Computer Engineering Group.
#
# (C) Copyright University of Paderborn 2009. Permission to copy,
# use, modify, sell and distribute this software is granted provided
# this copyright notice appears in all copies. This software is
# provided "as is" without express or implied warranty, and with no
# claim as to its suitability for any purpose.
#
#---------------------------------------------------------------------------
#
# Major Changes:
#
# 30.07.2009   Markus Happe   File created.

import sys, operator
sys.path.append("../Components")
from cpu import *
from reconos_resource import *
from migrate_thread import *
from sw_thread import *
from hw_thread import *
from find_slot import *

def run_migrate_threads(cpu, slots, sw_threads, migrate_threads, icap):

    # sort threads
    migrate_threads[:] = sorted(migrate_threads, key=operator.attrgetter('priority'),reverse=True)

    ###################################################################################
    #
    #  0: check for resource usage: lock resources
    #
    ###################################################################################
    for m in migrate_threads:
        t = m.sw_thread
        if t.state == 'running' or t.state == 'blocking':
            for r, times in t.resources:
                for times_element in times:
                    if t.time_this == times_element[0]:   # even index -> request
                        #print 'Thread', t.name,'requests Resource', r.name, ' = ', str(r.number)
                        # request
                        best_thread = True
                        for t2 in sw_threads:
                            if t2.deadline < t.deadline and (t2.state == 'running' or t2.state == 'ready'):
                                best_thread = False
                        for m2 in migrate_threads:
                            if m2.migration == 'sw':
                                t2 = m2.sw_thread
                                if t2.deadline < t.deadline and (t2.state == 'running' or t2.state == 'ready'):
                                    best_thread = False
                        if r.number > 0 and best_thread:
                            # resource is available, use it
                            r.number = r.number - 1
                            t.current_resources.append(r)
                            if t.state == 'blocking':
                                t.state = 'ready'
                        else:
                            # resource is unavailable, block (and make cpu available)!
                            if t.cpu:
                                t.cpu.state = 'idle'
                                t.cpu.sw_thread = None
                                t.cpu = None
                            t.state = 'blocking'
        t = m.hw_thread
        if t.state == 'running' or t.state == 'blocking':
            for r, times in t.resources:
                for times_element in times:
                    if t.time_this+1 == times_element[0]:   # even index -> request
                        #print 'Thread', t.name,'requests Resource', r.name, ' = ', str(r.number)
                        # request
                        if r.number > 0:
                            # resource is available, use it
                            r.number = r.number - 1
                            t.current_resources.append(r)
                            if t.state == 'blocking':
                                # check if reconfiguration is needed (iff thread not in any slot)
                                if t.slot != None:
                                    if t.slot.hw_thread.name == t.name:
                                        t.state = 'running'
                                else:
                                    t.state = 'ready'
                        else:
                            # resource is unavailable, block (and make slot available)!
                            if t.slot:
                                t.slot.state = 'blocking'
                            t.state = 'blocking'


    # check for threads that want to run
    ###################################################################################
    #
    #  1: initially: if slot is available, run migrate thread in hw, else in sw
    #
    ###################################################################################
    for m in migrate_threads:
        # try as hw thread first
        t = m.hw_thread
        found_thread = False
        if t.state == 'ready':
            if t.slot != None:
                t.state = 'running'
                t.slot.state = 'active'
                found_thread = True
        # only put thread into hw, if a slot is available
        if (m.migration == 'hw') and (not found_thread) and (t.state == 'ready' or t.state == 'yielded'):
            # find slot for thread
            s = find_free_slot(slots, t)
            if s:
                if s.hw_thread == t:
                    t.slot = s
                    t.state = 'running'
                    s.state = 'active'
                    if (len(icap)>0):
                        i = icap[0]
                        if t in i.threads:
                            i.threads.remove(t);
                else:
                    if s.hw_thread:
                        # replace thread currently running in s
                        #if s.hw_thread.state != 'terminated':
                        #    s.hw_thread.state = 'yielded'
                        s.hw_thread.slot = None
                    t.slot = s
                    s.hw_thread = t
                    # reconfigure thread
                    if (len(icap)>0):
                        i = icap[0]
                        if i.current_thread == None:
                            i.state = 'reconfiguring'
                            i.current_thread = t
                            i.current_thread.reconfig_time_this += 1
                            t.state = 'reconfig'
                            s.state = 'reconfig'                                
                        else:
                            i.threads.append(t)
                            t.state = 'wait for icap'
                            s.state = 'wait for icap'
            else:      
                if t.state == 'yielded' or t.time_this == 0:
                    # if yielded in hw => do it rest in sw
                    m.migration = 'sw'
                    # remove thread from icap list
                    if (len(icap)>0):
                        i = icap[0]
                        if t in i.threads:
                            i.threads.remove(t);
                    # find current migration point
                    position = 0
                    current_time = 0
                    if t.time_this > 0:
                        for k in t.migration_points:
                            if k == t.time_this+1:   #undo +1
                                # found position => update time in sw thread
                                current_time = m.sw_thread.migration_points[position] - 1
                            position += 1
                    # reactivate sw thread
                    m.sw_thread.state = 'ready'
                    m.sw_thread.time_this = current_time
                    # deactivate hw thread
                    t.slot = None
        ###################################################################################
        #
        #  2. if migrate thread in sw, but hw slot is free => migrate
        #
        ###################################################################################
        t = m.sw_thread
        if (m.migration == 'sw') and (t.state == 'running') and t.time_this > 0:
            # if we have a migration point, check if a slot is free => if yes, migrate to hw
            if t.time_this+1 in t.migration_points and t.state != 'preempted':
                #check if a hw slot is available
                s = find_free_slot(slots, t)
                if s:
                    # migrate thread to hw
                    #print 'migrate thread to hw'
                    m.migration = 'hw'
                    # get index of migration point in list
                    position = 0
                    current_time = 0
                    for k in t.migration_points:
                        if k == t.time_this+1:   #undo +1
                            # found position => update time in sw thread
                            current_time = m.hw_thread.migration_points[position] - 1
                        position += 1
                    m.hw_thread.state = 'ready'
                    m.hw_thread.time_this = current_time
                    # activate hw thread
                    #m.hw_thread.slot = s
                    if t.cpu:
                        if t.cpu.sw_thread == t:
                            # remove thread from cpu if needed
                            t.cpu.sw_thread = None
                            # try next best migrate thread
                            for m2 in migrate_threads:
                                t2 = m2.sw_thread
                                if not t.cpu.sw_thread:
                                    t.cpu.sw_thread = t2
                                    t2.cpu = t.cpu
                                else:
                                    if t2.deadline < t.cpu.sw_thread.deadline:
                                        if t2.state != 'terminated' and t2.state != 'blocked' and m2.migration == 'sw':
                                            t.cpu.sw_thread = t2
                                            t2.cpu = t.cpu
                            if t.cpu.sw_thread:
                                if t.cpu.sw_thread.state == 'ready':
                                    t.cpu.sw_thread.state = 'running'
                    t.cpu = None
                    t.state = 'migrated'
                    if s.hw_thread:
                        # replace thread currently running in s
                        #if s.hw_thread.state != 'terminated':
                        #    s.hw_thread.state = 'yielded'
                        s.hw_thread.slot = None
                    s.hw_thread = m.hw_thread
                    m.hw_thread.slot = s
                    # reconfigure thread
                    if (len(icap)>0):
                        i = icap[0]
                        if i.current_thread == None:
                            i.state = 'reconfiguring'
                            i.current_thread = m.hw_thread
                            i.current_thread.reconfig_time_this += 1
                            m.hw_thread.state = 'reconfig'
                            s.state = 'reconfig'                                
                        else:
                            i.threads.append(m.hw_thread)
                            m.hw_thread.state = 'wait for icap'
                            s.state = 'wait for icap'
        ###################################################################################
        #
        #  3. else, if migrate thread in sw, execute it
        #
        ###################################################################################
        if (m.migration == 'sw') and (t.state == 'ready' or t.state == 'preempted'):

            # change sw thread if needed
            if m.migration == 'sw':
                if len(cpu) > 0:
                    c = cpu[0]
                    if c.sw_thread:
                        if t.deadline < c.sw_thread.deadline:
                            if c.sw_thread:
                                # preempt thread currently running in s
                                c.sw_thread.state = 'preempted'
                                c.sw_thread.cpu = None
                            t.cpu = c
                            c.sw_thread = t
                            t.state = 'running'
                            c.state = 'active'
                    else:
                         t.cpu = c
                         c.sw_thread = t
                         t.state = 'running'
                         c.state = 'active'


