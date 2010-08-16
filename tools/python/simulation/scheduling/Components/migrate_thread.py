#!/usr/bin/env python
"""\file migrate_thread.py

migrate thread class

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


from slot import *
from cpu import *
from sw_thread import *
from hw_thread import *
from slot import *
from reconos_resource import *

class Migrate_Thread:
    def __init__(self, priority, period, hw_exec, hw_res, hw_migrations, sw_exec, sw_res, sw_migrations, name='unnamed', sw_color='\033[34m', hw_color='\033[34m', hw_color_blocked='\033[33m', reconfig_time=4, context_save_time=2, context_load_time=2):

        self.hw_thread = HW_Thread(priority,
            period,
            hw_exec,
            hw_res,
            hw_migrations,
            name,
            hw_color,
            hw_color_blocked,
            reconfig_time,
            context_save_time,
            context_load_time)

        self.sw_thread = SW_Thread(priority,
            period,
            sw_exec,
            sw_res,
            sw_migrations,
            name,
            sw_color)

        self.priority = priority
        self.period = period       # absoult deadline
        self.deadline = period       # absoult deadline
        self.migration = 'hw'
        #self.state = 'terminated'




