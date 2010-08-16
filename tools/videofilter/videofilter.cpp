///
/// \file videofilter.cpp
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

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <opencv/cv.h>
#include <opencv/highgui.h>
#include "rank_filter.h"
#include "conv_filter.h"
#include "susan_filter.h"

// some example filter instantiations
RankFilter<5> rf(12);
ConvFilter<5> cf;
SusanFilter<21> sf21(21,1);
SusanFilter<9> sf9(7.1,0.5);
SusanFilter<5> sf5(7.1,0.05);
SusanFilter<3> sf3(2,0.04);

// example implemetation of the filter() method: 10 times susan 3x3
// replace this method with your own code...
IplImage * filter(IplImage * img){
	IplImage * tmp = img;
	for(int i = 0; i < 10; i++){
		tmp = sf3.filter(tmp);
	}
	return tmp;
}

// returns a value from [0.1] chosen uniform at random
double uniform(){
	return rand()/(double)RAND_MAX;
}

// returns a normal distributed random number
double normal(double mean, double var)
{
	while(1){
		double u1 = uniform();
		double u2 = uniform();
		double a = 2*u1 - 1;
		double b = 2*u2 - 1;
		double q = a*a + b*b;
		if(q < 1){
			double p = sqrt(-2*log(q)/q);
			double x = a*p;
			return x*var + mean;
		}
	}
}

// adds gaussian noise to an image
void add_noise(IplImage * img, double var){
	for(int y = 0; y < img->height; y++){
		for(int x = 0; x < img->width; x++){
			for(int c = 0; c < img->nChannels; c++){
				int i = (int)normal((uint8_t)img->imageData[y*img->widthStep + x*img->nChannels + c],var);
				
				if(i < 0) i = 0;
				else if(i > 0xFF) i = 0xFF;
				
				img->imageData[y*img->widthStep + x*img->nChannels + c] = i;
			}
		}
	}
}

int main(int argc, char *argv[]) {
	IplImage* img = 0;

	CvCapture* capture = cvCaptureFromCAM(0);
	
	cvNamedWindow("source", CV_WINDOW_AUTOSIZE);
	cvNamedWindow("filter", CV_WINDOW_AUTOSIZE);
	
	while(1){
		if(!cvGrabFrame(capture)){
			printf("Could not grab a frame\n\7");
			exit(0);
		}
		img = cvRetrieveFrame(capture);
		
//		add_noise(img,100);
		
		cvShowImage("source", img);
		cvShowImage("filter", filter(img));
		
		cvWaitKey(10);
	}
	
	cvReleaseCapture(&capture);
	
	return 0;
}
