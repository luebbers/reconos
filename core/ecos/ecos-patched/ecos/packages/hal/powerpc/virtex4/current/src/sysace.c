//==========================================================================
//
//      sysace.c
//
//      Support for RedBoot disk commands (via SysACE)
//
//==========================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002, 2003 Red Hat, Inc.
// Copyright (C) 2002, 2003, 2004, 2005 Mind n.v.
// Copyright (C) 2007 ReconOS
//
// eCos is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 or (at your option) any later version.
//
// eCos is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with eCos; if not, write to the Free Software Foundation, Inc.,
// 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
//
// As a special exception, if other files instantiate templates or use macros
// or inline functions from this file, or you compile this file and link it
// with other works to produce a work based on this file, this file does not
// by itself cause the resulting work to be covered by the GNU General Public
// License. However the source code for this file must still be made available
// in accordance with section (3) of the GNU General Public License.
//
// This exception does not invalidate any other reasons why a work based on
// this file might be covered by the GNU General Public License.
//
// Alternative licenses for eCos may be arranged by contacting Red Hat, Inc.
// at http://sources.redhat.com/ecos/ecos-license/
// -------------------------------------------
//####ECOSGPLCOPYRIGHTEND####
//==========================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):    gthomas
// Contributors: 
// Date:         2003-08-28
// Purpose:      
// Description:  
//              
// This code is part of RedBoot (tm).
//
//####DESCRIPTIONEND####
//
//==========================================================================

#include <redboot.h>
#include <cyg/hal/hal_io.h>
#include <fs/disk.h>
#include <xsysace.h>
#include <xparameters.h>
#include <xparameters_translation.h>

static XSysAce ace;

static int sysace_read(struct disk *d,
                       cyg_uint32 start_sector,
                       cyg_uint32 *buf,
                       cyg_uint8  nr_sectors);

static disk_funs_t sysace_funs = { sysace_read };

static int 
sysace_read(struct disk *d,
            cyg_uint32 start_sector,
            cyg_uint32 *buf,
            cyg_uint8  nr_sectors)
{
    if (XSysAce_Lock(&ace, 0) != XST_SUCCESS) {
        diag_printf("Can't lock SysACE\n");
        return 0;
    }
    if (XSysAce_SectorRead(&ace, start_sector, nr_sectors, (Xuint8 *)buf) != XST_SUCCESS) {
        diag_printf("SysACE read failed - sec: %d, count: %d\n", start_sector, nr_sectors);
        XSysAce_Unlock(&ace);
        return 0;
    }
    XSysAce_Unlock(&ace);
    return 1;
}

static void
sysace_init(void)
{
    XSysAce_CFParameters drive_info;
    disk_t disk;

    if (XSysAce_Initialize(&ace, UPBHWR_SYSACE_0_DEVICE_ID) != XST_SUCCESS) {
        diag_printf("Can't initialize SysACE?\n");
        return;
    }
    if (XSysAce_Lock(&ace, 0) != XST_SUCCESS) {
        diag_printf("Can't lock SysACE\n");
        return;
    }
    if (XSysAce_IdentifyCF(&ace, &drive_info) != XST_SUCCESS) {
        diag_printf("Can't get SysACE info\n");
        XSysAce_Unlock(&ace);
        return;
    }
    XSysAce_Unlock(&ace);
#if 0
    diag_printf("SysACE - sectors: %d (%d/%d/%d) - %d bytes/sector\n", 
                drive_info.NumSectorsPerCard, 
                drive_info.NumCylinders,
                drive_info.NumHeads,
                drive_info.NumSectorsPerTrack,
                drive_info.NumBytesPerSector);
    diag_dump_buf(drive_info.ModelNo, 64);
#endif
    memset(&disk, 0, sizeof(disk));
    disk.funs = &sysace_funs;
//	    disk.private = priv;
    disk.kind = DISK_IDE_HD;
    disk.nr_sectors = (drive_info.NumCylinders * drive_info.NumHeads * drive_info.NumSectorsPerTrack);

    if (!disk_register(&disk)) {
        return;
    }
}

RedBoot_init(sysace_init, RedBoot_INIT_FIRST);

//=========================================================================
// EOF sysace.c
