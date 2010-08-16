ECOS_BASENAME=netimage_ecos
ECOS_INSTALL=$(ECOS_BASENAME)_install
ECOS_BUILD=$(ECOS_BASENAME)_build
ECOS_MLT=$(ECOS_BASENAME)_mlt
ECOS_SRC=$(RECONOS)/ecos-patched/ecos/packages
EDKDIR = $(HW_DESIGN)
BSPDIR = $(EDKDIR)

OBJECTS=netimage_ecos.o
TARGET=netimage_ecos.elf

CC=powerpc-eabi-gcc
CFLAGS=-O1 -pipe -g -Wall -ffunction-sections -fdata-sections -I../shared -I$(ECOS_INSTALL)/include \
 -I$(HW_DESIGN)/ppc405_0/include -Iinclude -msoft-float -I$(RECONOS)/core/ecos/include -DUSE_ECOS -D__RECONOS__
LDFLAGS=-g -nostartfiles --gc-sections -L$(HW_DESIGN)/ppc405_0/lib -L$(ECOS_INSTALL)/lib -Ttarget.ld -nostdlib -msoft-float

all: $(TARGET)

setup:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_BASENAME).ecc $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_BASENAME).ecc --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)
	cp -r $(ECOS_BUILD)/install $(ECOS_INSTALL)
	$(RECONOS)/tools/libxil_strip.sh $(HW_DESIGN)/ppc405_0/lib/libxil.a

libxil:
	ln -fs $(HW_DESIGN)/ppc405_0/lib/libxil.a $(ECOS_INSTALL)/lib/.
	
mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD) $(ECOS_MLT) deps

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $(TARGET)
	powerpc-eabi-size -A $(TARGET)
	cp $(TARGET) /tmp/.

deps:
	$(CC) -MM *.c  $(CFLAGS) > deps || /bin/true

include deps

.PHONY: clean mrproper

clean:
	rm -f $(OBJECTS) $(TARGET)

