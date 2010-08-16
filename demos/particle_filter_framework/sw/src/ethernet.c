//#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "../header/ethernet.h"
#include "../header/bgr2hsv.h"
#include "../header/tft_screen.h"
//#include "../framework/header/particle_filter.h"
#include "../framework/header/timing.h"

#ifndef NO_ETHERNET

//#define LWIP 1
#ifdef LWIP
#include <lwip/inet.h>
#include <lwip/sockets.h>
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <network.h>
#include <reconos/reconos.h>
#include <unistd.h>
#endif


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
particle_data * particles_data; 

//! valid  file descriptor
static int fd;

//! framebuffer pointer
unsigned int framebuffer;




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
        #ifdef LWIP
        u8_t * p = buf;
        #else
        uint8_t * p = buf;
        #endif
        int result;
        //diag_printf("\n[ethernet.c]<<<<<start tcp read");
	while(len > 0){
                result = read(fd, p, len);
                //diag_printf("\n[ethernet.c]<<<<<get tcp package (len: %d, result: %d)", (int) len, result);
		if(result == -1){
			//diag_printf("\n[ethernet.c]<<<<<package = -1 (error)");
			return 0;
		}		
		//diag_printf("\n[ethernet.c]<<<<<before p, len adjustment");
		p += result;
		//diag_printf("\n[ethernet.c]<<<<<updated buffer pointer");
		len -= result;
		//diag_printf("\n[ethernet.c]<<<<<updated length");
	}
	//diag_printf("\n[ethernet.c]<<<<<get tcp_read_2 done");
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

int recv_header(int fd, struct ImageParams * ip)
{
	if(!tcp_read_2(fd, ip, sizeof *ip)) return 0;
	
	ip->nChannels = ntohl(ip->nChannels);
	ip->depth = ntohl(ip->depth);		///< image depth per channel
	ip->width = ntohl(ip->width);		///< image width
	ip->height = ntohl(ip->height);		///< image height
	
	return 1;
}



/**
  reads region information

  @param region: pointer to input region array

*/
void read_region_information(int * region){

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
}




/**
   sends particles back to pc

  @param particle_array: array of particle, which have to be send back
  @param array_size: size of particle array
*/
void send_particles_back( particle * particle_array, int array_size ){

    
   // buffer for outgoing particle array data
   //uint8_t line[(N+1) * 5];
   int i;
   int medium_x = 0, medium_y = 0, medium_s = 0;
   particle * p;

   for (i=0; i<array_size; i++){

         p = &particle_array[i];

         // calculate best particle (= medium) 
         medium_x += p->x;
         medium_y += p->y;
         medium_s += p->s;

         // calculate bounding_box
         particles_data[i].x1 = (p->x / PF_GRANULARITY)  - ((p->s * (( p->width - 1) / 2)) / PF_GRANULARITY);
         particles_data[i].x2 = (p->x / PF_GRANULARITY)  + ((p->s * (( p->width - 1) / 2)) / PF_GRANULARITY);
         
         particles_data[i].y1 = (p->y / PF_GRANULARITY)  - ((p->s * (( p->height - 1) / 2)) / PF_GRANULARITY);
         particles_data[i].y2 = (p->y / PF_GRANULARITY)  + ((p->s * (( p->height - 1) / 2)) / PF_GRANULARITY);

         particles_data[i].best_particle = FALSE;

         //printf("\nParticle[%d]:\t x1 = %u,\t y1 = %u,\t x2 = %d,\t y2 = %u,\t Best Particle = %u", i, particles_data[i].x1, particles_data[i].y1 , particles_data[i].x2 , particles_data[i].y2  , particles_data[i].best_particle);

   }

   medium_x /= array_size;
   medium_y /= array_size;
   medium_s /= array_size;

   // calculate bounding_box for best particle
   particles_data[array_size].x1 = (medium_x / PF_GRANULARITY)  - ((medium_s * (( particles[0].width - 1) / 2)) / PF_GRANULARITY);
   particles_data[array_size].x2 = (medium_x / PF_GRANULARITY)  + ((medium_s * (( particles[0].width - 1) / 2)) / PF_GRANULARITY);
         
   particles_data[array_size].y1 = (medium_y / PF_GRANULARITY)  - ((medium_s * (( particles[0].height - 1) / 2)) / PF_GRANULARITY);
   particles_data[array_size].y2 = (medium_y / PF_GRANULARITY)  + ((medium_s * (( particles[0].height - 1) / 2)) / PF_GRANULARITY);

   particles_data[array_size].best_particle = TRUE;
   
   tcp_write_2(fd, (void *)particles_data, ((array_size+1)*sizeof(particle_data)));

}



/**
   sends best particle back to pc

  @param particle_array: array of particle, which have to be send back
  @param array_size: size of particle array
*/
void send_best_particle_back(particle * particle_array, int array_size ){


   // buffer for outgoing particle array data
   //uint8_t line[(N+1) * 5];
   int i;
   int medium_x = 0, medium_y = 0, medium_s = 0;
   particle * p;

   for (i=0; i<array_size; i++){

         p = &particle_array[i];

         // calculate best particle (= medium) 
         medium_x += p->x;
         medium_y += p->y;
         medium_s += p->s;
   }

   medium_x /= array_size;
   medium_y /= array_size;
   medium_s /= array_size;

   // calculate bounding_box for best particle
   particles_data[0].x1 = (medium_x / PF_GRANULARITY)  - ((medium_s * (( particles[0].width - 1) / 2)) / PF_GRANULARITY);
   particles_data[0].x2 = (medium_x / PF_GRANULARITY)  + ((medium_s * (( particles[0].width - 1) / 2)) / PF_GRANULARITY);
         
   particles_data[0].y1 = (medium_y / PF_GRANULARITY)  - ((medium_s * (( particles[0].height - 1) / 2)) / PF_GRANULARITY);
   particles_data[0].y2 = (medium_y / PF_GRANULARITY)  + ((medium_s * (( particles[0].height - 1) / 2)) / PF_GRANULARITY);

   particles_data[0].best_particle = TRUE;
   
   tcp_write_2(fd, (void *)particles_data, sizeof(particle_data));

}






/**
   establishes connection to ethernet

   @param port: port number for videotransfer
   @param region: pointer to input region array
   @return returns '0' if connection is established, else '1'
*/
int establish_connection(int port, int * region){

   
        int i;
#ifndef STORE_VIDEO
        timing_t t_start = 0, t_stop = 0, t_result = 0;
#endif


	// *** init display ******************************************************
	tft_init();
 

#ifdef STORE_VIDEO
        framebuffer = (unsigned int) tft_loading.fb;
#endif
	
	// *** init network interfaces *******************************************
	#ifdef LWIP
        lwip_init();
        #else
        //init_all_network_interfaces();
	//if(!eth0_up){
	//	printf("failed to initialize eth0\naborting\n");
	//	return 1;
       	//}
	//else{
	//	printf(" eth0 up\n");
	//}
        #endif
	
        printf("\n\n");
	printf("########################################\n");
	printf("#       START TO RECEIVE FRAMES        #\n");
	printf("########################################\n");
	printf("\n\n");
	
	// *** tcp/ip connect ****************************************************
	printf("waiting for connection...\n");
	fd = accept_connection(port);
	if(fd < 0){
		printf("connection failed\naborting\n");
		return 1;
	}
	printf("connection established\n");
	
	if(!recv_header(fd, &imageParams)){
		printf("failed reading image parameters (header)\n");
		return 1;
	}
	
	printf("\n");
        printf("Image stream header:  width = %d\n", imageParams.width);
	printf("                     height = %d\n", imageParams.height);
	printf("                        bpc = %d\n", imageParams.depth);
	printf("                   channels = %d\n", imageParams.nChannels);


        // read first frame
        read_frame();

        // read region information
        read_region_information(region);

#ifndef STORE_VIDEO
        // load first frames
        for(i=0; i<2; i++){

             switch_framebuffer();
             t_start = gettime();
	     read_frame();
             t_stop = gettime();
             t_result = calc_timediff(t_start, t_stop);
             printf("\nRead Frame: %d", t_result);
        };      

#endif


        // set height and width of frames to maximum x and y values
        SIZE_X = MIN ( imageParams.width, MAX_SIZE_X);
        SIZE_Y = MIN ( imageParams.height, MAX_SIZE_Y);

        // create array for hsvImage
        hsvImage = (int **) malloc (SIZE_X * sizeof (int *));
        for (i=0; i<SIZE_X; i++){
          
	      hsvImage[i] = (int *) malloc (SIZE_Y * sizeof(int));
        }

        // create partice data for one frame
        particles_data = (particle_data *) malloc ((N+1) * sizeof(particle_data));
        
        return 0;

}


/** 
   resets the framebuffer
*/
void reset_the_framebuffer(){

     reset_framebuffer();
     framebuffer = (unsigned int) tft_loading.fb;
}


/**
  reads next frame from ethernet and writes next frame to specific ram

*/
void read_frame(  ){
            
                // current pixel coordinates
                int x,y;
                // number of bytes between the end of a line in the framebuffer
                // and the beginning of the next line.
                int step = tft_loading.rlen/4 - imageParams.width;
                // buffer for incomming pixel data
                #ifdef LWIP
                u8_t line[4096];
                u32_t * fb_pos;
                u8_t * p;
                #else
                uint8_t line[4096];
                uint32_t * fb_pos;
                //current position
                uint8_t * p;
                #endif

                // frame buffer pointer
#ifdef STORE_VIDEO
                #ifdef LWIP
		fb_pos = (u32_t*)framebuffer;
                #else
                fb_pos = (uint32_t*)framebuffer;
                #endif
#else
                fb_pos = tft_loading.fb;
#endif

                //diag_printf("\n[ethernet.c]<<<<<start to read frame");
                for(y = 0; y < imageParams.height; y++){
			// read a line into the buffer
			tcp_read_2(fd, line, imageParams.depth/8*imageParams.nChannels*imageParams.width);
			// current position
			p = line;
		        //diag_printf("\n[ethernet.c]<<<<<received tcp packet");	
			for(x = 0; x < imageParams.width; x++){
				// write pixel to framebuffer
				*fb_pos = p[0] | (p[1] << 8) | (p[2] << 16);
				// next pixel
				p += 3;
				fb_pos++;
			}
			// next line
			fb_pos += step;
		}
                //diag_printf("\n[ethernet.c]<<<<<received entire frame");

#ifdef STORE_VIDEO
                framebuffer += framebuffer_space;
#endif
              
}

#else

//! framebuffer pointer
unsigned int framebuffer;

/**
  reads next frame from ethernet and writes next frame to specific ram

*/
void read_frame(  ){}

/** 
   resets the framebuffer
*/
void reset_the_framebuffer(){

     reset_framebuffer();
     framebuffer = (unsigned int) tft_loading.fb;
}

#endif


