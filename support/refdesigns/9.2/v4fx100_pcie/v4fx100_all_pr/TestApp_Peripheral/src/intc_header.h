#define TESTAPP_GEN

/* $Id: intc_header.h,v 1.2 2006/06/26 22:18:06 somn Exp $ */


#include "xbasic_types.h"
#include "xstatus.h"

XStatus IntcSelfTestExample(Xuint16 DeviceId);
XStatus IntcInterruptSetup(XIntc *IntcInstancePtr, Xuint16 DeviceId);


