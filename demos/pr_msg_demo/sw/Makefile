###### PLEASE FILL OUT THE FOLLOWING #######

# base name of eCos configuration (*.ecc)
ECOS_BASENAME=pr_msg_demo
# thread partial bitstream prefixes (e.g. prm0_a prm0_b prm1_a prm1_b)
THREADS=
# object files of software part excluding bitstreams (e.g. pr_howto.o)
OBJECTS=pr_msg_demo.o
#timing.o
# name of final executable (e.g. pr_howto.elf)
TARGET=pr_msg_demo.elf
######## NO CHANGES NECESSARY BEYOND THIS LINE ###################

# PlanAhead project name (within hw directory)
PA_PROJECT_NAME=project_reconos_1

BITFILES=$(notdir $(shell find ../hw/$(PA_PROJECT_NAME)/$(PA_PROJECT_NAME).runs/ -name "*_partial.bit"))
BITFILES_SRC=$(foreach b,$(BITFILES),$b.c) $(foreach b,$(BITFILES),$b.h)
BITFILES_OBJ=$(foreach b,$(BITFILES),$b.o)
ECOS_INSTALL=$(ECOS_BASENAME)_install
ECOS_BUILD=$(ECOS_BASENAME)_build
ECOS_MLT=$(ECOS_BASENAME)_mlt
ECOS_SRC=$(RECONOS)/core/ecos/ecos-patched/ecos/packages
EDKDIR = $(HW_DESIGN)
BSPDIR = $(EDKDIR)

CC=mb-gcc
CFLAGS=-O3 -pipe -g -Wall -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/microblaze_0/include -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__ -I.
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/microblaze_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float

all: $(TARGET)

setup:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_BASENAME).ecc $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_BASENAME).ecc --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)
	cp -r $(ECOS_BUILD)/install $(ECOS_INSTALL)

libxil:
	ln -fs $(HW_DESIGN)/ppc405_0/lib/libxil.a $(ECOS_INSTALL)/lib/.
	
mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD) $(ECOS_MLT)

$(BITFILES):
	find ../hw/$(PA_PROJECT_NAME)/$(PA_PROJECT_NAME).runs/ -name '$@' -exec cp {} . \;

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

