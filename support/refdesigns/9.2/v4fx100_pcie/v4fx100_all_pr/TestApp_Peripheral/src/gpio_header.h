#define TESTAPP_GEN

/* $Id: gpio_header.h,v 1.1 2006/02/16 23:28:46 moleres Exp $ */


#include "xbasic_types.h"
#include "xstatus.h"

XStatus GpioOutputExample(Xuint16 DeviceId, Xuint32 GpioWidth);
XStatus GpioInputExample(Xuint16 DeviceId, Xuint32 *DataRead);


