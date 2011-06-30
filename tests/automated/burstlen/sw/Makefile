ECOS_CONFIG=dcr-$(RECONOS_BOARD).ecc
ECOS_BUILD=ecos

ECOS_INSTALL=$(ECOS_BUILD)/install
ECOS_SRC=$(ECOS_REPOSITORY)
EDKDIR = $(HW_DESIGN)
BSPDIR = $(EDKDIR)

# set compiler and flags depending on ARCH
ifeq ($(ARCH),ppc)
CC=powerpc-eabi-gcc
CFLAGS=-O -g -Wall -Werror -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/ppc405_0/include -I../../common -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/ppc405_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float
else ($(ARCH),mb)
CC=mb-gcc
CFLAGS=-O3 -g -Wall -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/microblaze_0/include -I../../common -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/microblaze_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float
else
$(error Unsupported ARCH or no ARCH specified)
endif

help:
	@echo "Available make targets:"
	@echo "   setup        sets up and compiles eCos library"
	@echo "   mrproper     clean + delete eCos library"
	@echo "   deps         create dependency file"
	@echo "   ecos         compile eCos executables"
	@echo "   clean        clean all executables and objet files"

ecos:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG) --srcdir=$(ECOS_SRC) tree

setup: ecos
	@echo "HW_DESIGN IS $(HW_DESIGN)"
	make -C $(ECOS_BUILD)

mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD)

clean:
	rm -f *.o *.elf _impactbatch.log $(TARGET)

# this is where the MEMSIZE and BURSTLEN constants get defined
# copy up to 1k bytes
# one test with step = burstlen, one with step = 2*burstlen

burstlen_test_1024_%.o: MEMSIZE = 1024

burstlen_test_1024_16_128.o: BURSTLEN = 16
burstlen_test_1024_16_128.o: STEP = 128
burstlen_test_1024_16_256.o: BURSTLEN = 16
burstlen_test_1024_16_256.o: STEP = 256

burstlen_test_1024_15_128.o: BURSTLEN = 15
burstlen_test_1024_15_128.o: STEP = 128
burstlen_test_1024_15_256.o: BURSTLEN = 15
burstlen_test_1024_15_256.o: STEP = 256

burstlen_test_1024_14_128.o: BURSTLEN = 14
burstlen_test_1024_14_128.o: STEP = 128
burstlen_test_1024_14_256.o: BURSTLEN = 14
burstlen_test_1024_14_256.o: STEP = 256

burstlen_test_1024_13_128.o: BURSTLEN = 13
burstlen_test_1024_13_128.o: STEP = 128
burstlen_test_1024_13_256.o: BURSTLEN = 13
burstlen_test_1024_13_256.o: STEP = 256

burstlen_test_1024_12_128.o: BURSTLEN = 12
burstlen_test_1024_12_128.o: STEP = 128
burstlen_test_1024_12_256.o: BURSTLEN = 12
burstlen_test_1024_12_256.o: STEP = 256

burstlen_test_1024_11_128.o: BURSTLEN = 11
burstlen_test_1024_11_128.o: STEP = 128
burstlen_test_1024_11_256.o: BURSTLEN = 11
burstlen_test_1024_11_256.o: STEP = 256

burstlen_test_1024_10_128.o: BURSTLEN = 10
burstlen_test_1024_10_128.o: STEP = 128
burstlen_test_1024_10_256.o: BURSTLEN = 10
burstlen_test_1024_10_256.o: STEP = 256

burstlen_test_1024_9_128.o: BURSTLEN = 9 
burstlen_test_1024_9_128.o: STEP = 128
burstlen_test_1024_9_256.o: BURSTLEN = 9 
burstlen_test_1024_9_256.o: STEP = 256

burstlen_test_1024_8_64.o:   BURSTLEN = 8
burstlen_test_1024_8_64.o:   STEP = 64
burstlen_test_1024_8_128.o:  BURSTLEN = 8
burstlen_test_1024_8_128.o:  STEP = 128

burstlen_test_1024_7_64.o:   BURSTLEN = 7
burstlen_test_1024_7_64.o:   STEP = 64
burstlen_test_1024_7_128.o:  BURSTLEN = 7
burstlen_test_1024_7_128.o:  STEP = 128

burstlen_test_1024_6_64.o:   BURSTLEN = 6
burstlen_test_1024_6_64.o:   STEP = 64
burstlen_test_1024_6_128.o:  BURSTLEN = 6
burstlen_test_1024_6_128.o:  STEP = 128

burstlen_test_1024_5_64.o:   BURSTLEN = 5
burstlen_test_1024_5_64.o:   STEP = 64
burstlen_test_1024_5_128.o:  BURSTLEN = 5
burstlen_test_1024_5_128.o:  STEP = 128

burstlen_test_1024_4_32.o:   BURSTLEN = 4
burstlen_test_1024_4_32.o:   STEP = 32
burstlen_test_1024_4_64.o:   BURSTLEN = 4
burstlen_test_1024_4_64.o:   STEP = 64

burstlen_test_1024_3_32.o:   BURSTLEN = 3
burstlen_test_1024_3_32.o:   STEP = 32
burstlen_test_1024_3_64.o:   BURSTLEN = 3
burstlen_test_1024_3_64.o:   STEP = 64

burstlen_test_1024_2_16.o:   BURSTLEN = 2
burstlen_test_1024_2_16.o:   STEP = 16
burstlen_test_1024_2_32.o:   BURSTLEN = 2
burstlen_test_1024_2_32.o:   STEP = 32
	
burstlen_test_%.o: burstlen_test.c
	$(CC) $(CFLAGS) -DMEMSIZE=$(MEMSIZE) -DBURSTLEN=$(BURSTLEN) -DSTEP=$(STEP) -c -o $@ burstlen_test.c


%.elf: %.o
	$(CC) $^ $(LDFLAGS) -o $@
	powerpc-eabi-size -A $@
	cp $@ /tmp/.

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

include .deps

.PHONY: clean deps mrproper setup help all

