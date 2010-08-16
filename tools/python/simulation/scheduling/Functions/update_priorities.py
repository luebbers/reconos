#!/usr/bin/env python
"""\file update_priorities.py

updates priorities of hw and sw threads

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

import sys, operator
sys.path.append("../Components")
from sw_thread import *
from hw_thread import *
from migrate_thread import *

def update_priorities(hw_threads, sw_threads, migrate_threads):
    # sort hw threads according to deadlines (EDF)
    hw_threads[:] = sorted(hw_threads, key=operator.attrgetter('deadline'),reverse=True)

    old_deadline = sys.maxint
    p = 0
    for t in hw_threads:
        # set priority
        t.priority = p
        # same deadline => same priority
        if t.deadline < old_deadline:
            old_deadline = t.deadline
            p += 1
        t.priority = p


    # sort sw threads according to deadlines (EDF)
    sw_threads[:] = sorted(sw_threads, key=operator.attrgetter('deadline'),reverse=True)

    old_deadline = sys.maxint
    p = 0
    for t in sw_threads:
        # set priority
        t.priority = p
        # same deadline => same priority
        if t.deadline < old_deadline:
            old_deadline = t.deadline
            p += 1
        t.priority = p


    # sort migrate threads according to deadlines (EDF)
    migrate_threads[:] = sorted(migrate_threads, key=operator.attrgetter('deadline'),reverse=True)

    old_deadline = sys.maxint
    p = 0
    for t in migrate_threads:
        # set priority
        t.priority = p
        # same deadline => same priority
        if t.deadline < old_deadline:
            old_deadline = t.deadline
            p += 1
        t.priority = p
        t.sw_thread.priority = p
        t.sw_thread.priority = p



