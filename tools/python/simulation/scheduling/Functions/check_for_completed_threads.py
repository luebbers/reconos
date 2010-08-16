#!/usr/bin/env python
"""\file check_for_completed_threads.py

checks for

\author     Markus Happe   <markus.happe@upb.de>
\date       03.08.2009
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
# 03.08.2009   Markus Happe   File created.

import sys
sys.path.append("../Components")
from slot import *
from sw_thread import *
from hw_thread import *
from migrate_thread import *
from cpu import *
from slot import *

def check_for_completed_threads(cpu, hw_threads, sw_threads, migrate_threads):

    # 1. hw threads
    for t in hw_threads:
        if t.state == 'running':
            if t.time_this >= t.exec_time:
                t.state = 'terminated'
                t.time_this = 0
                if t.slot != None:
                    t.slot.state = 'available'

    # 2. sw threads
    for t in sw_threads:
        if t.state == 'running':
            if t.time_this >= t.exec_time:
                t.state = 'terminated'
                t.time_this = 0
                if t.cpu:
                    t.cpu.state = 'idle'
                    t.cpu.sw_thread = None
                    t.cpu = None

    # 3. migrate threads
    for m in migrate_threads:
        t = m.sw_thread
        if t.state == 'running':
            if t.time_this >= t.exec_time:
                t.state = 'terminated'
                t.time_this = 0
                t.cpu.state = 'idle'
                t.cpu.sw_thread = None
                t.cpu = None
        t = m.hw_thread
        if t.state == 'running':
            if t.time_this >= t.exec_time:
                t.state = 'terminated'
                t.time_this = 0
                if t.slot != None:
                    t.slot.state = 'available'

