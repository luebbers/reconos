#include "tree.h"

struct InternalNode
{
	uint16_t symbol;
	uint32_t frequency;
	uint8_t parent;
	uint16_t child[2];
};
		    
void tree_create(struct Tree * t, struct SortedHistogram16 * sh)
{
	struct InternalNode *node_A;     // nodes to dequeue
	struct InternalNode *node_B;     //
	struct InternalNode tmp_node;    // temporary node used for enqueuing

	static struct InternalNode leaf_nodes[256];
	static struct InternalNode nodes[256];
	
	int leaves = 0;
	int head   = 0;
	int tail   = 0;
	int i;
	
	for(i = 0; i < 256; i++){
		nodes[i].symbol = i;
		nodes[i].frequency = 0;
		nodes[i].parent = 0;
		leaf_nodes[i].symbol = sh->entries[i].symbol | 0x100;
		leaf_nodes[i].frequency = sh->entries[i].frequency;
		leaf_nodes[i].parent = 0;
		t->nodes[i].parent = 0;
	}
	
	if(sh->entries[0].frequency == 0) return;


	for(i = 255; i >= 0; i--){
		if(sh->entries[i].frequency != 0){
			leaves = i;
			break;
		}
	}
	
	
	// nested function to dequeue the lowest element from one of the two
	// queues
	struct InternalNode * dequeue_lowest(  ) {
		if ( head == tail ) {   // node queue empty
			return &leaf_nodes[leaves--];
		} else if ( leaves == 0 ) {    // no leaves left
			return &nodes[head++];
		} else if ( leaf_nodes[leaves].frequency <= nodes[head].frequency ) {
			return &leaf_nodes[leaves--];
		} else {
			return &nodes[head++];
		}
	}

	// nested function to enqueue a new element to the internal node queue
	void enqueue( struct InternalNode * n ) {
		nodes[tail++] = *n;
	}

	// while more than one node in queues:
	while ( leaves >= 0 || tail != head + 1 ) {
		// dequeue two nodes with lowest weight
		node_A = dequeue_lowest();
		node_B = dequeue_lowest();
		// create new node
		//printf("combining nodes %03X and %03X -> %03X\n",
		//		node_A->symbol, node_B->symbol, tail); 
		tmp_node.child[0] = node_A->symbol;
		tmp_node.child[1] = node_B->symbol;
		tmp_node.frequency = node_A->frequency + node_B->frequency;
		tmp_node.symbol = tail;
		tmp_node.parent = 0;
		// link the two nodes to the new node
		node_A->parent = tail;
		node_B->parent = tail;
		// enqueue new node in rear of second queue
		enqueue( &tmp_node );
	}
	
	for(i = 0; i < 256; i++){
		t->nodes[i].parent = nodes[i].parent;
		t->nodes[i].child[0] = nodes[i].child[0];
		t->nodes[i].child[1] = nodes[i].child[1];
	}
	
	t->root = tail - 1;
}

static void print_subtree(struct Tree *t, struct Node * n, int l, FILE * fout)
{
	int i;
	for(i = 0; i < l; i++){
		fprintf(fout," ");
	}
	
	fprintf(fout,"#\n");
	
	if(n->child[0] > 0xFF){
		for(i = 0; i < l + 1; i++){
			fprintf(fout," ");
		}
		fprintf(fout,"%02X '%c'\n", n->child[0] & 0xFF, n->child[0] & 0xFF);
	}
	else{
		print_subtree(t, t->nodes + n->child[0], l + 1, fout);
	}
	
	if(n->child[1] > 0xFF){
		for(i = 0; i < l + 1; i++){
			printf(" ");
		}
		fprintf(fout,"%02X '%c'\n", n->child[1] & 0xFF, n->child[1] & 0xFF);
	}
	else{
		print_subtree(t, t->nodes + n->child[1], l + 1, fout);
	}
}

void tree_print(struct Tree * t, FILE * fout)
{
	print_subtree(t, t->nodes + t->root, 0, fout);
}

void tree_print_flat(struct Tree * t, FILE * fout){
	int i;
	for(i = 0; i < 256; i++){
		struct Node * n = t->nodes + i;
		fprintf(fout, "node %d: parent = %d, children = %d,%d\n",
				i,n->parent, n->child[0], n->child[1]);
	}
	fprintf(stderr,"root = %d\n", t->root);
}

/*
void tree_print(struct Tree * t, FILE * fout)
{
	int i;
	for(i = 0; i < 256; i++){
		fprintf(fout,"Node %02X -> (%03X,%03X)\n",
				i, t->nodes[i].child[0], t->nodes[i].child[1]);
	}
}
*/
