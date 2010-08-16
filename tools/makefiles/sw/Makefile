# Makefile for the software part of a ReconOS system

######## Set the variables below to suitable values #####

# Your eCos configuration file
ECOS_CONFIG=myproject.ecc
TARGET = myproject.elf
OBJECTS = myproject.o foo.o bar.o

######## No edits necessary below this line #############

ECOS_BUILD=ecos_build
ECOS_INSTALL=$(ECOS_BUILD)/install
ECOS_SRC=$(ECOS_REPOSITORY)
EDKDIR = $(HW_DESIGN)
BSPDIR = $(EDKDIR)

CC=powerpc-eabi-gcc
CFLAGS=-O1 -g -Wall -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/ppc405_0/include -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/ppc405_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float

help:
	@echo "Available make targets:"
	@echo "   all          make everything (eCos library and target)"
	@echo "   clean        clean all executables and object files"
	@echo "   mrproper     clean + delete eCos library"
	@echo "   setup        sets up and compiles eCos library"
	@echo "   deps         create dependency file"

all: $(TARGET)

setup: $(ECOS_BUILD)

$(ECOS_BUILD):
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG) --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)

mrproper	: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD)

$(TARGET): $(ECOS_BUILD) $(OBJECTS)
	$(CC) $^ $(LDFLAGS) -o $@
	powerpc-eabi-size -A $@
	cp $@ /tmp/.

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

#include .deps

.PHONY: clean deps mrproper

clean:
	rm -f $(OBJECTS) $(TARGET)


