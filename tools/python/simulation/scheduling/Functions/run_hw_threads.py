#!/usr/bin/env python
"""\file find_slot.py

simulates current time step for hw threads

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
from sw_thread import *
from hw_thread import *
from migrate_thread import *
from icap import *
from slot import *
from reconos_resource import *
from find_slot import *


def run_hw_threads(slots, hw_threads, icap):

    #hw_threads[:] = sorted(hw_threads, key=operator.attrgetter('priority'),reverse=True)

    ###################################################################################
    #
    #  0: check for resource usage: lock resources
    #
    ###################################################################################
    for t in hw_threads:
        if t.state == 'running' or t.state == 'blocking':
            for time, resource, number, action in t.resources:
                if t.time_this == time:
                    if action == 'request':
            #for r, times in t.resources:
            #    for times_element in times:
            #        if t.time_this+1 == times_element[0]:   # even index -> request
                        #print 'Thread', t.name,'requests Resource', r.name, ' = ', str(r.number)
                        # request
                        #if r.number > 0:
                        #    # resource is available, use it
                        #    r.number = r.number - 1
                        #    t.current_resources.append(r)
                        #    if t.state == 'blocking':
                        #        # check if reconfiguration is needed (iff thread not in any slot)
                        #        if t.slot != None:
                        #            if t.slot.hw_thread.name == t.name:
                        #                t.state = 'running'
                        #        else:
                        #            t.state = 'ready'
                        if number <= resource.number:
                            # resource is available, use it
                            resource.number = resource.number - number
                            #if not resource in t.current_resources:
                            t.current_resources.append(resource)
                            if t.state == 'blocking':
                                t.state = 'ready'
                        else:
                            # resource is unavailable, block (and make slot available)!
                            if t.slot:
                                t.slot.state = 'blocking'
                            t.state = 'blocking'

    ###################################################################################
    #
    #  1: check for threads that want to run
    #
    ###################################################################################

    # first search for threads, which just wants to execute again and are allready configured in a slot => start them
    #for t in hw_threads:
    #    if t.state == 'ready':
    #        if t.slot != None:
    #            if t.slot.hw_thread == t: # to be sure
    #                t.state = 'running'
    #                t.slot.state = 'active'


    #for t in hw_threads:
    #    found_thread = False
    #    if t.state == 'ready':
    #        if t.slot != None:
    #            #t.state = 'running'
    #            #t.slot.state = 'active'
    #            if t.slot.hw_thread == t: # to be sure
    #                found_thread = True
    #                t.state = 'running'
    #                t.slot.state = 'active'
    #    if not found_thread and (t.state == 'ready' or t.state == 'yielded'):
    #        # find slot for thread
    #        s = find_free_slot(slots, t)
    #        if s:
    #            #print 'found slot', s.name, 'for thread', t.name
    #            if s.hw_thread == t:
    #                t.slot = s
    #                t.state = 'running'
    #                s.state = 'active'
    #                if (len(icap)>0):
    #                    i = icap[0]
    #                    if t in i.threads:
    #                        i.threads.remove(t);
    #            else:
    #                if s.hw_thread:
    #                    # replace thread currently running in s
    #                    #if s.hw_thread.state != 'terminated':
    #                    #    s.hw_thread.state = 'yielded'
    #                    # only replace, if thread is not just waiting for icap
    #                    #if s.hw_thread.state != 'wait '
    #                    s.hw_thread.slot = None
    #                t.slot = s
    #                s.hw_thread = t
    #                #print 'Try to reconfigure Thread', t.name, ' to Slot', t.slot.name
    #                # reconfigure thread
    #                if (len(icap)>0):
    #                    i = icap[0]
    #                    if i.current_thread == None:
    #                        i.state = 'reconfiguring'
    #                        i.current_thread = t
    #                        i.current_thread.reconfig_time_this += 1
    #                        t.state = 'reconfig'
    #                        s.state = 'reconfig'                                
    #                    else:
    #                        i.threads.append(t)
    #                        t.state = 'wait for icap'
    #                        s.state = 'wait for icap'
               



