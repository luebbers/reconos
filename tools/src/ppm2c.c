///
/// \file ppm2c.c
///
/// Converts PPMs/PNMs into C sources
/// 
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       14.11.2007
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//


// INCLUDES ================================================================

#include "crc32.h"
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <ctype.h>
#include <string.h>

// CONSTANTS ===============================================================

#define STRLEN 80
#define SYNC_WORD 0xAA995566


// GLOBAL VARIABLES ========================================================

static char ppmFileName[STRLEN] = "";
static char cFileName[STRLEN]   = "";
static char hFileName[STRLEN]   = "";
static char arrayName[STRLEN]  = "";
static char widthName[STRLEN]  = "";
static char heightName[STRLEN]  = "";
static char depthName[STRLEN]  = "";
static unsigned int width = 0;
static unsigned int height = 0; 
static unsigned int depth = 0; 

// FUNCTION DEFINITIONS ====================================================

///
/// Writes the bitmap file as bytes (0xXX) to the destination file
///
/// \param      src       source (ppm) file stream
/// \param      dst       destination (C) file stream
/// \param      offset    offset into source file to start writing from (in bytes)
///
/// \returns number of written bytes, or 0 on error
///
unsigned int writeCFile(FILE *src, FILE *dst, int offset) {
    time_t clock = time( NULL );
    int c;
    unsigned int i = 0;
    
    fprintf(dst, "/************************************************************\n"
           " * %s : c-coded pixmap\n"
           " *\n"
           " * source file      : %s\n"
           " * associated header: %s\n"
           " * generated on     : %s"
           " ************************************************************/\n"
           "\n"
           "unsigned int %s[] __attribute__ ((aligned (4))) = {\n\t\t",
           cFileName, ppmFileName, hFileName, ctime(&clock), arrayName);
   
    c = fseek(src, (long)offset, SEEK_SET);
    if (c != 0) {
	perror("error while seeking to image start");
	return 0;
    }

    while (1) {
        c = fgetc(src);
        if (c == EOF) {
            if (errno != 0) {
                perror("error while reading");
                return 0;
            }
            fprintf(dst, "\n            };\n");
            return i;
        } else {
            if (i > 0) {
                if (i % 12 == 0) {
                    fprintf(dst, ",\n\t\t");
                } else if ( i % 3 == 0) {
                    fprintf(dst, ", ");
                }
            }
	    if ( i % 3 == 0) {
		fprintf( dst, "0x00" );
	    }
            fprintf(dst, "%02X", c);
            i++;
        }
    }

}



///
/// Writes the destination header file
///
/// \param      dst       destination (C header) file stream
///
void writeHFile( FILE *dst ) {
    time_t clock = time( NULL );

    fprintf(dst, "/************************************************************\n"
           " * %s : c-coded pixmap header\n"
           " *\n"
           " * source bitstream   : %s\n"
           " * associated C source: %s\n"
           " * generated on       : %s"
           " ************************************************************/\n"
           "\n"
           "extern unsigned int %s[];\n\n"
           "#define %s %u\n"
	   "#define %s %u\n"
	   "#define %s %u\n",
           hFileName, ppmFileName, cFileName, ctime(&clock), arrayName, 
                   widthName, width, heightName, height, depthName, depth);
}


///
/// finds last occurrence of a substring in a string
///
/// \param     s1     string to search in
/// \param     s2     string to find
///
/// \returns   pointer to last position where c was found in s, NULL if not found
///
char *findLast(const char *s1, const char *s2) {
    char *last = NULL;
    char *ptr = (char*)s1;
    
    if (s1 == NULL || s2 == NULL) return NULL;
    
    while ((ptr = strstr(ptr, s2)) != NULL) {
        last = ptr;
        ptr++;
    }
    
    return last;
}

 
///
/// Prints usage information
///
void usage() {
    printf("\nConvert a PPM/PNM file to a C array\n"
           "\nUSAGE: ppm2c [-o newfile.c] [-i identifier] image.ppm\n\n"
           "\t-o newfile.c      write array into 'newfile.c'\n"
           "\t                  (defaults to image filename + \".c\")\n"
           "\t-i identifier     use 'identifier' as name of array variable\n"
           "\t                  (defaults to \"image\")\n"
           "\t image.bit        file name of image to convert\n\n");
   }


///
/// parse PPM/PNM header
///
/// \param f     file to parse (must be open)
/// 
/// \returns -1 on error, offset to image data otherwise
///

int parsePPM( FILE *f ) {
#define LINELEN 80
    char linebuf[LINELEN] = "";
    
    if ( f == NULL ) {
	return -1;
    }

    // parse PPM header here!
    // 1. read PPM P6 header
    fgets(linebuf, LINELEN, f);
    if (linebuf[0] != 'P' || linebuf[1] != '6') {
	return -1;
    }

    // 2. read dimensions
    do {  		// skip comments
	fgets(linebuf, LINELEN, f);
    } while (linebuf[0] == '#');
    sscanf(linebuf, "%d %d", &width, &height);
    
    // 3. read pixel depth
    do {  		// skip comments
	fgets(linebuf, LINELEN, f);
    } while (linebuf[0] == '#');
    sscanf(linebuf, "%d", &depth);

    return ftell(f);
}


///
/// Main program
///
int main(int argc, char *argv[]) {
    int c, i, o;
    unsigned int n;
    FILE *src, *dst;
    
    while(1) {
        c = getopt(argc, argv, "o:i:");
        
        if (c == -1) {
            break;
        }
        
        switch(c) {
            
            case 'o':
                strncpy(cFileName, optarg, STRLEN);
                break;

            case 'i':
                strncpy(arrayName, optarg, STRLEN);
                break;
            
            case '?':
                usage();
                return -1;
        }
    }
    
    if (optind == argc-1) {
        strncpy(ppmFileName, argv[optind], STRLEN);
    } else {
        usage();
        return -1;
    }

    if (strlen(cFileName) == 0) {
        strncpy(cFileName, ppmFileName, STRLEN-2);
        strcat(cFileName, ".c");
    }
    
    // if cFileName ends in ".c", replace that by ".h", otherwise just append ".h"
    if (strcmp(cFileName + strlen(cFileName)-2, ".c") == 0) {
        strcpy(hFileName, cFileName);
        hFileName[strlen(cFileName)-2] = 0;
    } else {
        strncpy(hFileName, cFileName, STRLEN-2);
    }
    strcat(hFileName, ".h");
    
    // if none given, generate array name
    if (strlen(arrayName) == 0) {
        // use everything after last '/'
        if (findLast(ppmFileName, "/") != NULL) {
            strncpy(arrayName, findLast(ppmFileName, "/")+1, STRLEN);
        } else {
            strncpy(arrayName, ppmFileName, STRLEN);
        }
    }
    // replace '.' with '_'
    for (i = 0; i < strlen(arrayName); i++) {
        if (arrayName[i] == '.') {
            arrayName[i] = '_';
        }
    }
        
    // generate width name
    strncpy(widthName, arrayName, STRLEN-5);
    for (i = 0; i < strlen(widthName); i++) {
        widthName[i] = toupper(widthName[i]);
    }
    strcat(widthName, "_WIDTH");

    // generate height name
    strncpy(heightName, arrayName, STRLEN-5);
    for (i = 0; i < strlen(heightName); i++) {
        heightName[i] = toupper(heightName[i]);
    }
    strcat(heightName, "_HEIGHT");

    // generate depth name
    strncpy(depthName, arrayName, STRLEN-5);
    for (i = 0; i < strlen(depthName); i++) {
        depthName[i] = toupper(depthName[i]);
    }
    strcat(depthName, "_MAXVAL");
    
    // read input file
    src = fopen(ppmFileName, "rb");
    if (src == NULL) {
        perror("error opening file");
        return -1;
    }

    // parse header
    o = parsePPM(src);
    if (o < 0) {
        fprintf(stderr, "no PPM header found, or PPM format not supported (!= P6)\n");
        fclose(src);
        return -1;
    }

    // check parameters
    if (depth > 255) {
	fprintf(stderr, "pixel depth > 255 not supported.\n");
	fclose(src);
	return -1;
    }

    // write output files
    dst = fopen(cFileName, "w");
    if (dst == NULL) {
        perror("error opening file for writing");
        fclose(src);
        return -1;
    }
    
    n = writeCFile(src, dst, o);
    fclose(src);
    fclose(dst);
    if (n == 0) {
        fprintf(stderr, "error while writing C source\n");
        return -1;
    }
    
    // write header
    dst = fopen(hFileName, "w");
    if (dst == NULL) {
        perror("error opening file for writing");
        return -1;
    }
    writeHFile(dst);
    fclose(dst);
    
    return 0;
}
