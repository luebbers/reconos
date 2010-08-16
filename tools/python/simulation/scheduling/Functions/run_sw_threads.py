#!/usr/bin/env python
"""\file run_sw_threads.py

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
from sw_thread import *
from cpu import *
from reconos_resource import *
from migrate_thread import *

def run_sw_threads(cpu, sw_threads, migrate_threads):

    #sw_threads[:] = sorted(sw_threads, key=operator.attrgetter('priority'),reverse=True)

    # check for resource usage: lock resources
    for t in sw_threads: 
        if t.state == 'running' or t.state == 'blocking':
            for time, resource, number, action in t.resources:
                if t.time_this == time and action == 'request':
                    # request resource
                    #assert t.state == 'running'
                    #if resource in t.current_resources:
                    #    t.current_resources.remove(resource)
                    #resource.number = resource.number + number
                    #print 'Thread', t.name,'requests Resource', resource.name, ' = ', str(resource.number)
                    # request, only if there is no other running thread, which has shorter deadline
                    #best_thread = True
                    #for t2 in sw_threads:
                    #    if t2.deadline < t.deadline and (t2.state == 'running' or t2.state == 'ready'):
                    #        best_thread = False
                    #for m in migrate_threads:
                    #    if m.migration == 'sw':
                    #        t2 = m.sw_thread
                    #        if t2.deadline < t.deadline and (t2.state == 'running' or t2.state == 'ready'):
                    #            best_thread = False
                    if resource.number > number-1: # and best_thread:
                        # resource is available, use it
                        resource.number = resource.number - number
                        #if not resource in t.current_resources:
                        t.current_resources.append(resource)
                        if t.state == 'blocking':
                            t.state = 'ready'
                    else:
                        # resource is unavailable, block (and make cpu available)!
                        if t.cpu:
                            t.cpu.state = 'idle'
                            t.cpu.sw_thread = None
                            t.cpu = None
                        t.state = 'blocking'


    # check for threads that want to run
    #for t in sw_threads:
    #    if t.state == 'ready' or t.state == 'preempted':
    #        # change sw thread if needed
    #        if len(cpu) > 0:
    #            c = cpu[0]
    #            if c.sw_thread:
    #                i = 1
    #                #if t.deadline < c.sw_thread.deadline:
    #                #    if c.sw_thread:
    #                #        # preempt thread currently running in s
    #                #        c.sw_thread.state = 'preempted'
    #                #        c.sw_thread.cpu = None
    #                #    t.cpu = c
    #                #    c.sw_thread = t
    #                #    t.state = 'running'
    #                #    c.state = 'active'
    #            else:
    #                 t.cpu = c
    #                 c.sw_thread = t
    #                 t.state = 'running'
    #                 c.state = 'active'





