#!/bin/bash
#
# \file update_copyright.sh
#
# Updates the copyright header in the specified file
#
# Replaces the text between the RECONOS_COPYRIGHT_BEGIN and _END tokens
# (which are surrounded by three '%' characters, each) with the current
# ReconOS copyright message, as given in
# $RECONOS/doc/templates/copyrightheader.
#
# \author Enno Luebbers <luebbers@reconos.de>
# \date   06.08.2010
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# 
# This file is part of ReconOS (http://www.reconos.de).
# Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
# All rights reserved.
# 
# ReconOS is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
# 
# ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along
# with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
# 
# %%%RECONOS_COPYRIGHT_END%%%
#---------------------------------------------------------------------------
#

#!/bin/sh
#
# update_copyright.sh: 
#

COPYRIGHTHEADER="$RECONOS/doc/templates/copyrightheader"

if [ $# -ne 1 ]; then
    echo "USAGE: update_copyright.sh <file_to_update>"
    exit 1
fi

if [ ! -f $1 ]; then
    echo "$1 does not exist"
    exit 1
fi

# make backup
cp "$1" "$1~"

repltok.py -i "$COPYRIGHTHEADER" -t %%%YEAR%%% -r `date +%Y` | repltok.py -i "$1" -o "$1" -s %%%RECONOS_COPYRIGHT_BEGIN%%% -e %%%RECONOS_COPYRIGHT_END%%% -k

