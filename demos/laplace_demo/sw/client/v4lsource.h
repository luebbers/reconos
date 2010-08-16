/***************************************************************************
 * v4lsource.h: Video4Linux video source class/struct
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#ifndef V4LSOURCE_H
#define V4LSOURCE_H

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <linux/videodev.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <time.h>
#include <malloc.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include "video_source.h"
#include "ccvt.h"


struct V4LSource : public VideoSource
{
	struct video_picture grab_pic;
	struct video_capability grab_cap;
	struct video_channel grab_vid;
	struct video_mmap grab_buf;
	int grab_fd, grab_size;
	unsigned char *grab_data;
	const char * device_name;
	unsigned char * rgb_data;
	
	bool open(const char * dev_name){
		device_name = dev_name;
		if ((grab_fd = ::open(device_name, O_RDWR)) == -1) {
			perror("open");
			close(grab_fd);
			return false;
		}
		return true;
	}
	
	bool init(int width, int height){
		if (ioctl(grab_fd, VIDIOCGCAP, &grab_cap) == -1){
			fprintf(stderr, "Bad Video Device!\n");
			close(grab_fd);
			return false;
		}
		
		memset(&grab_pic, 0, sizeof(struct video_picture));
		if (ioctl(grab_fd, VIDIOCGPICT, &grab_pic) == -1) {
			close(grab_fd);
			return false;
		}
		
		grab_buf.format = VIDEO_PALETTE_YUV420P;
		grab_buf.width = width;
		grab_buf.height = height;
		grab_size = width * height * 3;
		grab_data = (unsigned char*)mmap(0, grab_size, PROT_READ | PROT_WRITE, MAP_SHARED, grab_fd, 0);
		grab_buf.frame = 0;
		//grab_pic.hue = hue;
		//grab_pic.contrast = contrast;
		//grab_pic.brightness = brightness;
		//grab_pic.colour = color;
		
		if (ioctl(grab_fd, VIDIOCSPICT, &grab_pic) == -1) {
			perror("ioctl:VIDIOCSPICT");
			close(grab_fd);
			munmap(grab_data, grab_size);
			return false;
		}
		/*
		if ( -1 == ioctl(grab_fd, VIDIOCMCAPTURE, &grab_buf)) {
			perror("ioctl:VIDIOCMCAPTURE");
			close(grab_fd);
			munmap(grab_data, grab_size);
			return false;
		}
		swap_frame();
		*/
		
		rgb_data = new unsigned char[width*height*4];
		
		return true;
	}

	void swap_frame(){
		grab_buf.frame = grab_buf.frame ? 0 : 1;
	}
	
	bool next_frame(unsigned char ** data) {
		if ( -1 != ioctl(grab_fd, VIDIOCMCAPTURE, &grab_buf)) {
			//swap_frame();
			if ( -1 != ioctl(grab_fd, VIDIOCSYNC, &grab_buf)) {
				*data = grab_data;
				//if(grab_buf.frame == 0) *data += grab_buf.width*grab_buf.height*3/2;
			} else {
				perror("ioctl:VIDIOCSYNC");
				close(grab_fd);
				munmap(grab_data, grab_size);
				return false;
			}
		} else {
			perror("ioctl:VIDIOCMCAPTURE");
			close(grab_fd);
			munmap(grab_data, grab_size);
			return false;
		}
		return true;
	}
	
	virtual int get_width() const { return grab_buf.width; }
	virtual int get_height() const { return grab_buf.height; }
	virtual unsigned char * get_rgb32() {
		unsigned char * yuv420p;
		if(!next_frame(&yuv420p)) return NULL;
		ccvt_420p_rgb32(get_width(), get_height(), yuv420p, rgb_data);
		return rgb_data;
	}
};

#endif // V4LSOURCE_H
