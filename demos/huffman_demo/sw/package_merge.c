#include <stdio.h>
#include <stdlib.h>

#include "histogram.h"
#include "package_merge.h"

struct Package
{
	uint8_t coins[16*256];
	int total_freq;
	int num_coins;
};

struct PackageList
{
	struct Package pkgs[2*256];
	int num_pkgs;
};

void package_dump(struct Package *pkg, FILE *fout){
	int i;
	for(i = 0; i < pkg->num_coins; i++){
		fprintf(fout, "'%c' ", pkg->coins[i]);
	}
	fprintf(fout, " -> %d:%d\n", pkg->num_coins, pkg->total_freq);
}

void package_list_dump(struct PackageList *pl, FILE *fout){
	int i;
	for(i = 0; i < pl->num_pkgs; i++){
		package_dump(pl->pkgs + i, fout);
	}
}

static int cmp(const void *a, const void *b){
	const struct Package *pa = a;
	const struct Package *pb = b;
	return pa->total_freq - pb->total_freq;
}

static void init_package_list(struct PackageList *pl, const struct Histogram32 *h32){
	int i;
	pl->num_pkgs = 0;
	for(i = 0; i < 256; i++){
		if(h32->buckets[i] == 0) continue;
		pl->pkgs[pl->num_pkgs].coins[0] = i;
		pl->pkgs[pl->num_pkgs].total_freq = h32->buckets[i];
		pl->pkgs[pl->num_pkgs].num_coins = 1;
		pl->num_pkgs++;
	}
	qsort(pl->pkgs,pl->num_pkgs,sizeof *(pl->pkgs),cmp);
}


static void init_package_list2(struct PackageList *pl, const struct Histogram16 *h16){
	int i;
	pl->num_pkgs = 0;
	for(i = 0; i < 256; i++){
		if(h16->buckets[i] == 0) continue;
		pl->pkgs[pl->num_pkgs].coins[0] = i;
		pl->pkgs[pl->num_pkgs].total_freq = h16->buckets[i];
		pl->pkgs[pl->num_pkgs].num_coins = 1;
		pl->num_pkgs++;
	}
	qsort(pl->pkgs,pl->num_pkgs,sizeof *(pl->pkgs),cmp);
}

// dst = dst + src
static void package_add(struct Package * dst, const struct Package * src){
	int i;
	for(i = 0; i < src->num_coins; i++){
		dst->coins[dst->num_coins + i] =src->coins[i];
	}
	dst->num_coins += src->num_coins;
	dst->total_freq += src->total_freq;
}

static void package(struct PackageList *plout, const struct PackageList *plin){
	int i;
	plout->num_pkgs = plin->num_pkgs/2;
	for(i = 0; i < plout->num_pkgs; i++){
		plout->pkgs[i] = plin->pkgs[i*2];
		package_add(plout->pkgs + i, plin->pkgs + i*2 + 1);
	}
}

static void merge(struct PackageList *out, const struct PackageList *a, const struct PackageList *b){
	int i,idx_a,idx_b;
	out->num_pkgs = a->num_pkgs + b->num_pkgs;
	idx_a = idx_b = 0;
	for(i = 0; i < out->num_pkgs; i++){
		if(idx_b >= b->num_pkgs
		|| a->pkgs[idx_a].total_freq < b->pkgs[idx_b].total_freq){
			out->pkgs[i] = a->pkgs[idx_a++];
		}
		else{
			out->pkgs[i] = b->pkgs[idx_b++];
		}
	}
}

static void get_codelen(const struct PackageList * pl, uint8_t *codelen)
{
	int i,j;
	uint8_t tmp[256];
	for(i = 0; i < 256; i++) tmp[i] = 0;
	for(i = 0; i < pl->num_pkgs; i++){
		const struct Package *pkg = pl->pkgs + i;
		for(j = 0; j < pkg->num_coins; j++){
			tmp[pkg->coins[j]]++;
		}
	}
	for(i = 0; i < 128; i++){
		codelen[i] = tmp[i*2] | (tmp[i*2 + 1] << 4);
	}
}

void codelen_dump(const uint8_t *codelen, FILE *fout){
	int i;
	for(i = 0; i < 128; i++){
		uint8_t a = codelen[i] & 0x0F;
		uint8_t b = codelen[i] >> 4;
		if(a) fprintf(fout,"'%c': %d\n",i*2,a);
		if(b) fprintf(fout,"'%c': %d\n",i*2 + 1, b);
	}
}

double weight_of_tree(const uint8_t *codelen){
	double result = 0.0;
	int i;
	for(i = 0; i < 128; i++){
		uint8_t a = codelen[i] & 0x0F;
		uint8_t b = codelen[i] >> 4;
		
		if(a) result += 1.0/(1 << a);
		if(b) result += 1.0/(1 << b);
	}
	
	return result;
}

void package_merge(const struct Histogram32 * h32, int L, uint8_t *codelen){
	int i;

	static struct PackageList initial;
	static struct PackageList current;
	static struct PackageList tmp;
	
	init_package_list(&initial, h32);
	current = initial;
	tmp.num_pkgs = 0;
	
	package(&tmp, &current);
	L--;
	
	for(i = 0; i < L; i++){
		merge(&current, &tmp, &initial);
		package(&tmp, &current);
	}
	
	get_codelen(&tmp, codelen);
}

void package_merge2(const struct Histogram16 * h16, int L, uint8_t *codelen){
	int i;

	static struct PackageList initial;
	static struct PackageList current;
	static struct PackageList tmp;
	
	init_package_list2(&initial, h16);
	current = initial;
	tmp.num_pkgs = 0;
	
	package(&tmp, &current);
	L--;
	
	for(i = 0; i < L; i++){
		merge(&current, &tmp, &initial);
		package(&tmp, &current);
	}
	
	get_codelen(&tmp, codelen);
}

