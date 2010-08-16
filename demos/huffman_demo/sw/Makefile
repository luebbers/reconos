ECOS_CONFIG=networking.ecc
ECOS_BUILD=ecos

ECOS_INSTALL=$(ECOS_BUILD)/install
ECOS_SRC=$(ECOS_REPOSITORY)
EDKDIR = $(HW_DESIGN)
BSPDIR = $(EDKDIR)

CC=gcc
CFLAGS=-g -Wall -O3
LDFLAGS=-lrt -lm

clean:
	rm -f *.o *.elf _impactbatch.log codec_server pmtest pmencode\
 pmdecode

codec_server: decoder.o histogram.o tree.o decoder_server.o encoder_server.o\
 codec_server.o encoder.o codebook.o package_merge.o canonical.o

pmtest: pmtest.o package_merge.o histogram.o

pmencode: pmencode.o package_merge.o histogram.o codebook.o canonical.o\
 encoder.o tree.o

pmdecode: pmdecode.o codebook.o canonical.o decoder.o tree.o decoder_flat.o\
 codebook_flat.o decoder_flat.o

huffman_network: huffman_network.o encoder_thread.o network_io.o histogram.o\
 canonical.o tree.o codebook.o encoder.o package_merge.o decoder.o\
 decoder_thread.o codebook_flat.o decoder_flat.o util.o histogram_thread.o

huffman_carray: huffman_carray.o encoder_thread.o carray_io.o histogram.o\
 canonical.o tree.o codebook.o encoder.o package_merge.o decoder.o\
 decoder_thread.o codebook_flat.o decoder_flat.o util.o histogram_thread.o

deps:
	$(CC) -MM *.c  $(CFLAGS) > .deps

include .deps

.PHONY: clean deps mrproper setup help all

