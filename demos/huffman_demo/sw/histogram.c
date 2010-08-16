#include "histogram.h"
#include <stdlib.h>
#include <math.h>

#ifdef USE_ECOS
#include <network.h>
#include <netinet/in.h>
#endif

#include <arpa/inet.h>

void histogram32_init(struct Histogram32 * h)
{
	int i;
	for(i = 0; i < 256; i++){
		h->buckets[i] = 0;
	}
}

void histogram32_add(struct Histogram32 * h, unsigned char * syms, size_t len)
{
	size_t i;
	for(i = 0; i < len; i++){
		h->buckets[syms[i]]++;
	}
}

void histogram32to16(struct Histogram32 * in, struct Histogram16 * out)
{
	uint32_t fmax;
	int shift, i;
	
	// find maximum symbol frequency
	fmax = in->buckets[0];
	for(i = 1; i < 256; i++){
		if(in->buckets[i] > fmax) fmax = in->buckets[i];
	}
	
	// how many bits to shift?
	for(shift = 0; shift < 32 && fmax >= (1 << 16); shift++){
		fmax = fmax >> 1;
	}
	
	// scale histogram
	for(i = 0; i < 256; i++){
		out->buckets[i] = in->buckets[i] >> shift;
		// prevent positive symbol frequencies to be shifted to 0
		if(out->buckets[i] == 0 && in->buckets[i] > 0){
			out->buckets[i] = 1;
		}
	}
}

/*
static int cmp(const void * a, const void * b)
{
	const struct SortedHistogram16Entry * ea = a;
	const struct SortedHistogram16Entry * eb = b;
	
	return ea->frequency < eb->frequency;
}
*/

void histogram16_sort(struct Histogram16 * in, struct SortedHistogram16 * out)
{
	int swapped = 1;
	unsigned int i, n, n_new;
	struct SortedHistogram16Entry temp;
	
	for(i = 0; i < 256; i++){
		out->entries[i].frequency = in->buckets[i];
		out->entries[i].symbol = i;
	}

	n = 255;
	n_new = n;

	while ( swapped ) {
		swapped = 0;
		for ( i = 0; i < n; i++ ) {
			if ( out->entries[i].frequency < out->entries[i + 1].frequency ) {
				temp = out->entries[i];
				out->entries[i] = out->entries[i + 1];
				out->entries[i + 1] = temp;
				n_new = i;
				swapped = 1;
			}
		}
		n = n_new;
	}
	
	//qsort(out->entries, 256, sizeof out->entries[0], cmp);
}

void histogram32_print(struct Histogram32 * h, FILE * fout)
{
	int i;
	for(i = 0; i < 256; i++){
		printf("0x%02X: % 5d\n", i, h->buckets[i]);
	}
}

void histogram16_print(struct Histogram16 * h, FILE * fout)
{
	int i;
	for(i = 0; i < 256; i++){
		printf("0x%02X: % 5d\n", i, h->buckets[i]);
	}
}

void sorted_histogram16_print(struct SortedHistogram16 * h, FILE * fout)
{
	int i;
	for(i = 0; i < 256; i++){
		//if(h->entry.frequency == 0) break;
		printf("0x%02X: % 5d\n", h->entries[i].symbol, h->entries[i].frequency);
	}
}

int histogram16_write(struct Histogram16 * h, FILE * fout)
{
	int i;
	for(i = 0; i < 256; i++){
		int r;
		uint16_t n = htons(h->buckets[i]);
		
		r = fwrite(&n, 2, 1, fout);
		if(r == -1) return 0;
	}
	return 1;
}

int histogram16_read(struct Histogram16 * h, FILE * fin)
{
	int i;
	for(i = 0; i < 256; i++){
		int r;
		uint16_t n;
		
		r = fread(&n, 2, 1, fin);
		if(r == -1) return 0;
		
		h->buckets[i] = ntohs(n);
	}
	return 1;
}

double histogram32_entropy(struct Histogram32 * h)
{
	double result = 0;
	double total = 0;
	double log2 = log(2.0);
	int i;
	
	for(i = 0; i < 256; i++){
		total += h->buckets[i];
	}
	for(i = 0; i < 256; i++){
		if(h->buckets[i] == 0) continue;
		double p = h->buckets[i]/total;
		result -= p*log(p)/log2;
	}
	
	return result;
}

