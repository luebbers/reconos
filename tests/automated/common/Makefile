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
else
ifeq ($(ARCH),mb)
CC=mb-gcc
CFLAGS=-O3 -g -Wall -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/microblaze_0/include -I../../common -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/microblaze_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float
else
$(error Unsupported ARCH or no ARCH specified)
endif
endif

help:
	@echo "Available make targets:"
	@echo "   setup        set up eCos library"
	@echo "   ecos         compile eCos library"
	@echo "   mrproper     clean + delete eCos library"
	@echo "   deps         create dependency file"
	@echo "   clean        clean all executables and objet files"

ecos:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG) --srcdir=$(ECOS_SRC) tree

setup: ecos
	make -C $(ECOS_BUILD)

mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD)

clean:
	rm -f *.o *.elf _impactbatch.log $(TARGET)

%.elf: %.o
	$(CC) $^ $(LDFLAGS) -o $@
	powerpc-eabi-size -A $@
	cp $@ /tmp/.

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

include .deps

.PHONY: clean deps mrproper setup help all

