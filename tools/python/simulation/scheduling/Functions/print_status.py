#!/usr/bin/env python
"""\file print_status.py

prints schedule for current time step

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
from sw_thread import *
from hw_thread import *
from migrate_thread import *
from slot import *
from cpu import *

def print_status(cpu, hw_threads, sw_threads, migrate_threads, slots, time):

    n = len(slots)+len(cpu)
    w = 140 / n

    output = []
    # print current time step
    output.append("%5d   " % (time))

    # print current sw thread in cpu
    for c in cpu:
        if c.sw_thread and c.sw_thread.state != 'migrated':
            ## check, if current thread is yielding
            migration_occurs = ' '
            for m in c.sw_thread.migration_points:
                if m == c.sw_thread.time_this or m == c.sw_thread.time_this+1:
                    migration_occurs = '*'
            workload = workload_this = 0
            if c.sw_thread.multithread:
                workload = c.sw_thread.multithread.workload
                workload_this = c.sw_thread.workload_this
            output.append('%s  Thread %s %-8s%s[%2d/%2d|%2d/%2d]\033[m' % (c.sw_thread.color, c.sw_thread.name, c.sw_thread.state, migration_occurs, c.sw_thread.time_this, c.sw_thread.exec_time, workload_this, workload))
            #for r in c.sw_thread.current_resources:
            #    output.append(r.name)
            #if c.sw_thread.current_resources:
            #    output.append(c.sw_thread.current_resources[0].name)
                #output.append('%s%s\033[m' % (c.sw_thread.color, r.name))
            #print (('%-' + str(w+10) + 's') % (' '.join(output)))
            print (*output, sep=' ', end='')
        else:
            #output.append('\033[35m---\033[m')
            output.append('---')
            #print (('%-' + str(w-1) + 's') % (' '.join(output)))
            print (*output, sep=' ', end='')

    # print current hw thread in slot
    for s in slots:
        output = []
        if s.hw_thread:
            ## check, if current thread is yielding
            yield_occurs = ' '
            for y in s.hw_thread.yieldings:
                if y == s.hw_thread.time_this or y == s.hw_thread.time_this+1:
                    yield_occurs = '*'
            workload = workload_this = 0
            if s.hw_thread.multithread:
                workload = s.hw_thread.multithread.workload
                workload_this = s.hw_thread.workload_this
            ## print out for reconfiguration
            if s.state == 'reconfig':
                output.append('%sThread %s %-9s[%2d/%2d|%2d/%2d]\033[m' % (s.hw_thread.color_blocked, s.hw_thread.name, s.hw_thread.state, s.hw_thread.reconfig_time_this, s.hw_thread.reconfig_time, workload_this, workload))
            ## last reconfiguration step (hacked)
            elif s.hw_thread.state == 'reconfigured':
                output.append('%sThread %s %-8s%s[%2d/%2d|%2d/%2d]\033[m' % (s.hw_thread.color_blocked, s.hw_thread.name, 'reconfig', yield_occurs, s.hw_thread.reconfig_time, s.hw_thread.reconfig_time, workload_this, workload))
            ## do not print thread info, if it waits for the icap controller, it is blocked or its instance terminated
            elif s.hw_thread.state == 'blocking':
                output.append('%sThread %s %-8s%s[%2d/%2d|%2d/%2d]\033[m' % (s.hw_thread.color_blocked, s.hw_thread.name, s.hw_thread.state, yield_occurs, s.hw_thread.time_this+1, s.hw_thread.exec_time, workload_this, workload))
                # print owned by thread ressources
                #for r in s.hw_thread.current_resources:
                #    output.append(r.name)
                #if s.hw_thread.current_resources:
                #    output.append(s.hw_thread.current_resources[0].name)
            elif s.hw_thread.state != 'wait for icap' and s.hw_thread.state != 'terminated': # and s.hw_thread.state != 'blocking':
                output.append('%sThread %s %-8s%s[%2d/%2d|%2d/%2d]\033[m' % (s.hw_thread.color, s.hw_thread.name, s.hw_thread.state, yield_occurs, s.hw_thread.time_this, s.hw_thread.exec_time, workload_this, workload))
                # print owned by thread ressources
                #for r in s.hw_thread.current_resources:
                #    output.append(r.name)
                #if s.hw_thread.current_resources:
                #    output.append(s.hw_thread.current_resources[0].name)
            ## do not print thread info, if it waits for the icap controller, it is blocked or its instance terminated
            if s.hw_thread.state == 'wait for icap':
                output.append('vvv')
                #print (('%-' + str(w-3) + 's') % (' '.join(output)))
                print (*output, sep=' ', end='')
            #elif s.hw_thread.state == 'blocking':
            #    output.append('>-<')
            #    print ('%-' + str(w-3) + 's') % (' '.join(output)),
            elif s.hw_thread.state == 'terminated':
                output.append('xxx')
                #print (('%-' + str(w-3) + 's') % (' '.join(output)))
                print (*output, sep=' ', end='')
            elif s.hw_thread.state == 'blocking' or s.state == 'reconfig' or s.hw_thread.state == 'reconfigured':
                #print (('%-' + str(w+10) + 's') % (' '.join(output)))
                print (*output, sep=' ', end='')
            else:
                #print (('%-' + str(w+8) + 's') % (' '.join(output)))
                print (*output, sep=' ', end='')
        else:
            output.append('---')
            #print (('%-' + str(w-3) + 's') % (' '.join(output)))
            print (*output, sep=' ', end='')
    print ('')
#    print '\t\t',
#    for t in threads:
#        print 'Thread %s  %-8s[%3d]  ' % (t.name, t.state, t.time_this), 
#
#    print ''



def print_table_header(cpu, slots):

    # print table head (time step table)
    output = []
    n = len(slots)+len(cpu)
    w = 140 / n
    output.append('\33[1;37m\033[40m time             CPU     ')
    counter = 1
    for s in slots:
        for i in range(6-len(slots)):
            output.append('       ')
        output.append('Slot ')
        output.append(str(counter))
        counter = counter + 1
    output.append('       ')
    #print ('%-' + str(w) + 's') % (' '.join(output)),
    print (*output, sep=' ', end='')
    print ('\33[m\033\n')



