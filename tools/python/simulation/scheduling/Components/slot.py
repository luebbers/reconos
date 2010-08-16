#!/usr/bin/env python
"""\file slot.py

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


class Slot:
    def __init__(self, name='unnamed'):
        self.name = name
        self.schedule = []
        # states: 'reconfiguring', 'occupied' (by some hw thread), 'available' (yielding hw thread or free) 
        self.state = 'available'
        self.hw_thread = None
        self.schedule = []
        self.schedule_task = []
        self.work_package = []
        self.used_timeslots = 0
