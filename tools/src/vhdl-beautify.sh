#!/bin/bash
#
# vhdl-beautify.sh: Beautifies VHDL code
#

# constants
EMACS=`which emacs`
BASE=`basename $0`
DIR=`dirname $0`
SCRIPT="$DIR/vhdl-beautify.el"

if [ "$#" -ne 1 ]; then
	echo "Beautifies VHDL code using emacs"
	echo "USAGE: $BASE <source_file.vhd>"
	exit -1
fi

SRC="$1"

if [ ! -x "$EMACS" ]; then
	echo "!! Can't execute emacs. Is it installed?"
	exit -1
fi

if [ ! -f "$SCRIPT" ]; then
	echo "!! Can't find lisp script '$SCRIPT'."
	exit -1
fi

if [ ! -f "$SRC" ]; then
	echo "!! '$SRC' is not a regular file"
	exit -1
fi

#BAK="$SRC.bak"
# We don't need to back up, since Emacs does this for us
#echo ":: Saving backup to '$BAK'..."
#cp "$SRC" "$BAK"

echo ":: Beautifying '$SRC'..."
$EMACS --batch "$SRC" -l "$SCRIPT" -f save-buffer
