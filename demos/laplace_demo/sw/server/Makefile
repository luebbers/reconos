ECOS_CONF=laplace_demo2
ECOS_INCLUDE=../ecos/$(ECOS_CONF)_install/include
ECOS_LIB=../ecos/$(ECOS_CONF)_install/lib

CC=powerpc-eabi-gcc
CFLAGS=-O3 -g -Wall -ffunction-sections -fdata-sections -I$(HW_DESIGN)/ppc405_0/include -I$(RECONOS)/core/ecos/include -I../shared -I$(ECOS_INCLUDE) -msoft-float -DUSE_ECOS
LDFLAGS=-nostartfiles --gc-sections -L$(ECOS_LIB) -Ttarget.ld -nostdlib -msoft-float

OBJECTS=ipserver.o utils.o buffers.o buffers_ecos.o udp_connection.o profile.o

all: init ipserver.elf deps

init:
	ln -fs ../shared/*.c .

ipserver.elf: $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o ipserver.elf
	powerpc-eabi-size -A ipserver.elf
#	cp ipserver.elf /tftp/ipserver.elf

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

include .deps

.PHONY: clean deps

clean:
	rm -f $(OBJECTS) ipserver.elf

