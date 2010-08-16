///
/// \file susan_filter.h
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

#ifndef SUSAN_FILTER_H
#define SUSAN_FILTER_H

#include "window_filter.h"
#include "rank_filter.h"

/* implementation of the NxN susan filter. */
template <int WINDOW_WIDTH>
struct SusanFilter : public WindowFilter<WINDOW_WIDTH>
{
	double s;
	double t;
	double weight[WINDOW_WIDTH*WINDOW_WIDTH/2][256];
	
	RankFilter<WINDOW_WIDTH> median;
	
	/* for a start, try sigma = 2 and t = 0.04 for a 3x3 window and iterate the filter 10 times */	
	SusanFilter(double sigma, double t_): s(sigma), t(t_), median(2) {
		for(int r = 0; r < WINDOW_WIDTH*WINDOW_WIDTH/2; r++){
			for(int dv = 0; dv < 256; dv++){
				double delta = dv*dv/(256.0*256.0);
				weight[r][dv] = exp(-r/(2*s*s) - delta/(t*t));
			}
		}
	}
	
	virtual uint8_t apply(uint8_t * window, int col_0){
		double nom = 0;
		double denom = 0;
		
		int col_center = (col_0 + WINDOW_WIDTH/2) % WINDOW_WIDTH;
		int cv = window[col_center*WINDOW_WIDTH + WINDOW_WIDTH/2];
		
		for(int x = 0; x < WINDOW_WIDTH; x++)
		{
			int col = (col_0 + x + 1) % WINDOW_WIDTH;
			int dx = x - WINDOW_WIDTH/2;
			
			for(int y = 0; y < WINDOW_WIDTH; y++)
			{
				int dy = y - WINDOW_WIDTH/2;
				
				if(dx == 0 && dy == 0) continue;
				
				double value = window[col*WINDOW_WIDTH + y];
				
				int r = dx*dx + dy*dy;
				int dv = abs(window[col*WINDOW_WIDTH + y] - cv);
				
				nom += value * weight[r][dv];
				denom += weight[r][dv];
			}
		}
		
		if(denom == 0){
			return median.apply(window, col_0);
		}
		
		int result = (int)(nom/denom);
		if(result > 0xFF) result = 0xFF;
		else if(result < 0) result = 0;
		
		return result;
	}
};

#endif // SUSAN_FILTER_H

