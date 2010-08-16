#!/usr/bin/env python
"""\file cpu.py

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


class Cpu:
    def __init__(self, name='unnamed'):
        self.name = name
        # states: 'idle', 'busy'
        self.state = 'available'
        self.sw_thread = None
        self.schedule = []
        self.schedule_task = []
        self.work_package = []
        self.used_timeslots = 0





