#!/usr/bin/env python
"""\file update_measurement.py

updates measurement

\author     Markus Happe   <markus.happe@upb.de>
\date       17.08.2009
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
from slot import *
from cpu import *
from hw_thread import *
from sw_thread import *
from measurement_unit import *

# updates measurement for running(!) threads
def update_measurements(cpu, slots, measurement_unit):
    # update measurements for threads on cpu and slots
    for c in cpu:
        if c.sw_thread and c.sw_thread.state == 'running':
            # increase measured runtime
            c.sw_thread.measured_runtime += 1
    for s in slots:
        if s.hw_thread and (s.hw_thread.state == 'running' or s.hw_thread.state == 'reconfig'):
            # increase measured runtime
            s.hw_thread.measured_runtime += 1
    # update current measurement step
    for m in measurement_unit:
        m.time_this += 1


# clears measurements in sw/hw threads
def clear_measurements(sw_threads, hw_threads, measurement_unit):
    # if measurement complete, clear measurements
    for m in measurement_unit:
        # clear, if current time step == period
        if m.period <= m.time_this:
            # clear m. unit timer and sw/hw measurements
            m.time_this = 0
            for t in hw_threads:
                t.measured_runtime = 0
            for t in sw_threads:
                t.measured_runtime = 0




