/* 
 * Mind eCos demo
 * 
 * Copyright (c) 2005 Mind NV
 * 
 * Author : Jan Olbrechts (jano@mind.be)
 */
#ifndef __STARTTHREAD_H
#define __STARTTHREAD_H

void startThread(const char* name, void (*fn)(void*), int priority);

#endif

