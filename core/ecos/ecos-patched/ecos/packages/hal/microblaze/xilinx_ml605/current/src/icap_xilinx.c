///
/// \file icap.c
///
/// Low-level routines for partial reconfiguration via ICAP
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       28.01.2009
//
//---------------------------------------------------------------------------
// %%%RECONOS_COPYRIGHT_BEGIN%%%
// 
// This file is part of ReconOS (http://www.reconos.de).
// Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
// All rights reserved.
// 
// ReconOS is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
// 
// ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
// 
// You should have received a copy of the GNU General Public License along
// with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
// 
// %%%RECONOS_COPYRIGHT_END%%%
//---------------------------------------------------------------------------
//

#include <cyg/hal/icap.h>
#include <xhwicap.h>
#include <cyg/infra/diag.h>
#include <cyg/infra/cyg_ass.h>
#include <cyg/infra/cyg_trac.h>
#include <cyg/kernel/kapi.h>

#define HWICAP_DEVICEID             XPAR_XPS_HWICAP_0_DEVICE_ID

static XHwIcap HwIcap;
static XHwIcap_Config *icap_config;
static cyg_mutex_t icap_mutex;



///
/// Initialize the ICAP
///
void icap_init(void){
        CYG_REPORT_FUNCTION();

        XStatus Status;

        icap_config = XHwIcap_LookupConfig(HWICAP_DEVICEID);
        Status = XHwIcap_CfgInitialize(&HwIcap, &icap_config, icap_config->BaseAddress);

        if (Status != XST_SUCCESS)
        {
            switch (Status) {
                case XST_INVALID_PARAM:
                    diag_printf("HWICAP: invalid parameter\n");
                    break;
                case XST_FAILURE:
                    diag_printf("HWICAP: failure\n");
                    break;
                case XST_DEVICE_IS_STARTED:
                    diag_printf("HWICAP: device already started\n");
                    break;
                case XST_DEVICE_NOT_FOUND:
                    diag_printf("HWICAP: device not found\n");
                    break;
                default:
                    diag_printf("HWICAP: failed with return value %d\n", Status);
            }
            CYG_FAIL("failed to initialize icap\naborting\n");
        }
        cyg_mutex_init(&icap_mutex);

        CYG_REPORT_RETURN();
}

///
/// Load a bitstream via ICAP
///
/// @param bitstream pointer to the bitstream array
/// @param length    length of bitstream in bytes
///
void icap_load(unsigned char * bitstream, size_t length){

        XStatus status;

        if (!cyg_mutex_lock(&icap_mutex)) {
            CYG_FAIL("mutex lock failed, aborting thread\n");
        } else {
            status = XHwIcap_DeviceWrite(&HwIcap, (Xuint32*)bitstream, length);
            if (status != XST_SUCCESS)
            {
                if(status == XST_DEVICE_BUSY) diag_printf("HWICAP: device busy\n");
                if(status == XST_INVALID_PARAM) diag_printf("HWICAP: invalid parameter\n");
                CYG_FAIL("failed to load bitstream\naborting\n");
            }
            cyg_mutex_unlock(&icap_mutex);
        }
}

