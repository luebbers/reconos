#!/bin/bash
#
# \file dlusbfw.sh
#
# Downloads firmware to Xilinx Platform USB cable
#
# \author Enno Luebbers <luebbers@reconos.de>
# \date   26.08.2010
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
XILINX_USBID_MAJOR="03fd"
DESIRED_USBID_MINOR="0008"
FW_FILE="$XILINX/bin/lin/xusbdfwu.hex"
USBFS="/dev/bus/usb"

function lookup {
    # look up USB ID
    LSUSB_LINE=`lsusb | grep "$XILINX_USBID_MAJOR:.*Xilinx, Inc."`
    BUS=`echo $LSUSB_LINE | sed "s/^Bus \([0-9]\{3\}\).*$/\1/"`
    DEVICE=`echo $LSUSB_LINE | sed "s/^.*Device \([0-9]\{3\}\).*$/\1/"`
    USBID_MAJOR=`echo $LSUSB_LINE | sed "s/^.*\([0-9a-fA-F]\{4\}\):\([0-9a-fA-F]\{4\}\).*$/\1/"`
    USBID_MINOR=`echo $LSUSB_LINE | sed "s/^.*\([0-9a-fA-F]\{4\}\):\([0-9a-fA-F]\{4\}\).*$/\2/"`
}

lookup

# check for correct major ID
if [ "$USBID_MAJOR" != "$XILINX_USBID_MAJOR" ]; then
    echo "ERROR: no Platform USB cable found!"
    exit 1
fi

# check wether minor ID already matches correct firmware
if [ "$USBID_MINOR" = "$DESIRED_USBID_MINOR" ]; then
    echo "Nothing to be done; firmware already up-to-date!"
    exit 0
fi

# check for fxload
FXLOAD=`type -p fxload`
if [ $? -ne 0 ]; then
    echo "ERROR: fxload not installed!"
    exit 1
fi

# check for firmware file
if [ ! -f $FW_FILE ]; then
    echo "ERROR: firmware file not found ('$FW_FILE')!"
    exit 1
fi

# check for character node in USB filesystem tree
if [ ! -c $USBFS/$BUS/$DEVICE ]; then
    echo "ERROR: no node matching $BUS:$DEVICE found in $USBFS!"
    exit 1
fi

# download firmware
echo "Downloading firmware to bus: $BUS, device: $DEVICE (current USBID: $USBID_MAJOR:$USBID_MINOR)"
$FXLOAD -v -t fx2 -I $FW_FILE -D $USBFS/$BUS/$DEVICE

sleep 3

# check for success
lookup
if [ "$USBID_MINOR" != "$DESIRED_USBID_MINOR" ]; then
    echo "ERROR: fw download failed (USB ID still $USBID_MAJOR:$USBID_MINOR)"
    exit 1
fi

echo "Firmware download successful (current USBID: $USBID_MAJOR:$USBID_MINOR)"

exit 0
