#ifndef UTIL_H
#define UTIL_H

#include <mqueue.h>

mqd_t my_mq_open(char * name);
int my_mq_receive(mqd_t mq, void * buffer);
void my_mq_send(mqd_t mq, void * buffer, int len);

#endif

