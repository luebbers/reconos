#!/usr/bin/env python
"""\file find_slot.py

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

import sys
sys.path.append("../Components")
from slot import *
from hw_thread import *


def find_slot(slots, thread):
    """returns suitable slot for thread, or None
    
    Assumes that preemption is allowed."""

    minimum = 9999

    # first, try to find a free slot (and remember the minimum)
    for s in slots:
        if s.state == 'available':
            return s
#        if s.thread.priority < minimum:
#            minimum = s.thread.priority
#            x = s

#    # if that fails, return the slot with the lowest
#    # priority, if it is lower than the priority of 'thread'
#    if minimum < thread.priority:
#        return x
#    else:
#        return None 
    return None

#----------------------------------------------------------------------------

def find_free_slot(slots, thread):
    """returns free slot for thread, or None"""

    # 1. try to find an available slot (thread has terminated)
    for s in slots:
        if s.state == 'available':
            return s
    # 2. else: try to find an yielding slot
    #for s in slots:
    #    if s.state == 'yielding':
    #        return s
    return None




