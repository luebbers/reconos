#!/usr/bin/env python
"""\file schedule.py

schedules multithreads

\author     Markus Happe   <markus.happe@upb.de>
\date       12.08.2009
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
# 12.08.2009   Markus Happe   File created.

import sys, operator
sys.path.append("../Components")
from slot import *
from hw_thread import *
from sw_thread import *
from multithread import *

# allocate multithreads to cpu and slots
def find_schedule(cpu, slots, multithreads, icap, schedule, measurement_unit, time):

    i = icap[0]
    
    ##############################################################################################
    #
    #    check, if another hw thread should be migrated to a slot
    #
    ##############################################################################################

    if schedule == 'simple_with_workload':

        ##############################################################################################
        #
        #    A.1 get sw thread with maximum remaining sw runtime (respecting degree of parallelism)
        #
        ##############################################################################################
        reconfigured_slot = False # reconfigure at maximum one slot at time step
        for s in slots:
            # if there is a free slot and icap is not reconfiguring
            if not s.hw_thread and not i.current_thread and len(i.threads)==0 and not reconfigured_slot:
                ## i.1)  find multithread with highest best hw 'speedup' 
                ##     (saves most time steps when running in hw according to workload
                #best_speedup = 0
                #best_thread = None
                #sw_run_time = 0
                #for m in multithreads:
                #    if len(m.sw_threads)>0 and len(m.hw_threads)>0:
                #        diff = m.sw_threads[0].exec_time - m.hw_threads[0].exec_time
                #        current_workload = m.workload - m.workload_this
                #        current_speedup = diff * current_workload
                #        current_speedup -= m.hw_threads[0].reconfig_time
                #        if current_speedup > best_speedup:
                #            # found current best speedup
                #            best_speedup = current_speedup
                #            best_thread = m
                #            sw_run_time = m.sw_threads[0].exec_time * (m.workload - m.workload_this)

                ## i.2) find thread with highest sw runtime
                sw_run_time = 0
                best_thread = None
                for m in multithreads:
                    if len(m.sw_threads)>0 and len(m.hw_threads)>0:
                        current_sw_run_time = m.sw_threads[0].exec_time * (m.workload - m.workload_this)
                        if 0 <= m.priority:
                            current_sw_run_time /= (m.priority + 1)
                        if current_sw_run_time > sw_run_time:
                            # found current thread with highest sw runtime => use hw slots
                            sw_run_time = current_sw_run_time
                            best_thread = m
                ## ii) load best thread into free slot
                counter = 0
                if best_thread:
                    # find free hw thread
                    t = None
                    for t1 in best_thread.hw_threads:
                        if not t1.slot:
                            t = t1
                    #t = best_thread.hw_threads[counter]
                    if t and (not t.slot) and t.multithread.workload>0 and t.multithread.workload_this<t.multithread.workload:
                        # only reconfigure if there is still enough todo, so that reconfiguration time is accpetable
                        if (t.reconfig_time + t.exec_time) < (sw_run_time/(1+t.multithread.priority)):
                            m3 = t.multithread
                            #print("time= "+str(time)+"  3) increase workload for task "+str(m3.name)+" from: "+str(m3.workload_this)+" to: "+str(m3.workload_this+1))
                            #t.multithread.workload_this += 1
                            #t.workload_this = t.multithread.workload_this
                            #s.hw_thread = t
                            t.slot = s 
                            reconfigured_slot = True
                            #print 'thread', t.name, 'in slot', s.name


    elif schedule == 'bin_packing':

        ##############################################################################################
        #
        #    B.1 assign the threads to hw slots, which have the highest profit (= saved runtime = workload * sw_exec_time)
        #
        ############################################################################################## 

        reconfigured_slot = False # reconfigure at maximum one slot at time step
        for s in slots:
            # if there is a free slot and icap is not reconfiguring
            if not s.hw_thread and not i.current_thread and len(i.threads)==0 and not reconfigured_slot:

                ## i) find thread with highest sw runtime
                sw_run_time = 0
                best_thread = None
                for m in multithreads:
                    if len(m.sw_threads)>0 and len(m.hw_threads)>0 and m.priority==0: # thread only running in sw
                        current_sw_run_time = m.sw_threads[0].exec_time * (m.workload - m.workload_this)
                        #if 0 <= m.priority:
                        #    current_sw_run_time /= (m.priority + 1)
                        if current_sw_run_time > sw_run_time:
                            # found current thread with highest sw runtime => use hw slots
                            sw_run_time = current_sw_run_time
                            best_thread = m
                ## ii) load best thread into free slot
                counter = 0
                if best_thread:
                    # find free hw thread
                    t = None
                    for t1 in best_thread.hw_threads:
                        if not t1.slot:
                            t = t1
                    #t = best_thread.hw_threads[counter]
                    if t and (not t.slot) and t.multithread.workload_this < t.multithread.workload:
                        # only reconfigure if there is still enough todo, so that reconfiguration time is accpetable
                        #if (t.reconfig_time + t.exec_time) < (sw_run_time/(1+t.multithread.priority)):
                        m3 = t.multithread
                        t.slot = s 
                        reconfigured_slot = True


    #######################################################################################################
    #######################################################################################################

    elif schedule == 'simple_with_measuring':

        ##############################################################################################
        #
        #    C.1 get sw thread A with maximum measured sw runtime
        #
        ##############################################################################################
        best_thread = None
        mu = measurement_unit[0]
        if mu.period <= mu.time_this:
            # measurement complete => migrate
            # 1. find sw thread with highest measured runtime
            thread_with_highest_sw_runtime = None
            highest_measured_sw_runtime = 0
            for m in multithreads:
                for t in m.sw_threads:
                    if t.measured_runtime > highest_measured_sw_runtime:
                        # remember thread with currently highest sw runtime
                        highest_measured_sw_runtime = t.measured_runtime
                        thread_with_highest_sw_runtime = t


            ##############################################################################################
            #
            #    C.2 get reconfigured hw thread B with minimum estimated sw runtime
            #
            ##############################################################################################
            if thread_with_highest_sw_runtime:
                # find hw thread which is currently the one which has the lowest measured 'sw'-utilization
                lowest_sw_runtime = sys.maxsize
                worst_slot = None
                for s in slots:
                    if not s.hw_thread:
                        #print 'slot free'
                        lowest_sw_runtime = -1
                        worst_slot = s
                    else:
                        # estimate sw runtime for hw thread in slot
                        estimated_sw_runtime = (s.hw_thread.measured_runtime * s.hw_thread.multithread.speedup100) / 100
                        # add reconfigration costs (rc)
                        rc = thread_with_highest_sw_runtime.multithread.reconfig_time
                        ### highest_sw_runtime(CPU) - lowest_sw_runtime(Slots) > rc
                        ### highest_sw_runtime(CPU) > lowest_sw_runtime(Slots) + rc
                        if estimated_sw_runtime + rc <= highest_measured_sw_runtime:
                            if estimated_sw_runtime + rc < lowest_sw_runtime:
                                worst_slot = s
                                lowest_sw_runtime = estimated_sw_runtime + rc

                ##############################################################################################
                #
                #    C.3 switch sw thread with hw thread, if this seems advantageous and thread B is not running
                #
                ##############################################################################################
                # ii) load best thread into free slot
                counter = 0
                # check if thread in worst slot is still running
                if worst_slot and worst_slot.hw_thread:
                    if worst_slot.hw_thread.state=='running':
                        if worst_slot.hw_thread.time_this < worst_slot.hw_thread.exec_time:
                            worst_slot = None
                # else
                if worst_slot:
                    t = None
                    for t1 in thread_with_highest_sw_runtime.multithread.hw_threads:
                        if not t1.slot:
                            t = t1
                    if t and not t.slot:
                        if t.multithread.workload>0 and t.multithread.workload_this<t.multithread.workload:
                            t.multithread.workload_this += 1
                            t.workload_this = t.multithread.workload_this
                        t.time_this = 0
                        #worst_slot.hw_thread = t
                        t.slot = worst_slot
                        #print 'thread', t.name, 'in slot', s.name



    ####################################################################################################################
    #
    #    II. schedule sw threads
    #
    ####################################################################################################################

    # i) priority = number of hw threads in slots
    for m in multithreads:
        counter = 0
        for t in m.hw_threads:
            if t.slot:
                counter += 1
        m.priority = counter
        if counter == 0:
            m.sw_runtime = (m.workload - m.workload_this) * m.sw_exec
        else:
            m.sw_runtime = 0

    # ii) sort multithreads
    if schedule == 'simple_with_workload' or schedule=='bin_packing':
        multithreads[:] = sorted(multithreads, key=operator.attrgetter('sw_runtime'),reverse=False)
    else:
        multithreads[:] = sorted(multithreads, key=operator.attrgetter('priority'),reverse=False)



