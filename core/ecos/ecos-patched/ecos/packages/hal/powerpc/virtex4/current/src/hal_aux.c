//=============================================================================
//
//      hal_aux.c
//
//      HAL auxiliary objects and code; per platform
//
//=============================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
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
//=============================================================================
//#####DESCRIPTIONBEGIN####
//
// Author(s):   hmt
// Contributors:hmt, gthomas
// Date:        1999-06-08
// Purpose:     HAL aux objects: startup tables.
// Description: Tables for per-platform initialization
//
//####DESCRIPTIONEND####
//
//=============================================================================

#include <pkgconf/hal.h>

#include <cyg/infra/cyg_type.h>
#include <cyg/hal/hal_mem.h>            // HAL memory definitions
#define CYGARC_HAL_COMMON_EXPORT_CPU_MACROS
#include <cyg/hal/ppc_regs.h>           // Platform registers
#include <cyg/hal/hal_if.h>             // hal_if_init
#include <cyg/hal/hal_intr.h>           // interrupt definitions
#include <cyg/infra/cyg_ass.h>          // assertion macros
#include <cyg/hal/hal_io.h>             // I/O macros
#include <cyg/infra/diag.h>
#include <cyg/hal/i2c_support.h>        // i2c support routines
#include CYGHWR_MEMORY_LAYOUT_H

#ifdef CYGPKG_REDBOOT
#include <redboot.h>
#endif

//-----------------------------------------------------------------------------
// Xilinx Interrupt Controller
// We don't use the HAL completely, only the low-level functions
#include "xintc_l.h"

#define XINTC_PPC_WRITE(x,y)    *((volatile unsigned int *)x)=y
#define XINTC_PPC_READ(x,y)     y=*((volatile unsigned int *)x)
#define XINTC_PPC_ALL       0xFFFFFFFF
#define XINTC_PPC_ISR       (UPBHWR_INTC_0_BASEADDR + XIN_ISR_OFFSET) // Status       
#define XINTC_PPC_IPR       (UPBHWR_INTC_0_BASEADDR + XIN_IPR_OFFSET) // Pending
#define XINTC_PPC_IER       (UPBHWR_INTC_0_BASEADDR + XIN_IER_OFFSET) // Enable
#define XINTC_PPC_IAR       (UPBHWR_INTC_0_BASEADDR + XIN_IAR_OFFSET) // Acknowledge
#define XINTC_PPC_SIE       (UPBHWR_INTC_0_BASEADDR + XIN_SIE_OFFSET) // Set
#define XINTC_PPC_CIE       (UPBHWR_INTC_0_BASEADDR + XIN_CIE_OFFSET) // Clear
#define XINTC_PPC_IVR       (UPBHWR_INTC_0_BASEADDR + XIN_IVR_OFFSET) // Interrupt Vector Register */       
#define XINTC_PPC_MER       (UPBHWR_INTC_0_BASEADDR + XIN_MER_OFFSET) // Master Enable
//-----------------------------------------------------------------------------

// The memory map is weakly defined, allowing the application to redefine
// it if necessary. The regions defined below are the minimum requirements.
CYGARC_MEMDESC_TABLE CYGBLD_ATTRIB_WEAK = {
    // Mapping for the Xilinx VIRTEX4 development boards
    CYGARC_MEMDESC_NOCACHE_PA( 0x80000000, 0x00000000, CYGMEM_REGION_ram_SIZE ), // Uncached version of RAM
    CYGARC_MEMDESC_CACHE(   CYGMEM_REGION_ram, CYGMEM_REGION_ram_SIZE ), // Main memory
    CYGARC_MEMDESC_TABLE_END
};

//--------------------------------------------------------------------------
// Platform init code.

void
_virtex4_assert(char *file, int line)
{
    cyg_uint32 old;

    HAL_DISABLE_INTERRUPTS(old);
    diag_printf("VIRTEX4 firmware failure - file: %s, line: %d\n",
                file, line);
    while (1) ;
}

void
hal_platform_init(void)
{
    XAssertSetCallback(_virtex4_assert);
}

//
// Initialize serial ports - called during hal_if_init()
// Note: actual serial port support code is supported by the PPC405 variant layer
//       Having this call here allows for additional platform specific additions
//
void
cyg_hal_plf_comms_init(void)
{
    static int initialized = 0;

    if (initialized)
        return;
    initialized = 1;

#if defined(CYGSEM_VIRTEX4_LCD_COMM) && defined(MNDHWR_VIRTEX4_TFT)
    cyg_hal_plf_lcd_init();
#else
    cyg_hal_plf_serial_init();
#endif
}

//----------------------------------------------------------------------------
// Reset.
void
_virtex4_reset(void)
{
    CYGARC_MTSPR(SPR_DBCR0, 0x30000000);  // Asserts system reset
    while (1) ;
}

//----------------------------------------------------------------------------
// Interrupt support
void
hal_platform_IRQ_init(void)
{
// We need first to have a decent decoding routine!
    XINTC_PPC_WRITE(XINTC_PPC_CIE,XINTC_PPC_ALL);
    XINTC_PPC_WRITE(XINTC_PPC_IAR,XINTC_PPC_ALL);
#ifndef CYGPKG_REDBOOT
    // This is a write-once bit, so if we are not planning to enable
    // interrupts at this time, we can safely delay this to a later time
#ifdef XIntc_mMasterEnable
    XIntc_mMasterEnable(UPBHWR_INTC_0_BASEADDR);
#else
#ifdef XIntc_MasterEnable
    XIntc_MasterEnable(UPBHWR_INTC_0_BASEADDR);
#endif
#endif
#endif
}

void 
hal_virtex4_interrupt_init(void)
{
}

static inline unsigned long vectorToMask(int vector,
                                         const char* defaultError,
                                         unsigned long defaultMask)
{
  switch( vector )
  {
#ifdef MNDHWR_VIRTEX4_EMAC
    case CYGNUM_HAL_INTERRUPT_EMAC:
      return CYGNUM_HAL_INTERRUPT_EMAC_MASK;
    case CYGNUM_HAL_INTERRUPT_PHY:
      return CYGNUM_HAL_INTERRUPT_PHY_MASK;
#endif
#ifdef MNDHWR_VIRTEX4_SGDMATEMAC
    case CYGNUM_HAL_INTERRUPT_SGDMATEMAC:
      return CYGNUM_HAL_INTERRUPT_SGDMATEMAC_MASK;
#endif
#ifdef MNDHWR_VIRTEX4_USB
    case CYGNUM_HAL_INTERRUPT_USB:
      return CYGNUM_HAL_INTERRUPT_USB_MASK;
#endif
#ifdef MNDHWR_VIRTEX4_SYSACE
    case CYGNUM_HAL_INTERRUPT_SYSACE:
      return CYGNUM_HAL_INTERRUPT_SYSACE_MASK;
#endif
#ifdef MNDHWR_VIRTEX4_AC97
    case CYGNUM_HAL_INTERRUPT_AC97REC:
      return CYGNUM_HAL_INTERRUPT_AC97REC_MASK;
    case CYGNUM_HAL_INTERRUPT_AC97PB:
      return CYGNUM_HAL_INTERRUPT_AC97PB_MASK;
#endif
#ifdef MNDHWR_VIRTEX4_IIC
    case CYGNUM_HAL_INTERRUPT_I2C:
      return CYGNUM_HAL_INTERRUPT_I2C_MASK;
#endif
#ifdef MNDHWR_VIRTEX4_PS22
    case CYGNUM_HAL_INTERRUPT_PS22:
      return CYGNUM_HAL_INTERRUPT_PS22;
#endif
#ifdef MNDHWR_VIRTEX4_PS21
    case CYGNUM_HAL_INTERRUPT_PS21:
      return CYGNUM_HAL_INTERRUPT_PS21;
#endif
#ifdef MNDHWR_VIRTEX4_UART
    case CYGNUM_HAL_INTERRUPT_UART0:
      return CYGNUM_HAL_INTERRUPT_UART0_MASK;
#endif

#ifdef RECONOS_VIRTEX4_GPIO_INTR
    case CYGNUM_HAL_INTERRUPT_GPIO0:
      return CYGNUM_HAL_INTERRUPT_GPIO0_MASK;
#endif

#ifdef UPBHWR_VIRTEX4_PROFILE_TIMER
    case CYGNUM_HAL_INTERRUPT_FIT:
      return CYGNUM_HAL_INTERRUPT_FIT_MASK;
#endif

#ifdef UPBHWR_VIRTEX4_DCR_TIMEBASE
    case CYGNUM_HAL_INTERRUPT_TIMEBASE:
      return CYGNUM_HAL_INTERRUPT_TIMEBASE_MASK;
#endif

#ifdef UPBHWR_VIRTEX4_ICAP_LIS
    case CYGNUM_HAL_INTERRUPT_ICAP_LIS:
      return CYGNUM_HAL_INTERRUPT_ICAP_LIS_MASK;
#endif

#ifdef UPBHWR_VIRTEX4_RECONOS_INTR
#if UPBHWR_NUM_OSIFS > 0
    case CYGNUM_HAL_INTERRUPT_RECONOS0:
      return CYGNUM_HAL_INTERRUPT_RECONOS0_MASK;
#endif
#if UPBHWR_NUM_OSIFS > 1
    case CYGNUM_HAL_INTERRUPT_RECONOS1:
      return CYGNUM_HAL_INTERRUPT_RECONOS1_MASK;
#endif      
#if UPBHWR_NUM_OSIFS > 2
    case CYGNUM_HAL_INTERRUPT_RECONOS2:
      return CYGNUM_HAL_INTERRUPT_RECONOS2_MASK;
#endif      
#if UPBHWR_NUM_OSIFS > 3
    case CYGNUM_HAL_INTERRUPT_RECONOS3:
      return CYGNUM_HAL_INTERRUPT_RECONOS3_MASK;
#endif      
#if UPBHWR_NUM_OSIFS > 4
    case CYGNUM_HAL_INTERRUPT_RECONOS4:
      return CYGNUM_HAL_INTERRUPT_RECONOS4_MASK;
#endif      
#if UPBHWR_NUM_OSIFS > 5
    case CYGNUM_HAL_INTERRUPT_RECONOS5:
      return CYGNUM_HAL_INTERRUPT_RECONOS5_MASK;
#endif      
#if UPBHWR_NUM_OSIFS > 6
    case CYGNUM_HAL_INTERRUPT_RECONOS6:
      return CYGNUM_HAL_INTERRUPT_RECONOS6_MASK;
#endif      
#if UPBHWR_NUM_OSIFS > 7
    case CYGNUM_HAL_INTERRUPT_RECONOS7:
      return CYGNUM_HAL_INTERRUPT_RECONOS7_MASK;
#endif      
#if UPBHWR_NUM_OSIFS > 8
#error "We don't support more than 8 slots."
#endif
#endif // UPBHWR_VIRTEX4_RECONOS_INTR

    default:
      diag_printf( defaultError );
      return defaultMask;
  }
}

void 
hal_virtex4_interrupt_mask(int vector)
{
    unsigned long mask = 0;
    mask = vectorToMask(vector, "hal_virtex4_interrupt_mask: default case", XINTC_PPC_ALL);
    XINTC_PPC_WRITE(XINTC_PPC_CIE,mask);
}

void 
hal_virtex4_interrupt_unmask(int vector)
{
    unsigned long mask = 0;
    mask = vectorToMask(vector, "hal_virtex4_interrupt_unmask: default case", ~XINTC_PPC_SIE);
    XINTC_PPC_WRITE(XINTC_PPC_SIE,mask);
}

void 
hal_virtex4_interrupt_acknowledge(int vector)
{
    unsigned long mask = 0;
    mask = vectorToMask(vector, "hal_virtex4_interrupt_acknowledge: default case", XINTC_PPC_ALL);
    XINTC_PPC_WRITE(XINTC_PPC_IAR,mask);
}

void 
hal_virtex4_interrupt_configure(int vector, int level, int dir)
{
}

void 
hal_virtex4_interrupt_set_level(int vector, int level)
{
}

//----------------------------------------------------------------------------------------------------------------------------------
// I2C Support
//----------------------------------------------------------------------------------------------------------------------------------
void
hal_ppc40x_i2c_init()
{
#ifdef CYGSEM_VIRTEX4_I2C_SUPPORT
    virtex4_i2c_init();
#endif
}

// EOF hal_aux.c
