#!/usr/bin/env python
"""\file multithread.py

multithread class

\author     Markus Happe   <markus.happe@upb.de>
\date       11.08.2009
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
# 11.08.2009   Markus Happe   File created.

from slot import *
from sw_thread import *
from hw_thread import *
from cpu import *
from slot import *
from reconos_resource import *
import sys

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


class Multithread:
    def __init__(self, sw_exec, hw_exec, reconfig_time=4, workloads=[],resources_sw=[], resources_hw=[], migration_points_sw=[], migration_points_hw=[], number_of_sw_threads=1, number_of_hw_threads=0, name='unnamed', color='\033[34m', color_blocked='\033[33m', gantt_color='green' ): #, gantt_color_blocked='darkgreen'):

        # create (mutliple) hw threads
        self.hw_threads = []
        for i in range (number_of_hw_threads):
            thread_string = 'HW_' + name + '_' +str(i+1)
            self.hw_threads.append (HW_Thread(2,
                sys.maxsize,
                hw_exec,
                resources_hw,
                migration_points_hw,
                thread_string,
                color,
                color_blocked,
                reconfig_time,
                self)
            )

        # create (mutliple) sw threads
        self.sw_threads = []
        for i in range (number_of_sw_threads):
            thread_string = 'SW_' + name + '_' +str(i+1)
            self.sw_threads.append (SW_Thread(2,
                sys.maxsize,
                sw_exec,
                resources_sw,
                migration_points_sw,
                thread_string,
                color,
                self)
            )

        self.gantt_color = gantt_color
        self.sw_exec = sw_exec
        self.hw_exec = hw_exec
        #self.gantt_color_blocked = gantt_color_blocked
        self.name = name
        self.workloads = workloads
        self.workload = 0
        self.workload_this = 0
        self.number_of_sw_threads = number_of_sw_threads
        self.number_of_hw_threads = number_of_hw_threads
        self.priority = 0
        self.speedup100 = (sw_exec * 100) / hw_exec
        self.reconfig_time = reconfig_time
        self.sw_runtime = 0
        #self.state = 'terminated'




