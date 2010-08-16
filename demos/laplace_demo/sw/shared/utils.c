/***************************************************************************
 * utils.c: Various utilitiy functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#include "utils.h"
#include <errno.h>

#ifdef USE_ECOS

#include <string.h>
#include <cyg/infra/diag.h>

void util_perror(const char * msg){
	diag_printf(msg);
	diag_printf(": ");
	diag_printf(strerror(errno));
	diag_printf("\n");
}

#else

#include <stdio.h>

void util_perror(const char * msg){
	perror(msg);
}

#endif

