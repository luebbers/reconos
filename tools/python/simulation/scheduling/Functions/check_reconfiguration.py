#!/usr/bin/env python
"""\file check_reconfiguration.py

check if reconfiguration is needed

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

import sys
sys.path.append("../Components")
from slot import *
from hw_thread import *
from multithread import *


def check_reconfiguration(multithreads, icap):

    i = icap[0]
    for m in multithreads:
        for t in m.hw_threads:
            if t.slot and m.workload_this<=m.workload and not (m.workload<=m.workload_this and t.exec_time<=t.time_this): 
                # thread t shall run in slot s
                s = t.slot
                # check if thread t is already running in slot s
                if s.hw_thread == t and t.state != 'reconfig' and t.state != 'wait for icap':
                    t.slot = s
                    t.state = 'running'
                    s.state = 'active'
                    if t in i.threads:
                        i.threads.remove(t)
                elif t.state != 'reconfig' and t.state != 'wait for icap':
                    if s.hw_thread:
                        # replace thread currently running in s
                        s.hw_thread.slot = None
                    t.slot = s
                    s.hw_thread = t
                    #print 'Try to reconfigure Thread', t.name, ' to Slot', t.slot.name
                    i.threads.append(t)
                    t.state = 'wait for icap'
                    s.state = 'wait for icap'
            else:
                if t.slot and m.workload <= m.workload_this and t.exec_time <= t.time_this:
                    t.state = 'terminated'

