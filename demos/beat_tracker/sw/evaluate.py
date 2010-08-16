#!/usr/bin/python2.5

import sys

################################################################################
########
########    R E A D   I N P U T   A N D   E X T R A C T    R E S U L T S
########
################################################################################

partitionings = ["sw", "hw_i", "hw_ii", "hw_o", "hw_oo", "hw_oi", "hw_oii", "hw_ooi", "hw_ooii"]
audio = ["madness", "sound2", "sound3"]
number_of_frames = [50, 500, 500]
counter = [[0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]]
measurements = [[[], [], [], [], [], [], [], [], []], [[], [], [], [], [], [], [], [], []]]
print "\n"

current_partition = 0
current_time = 0
current_audio = 0
read_measurements = 0;
read_measurements_done = 0;
current_measurement = []

########## I. read input file
f=open("input/"+sys.argv[1], "r") # open file (read access)
for line in f:
	
	# 1. find audio
	#if line=="##########  S O C C E R   V I D E O  ############\n":
	#	if current_audio != 0:
	#		current_audio = 0
	#		print "Audio: ", audio[current_audio]
	#if line=="########  F O O T B A L L   V I D E O  ##########\n":
	#	if current_audio != 1:
	#		current_audio = 1
	#		print "Audio: ",audio[current_audio]
	#if line=="##########  H O C K E Y   V I D E O  ############\n":
	#	if current_audio != 2:
	#		current_audio = 2
	#		print "Audio: ",audio[current_audio]

	# 2. find partitioning
	if line=="######   P A R T I T I O N I N G    S W   #######\n":
		if current_partition != 0:
			current_partition = 0
			#print "Partitioning: ", partitionings[current_partition]	
	if line=="####   P A R T I T I O N I N G    H W  I   #####\n":
		if current_partition != 1:
			current_partition = 1
			#print "Partitioning: ", partitionings[current_partition]	
	if line=="####   P A R T I T I O N I N G    H W   II   #####\n":
		if current_partition != 2:
			current_partition = 2
			#print "Partitioning: ", partitionings[current_partition]	
	if line=="####   P A R T I T I O N I N G    H W   O   #####\n":
		if current_partition != 3:
			current_partition = 3
			#print "Partitioning: ", partitionings[current_partition]	
	if line=="####   P A R T I T I O N I N G    H W   OO   #####\n":
		if current_partition != 4:
			current_partition = 4
			#print "Partitioning: ", partitionings[current_partition]	
	if line=="####   P A R T I T I O N I N G    H W   OI   #####\n":
		if current_partition != 5:
			current_partition = 5
			#print "Partitioning: ", partitionings[current_partition]
	if line=="####   P A R T I T I O N I N G    H W   OII   #####\n":
		if current_partition != 6:
			current_partition = 6
			#print "Partitioning: ", partitionings[current_partition]	
	if line=="####   P A R T I T I O N I N G    H W   OOI   #####\n":
		if current_partition != 7:
			current_partition = 7
			#print "Partitioning: ", partitionings[current_partition]	
	if line=="####   P A R T I T I O N I N G    H W   OOII   #####\n":
		if current_partition != 8:
			current_partition = 8
			#print "Partitioning: ", partitionings[current_partition]

	# 3. end of reading measurements
	if read_measurements == 1:
		if line[0:7]=="Network" or line[0:6]=="ASSERT" or line=="\n":
			read_measurements = 0
			read_measurements_done = 1	
			#print "end of measurements"

	# 4. read current measurements
	if read_measurements == 1:
		# read measurements
		try:
			measured_time = int(line)
			current_measurement.append(measured_time)
			
			#print current_time#, ", ",measurements[current_audio][current_partition][current_time]
			# do not save peaks, which occur while data transfer
			#if len(measurements[current_audio][current_partition]) < (current_time+1):
			#	measurements[current_audio][current_partition].append(measured_time)
			#	#print current_time, ", ",measurements[current_audio][current_partition][current_time]
			#else:
			#	measurements[current_audio][current_partition][current_time]+=measured_time
			#	#print current_time,", ",measurements[current_audio][current_partition][current_time]			
			current_time+=1
		except ValueError:
			print "value error at: ", line
			read_measurements = 0
			read_measurements_done = 1

	# 5. start reading measurements
	if line=="start particle filter\n":
		#print "partitioning", partitionings[current_partition], "No.", counter[current_audio][current_partition]+1
		current_time = 0
		read_measurements = 1
		read_measurements_done = 0
		current_measurement = []

	# 6. update average measurements, if the measurements are completed 
	#    (= at least number_of_frames[current_audio] values)
	if read_measurements_done == 1:
		read_measurements_done = 0
		if len(current_measurement) > number_of_frames[current_audio]:
			counter[current_audio][current_partition]+=1
			if len(measurements[current_audio][current_partition]) < number_of_frames[current_audio]:
				# 'empty' average measurement
				measurements[current_audio][current_partition] = []
				for i in range(number_of_frames[current_audio]):
					measurements[current_audio][current_partition].append(current_measurement[i])
			else:
				# allready measurement before, add values
				for i in range(number_of_frames[current_audio]):
					measurements[current_audio][current_partition][i]+=current_measurement[i]
		#else, not enough values in measurement => ignore it
			
		

f.close()

########## II. write output files
sum = 0
for i in range(9):
	number = 0
	# 7. save results
	# open file (write access)
	f=open("partitionings/"+audio[0]+"/partitioning_"+partitionings[i]+".txt", "w")
	print "audio:", audio[0],", partitioning:", partitionings[i], ", measurements", counter[0][i]
	old_j = sys.maxint/5
	sum += counter[0][i]
	for j in measurements[0][i]:
		if j>0 and (((number+2) % 20) > 0):
			# 8. average measurements
			if counter[0][i] > 0:
				j = j / counter[0][i]
			#print number, "\t", j
			f.write(str(number)+"\t"+str(j)+"\n");
		number+=1
		old_j = j;
	f.write("\n");
	f.close()
print "sum of all measurements =", sum


