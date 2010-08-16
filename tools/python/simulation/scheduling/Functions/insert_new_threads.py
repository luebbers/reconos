#!/usr/bin/env python
"""\file insert_new_threads.py

inserts new instances from sw and hw threads

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
# 30.07.2009   Markus Happe   File created.

import sys
sys.path.append("../Components")
from sw_thread import *
from hw_thread import *
from migrate_thread import *


def insert_new_threads(hw_threads, sw_threads, multithreads, migrate_threads, time):

    # increase workload at given time steps
    for m in multithreads:
        for workload in m.workloads: 
            if time == workload[0]:
                # workload needs to be increase
                m.workload += workload[1]

    # check for newly starting hw threads
    for t in hw_threads:
        if t.state == 'reconfigured':
            t.state = 'running'
        if t.multithread:
            # if still workload to do
            if t.multithread.workload_this < t.multithread.workload and (t.state == 'terminated' or (t.state == 'running' and t.exec_time == t.time_this)):
                t.multithread.workload_this += 1
                t.workload_this = t.multithread.workload_this
                if t.state == 'running' and t.exec_time == t.time_this:
                    t.state = 'terminated'
                    t.time_this = 0
                    t.slot.state = 'available'
                t.state = 'ready'
                #t.deadline = time + t.period                    
        else:
            if time % t.period == 0:
                if t.state == 'running' and t.exec_time == t.time_this:
                    t.state = 'terminated'
                    t.time_this = 0
                    t.slot.state = 'available'
                if t.state != 'terminated':
                    print ("Deadline of thread %s missed!" % t.name)
                    sys.exit(1)
                t.state = 'ready'
                t.deadline = time + t.period

    # check for newly starting sw threads
    for t in sw_threads:
        if t.multithread:
            # if still workload to do
            if t.multithread.workload_this < t.multithread.workload and (t.state == 'terminated' or (t.state == 'running' and t.exec_time == t.time_this)):
                t.multithread.workload_this += 1
                t.workload_this = t.multithread.workload_this
                if t.state == 'running' and t.exec_time == t.time_this:
                    t.state = 'terminated'
                    t.time_this = 0
                    t.cpu.state = 'idle'
                    t.cpu.sw_thread = None
                    t.cpu = None
                t.state = 'ready'
                #t.deadline = time + t.period                 
        else:
            if time % t.period == 0:
                if t.state == 'running' and t.exec_time == t.time_this:
                    t.state = 'terminated'
                    t.time_this = 0
                    t.cpu.state = 'idle'
                    t.cpu.sw_thread = None
                    t.cpu = None
                if t.state != 'terminated' and t.exec_time > t.time_this:
                    print ("Deadline of thread %s missed!" % t.name)
                    sys.exit(1)
                t.state = 'ready'
                t.deadline = time + t.period

    # check for newly starting migrate threads
    for t in migrate_threads:
        if t.hw_thread.state == 'reconfigured':
            t.hw_thread.state = 'running'
        if time % t.period == 0:
            if t.hw_thread.state == 'running' and t.hw_thread.exec_time == t.hw_thread.time_this:
                t.hw_thread.state = 'terminated'
            if t.sw_thread.state == 'running' and t.sw_thread.exec_time == t.sw_thread.time_this:
                t.sw_thread.state = 'terminated'
            if t.sw_thread.state != 'terminated' and t.hw_thread.state != 'terminated' and t.hw_thread.exec_time > t.hw_thread.time_this and t.sw_thread.exec_time > t.sw_thread.time_this:
                print ("Deadline of thread %s missed!" % t.sw_thread.name)
                sys.exit(1)
            t.sw_thread.state = 'ready'
            t.hw_thread.state = 'ready'
            t.sw_thread.time_this = 0
            t.hw_thread.time_this = 0
            if t.hw_thread.slot:
                t.hw_thread.slot.state = 'available'
            t.deadline = time + t.period
            t.sw_thread.deadline = time + t.period
            t.hw_thread.deadline = time + t.period
            t.migration = 'hw'
