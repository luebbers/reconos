///
/// \file conv_filter.h
///
/// \author     Andreas Agne <agne@upb.de>
/// \date       23.11.2007
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//

#ifndef CONV_FILTER_H
#define CONV_FILTER_H

#include "window_filter.h"

/* implementation of an NxN double precission convolution filter */
template <int WINDOW_WIDTH>
struct ConvFilter : public WindowFilter<WINDOW_WIDTH>
{
	double kernel[WINDOW_WIDTH*WINDOW_WIDTH];
	
	ConvFilter(){
		set_laplace(2.0);
	}
	
	/* set kernel to gaussian blurr */
	void set_gauss(){
		int c = WINDOW_WIDTH/2;
		double sum = 0;
		for(int i = 0; i < WINDOW_WIDTH; i++){
			for(int j = 0; j < WINDOW_WIDTH; j++){
				int dx = c - i;
				int dy = c - j;
				kernel[i + j*WINDOW_WIDTH] = 1.0/(dx*dx + dy*dy + 1);
				sum += kernel[i + j*WINDOW_WIDTH];
			}
		}
		
		for(int i = 0; i < WINDOW_WIDTH*WINDOW_WIDTH; i++){
			kernel[i] /= sum;
		}
	}
	
	/* set kernel to laplace edge detection/sharpen */
	void set_laplace(double strength){
		int c = WINDOW_WIDTH/2;
		double sum = 0;
		for(int i = 0; i < WINDOW_WIDTH; i++){
			for(int j = 0; j < WINDOW_WIDTH; j++){
				int dx = c - i;
				int dy = c - j;
				if(i == WINDOW_WIDTH/2 && j == WINDOW_WIDTH/2){
					kernel[i + j*WINDOW_WIDTH] = strength + 1;
				}
				else{
					kernel[i + j*WINDOW_WIDTH] = -1.0/(dx*dx + dy*dy + 1);
					sum -= kernel[i + j*WINDOW_WIDTH];
				}
			}
		}
		
		for(int i = 0; i < WINDOW_WIDTH; i++){
			for(int j = 0; j < WINDOW_WIDTH; j++){
				if(i == WINDOW_WIDTH/2 && j == WINDOW_WIDTH/2) continue;
				kernel[i + j*WINDOW_WIDTH] *= strength/sum;
			}
		}
	}
	
	/* implemetation of the convolution */
	virtual uint8_t apply(uint8_t * window, int col_0){
		double s = 0;
		for(int x = 0; x < WINDOW_WIDTH; x++){
			int col = (col_0 + x + 1) % WINDOW_WIDTH;
			for(int y = 0; y < WINDOW_WIDTH; y++){
				s += kernel[x + WINDOW_WIDTH*y]*window[col*WINDOW_WIDTH + y];
			}
		}
		
		int i = (int)s;
		if(i > 0xFF) i = 0xFF;
		if(i < 0) i = 0;
		
		return i;
	}
};

#endif // CONV_FILTER_H
