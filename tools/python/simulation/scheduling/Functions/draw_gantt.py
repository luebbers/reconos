#!/usr/bin/env python
"""\file draws_gantt.py

creates gantt diagram into GUI

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
# 10.09.2009   Markus Happe   File created.

import operator
from tkinter import *

font  = 'times 12 normal'
font1 = 'times 8 normal'
font2 = 'times 12 bold'
font3 = 'times 10 bold'
font4 = 'times 10 bold'
width1 = 25


def draw_schedule(canvas1, cpu, slots, time, offset=0):
    for i in range(0,time):
        canvas1.create_text((i*width1)+37+offset, 15, text=str(i), fill="black", font=font1)
        j = 0
        for c in cpu:
            if i<=len(c.schedule) and c.schedule[i] != '---':
                canvas1.create_rectangle((i*width1)+25+offset,25+(j*60),((i+1)*width1)+25+offset,75+(j*60),fill=c.schedule[i])
            else:
                canvas1.create_rectangle((i*width1)+25+offset, 25+(j*60), ((i+1)*width1)+25+offset, 75+(j*60), fill="white")
            if i<=len(c.work_package):
                canvas1.create_text((i*width1)+37+offset, 40+(j*60), text=c.work_package[i], fill="white", font=font2)
            if i<=len(c.schedule_task):
                canvas1.create_text((i*width1)+37+offset, 60+(j*60), text=c.schedule_task[i], fill="white", font=font3)
            j += 1
        for s in slots:
            if i<=len(s.schedule) and s.schedule[i] != '---' and s.schedule[i] != 'reconfig':
                canvas1.create_rectangle((i*width1)+25+offset,25+(j*60),((i+1)*width1)+25+offset,75+(j*60),fill=s.schedule[i])
            elif i<=len(s.schedule) and s.schedule[i] == 'reconfig':
                canvas1.create_rectangle((i*width1)+25+offset, 25+(j*60), ((i+1)*width1)+25+offset, 75+(j*60), fill="black")
            else:
                canvas1.create_rectangle((i*width1)+25+offset, 25+(j*60), ((i+1)*width1)+25+offset, 75+(j*60), fill="white")
            if i<=len(s.work_package):
                canvas1.create_text((i*width1)+37+offset, 40+(j*60), text=s.work_package[i], fill="white", font=font2)
            if i<=len(s.schedule_task):
                canvas1.create_text((i*width1)+37+offset, 60+(j*60), text=s.schedule_task[i], fill="white", font=font3)
            j += 1


def draw_diagram_key(canvas_key, tasks, offset=0):
    # sort tasks by name
    tasks[:] = sorted(tasks, key=operator.attrgetter('name'),reverse=False)
    i = 0
    for t in tasks:
        canvas_key.create_rectangle((i*70)+25, 25+offset, ((i+1)*70)+25, 75+offset, fill=t.gantt_color)
        canvas_key.create_text((i*70)+60, 90+offset, text=t.name, fill="black", font=font)
        canvas_key.create_text((i*70)+60, 15+offset, text="["+str(t.workload)+"]", fill="black", font=font3)
        canvas_key.create_text((i*70)+60, 35+offset, text="sw: "+str(t.sw_exec), fill="white", font=font4)
        canvas_key.create_text((i*70)+60, 50+offset, text="hw: "+str(t.hw_exec), fill="white", font=font4)
        canvas_key.create_text((i*70)+55, 65+offset, text="reconf: "+str(t.reconfig_time), fill="white", font=font4)
        i += 1

def draw_diagram_legend(canvas_left, cpu, slots, time):
    j = 0
    for c in cpu:
        util = (100*c.used_timeslots)/time
        util = int(util)
        canvas_left.create_text(30, 40+(j*60), text="CPU "+c.name, fill="black", font=font2)
        canvas_left.create_text(30, 60+(j*60), text="("+str(util)+"%)", fill="black", font=font1)
        j+=1
    for s in slots:
        util = (100*s.used_timeslots)/time
        util = int(util)
        canvas_left.create_text(30, 40+(j*60), text="Slot "+s.name, fill="black", font=font2)
        canvas_left.create_text(30, 60+(j*60), text="("+str(util)+"%)", fill="black", font=font1)
        j+=1


def draw_gantt(tasks=[], cpu=[], slots=[], time=0):

    # window
    root = Tk()
    root.title('AG Platzner Task Allocation and Scheduling Simulator: Gantt Diagram')
    height1 = (len(slots)+len(cpu))*60+230
    if height1 > 945:
        height1 = 945
    root.geometry("%dx%d%+d%+d" % (1270, height1, 0, 0))

    # frame
    frame = Frame(root, bd=2, relief=SUNKEN)
    frame.grid_rowconfigure(0, weight=1)
    frame.grid_columnconfigure(0, weight=1)

    # canvas for environments (cpu, slots)
    yscrollbar_left = Scrollbar(frame)
    yscrollbar_left.grid(row=0, column=1, sticky=N+S)
    canvas_left = Canvas(frame, bd=0, width=100, height=height1-125, scrollregion=(0, 0, 70, (len(slots)+len(cpu))*60+30),
                yscrollcommand=yscrollbar_left.set)
    canvas_left.grid(row=0, column=0, sticky=N+S+E+W)
    yscrollbar_left.config(command=canvas_left.yview)

    # canvas for schedule
    xscrollbar = Scrollbar(frame, orient=HORIZONTAL)
    xscrollbar.grid(row=1, column=2, sticky=E+W)
    yscrollbar = Scrollbar(frame)
    yscrollbar.grid(row=0, column=3, sticky=N+S)
    canvas = Canvas(frame,bd=0,width=1170,height=height1-125,scrollregion=(0,0,(width1*time)+50,(len(slots)+len(cpu))*60+30),
                xscrollcommand=xscrollbar.set, yscrollcommand=yscrollbar.set, bg="white")
    canvas.grid(row=0, column=2, sticky=N+S+E+W)
    xscrollbar.config(command=canvas.xview)
    yscrollbar.config(command=canvas.yview)
    frame.pack(fill=X)

    # canvas for diagram key (tasks)
    xscrollbar_key = Scrollbar(frame, orient=HORIZONTAL)
    xscrollbar_key.grid(row=5, column=2, sticky=E+W)
    canvas_key = Canvas(frame, bd=0, width=1170, height=100 ,scrollregion=(0, 0, (70*len(tasks))+50, 800),
                xscrollcommand=xscrollbar_key.set) #, bg="white")
    xscrollbar_key.config(command=canvas_key.xview)
    canvas_key.grid(row=2, column=2, rowspan=3, sticky=N+S+E+W)

    # draw diagram
    # a) legend left
    draw_diagram_legend(canvas_left, cpu, slots, time)

    # b) draw schedule
    draw_schedule(canvas, cpu, slots, time)

    # c) draw diagram key
    draw_diagram_key(canvas_key, tasks)

    # d) save part of schedule to postscript file
    def save_schedule():
        root2 = Tk()
        width = (width1*time)+50
        height =(len(slots)+len(cpu))*60+200
        root2.title("save")
        root2.geometry("%dx%d%+d%+d" % (width, height, 0, 0))
        frame2 = Frame(root2, bd=2, bg="white", relief=SUNKEN)
        frame2.grid_rowconfigure(0, weight=1)
        frame2.grid_columnconfigure(0, weight=1)
        canvas_save = Canvas(frame2, bd=0, width=width, height=height, bg="white") 
        canvas_save.grid(row=0, column=0, sticky=N+S+E+W)
        frame2.pack(fill=X)
        draw_diagram_legend(canvas_save, cpu, slots, time)
        draw_diagram_key(canvas_save, tasks, offset=height-150)
        draw_schedule(canvas_save, cpu, slots, time, offset=50)
        canvas_save.update()
        canvas_save.postscript(file='gantt.ps',colormode='color')
        root2.destroy()

    def scale():
        canvas.scale( ALL, 0.0, 0.0, float(scale_spinbox.get()), float(scale_spinbox.get()))
        canvas.update()

    b = Button(frame, text="Save", command=save_schedule)
    b.pack()
    b.grid(row=2, column=0)
    scale_spinbox = Spinbox(frame, from_=0.1, to=100.0, increment=0.1, bg="white")
    scale_spinbox.grid(row=3, column=0)
    scale_spinbox.delete(0)
    scale_spinbox.insert(0, "1") 
    scale_spinbox.delete(2)
    scale_spinbox.insert(2, "0") 
    b2 = Button(frame, text="Scale", command=scale)
    b2.pack()
    b2.grid(row=4, column=0)
    #b.grid(row=4, column=2, sticky=N+S+E+W)

    # e) start loop
    mainloop()


