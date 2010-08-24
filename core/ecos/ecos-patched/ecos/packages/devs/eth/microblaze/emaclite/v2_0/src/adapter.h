//==========================================================================
//
//      adapter.h
//
//      Emaclite support
//      Taken from the Xilinx VIRTEX4 ethernet driver
//
//==========================================================================
//####ECOSGPLCOPYRIGHTBEGIN####
// -------------------------------------------
// This file is part of eCos, the Embedded Configurable Operating System.
// Copyright (C) 1998, 1999, 2000, 2001, 2002 Red Hat, Inc.
// Copyright (C) 2002, 2003, 2004, 2005 Mind n.v.
// Copyright (C) 2008 Michal Simek <monstr@monstr.eu>
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
// Description:  
//              
//
//####DESCRIPTIONEND####
//
//==========================================================================

#include "src/xemaclite.h"
#include "src/xemaclite_l.h"
#include <pkgconf/hal_microblaze_platform.h>

//
// Buffer descriptors - internal use with FIFO driver
//
#define EMACLITE_BD_Rx_Empty      0x8000  // Buffer is empty, S3ESK can fill
#define EMACLITE_BD_Rx_Wrap       0x2000  // Wrap: Last buffer in ring
#define EMACLITE_BD_Rx_Int        0x1000  // Interrupt
#define EMACLITE_BD_Rx_Last       0x0800  // Last buffer in frame
#define EMACLITE_BD_Rx_Miss       0x0100  // Miss: promiscious mode
#define EMACLITE_BD_Rx_BC         0x0080  // Broadcast address
#define EMACLITE_BD_Rx_MC         0x0040  // Multicast address
#define EMACLITE_BD_Rx_LG         0x0020  // Frame length violation
#define EMACLITE_BD_Rx_NO         0x0010  // Non-octet aligned frame
#define EMACLITE_BD_Rx_SH         0x0008  // Short frame
#define EMACLITE_BD_Rx_CR         0x0004  // CRC error
#define EMACLITE_BD_Rx_OV         0x0002  // Overrun
#define EMACLITE_BD_Rx_TR         0x0001  // Frame truncated. late collision

#define EMACLITE_BD_Tx_Ready      0x8000  // Frame ready
#define EMACLITE_BD_Tx_Pad        0x4000  // Pad short frames
#define EMACLITE_BD_Tx_Wrap       0x2000  // Wrap: Last buffer in ring
#define EMACLITE_BD_Tx_Int        0x1000  // Interrupt
#define EMACLITE_BD_Tx_Last       0x0800  // Last buffer in frame
#define EMACLITE_BD_Tx_TC         0x0400  // Send CRC after data
#define EMACLITE_BD_Tx_DEF        0x0200  // Defer indication
#define EMACLITE_BD_Tx_HB         0x0100  // Heartbeat
#define EMACLITE_BD_Tx_LC         0x0080  // Late collision
#define EMACLITE_BD_Tx_RL         0x0040  // Retransmission limit
#define EMACLITE_BD_Tx_RC         0x003C  // Retry count 
#define EMACLITE_BD_Tx_UN         0x0002  // Underrun
#define EMACLITE_BD_Tx_CSL        0x0001  // Carrier sense lost
#define EMACLITE_BD_Tx_ERRORS     (FCC_BD_Tx_LC|FCC_BD_Tx_RL|FCC_BD_Tx_RC|FCC_BD_Tx_UN|FCC_BD_Tx_CSL)

#define MTU	1500
//
// Info kept about interface
//
struct emaclite_info { 
	/* These fields should be defined by the implementation */
	int			int_vector;
	char		*esa_key;	/* RedBoot 'key' for device ESA */
	unsigned char	enaddr[6];
	unsigned char	*rxbuf;		/* Rx buffer space */
	unsigned char	*txbuf;		/* Tx buffer space */
	/* The rest of the structure is set up at runtime */
	XEmacLite		dev;
	unsigned short	rxlength;	/* Rx buffer length */
	unsigned short	txlength;	/* Tx buffer length */
#ifdef CYGPKG_NET
	cyg_interrupt	emaclite_interrupt;
	cyg_handle_t	emaclite_interrupt_handle;
#endif
	int	sended;
};
