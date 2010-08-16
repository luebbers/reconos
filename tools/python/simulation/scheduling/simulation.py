#!/usr/bin/env python
"""\file simulation.py

scheduling simulation for a user-defined number of time steps

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
sys.path.append("Components")
sys.path.append("Functions")
from print_status import *
from simulation_step import *
from slot import *
from cpu import *
from reconos_resource import *
from sw_thread import *
from hw_thread import *
from migrate_thread import *
from create_gantt import *
from draw_gantt import *

def remember_schedule(cpu, slots):
        # remember schedule for gantt diagram: here cpu
        for c in cpu:
            string_thread = "---"
            string_work = ""
            thread_name = ""
            if c.sw_thread:
                if c.sw_thread.multithread:
                    string_thread = c.sw_thread.multithread.gantt_color #name
                    if c.sw_thread.time_this < 2:
                        string_work = "["+str(c.sw_thread.workload_this)+"]"
                        thread_name = "T"+c.sw_thread.multithread.name[5:]
                    else:
                        string_work = " - "
            c.schedule.append(string_thread)
            c.schedule_task.append(thread_name)
            c.work_package.append(string_work)
        # remember schedule for slots
        for s in slots:
            string_thread = "---"
            string_work = ""
            thread_name = ""
            if s.hw_thread:
                if s.hw_thread.multithread:
                    if s.hw_thread.state == "running":
                        string_thread = s.hw_thread.multithread.gantt_color #name
                        if s.hw_thread.time_this < 2:
                            string_work = "["+str(s.hw_thread.workload_this)+"]"
                            thread_name = "T"+s.hw_thread.multithread.name[5:]
                        else:
                            string_work = " - "
                    elif s.hw_thread.state == "reconfig" or s.hw_thread.state == "reconfigured":
                        string_thread = "reconfig"
                        string_work = " > "
                    elif s.hw_thread.state == "blocking":
                        string_work = "x"
            s.schedule.append(string_thread)
            s.schedule_task.append(thread_name)
            s.work_package.append(string_work)
        # update used timeslots for each cpu and slot (for utilization calculation)    
        update_used_timeslots (cpu, slots)

# update used timeslots for cpus and slots
def update_used_timeslots (cpu, slots):
        for c in cpu:
            if c.sw_thread:
                c.used_timeslots += 1
        for s in slots:
            if s.hw_thread:
                if s.hw_thread.state == "running":
                    s.used_timeslots += 1


# run simulation for 'runtime' timestep (at most)
def run_simulation(cpu, hw_threads, sw_threads, multithreads, migrate_threads, slots, resources, icap, schedule, measurement_unit, runtime, debug):

    # print table header for output
    #print_table_header(cpu, slots)
    time = 0
    end_of_simulation = False
    simulation_time = 0

    # init workload for threads
    for t in multithreads:
        t.workload = 0
        t.workload_this = 0
        for t2 in t.hw_threads:
            t2.slot = None
    for t in hw_threads:
        t.workload_this = 0
        t.slot = None
        t.state = 'terminated'
    for t in sw_threads:
        t.workload_this = 0
        t.cpu = None
        t.state = 'terminated'

    
    while (time < runtime and not end_of_simulation):

        # run scheduling simulation for the next time step 
        run_simulation_step(cpu, hw_threads, sw_threads, multithreads, migrate_threads, slots, icap, schedule, measurement_unit, time)

        # remember schedule
        remember_schedule(cpu, slots)
  
        # increment simulation time
        time = time + 1

        # print status
        if debug=="debug" or debug=="DEBUG":
            print_status(cpu, hw_threads, sw_threads, migrate_threads, slots, time)

        # check, if more tasks need to be scheduled, else stop simulation
        if not end_of_simulation:
            end_of_simulation = True
            # 1. check, if this was the last workpackage
            for t in multithreads:
                if t.workload_this < t.workload:
                    end_of_simulation = False

            # 2. check, if all resources are idle
            for c in cpu:
                if c.sw_thread:
                    end_of_simulation = False
            for s in slots:
                if s.hw_thread:
                    if s.hw_thread.state == "running":
                        end_of_simulation = False

            if end_of_simulation:
                simulation_time = time-1
                print ("End of simulation at time "+str(time-1))

    if (not end_of_simulation):
        simulation_time = runtime

    # print effective utilization
    for c in cpu:
        print ("CPU "+c.name+": "+str((100*c.used_timeslots)/simulation_time)+"%")
    for s in slots:
        print ("Slot "+s.name+": "+str((100*s.used_timeslots)/simulation_time)+"%")

    # return simulated time
    return simulation_time

        #for r in resources:
        #   print 'Resource', r.name, ':', str(r.number)

        #for m in migrate_threads:
        #    print "Thread", m.hw_thread.name, ", SW =", m.sw_thread.state, ", HW =", m.hw_thread.state 

        # debug....
        #if 110 <= time <= 112:
        #    for s in slots:
        #        if s.hw_thread:
        #            print 'Slot', s.name, ' => HW_Thread', s.hw_thread.name, ', state =', s.state
        #    for t in hw_threads:
        #        if t.slot:
        #             print 'HW_Thread', t.name,' => Slot', t.slot.name,', state =',t.state,', workload =', t.workload_this
        #        else:
        #            print 'HW_Thread', t.name, ' => no Slot , state =', t.state, ', workload =', t.workload_this
        #    for t in sw_threads:
        #        if t.cpu:
        #             print 'HW_Thread', t.name, ' => on CPU, state =', t.state, ', workload =', t.workload_this
        #        else:
        #            print 'HW_Thread', t.name, ' => not on CPU, state =', t.state, ', workload =', t.workload_this
        #    for m in migrate_threads:
        #        t = m.hw_thread
        #        if t.slot:
        #            print 'HW_Thread', t.name, ' => Slot', t.slot.name, ', state =', t.state, ', deadline =', str(t.deadline)
        #        else:
        #            print 'HW_Thread', t.name, ' => no Slot , state =', t.state, ', deadline =', str(t.deadline)

     
    # draw Gantt diagram to html file
    #export_gantt(open('gantt.html', 'w'), multithreads, cpu, slots, runtime)
    #draw_gantt(multithreads, cpu, slots, runtime)

    #for c in cpu:
    #    counter = 0
    #    for t in c.schedule:
    #        counter += 1
    #        print counter, t

    #for s in slots:
    #    counter = 0
    #    for t in s.schedule:
    #        counter += 1
    #        print counter, t

