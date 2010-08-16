#!/usr/bin/env python
"""\file hw_thread.py

hardware thread class

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
from slot import *
from reconos_resource import *
from multithread import *

class HW_Thread:
    def __init__(self, priority, period, exec_time, res=[], yields=[], name='unnamed', color='\033[34m', color_blocked='\033[33m', reconfig_time=4, multithread=None, context_save_time=2, context_load_time=2):
        self.priority = priority     # hw priority
        self.period = period         # thread period
        self.deadline = period       # absoult deadline
        self.exec_time = exec_time   # execution time of the thread
        self.resources = res         # list of resources and times, when they are locked
        self.name = name             # thread name
        self.reconfig_time = reconfig_time # reconfiguration time
        self.reconfig_time_this = 0  # elapsed reconfiguration time
        self.color = color           # bash color
        self.color_blocked = color_blocked # bash color (for blocked threads)
        self.time_this = 0           # time elapsed in current period
        self.slot = None             # current slot
        self.state = 'terminated'    # can be 'ready', 'running', 'terminated', 'blocking', 'yielding', 'resumed'
        self.current_resources = []  # resources currently held by this thread
        self.yieldings = yields      # time steps in which a thread can be yielded
        self.migration_points = yields  # time steps in which a thread can be migrated between hw and sw 
        self.multithread = multithread  # pointer to multithread instance 
        self.context_save_time = context_save_time # for future: load/save context
        self.context_save_time_this = 0            # for future: load/save context
        self.context_load_time = context_load_time # for future: load/save context
        self.context_load_time_this = 0            # for future: load/save context
        self.workload_this = 0
        self.measured_runtime = 0

