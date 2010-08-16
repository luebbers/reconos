/***************************************************************************
 * ipclient.cpp: ReconOS image processing case study
 * 			    IP client
 * 
 * Grabs image frames from a Philips webcam and transmits them via UDP to
 * the ipserver application running on the ML403. 
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#include "v4lsource.h"
#include <SDL/SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/io.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>
#include <unistd.h>
#include "global.h"
#include "udp_connection.h"
#include "utils.h"

// delay per frame in microseconds
#define FRAME_DELAY 1000000*0


// the SDL window
static SDL_Surface *screen;


extern volatile unsigned int DGRAM_DELAY_USEC;


static void window_resize(int width, int height)
{
	screen = SDL_SetVideoMode(width, height, 32, SDL_HWSURFACE);
	if(!screen){
		fprintf(stderr,"Could not set video mode %ix%i: %s\n", width, height, SDL_GetError());
		SDL_Quit();
		exit(EXIT_FAILURE);
	}
}

static void window_init(int w, int h)
{
	SDL_Init(SDL_INIT_VIDEO);
	window_resize(w,h);
	SDL_WM_SetCaption("CamTest", "CamTest");
}

void send_buffer2(int sockfd, unsigned char * buf, int w, int h){
	int bytes_send = 0;
	while(bytes_send < w*h){
		int result = send(sockfd,buf + bytes_send,1024,0);
		if(result == -1){
			perror("send");
			return;
		}
		bytes_send += result;
		usleep(10);
	}
}

void send_buffer(int sockfd, unsigned char * buf, int w, int h){
	int result = send(sockfd,buf,w*h,0);
	if(result == -1){
		perror("send");
	}	
}

int wait_for_ack(struct udp_connection *con) {

	fd_set fds;
	int retval;
	struct timeval tv;
	char recv_char;

	FD_ZERO(&fds);
	FD_SET(con->local_fd, &fds);
	
	tv.tv_sec = 1;		// wait max 1 second
	tv.tv_usec = 0;
	
	retval = select(con->local_fd+1, &fds, NULL, NULL, &tv);
	if (retval == -1) {
		util_perror("select");
	}
	
	if (retval) {
		size_t fromlen = sizeof(con->remote_addr);

		if (!FD_ISSET(con->local_fd, &fds)) {
			util_perror("select FD_ISSET");
		}
	
		retval = recvfrom(con->local_fd, &recv_char, 1, 0, 
					(struct sockaddr*)&(con->remote_addr), &fromlen);
	
		if(retval == -1){
			util_perror("recvfrom");
		} 
	
		if (recv_char != 42) {
			printf("strange response received\n");
			return 1;
		}
		return 0;
	} else {
		printf("frame not acknowledged.\n");
		return 1;
	}
	
}

int init_connection(){
	int remote_fd, result;
	struct sockaddr_in remote;
	
	remote_fd = socket(AF_INET,SOCK_STREAM,0);
	if(remote_fd == -1){
		perror("socket");
	}
	
	memset(&remote,0,sizeof(remote));
	remote.sin_family = AF_INET;
	remote.sin_port = htons(6666);
	remote.sin_addr.s_addr = inet_addr("192.168.1.7");
	
	result = connect(remote_fd,(struct sockaddr*)&remote,sizeof(remote));
	if(result == -1){
		perror("connect");
	}
	
	fprintf(stderr,"connected\n");
	
	return remote_fd;
}


int main(int argc, char **argv)
{
	// init SDL-window
	window_init(WIDTH,HEIGHT);

	// init video source
	V4LSource v4l;
	unsigned char * rgb32_frame = NULL;
	if(!v4l.open("/dev/video0")) goto done;
	if(!v4l.init(WIDTH,HEIGHT)) goto done;
	
	// connect
	//init_connection();
	struct udp_connection * con = udp_connection_create(inet_addr("192.168.1.7"));
	
	// init buffers
	unsigned char * buf_r = new unsigned char[WIDTH*HEIGHT];
	unsigned char * buf_g = new unsigned char[WIDTH*HEIGHT];
	unsigned char * buf_b = new unsigned char[WIDTH*HEIGHT];

	// for fps measurement
	struct timeval current, last;
	unsigned int diff;	// time difference in usecs
	
	gettimeofday(&last, NULL);
	
	// give IO permissions (for mysleep() in udp_connection.c)
	if (ioperm(0x80, 1, 1)) {
		perror("ioperm");
	}
	
	printf("Use UP/DOWN ARROWS for changing the transmission delay.\n"
	       "Hold SHIFT for steps of 1000, CTRL for steps of 10, and ALT for single steps.\n");

	// Haupt-Schleife
	while (1) {
		// 1. Ereignisbehandlung (Benutzereingaben usw.)
		SDL_Event event;
		unsigned int step;
		while (SDL_PollEvent(&event)){
			switch(event.type){
				case SDL_VIDEORESIZE:
					window_resize(event.resize.w,event.resize.h);
					break;
				case SDL_KEYDOWN:
					unsigned int mod = event.key.keysym.mod;
					if ((mod & KMOD_CTRL) != 0) {
						step = 10;
					} else if ((mod & KMOD_ALT) != 0) {
						step = 1;
					} else if ((mod & KMOD_SHIFT) != 0) {
						step = 1000;
					} else {
						step = 100;
					}
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							goto done;
						case SDLK_F1:
							SDL_WM_ToggleFullScreen(screen);
							break;
						case SDLK_UP:
							if (DGRAM_DELAY_USEC >= step) {
								DGRAM_DELAY_USEC -= step;
								printf("datagram delay: %u\n", DGRAM_DELAY_USEC);
							}
							break;
						case SDLK_DOWN:
							if (DGRAM_DELAY_USEC <= 100000) {
								DGRAM_DELAY_USEC += step;
								printf("datagram delay: %u\n", DGRAM_DELAY_USEC);
							}
							break;
						default:
							break; // gcc zufriedenstellen
					}
					break;

				case SDL_QUIT:
					goto done;
			}
		}
		// 2. Frame lesen		
		rgb32_frame = v4l.get_rgb32();
		if(!rgb32_frame) goto done;

		// 3. Frame anzeigen
		SDL_LockSurface(screen);
		for(int i = 0; i < WIDTH*HEIGHT; i++){
			unsigned char * d = ((unsigned char*)screen->pixels) + 4*i;
			unsigned char * s = rgb32_frame + 4*i;
			d[0] = s[2];
			d[1] = s[1];
			d[2] = s[0];
		}
		
		SDL_UpdateRect(screen,0,0,0,0);
		SDL_UnlockSurface(screen);
		
		// 4. extract channels
		for(int y = 0; y < HEIGHT; y++){
			unsigned char * line = rgb32_frame + y*WIDTH*4;
			for(int x = 0; x < WIDTH; x++){
				buf_r[x + WIDTH*y] = line[x*4 + 0];
				buf_g[x + WIDTH*y] = line[x*4 + 1];
				buf_b[x + WIDTH*y] = line[x*4 + 2];
			}
		}
		
		// submit rgb data
	//	send_buffer2(remote_fd,buf_r,WIDTH,HEIGHT);
	//	send_buffer2(remote_fd,buf_g,WIDTH,HEIGHT);
	//	send_buffer2(remote_fd,buf_b,WIDTH,HEIGHT);
		
		udp_connection_send(con,buf_r,WIDTH*HEIGHT);
//		usleep(1000);

		gettimeofday(&current, NULL);
		diff = (current.tv_sec - last.tv_sec) * 1000000;
		diff += (current.tv_usec - last.tv_usec);
		
		fprintf(stderr, "FPS: %.2f\r", 1000000.0 / diff);
		
		last.tv_sec = current.tv_sec;
		last.tv_usec = current.tv_usec;

//		usleep(FRAME_DELAY);
	
//		wait_for_ack(con);

	//	udp_connection_send(con,buf_g,WIDTH*HEIGHT);
	//	udp_connection_send(con,buf_b,WIDTH*HEIGHT);
	}
done:
	SDL_Quit();
	return EXIT_SUCCESS;
}
