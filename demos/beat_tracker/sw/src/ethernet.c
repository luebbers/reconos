//#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>


#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <network.h>
#include <reconos/reconos.h>
#include <unistd.h>



#include "../header/ethernet.h"
#include "../framework/header/timing.h"

/*
//! struct for image parameters
struct ImageParams
{
	int nChannels;	         ///< number of channels
	int depth;		///< image depth per channel
	int width;		///< image width
	int height;		///< image height
};


//! image parameters
static struct ImageParams imageParams;

//! particles data array containing all particles for one frame
particle_data * particles_data; */

//! valid  file descriptor
static int fd;

//! framebuffer pointer
//unsigned int framebuffer;




/**
	creates a server socket and waits for incomming connection.

	@param port: listen port for new data/frames
	@return returns a valid file descriptor on success. returns -1 on error.
*/
int accept_connection(int port)
{
	struct sockaddr_in local_addr;
	struct sockaddr_in remote_addr;
	
	bzero(&local_addr,0);       
        bzero(&remote_addr,0);
	
	int sockfd = socket( AF_INET, SOCK_STREAM, 0 );
	if(sockfd < 0){
		printf("socket creation failed\n");
		return -1; 
	}
	
	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = INADDR_ANY;
	local_addr.sin_port = htons(port);
        
        int result = bind(sockfd, (struct sockaddr *) &local_addr, sizeof local_addr);
	if(result < 0){
		printf("bind socket failed\n");
		return -1;
	}
	
	listen(sockfd,0);
 
        printf ("\nNow accept the connection");

	socklen_t addrlen;
	int fd = accept(sockfd, (struct sockaddr *) &remote_addr, &addrlen);
	if(fd < 0){
		printf("accept failed\n");
		return -1;
	}

	printf("\nAcception completed");
	return fd;
}



/**
	reads 'len' bytes from 'sockfd' into 'buf'. Block until all data is read or an read error occurs.
  
	@param fd: valid file descriptor
	@param buf: buffer, where the data is stored
	@param len: number of bytes, which should be read 

	@return returns 1 on success, 0 otherwise.
*/
int tcp_read_2(int fd, void *buf, size_t len)
{

	uint8_t * p = buf;
	int result;
	while(len != 0){
 		result = read(fd, p, len);
		if(result == -1) return 0;
		
		p += result;
		len -= result;
	}
	return 1;
}



/**
	write 'len' bytes from 'sockfd' into 'buf'. Block until all data is written or an read error occurs.
  
	@param fd: valid file descriptor
	@param buf: buffer, where the data is stored
	@param len: number of bytes, which should be written

	@return returns 1 on success, 0 otherwise.
*/
int tcp_write_2(int fd, void *buf, size_t len)
{
	#ifdef LWIP
		u8_t * p = buf;
	#else
		uint8_t * p = buf;
	#endif
	int result;
	while(len != 0){
		result = write(fd, p, len);
		if(result == -1) return 0;
		
		p += result;
		len -= result;
	}
	return 1;
}



/**
	receives image stream header information.

	@param fd: valid file descriptor
	@param ip: image parameters, including channels, depth, width and height
 	@return returns 1 on success, 1 on error
*/
/*int recv_header(int fd, struct ImageParams * ip)
{
	if(!tcp_read_2(fd, ip, sizeof *ip)) return 0;
	
	ip->nChannels = ntohl(ip->nChannels);
	ip->depth = ntohl(ip->depth);		///< image depth per channel
	ip->width = ntohl(ip->width);		///< image width
	ip->height = ntohl(ip->height);		///< image height
	
	return 1;
}*/



/**
	reads region information

	@param region: pointer to input region array

*/
/*void read_region_information(int * region){

	// buffer for incomming data
	#ifdef LWIP
		u8_t line [16];
		u8_t * p;
	#else
		uint8_t line[16];
		uint8_t * p;
	#endif
 	int i;

	// get information over tcp
  	tcp_read_2(fd, line, 16);
	p = line;

	for (i=0; i<4; i++){

		// get information
		region[i] = p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24);
		// next information
		p += 4;

	}
}*/




/**
	sends next sound frame back to pc
	@param output: input buffer
	@param length: buffer length	
*/
void send_sound_frame( char * output, int length  ){
  
	tcp_write_2(fd, (void *)output, length);

}


/**
	establishes connection to ethernet

	@param port: port number for videotransfer
	@param region: pointer to input region array
	@return returns '0' if connection is established, else '1'
*/
int establish_connection(int port, int * region){

   
	
	// *** init network interfaces *******************************************
        init_all_network_interfaces();
	if(!eth0_up){
		printf("failed to initialize eth0\naborting\n");
		return 1;
       	}
	else{
		printf(" eth0 up\n");
	}

	
        printf("\n\n");
	printf("##############################################\n");
	printf("#       START TO RECEIVE AUDIO FRAMES        #\n");
	printf("##############################################\n");
	printf("\n\n");
	
	// *** tcp/ip connect ****************************************************
	printf("waiting for connection...\n");
	fd = accept_connection(port);
	if(fd < 0){
		printf("connection failed\naborting\n");
		return 1;
	}
	printf("connection established\n");
	
	/*if(!recv_header(fd, &imageParams)){
		printf("failed reading image parameters (header)\n");
		return 1;
	}*/

        // read first frame
        //receive_sound_frame();

        // read region information
        //read_region_information(region);
        return 0;

}




/**
	writes next sound frame to specific ram
	@param input: input buffer
	@param length: buffer length
*/
void receive_sound_frame( char * input, int length ){
            
	// receive next sound frame
	tcp_read_2(fd, (void *)input, length);
}


