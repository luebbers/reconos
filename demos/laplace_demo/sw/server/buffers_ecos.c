/***************************************************************************
 * buffer_ecos.c: Image processing threads
 *             
 * Defines thread entry and support functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	    File created
 * 04.04.2007	Enno Luebbers	changed thread to info structure
 * *************************************************************************/
#include "buffers_ecos.h"
#include "udp_connection.h"
#include "utils.h"
#include "global.h"
#include <cyg/hal/lcd_support.h>
#include "xcache_l.h"
#include "xparameters.h"

volatile int vsync = 0;

// for recv timing
#include <sys/select.h>

//***** profiling variables *****
#include "profile.h"
struct profile_t 
	p_recv_waitForPacket,
	p_recv_readPacket,
	p_recv_calcPacket,
	p_recv_semWait,
	p_recv_memWrite,
	p_recv_semPost,
	p_disp_semWait,
	p_disp_memCpy,
	p_disp_semPost,
	p_laplace_semWait0,
	p_laplace_semWait1,
	p_laplace_memAndCalc,
	p_laplace_semPost0,
	p_laplace_semPost1;

//*******************************

#ifndef MAX
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#endif
#ifndef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

// returns 1 if all profiles have accumulated at least PROFILE_AVERAGE_LOOPS measurements
int allProfiled() {
	if (p_recv_waitForPacket.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_recv_readPacket.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_recv_calcPacket.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_recv_semWait.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_recv_memWrite.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_recv_semPost.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_disp_semWait.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_disp_memCpy.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_disp_semPost.loops < PROFILE_AVERAGE_LOOPS) return 0;
#ifndef USE_HW_LAPLACE	
	if (p_laplace_semWait0.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_laplace_semWait1.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_laplace_memAndCalc.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_laplace_semPost0.loops < PROFILE_AVERAGE_LOOPS) return 0;
	if (p_laplace_semPost1.loops < PROFILE_AVERAGE_LOOPS) return 0;
#endif
	return 1;
}

// returns 1 if any profile has reached PROFILE_AVERAGE_LOOPS
int oneProfiled() {
	if (p_recv_waitForPacket.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_recv_readPacket.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_recv_calcPacket.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_recv_semWait.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_recv_memWrite.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_recv_semPost.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_disp_semWait.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_disp_memCpy.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_disp_semPost.loops >= PROFILE_AVERAGE_LOOPS) return 1;
#ifndef USE_HW_LAPLACE	
	if (p_laplace_semWait0.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_laplace_semWait1.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_laplace_memAndCalc.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_laplace_semPost0.loops >= PROFILE_AVERAGE_LOOPS) return 1;
	if (p_laplace_semPost1.loops >= PROFILE_AVERAGE_LOOPS) return 1;
#endif
	return 0;
}



void printAllProfiles() {

	// evaluate all profiles
	profile_eval(&p_recv_waitForPacket);
	profile_eval(&p_recv_readPacket);
	profile_eval(&p_recv_calcPacket);
	profile_eval(&p_recv_semWait);
	profile_eval(&p_recv_memWrite);
	profile_eval(&p_recv_semPost);
	profile_eval(&p_disp_semWait);
	profile_eval(&p_disp_memCpy);
	profile_eval(&p_disp_semPost);
#ifndef USE_HW_LAPLACE	
	profile_eval(&p_laplace_semWait0);
	profile_eval(&p_laplace_semWait1);
	profile_eval(&p_laplace_memAndCalc);
	profile_eval(&p_laplace_semPost0);
	profile_eval(&p_laplace_semPost1);
#endif
	
	// print all profiles
	profile_print(&p_recv_waitForPacket, "p_recv_waitForPacket");
	profile_print(&p_recv_readPacket,    "p_recv_readPacket   ");
	profile_print(&p_recv_calcPacket,    "p_recv_calcPacket   ");
	profile_print(&p_recv_semWait,       "p_recv_semWait      ");
	profile_print(&p_recv_memWrite,      "p_recv_memWrite     ");
	profile_print(&p_recv_semPost,       "p_recv_semPost      ");
	profile_print(&p_disp_semWait,       "p_disp_semWait      ");
	profile_print(&p_disp_memCpy,        "p_disp_memCpy       ");
	profile_print(&p_disp_semPost,       "p_disp_semPost      ");
#ifndef USE_HW_LAPLACE	
	profile_print(&p_laplace_semWait0,   "p_laplace_semWait0  ");
	profile_print(&p_laplace_semWait1,   "p_laplace_semWait1  ");
	profile_print(&p_laplace_memAndCalc, "p_laplace_memAndCalc");
	profile_print(&p_laplace_semPost0,   "p_laplace_semPost0  ");
	profile_print(&p_laplace_semPost1,   "p_laplace_semPost1  ");
#endif
	
}



/******************************************************************************
 * PRINTTRACE
 ******************************************************************************/
void printTrace() {

	unsigned int *ptr = (unsigned int *)XPAR_OPB_BRAM_IF_CNTLR_0_BASEADDR;
	unsigned int i = 0;
	unsigned int size = XPAR_OPB_BRAM_IF_CNTLR_0_HIGHADDR - XPAR_OPB_BRAM_IF_CNTLR_0_BASEADDR + 1;
	unsigned int time;
	unsigned char state;
	
	for(i = 0; i < size/4; i++) {
		state = ptr[i] >> 28;
		time = ptr[i] & 0x0FFFFFFF;
		diag_printf("%x, %u\n", state, time);
	}

}


///
/// Initialize buffe thread info structure
///
/// \param	bti				buffer thread info structure
/// \param	num_buffers		number of buffers (usually 2 for double buffering)
/// \param	src				source buffer(s)
/// \param	dst				destination buffer(s)
///
/// \returns	1 (always)
///
int buffer_thread_info_init(
								struct buffer_thread_info * bti,
								unsigned int num_buffers, 
								struct byte_buffer *src,
								struct byte_buffer *dst/*, 
								cyg_sem_t *rdy0, 
								cyg_sem_t *rdy1, 
								cyg_sem_t *new0, 
								cyg_sem_t *new1*/
							)

{
	bti->num_buffers = num_buffers;
	bti->src = src;
	bti->dst = dst;
	bti->data = (cyg_addrword_t)0;
/*    bti->rdy0 = rdy0;
    bti->rdy1 = rdy1;
    bti->new0 = new0;
    bti->new1 = new1;*/

	return 1;	
}




/******************************************************************************
 * ENTRY_BUFFER_RECV
 ******************************************************************************/
void entry_buffer_recv(cyg_addrword_t p_buffer_thread){
	struct buffer_thread_info * bti = (struct buffer_thread_info*)p_buffer_thread;
	struct udp_connection * con = (struct udp_connection*)bti->data;
	unsigned char * buffer;
	u_int32_t dgram_buffer[DGRAM_SIZE/4 + 1];
	size_t len = WIDTH*HEIGHT;
	unsigned int bufnum; 		// which buffer to write to
	unsigned int adr, k;
	
/*--- for recvfrom timing ---*/
	fd_set fds;
	int retval;
	FD_ZERO(&fds);
	FD_SET(con->local_fd, &fds);
	
	profile_init(&p_recv_waitForPacket);
	profile_init(&p_recv_readPacket);
	profile_init(&p_recv_calcPacket);
	profile_init(&p_recv_semWait);
	profile_init(&p_recv_memWrite);
	profile_init(&p_recv_semPost);

	dgram_buffer[0] = 0;
	diag_printf("recv thread\n");
	
	bufnum = 0;
	
	while(1){
		int seq_end = len/DGRAM_SIZE;
		int seq = -1;
		
		while(seq < seq_end - 1){
			buffer = bti->dst[bufnum].data;
			size_t fromlen = sizeof(con->remote_addr);

//			diag_printf("capture: waiting for rdy_sem[%u]\n", bufnum);
			profile_start(&p_recv_semWait);
			cyg_semaphore_wait(&bti->dst[bufnum].rdy_sem);
			profile_stop(&p_recv_semWait);
//			diag_printf("capture: got it\n");

			for (k = 0; k < DGRAMS_PER_BLOCK; k++) {
			
/*--- for recvfrom timing ---*/
				profile_start(&p_recv_waitForPacket);
				retval = select(con->local_fd+1, &fds, NULL, NULL, NULL);
				if (retval == -1) {
					util_perror("select");
				}
				if (!FD_ISSET(con->local_fd, &fds)) {
					util_perror("select FD_ISSET");
				}
				profile_stop(&p_recv_waitForPacket);
				
				// this takes around 640 usec for one packet (with no DCACHE)
				//                   117 usec                ( with DCACHE  )
				profile_start(&p_recv_readPacket);
				int result = recvfrom(con->local_fd, dgram_buffer, DGRAM_SIZE + 4, 0, 
						(struct sockaddr*)&(con->remote_addr), &fromlen);
				if(result == -1){
					util_perror("recvfrom");
				} 
				profile_stop(&p_recv_readPacket);
	
	
				profile_start(&p_recv_calcPacket);
	
				// check for dropped frames
				if((int)dgram_buffer[0] != seq+1){
					diag_printf("*");//invalid sequence number %u\n",dgram_buffer[0]);
				}
				
/*				// check for missed vsync
				if ((int)dgram_buffer[0] <= seq) {
					break;
				}*/
				seq = dgram_buffer[0];
	
				profile_stop(&p_recv_calcPacket);
	
				profile_start(&p_recv_memWrite);
				// copy received data to buffer for filter thread
				memcpy( buffer+k*DGRAM_SIZE, dgram_buffer + 1, result - 4 );
				
#if defined(USE_HW_LAPLACE)
#if defined(USE_DCACHE)			
				// store cachelines to memory
				for (adr = (unsigned int)buffer; adr < (unsigned int)buffer+BLOCK_SIZE; adr += 32) {
					XCache_StoreDCacheLine(adr);
				}
#endif
#endif
				profile_stop(&p_recv_memWrite);
			} // for (k)
	
//			diag_printf("capture: posting for new_sem[%u]\n", bufnum);
			profile_start(&p_recv_semPost);
			cyg_semaphore_post(&bti->dst[bufnum].new_sem);
			profile_stop(&p_recv_semPost);
//			diag_printf("capture: posted\n");

			bufnum = (bufnum + 1) % bti->num_buffers; 
			
		}
	}
}



/******************************************************************************
 * ENTRY_BUFFER_DISPLAY
 ******************************************************************************/
void entry_buffer_display(cyg_addrword_t p_buffer_thread){
	struct buffer_thread_info * bti = (struct buffer_thread_info*)p_buffer_thread;
	struct byte_buffer * src = &bti->src[0];
	struct lcd_info fb_info;
	int i,j,x, f=0;
	unsigned char * src_addr;
	unsigned int * dst_addr;
	unsigned int adr, bufnum;
	
	diag_printf("\t\t\t\t\t\tdisplay thread\n");

	profile_init(&p_disp_semWait);
	profile_init(&p_disp_memCpy);
	profile_init(&p_disp_semPost);

	//lcd_getinfo(&fb_info);
	
	if(!src) return;
	
	bufnum = 0;
	
	while(1){
		
		//dst_addr = fb_info.fb;                        
		dst_addr = (unsigned int*)bti->dst[0].data;                        

		for(i = 0; i < HEIGHT / LINES_PER_BLOCK ; i++) {

			// select current buffer
			src = &bti->src[bufnum];

			profile_start(&p_disp_semWait);

//			diag_printf("\t\t\t\t\t\tdisplay: waiting for new_sem[%u]\n", bufnum);
			cyg_semaphore_wait(&src->new_sem);
//			diag_printf("\t\t\t\t\t\tdisplay: got it\n");

			profile_stop(&p_disp_semWait);

//			profile_start(&display_prof);

//			diag_printf("\t\t\t\t\t\tdisplay: showing %u\n", i);

			profile_start(&p_disp_memCpy);

			src_addr = src->data;

#if defined(USE_HW_LAPLACE)
#if defined(USE_DCACHE)			
			// invalidate cachelines
			for (adr = (unsigned int)src_addr; adr < (unsigned int)src_addr+BLOCK_SIZE; adr += 32) {
				XCache_FlushDCacheLine(adr);
			}
#endif
#endif

			for (j = 0; j < LINES_PER_BLOCK; j++) {
				for(x = 0; x < WIDTH; x++){
					*(dst_addr++) = (0x00 << 24) | (*src_addr << 16) | (*src_addr << 8) | *src_addr;
					src_addr++;
				}
				dst_addr += 1024-WIDTH;
			}


			profile_stop(&p_disp_memCpy);


//			profile_stop(&display_prof);

//			diag_printf("\t\t\t\t\t\tdisplay: posting rdy_sem[%u]\n", bufnum);
			profile_start(&p_disp_semPost);

			cyg_semaphore_post(&src->rdy_sem);

			profile_stop(&p_disp_semPost);
//			diag_printf("\t\t\t\t\t\tdisplay: posted\n");

			bufnum = (bufnum + 1) % bti->num_buffers; 

		}

#ifdef DO_STATETRACE
//		cyg_semaphore_post(&sem_frameAck);
		if (++f == 30) {
			printTrace();
			while(1);
		}
#endif

#ifdef DO_PROFILE
		if ( oneProfiled() ) {
			printAllProfiles();
			while (1);
		}
#endif

/*		profile_print(&recv_prof,    "recv_prof   ");
		profile_print(&display_prof, "display_prof");
		profile_print(&laplace_prof, "laplace_prof");*/
		
	}
}


/******************************************************************************
 * ENTRY_BUFFER_LAPLACE
 ******************************************************************************/
//  Laplace-Filter: Faltung mit folgendem Kernel:  0  2  0             k[0] 
//                                                 2 -8  2    =   k[1] k[4] k[2]
//                                                 0  2  0             k[3]
//
void laPlacian1(unsigned char *src, unsigned char *dst) {
	unsigned char *k[5];
	int j,x;
	int result = 0;

	// set pointers to kernel coefficients != 0
	k[0] = src+1;
	k[1] = src+WIDTH;
	k[4] = src+WIDTH+1;
	k[2] = src+WIDTH+2;
	k[3] = src+2*WIDTH+1;
				
	for (j = 0; j < LINES_PER_BLOCK; j++) {
		for(x = 0; x < WIDTH; x++){
//                               (  k[0]    +   k[1]    +   k[2]    +   k[3]    -  4 * k[4]     ) * 2
			result = (*(k[0]++) + *(k[1]++) + *(k[2]++) + *(k[3]++) - (*(k[4]++)<<2)) << 1;
			// clip (prevent overflow)
			result = MAX(0,result);
			result = MIN(255,result);
			
			*(dst++) = result;
		}
	}
}

//  Laplace-Filter: Faltung mit folgendem Kernel:  1  1  1          k[0] k[1] k[2]
//                                                 1 -8  1   *2 =   k[3] k[4] k[5]
//                                                 1  1  1          k[6] k[7] k[8]
//
void laPlacian2(unsigned char *src, unsigned char *dst) {
	unsigned char *k[9];
	int j,x;
	int result = 0;

	// set pointers to kernel coefficients != 0
	k[0] = src;
	k[1] = src+1;
	k[2] = src+2;
	k[3] = src+WIDTH;
	k[4] = src+WIDTH+1;
	k[5] = src+WIDTH+2;
	k[6] = src+2*WIDTH;
	k[7] = src+2*WIDTH+1;
	k[8] = src+2*WIDTH+2;
				
	for (j = 0; j < LINES_PER_BLOCK; j++) {
		for(x = 0; x < WIDTH; x++){
			result = (*(k[0]++) + *(k[1]++) + *(k[2]++) + *(k[3]++) +
				  *(k[5]++) + *(k[6]++) + *(k[7]++) + *(k[8]++) -			
				  (*(k[4]++)<<3)) << 1;
			// clip (prevent overflow)
			result = MAX(0,result);
			result = MIN(255,result);
			
			*(dst++) = result;
		}
	}
}



//  Laplace-Filter: Faltung mit folgendem Kernel:  1  1  1          k[0] k[1] k[2]
//                                                 1 -8  1   *2 =   k[3] k[4] k[5]
//                                                 1  1  1          k[6] k[7] k[8]
//
void laPlacian3(unsigned char *src, unsigned char *dst) {
	unsigned char *k[25];
	int i,j,x,y;
	int result = 0;

	// set pointers to kernel coefficients != 0
	for (y = 0; y < 5; y++) {
		for (x = 0; x < 5; x++) {
			k[5*y+x] = src+y*WIDTH+x;
		}
	}
				
	for (j = 0; j < LINES_PER_BLOCK; j++) {
		for(i = 0; i < WIDTH; i++){
			for (y = 0; y < 25; y++) {
				result += *(k[y]++);
			}
			result -= *(k[11])*25;
			
//			result *= 2;
			
			// clip (prevent overflow)
			result = MAX(0,result);
			result = MIN(255,result);
			
			*(dst++) = result;
		}
	}
}





void entry_buffer_laplace(cyg_addrword_t p_buffer_thread){
	struct buffer_thread_info * bti = (struct buffer_thread_info*)p_buffer_thread;
	unsigned char *src = NULL, *dst = NULL;
	unsigned int adr, bufnum;
	
	diag_printf("\t\t\tlaplace thread\n");
	
	profile_init(&p_laplace_semWait0);
	profile_init(&p_laplace_semWait1);
	profile_init(&p_laplace_memAndCalc);
	profile_init(&p_laplace_semPost0);
	profile_init(&p_laplace_semPost1);
	
	if(!bti->src) {
		diag_printf("\t\t\tlaplace: no src!\n");
		return;
	}
	if(!bti->dst) {
		diag_printf("\t\t\tlaplace: no dst!\n");
		return;
	}
	
	bufnum = 0;
	
	while(1){
		
//		diag_printf("\t\t\tlaplace: waiting for new0\n");
		profile_start(&p_laplace_semWait0);
		cyg_semaphore_wait(&bti->src[bufnum].new_sem);
		profile_stop(&p_laplace_semWait0);
//		diag_printf("\t\t\tlaplace: got new0\n");
//		diag_printf("\t\t\tlaplace: waiting for rdy1\n");
		profile_start(&p_laplace_semWait1);
		cyg_semaphore_wait(&bti->dst[bufnum].rdy_sem);
		profile_stop(&p_laplace_semWait1);
//		diag_printf("\t\t\tlaplace: got rdy1\n");

//		diag_printf("\t\t\tlaplace: calculating %u\n", i++);

		profile_start(&p_laplace_memAndCalc);

		// initialize source and destination data pointers		
		src = bti->src[bufnum].data;
		dst = bti->dst[bufnum].data; 
		
		laPlacian1(src, dst);

		profile_stop(&p_laplace_memAndCalc);

#if defined(USE_HW_DISPLAY)
#if defined(USE_DCACHE)			
		// store cachelines to memory
		for (adr = (unsigned int)dst; adr < (unsigned int)dst + BLOCK_SIZE; adr += 32) {
			XCache_StoreDCacheLine(adr);
		}
#endif
#endif



//		profile_stop(&laplace_prof);
//		diag_printf("\t\t\tlaplace: posting rdy0\n");
		profile_start(&p_laplace_semPost0);
		cyg_semaphore_post(&bti->src[bufnum].rdy_sem);
		profile_stop(&p_laplace_semPost0);
//		diag_printf("\t\t\tlaplace: posting new1\n");
		profile_start(&p_laplace_semPost1);
		cyg_semaphore_post(&bti->dst[bufnum].new_sem);
		profile_stop(&p_laplace_semPost1);

		bufnum = (bufnum + 1) % bti->num_buffers; 

	}	
}





