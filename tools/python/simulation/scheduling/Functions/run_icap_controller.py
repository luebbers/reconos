#!/usr/bin/env python
"""\file run_icap_controller.py

simulates smart icap controller

\author     Markus Happe   <markus.happe@upb.de>
\date       31.07.2009
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
from slot import *
from hw_thread import *
from icap import *

def run_icap_controller(icap, slots):
    """runs (extended) icap controller. It checks, if a hw thread wants to be reconfigured.
    It does the reconfiguration steps, but only if the thread is not allready configured in a slot"""


    # increment running time for running threads
    for i in icap:
        # sort icap list according to deadlines
        #i.threads[:] = sorted(i.threads, key=operator.attrgetter('deadline'),reverse=False)
        #for t in i.threads:
            #print '   Thread', t.name, 'waits for reconfiguration to slot', t.slot.name

        if i.current_thread == None:
            if len(i.threads)==0:
                # nothing to do => go idle
                i.state = 'idle'
                i.slot = None
            else:
                # get next thread from list
                i.current_thread = i.threads[0]
                #if i.current_thread.slot:
                #    if i.current_thread.slot.hw_thread != i.current_thread:
                #        #i.current_thread = i.threads[1]
                #        a = 1
                i.threads.remove(i.current_thread)
                # check if hw thread is already in a slot. If so, use it
                found_thread = False
                for s in slots:
                    if i.current_thread != None and s.hw_thread != None:
                        if i.current_thread.name == s.hw_thread.name and i.current_thread.state == 'yielded':
                            found_thread = True
                            i.current_thread.reconfig_time_this = 0
                            i.current_thread.state = 'running'
                            i.current_thread.slot = s
                            s.state = 'active'
                            i.current_thread = None
                #  else: start reconfiguration                 
                if not found_thread:
                    #slot_busy = False
                    #if i.slot and i.slot.hw_thread:
                    #    print 'test test'
                    #    if i.slot.hw_thread.state!='terminated' or i.slot.hw_thread.exec_time<=i.slot.hw_thread.time_this:
                    #        print 'testA testA'
                    #        slot_busy = True
                    #if not slot_busy:
                    if len(icap)>0: # todo remove this if condition
                        i.state = 'reconfiguring'
                        i.slot = i.current_thread.slot
                        i.current_thread.reconfig_time_this += 1
                        i.current_thread.state = 'reconfig'
                        if i.current_thread.slot:
                            i.current_thread.slot.hw_thread = i.current_thread #new
                            i.current_thread.slot.state = 'reconfig'
        else:
            # continue reconfiguring of current thread
            found_thread = False
            # is thread allready configured in a slot => use it
            for s in slots:
                if i.current_thread != None and s.hw_thread != None:
                    if i.current_thread == s.hw_thread and i.current_thread.state == 'yielded':
                        found_thread = True
                        i.current_thread.reconfig_time_this = 0
                        i.current_thread.state = 'running'
                        i.current_thread.slot = s
                        s.state = 'active'
                        i.current_thread = None 
            # else: configure hw thread into slot                  
            if not found_thread:
                i.current_thread.reconfig_time_this += 1   
                if  i.current_thread.reconfig_time <= i.current_thread.reconfig_time_this:
                    i.current_thread.reconfig_time_this = 0
                    i.current_thread.state = 'reconfigured' #'running'
                    if i.current_thread.slot:
                        i.current_thread.slot.state = 'reconfigured' #'active'
                    i.current_thread = None




