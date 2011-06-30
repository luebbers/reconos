// \file 	controller.c
// \author	Ariane Keller   <ariane.keller@tik.ee.ethz.ch>
// \date       	23.03.2011
//
// This file is part of the ReconOS project <http://www.reconos.de> and <https://github.com/luebbers/reconos/>
// It is published under the GPL.
//
// This file sends commands to the hardware threads in order to configure which thread sends to which.
// The communication goes over the multibus system. The threads in slot 0 and 1 are identical. The thread in
// slot 2 additionaly has access to the Ethernet interface.
//

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <cyg/infra/diag.h>

#include <cyg/infra/cyg_type.h>
#include <cyg/kernel/kapi.h>
#include <cyg/hal/hal_cache.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include "config.h"

#define printf diag_printf

//Commands: the SEND_* commands can be combined (binary |), 
//but the GET_* commands need to be executed one after the other.
#define SEND_TO_SLOT_0	2147483648
#define SEND_TO_SLOT_1	1073741824
#define SEND_TO_SLOT_2	536870912
#define SEND_TO_ETH	268435456
#define GET_STATS_BUS	33554432
#define GET_STATS_ETH	16777216

//mboxes
cyg_mbox first_sw_hw, first_hw_sw;
cyg_handle_t first_sw_hw_handle, first_hw_sw_handle;

cyg_mbox second_sw_hw, second_hw_sw;
cyg_handle_t second_sw_hw_handle, second_hw_sw_handle;

cyg_mbox third_sw_hw, third_hw_sw;
cyg_handle_t third_sw_hw_handle, third_hw_sw_handle;

// first hardware thread
cyg_thread hwthread_first;
rthread_attr_t hwthread_first_attr;
cyg_handle_t hwthread_first_handle;
char hwthread_first_stack[STACK_SIZE];
reconos_res_t hwthread_first_resources[2] =
	{ {&first_sw_hw_handle, CYG_MBOX_HANDLE_T},
	{&first_hw_sw_handle, CYG_MBOX_HANDLE_T}
	};

// second hardware thread
cyg_thread hwthread_second;
rthread_attr_t hwthread_second_attr;
cyg_handle_t hwthread_second_handle;
char hwthread_second_stack[STACK_SIZE];
reconos_res_t hwthread_second_resources[2] =
	{ {&second_sw_hw_handle, CYG_MBOX_HANDLE_T},
	{&second_hw_sw_handle, CYG_MBOX_HANDLE_T}
	};

// third hardware thread
cyg_thread hwthread_third;
rthread_attr_t hwthread_third_attr;
cyg_handle_t hwthread_third_handle;
char hwthread_third_stack[STACK_SIZE];
reconos_res_t hwthread_third_resources[2] =
	{ {&third_sw_hw_handle, CYG_MBOX_HANDLE_T},
	{&third_hw_sw_handle, CYG_MBOX_HANDLE_T}
	};

void delay_countdown(unsigned int secs) {
	int i;
	for (i = 0; i < secs; i++) {
		diag_printf("\r%3d...", secs-i);
		cyg_thread_delay(100);  // sleep for 1 second	
	}
    	diag_printf("\n");
}

int main( int argc, char *argv[] )
{

	int ret = 0;

	srand( time( 0 ) );

	printf( "-------------------------------------------------------\n"
            "ReconOS hardware multithreading case study (multibus with Ethernet)\n"
            "(c) Computer Engineering Group, University of Paderborn\n\n"
            "eCos, multi-threaded hardware version (" __FILE__ ")\n"
            "Compiled on " __DATE__ ", " __TIME__ ".\n"
            "-------------------------------------------------------\n\n" );

    	// create mail boxes for 'start' and 'complete' messages
    	cyg_mbox_create( &first_sw_hw_handle, &first_sw_hw );
    	cyg_mbox_create( &first_hw_sw_handle, &first_hw_sw );

 	// create mail boxes for second thead
    	cyg_mbox_create( &second_sw_hw_handle, &second_sw_hw );
    	cyg_mbox_create( &second_hw_sw_handle, &second_hw_sw );

 	// create mail boxes for third thead
    	cyg_mbox_create( &third_sw_hw_handle, &third_sw_hw );
    	cyg_mbox_create( &third_hw_sw_handle, &third_hw_sw );

    	// create first hardware thread
    	rthread_attr_init(&hwthread_first_attr);
    	rthread_attr_setslotnum(&hwthread_first_attr, 0);
    	rthread_attr_setresources(&hwthread_first_attr, hwthread_first_resources, 2);
    	reconos_hwthread_create( 15,                   	// priority
                             &hwthread_first_attr,	// hardware thread attributes
                             0,                         // entry data (not needed)
                             "SLOT_0",                  // thread name
                             hwthread_first_stack,      // stack
                             STACK_SIZE,                // stack size
                             &hwthread_first_handle,    // thread handle
                             &hwthread_first            // thread object
         );

 	// create second hardware thread
   	rthread_attr_init(&hwthread_second_attr);
    	rthread_attr_setslotnum(&hwthread_second_attr, 1);
    	rthread_attr_setresources(&hwthread_second_attr, hwthread_second_resources, 2);
   	reconos_hwthread_create( 15,                 
                             &hwthread_second_attr,  
                             0,       
                             "SLOT_1", 
                             hwthread_second_stack, 
                             STACK_SIZE,     
                             &hwthread_second_handle, 
                             &hwthread_second
	);

 	// create third hardware thread
    	rthread_attr_init(&hwthread_third_attr);
    	rthread_attr_setslotnum(&hwthread_third_attr, 2);
    	rthread_attr_setresources(&hwthread_third_attr, hwthread_third_resources, 2);
    	reconos_hwthread_create( 15, 
                             &hwthread_third_attr, 
                             0, 
                             "SLOT_2",
                             hwthread_third_stack,
                             STACK_SIZE,
                             &hwthread_third_handle,
                             &hwthread_third 
         );

    	cyg_thread_resume( hwthread_first_handle );
    	cyg_thread_resume( hwthread_second_handle );
    	cyg_thread_resume( hwthread_third_handle );

	delay_countdown(1);
    	printf( "Started threads...\n" );

	//Set it up so that slot 0 sends to slot 1, 1 to 2, 2 to 0 and 2 to Ethernet
	cyg_mbox_put(first_sw_hw_handle, SEND_TO_SLOT_1); 
	cyg_mbox_put(second_sw_hw_handle, SEND_TO_SLOT_2);
	cyg_mbox_put(third_sw_hw_handle,  SEND_TO_SLOT_0 | SEND_TO_ETH);

	printf( "Started sending\n" );

	delay_countdown(1);

	cyg_mbox_put(first_sw_hw_handle, 1);
	cyg_mbox_put(second_sw_hw_handle, 1);
	cyg_mbox_put(third_sw_hw_handle, 1);
	printf( "Stopped sending\n" );


	cyg_mbox_put(first_sw_hw_handle, GET_STATS_BUS);
	ret = cyg_mbox_get(first_hw_sw_handle);
	printf("received %d packets on thread 0\n", ret);

	cyg_mbox_put(second_sw_hw_handle, GET_STATS_BUS);
	ret = cyg_mbox_get(second_hw_sw_handle);
	printf("received %d packets on thread 1\n", ret);

	cyg_mbox_put(third_sw_hw_handle, GET_STATS_BUS);
	ret = cyg_mbox_get(third_hw_sw_handle);
	printf("received %d packets on thread 2 on the multibus interface\n", ret);

	cyg_mbox_put(third_sw_hw_handle, GET_STATS_ETH);
	ret = cyg_mbox_get(third_hw_sw_handle);
	printf("received %d packets on thread 2 on the Ethernet interface\n", ret);

    return 0;

}
