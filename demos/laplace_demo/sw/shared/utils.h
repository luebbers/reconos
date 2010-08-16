/***************************************************************************
 * utils.h: Various utilitiy functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#ifndef UTILS_H
#define UTILS_H

void util_perror(const char * msg);

#ifdef USE_ECOS
	#include <cyg/infra/diag.h>
	#define debug_printf diag_printf
#else
	#include <stdio.h>
	#define debug_printf printf
#endif

#endif // UTILS_H

