#include "codebook_flat.h"

void codebook_flat_create(struct CodebookFlat *flat, struct Codebook *cb){
	int i;
	for(i = 0; i < 256; i++){
		uint16_t code = (cb->entries[i].code[1] << 8) | cb->entries[i].code[0];
		int n = cb->entries[i].num_bits;
		int m = 16 - n;
		int j;
		
		if(n == 0) continue;
		
		for(j = 0; j < (1 << m); j++){
			flat->symbol[j << n | code] = i;
			flat->shift[j << n | code] = n;
		}
	}
}

