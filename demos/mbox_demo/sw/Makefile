#
# Makefile
# Main makefile for mbox demo
#
# Author:     Enno Luebbers   <luebbers@reconos.de>
# Date:       16.10.2007
#
# This file is part of the ReconOS project <http://www.reconos.de>.
# University of Paderborn, Computer Engineering Group.
#
# (C) Copyright University of Paderborn 2007.
#

include config.make

help:
	@echo "Available make targets:"
	@echo "   setup        sets up and compiles eCos library"
	@echo "   mrproper     clean + delete eCos library"
	@echo "   deps         create dependency file"
	@echo "   ecos         compile eCos executables"
	@echo "   posix        compile eCos executables (POSIX API)"
	@echo "   linux        compile Linux executables"
	@echo "   clean        clean all executables and objet files"

setup:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG) --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)

#libxil:
#	ln -fs $(HW_DESIGN)/ppc405_0/lib/libxil.a $(ECOS_INSTALL)/lib/.
	
mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD)

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

.PHONY: deps mrproper linux

ecos: 
	make -f Makefile.ecos ecos

posix:
	make -f Makefile.ecos posix

linux:
	make -f Makefile.linux
        
clean:
	make -f Makefile.ecos clean
	make -f Makefile.linux clean
