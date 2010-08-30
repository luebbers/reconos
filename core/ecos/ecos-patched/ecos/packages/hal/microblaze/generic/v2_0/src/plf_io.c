//=============================================================================
//
//     plf_io.c
//
//      HAL diagnostic I/O code
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002, 2003 Gary Thomas
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
//=============================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):      Michal Pfeifer
// Original data:  PowerPC
// Date:        1999-06-08
// Purpose:     HAL diagnostic output
// Description: Implementations of HAL diagnostic I/O support.
//
//####DESCRIPTIONEND####
//
//=============================================================================

#include <pkgconf/hal.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/hal/plf_io.h>
#include <pkgconf/hal_microblaze_platform.h>

static struct gpio gpio_dev[] = {
#ifdef MON_GPIO_0
	{
		MON_GPIO_0_BASE,
		0,
		0,
	},
#endif
#ifdef MON_GPIO_1
	{
		MON_GPIO_1_BASE,
		0,
		0,
	},
#endif
#ifdef MON_GPIO_2
	{
		MON_GPIO_2_BASE,
		0,
		0,
	},
#endif
#ifdef MON_GPIO_3
	{
		MON_GPIO_3_BASE,
		0,
		0,
	},
#endif
};

/* simple gpio function for testing */
cyg_uint32 gpio_init(void)
{
	cyg_uint32 i;

	for(i = 0; i < (sizeof(gpio_dev) / sizeof(gpio_dev)[0]); i++) {
//		diag_printf("Init GPIO %d\n",i);
		*(cyg_uint32 *)(gpio_dev[i].baseaddr + 0x4) = 0x0; /* data direction */
		*(cyg_uint32 *)gpio_dev[i].baseaddr = 0xffffffff;

	}
	return 1;
}

cyg_uint32 gpio_read(cyg_uint32 channel)
{
//	diag_printf("read 0x%x\n", gpio_dev[channel].baseaddr, *(cyg_uint32 *)gpio_dev[channel].baseaddr);
	return *(cyg_uint32 *)gpio_dev[channel].baseaddr;
}

void gpio_write(cyg_uint32 channel, cyg_uint32 value)
{
//	diag_printf("write 0x%x = 0x%x\n",gpio_dev[channel].baseaddr, value);
	*(cyg_uint32 *)gpio_dev[channel].baseaddr = value;
}


// EOF plf_io.c
