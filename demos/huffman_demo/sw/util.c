#include <mqueue.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>

mqd_t my_mq_open(char * name)
{
	mqd_t mq;
	mq = mq_open(name, O_RDWR);
	if(mq == (mqd_t)(-1)){
		fprintf(stderr,"mq '%s':\n", name);
		perror("could not open mq");
		exit(1);
	}
	
	return mq;
}

int my_mq_receive(mqd_t mq, void * buffer)
{
	int res;
	struct mq_attr attr;
	
	mq_getattr(mq, &attr);
	
	res = mq_receive(mq, (char*)buffer, attr.mq_msgsize, NULL);
	
	if(res == -1){
		perror("mq_receive");
		exit(1);
	}
	
	return res;
}

void my_mq_send(mqd_t mq, void * buffer, int len)
{
	int error;
	error = mq_send(mq, (char*)buffer,len,0);

	if(error){
		perror("mq_send");
		exit(1);
	}
}

