#ifndef CODEBOOK_H
#define CODEBOOK_H

#include "tree.h"
#include <stdio.h>

#ifdef USE_ECOS
#include <sys/types.h>
#else
#include <stdint.h>
#endif


#define CODEBOOK_ENTRY_BYTES 32

// codebook vector data structure
struct CodebookEntry
{
	uint8_t num_bits;                    // number of bits in this entry
	uint8_t code[CODEBOOK_ENTRY_BYTES];  // code vector
};

// the codebook is just a collection of codebook entries
struct Codebook
{
	struct CodebookEntry entries[256];
};

// creates a new codebook from tree t
void codebook_create(struct Codebook * cb, struct Tree * t);

// prints out the codebook (debug function)
void codebook_print(struct Codebook * cb, FILE * fout);

#endif


