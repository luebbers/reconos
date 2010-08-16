/***************************************************************************
 * global.h: Global definitions and constants
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * ??.03.2007	Enno Luebbers	Added compile time switches for HW thread
 * *************************************************************************/
#ifndef GLOBAL_H
#define GLOBAL_H

#define WIDTH 320
#define HEIGHT 240

// four lines
#define DGRAM_SIZE 1280

// how many dgrams per calculation block
#define DGRAMS_PER_BLOCK 60

// inferred constants
#define LINES_PER_DGRAM (DGRAM_SIZE / WIDTH)
#define DGRAMS_PER_FRAME (HEIGHT / LINES_PER_DGRAM)
#define BLOCK_SIZE (DGRAMS_PER_BLOCK*DGRAM_SIZE)
#define LINES_PER_BLOCK (LINES_PER_DGRAM*DGRAMS_PER_BLOCK)

// comment these in or out as desired
//#define USE_HW_LAPLACE 1
//#define USE_DCACHE 1
//#define USE_HW_DISPLAY 1

//#define DO_STATETRACE 1
//#define DO_PROFILE 1


#endif

