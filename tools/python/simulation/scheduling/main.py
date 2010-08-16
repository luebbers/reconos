#!/usr/bin/env python
"""\file main.py

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

import sys, random
sys.path.append("Components")
sys.path.append("Functions")
from sw_thread import *
from hw_thread import *
from reconos_resource import *
from icap import *
from slot import *
from simulation import * 
from cpu import *
from migrate_thread import *
from multithread import *
from show_menu import *

#import Components.sw_thread, Components.hw_thread, Components.reconos_resource, Components.slot, Components.cpu, simulation 

if __name__ == "__main__":

    show_menu()

    #num_slots = 5

    #R1 = Resource(1, 'R1')
    #R2 = Resource(1, 'R2')
    #R3 = Resource(1, 'R3')
    #resources = []
    #for i in range (10):
    #    resources.append(Resource(1, 'M'+str(i)))
    #for r in resources:
    #    print r.name
    #messages_AB = Resource( 0, 'Mab')
    #messages_BS = Resource( 0, 'Mbs')
    #messages_SC = Resource( 0, 'Msc') # synchronize
    #messages_CA = Resource(1, 'Mca')
    #resources = [messages_AB, messages_BS, messages_SC, messages_CA]
    #resources = () #(R1, R2, R3)

    #HW_A = HW_Thread(1,
    #        40,
    #        10,
    #        ( ( R1, [(5, 7)]),),
    #        ( [ 5 ]
    #        ),
    #        'HW_A',
    #        '\033[m\33[42m',
    #        '\033[37m\33[42m',
    #        4)

    #HW_B = HW_Thread(3,
    #        50, 
    #        20,
    #        ( ( R1, [(5, 10)]),
    #          #( R2, [(1, 17)]),
    #        ),
    #        ( [ 5, 15 ]
    #        ),
    #        'HW_B',
    #        '\033[m\33[41m',
    #        '\033[37m\33[41m',
    #        6)

    #HW_C = HW_Thread(2,
    #        70, 
    #        36,
    #        (   ( R1, [(10, 22), (30, 35)]),      # resource 1 held between t = (10, 20) and (30, 35)
    #            ( R2, [(15, 17)])                 # resource 2 held between t = (15, 17)
    #        ),
    #        ( [ 10, 30 ]
    #        ),
    #        'HW_C',
    #        '\033[m\33[46m',
    #        '\033[37m\33[46m',
    #        8)

    #SW_A = SW_Thread(6,
    #        25, 
    #        5,
    #        ( ( R3, [(2, 4)]), ),
    #        ([]),
    #        'SW_A',
    #        '\033[m\33[42m')
    #        #'\033[37m\33[44m')

    #SW_B = SW_Thread(7,
    #        40,#50,
    #        10,
    #        #( ),
    #        ( ( R3, [(4, 7)]),),
    #        ([]),
    #        'SW_B',
    #        '\033[m\33[41m')
    #        #'\033[37m\33[45m')

    #SW_C = SW_Thread(5,
    #        80, 
    #        20,
    #        ( ( R3, [(5, 12)]),),
    #        ([]),
    #        'SW_C',
    #        #'\033[30m\33[47m')
    #        '\033[m\33[46m')
    #        ####'\033[30m\33[43m')

    #MGT_A = Migrate_Thread(5,
    #        90,
    #        10,
    #        ( ( R1, [(3, 6)]), ),
    #        ( [3, 7] ),
    #        20,
    #        ( ( R1, [(7, 13)]), ),
    #        ( [7, 14] ), 
    #        'MT_A',
    #        #'\033[30m\33[47m',
    #        '\033[30m\33[43m',
    #        '\033[m\33[43m',
    #        '\033[37m\33[43m',
    #        4,
    #        2,
    #        2
    #)

    #hw_threads = [HW_A, HW_B, HW_C]
    #sw_threads = [SW_A, SW_B, SW_C]
    #migrate_threads = [] #MGT_A]
    #slots = [ Slot('S%d' % i) for i in range(num_slots) ]
    #cpu = [Cpu('CPU')]
    #icap = [Icap('ICAP')]

    #MT_A = Multithread(
    #    20,               # sw (worst case) execution time
    #    10,               # hw (worst case) execution time  
    #    30,               # reconfig time for hw thread
    #    ((0, 2), (120, 3), (200, 3)), # workload list (time, workload)
    #    # resources (time step, resource, number of units, request/release)
    #    [], #((1, messages_CA, 1, 'request'), (19, messages_AB, 1, 'release'),),    # resources (sw thread)
    #    [], #((1, messages_CA, 1, 'request'), ( 9, messages_AB, 1, 'release'),),   # resources (hw thread)
    #    #(( messages_CA, [(1, 10)]),),
    #    [],               # migration points (sw)
    #    [], #( [ 1] ),         # migration/yielding points (hw)
    #    1,                # number of sw threads
    #    2,                # number of hw threads
    #    'MT_A',           # name
    #    '\033[m\33[42m',  # text color for bash
    #    '\033[37m\33[42m', # text color for blocking/reconfiguring states#
    #    'blue' #,            # gantt color
    #    #'darkblue'         # gantt blocked color 
    #)

    #MT_B = Multithread(
    #    30,               # sw (worst case) execution time
    #    12,               # hw (worst case) execution time  
    #    35,               # reconfig time for hw thread
    #    ((0, 4), (120, 10), (240, 8)), # workload list (time, workload)
    #    # resources (time step, resource, number of units, request/release)
    #    [], #((1, messages_AB, 1, 'request'), (29, messages_BS, 1, 'release'),),    # resources (sw thread)
    #    [], #((1, messages_AB, 1, 'request'), (11, messages_BS, 1, 'release'),),    # resources (hw thread)
    #    [],               # migration points (sw)
    #    [], #( [ 1] ),         # migration/yielding points (hw)
    #    1,                # number of sw threads
    #    2,                # number of hw threads
    #    'MT_B',           # name
    #    '\033[m\33[41m',  # text color for bash
    #    '\033[37m\33[41m', # text color for blocking/reconfiguring states 
    #    'red' #,             # gantt color  
    #    #'darkred'          # gantt blocked color 
    #)

    #MT_S = Multithread(   # synchronize
    #    3,                # sw (worst case) execution time
    #    10,               # hw (worst case) execution time  
    #    4,                # reconfig time for hw thread
    #    ((0, 1), (130,1), (260, 1)), # workload list (time, workload)
    #    # resources (time step, resource, number of units, request/release)
    #    [], #((1, messages_BS, 10, 'request'), (2, messages_SC, 10, 'release'),),    # resources (sw thread)
    #    [],               # migration points (sw)
    #    [],               # migration points (hw)
    #    [],               # resources (hw thread)
    #    1,                # number of sw threads
    #    0,                # number of/yielding hw threads
    #    'SYNC',           # name
    #    '\033[m\33[45m',  # text color for bash
    #    '\033[37m\33[45m', # text color for blocking/reconfiguring states 
    #    'yellow' #,          # gantt color
    #    #'orange'           # gantt blocked color  
    #)

    #MT_C = Multithread(
    #    20,               # sw (worst case) execution time
    #    15,               # hw (worst case) execution time  
    #    40,               # reconfig time for hw thread
    #    ((0, 20), (130,20), (260, 20)), # workload list (time, workload)
    #    # resources (time step, resource, number of units, request/release)
    #    [], #((1, messages_SC, 1, 'request'), (19, messages_CA, 1, 'release'),),    # resources (sw thread)
    #    [], #((1, messages_SC, 1, 'request'), (14, messages_CA, 1, 'release'),),    # resources (hw thread)
    #    [],               # migration points (sw)
    #    [], #( [ 1 ] ),        # migration/yielding points (hw)
    #    1,                 # number of sw threads
    #    2,                 # number of hw threads
    #    'MT_C',            # name
    #    '\033[m\33[46m',   # text color for bash
    #    '\033[37m\33[46m', # text color for blocking/reconfiguring states 
    #    'green' #,           # gantt color
    #    #'darkgreen'        # gantt blocked color  
    #)

    #measurement_unit = [Measurement_unit('Measurement Unit 1', 40)]


    #multithreads = [MT_C, MT_A, MT_B] #, MT_S]

    # create 40 multithreads
    #multithreads = []
    #for i in range(1,50+1):
    #    string_color = '#'+str(hex(random.randint(0,15)))[2:]
    #    string_color += str(hex(random.randint(0,15)))[2:]
    #    string_color += str(hex(random.randint(0,15)))[2:]
    #    string_color += str(hex(random.randint(0,15)))[2:]
    #    string_color += str(hex(random.randint(0,15)))[2:]
    #    string_color += str(hex(random.randint(0,15)))[2:]
    #    if i < 10:
    #        thread_name = "Task_0"+str(i)
    #    else:
    #        thread_name = "Task_"+str(i)
    #    multithreads.append(Multithread(
    #        random.randint(30, 60) ,        # sw (worst case) execution time
    #        random.randint(10, 30) ,        # hw (worst case) execution time  
    #        random.randint(60,  80) ,        # reconfig time for hw thread
    #        ((0, random.randint(5, 30) ), ), # workload list (time, workload)
    #        [],                # resources (sw thread) (time step, resource, number of units, request/release)
    #        [],                # resources (hw thread) (time step, resource, number of units, request/release)
    #        [],                # migration points (sw)
    #        [],                # migration/yielding points (hw)
    #        1,                 # number of sw threads
    #        1,                 # number of hw threads
    #        thread_name,       # name
    #        '\033[m\33[46m',   # text color for bash
    #        '\033[37m\33[46m', # text color for blocking/reconfiguring states 
    #        string_color   # gantt color 
    #    ))


    # extract hw and sw threads from multithreads
    #hw_threads = [t for m in multithreads for t in m.hw_threads]
    #sw_threads = [t for m in multithreads for t in m.sw_threads]

    #schedule = ['simple_with_workload', 'simple_with_measuring']

    #run_simulation(cpu, hw_threads, sw_threads, multithreads, migrate_threads, slots, resources, icap, schedule[int(sys.argv[1])], measurement_unit, int(sys.argv[2]), sys.argv[3])

    #show_menu(schedule[int(sys.argv[1])], sys.argv[3])


