#
# Makefile
# Main makefile for sorting demo
#
# Author:     Enno Luebbers   <luebbers@reconos.de>
# Date:       28.09.2007
#
# This file is part of the ReconOS project <http://www.reconos.de>.
# University of Paderborn, Computer Engineering Group.
#
# (C) Copyright University of Paderborn 2007.
#

include config.make

help:
	@echo "Available make targets:"
	@echo "   setup.mb     sets up and compiles eCos library (Microblaze)"
	@echo "   setup.ppc    sets up and compiles eCos library (PowerPC)"
	@echo "   mrproper     clean + delete eCos library"
	@echo "   deps         create dependency file"
	@echo "   pc           compile pc executables"
	@echo "   ecos.mb      compile eCos executables (Microblaze)"
	@echo "   ecos.ppc     compile eCos executables (PowerPC)"
	@echo "   posix        compile eCos/POSIX executables"
	@echo "   clean        clean all executables and objet files"

setup.mb:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG_MB) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG_MB) --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)

setup.ppc:
	mkdir $(ECOS_BUILD)
	cp $(ECOS_CONFIG_PPC) $(ECOS_BUILD)
	cd $(ECOS_BUILD) && ecosconfig --config=$(ECOS_CONFIG_PPC) --srcdir=$(ECOS_SRC) tree
	make -C $(ECOS_BUILD)

#libxil:
#	ln -fs $(HW_DESIGN)/ppc405_0/lib/libxil.a $(ECOS_INSTALL)/lib/.
	
mrproper: clean
	rm -rf $(ECOS_INSTALL) $(ECOS_BUILD)

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

.PHONY: deps mrproper

pc: 
	rm -f *.o
	make -f Makefile.pc
        
posix: 
	rm -f *.o
	make -f Makefile.posix

ecos.mb: 
	rm -f *.o
	make -f Makefile.ecos.mb
        
ecos.ppc: 
	rm -f *.o
	make -f Makefile.ecos.ppc
        
clean:
	make -f Makefile.pc clean
	make -f Makefile.ecos.ppc clean
	make -f Makefile.ecos.mb clean
	make -f Makefile.posix clean
