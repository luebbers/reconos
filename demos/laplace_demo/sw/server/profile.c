/// 
/// \file profile.c
/// Very simple code profiling functions
/// 
/// Uses the OPB_TBWDT timebase
/// 
/// \author	Enno Luebbers <enno.luebbers@upb.de>
/// \created	2007
// -------------------------------------------------------------------------
// Major Changes:
// 
// ??.??.2007	Enno Luebbers	File created
//

// INCLUDES ================================================================

#include "profile.h"
#include "xwdttb.h"
#include "xparameters.h"
#include "utils.h"
#include <cyg/kernel/kapi.h>

#ifndef MAX
/// Returns maximum of a and b
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#endif

#ifndef MIN
/// Returns minimum of a and b
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif


//static volatile unsigned int profile_rolloverCount;
XWdtTb profile_tbwdt;		///< Watchdog device instance

/*
cyg_uint32 profile_rolloverISR(cyg_vector_t vector, cyg_addrword_t data)
{
  cyg_interrupt_mask (vector);
  cyg_interrupt_acknowledge (vector);
  profile_rolloverCount++;
  return (CYG_ISR_HANDLED);		// no DSR necessary
}
*/


int profile_tbwdtInit() {
	XStatus status;

//	profile_rolloverCount = 0;
	
	status = XWdtTb_Initialize(&profile_tbwdt, XPAR_OPB_TIMEBASE_WDT_0_DEVICE_ID);
	if (status != XST_SUCCESS) {
		util_perror("XWdtTb_Initialize");
		return status;
	}
	
	status = XWdtTb_SelfTest(&profile_tbwdt);
	if (status != XST_SUCCESS) {
		util_perror("XWdtTb_SelfTest");
		return status;
	}
	
	return 0;
}


void profile_init(struct profile_t *timer) {
	timer->loops = 0;
	timer->start = 0;
	timer->stop = 0;
	timer->max = 0;
	timer->min = 0xFFFFFFFF;
	timer->average = 0;
	timer->overhead = 0;
}


void inline profile_start(struct profile_t *timer) {
	unsigned int a, b;
	// FIXME: disable interrupts?
	if (timer->overhead == 0) {
		a = XWdtTb_GetTbValue(&profile_tbwdt);
		b = XWdtTb_GetTbValue(&profile_tbwdt);
		timer->overhead = b > a ? b-a : 0xFFFFFFFF-(a-b);
	}
	timer->start = XWdtTb_GetTbValue(&profile_tbwdt);
//	timer->rolloverStart = profile_rolloverCount;
	// FIXME: enable interrupts?
}


void inline profile_stop(struct profile_t *timer) {
	unsigned int diff;
//	unsigned int oldest;
	// FIXME: disable interrupts?
	timer->stop = XWdtTb_GetTbValue(&profile_tbwdt);
//	timer->rolloverStop = profile_rolloverCount;
	// FIXME: enable interrupts?

	
	if (timer->stop > timer->start) {
		diff = timer->stop - timer->start;
	} else {
		diff = (unsigned int)0xFFFFFFFF - (timer->start - timer->stop);
//		diag_printf("!!!");
	}
	diff -= timer->overhead;	// subtract measurement overhead

/*
	if (diff > timer->max) timer->max = diff;
	if (diff < timer->min) timer->min = diff;
	if (timer->loops < PROFILE_AVERAGE_LOOPS) {
		timer->average = (timer->average / (timer->loops+1)) * timer->loops + (diff / (timer->loops+1));
	} else {
		oldest = timer->diffs[timer->loops % PROFILE_AVERAGE_LOOPS];	// get oldest
		if (oldest > diff) {
			timer->average = timer->average - (( oldest - diff ) / PROFILE_AVERAGE_LOOPS);
		} else {
			timer->average = timer->average + (( diff - oldest ) / PROFILE_AVERAGE_LOOPS);
		}
	} */
	
	timer->diffs[timer->loops % PROFILE_AVERAGE_LOOPS] = diff;		// save difference

	timer->loops++;
}


void profile_eval(struct profile_t *timer) {
	unsigned int i, diff, n;
	double avg = 0.0;
	
	n = MIN(timer->loops, PROFILE_AVERAGE_LOOPS);
	
	for (i = 0; i < n; i++) {
		diff = timer->diffs[i];
		timer->max = MAX(timer->max, diff);
		timer->min = MIN(timer->min, diff);
		avg += diff;
	}
	avg /= n;
	timer->average = (int)avg;
}

void profile_print(struct profile_t *timer, const char* prefix) {
//	int i;

	diag_printf("%s:  n: %5u  min: %10u  max: %10u  avg: %10u     (oh: %u)\n",
		prefix, MIN(timer->loops, PROFILE_AVERAGE_LOOPS), timer->min, timer->max, timer->average, timer->overhead);
/*	diag_printf("\t->");
	for (i = 0; i < PROFILE_AVERAGE_LOOPS; i++) diag_printf("%u ", timer->diffs[i]);
	diag_printf("\n\n");*/
		
/*	diag_printf("diffs: ");
	for (int i = 0; i < PROFILE_AVERAGE_LOOPS; i++) {
		diag_printf("%u ", timer->diffs[i]);
	}
	diag_printf("\n^- loops: %u\n", timer->loops);*/
}
