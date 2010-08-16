#!/usr/bin/env python
"""\file icap.py

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

# reconfigures a slot with a hw thread. It can only reconfigure 1 slot at a time
class Icap:
    def __init__(self, name='unnamed'):
        self.name = name

    # states: 'idle', 'reconfiguring' 
    state = 'idle'
    current_thread = None
    threads = []
    slot = None




