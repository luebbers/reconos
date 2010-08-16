#!/bin/bash

# bitfile
b=~/work/sound_demo_v4/hw/edk-static/implementation/system.bit

# prefix
r=$SW_DESIGN/executables

PARTITIONINGS="sw hw_i hw_ii hw_o hw_oo hw_oi hw_oii hw_ooi hw_ooii"
#PARTITIONINGS="sw hw_i"
#hw_ii
# audio path
a=~/work/BeatTrackPF/audio

# audio files
f=$a/madness_mono.wav
g=$a/madness_mono_output_v4.wav

# number of frames (for tracking)
#m=440

cd $SW_DESIGN
#echo -e 'cleancablelock\nexit' | impact -batch
#echo -e 'cleancablelock\nexit' | impact -batch
#sleep 4

# I: download bitfile to FPGA
##################################
dow $b 2
# wait some time
sleep 15
echo sleep 15

# II: make measurements
##################################
# make 50 measurements per partitioning
#for j in `echo $PARTITIONINGS`; do
for i in `seq 1 50`; do
	for j in `echo $PARTITIONINGS`; do
		
		# download executable to FPGA
		dow $r/beat_tracker_`echo $j`.elf 2
		
		# wait some time
		sleep 10
		
		# write some information about the current measurement
		echo //////////////////////////////////////////////////////////
		echo //////////////////////////////////////////////////////////
                echo ///// Partitioning $j  ////  Measurement No. $i  ////
		echo //////////////////////////////////////////////////////////
		echo //////////////////////////////////////////////////////////
		
		# send video to FPGA and do Object Tracking
		$SW_DESIGN/../pc/bin/beatTracking 192.168.1.7 -i `echo $f` -o `echo $g` -m 500
		
		# wait some time
		echo sleep 30
		sleep 30
	done
	echo sleep 30
	sleep 30
done

# III. evaluate measurements
##################################
#sleep 200
#cd ~/work/measurements_beat
#sh evaluate_measurements.sh input.txt

# IV. display results
##################################
#acroread measurements_madness.pdf
