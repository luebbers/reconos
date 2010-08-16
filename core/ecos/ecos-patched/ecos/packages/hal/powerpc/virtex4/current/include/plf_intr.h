#ifndef CYGONCE_HAL_PLF_INTR_H
#define CYGONCE_HAL_PLF_INTR_H

//==========================================================================
//
//      plf_intr.h
//
//      Xilinx VIRTEX4 platform specific interrupt definitions
//      Taken from ML300 board
//
//==========================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002, 2003, 2004, 2005 Mind n.v.
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
// Author(s):    jskov
// Contributors: jskov, gthomas
// Date:         2000-06-13
// Purpose:      Define platform specific interrupt support
//              
// Usage:
//              #include <cyg/hal/plf_intr.h>
//              ...
//              
//
//####DESCRIPTIONEND####
//
//==========================================================================

#include <pkgconf/hal.h>
#include <cyg/infra/cyg_type.h>
#include <xparameters.h>
#include <xparameters_translation.h>
#include <xintc_l.h>

//--------------------------------------------------------------------------
// Platform defined interrupt layout
#define CYGHWR_HAL_INTERRUPT_LAYOUT_DEFINED
// Additional interrupt sources which are supported by the VIRTEX4

#define VIRTEX4_IAR   0xD1000FCC
#define VIRTEX4_SIE   0xD1000FD0
#define VIRTEX4_CIE   0xD1000FD4

#define CYGNUM_HAL_INTERRUPT_405_BASE   1
#define CYGNUM_HAL_INTERRUPT_first      CYGNUM_HAL_INTERRUPT_405_BASE
#define CYGNUM_HAL_INTERRUPT_EMAC       (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_ETHERNET_0_INTR)
#define CYGNUM_HAL_INTERRUPT_SGDMATEMAC (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_TEMAC_0_INTR)
#define CYGNUM_HAL_INTERRUPT_USB        (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_USB_HPI_INTR)
#define CYGNUM_HAL_INTERRUPT_PHY        (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_PHY_0_INTR)
#define CYGNUM_HAL_INTERRUPT_SYSACE     (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_SYSACE_0_INTR)
#define CYGNUM_HAL_INTERRUPT_AC97REC    (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_AC97_0_INTR)
#define CYGNUM_HAL_INTERRUPT_AC97PB     (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_AC97_0_PLAYBACK_INTR)
#define CYGNUM_HAL_INTERRUPT_I2C        (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_IIC_0_INTR)
#define CYGNUM_HAL_INTERRUPT_PS22       (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_PS2_0_2_INTR)
#define CYGNUM_HAL_INTERRUPT_PS21       (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_PS2_0_1_INTR)
#define CYGNUM_HAL_INTERRUPT_UART0      (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_UART16550_0_INTR)
#define CYGNUM_HAL_INTERRUPT_FIT        (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_FIT_TIMER_0_INTR)
#define CYGNUM_HAL_INTERRUPT_TIMEBASE   (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_DCR_TIMEBASE_0_INTR)
#define CYGNUM_HAL_INTERRUPT_ICAP_LIS   (CYGNUM_HAL_INTERRUPT_405_BASE + UPBHWR_ICAP_LIS_0_INTR)

// GPIO
#define CYGNUM_HAL_INTERRUPT_GPIO0      (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_GPIO_0_INTR)

//
// ---------- RECONOS INTERRUPTS and INTERRUPT MASKS ----------
//
#ifdef UPBHWR_VIRTEX4_RECONOS_INTR

#ifdef UPBHWR_NUM_OSIFS
#if UPBHWR_NUM_OSIFS > 0
#define CYGNUM_HAL_INTERRUPT_RECONOS0   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_0_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS0_MASK   UPBHWR_OSIF_0_INTR_MASK
#endif

#if UPBHWR_NUM_OSIFS > 1
#define CYGNUM_HAL_INTERRUPT_RECONOS1   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_1_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS1_MASK   UPBHWR_OSIF_1_INTR_MASK
#endif

#if UPBHWR_NUM_OSIFS > 2
#define CYGNUM_HAL_INTERRUPT_RECONOS2   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_2_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS2_MASK   UPBHWR_OSIF_2_INTR_MASK
#endif

#if UPBHWR_NUM_OSIFS > 3
#define CYGNUM_HAL_INTERRUPT_RECONOS3   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_3_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS3_MASK   UPBHWR_OSIF_3_INTR_MASK
#endif

#if UPBHWR_NUM_OSIFS > 4
#define CYGNUM_HAL_INTERRUPT_RECONOS4   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_4_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS4_MASK   UPBHWR_OSIF_4_INTR_MASK
#endif

#if UPBHWR_NUM_OSIFS > 5
#define CYGNUM_HAL_INTERRUPT_RECONOS5   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_5_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS5_MASK   UPBHWR_OSIF_5_INTR_MASK
#endif

#if UPBHWR_NUM_OSIFS > 6
#define CYGNUM_HAL_INTERRUPT_RECONOS6   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_6_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS6_MASK   UPBHWR_OSIF_6_INTR_MASK
#endif

#if UPBHWR_NUM_OSIFS > 7
#define CYGNUM_HAL_INTERRUPT_RECONOS7   (CYGNUM_HAL_INTERRUPT_405_BASE+UPBHWR_OSIF_7_INTR)
#define CYGNUM_HAL_INTERRUPT_RECONOS7_MASK   UPBHWR_OSIF_7_INTR_MASK
#endif

#endif // UPB_HWR_VIRTEX4_RECONOS_NUMSLOTS
#endif // RECONOS_INTR
// ---------------------------------------------------------------


// FIXME
#define CYGNUM_HAL_INTERRUPT_last       20

// Masks for all interrutps
#define CYGNUM_HAL_INTERRUPT_EMAC_MASK       UPBHWR_ETHERNET_0_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_SGDMATEMAC_MASK XPAR_TEMAC_0_IP2INTC_IRPT_MASK
#define CYGNUM_HAL_INTERRUPT_USB_MASK        XPAR_SYSTEM_USB_HPI_INT_MASK
#define CYGNUM_HAL_INTERRUPT_PHY_MASK        UPBHWR_PHY_0_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_SYSACE_MASK     UPBHWR_SYSACE_0_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_AC97REC_MASK    UPBHWR_AC97_0_RECORD_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_AC97PB_MASK     UPBHWR_AC97_0_PLAYBACK_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_I2C_MASK        UPBHWR_IIC_0_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_PS22_MASK       UPBHWR_PS2_0_2_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_PS21_MASK       UPBHWR_PS2_0_1_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_UART0_MASK      UPBHWR_UART16550_0_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_FIT_MASK        UPBHWR_FIT_TIMER_0_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_TIMEBASE_MASK   UPBHWR_DCR_TIMEBASE_0_INTR_MASK
#define CYGNUM_HAL_INTERRUPT_ICAP_LIS_MASK   UPBHWR_ICAP_LIS_0_INTR_MASK

// GPIO
#define CYGNUM_HAL_INTERRUPT_GPIO0_MASK UPBHWR_GPIO_0_INTR_MASK

// new for ReconOS
// see plf_intr_reconos.h

// Platform defines interrupt controller access
#define CYGHWR_HAL_INTERRUPT_CONTROLLER_DEFINED
externC void hal_virtex4_interrupt_init(void);
externC void hal_virtex4_interrupt_mask(int);
externC void hal_virtex4_interrupt_unmask(int);
externC void hal_virtex4_interrupt_acknowledge(int);
externC void hal_virtex4_interrupt_configure(int, int, int);
externC void hal_virtex4_interrupt_set_level(int, int);

#define HAL_PLF_INTERRUPT_INIT()                                \
    hal_virtex4_interrupt_init()                                     
#define HAL_PLF_INTERRUPT_MASK( _vector_ )                      \
    hal_virtex4_interrupt_mask( _vector_ )                         
#define HAL_PLF_INTERRUPT_UNMASK( _vector_ )                    \
    hal_virtex4_interrupt_unmask( _vector_ )                       
#define HAL_PLF_INTERRUPT_ACKNOWLEDGE( _vector_ )               \
    hal_virtex4_interrupt_acknowledge( _vector_ )                  
#define HAL_PLF_INTERRUPT_CONFIGURE( _vector_, _level_, _up_ )  \
    hal_virtex4_interrupt_configure( _vector_, _level_, _up_ )     
#define HAL_PLF_INTERRUPT_SET_LEVEL( _vector_, _level_ )        \
    hal_virtex4_interrupt_set_level( _vector_, _level_ )

//-----------------------------------------------------------------------------
// Symbols used by assembly code
#define CYGARC_PLATFORM_DEFS                                            \
    DEFINE(_VIRTEX4_INTC, UPBHWR_INTC_0_BASEADDR);                          \
    DEFINE(_VIRTEX4_INTC_ISR, XIN_ISR_OFFSET);                            \
    DEFINE(_VIRTEX4_INTC_IER, XIN_IER_OFFSET);                            \
    DEFINE(CYGNUM_HAL_INTERRUPT_first, CYGNUM_HAL_INTERRUPT_first);

//--------------------------------------------------------------------------
// Control-C support.

//----------------------------------------------------------------------------
// Reset.

externC void _virtex4_reset(void);
#define HAL_PLATFORM_RESET() _virtex4_reset()
#define HAL_PLATFORM_RESET_ENTRY 0xFFF80100

//--------------------------------------------------------------------------
#endif // ifndef CYGONCE_HAL_PLF_INTR_H
// End of plf_intr.h
