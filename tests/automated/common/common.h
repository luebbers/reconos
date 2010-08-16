#ifndef COMMON_H
#define COMMON_H

#include <reconos/reconos.h>
#include <reconos/resources.h>

#define STACK_SIZE (64*1024)
static unsigned int thread_stack[NUM_OSIFS][STACK_SIZE/4];
static rthread_attr_t rattr[NUM_OSIFS];

static cyg_thread ecos_thread[NUM_OSIFS];
static cyg_handle_t ecos_thread_handle[NUM_OSIFS];

static pthread_t posix_thread[NUM_OSIFS];
static pthread_attr_t posix_attr[NUM_OSIFS];

static inline cyg_handle_t ecos_hwt_create(int nslot, cyg_addrword_t init_data, reconos_res_t * res, int nres)
{
	rthread_attr_init(rattr + nslot);
	rthread_attr_setslotnum(rattr + nslot, nslot);
	rthread_attr_setresources(rattr + nslot, res, nres);

	reconos_hwthread_create(
		0,
		rattr + nslot,
		init_data,
		"delegate thread",
		thread_stack[nslot],
		STACK_SIZE,
		ecos_thread_handle + nslot,
		ecos_thread + nslot
	);
	
	return ecos_thread_handle[nslot];
}
#define ECOS_HWT_CREATE(nslot, init_data, resarray) ecos_hwt_create((nslot), (init_data), (resarray), sizeof (resarray) / sizeof (resarray)[0])

#define POSIX_HWT_CREATE(nslot, init_data, resarray) posix_hwt_create((nslot), (init_data), (resarray), sizeof (resarray) / sizeof (resarray)[0])

static inline pthread_t * posix_hwt_create(int nslot, cyg_addrword_t init_data, reconos_res_t * res, int nres)
{
	rthread_attr_init(rattr + nslot);
	rthread_attr_setslotnum(rattr + nslot, nslot);
	rthread_attr_setresources(rattr + nslot, res, nres);

	pthread_attr_init(posix_attr + nslot);
	
	rthread_create(posix_thread + nslot, posix_attr + nslot, rattr + nslot, (void*)init_data);
	return posix_thread + nslot;
}

#endif // COMMON_H
