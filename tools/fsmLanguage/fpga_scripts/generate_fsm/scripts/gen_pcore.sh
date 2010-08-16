#!/bin/sh

# Check for arguments
if [ $# -ne 4 ]
then
  echo "Correct Usage:"
  echo " ./gen_core.sh <entityName> <vhdlFile> <mpdFile> <pcoreRepoPath>"
  exit
fi

# Grab command line arguments
entName=$1
vhdName=$2
mpdName=$3
pcorePath=$4

# Set up new file and path names
paoName="$entName"_v2_1_0.pao
newMpdName="$entName"_v2_1_0.mpd

# Create directory structure
mkdir -p $pcorePath/$entName/data
mkdir -p $pcorePath/$entName/hdl/vhdl

# Create MPD
cp $mpdName $pcorePath/$entName/data/$newMpdName

# Create PAO
echo "lib $entName $entName vhdl" > $pcorePath/$entName/data/$paoName

# Create and move HDL files
cp $vhdName $pcorePath/$entName/hdl/vhdl/.
