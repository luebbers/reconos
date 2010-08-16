#include <stdlib.h>
#include <stdio.h>
#include <xparameters.h>
#include <xio_dcr.h>
#include "../header/tft_screen.h"

//! index for different framebuffers: (i) loading, (ii) editing, (iii) display
int display_fb, editing_fb, loading_fb;

//! information for the three framebuffer
struct lcd_info fb_info[3];

//! frame counter, stops when frame counter is at least 4;
int frame_counter;

//! addresses for framebuffer
void * fb[3];

//! framebuffer pointer to start address
void * framebuffer_start;


/**
   sets a pixel (x, y) in a specific RGB value

   @param x: x coordinate of pixel
   @param y: y coordinate of pixel
   @param r: red component of pixel
   @param g: green component of pixel
   @param b: blue component of pixel
 */
void tft_set_pixel(int x, int y, unsigned int r, unsigned int g, unsigned int b){
	
        r = r & 0xFF;
	g = g & 0xFF;
	b = b & 0xFF;
	((cyg_uint32*)tft_editing.fb)[x + y*tft_editing.rlen/4] = b | (g << 8) | (r << 16);
}


/**
   sets a pixel (x, y) in a specific RGB value

   @param framebuffer: address to framebuffer
   @param x: x coordinate of pixel
   @param y: y coordinate of pixel
   @param r: red component of pixel
   @param g: green component of pixel
   @param b: blue component of pixel
 */
void tft_set_pixel_fb(void * framebuffer, int x, int y, unsigned int r, unsigned int g, unsigned int b){
	
        r = r & 0xFF;
	g = g & 0xFF;
	b = b & 0xFF;
	((cyg_uint32*)framebuffer)[x + y*tft_editing.rlen/4] = b | (g << 8) | (r << 16);
}


/**
 clear framebuffer with black background

 @param framebuffer_number: number of framebuffer (editing_fb, loading_fb or display_fb)

*/
void tft_clear (int framebuffer_number){

    
   int x; int y;
   
   for (x=0; x<tft_editing.width; x++)
        for (y=0; y<tft_editing.height; y++)
          // draw black pixel
	  tft_set_pixel_fb ((void *)fb[framebuffer_number], x, y, 0, 0, 0);
}


/**
 clears all framebuffers with black background

*/
void tft_clear_all (){

    
   int i; int x; int y;
   void * framebuffer;
  
   framebuffer = fb[0];   

#ifdef MAX_FRAMES
   for (i=0; i<MAX_FRAMES; i++){
#else
   for (i=0; i<1; i++){
#endif

      for (x=0; x<tft_editing.width; x++)
        for (y=0; y<tft_editing.height; y++)
          // draw black pixel
	  tft_set_pixel_fb (framebuffer, x, y, 0, 0, 0);

      framebuffer += framebuffer_space;

   }
}


/**
  resets framebuffer to start address
*/
void reset_framebuffer(){

    fb[0] = framebuffer_start;
    tft_loading.fb = framebuffer_start;
    tft_editing.fb = framebuffer_start;
}


/**
 initializes vga display. Two framebuffers are used. One framebuffer will contain the working process, while the other will be displayed. After the working process is over, the first framebuffer will be displayed, while the other framebuffer will be in the working process (get new frame->particle filter->display particles)
*/
void tft_init(){


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //             W I T H     S T O R E D    V I D E O                                                       //
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////          

  // TODO: no VGA Controler: Not working for storing a video
#ifdef STORE_VIDEO 
 
#ifndef HWMEASURE
       framebuffer_space = 0x200000;
#else
        // set framebuffer space 
       //framebuffer_space = 0x96000;  
       //fb[0] = (void *) malloc ((MAX_FRAMES+2) * 1024 * 1024 * 2);
       framebuffer_space = 0x200000;
       //changeMe(1/2)
#endif
        
        // init and clear TFT
#ifndef NO_VGA_FRAMEBUFFER
        lcd_init(24);
	lcd_clear();
	lcd_getinfo(&fb_info[0]);

        //information about tft framebuffer
        printf("TFT framebuffer: width : %d\n", fb_info[0].width);
	printf("                 height: %d\n", fb_info[0].height);
	printf("                 bpp   : %d\n", fb_info[0].bpp);
	printf("                 type  : %d\n", fb_info[0].type);
	printf("                 rlen  : %d\n", fb_info[0].rlen);
#else

        fb_info[0].width  = 640;
        fb_info[0].height = 480;
        fb_info[0].bpp    = 32;
        fb_info[0].type   = 3;
        fb_info[0].rlen   = 4096;
#endif

        fb_info[1] = fb_info[0];
        fb_info[2] = fb_info[0];
	
        printf("\n\nThe Framebuffers in Main Memory will be initialized. This needs some time.\n");
        

        // save two additonal framebuffer addresses.
        //fb[0] = (void *) 0x04000000;
        fb[0] = (void*) malloc ((MAX_FRAMES+2)*2*1024*1024);
        framebuffer_start = fb[0];
        //changeMe(2/2)
       
        // set framebuffer for editing and loading
        tft_editing = fb_info[0];
        tft_editing.width  = 640;
        tft_editing.height = 480;
	tft_editing.fb = fb[0];
         
        tft_clear_all();

        printf("\n\nFramebuffers are intialised.\n");
        tft_loading = fb_info[0];
  
        tft_loading.fb = fb[0];
         
#ifndef NO_VGA_FRAMEBUFFER
        // display framebuffer display_fb
        XIo_DcrOut(XPAR_VGA_FRAMEBUFFER_DCR_BASEADDR, (unsigned int)fb[0]);
#endif        

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //             N O    S T O R E D    V I D E O                                                            //
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////        

#else

#ifndef NO_VGA_FRAMEBUFFER
        // read framebuffer address from DCR
        // frame buffer base address

        unsigned int fbBase = XIo_DcrIn(XPAR_VGA_FRAMEBUFFER_DCR_BASEADDR);
        
        // init and clear TFT

        printf("\nfbbase %X\nLCD_INIT Start", fbBase);
        lcd_init(24);
	printf("\nLCD_INIT End");
	lcd_clear();
	lcd_getinfo(&fb_info[0]);

        
	
        // print information about tft framebuffer
        printf("TFT framebuffer: width : %d\n", fb_info[0].width);
	printf("                 height: %d\n", fb_info[0].height);
	printf("                 bpp   : %d\n", fb_info[0].bpp);
	printf("                 type  : %d\n", fb_info[0].type);
	printf("                 rlen  : %d\n", fb_info[0].rlen);
               
        fb_info[1] = fb_info[0];
        fb_info[2] = fb_info[0];

        // defines, which framebuffer will be display first 
        display_fb = 1;
        loading_fb = 0;
        editing_fb = 2;
        
        fb[0] = (void *)fbBase;
        fb[1] = (void *)fbBase - 0x01000000;
        fb[2] = (void *)fbBase - 0x02000000;

        fb_info[0].fb = fb[0];
        fb_info[1].fb = fb[1];
        fb_info[2].fb = fb[2];
       
        // set framebuffer for editing and loading
        //fb_info[editing_fb].fb = (void *)fb[editing_fb];
        tft_editing = fb_info[editing_fb];
        tft_clear(loading_fb);
        tft_clear(editing_fb);
        tft_clear(display_fb);
        
        //fb_info[loading_fb].fb = (void *)fb[loading_fb];
        tft_loading = fb_info[loading_fb];

        //tft_editing.fb = (void *)fb[editing_fb];
        tft_loading.fb = fb[loading_fb];
        tft_editing.fb = fb[loading_fb];


        // display framebuffer display_fb
        XIo_DcrOut(XPAR_VGA_FRAMEBUFFER_DCR_BASEADDR, (unsigned int)fb[display_fb]);

#else
        
        fb_info[0].width  = 640;
        fb_info[0].height = 480;
        fb_info[0].bpp    = 32;
        fb_info[0].type   = 3;
        fb_info[0].rlen   = 4096;
       
        fb_info[1] = fb_info[0];
        fb_info[2] = fb_info[0];


        loading_fb = 0;
        editing_fb = 1;

        // save two additonal framebuffer addresses.
        fb[0] = (void *) malloc (2*1024*1024);
        fb[1] = (void *) malloc (2*1024*1024);

        fb_info[0].fb = fb[0];
        fb_info[1].fb = fb[1];
       
        // set framebuffer for editing and loading
        tft_editing = fb_info[editing_fb]; 
        tft_loading = fb_info[loading_fb];

        tft_loading.fb = fb[loading_fb];
        tft_editing.fb = fb[loading_fb];

        tft_loading.rlen = 4096;
        tft_editing.rlen = 4096;

#endif

#endif

        #ifdef HWMEASURE
        tft_editing.fb = fb[0];
        tft_loading.fb = fb[0];
        #endif
       
        // init frame counter
        frame_counter = 0; 

}


/**
 switches from one frame buffer to the other
 There are two framebuffer. One of both is in the working state, while the other is in the display state.
*/
void switch_framebuffer(){


#ifdef STORE_VIDEO 

  unsigned int show;
 
  // A] VIDEO IS STORED IN MAIN MEMORY 

  // 1) set new display address  
  show = (unsigned int)tft_editing.fb;

  // 2) set new edit address
  tft_editing.fb = (void *)((unsigned int )tft_editing.fb + framebuffer_space);

#ifndef NO_VGA_FRAMEBUFFER
  // 3) display framebuffer
  XIo_DcrOut(XPAR_VGA_FRAMEBUFFER_DCR_BASEADDR, show);
#endif


#else


  // B] VIDEO IS RECEIVED ON DEMAND VIA LAN
#ifndef NO_VGA_FRAMEBUFFER
   // switch framebuffers
   if (display_fb == 0){
       
        display_fb = 1;
        loading_fb = 0;
        editing_fb = 2;


   } else
   if (display_fb == 1){
 
        display_fb = 2;
        loading_fb = 1;
        editing_fb = 0;
   
   } else {

        display_fb = 0;
        loading_fb = 2;
        editing_fb = 1;


   }

   // set framebuffer for working process and display   
   tft_editing.fb = fb[editing_fb];
   tft_loading.fb = fb[loading_fb];
   
   //printf("\nFrame No. %d", frame_counter);

   frame_counter++;

   // before resetting the framebuffer, wait for that 2 frames are read
   
   if (frame_counter > 4)
        XIo_DcrOut(XPAR_VGA_FRAMEBUFFER_DCR_BASEADDR, (unsigned int)fb[display_fb]);
   else  {
        frame_counter++;
       XIo_DcrOut(XPAR_VGA_FRAMEBUFFER_DCR_BASEADDR, (unsigned int) fb[1]);
   }

#else

   if (loading_fb == 0){

       editing_fb = 0;
       loading_fb = 1;

   } else {

       editing_fb = 1;
       loading_fb = 0;
   }

  
   // set framebuffer for working process and display   
   tft_editing.fb = fb[editing_fb];
   tft_loading.fb = fb[loading_fb];
   
#endif


#endif

}



#ifdef HWMEASURE
/**
 changes from one frame buffer to the other. There are 50 framebuffer.
*/
void change_framebuffer(){

  tft_editing.fb = (void *)((unsigned int )tft_editing.fb + framebuffer_space);
}


/**
 resets from one frame buffer to the other. There are 50 framebuffer.
*/
void reset_framebuffer(){

  tft_editing.fb = fb[0];
}
#endif




