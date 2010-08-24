//==========================================================================
//
//      dev/if_spartan3esk.c
//
//      Spartan3E Starter Kit ethernet support
//      Taken from the driver for the Xilinx VIRTEX4 development board
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
// Author(s):    Michal Pfeifer
// Contributors:
// Date:         2003-09-23
//               2005-04-21
// Purpose:      
// Description:  eCos hardware driver for Xilinx ML300
//              
//
//####DESCRIPTIONEND####
//
//==========================================================================

//#include <pkgconf/devs_eth_microblaze_emaclite.h>
#include <cyg/infra/cyg_type.h>
#include <cyg/infra/diag.h>

#include <cyg/hal/hal_arch.h>
#include <cyg/hal/hal_cache.h>
#include <cyg/hal/hal_intr.h>
#include <cyg/hal/drv_api.h>
#include <cyg/hal/hal_if.h>

#include <cyg/io/eth/netdev.h>
#include <cyg/io/eth/eth_drv.h>
//#include <cyg/io/eth_phy.h>

#ifdef CYGPKG_NET
#include <pkgconf/net.h>
#endif

#include "adapter.h"

#ifdef CYGPKG_REDBOOT
#include <pkgconf/redboot.h>
#ifdef CYGSEM_REDBOOT_FLASH_CONFIG
#include <redboot.h>
#include <flash_config.h>
#endif
#endif

#include <cyg/hal/platform.h>	/* platform setting */

//#define ALIGN_TO_CACHE_LINES(x)  ( (long)((x) + 31) & 0xffffffe0 )

//#define os_printf diag_printf

// CONFIG_ESA and CONFIG_BOOL are defined in redboot/include/flash_config.h
#ifndef CONFIG_ESA
#define CONFIG_ESA 6      // ethernet address length ...
#endif

#ifndef CONFIG_BOOL
#define CONFIG_BOOL 1
#endif

static int deferred = 0; // FIXME

// Align buffers on a cache boundary
static unsigned char emaclite_rxbufs[MTU];
static unsigned char emaclite_txbufs[MTU];

static struct emaclite_info emaclite0_info = {
    MON_EMACLITE_INTR,             // Interrupt vector 
    "eth0_esa",
    { 0x08, 0x00, 0x3E, 0x28, 0x7A, 0xBA},  // Default ESA
    emaclite_rxbufs,                      // Rx buffer space
    emaclite_txbufs                      // Tx buffer space
//    &eth0_phy,                             // PHY access routines
};

ETH_DRV_SC(emaclite0_sc,
           &emaclite0_info,  // Driver specific data
           "eth0",             // Name for this interface
           emaclite_start,
           emaclite_stop,
           emaclite_control,
           emaclite_can_send,
           emaclite_send,
           emaclite_recv,
           emaclite_deliver,
           emaclite_int,
           emaclite_int_vector);

NETDEVTAB_ENTRY(s3esk_netdev, 
                "emaclite", 
                emaclite_init, 
                &emaclite0_sc);

#ifdef CYGPKG_REDBOOT
#include <pkgconf/redboot.h>
#ifdef CYGSEM_REDBOOT_FLASH_CONFIG
#include <redboot.h>
#include <flash_config.h>
RedBoot_config_option("Network hardware address [MAC]",
                      eth0_esa,
                      ALWAYS_ENABLED, true,
                      CONFIG_ESA, &emaclite0_info.enaddr
    );
#endif // CYGSEM_REDBOOT_FLASH_CONFIG
#endif // CYGPKG_REDBOOT


static void emaclite_int(struct eth_drv_sc *data);
static void emaclite_RxEvent(void *sc);
static void emaclite_TxEvent(void *sc);

// This ISR is called when the ethernet interrupt occurs
#ifdef CYGPKG_NET
static int
emaclite_isr(cyg_vector_t vector, cyg_addrword_t data, HAL_SavedRegisters *regs)
{
    struct eth_drv_sc *sc = (struct eth_drv_sc *)data;
    struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;

    cyg_drv_interrupt_mask(qi->int_vector);
    return (CYG_ISR_HANDLED|CYG_ISR_CALL_DSR);  // Run the DSR
}
#endif

// Deliver function (ex-DSR) handles the ethernet [logical] processing
static void
emaclite_deliver(struct eth_drv_sc * sc)
{
#ifdef CYGPKG_NET
    struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
    cyg_drv_interrupt_acknowledge(qi->int_vector);
#endif
    emaclite_int(sc);
#ifdef CYGPKG_NET
    cyg_drv_interrupt_unmask(qi->int_vector);
#endif

}

//
// PHY unit access
//
static XEmacLite *_s3esk_dev;  // Hack - since PHY routines don't provide this



// Initialize the interface - performed at system startup
// This function must set up the interface, including arranging to
// handle interrupts, etc, so that it may be "started" cheaply later.
static bool emaclite_init(struct cyg_netdevtab_entry *dtp)
{
	struct eth_drv_sc *sc = (struct eth_drv_sc *)dtp->device_instance;
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;

	unsigned char _enaddr[6];
	bool esa_ok;

	/* Try to read the ethernet address of the transciever ... */
#if defined(CYGPKG_REDBOOT) && defined(CYGSEM_REDBOOT_FLASH_CONFIG)
	esa_ok = flash_get_config(qi->esa_key, _enaddr, CONFIG_ESA);
#else
	esa_ok = CYGACC_CALL_IF_FLASH_CFG_OP(CYGNUM_CALL_IF_FLASH_CFG_GET, 
					qi->esa_key, _enaddr, CONFIG_ESA);
#endif
	if (esa_ok) {
		memcpy(qi->enaddr, _enaddr, sizeof(qi->enaddr));
	} else {
		/* No 'flash config' data available - use default */
		diag_printf("Emaclite_ETH - Warning! Using default ESA for '%s'\n", dtp->name);
	}

	/* Initialize Xilinx driver  - device id 0*/
	if (XEmacLite_Initialize(&qi->dev, 0) != XST_SUCCESS) {
		diag_printf("Emaclite_ETH - can't initialize\n");
		return false;
	}
	if (XEmacLite_SelfTest(&qi->dev) != XST_SUCCESS) {
		diag_printf("Emaclite_ETH - self test failed\n");
		return false;
	}

	XEmacLite_SetMacAddress(&qi->dev, qi->enaddr);
	XEmacLite_SetSendHandler(&qi->dev, sc, emaclite_TxEvent);
	XEmacLite_SetRecvHandler(&qi->dev, sc, emaclite_RxEvent);


#ifdef CYGPKG_NET
	/* Set up to handle interrupts */
	cyg_drv_interrupt_create(qi->int_vector,
				0,  // Highest //CYGARC_SIU_PRIORITY_HIGH,
				(cyg_addrword_t)sc, //  Data passed to ISR
				(cyg_ISR_t *)emaclite_isr,
				(cyg_DSR_t *)eth_drv_dsr,
				&qi->emaclite_interrupt_handle,
				&qi->emaclite_interrupt);
	cyg_drv_interrupt_attach(qi->emaclite_interrupt_handle);
	cyg_drv_interrupt_acknowledge(qi->int_vector);
	cyg_drv_interrupt_unmask(qi->int_vector);
#endif

	/* Operating mode */
	_s3esk_dev = &qi->dev;

	/* Initialize upper level driver for ecos */
	(sc->funs->eth_drv->init)(sc, (unsigned char *)&qi->enaddr);

	return true;
}
 
//
// This function is called to "start up" the interface.  It may be called
// multiple times, even when the hardware is already running.  It will be
// called whenever something "hardware oriented" changes and should leave
// the hardware ready to send/receive packets.
//
static void emaclite_start(struct eth_drv_sc *sc, unsigned char *enaddr, int flags)
{
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
	XEmacLite_EnableInterrupts(&qi->dev);
}

//
// This function is called to shut down the interface.
//
static void emaclite_stop(struct eth_drv_sc *sc)
{
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
	XEmacLite_DisableInterrupts(&qi->dev);
}

//
// This function is called for low level "control" operations
//
static int emaclite_control(struct eth_drv_sc *sc, unsigned long key, void *data, int length)
{
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;

	switch (key) {
	case ETH_DRV_SET_MAC_ADDRESS:
		XEmacLite_SetMacAddress(&qi->dev, qi->enaddr);
		return 0;
		break;
	default:
		return 1;
		break;
	}
}


/*
 * This function is called to see if another packet can be sent.
 * It should return the number of packets which can be handled.
 * Zero should be returned if the interface is busy and can not send any more.
 */
static int emaclite_can_send(struct eth_drv_sc *sc)
{
  return !deferred;
}


/* This routine is called to send data to the hardware. */
static void emaclite_send(struct eth_drv_sc *sc, struct eth_drv_sg *sg_list,
				int sg_len, int total_len, unsigned long key)
{
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
	volatile char *bp;
	int i;

#ifdef CYGPKG_NET
	cyg_uint32 int_state;
	HAL_DISABLE_INTERRUPTS(int_state);
	// FIXME: closer to Send
#endif

	/* can be send max 1500 bytes */
	/* Set up buffer */
	qi->txlength = total_len;
	bp = qi->txbuf;
	qi->sended = 0;
	for (i = 0;  i < sg_len;  i++) {
		memcpy((void *)bp, (void *)sg_list[i].buf, sg_list[i].len);
		bp += sg_list[i].len;
	}

	cyg_uint32 len = qi->txlength - qi->sended;
	if(len > MTU) len = MTU;
	
	//XEmacLite_SetMacAddress(&qi->dev, qi->enaddr);
	if (XEmacLite_Send(&qi->dev, qi->txbuf + qi->sended, len) != XST_SUCCESS) {
		deferred = 1;
	} else {
		qi->sended += len;
		if(qi->sended >= qi->txlength) deferred = 0;
		else deferred = 1;
	}

	// sg_list can be freed! (maybe deferred)
	// FIXME this can be removed
	(sc->funs->eth_drv->tx_done)(sc, key, 0);
#ifdef CYGPKG_NET
	HAL_RESTORE_INTERRUPTS(int_state);
#endif
}

//
// This function is called when a frame has been sent
//
static void
emaclite_TxEvent(void *_cb)
{
    struct eth_drv_sc *sc = (struct eth_drv_sc *)_cb;
    struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;

    if (deferred) {
      	cyg_uint32 len = qi->txlength - qi->sended;
		if(len > MTU) len = MTU;
		
		//XEmacLite_SetMacAddress(&qi->dev, qi->enaddr);
		if (XEmacLite_Send(&qi->dev, qi->txbuf + qi->sended, len) != XST_SUCCESS) {
			deferred = 1;
	    }
		else
		{
			qi->sended += len;
			if(qi->sended >= qi->txlength) deferred = 0;
			else deferred = 1;
		}
    }
}

//
// This function is called when a packet has been received.  It's job is
// to prepare to unload the packet from the hardware.  Once the length of
// the packet is known, the upper layer of the driver can be told.  When
// the upper layer is ready to unload the packet, the internal function
// 'emaclite_recv' will be called to actually fetch it from the hardware.
//
static void emaclite_RxEvent(void *_cb)
{
	struct eth_drv_sc *sc = (struct eth_drv_sc *)_cb;
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
	cyg_uint32 len;

	len = (cyg_uint32)XEmacLite_Recv(&qi->dev, qi->rxbuf);
	if(len > 0) {
		qi->rxlength = len;
		(sc->funs->eth_drv->recv)(sc, qi->rxlength);
	}
}

//
// This function is called as a result of the "eth_drv_recv()" call above.
// It's job is to actually fetch data for a packet from the hardware once
// memory buffers have been allocated for the packet.  Note that the buffers
// may come in pieces, using a scatter-gather list.  This allows for more
// efficient processing in the upper layers of the stack.
//
static void emaclite_recv(struct eth_drv_sc *sc, struct eth_drv_sg *sg_list, int sg_len)
{
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
	unsigned char *bp;
	int i;

	bp = (unsigned char *)qi->rxbuf;

	for (i = 0;  i < sg_len;  i++) {
		if (sg_list[i].buf != 0) {
			memcpy((void *)sg_list[i].buf, bp, sg_list[i].len);
			bp += sg_list[i].len;
		}
	}
}

/* Interrupt processing */
static void emaclite_int(struct eth_drv_sc *sc)
{
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
	XEmacLite_InterruptHandler(&qi->dev);
}

/* Interrupt vector */
static int emaclite_int_vector(struct eth_drv_sc *sc)
{
	struct emaclite_info *qi = (struct emaclite_info *)sc->driver_private;
	return (qi->int_vector);
}
