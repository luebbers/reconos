#!/usr/bin/env python
"""\file start_thread_instances.py

start thread instances

\author     Markus Happe   <markus.happe@upb.de>
\date       30.07.2009
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
# 13.08.2009   Markus Happe   File created.

import sys, operator
sys.path.append("../Components")
from cpu import *
from slot import *
from sw_thread import *
from hw_thread import *
from multithread import *

def start_thread_instances(cpu, slots, multithreads, time):

    ##############################################################################################
    #
    #    A. run hw threads
    #
    ##############################################################################################

    # check for newly starting hw threads
    for s in slots:
        if s.hw_thread and s.hw_thread.state != 'reconfig' and s.hw_thread.state != 'wait for icap':
            #print 'Thread', s.hw_thread.name, ':', s.hw_thread.state
            t = s.hw_thread
            m = t.multithread
            #if t.state == 'reconfigured':
            #    t.state = 'running'
            if m:
                # if still workload to do
                if m.workload_this < m.workload and m.workload>0:
                    if t.state == 'terminated' or (t.state == 'running' and (t.exec_time <= t.time_this)):
                        #print("time= "+str(time)+"  1) increase workload for task "+str(m.name)+" from: "+str(m.workload_this)+" to: "+str(m.workload_this+1))
                        m.workload_this += 1
                        t.workload_this = m.workload_this
                        if t.state == 'running' and t.exec_time == t.time_this:
                            t.state = 'terminated'
                            t.time_this = 0
                            t.slot.state = 'available'
                        t.state = 'ready'
                        if t.slot and t.slot.hw_thread == t and t.state!='reconfig' and t.state!='wait for icap':
                            t.state = 'running'
                        #print t.name, ':', t.state

    ##############################################################################################
    #
    #    B. run sw thread (prefer threads which run on minimum number of runtime enviroments, 
    #                       ie. only on CPU)
    #
    ##############################################################################################


    # iii) all tasks to => cpu, pick first sw thread which has something to do 
    #      (it will have lowest=best priority)
    found_thread = False
    c = cpu[0]
    for m in multithreads:
        for t in m.sw_threads:
            #if t.state == 'ready' or t.state == 'preempted':
            if not found_thread and(not c.sw_thread or c.sw_thread.state=='terminated' or c.sw_thread.exec_time<= c.sw_thread.time_this):
                if c.sw_thread and c.sw_thread.exec_time <= c.sw_thread.time_this:
                    c.sw_thread.state = 'terminated'
                    c.sw_thread.time_this = 0
                    c.sw_thread.cpu = None
                    c.sw_thread = None
                    c.state = 'idle'
                if m.workload > 0 and m.workload_this < m.workload and m.priority==0: # there is more stuff todo, and no hw 
                    m.workload_this += 1
                    t.workload_this = m.workload_this
                    t.time_this = 0
                    t.cpu = c
                    c.sw_thread = t
                    t.state = 'running'
                    c.state = 'active'
                    found_thread = True
                    #print 'thread', t.name, 'on cpu'
