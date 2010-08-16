#!/usr/bin/env python
"""\file update_workload.py

update workload

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
# 13.08.2009   Markus Happe   File created.

import sys
sys.path.append("../Components")
from slot import *
from multithread import *
from sw_thread import *
from hw_thread import *

def update_workload(multithreads, time):

    for m in multithreads:
        for workload in m.workloads: 
            if (time == workload[0] == 0) or (time > 0 and time+1 == workload[0]):
                # workload needs to be increase
                m.workload += workload[1]


