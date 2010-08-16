/***************************************************************************
 * udp_connection.c: UDP support functions
 * 
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#include "udp_connection.h"
#include <sys/types.h>
#include <sys/socket.h>
#ifndef USE_ECOS
#include <sys/io.h>
#endif
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include "utils.h"
#include "global.h"

//#define DGRAM_DELAY_USEC 1000

#ifdef USE_ECOS
	#define DGRAM_DELAY
#else
	volatile unsigned int DGRAM_DELAY_USEC = 5000;
	#define DGRAM_DELAY  mysleep(DGRAM_DELAY_USEC)
#endif

#define MIN(a,b) ((a) < (b) ? (a) : (b))

#ifndef USE_ECOS
unsigned int inline mysleep(unsigned int ns) {
	unsigned int dummy;
	unsigned int i;
	
	for (i = 0; i < ns; i++) {
		dummy += inb_p(0x80);
	}
	return dummy;
}
#endif

struct udp_connection * udp_connection_create(in_addr_t remote){
	struct sockaddr_in local;
	int result, localfd;

	localfd = socket(AF_INET,SOCK_DGRAM,0);
	if(localfd == -1){
		util_perror("socket");
		return 0;
	}
	
	memset(&local,0,sizeof(local));
	local.sin_family = AF_INET;
	//local.sin_len = sizeof(local);
	local.sin_port = htons(6666);
	local.sin_addr.s_addr = INADDR_ANY;
	
	result = bind(localfd,(struct sockaddr*)&local,sizeof(local));
	if(result == -1){
		util_perror("bind");
		return NULL;
	}
	
	struct udp_connection * con = (struct udp_connection*)malloc(sizeof(struct udp_connection));
	if(!con) return NULL;
	
	con->local_fd = localfd;
	
	memset(&(con->remote_addr),0,sizeof con->remote_addr);
	con->remote_addr.sin_family = AF_INET;
	con->remote_addr.sin_addr.s_addr = remote;
	con->remote_addr.sin_port = htons(6666);
	
	return con;
}

void udp_connection_free(struct udp_connection * con){
	close(con->local_fd);
	free(con);
}

int udp_connection_send(struct udp_connection * con, unsigned char * buf, size_t len){
	u_int32_t buffer[DGRAM_SIZE/4 + 1];
	
	size_t bytes_send = 0;
	size_t seq = 0;
	
	while(bytes_send < len){
		unsigned char * offset = buf + bytes_send;
		int rem = MIN(len - bytes_send,DGRAM_SIZE);
		
		memcpy(&(buffer[1]),offset,rem);
		buffer[0] = htonl(seq++);
		
		int result = sendto(con->local_fd, buffer, rem + 4, 0,
				(struct sockaddr*)&con->remote_addr, sizeof(con->remote_addr));
		if(result == -1){
			return -1;
			util_perror("sendto");
		}
		
		//debug_printf("%d bytes send\n",bytes_send);
		
		bytes_send += rem;
		
		DGRAM_DELAY;
	}
	
	return 0;
}

int udp_connection_recv(struct udp_connection * con, unsigned char * buf, size_t len){
	u_int32_t buffer[DGRAM_SIZE/4 + 1];
	
	int seq_end = len/DGRAM_SIZE;
	int seq = -1;
	
	while(seq < seq_end - 1){
		size_t fromlen = sizeof(con->remote_addr);
		int result = recvfrom(con->local_fd, buffer, DGRAM_SIZE + 4, 0, 
				(struct sockaddr*)&(con->remote_addr), &fromlen);
		
	//	debug_printf("received %d bytes, SEQ = %d\n",result,buffer[0]);
				
		if(result == -1){
			return -1;
		} 
		
		if((int)buffer[0] < seq) return -1;
		seq = buffer[0];
		
		memcpy(buf + buffer[0]*DGRAM_SIZE, buffer + 1, result - 4);
	}
	
	return 0;
}


