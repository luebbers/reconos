#!/usr/bin/env python
"""\file show_menu.py

shows menu for creating task sets

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
# 11.09.2009   Markus Happe   File created.

import operator, random, sys, pickle
sys.path.append("../Components")
sys.path.append("..")
from simulation import * 
from multithread import *
from hw_thread import *
from sw_thread import *
from cpu import *
from icap import *
from slot import *
from draw_gantt import *
from tkinter import *


def show_menu():

    # window
    tasks = []
    cpu = []
    slots = []
    schedule = ['simple_with_workload', 'simple_with_measuring', 'bin_packing']
    effective_runtime = []
    root = Tk()
    root.title('AG Platzner Task Allocation and Scheduling Simulator: Menu')
    root.geometry("%dx%d%+d%+d" % (700, 300, 0, 0))

    # frame
    frame = Frame(root, bd=2, relief=SUNKEN)
    frame.grid_rowconfigure(0, weight=1)
    frame.grid_columnconfigure(0, weight=1)

    # insert parameter: debug
    debug_var = IntVar()
    debug_button = Checkbutton(frame, text="Debug", variable=debug_var)
    debug_button.grid(row=5, column=4)

    # insert parameter: time
    time_label = Label(frame, text="Time")
    time_label.grid(row=6, column=0)
    time_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    time_spinbox.delete(0)
    time_spinbox.insert(0, "5000")
    time_spinbox.grid(row=6, column=1)

    # insert parameter: cpu
    cpu_label = Label(frame, text="#CPU")
    cpu_label.grid(row=1, column=0)
    cpu_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white", disabledbackground="white")
    cpu_spinbox.grid(row=1, column=1)
    cpu_spinbox.delete(0)
    cpu_spinbox.insert(0, "1")
    cpu_spinbox.config(state = DISABLED)

    # insert parameter: slots
    slots_label = Label(frame, text="#Slots")
    slots_label.grid(row=2, column=0)
    slots_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    slots_spinbox.grid(row=2, column=1)
    slots_spinbox.delete(0)
    slots_spinbox.insert(0, "5")

    # insert parameter: tasks
    tasks_label = Label(frame, text="#Tasks")
    tasks_label.grid(row=3, column=0)
    tasks_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    tasks_spinbox.grid(row=3, column=1)
    tasks_spinbox.delete(0)
    tasks_spinbox.insert(0, "50")

    # insert parameter: sw_exec_min
    sw_exec_min_label = Label(frame, text="sw exec (min-max)")
    sw_exec_min_label.grid(row=1, column=2)
    sw_exec_min_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    sw_exec_min_spinbox.grid(row=1, column=3)
    sw_exec_min_spinbox.delete(0)
    sw_exec_min_spinbox.insert(0, "30")
    sw_exec_max_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    sw_exec_max_spinbox.grid(row=1, column=4)
    sw_exec_max_spinbox.delete(0)
    sw_exec_max_spinbox.insert(0, "60")

    # insert parameter: hw_exec_min
    hw_exec_min_label = Label(frame, text="hw exec (min-max)")
    hw_exec_min_label.grid(row=2, column=2)
    hw_exec_min_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    hw_exec_min_spinbox.grid(row=2, column=3)
    hw_exec_min_spinbox.delete(0)
    hw_exec_min_spinbox.insert(0, "10")
    hw_exec_max_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    hw_exec_max_spinbox.grid(row=2, column=4)
    hw_exec_max_spinbox.delete(0)
    hw_exec_max_spinbox.insert(0, "30")

    # insert parameter: reconfig_time_min
    reconfig_time_min_label = Label(frame, text="reconfig time (min-max)")
    reconfig_time_min_label.grid(row=3, column=2)
    reconfig_time_min_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    reconfig_time_min_spinbox.grid(row=3, column=3)
    reconfig_time_min_spinbox.delete(0)
    reconfig_time_min_spinbox.insert(0, "60")
    reconfig_time_max_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    reconfig_time_max_spinbox.grid(row=3, column=4)
    reconfig_time_max_spinbox.delete(0)
    reconfig_time_max_spinbox.insert(0, "80")

    # insert parameter: workload_min
    workload_min_label = Label(frame, text="workload (min-max)")
    workload_min_label.grid(row=4, column=2)
    workload_min_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    workload_min_spinbox.grid(row=4, column=3)
    workload_min_spinbox.delete(0)
    workload_min_spinbox.insert(0, "1")
    workload_max_spinbox = Spinbox(frame, from_=0, to=1000000, bg="white")
    workload_max_spinbox.grid(row=4, column=4)
    workload_max_spinbox.delete(0)
    workload_max_spinbox.insert(0, "20")

    def next_algorithm():
        i = 0; index = -1
        for a in schedule:
            if a == algo_spinbox.get():
                index = i
            i += 1
        index += 1
        if len(schedule) <= index:
            index = 0
        algo_spinbox.configure(state=NORMAL)
        algo_spinbox.delete(0, END)
        algo_spinbox.insert(0, schedule[index])
        algo_spinbox.configure(state="readonly")

    # insert parameter: algorithm
    algo_label = Label(frame, text="Algorithm")
    algo_label.grid(row=4, column=0)
    algo_spinbox = Spinbox(frame, bg="white", command=next_algorithm, foreground="black", readonlybackground="white")
    algo_spinbox.grid(row=4, column=1)
    algo_spinbox.delete(0, END)
    algo_spinbox.insert(0, schedule[0])
    algo_spinbox.configure(state="readonly")

    #filename
    file_label = Label(frame, text="File")
    file_label.grid(row=5, column=0)
    file_entry = Entry(frame, bg="white");
    file_entry.insert(0, "task_set")
    file_entry.grid(row=5, column=1)

    # insert button functions
    def create_task_set():
        # 1. create task set
        del tasks[:]
        text.delete(1.0, END)
        for i in range(1,int(tasks_spinbox.get())+1):
            string_color = '#'+str(hex(random.randint(0,13)))[2:]
            string_color += str(hex(random.randint(0,15)))[2:]
            string_color += str(hex(random.randint(0,13)))[2:]
            string_color += str(hex(random.randint(0,15)))[2:]
            string_color += str(hex(random.randint(0,13)))[2:]    
            string_color += str(hex(random.randint(0,15)))[2:]   
            if i < 10:
                thread_name = "Task_0"+str(i)
            else:
                thread_name = "Task_"+str(i)
            workload = random.randint(int(workload_min_spinbox.get()), int(workload_max_spinbox.get()))
            tasks.append(Multithread(
                # sw (worst case) execution time
                random.randint(int(sw_exec_min_spinbox.get()), int(sw_exec_max_spinbox.get())) ,
                # hw (worst case) execution time
                random.randint(int(hw_exec_min_spinbox.get()), int(hw_exec_max_spinbox.get())) ,
                # reconfig time for hw thread
                random.randint(int(reconfig_time_min_spinbox.get()), int(reconfig_time_max_spinbox.get())) ,
                ((0, workload ), ), # workload list (time, workload)
                [],                # resources (sw thread) (time step, resource, number of units, request/release)
                [],                # resources (hw thread) (time step, resource, number of units, request/release)
                [],                # migration points (sw)
                [],                # migration/yielding points (hw)
                1,                 # number of sw threads
                1,                 # number of hw threads
                thread_name,       # name
                '',   # text color for bash
                '',   # text color for blocking/reconfiguring states 
                string_color   # gantt color 
            ))
            string1 = tasks[i-1].name
            string1 += ": sw_exec_time=" + str(tasks[i-1].sw_exec)
            string1 += ", hw_exec_time=" + str(tasks[i-1].hw_exec)
            string1 += ", reconfig_time=" + str(tasks[i-1].reconfig_time)
            string1 += ", workload=" + str(workload)+"\n"
            text.insert(END, string1)

    def do_simulation():
        # 2. run simulation    
        hw_threads = [t for m in tasks for t in m.hw_threads]
        sw_threads = [t for m in tasks for t in m.sw_threads]
        del cpu[:]
        del slots[:]
        for i in range(int(cpu_spinbox.get())):
            cpu.append(Cpu('%d' % i))
        for i in range(int(slots_spinbox.get())):
            slots.append(Slot('S%d' % i))
        icap = [Icap('ICAP')]
        measurement_unit = [Measurement_unit('Measurement Unit', 40)]
        if debug_var.get() == 0:
            debug = "nodebug"
        else:
            debug = "debug"
        runtime = int(time_spinbox.get())
        del effective_runtime[:]
        effective_runtime.append(run_simulation(cpu, hw_threads, sw_threads, tasks, [], slots, [], icap, algo_spinbox.get(), measurement_unit, runtime, debug))
        #effective_runtime.append(run_simulation(cpu, hw_threads, sw_threads, tasks, [], slots, [], icap, schedule[int(algo_spinbox.get())], measurement_unit, runtime, debug))

    def show_schedule():
        # 3. draw gantt diagram
        runtime = 0
        if len(effective_runtime)>0:
            runtime = effective_runtime[0]
        else:
            runtime = time_spinbox.get()
        draw_gantt(tasks=tasks, cpu=cpu, slots=slots, time=runtime)


    def open_file():
        text.delete(1.0, END)
        f=open(file_entry.get()+'.tsk', 'rb')
        tasks2 = pickle.load(f)
        f.close()
        del tasks[:]
        for t in tasks2:
            tasks.append(t)
            string1 = t.name
            string1 += ": sw_exec_time=" + str(t.sw_exec)
            string1 += ", hw_exec_time=" + str(t.hw_exec)
            string1 += ", reconfig_time=" + str(t.reconfig_time)
            string1 += ", workload=" + str(t.workloads[0][1])+"\n"
            text.insert(END, string1)

    def save_file():
        f=open(file_entry.get()+'.tsk', 'wb')
        pickle.dump(tasks, f, 0) # pickle.HIGHEST_PROTOCOL)
        f.close()

    # buttons
    button_load = Button(frame, text="i) Load Tasks", command=open_file)
    button_load.pack(fill=BOTH, expand=1)
    button_load.grid(row=5, column=2, sticky=N+S+E+W)

    button_save = Button(frame, text="ii) Save Tasks", command=save_file)
    button_save.pack(fill=BOTH, expand=1)
    button_save.grid(row=5, column=3, sticky=N+S+E+W)

    button_taskset = Button(frame, text="1) Create Task Set", command=create_task_set)
    button_taskset.pack(fill=BOTH, expand=1)
    button_taskset.grid(row=6, column=2, sticky=N+S+E+W)

    button_taskset = Button(frame, text="2) Run Simulation", command=do_simulation)
    button_taskset.pack(fill=BOTH, expand=1)
    button_taskset.grid(row=6, column=3, sticky=N+S+E+W)

    button_schedule = Button(frame, text="3) Show Schedule", command=show_schedule)
    button_schedule.pack(fill=BOTH, expand=1)
    button_schedule.grid(row=6, column=4, sticky=N+S+E+W)

    # text field
    scrollbar = Scrollbar(frame)
    scrollbar.grid(row=0, column=5, sticky=N+S)
    text = Text(frame, width=100, height=200, wrap=WORD, yscrollcommand=scrollbar.set, bg="white")
    text.grid(row=0, column=0, columnspan=5 )
    scrollbar.config(command=text.yview)
    
    # start loop
    frame.pack()
    mainloop()

