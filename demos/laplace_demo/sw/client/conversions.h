/***************************************************************************
 * conversions.h: Various color space conversions 
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#ifndef CONVERSIONS_H
#define CONVERSIONS_H

#include <math.h>
#include <stdlib.h>
#include <string>
#include <sstream>
#include <stdint.h>

#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) < (b) ? (a) : (b))

#define HUE_MAX 255
#define HUE_DELTA (HUE_MAX/6)


// VIDEO MODE INDEPENDANT ***********
static void rgb_to_hsv(int r, int g, int b, int *h, int *s, int *v){

	int rgb_max = MAX(r,g);
	rgb_max = MAX(rgb_max,b);
	
	int rgb_min = MIN(r,g);
	rgb_min = MIN(rgb_min,b);
	
	if(rgb_max == rgb_min || !rgb_max) return;
	
	if(rgb_max == r){
		if(g >= b){
			*h = HUE_DELTA*(g - b)/(rgb_max - rgb_min);
		}
		else{
			*h = HUE_DELTA*(g - b)/(rgb_max - rgb_min) + HUE_MAX;
		}
	}
	else if(rgb_max == g){
		*h = HUE_DELTA*(b - r)/(rgb_max - rgb_min) + HUE_DELTA*2;
	}
	else{
		*h = HUE_DELTA*(r - g)/(rgb_max - rgb_min) + HUE_DELTA*4;
	}
	
	*s = (rgb_max - rgb_min)*255/rgb_max;
	*v = rgb_max;
}

int hue_delta(int h1, int h2){
	int res_a = h1 - h2;
	
	int res_b = res_a;
	
	if(h2 < h1) res_b = h1 - h2 - HUE_MAX;
	else if(h1 < h2) res_b = h1 + HUE_MAX - h2;
	
	if(abs(res_a) < abs(res_b)) return res_a;
	return res_b;
}

int hsv_to_p(int h, int s ,int v, int h_obj, int s_obj){
	if(s < 25) return 0;
	if(v < 25) return 0;
	
	int ds = abs(s - s_obj) + 1;
	
	int res = 2*ds + 8*abs(hue_delta(h_obj,h));
	
	res = 255 - res;
	//if(res < 254) res = 0;
	return MAX(res,0);
}

void rgb32_to_value(uint32_t * in, uint8_t * out, int width, int height) {
	for(int y = 0; y < height; y++){
		uint32_t * in_line = in + y*width;
		uint8_t * out_line = &(out[0]) + y*width;
		for(int x = 0; x < width; x++){
			uint8_t r = in_line[x] & 0xFF;
			uint8_t g = (in_line[x] & 0xFF00) >> 8;
			uint8_t b = (in_line[x] & 0xFF0000) >> 16;
			uint8_t tmp = MAX(r,g);
			out_line[x] = MAX(tmp,b);
		}
	}
}

void rgb32_to_mean(uint32_t * in, uint8_t * out, int width, int height) {
	for(int y = 0; y < height; y++){
		uint32_t * in_line = in + y*width;
		uint8_t * out_line = &(out[0]) + y*width;
		for(int x = 0; x < width; x++){
			uint8_t r = in_line[x] & 0xFF;
			uint8_t g = (in_line[x] & 0xFF00) >> 8;
			uint8_t b = (in_line[x] & 0xFF0000) >> 16;
			out_line[x] = (r + g + b)/3;
		}
	}
}

void rgb32_to_color_value(uint32_t * in, uint8_t * out, int width, int height, int color) {
	for(int y = 0; y < height; y++){
		uint32_t * in_line = in + y*width;
		uint8_t * out_line = &(out[0]) + y*width;
		for(int x = 0; x < width; x++){
			int c[3];
			c[0] = in_line[x] & 0xFF;
			c[1] = (in_line[x] & 0xFF00) >> 8;
			c[2] = (in_line[x] & 0xFF0000) >> 16;
			out_line[x] = c[color];
		}
	}
}

// VIDEO MODE DEPENDANT

void rgb24_to_hsv24(int width, int height, unsigned char * rgb24, unsigned char * hsv24){
	for(int y = 0; y < height; y++){
		unsigned char *rgb_row = rgb24 + width*y*3;
		unsigned char *hsv_row = hsv24 + width*y*3;
		for(int x = 0; x < width; x++){
			int r = rgb_row[x*3 + 2];
			int g = rgb_row[x*3 + 1];
			int b = rgb_row[x*3 + 0];
			int h,s,v;
			
			rgb_to_hsv(r,g,b,&h,&s,&v);
			
			hsv_row[x*3 + 0] = h;
			hsv_row[x*3 + 1] = s;
			hsv_row[x*3 + 2] = v;
		}
	}
}

void rgb32_to_ppm(unsigned char * buf, int w, int h, FILE * out){
	unsigned int * b = (unsigned int*)buf;
	fprintf(out,"P6\n%i %i %i\n",w,h,255);
	for(int y = 0; y < h; y++){
		unsigned int * l = b + y*w;
		for(int x = 0; x < w; x++){
			unsigned char * p = (unsigned char*)(l + x);
			fprintf(out,"%c%c%c",p[0],p[1],p[2]);
		}
	}
}

void rgb32_to_ppm_series(unsigned char * buf, int w, int h, const char * prefix){
	static int screenshot_number = 0;
	std::stringstream ss;
	ss << prefix << screenshot_number++ << ".ppm";
	std::string fname;
	ss >> fname;
	FILE * out = fopen(fname.c_str(),"w");
	if(out){
		rgb32_to_ppm(buf,w,h,out);
		fclose(out);
	}
}

void rgb32_to_hsv32(int width, int height, unsigned char * rgb32, unsigned char * hsv32){
	for(int y = 0; y < height; y++){
		unsigned char *rgb_row = rgb32 + width*y*4;
		unsigned char *hsv_row = hsv32 + width*y*4;
		for(int x = 0; x < width; x++){
			int r = rgb_row[x*4 + 2];
			int g = rgb_row[x*4 + 1];
			int b = rgb_row[x*4 + 0];
			int h,s,v;
			
			rgb_to_hsv(r,g,b,&h,&s,&v);
			
			hsv_row[x*4 + 0] = h;
			hsv_row[x*4 + 1] = s;
			hsv_row[x*4 + 2] = v;
		}
	}
}

void hsv24_to_p8(int width, int height, unsigned char * hsv24, unsigned char * p8, int h_obj, int s_obj){
	for(int y = 0; y < height; y++){
		unsigned char *p_row = p8 + width*y;
		unsigned char *hsv_row = hsv24 + width*y*3;
		for(int x = 0; x < width; x++){
			int p = hsv_to_p(hsv_row[x*3],hsv_row[x*3 + 1],hsv_row[x*3 + 2],h_obj,s_obj);
			p_row[x] = p;
		}
	}
}

void hsv32_to_p8(int width, int height, unsigned char * hsv32, unsigned char * p8, int h_obj, int s_obj){
	for(int y = 0; y < height; y++){
		unsigned char *p_row = p8 + width*y;
		unsigned char *hsv_row = hsv32 + width*y*4;
		for(int x = 0; x < width; x++){
			int p = hsv_to_p(hsv_row[x*4],hsv_row[x*4 + 1],hsv_row[x*4 + 2],h_obj, s_obj);
			p_row[x] = p;
		}
	}
}

void rgb32_to_p8(int width, int height, unsigned char * rgb32, unsigned char * p8, int h_obj, int s_obj){
	for(int y = 0; y < height; y++){
		unsigned char *p_row = p8 + width*y;
		unsigned char *rgb_row = rgb32 + width*y*4;
		for(int x = 0; x < width; x++){
			int h,s,v;
			rgb_to_hsv(rgb_row[x*4],rgb_row[x*4 + 1],rgb_row[x*4 + 2],&h,&s,&v);
			int p = hsv_to_p(h,s,v,h_obj,s_obj);
			p_row[x] = p;
		}
	}
}

#endif // CONVERSIONS_H
