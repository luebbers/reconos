/***************************************************************************
 * video_source.h: Video source class/struct
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#ifndef VIDEOSOURCE_H
#define VIDEOSOURCE_H

struct VideoSource
{
	virtual int get_width() const = 0;
	virtual int get_height() const = 0;
	virtual unsigned char * get_rgb32() = 0;
	virtual ~VideoSource(){}
};

#endif // VIDEOSOURCE_H
