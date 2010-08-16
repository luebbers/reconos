#!/bin/bash
##############################
# USB init script for iMPACT #
#                            #
#     by Stefan Endrullis    #
##############################

rmmod xpc4drv
rmmod windrvr6

modprobe windrvr6
chown luebbers:users /dev/windrvr6
chmod 660 /dev/windrvr6
modprobe xpc4drv

echo "Bitte Board einschalten."

while [ susb | grep -c "ID 03fd:0008 Xilinx, Inc." != "1" ]; do 
  printf ".";
  sleep 1;
done
    
echo "OK"
    
/etc/init.d/hotplug restart
