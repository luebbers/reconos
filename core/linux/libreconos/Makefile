CFLAGS=-O3

all: default

default: lib/libreconos.a

lib/libreconos.a:
	make -C src
	cp src/libreconos.a lib

clean:
	make -C src clean
	rm -f lib/libreconos.a

.PHONY: clean
