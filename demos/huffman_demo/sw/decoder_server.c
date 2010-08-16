#include "histogram.h"
#include "tree.h"
#include "decoder.h"
#include "decoder_server.h"
#include "canonical.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <assert.h>

#define IP_ADDR "0.0.0.0"
#define RECV_BUFFER_SIZE (64*1024)
#define SEND_BUFFER_SIZE (2*1024)


static int recv_all(int sock, unsigned char * buffer, int len)
{
	while(len > 0){
		int d = recv(sock, buffer, len, 0);
		
		if(d == -1){
			return -1;
		}
		
		buffer += d;
		len -= d;
	}
	return 0;
}

static void decode(int sock)
{
	struct Tree tree;
	struct Decoder decoder;
	uint8_t codelen[128];
	
	unsigned char recv_buffer[RECV_BUFFER_SIZE];
	unsigned char send_buffer[SEND_BUFFER_SIZE];
	
	int send_len = 0; // number of bytes in send buffer
	int recv_total = 0;
	int send_total = 0;
	
	int32_t sym_count = 0;
	
	if(recv_all(sock, (unsigned char*)&sym_count, 4) == -1){
		perror("recv");
		return;
	}
	
	printf("#symbols = %d\n", sym_count); 
	
	if(recv_all(sock, codelen, 128) == -1){
		perror("recv");
		return;
	}
	
	printf("creating tree...\n");
	ctree_create(&tree, codelen);
	
	printf("initializing decoder...\n");
	decoder_init(&decoder,&tree);
	
	printf("decoding...\n");
	
	while(1){
		int b;
		int len;
		int i;
		
		
		
		len = recv(sock, recv_buffer, RECV_BUFFER_SIZE,0);
		if(len == -1){
			perror("recv");
			return;
		}
		if(len == 0){
			fprintf(stderr,"Error: client has shut down the connection but "
			        "there are %d symbols still to be decoded.\n", sym_count);
			fprintf(stderr,"received a total of %d bytes of code\n",recv_total);
			return;
		}
		
		recv_total += len;
		
		for(i = 0; i < len; i++){
			decoder_put_byte(&decoder,recv_buffer[i]);
			while((b = decoder_get_symbol(&decoder)) != DECODER_NEED_INPUT){
				send_buffer[send_len++] = b;
				if(send_len >= SEND_BUFFER_SIZE){
					int res = send(sock, send_buffer, send_len, 0);
					if(res == -1){
						perror("send");
						return;
					}
					send_total += send_len;
					send_len = 0;
				}
				sym_count--;
				if(sym_count <= 0) goto done;
			}
		}
	}
	
done:
	if(send_len > 0){
		int res = send(sock, &send_buffer, send_len, 0);
		if(res == -1){
			perror("send");
			return;
		}
	}
	
	printf("decoding done\n\n");
	
}

void * decoder_entry(void * data)
{
	int local_socket;
	int result;
	struct sockaddr_in local_addr, remote_addr;
	struct DecoderArgs * args;
	
	args = data;
	
	memset(&local_addr, 0, sizeof(local_addr));
	local_addr.sin_family      = AF_INET;
	local_addr.sin_addr.s_addr = inet_addr(IP_ADDR);
	local_addr.sin_port        = htons(args->port);
	
	local_socket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (local_socket == -1){
		perror("socket");
		exit(1);
	}
	
	result = bind(local_socket, (struct sockaddr *) &local_addr, sizeof(local_addr));
	if (result == -1){
		perror("bind");
	}
	
	result = listen(local_socket, -1);
	if (result == -1){
		perror("listen");
	}
	
	while(1){
		int dontcare = sizeof(remote_addr);
		printf("decoder ready, listening on port %d\n", args->port);
		printf("waiting for connection...\n");
		int remote_socket = accept(local_socket, (struct sockaddr *) &remote_addr, &dontcare);
		if (remote_socket == -1){
			perror("accept");
			exit(1);
		}
		
		printf("incoming connection from %s:%d\n", inet_ntoa(remote_addr.sin_addr), remote_addr.sin_port);
		
		decode(remote_socket);
		
		shutdown(remote_socket, SHUT_RDWR);
		close(remote_socket);
	}
	
	return NULL;
}


