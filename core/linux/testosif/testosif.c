///
/// \file testosif.c
///
/// Small tool for command line testing of /dev/osif
///
/// \author     Enno Luebbers <enno.luebbers@uni-paderborn.de>
/// \date       23.1.2008
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

#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>


#define NUM_REGS 3


void usage(char *s) {
    printf("USAGE: %s r\n"
           "       %s w <reg0> <reg1> <reg2>\n", s, s);
}


int main(int argc, char *argv[]) {

    int fd_osif, i;
    unsigned int buf[NUM_REGS];
    ssize_t retval;
    char mode;

    // check arguments
    if (argc < 2) {
        usage(argv[0]);
        return -1;
    }
    
    mode = argv[1][0];
    
    if (mode == 'w' && argc < NUM_REGS+2) {
        usage(argv[0]);
        return -1;
    }

    // open first OSIF device
    fd_osif = open("/dev/osif0", O_RDWR);
    if (fd_osif < 0) {
        perror("error while opening /dev/osif0");
        return -1;
    } 

    // do the thing
    switch (mode) {
        case 'r':
            retval = read(fd_osif, buf, sizeof(buf));
            break;
        case 'w':
            for (i = 0; i < NUM_REGS; i++) {
                if (argv[i+2][1] == 'x')       // assume 0x1234ABCD format
                    sscanf(argv[i+2], "0x%08x", &buf[i]);
                else                           // assume 1234ABCD format
                    sscanf(argv[i+2], "%08x", &buf[i]);
            }
            retval = write(fd_osif, buf, sizeof(buf));
            break;
        default:
            usage(argv[0]);
            return -1;
    }
    
    // close OSIF device
    close(fd_osif);

    // print read/written values after closing the device.
    // this way we don't interfere with kernel messages
    // on the console.
    switch(mode) {
        case 'r':
            printf("Values read:\n");
            break;
        case 'w':
            printf("Values written:\n");
            break;
    }

    for (i = 0; i < NUM_REGS; i++)
        printf("\tRegister %d: 0x%08X\n", i, buf[i]);

    return 0;
}
