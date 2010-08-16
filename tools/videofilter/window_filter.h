///
/// \file window_filter.h
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

#ifndef WINDOW_FILTER_H
#define WINDOW_FILTER_H

#include <stdlib.h>
#include <stdint.h>
#include <opencv/cv.h>
#include <vector>


/* 
   This template class provides in connection width opencv an easy-to-use way to implement
   a window based image filter. WINDOW_WIDTH is the width of the square shaped window.

   In order to implement a new image filter, create a subclass and implement the apply()
   method. Instantiate the subclass and supply IplImages to the filter() method, which
   will return the processed image.
*/
template <int WINDOW_WIDTH>
struct WindowFilter
{
	static const int ww = WINDOW_WIDTH;
	
	WindowFilter(): out(NULL) {}
	
	// overwrite this method to implement your own image filter.
	// use window[col*WINDOW_WIDTH + row] where col = (col_0 + i) % WINDOW_WIDTH
	//                                      and row = j
	// to access (sub-)pixel (i,j) of the window and return the resulting value.
	// seperate image channels will be handed to this method seperately.
	virtual uint8_t apply(uint8_t * window, int col_0) = 0;
	
	IplImage * filter(IplImage * img)
	{
		if(out == NULL) out = cvCloneImage(img);
		
		std::vector<Window> w(img->nChannels);
		
		uint8_t * o = (uint8_t*)out->imageData;
		
		int col_0 = 0;
		
		for(int y = 1; y < img->height; y++){
			int8_t * line = (int8_t*)(img->imageData + y*img->widthStep);
			for(int x = 0; x < img->width; x++){
				for(int c = 0; c < img->nChannels; c++){
					int8_t * tmp = line + x*img->nChannels + c;
					for(int dy = 0; dy < ww; dy++){
						w[c].data[col_0*ww + dy] = (int)tmp[dy*img->widthStep];
					}
					o[(x-1-WINDOW_WIDTH/2)*img->nChannels + y*img->widthStep + c]
							= apply(w[c].data, col_0);
				}
				col_0 = (col_0 + 1) % ww;
			}
		}
		
		return out;
	}
	
	virtual ~WindowFilter(){
		cvReleaseImage(&out);
	}

	protected:
	IplImage * out;

	private:
	struct Window {
		uint8_t data[WINDOW_WIDTH*WINDOW_WIDTH];
	};
	
};

#endif // WINDOW_FILTER_H
