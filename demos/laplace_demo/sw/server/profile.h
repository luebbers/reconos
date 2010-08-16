/// 
/// \file profile.h
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
#ifndef __PROFILE_H__
#define __PROFILE_H__

/// Maximum number of measurements to save and average
#define PROFILE_AVERAGE_LOOPS 10000

/// Stores measurement values
struct profile_t {
	unsigned int 		loops;	///< number of stored measurements
	
	unsigned int		rolloverStart;
	unsigned int		rolloverStop;
	unsigned int 		start;	///< measurement start time
	unsigned int 		stop;	///< measurement stop time
	
	unsigned int		overhead;	///< measurement overhead
	
	unsigned int		diffs[PROFILE_AVERAGE_LOOPS];	///< stored measurements

	unsigned int 		max;	///< maximum of measurements
	unsigned int 		min;	///< minimum of measurements
	unsigned int		average;	///< mean of measurements
};

///
/// Register interrupt for timebase
///
int profile_tbwdtInit();

///
/// Initialize profiling structure
///
/// \param	timer	profiling structure to initialize
///
void profile_init(struct profile_t *timer);

///
/// Start measurement
///
/// \param	timer	profiling structure to use for measurement
///
void inline profile_start(struct profile_t *timer);

///
/// Stop measurement
///
/// \param	timer	profiling structure to use for measurement
///
void inline profile_stop(struct profile_t *timer);

///
/// Extract measurement features (min, max, average) from measured data
///
/// \param	timer	profiling structure to evaluate
///
void profile_eval(struct profile_t *timer);

///
/// Print measurement feature summary
///
/// \param	timer	profiling structure to print
///
void profile_print(struct profile_t *timer, const char *prefix);


#endif // __PROFILE_H__
