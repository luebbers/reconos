#!/usr/bin/env python
"""\file measurement_unit.py

measurement unit keeps track of cpu and slot utilizations

\author     Markus Happe   <markus.happe@upb.de>
\date       17.08.2009
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


class Measurement_unit:
    def __init__(self, name='unnamed', period=300):
        self.name = name
        self.period = period
        self.time_this = 0





