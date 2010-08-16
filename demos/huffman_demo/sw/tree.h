#ifndef TREE_H
#define TREE_H

#include "histogram.h"

#ifdef USE_ECOS
#include <sys/types.h>
#else
#include <stdint.h>
#endif


// a node of the fully connected huffman tree
struct Node
{
	uint8_t parent;     // 8 bit are enough to address all parent nodes
	uint16_t child[2];  // child nodes are addressed in two modes:
	                    //  - addresses below 0x100 point to internal nodes
	                    //  - addressed above 0x100 represent symbols
	                    //    the symbol can be retrieved by subtracting
	                    //    0x100 from the address value.
};

// complete huffman tree
struct Tree
{
	struct Node nodes[256]; // the internal nodes of the tree
	uint8_t root;           // index of the root node
};

// create a new tree from the sortes histogram sh
void tree_create(struct Tree * t, struct SortedHistogram16 * sh);

// print out tree t (debug function)
void tree_print(struct Tree * t, FILE * fout);

void tree_print_flat(struct Tree * t, FILE * fout);

#endif

