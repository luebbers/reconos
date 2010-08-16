#ifndef HISTOGRAM_H
#define HISTOGRAM_H

#ifdef USE_ECOS
#include <sys/types.h>
#else
#include <stdint.h>
#endif

#include <stdio.h>

// histogram with 32 bit precission
struct Histogram32
{
	uint32_t buckets[256];
};

// histogram with 16 bit precission
struct Histogram16
{
	uint16_t buckets[256];
};

// symbol and frequency make up an entry of the sorted histogram
struct SortedHistogram16Entry
{
	uint8_t symbol;
	uint16_t frequency;
};

// the entries are sorted in decreasing order of the symbol frequencies
struct SortedHistogram16
{
	struct SortedHistogram16Entry entries[256];
};

// initializes an empty histogram
void histogram32_init(struct Histogram32 * h);
void histogram32_add(struct Histogram32 * h, unsigned char * syms, size_t len);

// converts (scales) a 32-bit histogram to a 16-bit histogram
void histogram32to16(struct Histogram32 * in, struct Histogram16 * out);

// takes histogram 'in' and sorts it according to symbol frequencies
// returns the sorted histogram in 'out'.
void histogram16_sort(struct Histogram16 * in, struct SortedHistogram16 * out);

// print histograms (debug functions)
void histogram32_print(struct Histogram32 * h, FILE * fout);
void histogram16_print(struct Histogram16 * h, FILE * fout);
void sorted_histogram16_print(struct SortedHistogram16 * h, FILE * fout);

// writes histogram to file 'fout' (binary)
int histogram16_write(struct Histogram16 * h, FILE * fout);

// reads histogram from file 'fin' (binary)
int histogram16_read(struct Histogram16 * h, FILE * fin);

double histogram32_entropy(struct Histogram32 * h);

#endif

