#include "decoder_flat.h"

void decoder_flat_init(struct DecoderFlat * dec, struct CodebookFlat *cb){
	dec->cb_flat = cb;
	dec->buffer = 0;
	dec->buffer_fill = 0;
}

// this function supplies the decoder with the next input byte
void decoder_flat_put_byte(struct DecoderFlat * dec, uint8_t byte){
	uint32_t tmp = byte;
	tmp <<= dec->buffer_fill;
	dec->buffer |= tmp;
	dec->buffer_fill += 8;
	//fprintf(stderr,"adding byte %02X to buffer -> fill = %d\n",
	//		byte, dec->buffer_fill);
}

// returns next decoded symbol or DECODER_NEED_INPUT, which indicates
// that the next input byte can be processed (see decoder_put_byte())
int decoder_flat_get_symbol(struct DecoderFlat * dec){
	int shift, symbol;
	
	//fprintf(stderr,"buffer: 0x%08X fill: %d, shift: %d, sym: %02X\n",
	//		dec->buffer, dec->buffer_fill,
	//		dec->cb_flat->shift[dec->buffer & 0xFFFF],
	//		dec->cb_flat->symbol[dec->buffer & 0xFFFF]);
	
	shift = dec->cb_flat->shift[dec->buffer & 0xFFFF];
	if(shift > dec->buffer_fill) return DECODER_NEED_INPUT;
	
	symbol = dec->cb_flat->symbol[dec->buffer & 0xFFFF];
	dec->buffer >>= shift;
	dec->buffer_fill -= shift;
	
	//fprintf(stderr,"-> %02X\n", symbol);
	
	return symbol;
}

