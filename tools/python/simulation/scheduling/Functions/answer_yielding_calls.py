#!/usr/bin/env python
"""\file answer_yielding_calls.py

handles yielding calls from hw threads, which are not running in a slot (i.e. using priorities)

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

import sys, operator
sys.path.append("../Components")
from slot import *
from hw_thread import *
from migrate_thread import *
from icap import *
from find_slot import *

def answer_yielding_calls(slots, hw_threads, migrate_threads, icap):

    # only do this, if there is no available slot
    s = find_slot(slots, None)
    if not s:

        # 1. list all yielding threads and sort them
        yielding_threads = []
        for s in slots:
            if s.hw_thread:
                for y in s.hw_thread.yieldings:
                    if s.hw_thread.time_this == y: #undo +1
                        # yielding thread found
                        yielding_threads.append(s.hw_thread)

        #yielding_threads[:] = sorted(yielding_threads, key=operator.attrgetter('priority'),reverse=False)

        # 2. find hw threads, which are not configured in a slot
        # sort hw threads, starting with the highest hw priority
        #hw_threads[:] = sorted(hw_threads, key=operator.attrgetter('priority'),reverse=True)
        for t in hw_threads:
            # pick next yielding thread (if there is any)
            if len(yielding_threads)>0:
                if t.slot == None and t.state != 'terminated': # implies a yielding call
                    # check if a yielding is allowed according to hw priorities
                    #if t.priority > yielding_threads[0].priority:
                    if yielding_threads[0].state == 'blocking':
                        #print 'yielding thread', yielding_threads[0].name, 'can be replaced' 
                    #if t.deadline < yielding_threads[0].deadline:
                        # yielding call. => reconfigure
                        if yielding_threads[0].slot:
                            # remove yielding thread from list
                            yielder = yielding_threads.pop(0)
                            t.slot = yielder.slot
                            # reconfigure
                            if (len(icap)>0):
                                i = icap[0]
                                if i.current_thread == None:
                                    i.state = 'reconfiguring'
                                    i.current_thread = t
                                    i.current_thread.reconfig_time_this += 1
                                    i.slot = t.slot
                                    t.state = 'reconfig'
                                    t.slot.hw_thread = t
                                    t.slot.state = 'reconfig' 
                                    yielder.slot = None
                                    yielder.state = 'yielded'                              
                                #else:
                                #    i.threads.append(t)
                                #    t.state = 'wait for icap'
                                #    t.slot.state = 'wait for icap'
                            #print "yield: replace Thread", yielder.name, "by Thread", t.name, "in Slot", t.slot.name


