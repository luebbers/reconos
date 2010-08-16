///
/// \file rank_filter.h
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

#ifndef RANK_FILTER_H
#define RANK_FILTER_H

#include "window_filter.h"

/* implementation of an NxN window based rank filter */
template <int WINDOW_WIDTH>
struct RankFilter : public WindowFilter<WINDOW_WIDTH>
{
	int rank;
	
	/* r is the rank of the chosen pixel. Set r to WINOW_WIDTH/2 for median filtering */
	RankFilter(int r = WINDOW_WIDTH/2): rank(r) {}
	
	virtual uint8_t apply(uint8_t * window, int col_0){
		uint8_t value = window[0];
		uint8_t idx = 0;
		for(int r = 0; r <= rank; r++){
			for(int i = 1; i < WINDOW_WIDTH*WINDOW_WIDTH; i++){
				if(window[i] > value){
					value = window[i];
					idx = i;
				}
			}
			
			if(r == rank) return value;
			
			window[idx] = 0;
		}
		
		return 0; // never
	}
};

#endif // RANK_FILTER_H
