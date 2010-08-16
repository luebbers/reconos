///
/// \file susan_edge_filter.h
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

#ifndef SUSAN_EDGE_FILTER_H
#define SUSAN_EDGE_FILTER_H

#include "window_filter.h"
#include "rank_filter.h"

/* Implementation of the susan edge detection filter */
template <int WINDOW_WIDTH>
struct SusanEdgeFilter : public WindowFilter<WINDOW_WIDTH>
{
	double t;
	double weight[256];
	double g;
	
	RankFilter<WINDOW_WIDTH> median;
	
	/* try t = 0.1 with 3x3 window */
	SusanEdgeFilter(double t_): t(t_), median(2) {
		double w_max = 0;
		for(int dv = 0; dv < 256; dv++){
			weight[dv] = exp(-pow(dv/256.0/t,6));
			if(weight[dv] > w_max) w_max = weight[dv];
		}
		g = 3*w_max*WINDOW_WIDTH*WINDOW_WIDTH/4.0;
	}
	
	virtual uint8_t apply(uint8_t * window, int col_0){
		double n = 0;
		int result;
		
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
				
				int dv = abs(window[col*WINDOW_WIDTH + y] - cv);
				
				n += weight[dv];
			}
		}
		
		if(n < g){
			result = (int)(0xFF*(g - n)/g);
			if(result > 0xFF) result = 0xFF;
			if(result < 0) result = 0;
		}
		else{
			result = 0;
		}
		
		return result;
	}
};

#endif // SUSAN_EDGE_FILTER_H

