#!/bin/sh
LIBXIL=$1
FILELIST=$2

echo "$0 <path_to_libxil.a> [path_to_filelist]"
echo "    Strips duplicate symbols from libxil."
echo ""

if [ -z $LIBXIL ]; then
  LIBXIL="./libxil.a"
  echo "Trying '$LIBXIL'."
fi

if [ -z $FILELIST ]; then
  FILELIST="`dirname $0`/libxil_strip.in"
  echo "Trying '$FILELIST'."
fi

if [ ! -f $LIBXIL ]; then
  echo "'$LIBXIL' not found, please specifiy."
  exit
fi

if [ ! -f $FILELIST ]; then
  echo "filelist not found, please specifiy."
  exit
fi

echo "This script will remove those files specified in"
echo "   '$FILELIST'"
echo "from the Xilinx BSP library"
echo "   '$LIBXIL'."
echo "Usually, this script is used before including libxil.a"
echo "in an eCos build, because eCos provides the functionality."

for i in `cat $FILELIST`; do
  echo "powerpc-eabi-ar d $LIBXIL $i"
  powerpc-eabi-ar d $LIBXIL $i
done
