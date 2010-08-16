#!/bin/bash
#
# \file build_header.sh
#
# Constructs file headers from templates
#
# This script takes a filename for which it prints a header. It uses the
# filename's extension to determine which template from $RECONOS/doc/templates
# to use (the template's filename is template.EXT, where EXT is the extension
# of the given filename).
# The individual templates usually contain one or more of the following
# placeholder tokens, each starting and ending withthree '%' characters,
# such as %%%TOKEN%%%
#
#   SHORT_DESCRIPTION        Short file description. Can be supplied as
#                            second argument.
#   LONG_DESCRIPTION         Longer description.
#   REALNAME                 Name of author (e.g. Enno Luebbers).
#   EMAIL                    E-mail address of author.
#                            If possible, these are generated from the
#                            local machine's git configuration.
#   DATE                     Will be replaced with the current date.
#   RECONOS_COPYRIGHT_BEGIN
#   RECONOS_COPYRIGHT_END    Start and end the ReconOS copyright message.
#                            Will be replaced with the contents of
#                            $RECONOS/doc/templates/copyrightheader
#   YEAR                     Will be replaced with the current year.
#
# Have a look at the templates in $RECONOS/doc/templates.
#
# You can use this script conveniently from within vi by issuing:
#
#   :r ! $RECONOS/tools/doc/build_header.sh %
#
# on an already open file. This will insert the appropriate header at the
# cursor position.
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

# TODO: common shell functions for checking valid environment

# set command locations
REPLTOK=$RECONOS/tools/python/repltok.py

print_usage()
{
    echo "`basename $0`: Assembles file header from template"
    echo "USAGE: `basename $0` <filename> [short description]"
    exit 1
}


# parse arguments
FILENAME=$1
if [ -z $FILENAME ]; then print_usage; fi

EXTENSION=`echo $FILENAME | sed "s/.*\.//"`
TEMPLATE=$RECONOS/doc/templates/template.$EXTENSION
if [ ! -f $TEMPLATE ]; then 
    echo "No template for '.$EXTENSION'"
    exit 1
fi

SHORT_DESCRIPTION=$2
# <+...+> are more easily editable by vi (CTRL+J)
if [ -z $SHORT_DESCRIPTION ]; then SHORT_DESCRIPTION="<+SHORT_DESCRIPTION+>"; fi
LONG_DESCRIPTION="<+LONG_DESCRIPTION+>"

# take author name and email from git, if applicable
type -P git &>/dev/null
if [ $? -eq 0 ]; then
    REALNAME=`git config --get user.name`
    EMAIL=`git config --get user.email`
else
    REALNAME="<+REALNAME+>"
    EMAIL="<+EMAIL+>"
fi

DATE=`date +%d.%m.%Y`
YEAR=`date +%Y`
COPYRIGHT=$RECONOS/doc/templates/copyrightheader

cat $TEMPLATE |\
    $REPLTOK -s %%%RECONOS_COPYRIGHT_BEGIN%%% -e %%%RECONOS_COPYRIGHT_END%%% -f $COPYRIGHT -k |\
    sed "\
s/%%%FILENAME%%%/$FILENAME/;\
s/%%%SHORT_DESCRIPTION%%%/$SHORT_DESCRIPTION/;\
s/%%%LONG_DESCRIPTION%%%/$LONG_DESCRIPTION/;\
s/%%%REALNAME%%%/$REALNAME/;\
s/%%%EMAIL%%%/$EMAIL/;\
s/%%%DATE%%%/$DATE/;\
s/%%%YEAR%%%/$YEAR/"


