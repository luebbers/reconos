###### PLEASE FILL OUT THE FOLLOWING #######

# base name of eCos configuration (*.ecc)
ECOS_BASENAME=track
#_config
# thread partial bitstream prefixes (e.g. prm0_a prm0_b prm1_a prm1_b)
THREADS=prm0_observation prm0_importance prm1_observation prm1_importance
# object files of software part excluding bitstreams (e.g. pr_howto.o)
OBJECTS=src/object_tracker.o src/observation.o src/bgr2hsv.o framework/user_src/uf_extract_observation.o src/histogram.o src/ethernet.o src/display.o src/tft_screen.o framework/src/preSampling.o framework/src/sampling.o framework/src/observation.o framework/src/importance.o framework/src/preResampling.o framework/src/resampling.o framework/src/particle_filter.o framework/user_src/uf_init_particles.o framework/user_src/uf_prediction.o framework/user_src/uf_likelihood.o framework/user_src/uf_iteration_done.o framework/user_src/uf_get_new_measurement.o framework/src/timing.o  # sort_demo/sort8k.o sort_demo/data.o
# name of final executable (e.g. pr_howto.elf)
TARGET=object_tracker.elf


######## NO CHANGES NECESSARY BEYOND THIS LINE ###################

BITFILES=$(notdir $(shell find ../hw/merges -name "*_routed_partial.bit"))
BITFILES_SRC=$(foreach b,$(BITFILES),$b.c) $(foreach b,$(BITFILES),$b.h)
BITFILES_OBJ=$(foreach b,$(BITFILES),$b.o)

ECOS_CONFIG=track.ecc
ECOS_BUILD=ecos_build
ECOS_INSTALL=$(ECOS_BUILD)/install
ECOS_SRC=$(ECOS_REPOSITORY)
EDKDIR = $(HW_DESIGN)
BSPDIR = $(EDKDIR)
BSPDIR = $(EDKDIR)
#CFLAGS = 

#ECOS_INSTALL=$(ECOS_BASENAME)_build/install
##$(ECOS_BASENAME)_install
#ECOS_BUILD=$(ECOS_BASENAME)_build
#ECOS_MLT=$(ECOS_BASENAME)_mlt
#ECOS_SRC=$(ECOS_REPOSITORY)
#EDKDIR = $(HW_DESIGN)
#BSPDIR = $(EDKDIR)

CC=powerpc-eabi-gcc
CFLAGS=-O1 -pipe -g -Wall -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/ppc405_0/include -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/ppc405_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float

all: $(TARGET)

setup:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG) --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)
	#cp -r $(ECOS_BUILD)/install $(ECOS_INSTALL)
	$(RECONOS)/tools/libxil_strip.sh $(HW_DESIGN)/ppc405_0/lib/libxil.a

#libxil:
#	ln -fs $(HW_DESIGN)/ppc405_0/lib/libxil.a $(ECOS_INSTALL)/lib/.

mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD) $(ECOS_MLT)

$(BITFILES):
	find ../hw/merges -name '$@' -exec cp {} . \;

%.bit.c %.bit.h: $(BITFILES)
	bit2c $*.bit

$(OBJECTS): $(BITFILES_SRC)

$(TARGET): $(BITFILES_OBJ) $(OBJECTS)
	$(CC) $(OBJECTS) $(BITFILES_OBJ) $(LDFLAGS) -o $(TARGET)
	powerpc-eabi-size -A $(TARGET)
	cp $(TARGET) /tmp/.

deps:
	$(CC) -MM *.c  $(CFLAGS) > deps || /bin/true

include deps

.PHONY: clean mrproper

clean:
	rm -f $(OBJECTS) $(BITFILES) $(BITFILES_SRC) $(BITFILES_OBJ) $(TARGET)

