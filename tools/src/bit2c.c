///
/// \file bit2c.c
///
/// Converts bitstreams into C sources
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       30.07.2007
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

static char bitFileName[STRLEN] = "";
static char cFileName[STRLEN]   = "";
static char hFileName[STRLEN]   = "";
static char arrayName[STRLEN]  = "";
static char sizeName[STRLEN]  = "";
static int  force = 0;

static uint32_t crc32_value = 0;

// FUNCTION DEFINITIONS ====================================================


///
/// finds the first occurrence of the synchronization word in file f
///
/// \param      f     file stream to search
///
/// \returns    the byte-position of the sync word in the stream, -1 on error
///
int findSyncWord(FILE *f) {
    int c;
    int i = 0;
    int buf = 0x000000000;

    c = fseek(f, (long)0, SEEK_SET);
    if (c != 0) {
        perror("findSyncWord");
        return -1;
    }
    
    while (1) {
        c = fgetc(f);
        if (c == EOF) {
            return -1;
        } else {
            buf = (buf << 8) | c;
            if (buf == SYNC_WORD) {
                return i-3;
            }
        }
        i++;
    }
}



///
/// Writes the bitstream as bytes (0xXX) to the destination file
///
/// \param      src       source (bitstrem) file stream
/// \param      dst       destination (C) file stream
/// \param      offset    offset into source file to start writing from (in bytes)
///
/// \returns number of written bytes, or 0 on error
///
unsigned int writeCFile(FILE *src, FILE *dst, int offset) {
    time_t clock = time( NULL );
    int c;
    unsigned int i = 0;
    
    c = fseek(src, (long)offset, SEEK_SET);
    if (c != 0) {
        perror("error while seeking to sync word");
        return 0;
    }

    fprintf(dst, "/************************************************************\n"
           " * %s : c-coded bitstream\n"
           " *\n"
           " * source bitstream : %s\n"
           " * associated header: %s\n"
           " * generated on     : %s"
           " ************************************************************/\n"
           "\n"
           "unsigned char %s[] __attribute__ ((aligned (4))) = {\n\t\t",
           cFileName, bitFileName, hFileName, ctime(&clock), arrayName);
    
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
            crc32_value = crc32_add_byte(crc32_value,c);
            if (i > 0) {
                if (i % 8 == 0) {
                    fprintf(dst, ",\n\t\t");
                } else {
                    fprintf(dst, ", ");
                }
            }
            fprintf(dst, "0x%02X", c);
            i++;
        }
    }

}



///
/// Writes the destination header file
///
/// \param      size      bitstream size in bytes
/// \param      dst       destination (C header) file stream
///
void writeHFile(unsigned int size, FILE *dst) {
    time_t clock = time( NULL );

    fprintf(dst, "/************************************************************\n"
           " * %s : c-coded bitstream header\n"
           " *\n"
           " * source bitstream   : %s\n"
           " * associated C source: %s\n"
           " * generated on       : %s"
           " ************************************************************/\n"
           "\n"
           "extern unsigned char %s[];\n\n"
	   "#define %s_crc32 0x%X\n"
           "#define %s %u\n",
           hFileName, bitFileName, cFileName, ctime(&clock), arrayName, arrayName,
                   crc32_value, sizeName, size);
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
    printf("\nConvert a Xilinx FPGA configuration bitstream into a C array.\n"
           "\nUSAGE: bit2c [-o newfile.c] [-i identifier] bitstream.bit\n\n"
           "\t-o newfile.c      write bitstream array into 'newfile.c'\n"
           "\t                  (defaults to bitstream filename + \".c\")\n"
           "\t-i identifier     use 'identifier' as name of bitstream variable\n"
           "\t                  (defaults to \"bitstream\")\n"
           "\t-f                force file creation even if no sync word is found\n"
           "\t bitstream.bit    file name of bitstream to convert\n\n");
   }


///
/// Main program
///
int main(int argc, char *argv[]) {
    int c, i, o;
    unsigned int n;
    FILE *src, *dst;
    
    while(1) {
        c = getopt(argc, argv, "o:i:f");
        
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

            case 'f':
                force = 1;
                break;
            
            case '?':
                usage();
                return -1;
        }
    }
    
    if (optind == argc-1) {
        strncpy(bitFileName, argv[optind], STRLEN);
    } else {
        usage();
        return -1;
    }

    if (strlen(cFileName) == 0) {
        strncpy(cFileName, bitFileName, STRLEN-2);
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
        if (findLast(bitFileName, "/") != NULL) {
            strncpy(arrayName, findLast(bitFileName, "/")+1, STRLEN);
        } else {
            strncpy(arrayName, bitFileName, STRLEN);
        }
    }
    // replace '.' with '_'
    for (i = 0; i < strlen(arrayName); i++) {
        if (arrayName[i] == '.') {
            arrayName[i] = '_';
        }
    }
        
    // generate size name
    strncpy(sizeName, arrayName, STRLEN-5);
    for (i = 0; i < strlen(sizeName); i++) {
        sizeName[i] = toupper(sizeName[i]);
    }
    strcat(sizeName, "_SIZE");

    // write C source
    src = fopen(bitFileName, "rb");
    if (src == NULL) {
        perror("error opening file");
        return -1;
    }

    o = findSyncWord(src);
    if (o < 0) {
        if (!force) {
            fprintf(stderr, "no sync word in bitstream\n");
            fclose(src);
            return -1;
        } else {
            o = 4;
        }
    } 

    dst = fopen(cFileName, "w");
    if (dst == NULL) {
        perror("error opening file for writing");
        fclose(src);
        return -1;
    }
    
    n = writeCFile(src, dst, o-4);
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
    writeHFile(n, dst);
    fclose(dst);
    
    return 0;
}
