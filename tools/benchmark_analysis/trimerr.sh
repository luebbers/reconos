#!/bin/bash
#
# trimerr.sh: trims erroneous measurement data (first value)

if [ ! $1 ]; then
	echo "Usage: $0 <data file.dat>"
	exit
fi

TMPFILE=`mktemp /tmp/trimerr.XXXXX`

head -n 1 $1 > $TMPFILE
tail -n +3 $1 >> $TMPFILE
mv $TMPFILE $1
