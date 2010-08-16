#!/bin/bash
#
# Program for downloading bitstreams.
#
# Usage: download_bitstream.sh <bitfile> [jtag chain pos]
#        - jtag chain pos defaults to 3
#

POS=3
if [ $# -eq 2 ]
then
	POS=$2
fi


echo "
setMode -bs
setCable -port auto
Identify
IdentifyMPM
assignFile -p $POS -file \"$1\"
Program -p $POS
quit
" | impact -batch && echo "

SUCCESS
bitstream is $(($(date "+%s") - $(stat -c "%Y" $1))) seconds old" || echo "

FAILURE
could not download bitstream"

