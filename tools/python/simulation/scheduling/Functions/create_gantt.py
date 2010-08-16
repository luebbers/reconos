#!/usr/bin/env python
"""\file create_gantt.py

creates gantt diagram in html form

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
# adapted from Mechanical Cat: Python Task Planner (v.1.3.3)
# Copyright (c) 2004 Richard Jones (richard at mechanicalcat)
#
#---------------------------------------------------------------------------
#
# Major Changes:
#
# 09.09.2009   Markus Happe   File created.

import sys, operator
sys.path.append("../Components")
from slot import *
from cpu import *
from multithread import *

def empty_line(file1, time, span=3):
            ###############################################################################################
            # middle line
            ###############################################################################################
            print ('<tr><th nowrap></th>', file=file1)
            for time_step in range(1, time+1):
                style = time_step%2 and 'normal' or 'alt'
                print ('<td class="%s" colspan="%d">%s</td>'%(style, span, ' '), file=file1)
                #print >>file1, '<td class="%s" colspan="%d">&nbsp;</td>'%(style, span)
            print ('</tr>', file=file1)


#class Gantt_Diagram:
def export_gantt(file1=sys.stdout, tasks=None, cpu=None, slots=None, time=0):
        styles = []
        style_key = []
        span = 4
        ###############################################################################################
        # print key of gantt diagramm
        ###############################################################################################
        style_key.append('<br><br>');
        width = 200
        style_key.append('<b>Gantt diagram key:</b></tr><tr>')
        #sort tasks
        tasks[:] = sorted(tasks, key=operator.attrgetter('name'),reverse=False)
        for t in tasks:
            safe = t.name
            color = t.gantt_color
            styles.append('td.%s {background-color: %s}'%(safe, color))
            style_key.append('<td width="%s" class="%s">%s</td>'%(width, safe, t.name))

        #style_key.append('</tr><tr>')
        #for t in tasks:
        #    safe = t.name
        #    blocked_color = t.gantt_color_blocked
        #    styles.append('td.%s {background-color: %s}'%(safe+"_blocked", blocked_color))
        #    style_key.append('<td width="%s" class="%s">%s (blocked)</td>'%(width, safe+"_blocked", t.name))

        style_key.append('</tr><tr>')

        styles.append('td.%s {background-color: %s}'%("reconfig", "black"))
        style_key.append('<td width="%s" class="%s">%s</td>'%(width, "reconfig", "Reconfiguration"))

        ###############################################################################################
        # print html
        ###############################################################################################
        print ('''

        <html>
        <style>
        table {border-collapse: collapse; padding:0}

        tr {border: 0; padding:0}

        th {text-align: right; border: 0; padding:1; margin:0}
        th.normal {background-color: #ddd}
        th.alt {background-color: #bbb}

        td {color: white; border-bottom: thin solid white; padding:1; margin:0}
        td.normal {background-color: #ddd}
        td.alt {background-color: #bbb}
        td.reconfig {background-color: #000}
        %s
        </style>
        '''%'\n'.join(styles), file=file1)
        print ('<table>', file=file1)
        print ('<tr><th>Environment</th>', file=file1)

        ###############################################################################################
        # print gantt diagram header
        ###############################################################################################
        for time_step in range(1, time+1):
            style = time_step%2 and 'normal' or 'alt'
            if time_step < 10:
                time_step_string = "000" + str(time_step)
            elif time_step < 100:
                time_step_string = "00" + str(time_step)
            elif time_step < 1000:
                time_step_string = "0" + str(time_step)
            else:
                time_step_string = str(time_step)
            print ('<th class="%s" colspan="%s">%s</th>'%(style, span, time_step_string), file=file1)
        print ('''</tr>''', file=file1)

        ###############################################################################################
        # print gantt diagram for cpu
        ###############################################################################################
        for c in cpu:
            empty_line(file1, time, span)

            print ('<tr><th nowrap>%s</th>'%c.name, file=file1)
            for time_step in range(1, time+1):
                style = time_step%2 and 'normal' or 'alt'
                if time_step <= len(c.schedule):
                    if c.schedule[time_step-1] != "---":
                        style = c.schedule[time_step-1]
                print ('<td class="%s" align="center" colspan="%d">%s</td>'%(style, span, c.work_package[time_step-1]), file=file1) #'')
            print ('<td class="%s" align="center" colspan="%d">&nbsp;</td>'%(style, span), file=file1)
            print ('</tr>', file=file1)

        ###############################################################################################
        # print gantt diagram for slots
        ###############################################################################################
        for s in slots:
            empty_line(file1, time, span)

            print ('<tr><th nowrap>Slot %s</th>'%s.name, file=file1)
            for time_step in range(1, time+1):
                style = time_step%2 and 'normal' or 'alt'
                if time_step <= len(s.schedule):
                    if s.schedule[time_step-1] != "---":
                        style = s.schedule[time_step-1]
                print ('<td class="%s" align="center" colspan="%d">%s</td>'%(style, span, s.work_package[time_step-1]), file=file1) #'')
            print ('<td class="%s" align="center" colspan="%d">&nbsp;</td>'%(style, span), file=file1)
            print ('</tr>', file=file1)

        empty_line(file1, time, span)

        ###############################################################################################
        # print diagram key width="90%%"
        ###############################################################################################
        print ('''
        </table>
        <table>
        <tr>
        %s
        </tr>
        </table>
        </html>
        '''%'\n'.join(style_key), file=file1)

