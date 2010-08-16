#!/bin/sh

cp $RECONOS/tools/makefiles/eapr/Makefile .
make edk-static
cd edk-static/pcores && rm -rf hw_task_v1_01_b && rm -rf hw_task_v1_02_b
mkhwthread.py threadA 1 ../../src/threadA.vhd
mkhwthread.py threadB 2 ../../src/threadB.vhd
cd ../..
