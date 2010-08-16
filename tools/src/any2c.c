///
/// \file any2c.c
///
/// \author     Andreas Agne <agne@upb.de>
/// \date       25.1.2009
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
#include <stdlib.h>
#include <string.h>

void exit_usage(const char * progname){
	fprintf(stderr,"usage: %s [identifier]\n", progname);
	fprintf(stderr,"\tread input from stdin and convert it to a c-array\n");
	fprintf(stderr,"\tidentifier: name of the array identifier\n");
	exit(1);
}

int main(int argc, char **argv) {
	char * id = "data";
	int c, i;
	
	if(argc == 2){
		if(!strcmp(argv[1], "-h")
		|| !strcmp(argv[1],"--help")){
			exit_usage(argv[0]);
		}
		id = argv[1];
	}
	
	if(argc > 2) exit_usage(argv[0]);
	
	i = 0;
	printf("const unsigned char %s[] = {\n\t  ", id);
	while((c = fgetc(stdin)) != EOF){
		unsigned char a = c;
		if(i > 0) printf(", ");
		printf("0x%02X", a);
		if(i % 8 == 7) printf("\n\t");
		i++;
	}
	
	printf("\n};\n\nconst unsigned int %s_len = %d;\n\n", id, i);
	
	return 0;
}

