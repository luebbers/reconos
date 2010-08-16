#ifndef CODEBOOK_FLAT_H
#define CODEBOOK_FLAT_H

#include "codebook.h"

struct CodebookFlat
{
	uint8_t symbol[65536];
	uint8_t shift[65536];
};

void codebook_flat_create(struct CodebookFlat *flat, struct Codebook *cb);

#endif

