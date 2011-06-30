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

#include <pkgconf/devs_eth_microblaze_s3esklite.h>
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

#include "spartan3esk.h"

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

//
// PHY access functions
//
//static void s3esk_eth_phy_init(void);
//static void s3esk_eth_phy_reset(void);
//static void s3esk_eth_phy_put_reg(int reg, int phy, unsigned short data);
//static bool s3esk_eth_phy_get_reg(int reg, int phy, unsigned short *val);
//#define PHY_DEBUG

//ETH_PHY_REG_LEVEL_ACCESS_FUNS(eth0_phy, 
//                              s3esk_eth_phy_init,
//                              s3esk_eth_phy_reset,
//                              s3esk_eth_phy_put_reg,
//                              s3esk_eth_phy_get_reg);

// Align buffers on a cache boundary
static unsigned char s3esk_eth_rxbufs[CYGNUM_DEVS_ETH_POWERPC_S3ESK_BUFSIZE];
static unsigned char s3esk_eth_txbufs[CYGNUM_DEVS_ETH_POWERPC_S3ESK_BUFSIZE];

static struct s3esk_eth_info s3esk_eth0_info = {
    MON_EMACLITE_INTR,             // Interrupt vector
    "eth0_esa",
    { 0x08, 0x00, 0x3E, 0x28, 0x7A, 0xBA},  // Default ESA
    s3esk_eth_rxbufs,                      // Rx buffer space
    s3esk_eth_txbufs                      // Tx buffer space
//    &eth0_phy,                             // PHY access routines
};

ETH_DRV_SC(s3esk_eth0_sc,
           &s3esk_eth0_info,  // Driver specific data
           "eth0",             // Name for this interface
           s3esk_eth_start,
           s3esk_eth_stop,
           s3esk_eth_control,
           s3esk_eth_can_send,
           s3esk_eth_send,
           s3esk_eth_recv,
           s3esk_eth_deliver,
           s3esk_eth_int,
           s3esk_eth_int_vector);

NETDEVTAB_ENTRY(s3esk_netdev, 
                "s3esk_eth", 
                s3esk_eth_init, 
                &s3esk_eth0_sc);

#ifdef CYGPKG_REDBOOT
#include <pkgconf/redboot.h>
#ifdef CYGSEM_REDBOOT_FLASH_CONFIG
#include <redboot.h>
#include <flash_config.h>
RedBoot_config_option("Network hardware address [MAC]",
                      eth0_esa,
                      ALWAYS_ENABLED, true,
                      CONFIG_ESA, &s3esk_eth0_info.enaddr
    );
#endif // CYGSEM_REDBOOT_FLASH_CONFIG
#endif // CYGPKG_REDBOOT


static void s3esk_eth_int(struct eth_drv_sc *data);
static void s3esk_eth_RxEvent(void *sc);
static void s3esk_eth_TxEvent(void *sc);
//static void s3esk_eth_ErrEvent(void *sc, XStatus code);

// This ISR is called when the ethernet interrupt occurs
#ifdef CYGPKG_NET
static int
s3esk_eth_isr(cyg_vector_t vector, cyg_addrword_t data, HAL_SavedRegisters *regs)
{
    struct eth_drv_sc *sc = (struct eth_drv_sc *)data;
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;

    cyg_drv_interrupt_mask(qi->int_vector);
    return (CYG_ISR_HANDLED|CYG_ISR_CALL_DSR);  // Run the DSR
}
#endif

// Deliver function (ex-DSR) handles the ethernet [logical] processing
static void
s3esk_eth_deliver(struct eth_drv_sc * sc)
{
#ifdef CYGPKG_NET
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    cyg_drv_interrupt_acknowledge(qi->int_vector);
#endif
    s3esk_eth_int(sc);
#ifdef CYGPKG_NET
    cyg_drv_interrupt_unmask(qi->int_vector);
#endif

}

//
// PHY unit access
//
static XEmacLite *_s3esk_dev;  // Hack - since PHY routines don't provide this
/* PHY func removed
static void 
s3esk_eth_phy_init(void)
{
    // Set up MII hardware - nothing to do on this platform
}

static void
s3esk_eth_phy_reset(void)
{
    //diag_printf( "Resetting PHY! \n" );
    //XEmac_mPhyReset(_s3esk_dev->BaseAddress);
	// nothing to do on this platform - phy reset on OPB-reset
}

static void 
s3esk_eth_phy_put_reg(int reg, int phy, unsigned short data)
{
#ifdef PHY_DEBUG
    //os_printf("PHY PUT - reg: %d, phy: %d, val: %04x\n", reg, phy, data);
#endif
    //XEmac_PhyWrite(_s3esk_dev, phy, reg, data);
}

static bool 
s3esk_eth_phy_get_reg(int reg, int phy, unsigned short *val)
{
    //if (XEmac_PhyRead(_s3esk_dev, phy, reg, val) == XST_SUCCESS) {
#ifdef PHY_DEBUG
        //os_printf("PHY GET - reg: %d, phy: %d = %x\n", reg, phy, *val);
#endif
        return true;
    //} else {
    //    return false;  // Failed for some reason
    //}
}
*/

// Initialize the interface - performed at system startup
// This function must set up the interface, including arranging to
// handle interrupts, etc, so that it may be "started" cheaply later.
static bool 
s3esk_eth_init(struct cyg_netdevtab_entry *dtp)
{
    struct eth_drv_sc *sc = (struct eth_drv_sc *)dtp->device_instance;
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    
	//Xuint32 opt;
    unsigned char _enaddr[6];
    bool esa_ok;

    // Try to read the ethernet address of the transciever ...
#if defined(CYGPKG_REDBOOT) && defined(CYGSEM_REDBOOT_FLASH_CONFIG)
    esa_ok = flash_get_config(qi->esa_key, _enaddr, CONFIG_ESA);
#else
    esa_ok = CYGACC_CALL_IF_FLASH_CFG_OP(CYGNUM_CALL_IF_FLASH_CFG_GET, 
                                         qi->esa_key, _enaddr, CONFIG_ESA);
#endif
    if (esa_ok) {
        memcpy(qi->enaddr, _enaddr, sizeof(qi->enaddr));
    } else {
        // No 'flash config' data available - use default
        diag_printf("s3esk_ETH - Warning! Using default ESA for '%s'\n", dtp->name);
    }

    // Initialize Xilinx driver
    if (XEmacLite_Initialize(&qi->dev, XPAR_ETHERNET_MAC_DEVICE_ID) != XST_SUCCESS) {
        diag_printf("s3esk_ETH - can't initialize\n");
        return false;
    }
    //if (XEmac_mIsSgDma(&qi->dev)) {
    //    diag_printf("s3esk_ETH - DMA support?\n");
    //    return false;
    //}
    if (XEmacLite_SelfTest(&qi->dev) != XST_SUCCESS) {
        diag_printf("s3esk_ETH - self test failed\n");
        return false;
    }
    //XEmac_ClearStats(&qi->dev);

    // Configure device operating mode
    //opt = XEM_UNICAST_OPTION | 
    //    XEM_BROADCAST_OPTION |
    //    XEM_INSERT_PAD_OPTION |
    //    XEM_INSERT_FCS_OPTION |
    //    XEM_STRIP_PAD_FCS_OPTION;
    //if (XEmac_SetOptions(&qi->dev, opt) != XST_SUCCESS) {
    //    diag_printf("s3esk_ETH - can't configure mode\n");
    //    return false;
    //}
    //if (XEmacLite_SetMacAddress(&qi->dev, qi->enaddr) != XST_SUCCESS) {
    //    diag_printf("s3esk_ETH - can't set ESA\n");
    //    return false;
    //}
	XEmacLite_SetMacAddress(&qi->dev, qi->enaddr);
	
    // Set up FIFO handling routines - these are callbacks from the
    // Xilinx driver code which happen at interrupt time
    XEmacLite_SetSendHandler(&qi->dev, sc, s3esk_eth_TxEvent);
    XEmacLite_SetRecvHandler(&qi->dev, sc, s3esk_eth_RxEvent);
    //XEmac_SetErrorHandler(&qi->dev, sc, s3esk_eth_ErrEvent);

#ifdef CYGPKG_NET
    // Set up to handle interrupts
    cyg_drv_interrupt_create(qi->int_vector,
                             0,  // Highest //CYGARC_SIU_PRIORITY_HIGH,
                             (cyg_addrword_t)sc, //  Data passed to ISR
                             (cyg_ISR_t *)s3esk_eth_isr,
                             (cyg_DSR_t *)eth_drv_dsr,
                             &qi->s3esk_eth_interrupt_handle,
                             &qi->s3esk_eth_interrupt);
    cyg_drv_interrupt_attach(qi->s3esk_eth_interrupt_handle);
    cyg_drv_interrupt_acknowledge(qi->int_vector);
    cyg_drv_interrupt_unmask(qi->int_vector);
#endif

    // Operating mode
    _s3esk_dev = &qi->dev;
    
	//if (!_eth_phy_init(qi->phy)) {
    //    return false;
    //}
//#ifdef CYGSEM_DEVS_ETH_POWERPC_s3esk_RESET_PHY
    //_eth_phy_reset(qi->phy);
//#endif

    // Initialize upper level driver for ecos
    (sc->funs->eth_drv->init)(sc, (unsigned char *)&qi->enaddr);

    return true;
}
 
//
// This function is called to "start up" the interface.  It may be called
// multiple times, even when the hardware is already running.  It will be
// called whenever something "hardware oriented" changes and should leave
// the hardware ready to send/receive packets.
//
static void
s3esk_eth_start(struct eth_drv_sc *sc, unsigned char *enaddr, int flags)
{
	
/*
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    unsigned short phy_state = 0;
    
    // Enable the device
    XEmac_Start(&qi->dev);
    phy_state = _eth_phy_state(qi->phy);
    diag_printf("s3esk ETH: ");
    if ((phy_state & ETH_PHY_STAT_LINK) != 0) {
        diag_printf( "Link detected - " );
        if ((phy_state & ETH_PHY_STAT_100MB) != 0) {
            // Link can handle 100Mb
            diag_printf("100Mb");
            if ((phy_state & ETH_PHY_STAT_FDX) != 0) {
                diag_printf("/Full Duplex");
            }
        } else {
            // Assume 10Mb, half duplex
            diag_printf("10Mb");
        }
    } else 
        diag_printf("s3esk ETH: Waiting for link to come up\n" ); 
    diag_printf("\n");
	*/
	struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
	XEmacLite_EnableInterrupts(&qi->dev);
}

//
// This function is called to shut down the interface.
//
static void
s3esk_eth_stop(struct eth_drv_sc *sc)
{
	//nothing to do

    //struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    
    // Disable the device : 
    //if (XEmac_Stop(&qi->dev) != XST_SUCCESS) {
    //    diag_printf("s3esk_ETH - can't stop device!\n");
    //}
	
	struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
	XEmacLite_DisableInterrupts(&qi->dev);
}


//
// This function is called for low level "control" operations
//
static int
s3esk_eth_control(struct eth_drv_sc *sc, unsigned long key,
                void *data, int length)
{
	struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;

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


//
// This function is called to see if another packet can be sent.
// It should return the number of packets which can be handled.
// Zero should be returned if the interface is busy and can not send any more.
//
static int
s3esk_eth_can_send(struct eth_drv_sc *sc)
{
  return !deferred;
}

//
// This routine is called to send data to the hardware.
static void 
s3esk_eth_send(struct eth_drv_sc *sc, struct eth_drv_sg *sg_list, int sg_len, 
             int total_len, unsigned long key)
{
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    volatile char *bp;
    int i;

#ifdef CYGPKG_NET
    cyg_uint32 int_state;
    HAL_DISABLE_INTERRUPTS(int_state);
    // FIXME: closer to Send
#endif

	//can be send max 1500 bytes
	
    // Set up buffer
	qi->txlength = total_len;
	bp = qi->txbuf;
	qi->sended = 0;
	for (i = 0;  i < sg_len;  i++) 
	{
        memcpy((void *)bp, (void *)sg_list[i].buf, sg_list[i].len);
        bp += sg_list[i].len;
    }
	
	cyg_uint32 len = qi->txlength - qi->sended;
	if(len > CYGNUM_DEVS_ETH_POWERPC_S3ESK_BUFSIZE) len = CYGNUM_DEVS_ETH_POWERPC_S3ESK_BUFSIZE;
	
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

    // sg_list can be freed! (maybe deferred)
    (sc->funs->eth_drv->tx_done)(sc, key, 0);
#ifdef CYGPKG_NET
    HAL_RESTORE_INTERRUPTS(int_state);
#endif
}

//
// This function is called when a frame has been sent
//
static void
s3esk_eth_TxEvent(void *_cb)
{
    struct eth_drv_sc *sc = (struct eth_drv_sc *)_cb;
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;

    if (deferred) {
      	cyg_uint32 len = qi->txlength - qi->sended;
		if(len > CYGNUM_DEVS_ETH_POWERPC_S3ESK_BUFSIZE) len = CYGNUM_DEVS_ETH_POWERPC_S3ESK_BUFSIZE;
		
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
// 's3esk_eth_recv' will be called to actually fetch it from the hardware.
//
static void
s3esk_eth_RxEvent(void *_cb)
{
    struct eth_drv_sc *sc = (struct eth_drv_sc *)_cb;
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    Xint32 len;

	len = (Xint32)XEmacLite_Recv(&qi->dev, qi->rxbuf);
	if(len>0){
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
static void
s3esk_eth_recv(struct eth_drv_sc *sc, struct eth_drv_sg *sg_list, int sg_len)
{
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
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

//
// This function is called when there is some sort of error
//
//static void
//s3esk_eth_ErrEvent(void *sc, XStatus code)
//{
//    diag_printf("%s.%d\n", __FUNCTION__, __LINE__);
//}

//
// Interrupt processing
//
static void          
s3esk_eth_int(struct eth_drv_sc *sc)
{
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    XEmacLite_InterruptHandler(&qi->dev);
}

//
// Interrupt vector
//
static int          
s3esk_eth_int_vector(struct eth_drv_sc *sc)
{
    struct s3esk_eth_info *qi = (struct s3esk_eth_info *)sc->driver_private;
    return (qi->int_vector);
}

