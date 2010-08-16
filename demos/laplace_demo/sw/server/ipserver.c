///
/// \file  ipserver.c
/// Example demonstrating multithreaded ReconOS programming.
/// 
/// This application, running on the XUP board, demonstrates a image
/// processing chain consisting of separate communicating threads running
/// in software and (possibly) hardware.
/// 
/// It serves as a demonstration for using ReconOS threads.
/// 
/// \author     Andreas Agne    <agne@upb.de>
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       2006
// -------------------------------------------------------------------------
// Major Changes:
// 
// ??.??.2006   Andreas Agne    File created
// 28.03.2007   Enno Luebbers   Source cleanup
// 18.04.2007   Enno Luebbers   Added display hardware thread, double 
//                              buffering
// 06.06.2008   Enno Luebbers   Updated for reconos_v2_00_a
// 

// INCLUDES ================================================================

#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_type.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <network.h>
#include <cyg/hal/lcd_support.h>
#include <reconos/reconos.h>
#include "global.h"
#include "utils.h"
#include "buffers.h"
#include "buffers_ecos.h"
#include "udp_connection.h"
#include "profile.h"
#include "xparameters.h"
#include "xcache_l.h"

// CONSTANTS ===============================================================

/// user thread stack size.
/// \warning Don't set too low, this will screw up scheduler data structures.
#define MYTHREAD_STACK_SIZE (8192)

/// size of HW thread shared memory (four addresses and one "loop" variable)
#define SHM_SIZE 20

// GLOBAL VARIABLES ========================================================

struct lcd_info fb_info;        ///< framebuffer info structure
struct byte_buffer input_buffer[2], laplace_buffer[2], output_buffer[1];  ///< image buffers

// semaphores
cyg_sem_t input_new,            ///< new datagram from input thread
 laplace_rdy,                   ///< laplace thread ready for new data
 laplace_new,                   ///< new processed datagram from laplace thread
 display_rdy;                   ///< display thread ready for new data

// thread info structures
struct buffer_thread_info
 input_thread_info, laplace_thread_info, display_thread_info;

// thread handles
cyg_handle_t input_handle, laplace_handle, display_handle;

// thread stacks
cyg_uint8
    input_stack[MYTHREAD_STACK_SIZE],
    laplace_stack[MYTHREAD_STACK_SIZE], display_stack[MYTHREAD_STACK_SIZE];

// software threads
cyg_thread input_thread, laplace_thread, display_thread;

// hardware threads
reconos_hwthread laplace_hwthread, display_hwthread;
rthread_attr laplace_hwthread_attr, display_hwthread_attr;



// FUNCTION DEFINITIONS ====================================================

///
/// Fills a cyg_sem_t[4] array with semaphores from a buffer_thread_info 
/// structure
///
/// \param      sem_array       the array to fill
/// \param      bti             the info structure containing the semaphores
///
/// \returns    the filled array
/// 
//cyg_sem_t **fill_sem_array(cyg_sem_t ** sem_array,
//                           struct buffer_thread_info *bti)
reconos_res_t *fill_sem_array(reconos_res_t * sem_array,
                           struct buffer_thread_info *bti)
{

    sem_array[0].ptr = &bti->src[0].rdy_sem;//rdy0;
    sem_array[0].type = RECONOS_SEM_T;
    sem_array[1].ptr = &bti->dst[0].rdy_sem;//rdy1;
    sem_array[1].type = RECONOS_SEM_T;
    sem_array[2].ptr = &bti->src[0].new_sem;//new0;
    sem_array[2].type = RECONOS_SEM_T;
    sem_array[3].ptr = &bti->dst[0].new_sem;//new1;
    sem_array[3].type = RECONOS_SEM_T;
    sem_array[4].ptr = &bti->src[1].rdy_sem;//rdy0;
    sem_array[4].type = RECONOS_SEM_T;
    sem_array[5].ptr = &bti->dst[1].rdy_sem;//rdy1;
    sem_array[5].type = RECONOS_SEM_T;
    sem_array[6].ptr = &bti->src[1].new_sem;//new0;
    sem_array[6].type = RECONOS_SEM_T;
    sem_array[7].ptr = &bti->dst[1].new_sem;//new1;
    sem_array[7].type = RECONOS_SEM_T;

    return sem_array;
}

///
/// Prints the current dynamic memory utilization
///
void diag_print_mallinfo()
{
    struct mallinfo mi;

    mi = mallinfo();
    diag_printf("\tarena    = %u\n"
                "\tordblks  = %u\n"
                "\tsmblks   = %u\n"
                "\thblks    = %u\n"
                "\thblkhd   = %u\n"
                "\tusmblks  = %u\n"
                "\tfsmblks  = %u\n"
                "\tuordblks = %u\n"
                "\tfordblks = %u\n"
                "\tkeepcost = %u\n"
                "\tmaxfree  = %u\n",
                mi.arena, mi.ordblks, mi.smblks, mi.hblks, mi.hblkhd,
                mi.usmblks, mi.fsmblks, mi.uordblks, mi.fordblks,
                mi.keepcost, mi.maxfree);

}

///
/// Allocates and initializes a shared memory segment for image processing 
/// hardware threads. It places the addresses of the source and destination
/// image buffers in the shared memory, as well as the datagrams per block.  
///
/// \param      bti     structure containing the thread support info
///
/// \returns    pointer to the allocated shared memory
///
cyg_uint32 *shm_init(struct buffer_thread_info *bti)
{

    cyg_uint32 *shared_mem = NULL;

    // allocate shared memory
    diag_printf("shm_init: allocating shared memory\n");
    shared_mem = (cyg_uint32 *) malloc(SHM_SIZE);                              // two addresses and one word (for "loops")
    if (shared_mem == NULL) {
        diag_printf("unable to allocate shared memory!\n");
        abort();
    }
    // initialize shared mem with buffer addresses
    shared_mem[0] = (unsigned int) bti->src[0].data;
    shared_mem[1] = (unsigned int) bti->dst[0].data;
    shared_mem[2] = (unsigned int) bti->src[1].data;
    shared_mem[3] = (unsigned int) bti->dst[1].data;
    shared_mem[4] = DGRAMS_PER_BLOCK;
    diag_printf
        ("shm_init: saving source and dst image pointers:"
        "\n\tsrc[0]: 0x%08X, src[1]: 0x%08X,"
        "\n\tdst[0]: 0x%08X, dst[1]: 0x%08X,\n\tloops: %u\n",
         shared_mem[0], shared_mem[2], shared_mem[1], shared_mem[3], shared_mem[4]);

    return shared_mem;

}




///
/// Initializes the framebuffer and the network interfaces
///
void init()
{
    //cyg_interrupt_unmask(CYGNUM_HAL_INTERRUPT_EMAC);

    // initialize profiling timebase
    if (profile_tbwdtInit() != 0) {
        diag_printf("TBWDT initialization failed.\n");
    }
#ifdef DO_STATETRACE
    reconos_clearStateTrace();
#endif

    lcd_init(24);
    lcd_clear();
    lcd_getinfo(&fb_info);
    diag_printf("framebuffer @ %dx%d\n", fb_info.width, fb_info.height);

    init_all_network_interfaces();
    diag_printf("eth0_up = %d\n", eth0_up);

}



// MAIN ////////////////////////////////////////////////////////////////////

///
/// Application entry function. Sets up data strctures and threads.
///
void cyg_user_start()
{
    struct udp_connection *con;
//    cyg_sem_t *sem_array[8];
    reconos_res_t sem_array_laplace[8];
    reconos_res_t sem_array_display[8];
    int i;

#if defined(USE_DCACHE)
    // enable caches for DRAM
    XCache_EnableDCache(0x80000000);
#endif

    diag_printf("Hello embedded world!\n"
                "This is " __FILE__ " (ReconOS), built " __DATE__ ", "
                __TIME__ "\n");

    // initialize hardware
    diag_printf("Initializing hardware...\n");
    init();

    // initialize image buffers
    diag_printf("Initializing image buffers...\n");
    for (i = 0; i < 2; i++) {
		byte_buffer_init(&input_buffer[i], WIDTH, HEIGHT);                            // one image + four lines (???)
		byte_buffer_fill(&input_buffer[i], 0);
		byte_buffer_init(&laplace_buffer[i], WIDTH, HEIGHT);                          // one image
		byte_buffer_fill(&laplace_buffer[i], 0);
    }

    // initialize fake output image buffer
    output_buffer[0].width = WIDTH;                                               // irrelevant
    output_buffer[0].height = HEIGHT;                                             // irrelevant
    output_buffer[0].data = fb_info.fb;                                           // this points to the VGA frame buffer
    // NOTE: the semaphores of this buffer are not used and therefore not initialized

    diag_printf
        ("Buffer addresses: input: 0x%08X, laplace: 0x%08X, output: 0x%08X\n",
         input_buffer[0].data, laplace_buffer[0].data, output_buffer[0].data);

    // set up UDP connection        
    diag_printf("Setting up UDP networking...\n");
    con = udp_connection_create(inet_addr("192.168.1.2"));

    // initialize thread info structures
    diag_printf("Initializing thread info structures...\n");
    buffer_thread_info_init(&input_thread_info, 2,  NULL, input_buffer);/*, NULL,
                            &laplace_rdy, NULL, &input_new);*/
    buffer_thread_info_init(&laplace_thread_info, 2, input_buffer,
                            laplace_buffer);/*, &laplace_rdy, &display_rdy,
                            &input_new, &laplace_new);*/
    buffer_thread_info_init(&display_thread_info, 2, laplace_buffer,
                            output_buffer);/*, &display_rdy, NULL,
                            &laplace_new, NULL);*/

    // initialize semaphores        
/*    diag_printf("Initializing semaphores...\n");
    cyg_semaphore_init(&input_new, 0);
    cyg_semaphore_init(&laplace_rdy, 1);
    cyg_semaphore_init(&laplace_new, 0);
    cyg_semaphore_init(&display_rdy, 1);*/

    // pass connection info to input thread 
    input_thread_info.data = (cyg_addrword_t) con;

    diag_printf("Creating threads...");

    // create input thread
    diag_printf("input...");
    cyg_thread_create(16,                                                      // scheduling info (eg pri)  
                      entry_buffer_recv,                                       // entry point function     
                      (cyg_addrword_t) & input_thread_info,                    // entry data                
                      "INPUT THREAD",                                          // optional thread name      
                      input_stack,                                             // stack base                
                      MYTHREAD_STACK_SIZE,                                     // stack size,       
                      &input_handle,                                           // returned thread handle    
                      &input_thread                                            // put thread here           
        );

#if !defined(USE_HW_LAPLACE)
    // create laplace software thread
    diag_printf("laplace_sw...");
    cyg_thread_create(16,                                                      // scheduling info (eg pri)  
                      entry_buffer_laplace,                                    // entry point function      
                      (cyg_addrword_t) & laplace_thread_info,                  // entry data
                      "LAPLACE THREAD (SW)",                                   // optional thread name     
                      laplace_stack,                                           // stack base               
                      MYTHREAD_STACK_SIZE,                                     // stack size,      
                      &laplace_handle,                                         // returned thread handle 
                      &laplace_thread                                          // put thread here       
        );
#else
    // create laplace hardware thread
    diag_printf("laplace_hw...");
    fill_sem_array(sem_array_laplace, &laplace_thread_info);
    rthread_attr_init(&laplace_hwthread_attr);
    rthread_attr_setslotnum(&laplace_hwthread_attr, 0);
    rthread_attr_setresources(&laplace_hwthread_attr, sem_array_laplace, 8);
    reconos_hwthread_create(16,                                                // scheduling info (eg pri)  
                            &laplace_hwthread_attr,                            // hw thread attributes
                            shm_init(&laplace_thread_info),                    // init data
                            "LAPLACE_THREAD (HW)",                             // optional thread name      
                            laplace_stack,                                     // stack base                
                            MYTHREAD_STACK_SIZE,                               // stack size,           
                            &laplace_handle,                                   // returned thread handle    
                            &laplace_hwthread);                                // put thread here       
#endif

#if !defined(USE_HW_DISPLAY)
    // create display software thread
    diag_printf("display_sw...");
    cyg_thread_create(16,                                                      // scheduling info (eg pri)  
                      entry_buffer_display,                                    // entry point function     
                      (cyg_addrword_t) & display_thread_info,                  // entry data
                      "DISPLAY THREAD",                                        // optional thread name      
                      display_stack,                                           // stack base               
                      MYTHREAD_STACK_SIZE,                                     // stack size,       
                      &display_handle,                                         // returned thread handle
                      &display_thread                                          // put thread here       
        );
#else
    // create display hardware thread
    diag_printf("display_hw...");
    fill_sem_array(sem_array_display, &display_thread_info);
    rthread_attr_init(&display_hwthread_attr);
    rthread_attr_setslotnum(&display_hwthread_attr, 0);
    rthread_attr_setresources(&display_hwthread_attr, sem_array_display, 8);
    reconos_hwthread_create(16,                                                // scheduling info (eg pri)  
                            &display_hwthread_attr,                            // hw thread attributes
                            shm_init(&display_thread_info),                    // init data
                            "DISPLAY_THREAD (HW)",                             // optional thread name      
                            display_stack,                                     // stack base                
                            MYTHREAD_STACK_SIZE,                               // stack size,           
                            &display_handle,                                   // returned thread handle    
                            &display_hwthread,                                 // put thread here       
                            (void *) XPAR_PLB_RECONOS_SLOT_1_BASEADDR, XPAR_OPB_INTC_0_PLB_RECONOS_SLOT_1_INTERRUPT_INTR + 1,   // associated interrupt vector
                            shm_init(&display_thread_info), SHM_SIZE,
                            sem_array, 8);
#endif

    diag_printf("\nStarting threads...\n");

    cyg_thread_resume(input_handle);
    cyg_thread_resume(laplace_handle);
    cyg_thread_resume(display_handle);

    diag_printf("end of main()\n");

}
