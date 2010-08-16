#ifndef HISTOGRAM_THREAD_H
#define HISTOGRAM_THREAD_H

struct HistogramArgs
{
	char * mq_send;
	char * mq_recv;
};

void * histogram_entry(void * data);

#endif

