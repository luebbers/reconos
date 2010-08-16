#!/usr/bin/env python
"""\file check_termination.py

check if a thread terminates

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
from cpu import *
from slot import *
from sw_thread import *
from hw_thread import *
from multithread import *


def check_termination(multithreads, schedule):

    for m in multithreads:
        for t in m.sw_threads:
            if t.cpu:
                # check if a sw thread terminated
                if t.exec_time <= t.time_this and m.workload <= m.workload_this:
                    t.state = 'terminated'
                    c = t.cpu
                    if c.sw_thread == t: # and m.workload <= m.workload_this:
                        c.sw_thread = None
                        c.state = 'idle'
                        t.cpu = None
        for t in m.hw_threads:
            if t.slot:
                # check if a hw thread terminated
                if t.exec_time <= t.time_this and m.workload <= m.workload_this:
                    if schedule != 'simple_with_measuring':
                        t.state = 'terminated'
                        t.slot.state = 'available'
                        t.slot.hw_thread = None
                        t.slot = None

