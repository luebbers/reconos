#!/bin/bash -i
LAST_BITSTREAM_FILE="/tmp/.impact_download_last"
TEMPLATE="impact_download.batch.template"
BATCH="impact_download.batch"

AGE="age"

if [ -f $LAST_BITSTREAM_FILE ]; then
  BITSTREAM=`cat $LAST_BITSTREAM_FILE`
else
  BITSTREAM="/home/luebbers/work/"
fi

RETVAL=`zenity --title "Select bitstream" --entry --text="Please enter the bitstream filename" --entry-text="${BITSTREAM}" --width=500`

if [ ! -f $RETVAL ]; then
  echo "The file $RETVAL does not exist!"
  exit
else
  BITSTREAM=$RETVAL
fi

cat $TEMPLATE | sed "s#PLACEHOLDER#${BITSTREAM}#" > $BATCH
echo $BITSTREAM > $LAST_BITSTREAM_FILE

impact -batch $BATCH

DIFF=`$AGE $BITSTREAM`

echo ""
echo ""
echo "----> This bitstream is $((${DIFF}/60)) minutes and $((${DIFF}%60)) seconds old."
echo ""
echo "Press ENTER to quit"
read
