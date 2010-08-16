#!/usr/bin/env python
"""\file simulation_step.py

runs one simulation step

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
sys.path.append("Functions")
from insert_new_threads import *
from run_icap_controller import *
from release_resources import *
from run_hw_threads import *
from run_sw_threads import *
from run_migrate_threads import *
from answer_yielding_calls import *
from update_priorities import *
from check_for_completed_threads import *
from increment_running_times import *
from update_workload import *
from check_termination import *
from schedule import *
from check_reconfiguration import *
from start_thread_instances import *
from update_measurement import *


def run_simulation_step(cpu, hw_threads, sw_threads, multithreads, migrate_threads, slots, icap, schedule, measurement_unit, time):

    # i) update workload
    update_workload(multithreads, time)

    # ii) check for terminated threads
    check_termination(multithreads, schedule)

    # iii) find best schedule / thread allocation
    find_schedule(cpu, slots, multithreads, icap, schedule, measurement_unit, time)

    # iv) clear_measurements(sw_threads, hw_threads, measurement_unit)
    clear_measurements(sw_threads, hw_threads, measurement_unit)

    # v) check for reconfiguration
    check_reconfiguration(multithreads, icap)

    # vi) start thread instances
    start_thread_instances(cpu, slots, multithreads, time)

    # vii) run icap controller for current time step
    run_icap_controller(icap, slots)

    # viii) increment running time for running threads
    increment_running_times(hw_threads, sw_threads, migrate_threads, time)

    # ix) update measurements
    update_measurements(cpu, slots, measurement_unit)

    # i) insert new thread instances
    #insert_new_threads(hw_threads, sw_threads, multithreads, migrate_threads, time)
    #
    # ii) update priorities
    #update_priorities(hw_threads, sw_threads, migrate_threads)
    #
    # ii) schedule
    #find_schedule(cpu, slots, multithreads, icap, time)
    #
    # iii) run icap controller for current time step
    #run_icap_controller(icap, slots)
    #
    # iv) release resources
    #release_resources (hw_threads, sw_threads, migrate_threads)
    #
    # v) check for completed threads
    #check_for_completed_threads (cpu, hw_threads, sw_threads, migrate_threads)
    #
    # vi) handle yieling calls
    #answer_yielding_calls(slots, hw_threads, migrate_threads, icap)
    #
    # vii) run hw threads for current time step
    #run_hw_threads(slots, hw_threads, icap)
    #
    # viii) run migrate threads for current time step
    #run_migrate_threads(cpu, slots, sw_threads, migrate_threads, icap)  
    #
    # ix) run sw threads for current time step
    #run_sw_threads(cpu, sw_threads, migrate_threads)
    #
    # x) increment running time for running threads
    #increment_running_times(hw_threads, sw_threads, migrate_threads)
    #


