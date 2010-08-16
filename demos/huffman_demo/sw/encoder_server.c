#include "histogram.h"
#include "tree.h"
#include "codebook.h"
#include "encoder.h"
#include "encoder_server.h"
#include "canonical.h"
#include "package_merge.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <pthread.h>
#include <mqueue.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <assert.h>

#ifdef __RECONOS__
#include <reconos/reconos.h>
#include <reconos/resources.h>
#endif

//#define HW_HISTOGRAM

#define STACK_SIZE (1024*1024*8)
#define BLOCK_SIZE_MAX (8*1024)

#define IP_ADDR "0.0.0.0"
#define RECV_BUFFER_SIZE (32*1024*1024)
#define SEND_BUFFER_SIZE (2*1024)

static pthread_t build_histogram_thread;
static pthread_attr_t build_histogram_attr;

#ifdef HW_HISTOGRAM
	static rthread_attr_t build_histogram_rattr;
	
	reconos_res_t build_histogram_resources[] =
	{
		{"/mq_build_histogram_in" , PTHREAD_MQD_T},
		{"/mq_build_histogram_out", PTHREAD_MQD_T}
	};
#endif

static mqd_t mq_open_default(const char * name, int msgsize)
{
	struct mq_attr default_mq_attr;
	default_mq_attr.mq_flags = 0;
	default_mq_attr.mq_maxmsg = 4;
	default_mq_attr.mq_msgsize = msgsize;
	default_mq_attr.mq_curmsgs = 0;
	int error;
	mqd_t result;
	
	error = mq_unlink(name);
	/* we expect this error, so we don't indicate it
	if(error){
		perror("mq_unlink");
	}
	*/
	result = mq_open(name, O_CREAT|O_RDWR, S_IRWXU, &default_mq_attr);
	if(result == (mqd_t)(-1)){
		perror("mq_open");
		exit(1);
	}
	
	return result;
}

void * build_histogram_entry(void * data)
{
	int i = 0;
	int num_blocks, error;
	struct Histogram32 h32;
	struct Histogram16 h16;
	mqd_t mq_histogram_in, mq_histogram_out;
	char buffer[BLOCK_SIZE_MAX];

	// set up mqs for communication
	mq_histogram_in = mq_open("/mq_build_histogram_in",O_RDWR);
	if(mq_histogram_in == (mqd_t)(-1)){
		perror("could not open /mq_build_histogram_in");
		exit(1);
	}
	mq_histogram_out = mq_open("/mq_build_histogram_out",O_RDWR);
	if(mq_histogram_out == (mqd_t)(-1)){
		perror("could not open /mq_build_histogram_out");
		exit(1);
	}

	// get the number of blocks
	i = mq_receive(mq_histogram_in, (char*)&num_blocks, BLOCK_SIZE_MAX, NULL);
	assert(i == 4);

	// receive blocks and add the symbols to the 31-bit histogram
	histogram32_init(&h32);
	while(num_blocks){
		i = mq_receive(mq_histogram_in, buffer, BLOCK_SIZE_MAX, NULL);
		histogram32_add(&h32, buffer, i);
		num_blocks--;
	}

	// convert the histogram to 16-bit resolution
	histogram32to16(&h32, &h16);

	// send the histogram
	error = mq_send(
			mq_histogram_out,
			(char*)&h16,
			sizeof h16,
			0);	
	if(error){
		perror("mq_send: /mq_build_histogram_out");
	}
	
	return NULL;
}

static void build_histogram_thread_create(void)
{
	int error;
	pthread_attr_init(&build_histogram_attr);
	pthread_attr_setstacksize(&build_histogram_attr, STACK_SIZE);
	
#ifdef HW_HISTOGRAM
	printf("building histogram in hardware...\n");
	rthread_attr_init(&build_histogram_rattr);
	rthread_attr_setslotnum(&build_histogram_rattr, 0);
	rthread_attr_setresources(&build_histogram_rattr, build_histogram_resources, 2);
	error = rthread_create(
			&build_histogram_thread,
			&build_histogram_attr,
			&build_histogram_rattr,
			NULL);
#else
	printf("building histogram in software...\n");
	error = pthread_create(
			&build_histogram_thread,
			&build_histogram_attr,
			build_histogram_entry,
			NULL);
#endif
	
	if(error){
		perror("pthread_create: build_histogram");
		exit(1);
	}

}

static void encode(int sock)
{
	struct Histogram16 h16;
	struct Tree tree;
	struct Codebook cb;
	struct Encoder encoder;
	uint8_t codelen[128];
	mqd_t mq_histogram_in, mq_histogram_out;
	
	unsigned char *recv_buffer;
	unsigned char send_buffer[SEND_BUFFER_SIZE + 1];
	
	int send_len = 0; // number of bytes in send buffer
	int send_total = 0;
	int i;
	int b;
	int error;
	
	int32_t sym_count = 0;

	// allocate memory for the receive buffer
	recv_buffer = malloc(RECV_BUFFER_SIZE + 1);
	if(!recv_buffer){
		fprintf(stderr,"could not allocate buffer (%d bytes)\n", RECV_BUFFER_SIZE);
		return;
	}
	
	// receive input text
	sym_count = recv(sock, recv_buffer, RECV_BUFFER_SIZE + 1, MSG_WAITALL);
	if(sym_count <= 0){
		perror("recv");
		free(recv_buffer);
		return;
	}
	
	if(sym_count == RECV_BUFFER_SIZE + 1){
		fprintf(stderr,"buffer overflow! do not send more than %d bytes per connection\n", RECV_BUFFER_SIZE);
		free(recv_buffer);
		return;
	}
	
	printf("#symbols = %d\n", sym_count); 
	
	// build the histogram
	// this is done in a separate thread, so we first create the thread
	// and then open two message queues for communication
	printf("creating histogram...\n");
	build_histogram_thread_create();

	mq_histogram_in = mq_open("/mq_build_histogram_in",O_RDWR);
	if(mq_histogram_in == (mqd_t)(-1)){
		perror("could not open /mq_build_histogram_in");
		exit(1);
	}
	mq_histogram_out = mq_open("/mq_build_histogram_out",O_RDWR);
	if(mq_histogram_out == (mqd_t)(-1)){
		perror("could not open /mq_build_histogram_out");
		exit(1);
	}

	// send the number of blocks to the build_histogram thread
	i = sym_count/BLOCK_SIZE_MAX;
	if(sym_count % BLOCK_SIZE_MAX > 0) i++;
	error = mq_send(
			mq_histogram_in,
			(char*)&i,
			4,
			0);

	if(error){
		perror("mq_send: /mq_build_histogram_input (1)");
	}

	// send the input text block by block
	for(i = 0; i < sym_count; i += BLOCK_SIZE_MAX)
	{
		int len = sym_count - i;

		if(len > BLOCK_SIZE_MAX) len = BLOCK_SIZE_MAX;

		error = mq_send(
				mq_histogram_in,
				(char*)(recv_buffer + i),
				len,
				0);

		if(error){
			perror("mq_send: /mq_build_histogram_input (2)");
		}
	}

	// receive the histogram
	i = mq_receive(mq_histogram_out, (char*)&h16, BLOCK_SIZE_MAX, NULL);
	assert(i == sizeof h16);
	
	// send the number of symbols and the histogram to the network connection
	printf("sending histogram...\n");
	if(send(sock, &sym_count, 4, 0) != 4){
		perror("send (1)");
		free(recv_buffer);
		return;
	}
	
	printf("using package-merge to create codelengths...\n");
	package_merge2(&h16,16,codelen);
	
	send_total = send(sock, codelen, 128, 0);
	if(send_total != 128){
		perror("send (2)");
		free(recv_buffer);
		return;
	}
	
	printf("creating tree...\n");
	ctree_create(&tree, codelen);
	
	printf("creating codebook...\n");
	codebook_create(&cb,&tree);
	
	printf("initializing encoder...\n");
	encoder_init(&encoder,&cb);
	
	printf("encoding...\n");
	
	// encode the input text symbol by symbol and send the code
	// to the network connection
	for(i = 0; i < sym_count; i++){
		encoder_put_symbol(&encoder,recv_buffer[i]);
		while((b = encoder_get_byte(&encoder)) != ENCODER_NEED_INPUT){
			send_buffer[send_len++] = b;
			if(send_len >= SEND_BUFFER_SIZE){
				int res = send(sock, send_buffer, send_len, 0);
				if(res == -1){
					perror("send");
					free(recv_buffer);
					return;
				}
				send_total += send_len;
				send_len = 0;
			}
		}
	}
	
	b = encoder_get_last_byte(&encoder);
	if(b != ENCODER_NEED_INPUT){
		send_buffer[send_len++] = b;
	}
	
	if(send_len > 0){
		int res = send(sock, &send_buffer, send_len, 0);
		if(res == -1){
			perror("send");
			free(recv_buffer);
			return;
		}
	}
	
	free(recv_buffer);
	printf("encoding done\n\n");
}

static void set_up_mqs(void)
{
	mq_open_default("/mq_build_histogram_in", BLOCK_SIZE_MAX);
	mq_open_default("/mq_build_histogram_out", BLOCK_SIZE_MAX);
}


// This is the entry point of the main encoder thread
// It waits for an incoming network connection and then calls
// the encode function.
void * encoder_entry(void * data)
{
	int local_socket;
	int result;
	struct sockaddr_in local_addr, remote_addr;
	struct EncoderArgs * args;
	
	set_up_mqs();

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
		printf("encoder ready, listening on port %d\n", args->port);
		printf("waiting for connection...\n");
		int remote_socket = accept(local_socket, (struct sockaddr *) &remote_addr, &dontcare);
		if (remote_socket == -1){
			perror("accept");
			exit(1);
		}
		
		printf("incoming connection from %s:%d\n", inet_ntoa(remote_addr.sin_addr), remote_addr.sin_port);
		
		encode(remote_socket);
		
		shutdown(remote_socket, SHUT_RDWR);
		close(remote_socket);
	}
	
	return NULL;
}


