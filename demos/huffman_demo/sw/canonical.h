#ifndef CANONICAL_H
#define CANONICAL_H

#ifdef USE_ECOS
#include <sys/types.h>
#else
#include <stdint.h>
#endif

#include "codebook.h"

void ccodebook_create(struct Codebook *cb, const uint8_t *codelen);
void ctree_create(struct Tree *t, const uint8_t *codelen);

#endif

