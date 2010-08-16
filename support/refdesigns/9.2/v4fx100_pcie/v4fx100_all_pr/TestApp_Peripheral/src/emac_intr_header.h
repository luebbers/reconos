#define TESTAPP_GEN

/* $Id: emac_intr_header.h,v 1.2 2006/06/26 22:37:44 somn Exp $ */


#include "xbasic_types.h"
#include "xstatus.h"

XStatus EmacIntrExample(XIntc *IntcInstancePtr,
                        XEmac *EmacInstancePtr,
                        Xuint16 EmacDeviceId,
                        Xuint16 EmacIntrId);


