include config.make

TARGETS = beat_tracker.elf

CC=powerpc-eabi-gcc
CFLAGS=-O1 -g -Wall -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/ppc405_0/include -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/ppc405_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float  -pthread

all: $(TARGETS)

mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD)

beat_tracker.elf: src/beat_tracker.o framework/user_src/uf_extract_observation.o framework/src/preSampling.o framework/src/sampling.o framework/src/observation.o framework/src/importance.o framework/src/preResampling.o framework/src/resampling.o framework/src/particle_filter.o framework/user_src/uf_init_particles.o framework/user_src/uf_prediction.o framework/user_src/uf_likelihood.o framework/user_src/uf_iteration_done.o framework/user_src/uf_get_new_measurement.o framework/src/timing.o src/fft.o src/ethernet.o
	$(CC) $^ $(LDFLAGS) -o $@
	powerpc-eabi-size -A $@
	cp $@ /tmp/.



setup:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG) --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)
	$(RECONOS)/tools/libxil_strip.sh $(HW_DESIGN)/ppc405_0/lib/libxil.a

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

pc: 
	rm -f src/*.o
	rm -f framework/src/*.o
	rm -f framework/user_src/*.o
	make -f Makefile.pc

#include .deps

.PHONY: clean deps mrproper

clean:
	rm -f src/*.o $(TARGETS)
	rm -f framework/src/*.o
	rm -f framework/user_src/*.o

