#include <stdio.h>
#include <stdlib.h>

#ifdef USE_ECOS
#include <sys/types.h>
#else
#include <stdint.h>
#endif

#include "histogram.h"
#include "package_merge.h"
#include "codebook.h"
#include "encoder.h"
#include "canonical.h"

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

double compr_factor(uint8_t *text, int len, uint8_t *codelen){
	int i;
	int bits = 0;
	for(i = 0; i < len; i++){
		if(text[i] % 2 == 0){
			bits += codelen[text[i]/2] & 0x0F;
		}
		else {
			bits += codelen[text[i]/2] >> 4;
		}
	}
	return bits/(double)len/8;
}

int main(int argc, char **argv)
{
	uint8_t codelen[128];
	struct Histogram32 h32;
	struct Codebook cb;
	struct Encoder enc;
	struct Tree tree;
	FILE *fout;
	int i,L;
	
	if(argc == 1) L = 16;
	//else if(argv == 2) L = atoi(argv[1]);
	else{
		fprintf(stderr,"Usage: %s\n", argv[0]);
		fprintf(stderr,"\treads input data from stdin, compresses it using\n");
		fprintf(stderr,"\tlength-restricted canonical huffman codes and writes\n");
		fprintf(stderr,"\tthe result to 'enc.out'.\n");
		exit(1);
	}
	
	read_text(stdin);
	
	histogram32_init(&h32);
	histogram32_add(&h32, buffer, buffer_fill);
	
	package_merge(&h32, L, codelen);
	//printf("final codelengths:\n");
	//codelen_dump(codelen, stdout);
	
	fprintf(stderr,"weight of huffman tree = %f\n", weight_of_tree(codelen));
	fprintf(stderr,"compression factor = %.11f\n",compr_factor(buffer,buffer_fill,codelen));
	
	ctree_create(&tree, codelen);
	//tree_print_flat(&tree,stderr);
	//ccodebook_create(&cb, codelen);
	codebook_create(&cb,&tree);
	//codebook_print(&cb,stderr);
	
	
	
	encoder_init(&enc, &cb);
	
	fout = fopen("enc.out","w");
	
	fwrite(&buffer_fill,4,1,fout);
	fwrite(codelen,128,1,fout);
	
	for(i = 0; i < buffer_fill; i++){
		int c;
		//fprintf(stderr,"byte %d of %d\n",i,buffer_fill);
		encoder_put_symbol(&enc, buffer[i]);
		while((c = encoder_get_byte(&enc)) != ENCODER_NEED_INPUT){
			uint8_t tmp = c;
			fwrite(&tmp,1,1,fout);
		}
	}
	
	i = encoder_get_last_byte(&enc);
	if(i != ENCODER_NEED_INPUT){
		uint8_t tmp = i;
		fwrite(&tmp,1,1,fout);
	}
	
	fclose(fout);
	
	return 0;
}

