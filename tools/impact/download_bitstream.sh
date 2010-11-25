#!/bin/bash
#
# Program for downloading bitstreams.
#
# Usage: download_bitstream.sh <bitfile> [jtag chain pos]
#        - jtag chain pos defaults to 3
#
# If the environment variable IMPACT_REMOTE is set, it is used
# as a remotely running cse_server instead of a local USB connection

POS=3
if [ $# -eq 2 ]
then
	POS=$2
fi

if [ -z $IMPACT_REMOTE ]; then

echo "
setMode -bs
setCable -port auto
Identify
IdentifyMPM
assignFile -p $POS -file \"$1\"
Program -p $POS
quit
" | impact -batch

else
echo "Using remote cs_server at ${IMPACT_REMOTE}"
echo "
setMode -bs
setCable -port auto -server ${IMPACT_REMOTE}
Identify
IdentifyMPM
assignFile -p $POS -file \"$1\"
Program -p $POS
quit
" | impact -batch

fi

# test for success
if [ $? -eq 0 ]; then
   echo "

SUCCESS
bitstream is $(($(date "+%s") - $(stat -c "%Y" $1))) seconds old" 

else
    echo "

FAILURE
could not download bitstream"
    exit 1
fi


