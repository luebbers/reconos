#!/bin/bash

PARTITIONINGS="sw hw_i hw_ii hw_o hw_oo hw_oi hw_oii hw_ooi hw_ooii"

make clean
for i in `echo $PARTITIONINGS`
do
	make executables/beat_tracker_`echo $i`.elf
done

