#include "encoder.h"

void encoder_init(struct Encoder * enc, struct Codebook * cb)
{
	enc->cb = cb;
	enc->symbol = -1;
	enc->bit_pos = 0;
	enc->buffer = 0;
	enc->buffer_pos = 0;
}

void encoder_put_symbol(struct Encoder * enc, uint8_t symbol)
{
	enc->symbol = symbol;
	enc->bit_pos = 0;
}

int encoder_get_byte(struct Encoder * enc)
{
	struct CodebookEntry * cbe = enc->cb->entries + enc->symbol;
	
	while(1){
		int byte_pos = enc->bit_pos / 8;
		int bit_offset = enc->bit_pos % 8;
		
		if(enc->bit_pos >= cbe->num_bits){
			return ENCODER_NEED_INPUT;
		}
		int bit = (cbe->code[byte_pos] & (1 << bit_offset)) ? 1 : 0;
		
		enc->buffer |= (bit << enc->buffer_pos);
		enc->buffer_pos = (enc->buffer_pos + 1) % 8;
		enc->bit_pos++;
		
		if(enc->buffer_pos == 0){
			int result = enc->buffer;
			enc->buffer = 0;
			return result;
		}
	}
}

int encoder_get_last_byte(struct Encoder * enc)
{
	int result;
	
	if(enc->buffer_pos == 0) return ENCODER_NEED_INPUT;
	
	enc->buffer_pos = 0;
	
	result = enc->buffer;
	enc->buffer = 0;
	
	return result;
}

