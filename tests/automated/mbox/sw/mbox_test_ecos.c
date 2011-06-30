///
/// \file dcr_test.c
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       13.11.2007
//
// This file is part of the ReconOS project <http://www.reconos.de>.
// University of Paderborn, Computer Engineering Group.
//
// (C) Copyright University of Paderborn 2007.
//

#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "common.h"
//#include <xio_dcr.h>

cyg_mbox mbox0, mbox1;
cyg_handle_t mbox0_handle, mbox1_handle;

reconos_res_t thread_resources[2] =
        {
                {&mbox0_handle, CYG_MBOX_HANDLE_T},
                {&mbox1_handle, CYG_MBOX_HANDLE_T}
        };

int main( int argc, char *argv[] )
{
	int retval, i = 1, j, k;

	printf("begin mbox_test_ecos\n");

	cyg_mbox_create( &mbox1_handle, &mbox1 );
	cyg_mbox_create( &mbox0_handle, &mbox0 );

	printf("creating hw thread... ");
	cyg_thread_resume(ECOS_HWT_CREATE(0,0,thread_resources));
	printf("ok\n");
	
	// loop 10 times
	for (k = 0; k < 10; k++) {
		// send a message to mbox0
		retval = cyg_mbox_put( mbox0_handle, (void*)i);
		printf("sent: %d (retval %d)\n", i, retval);

		// receive a message from mbox1
		j = (int)cyg_mbox_get ( mbox1_handle );
		printf("recvd: %d\n", j);
		i++;
	}

	printf("mbox_test_ecos done.\n");
	
	return 0;
}

