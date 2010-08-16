#include "codebook.h"
#include <string.h>

static void codebook_entry_append_bit(struct CodebookEntry * cbe, int bit)
{
	int byte_pos = cbe->num_bits / 8;
	int bit_pos = cbe->num_bits % 8;
	int mask = (bit & 0x01) << bit_pos;
	cbe->code[byte_pos] |= mask;
	cbe->num_bits++;
}

static void populate(struct Codebook * cb, struct Tree * t, int node,
		struct CodebookEntry cbe)
{
	struct Node * n = t->nodes + node;
	int c;
	
	for(c = 0; c < 2; c++){
		struct CodebookEntry tmp = cbe;
		codebook_entry_append_bit(&tmp,c);
		if(n->child[c] > 0xFF){
			int sym = n->child[c] & 0xFF;
			cb->entries[sym] = tmp;
		}
		else{
			populate(cb, t, n->child[c], tmp);
		}
	}
}

void codebook_create(struct Codebook * cb, struct Tree * t)
{
	int i;
	struct CodebookEntry cbe;
	
	cbe.num_bits = 0;
	for(i = 0; i < CODEBOOK_ENTRY_BYTES; i++) cbe.code[i] = 0x00;
	
	for(i = 0; i < 256; i++){
		cb->entries[i].num_bits = 0;
		memset(cb->entries[i].code, 0, CODEBOOK_ENTRY_BYTES);
	}
	
	populate(cb, t, t->root, cbe);
}

void codebook_print(struct Codebook * cb, FILE * fout)
{
	int i;
	for(i = 0; i < 256; i++){
		int j;
		fprintf(fout,"%02X: ", i);
		for(j = CODEBOOK_ENTRY_BYTES; j >= 0; j--){
			fprintf(fout,"%02X",cb->entries[i].code[j]);
		}
		fprintf(fout, " (%d)\n", cb->entries[i].num_bits);
	}
}

