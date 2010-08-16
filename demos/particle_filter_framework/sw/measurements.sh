#!/bin/bash

# bitfile
b=$SW_DESIGN/../hw/merges/prm0_observation/base_routed_full.bit

# video path
p=~/work/sandbox/track/video

#video
v=soccer

# video file
f=$p/soccer.avi

# number of frames (for tracking)
m=440

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
# make 50 measurements
for i in `seq 1 50`; do
		
	# start pr_server
	pr_server.py &
	s=$!	
	
	# download executable to FPGA
	dow $SW_DESIGN/object_tracker.elf 2
	
	# wait some time
	sleep 10
	
	# write some information about the current measurement
	echo //////////////////////////////////////////////////////////
	echo //////////////////////////////////////////////////////////
        echo /////  Measurement No. $i                            ////
	echo //////////////////////////////////////////////////////////
	echo //////////////////////////////////////////////////////////
	
	# send video to FPGA and do Object Tracking
	$SW_DESIGN/../pc/bin/objectTracking 192.168.1.7 -q -i `echo $f` -m `echo $m`
	
	# wait some time
	echo sleep 25
	sleep 25
	
	# kill pr_server
	kill `echo $s`
	
	echo sleep 5
	sleep 5
done

# III. evaluate measurements
##################################
#sleep 200
#cd ~/work/measurements_adaptive
#sh evaluate_measurements.sh input.txt

# IV. display results
##################################
#acroread measurements_`echo $v`.pdf
