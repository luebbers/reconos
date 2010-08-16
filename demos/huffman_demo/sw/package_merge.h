#ifndef PACKAGE_MERGE_H
#define PACKAGE_MERGE_H

#ifdef USE_ECOS
#include <sys/types.h>
#else
#include <stdint.h>
#endif

#include "histogram.h"

double weight_of_tree(const uint8_t *codelen);
void package_merge(const struct Histogram32 * h32, int L, uint8_t *codelen);
void package_merge2(const struct Histogram16 * h16, int L, uint8_t *codelen);

#endif

