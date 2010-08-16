#
# Makefile for mbox-demo
#
EAPR_MAKEFILE := $(RECONOS)/tools/makefiles/eapr/Makefile

.PHONY: threads clean bits-static

all: bits-static

# NOTE: bits-static also builds the libraries
bits-static: threads
	make -f $(EAPR_MAKEFILE) bits-static

# replace dummy threads with the actual hardware threads
threads: edk-static mbox_pcore
	cd edk-static/pcores && rm -rf hw_task_v1_01_b hw_task_v1_02_b
	cd edk-static/pcores && mkhwthread.py threadA 1 ../../src/threadA.vhd
	cd edk-static/pcores && mkhwthread.py threadB 2 ../../src/threadB.vhd

# add mbox fifo pcore to hw design
mbox_pcore: edk-static
	cd edk-static && mv system.mhs system.mhs.nofifo && mhsaddfifo.py system.mhs.nofifo 0 1 > system.mhs
	touch mbox_pcore

# create new hw design
edk-static:
	make -f $(EAPR_MAKEFILE) edk-static

clean:
	rm -rf mbox_pcore edk-static edk-base make.log

