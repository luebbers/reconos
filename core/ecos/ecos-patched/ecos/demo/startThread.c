/* 
 * Mind eCos demo
 * 
 * Copyright (c) 2005 Mind NV
 * 
 * Author : Jan Olbrechts (jano@mind.be)
 */

#include <stdio.h>
#include <string.h>
#include <cyg/io/io.h>
#include <cyg/hal/led_manager.h>
#include <stdlib.h>
#include <network.h>

#define STACK_SIZE (CYGNUM_HAL_STACK_SIZE_TYPICAL + 0x1000)

void startThread(char* name, void (*fn)(cyg_addrword_t), int priority)
{
  char *stack;
  cyg_thread* thread_data;
  cyg_handle_t* thread_handle;

  stack = (char*)malloc(STACK_SIZE);
  thread_data = (cyg_thread*)malloc(sizeof(cyg_thread));
  thread_handle = (cyg_handle_t*)malloc(sizeof(cyg_handle_t));

  cyg_thread_create(priority,
                    fn,
                    0, // parameter for fn
                    name,
                    stack,
                    STACK_SIZE,
                    thread_handle,
                    thread_data);
  cyg_thread_resume(*thread_handle);
}

