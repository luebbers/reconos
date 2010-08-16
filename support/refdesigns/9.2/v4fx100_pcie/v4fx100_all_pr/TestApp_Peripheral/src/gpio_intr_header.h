#define TESTAPP_GEN

/* $Id: gpio_intr_header.h,v 1.2 2006/06/26 22:23:20 somn Exp $ */


#include "xbasic_types.h"
#include "xstatus.h"


XStatus GpioIntrExample(XIntc* IntcInstancePtr,
                        XGpio* InstancePtr,
                        Xuint16 DeviceId,
                        Xuint16 IntrId,
                        Xuint16 IntrMask,
                        Xuint32 *DataRead);



