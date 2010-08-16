#ifndef DECODER_H
#define DECODER_H

#include "tree.h"

#define DECODER_NEED_INPUT 0xFFFFFFFF

// decoder state. do not access directly
struct Decoder
{
	struct Tree * tree;  // tree used for decoding
	uint8_t buffer;      // 8-bit input buffer
	int buffer_pos;      // current buffer address (bit)
	int node;            // current node in decode tree
};

// initializes decoder with tree t
void decoder_init(struct Decoder * dec, struct Tree * t);

// this function supplies the decoder with the next input byte
void decoder_put_byte(struct Decoder * dec, uint8_t byte);

// returns next decoded symbol or DECODER_NEED_INPUT, which indicates
// that the next input byte can be processed (see decoder_put_byte())
int decoder_get_symbol(struct Decoder * dec);

#endif

