#!/bin/bash -i
LAST_ELF_FILE="/tmp/.xmd_download_last"


if [ "$1" ]; then		# ELF provided on command line
	RETVAL="$1"
else
	if [ -f $LAST_ELF_FILE ]; then
	  ELF=`cat $LAST_ELF_FILE`
	else
	  ELF=$HOME
	fi

	RETVAL=`zenity --title "Select ELF" --entry --text="Please enter the ELF filename" --entry-text="${ELF}" --width=500`
fi

if [ ! -f $RETVAL ]; then
  echo "The file $RETVAL does not exist!"
  exit 1
else
  ELF=$RETVAL
fi

if [ -e "$XILINX_EDK/bin/lin64/xmd" ] ; then
        echo -e "ppccon\ndow $ELF\nrun\n" | $XILINX_EDK/bin/lin64/xmd
else
        echo -e "ppccon\ndow $ELF\nrun\n" | $XILINX_EDK/bin/lin/xmd
fi
	
