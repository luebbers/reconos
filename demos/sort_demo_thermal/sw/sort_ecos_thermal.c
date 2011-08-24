///
/// \file sort_ecos_st_hw.c
/// Sorting application. eCos-based, single-threaded, hardware-accelerated
/// version.
///
/// \author     Enno Luebbers   <luebbers@reconos.de>
/// \date       28.09.2007
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
#include <time.h>
//#include <xcache_l.h>
#include <cyg/hal/hal_cache.h>
#include <reconos/reconos.h>
#include <reconos/resources.h>
#include <reconos/thermal.h>
#include "config.h"
#include "merge.h"
#include "data.h"
#include "timing.h"

#define printf diag_printf

unsigned int t;
unsigned int sysmon_value;
unsigned int vcc_raw;
unsigned int vcc;
int mc;
int sorting_data;

unsigned int buf_a[SIZE] __attribute__ ( ( aligned( 32 ) ) );   // align sort buffers to cache lines
unsigned int buf_b[SIZE];       // buffer for merging
unsigned int *data;

unsigned int crc;

cyg_mbox mb_start, mb_done;
cyg_handle_t mb_start_handle, mb_done_handle;

cyg_thread hwthread_sorter;
rthread_attr_t hwthread_sorter_attr;
cyg_handle_t hwthread_sorter_handle;
char hwthread_sorter_stack[STACK_SIZE];
reconos_res_t hwthread_sorter_resources[2] =
	{ {&mb_start_handle, CYG_MBOX_HANDLE_T},
	{&mb_done_handle, CYG_MBOX_HANDLE_T}
};

void sort_data ()
{
    unsigned int i;
    unsigned int start_count = 0, done_count = 0;
    timing_t t_start = 0, t_stop = 0, t_gen = 0, t_sort = 0, t_merge = 0, t_check = 0, t_tmp;
    //----------------------------------
    //-- GENERATE DATA
    //----------------------------------
#ifdef USE_CACHE
    // flush cache contents - the hardware can only read from main memory
    // TODO: storing could be more efficient
    printf( "Flushing cache..." );
    //XCache_EnableDCache( 0x80000000 );
    HAL_DCACHE_FLUSH( data, SIZE);
    printf( "done\n" );
#endif

    printf( "Generating data..." );
    t_start = gettime(  );
    generate_data( data, SIZE );
    t_stop = gettime(  );
    t_gen = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

#ifdef USE_CACHE
    // flush cache contents - the hardware can only read from main memory
    // TODO: storing could be more efficient
    printf( "Flushing cache..." );
    //XCache_EnableDCache( 0x80000000 );
    HAL_DCACHE_FLUSH( data, SIZE);
    printf( "done\n" );
#endif

    printf( "Sorting data..." );
    i = 0;
    while ( done_count < SIZE / N ) {
        t_start = gettime(  );
        // if we have something to distribute,
        // put as many as possile into the start mailbox
        while ( start_count < SIZE / N ) {
            if ( cyg_mbox_tryput( mb_start_handle, ( void * ) &data[i] ) ==  true ) {
                start_count++;
                i += N;
            } else {  // mailbox full
                //printf( "mailbox_full!\n" );
                break;
            }
        }
        t_stop = gettime(  );
        t_sort += calc_timediff_ms( t_start, t_stop );
        // see whether anybody's done
        t_start = gettime(  );
        if ( ( t_tmp = ( timing_t ) cyg_mbox_get( mb_done_handle ) ) != 0 ) {
            done_count++;
        } else {
            printf( "cyg_mbox_get returned NULL!\n" );
        }
        t_stop = gettime(  );
        t_sort += calc_timediff_ms( t_start, t_stop );
    }
    printf( "done\n" );

#ifdef USE_CACHE
    // invalidate cache contents
    printf( "Invalidating cache..." );
    HAL_DCACHE_FLUSH( data, SIZE);
    printf( "done\n" );
#endif


    //----------------------------------
    //-- MERGE DATA
    //----------------------------------
    printf( "Merging data..." );
    t_start = gettime(  );
    data = recursive_merge( data, buf_b, SIZE, N, simple_merge );
    t_stop = gettime(  );
    t_merge = calc_timediff_ms( t_start, t_stop );
    printf( "done\n" );

    //----------------------------------
    //-- CHECK DATA
    //----------------------------------
    printf( "Checking sorted data..." );
    t_start = gettime(  );
    if ( check_data( data, SIZE ) != 0 )
        printf( "CHECK FAILED!\n" );
    else
        printf( "check successful.\n" );
    t_stop = gettime(  );
    t_check = calc_timediff_ms( t_start, t_stop );

    printf( "\nRunning times (size: %d words):\n"
            "\tGenerate data: %d ms\n"
            "\tSort data    : %d ms\n"
            "\tMerge data   : %d ms\n"
            "\tCheck data   : %d ms\n"
            "\nTotal computation time (sort & merge): %d ms\n",
            (timing_t) SIZE, t_gen, t_sort, t_merge, t_check, t_sort + t_merge );
}

// CRC16 check sum for unsigned char or byte
void crc16(unsigned char ser_data)
{
    crc  = (unsigned char)(crc >> 8) | (crc << 8);
    crc ^= ser_data;
    crc ^= (unsigned char)(crc & 0xff) >> 4;
    crc ^= (crc << 8) << 4;
    crc ^= ((crc & 0xff) << 4) << 1;
}

// calculates CRC16 check sum for a measurement
void crc16_measurement(unsigned char * data, int size)
{
    int i;
    crc = 0;
    for (i=0; i<size;i++)
    {
         crc16(data[i]);
    }
}

//! prints temperature map
void print_temperature_map(void){

    int x,y;
    float temp;
    printf("\n");
    reconos_make_temperature_measurement();
    for (y=0; y<reconos_get_temperature_sensor_grid_height(); y++){
        for (x=0; x<reconos_get_temperature_sensor_grid_width(); x++){
            temp = reconos_get_temperature_at_loc(x,y);
            if (temp>0) printf("%02d.%02d  ", (int)temp, ((int)(temp*100))%100);
            else        printf("       ");
        }
        printf("\n");
    }
    printf("\n");
}


int main( int argc, char *argv[] )
{

    int i,j;
    float test_ret, diode;


#ifdef USE_CACHE
    HAL_DCACHE_ENABLE();
#else
    HAL_DCACHE_DISABLE();
#endif

    data = buf_a;

    // test thermal reconos function
    printf( "sensor calibration: wait for 3-4 minutes\n");
    reconos_calibrate_temperature_sensors();
    reconos_make_temperature_measurement();
    test_ret = reconos_get_temperature(1);
    test_ret *= 1000;
    printf( "sensor reading: %d.%03d C\n", (int)test_ret/1000, ((int)test_ret)%1000);
    test_ret = reconos_get_temperature_at_loc(0,0);
    test_ret *= 1000;
    printf( "sensor reading: %d.%03d C\n", (int)test_ret/1000, ((int)test_ret)%1000);

    print_temperature_map();
    //----------------------------------
    //-- SORT DATA
    //----------------------------------
    // create mail boxes for 'start' and 'complete' messages
    cyg_mbox_create( &mb_start_handle, &mb_start );
    cyg_mbox_create( &mb_done_handle, &mb_done );
    // create sorting hardware thread
    rthread_attr_init(&hwthread_sorter_attr);
    rthread_attr_setslotnum(&hwthread_sorter_attr, 0);
    rthread_attr_setresources(&hwthread_sorter_attr, hwthread_sorter_resources, 2);
    reconos_hwthread_create( 16,                                               // priority
                             &hwthread_sorter_attr,                             // hardware thread attributes
                             0,                                                // entry data (not needed)
                             "MT_HW_SORT",                                     // thread name
                             hwthread_sorter_stack,                            // stack
                             STACK_SIZE,                                       // stack size
                             &hwthread_sorter_handle,                          // thread handle
                             &hwthread_sorter                                  // thread object
         );
    cyg_thread_resume( hwthread_sorter_handle );
    
    j = 0;
    i = 2;
    printf( "\n");
    while (1)
    {
        print_temperature_map();
        diode = reconos_get_diode_temperature();
        diode *= 1000;
        printf( "###################### RUN %d ( %d.%03d C) #######################\n", j, (int)diode/1000 , ((int)diode)%1000);
        // sort data
        sort_data();
        j++;     

        if (j==10){reconos_activate_local_heater(i);}
        if (j==20){reconos_deactivate_local_heater(i); i=1;}

        if (j==20){reconos_activate_local_heater(i);}
        if (j==30){reconos_deactivate_local_heater(i); i=0;}

        if (j==30){reconos_activate_local_heater(i);}
        if (j==40){reconos_deactivate_local_heater(i); i=3;}

        if (j==40){reconos_activate_local_heater(i);}
        if (j==50){reconos_deactivate_local_heater(i); i=4;}

        if (j==50){reconos_activate_local_heater(i);}
        if (j==60){reconos_deactivate_local_heater(i); i=7;}

        if (j==60){reconos_activate_local_heater(i);}
        if (j==70){reconos_deactivate_local_heater(i); i=9;}

        if (j==70){reconos_activate_local_heater(i);}
        if (j==80){reconos_deactivate_local_heater(i); i=10;}

        if (j==80){reconos_activate_local_heater(i);}
        if (j==90){reconos_deactivate_local_heater(i); i=11;}

        if (j==90){reconos_activate_local_heater(i);}
        if (j==100){reconos_deactivate_local_heater(i); i=8;}

        if (j==100){reconos_activate_local_heater(i);}
        if (j==110){reconos_deactivate_local_heater(i); i=6;}

        if (j==110){reconos_activate_local_heater(i);}
        if (j==120){reconos_deactivate_local_heater(i); i=4;}

        if (j==120){reconos_activate_local_heater(i);}
        if (j==130){reconos_deactivate_local_heater(i); i=2;}
        
    }

    return 0;

}
