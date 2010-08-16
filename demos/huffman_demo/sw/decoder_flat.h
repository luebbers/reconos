#ifndef DECODER_FLAT_H
#define DECODER_FLAT_H

#include "codebook_flat.h"
#include "decoder.h"

struct DecoderFlat
{
	struct CodebookFlat *cb_flat;
	uint32_t buffer;
	int buffer_fill;
};

// initializes decoder with tree t
void decoder_flat_init(struct DecoderFlat * dec, struct CodebookFlat *cb);

// this function supplies the decoder with the next input byte
void decoder_flat_put_byte(struct DecoderFlat * dec, uint8_t byte);

// returns next decoded symbol or DECODER_NEED_INPUT, which indicates
// that the next input byte can be processed (see decoder_put_byte())
int decoder_flat_get_symbol(struct DecoderFlat * dec);

#endif

