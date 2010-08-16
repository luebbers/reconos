#!/usr/bin/env python
"""\file sw_thread.py

Python simulation classes for ReconOS Scheduling Policies

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

from cpu import *
from reconos_resource import *
from multithread import *

class SW_Thread:
    def __init__(self, priority, period, exec_time, res=[], migrations=[], name='unnamed', color='\033[m', multithread=None):
        self.priority = priority
        self.period = period
        self.deadline = period
        self.exec_time = exec_time
        self.resources = res
        self.migration_points = migrations  # time steps in which a thread can be migrated between hw and sw 
        self.name = name
        self.color = color
        self.time_this = 0          # time elapsed in current period
        self.cpu = None
        self.state = 'terminated'         # can be 'ready', 'running', 'terminated', 'blocking', 'preempted', 'yield'
        self.current_resources = []  # resources currently held by this thread
        self.multithread = multithread  # pointer to multithread instance
        self.workload_this = 0
        self.measured_runtime = 0





