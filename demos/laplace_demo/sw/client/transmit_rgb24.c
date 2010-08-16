/***************************************************************************
 * transmit_rgb24.c: Transmits color RGB data via UDP
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>

#define WIDTH 640
#define HEIGHT 480
#define REMOTE_HOST "192.168.1.7"
#define REMOTE_PORT 6666

void exit_usage(char * name){
	fprintf(stderr,"%s: argument required\n",name);
}

int main(int argc, char ** argv){
	int remote_fd, result;
	struct sockaddr_in remote;
	
	//if(argc != 2) exit_usage(argv[0]);
	
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
	
	while(1){
		uint32_t pixel = 0;
		result = fread(&pixel,3,1,stdin);
		if(result != 1){
			break;
		}
		
		result = send(remote_fd,&pixel,4,0);
		if(result == -1){
			perror("send");
		}
	}
	
	return 0;
}

