# if KERNELRELEASE is defined (i.e. != ""), we've been invoked from
# the kernel build system and can build the module
ARCH ?= powerpc
CROSS_COMPILE ?= powerpc-405-linux-gnu-
export ARCH CROSS_COMPILE

ifneq ($(KERNELRELEASE),)
# extend include directories
EXTRA_CFLAGS += -I$(HW_DESIGN)/ppc405_0/include
  
obj-m := timebase.o

else

# for PPC
KERNELDIR ?= /home/luebbers/work/linux/sw/2.6/linux

PWD       := $(shell pwd)


modules:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

# for MicroBlaze
petalinux: CFLAGS += -D__PETALINUX__
petalinux: KERNELDIR := $(PETALINUX)/software/petalinux-dist
petalinux: modules

endif

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions Module.symvers
	
depend .depend dep:
	$(CC) $(CFLAGS) -M *.c > .depend
	
ifeq (.depend,$(wildcard .depend))
include .depend
endif
