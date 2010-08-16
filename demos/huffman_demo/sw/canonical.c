#include "canonical.h"

static uint16_t reorder_bits(uint16_t n, int k){
	int i;
	uint16_t res = 0;
	
	for(i = 0; i < k; i++){
		res = (res << 1) | (n & 0x01);
		n = n >> 1;
	}
	
	return res;
}

void ccodebook_create(struct Codebook *cb, const uint8_t *codelen){
	int counter = 0;
	int i,j;
	
	for(i = 0; i < 256; i++){
		for(j = 0; j < CODEBOOK_ENTRY_BYTES; j++){
			cb->entries[i].code[j] = 0;
		}
		cb->entries[i].num_bits = 0;
	}
	
	for(j = 16; j >= 1; j--){
		for(i = 0; i < 128; i++){
			uint8_t a = codelen[i] & 0x0F;
			uint8_t b = codelen[i] >> 4;
			if(a == j){
				uint16_t tmp = reorder_bits(counter,j);
				cb->entries[i*2].code[0] = tmp & 0xFF;
				cb->entries[i*2].code[1] = tmp >> 8;
				cb->entries[i*2].num_bits = j;
				counter++;
			}
			if(b == j){
				uint16_t tmp = reorder_bits(counter,j);
				cb->entries[i*2 + 1].code[0] = tmp & 0xFF;
				cb->entries[i*2 + 1].code[1] = tmp >> 8;
				cb->entries[i*2 + 1].num_bits = j;
				counter++;
			}
		}
		counter = (counter >> 1) + 1;
	}
}

void ctree_create(struct Tree *t, const uint8_t *codelen){
	int i,j,tmp;
	int nodes[256];
	int num_nodes = 0;
	for(i = 0; i < 256; i++){
		t->nodes[i].parent = 0x00;
		t->nodes[i].child[0] = 0x100;
		t->nodes[i].child[1] = 0.100;
	}
	t->root = 0;
	for(j = 16; j > 0; j--){
		//fprintf(stderr,"j = %d, num_nodes = %d\n",j,num_nodes);
		
		for(i = 0; i < 128; i++){
			uint8_t a = codelen[i] & 0x0F;
			uint8_t b = codelen[i] >> 4;
			if(a == j){
				nodes[num_nodes++] = (i*2) | 0x100;
				//fprintf(stderr,":= nodes[%d] = %d\n", num_nodes - 1, nodes[num_nodes - 1]);
			}
			if(b == j){
				nodes[num_nodes++] = (i*2 + 1) | 0x100;
				//fprintf(stderr,":= nodes[%d] = %d\n", num_nodes - 1, nodes[num_nodes - 1]);
			}
		}
		tmp = 0;
		for(i = tmp; i < num_nodes - 1; i += 2){
			t->nodes[t->root].child[0] = nodes[i];
			t->nodes[t->root].child[1] = nodes[i + 1];
			//fprintf(stderr,"nodes[%d] = %d\n", i, nodes[i]);
			//fprintf(stderr,"nodes[%d] = %d\n", i + 1, nodes[i + 1]);
			if(nodes[i] < 0x100){
				t->nodes[nodes[i]].parent = t->root;
			}
			if(nodes[i + 1] < 0x100){
				t->nodes[nodes[i + 1]].parent = t->root;
			}
			nodes[tmp++] = t->root;
			t->root++;
		}
		num_nodes = tmp;
	}
	t->root--;
}

