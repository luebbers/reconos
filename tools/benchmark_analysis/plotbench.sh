#!/bin/bash
#
# plotbench.sh: Plot benchmark results parsed from ReconOS
# benchmark suite output

DAT2GP="./dat2gp.pl"
MKHIST="./mkhist.pl"
TEXT2DAT="./text2dat.pl"
TRIMERR="./trimerr.sh"

if [ ! $1 ]; then
	echo "Usage: $0 <benchmark_output>"
	exit
fi

echo "Parsing text file..."
$TEXT2DAT < $1

echo "Creating GnuPlot scripts..."
for i in *.dat; do
	$TRIMERR $i
	$DAT2GP $i
	$MKHIST $i
done

echo "Plotting..."
gnuplot *.gp

echo "Plotting done."
