COMPILER=

ARCHIVER=

CP=cp

COMPILER_FLAGS=

EXTRA_COMPILER_FLAGS=

LIB=libxil.a

LEVEL=0



RELEASEDIR=../../../lib

INCLUDEDIR=../../../include

INCLUDES=-I./. -I${INCLUDEDIR}



L0_INCLUDEFILES=opb_onewire_l.h 

LIBSOURCES=*.c

OUTS = *.o 



INCLUDEFILES=$(L$(LEVEL)_INCLUDEFILES)



libs:

	echo "Compiling opb_onewire"

	$(COMPILER) -g $(COMPILER_FLAGS) $(EXTRA_COMPILER_FLAGS) $(INCLUDES) $(LIBSOURCES)

	$(ARCHIVER) -r ${RELEASEDIR}/${LIB} $(OUTS)

	make clean



include: 

	${CP} $(INCLUDEFILES) $(INCLUDEDIR)



clean:

	rm -rf ${OUTS}

