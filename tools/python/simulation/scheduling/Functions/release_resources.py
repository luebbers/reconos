#!/usr/bin/env python
"""\file release_resources.py

releases all resources not needed anymore by sw and hw threads

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
from slot import *
from sw_thread import *
from hw_thread import *
from migrate_thread import *
from reconos_resource import *

def release_resources(hw_threads, sw_threads, migrate_threads):

    # i) hw threads (release resources)
    for t in hw_threads:
        if t.state == 'running' or t.state == 'blocking':
             for time, resource, number, action in t.resources:
                if t.time_this == time and action == 'release':
                    # release
                    assert t.state == 'running'
                    if resource in t.current_resources:
                        t.current_resources.remove(resource)
                    resource.number = resource.number + number
                    #print 'Thread', t.name,'releases Resource', resource.name, ' = ', str(resource.number)

    # ii) sw threads (release resources)
    for t in sw_threads:
        if t.state == 'running' or t.state == 'blocking':
            for time, resource, number, action in t.resources:
                if t.time_this == time and action == 'release':
                    # release
                    #assert t.state == 'running'
                    if resource in t.current_resources:
                        t.current_resources.remove(resource)
                    resource.number = resource.number + number
                    #print 'Thread', t.name,'releases Resource', resource.name, ' = ', str(resource.number)


    # iii) migrate threads (release resources)
    for m in migrate_threads:
        t = m.sw_thread
        if t.state == 'running' or t.state == 'blocking':
            for time, resource, number, action in t.resources:
                if t.time_this == time and action == 'release':
                    # release
                    assert t.state == 'running'
                    if resource in t.current_resources:
                        t.current_resources.remove(resource)
                    resource.number = resource.number + number
                    #print 'Thread', t.name,'releases Resource', resource.name, ' = ', str(resource.number)
        t = m.hw_thread
        if t.state == 'running' or t.state == 'blocking':
            for time, resource, number, action in t.resources:
                if t.time_this == time and action == 'release':
                    # release
                    assert t.state == 'running'
                    if resource in t.current_resources:
                        t.current_resources.remove(resource)
                    resource.number = resource.number + number
                    #print 'Thread', t.name,'releases Resource', resource.name, ' = ', str(resource.number)
