#include "decoder.h"

void decoder_init(struct Decoder * dec, struct Tree * t)
{
	dec->tree = t;
	dec->buffer = 0;
	dec->buffer_pos = 8;
	dec->node = t->root;
}

void decoder_put_byte(struct Decoder * dec, uint8_t byte)
{
	dec->buffer = byte;
	dec->buffer_pos = 0;
}

int decoder_get_symbol(struct Decoder * dec)
{
	while(1){
		struct Node * n = dec->tree->nodes + dec->node;
		int bit;
		
		if(dec->buffer_pos > 7) return DECODER_NEED_INPUT;
		bit = (dec->buffer & (1 << dec->buffer_pos)) ? 1 : 0;
		
		dec->buffer_pos = dec->buffer_pos + 1;
		
		if(n->child[bit] > 0xFF){
			dec->node = dec->tree->root;
			return n->child[bit] & 0xFF;
		}
		else {
			dec->node = n->child[bit];
		}
	}
}

