#!/usr/bin/env python
"""\file increment_running_times.py

increments running times for running threads

\author     Markus Happe   <markus.happe@upb.de>
\date       04.08.2009
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
# 04.08.2009   Markus Happe   File created.

import sys
sys.path.append("../Components")
from slot import *
from cpu import *
from sw_thread import *
from hw_thread import *
from migrate_thread import *

def increment_running_times(hw_threads, sw_threads, migrate_threads, time):

    # 1. hw threads
    for t in hw_threads:
        # if newly reconfigured thread (workload_this=0), try to get work, else terminate
        if t.state == 'running' and t.workload_this <= 0:
            if t.multithread.workload <= t.multithread.workload_this:
                t.state = 'terminated'
            else:
                m3 = t.multithread
                #print("time= "+str(time)+"  2) increase workload for task "+str(m3.name)+" from: "+str(m3.workload_this)+" to: "+str(m3.workload_this+1))
                t.multithread.workload_this += 1
                t.workload_this = t.multithread.workload_this
        # increase execution time for running hw task t
        if t.state == 'running':
            t.time_this = t.time_this + 1
        # set reconfigured slot 'active'
        if t.state == 'reconfigured':
            #t.state = 'running'
            if t.slot:
                t.slot.state = 'active'

    # 2. sw threads
    # increase execution time for running sw task (on CPU)
    for t in sw_threads:
        if t.state == 'running':
            t.time_this = t.time_this + 1

    # 3. migrate threads
    for m in migrate_threads:
        t = m.sw_thread
        if t.state == 'running' and m.migration == 'sw':
            if t.time_this < t.exec_time:
                t.time_this = t.time_this + 1
        t = m.hw_thread
        if t.state == 'running' and m.migration == 'hw':
            t.time_this = t.time_this + 1
        if t.state == 'reconfigured':
            #t.state = 'running'
            if t.slot:
                t.slot.state = 'active'
        #print 'Thread', m.hw_thread.name, ', hw time: ', m.hw_thread.time_this, ', sw time: ', m.sw_thread.time_this, ', migration:', m.migration




