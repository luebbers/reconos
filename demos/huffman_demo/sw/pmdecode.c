#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "tree.h"
#include "canonical.h"
#include "decoder.h"
#include "decoder_flat.h"
#include "codebook.h"
#include "codebook_flat.h"

// define this macro in order to use the flat decoder
#define FLAT_DECODER

#define BUFFER_SIZE_MAX (1024*1024*1024)

unsigned char buffer[BUFFER_SIZE_MAX];
int buffer_fill;

void read_text(FILE * fin){
	int c;
	buffer_fill = 0;
	while((c = fgetc(fin)) != EOF){
		if(buffer_fill >= BUFFER_SIZE_MAX){
			fprintf(stderr,"Buffer Overflow!\n");
			exit(1);
		}
		buffer[buffer_fill++] = c;
	}
}

int main(int argc, char **argv)
{
	FILE *fin, *fout;
	uint8_t codelen[128];
	int count, i;
	
	struct Tree tree;
#ifdef FLAT_DECODER
	struct Codebook cb;
	struct CodebookFlat cb_flat;
	struct DecoderFlat dec_flat;
#else
	struct Decoder dec;
#endif

	if(argc != 1){
		fprintf(stderr,"Usage: %s\n", argv[0]);
		fprintf(stderr,"decodes the file 'enc.out' and writes it to 'dec.out'\n");
		exit(1);
	}
	
	fout = fopen("dec.out","w");
	fin = fopen("enc.out","r");
	fread(&count,4,1,fin);
	fread(codelen,128,1,fin);
	
	ctree_create(&tree, codelen);
	read_text(fin);
	
#ifdef FLAT_DECODER
	codebook_create(&cb, &tree);
	codebook_flat_create(&cb_flat, &cb);
	decoder_flat_init(&dec_flat, &cb_flat);

	for(i = 0; i < buffer_fill; i++){
		uint8_t tmp = buffer[i];
		int sym;
		decoder_flat_put_byte(&dec_flat,tmp);
		while((sym = decoder_flat_get_symbol(&dec_flat)) != DECODER_NEED_INPUT){
			tmp = sym;
			fwrite(&tmp,1,1,fout);
			count--;
		}
	}
#else
	decoder_init(&dec,&tree);
	
	for(i = 0; i < buffer_fill; i++){
		uint8_t tmp = buffer[i];
		int sym;
		decoder_put_byte(&dec,tmp);
		while((sym = decoder_get_symbol(&dec)) != DECODER_NEED_INPUT){
			tmp = sym;
			fwrite(&tmp,1,1,fout);
			count--;
		}
	}
#endif
	fclose(fin);
	fclose(fout);
	
	return 0;
}
