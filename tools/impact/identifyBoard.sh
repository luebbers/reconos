#!/bin/bash
#
# identifyBoard.sh: Tries to identify an FPGA board on a PlatformUSB cable.
# Can detect an XUP or an ML403 board.
#
# Checks for a Xilinx Virtex-II Pro xc2vp30 (XUP) or Virtex-4FX12 (ML403). 
# We don't have any other boards with these devices, so that's good enough.
#

# select device to look for (XUP is default)
if [ "$RECONOS_BOARD" == "ml403" ]; then
    DEVICE="xc4vfx12"
else
    DEVICE="xc2vp30"
fi

# see what device is connected
RESULT=`echo "
setMode -bs
setCable -port auto
Identify
quit
" | impact -batch`

# test for our device
echo $RESULT | grep "Xilinx $DEVICE" > /dev/null

if [ "$?" -eq 0 ]; then
    echo "Found $DEVICE, assuming $RECONOS_BOARD is present."
    exit 0
else
    echo "No $DEVICE found, $RECONOS_BOARD board appears not to be connected."
    exit 1
fi

