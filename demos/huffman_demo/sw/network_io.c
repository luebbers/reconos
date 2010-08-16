#include "network_io.h"
#include "util.h"

#include <mqueue.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>

#include <assert.h>


static void text_sock2mq(int socket, mqd_t mq)
{
	int len;
	unsigned char * buffer;
	struct mq_attr attr;
	
	mq_getattr(mq, &attr);
	buffer = malloc(attr.mq_msgsize);
	
	do{
		len = recv(socket, buffer, attr.mq_msgsize, MSG_WAITALL);
		if(len < 0){
			perror("recv");
			fprintf(stderr,"File %s line %d\n", __FILE__, __LINE__);
			break;
		}
		
		my_mq_send(mq, buffer, len);
		
	} while(len == attr.mq_msgsize);
}

static void text_mq2sock(mqd_t mq, int socket)
{
	int len;
	unsigned char * buffer;
	struct mq_attr attr;
	
	mq_getattr(mq, &attr);
	buffer = malloc(attr.mq_msgsize);
	
	do{
		int tmp;
		tmp = my_mq_receive(mq, buffer);
		len = send(socket, buffer, tmp, 0);
		assert(len == tmp);
		
	} while(len == attr.mq_msgsize);
}

static void code_mq2sock(mqd_t mq, int socket)
{
	int symcount;
	unsigned char codelen[128];
	unsigned char * buffer;
	struct mq_attr attr;
	int len;
	
	mq_getattr(mq, &attr);
	buffer = malloc(attr.mq_msgsize);
	
	len = my_mq_receive(mq, &symcount);
	assert(len == 4);
	
	len = send(socket, &symcount, 4, 0);
	assert(len == 4);
	
	len = my_mq_receive(mq, codelen);
	assert(len == 128);
	
	len = send(socket, codelen, 128, 0);
	assert(len == 128);
	
	do{
		int tmp;
		tmp = my_mq_receive(mq, buffer);
		len = send(socket, buffer, tmp, 0);
		assert(len == tmp);
	} while(len == attr.mq_msgsize);
}

static void code_sock2mq(int socket, mqd_t mq)
{
	int symcount;
	unsigned char codelen[128];
	unsigned char * buffer;
	struct mq_attr attr;
	int len;
	
	mq_getattr(mq, &attr);
	buffer = malloc(attr.mq_msgsize);
	
	len = recv(socket, &symcount, 4, MSG_WAITALL);
	assert(len == 4);
	
	my_mq_send(mq, &symcount, 4);
	
	len = recv(socket, codelen, 128, MSG_WAITALL);
	assert(len == 128);
	
	my_mq_send(mq, codelen, 128);
	
	do{
		len = recv(socket, buffer, attr.mq_msgsize, MSG_WAITALL);
		if(len == -1) perror("recv");
		my_mq_send(mq, buffer, len);
		
	} while(len == attr.mq_msgsize);
}

static int create_socket(int port)
{
	struct sockaddr_in local_addr;
	int local_socket;
	int result;
	int TRUE = 1; // sad but true
	
	memset(&local_addr, 0, sizeof(local_addr));
	local_addr.sin_family      = AF_INET;
	local_addr.sin_addr.s_addr = inet_addr("0.0.0.0");
	local_addr.sin_port        = htons(port);
	
	local_socket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (local_socket == -1){
		perror("socket");
		exit(1);
	}
	
	fprintf(stderr,"setsockopt\n");
	setsockopt(local_socket, IPPROTO_TCP, SO_REUSEADDR, &TRUE, sizeof TRUE);
	
	result = bind(local_socket, (struct sockaddr *) &local_addr, sizeof(local_addr));
	if (result == -1){
		perror("bind");
		exit(1);
	}
	
	result = listen(local_socket, -1);
	if (result == -1){
		perror("listen");
		exit(1);
	}
	
	return local_socket;
}

void * encoder_network_io(void *data)
{
	struct NetworkIOArgs *args;
	struct sockaddr_in remote_addr;
	mqd_t mq_in, mq_out;
	int local_socket;
	
	args = data;
	mq_in = my_mq_open(args->mq_recv);
	mq_out = my_mq_open(args->mq_send);
	local_socket = create_socket(args->port);
	
	while(1){
		unsigned int dontcare = sizeof(remote_addr);
		printf("encoder ready, listening on port %d\n", args->port);
		printf("waiting for connection...\n");
		int remote_socket = accept(local_socket, (struct sockaddr *) &remote_addr, &dontcare);
		if (remote_socket == -1){
			perror("accept");
			exit(1);
		}
		
		printf("incoming connection from %s:%d\n", inet_ntoa(remote_addr.sin_addr), remote_addr.sin_port);
		
		text_sock2mq(remote_socket, mq_out);
		code_mq2sock(mq_in, remote_socket);
		
		shutdown(remote_socket, SHUT_RDWR);
		close(remote_socket);
	}
	
	return NULL;
}

void * decoder_network_io(void *data)
{
	struct NetworkIOArgs *args;
	struct sockaddr_in remote_addr;
	mqd_t mq_in, mq_out;
	int local_socket;
	
	args = data;
	mq_in = my_mq_open(args->mq_recv);
	mq_out = my_mq_open(args->mq_send);
	local_socket = create_socket(args->port);
	
	while(1){
		unsigned int dontcare = sizeof(remote_addr);
		printf("decoder ready, listening on port %d\n", args->port);
		printf("waiting for connection...\n");
		int remote_socket = accept(local_socket, (struct sockaddr *) &remote_addr, &dontcare);
		if (remote_socket == -1){
			perror("accept");
			exit(1);
		}
		
		printf("incoming connection from %s:%d\n", inet_ntoa(remote_addr.sin_addr), remote_addr.sin_port);
		
		code_sock2mq(remote_socket, mq_out);
		text_mq2sock(mq_in, remote_socket);
		
		fprintf(stderr,"shutting down socket\n");
		shutdown(remote_socket, SHUT_RDWR);
		close(remote_socket);
	}
	
	return NULL;
}
