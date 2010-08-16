CFLAGS=-Wall -O3

TARGETS=bit2c ppm2c tcpcat any2c

all: $(TARGETS)

bit2c: bit2c.o crc32.o

ppm2c: ppm2c.o

any2c: any2c.o

tcpcat: tcpcat.o
	$(CC) tcpcat.o -o tcpcat -lrt

clean:
	rm -f $(TARGETS) bit2c.o crc32.o ppm2c.o tcpcat.o 

.PHONY: clean

install: $(TARGETS)
	cp $(TARGETS) ..

