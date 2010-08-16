#ifndef ENCODER_H
#define ENCODER_H

#include "codebook.h"

#define ENCODER_NEED_INPUT 0xFFFFFFFF

// encoder state. do not access directly
struct Encoder
{
	uint8_t buffer;          // 8-bit output buffer
	int buffer_pos;          // current address in output buffer
	int symbol;              // current input symbol
	int bit_pos;             // address in codebook entry
	struct Codebook * cb;    // current codebook entry
};

// initializes encoder and associates it with the codebook cb
void encoder_init(struct Encoder * enc, struct Codebook * cb);

// supplies the next input symbol to the encoder
void encoder_put_symbol(struct Encoder * enc, uint8_t symbol);

// retrieve one byte of code. A return value of ENCODER_NEED_INPUT
// indicates, that the next symbol can be passed to the encoder
int encoder_get_byte(struct Encoder * enc);

// returns the last (incomplete) byte of code. since there may be less than
// 8 bits available, the result may be padded with zeros.
// Returns ENCODER_NEED_INPUT if there are no output bits available.
int encoder_get_last_byte(struct Encoder * enc);

#endif

