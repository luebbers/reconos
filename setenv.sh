#!/bin/bash
#
# \file setenv.sh
#
# Sets up necessary environment variable for ReconOS
#
# The respective environment variables are:
#
#   * RECONOS         -- the top-level directory of the ReconOS repository
#   * RECONOS_VER     -- current version to use (format: vX_YY_Z)
#   * ECOS_REPOSITORY -- points to the 'packages' dir of patched eCos
#   * ECOS_EXTRA      -- used by eCos as additional include dir
#   * EDK_LIB         -- precompiled EDK simulation models
#   * ISE_LIB         -- precompiled ISE simulation models
#   * MODELSIM        -- modelsim.ini with ReconOS references
#   * PATH            -- ReconOS tools directory
#   * PYTHONPATH      -- Path to ReconOS python script library
#
# This script needs to be sourced to take effect:
#
#   . <path_to_reconos>/setenv.sh [-v]
#
# When "-v" is specified, the current ReconOS environment is printed.
#
# \author Enno Luebbers <luebbers@reconos.de>
# \date   11.08.2010
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

# check whether we've been sourced correctly
if [ "$0" != "-bash" ] && [ `basename $0` = "setenv.sh" ]; then
    echo "You need to source 'setenv.sh', not execute it."
    echo "Try:"
    echo "    . <path_to_reconos>/setenv.sh"
    exit 1
fi

# check whether environment has already been set
if [ -n "$RECONOS" ]; then
    echo -n "RECONOS environment already set. Continue [y|N]? "
    read RETVAL
    if [ "$RETVAL" != 'y' ]; then
        return 
    fi
fi

# get directory this script is residing in
# found on http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-in
SCRIPT_PATH="${BASH_SOURCE[0]}";
if([ -h "${SCRIPT_PATH}" ]) then
  while([ -h "${SCRIPT_PATH}" ]) do SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
fi
pushd . > /dev/null
cd `dirname ${SCRIPT_PATH}` > /dev/null
SCRIPT_PATH=`pwd`;
popd  > /dev/null

# set variables to default values
RECONOS="$SCRIPT_PATH"
if [ ! -f "$RECONOS/current_version" ]; then
    echo "'current_version' not found. Your ReconOS install seems broken.'"
    return
fi
read RECONOS_VER < "$RECONOS/current_version"
ECOS_REPOSITORY="$RECONOS/core/ecos/ecos-patched/ecos/packages"
ECOS_EXTRA="$RECONOS/core/ecos/include"
MODELSIM="$RECONOS/support/modelsim.ini"

# only add path if not already present
PATH_TO_ADD="$RECONOS/tools:$RECONOS/tools/python"
if echo $PATH | grep -v "$PATH_TO_ADD" > /dev/null; then
    PATH="$PATH_TO_ADD:$PATH"
else
    PATH="$PATH"
fi

# check if EDK and ISE libs exist
# TODO
EDK_LIB="/Xilinx/EDK_Lib"
ISE_LIB="/Xilinx/ISE_Lib"

# add ReconOS python scripts to PYTHONPATH
PYTHONPATH="$RECONOS/tools/python:$PYTHONPATH"

export RECONOS RECONOS_VER ECOS_REPOSITORY ECOS_EXTRA MODELSIM PATH EDK_LIB ISE_LIB PYTHONPATH

# print environment, if requested
if [ "$1" = '-v' ]; then
    echo "    RECONOS:         '$RECONOS'"
    echo "    RECONOS_VER:     '$RECONOS_VER'"
    echo "    ECOS_REPOSITORY: '$ECOS_REPOSITORY'"
    echo "    ECOS_EXTRA:      '$ECOS_EXTRA'"
    echo "    MODELSIM:        '$MODELSIM'"
    echo "    PATH:            '$PATH'"
    echo "    EDK_LIB:         '$EDK_LIB'"
    echo "    ISE_LIB:         '$ISE_LIB'"
    echo "    PYTHONPATH:      '$PYTHONPATH'"
fi

