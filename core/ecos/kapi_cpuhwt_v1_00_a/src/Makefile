####################################/-*-Makefile-*- 



#include all common source files
SRCS = kapi_cpuhwt.c

CFLAGS = -Wall -O2

OBJS = ${SRCS:.c=.o}

COMPILER=
ARCHIVER=
CP=cp
EXTRA_COMPILER_FLAGS= 
LIB=libxil.a
LEVEL=0

RELEASEDIR=../../../lib/
INCLUDEDIR=../../../include/
INCLUDES=-I./include/ -I${INCLUDEDIR}

INCLUDEFILES= ./include/kapi_cpuhwt.h
LIBSOURCES= $(SRCS:%.c=src/%.c)
OUTS = *.o 

libs:
	for i in $(LIBSOURCES); do \
	  echo "Compiling " $$i ;\
	  $(COMPILER) $(COMPILER_FLAGS) $(CFLAGS) $(EXTRA_COMPILER_FLAGS) $(INCLUDES) $$i; \
        done
	$(ARCHIVER) -r ${RELEASEDIR}/${LIB} ${OUTS} 
	echo make clean

include: dummy
	${CP} -rf ${INCLUDEFILES} ${INCLUDEDIR}

dummy:
clean:
	rm -rf ${OUTS}

