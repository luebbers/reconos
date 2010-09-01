///
/// \file osif_comm.c
///
/// Helper routines for OSIF communication (e.g. across DCR)
///
/// \author     Enno Luebbers   <enno.luebbers@upb.de>
/// \date       12.03.2009
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
// Major Changes:
//
// 12.03.2009   Enno Luebbers   File created.

#include <reconos/reconos.h>
#include <reconos/osif_comm.h>
#include <cyg/infra/diag.h>

// header files for low-level communication
// FIXME: might be moved to HAL?
// PowerPC uses DCR bus
#ifdef CYGPKG_HAL_POWERPC_VIRTEX4
#include <xio_dcr.h>
// microblaze uses mmio'd bridge to DCR
#elif CYGPKG_HAL_MICROBLAZE
#include <xil_io.h>
#endif

// MACROS ===================================================================

// debugging output
#ifdef UPBDBG_RECONOS_DEBUG
#define DEBUG_PRINTF(format, args...) diag_printf(format , ##args)
#else
#define DEBUG_PRINTF(format, args...)
#endif

// Macros for OSIF bus communications
#ifdef CYGPKG_HAL_POWERPC_VIRTEX4
#define OSIF_READ(s, reg)            XIo_DcrIn(s->dcr_base_addr + reg)
#define OSIF_WRITE(s, reg, value)    XIo_DcrOut(s->dcr_base_addr + reg, value)
// Microblaze does not have a DCR, so we go across the memory bus
// The DCR addresses are already converted to memory bus addresses by XPS
#elif CYGPKG_HAL_MICROBLAZE
#define OSIF_READ(s, reg)            Xil_In32(s->dcr_base_addr + (reg*4))
#define OSIF_WRITE(s, reg, value)    Xil_Out32(s->dcr_base_addr + (reg*4), value)
#endif
#define OSIF_REG_COMMAND       0
#define OSIF_REG_DATA          1
#define OSIF_REG_DONE          2
#define OSIF_REG_DATAX         2
#define OSIF_REG_SIGNATURE     3



// FUNCTIONS ================================================================

//-----------------------------------------
// helper function: write result back to osif and unblock hardware thread
//-----------------------------------------
void osif_write_result(reconos_slot_t *s, uint32 retval)
{

	DEBUG_PRINTF("slot %d: unblocking and writing result 0x%08X\n", s->num, retval);

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_UNBLOCK);
	OSIF_WRITE(s, OSIF_REG_DATA, retval);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);	
}

//-----------------------------------------
// helper function: unblock hardware thread
//-----------------------------------------
void osif_unblock(reconos_slot_t *s) {

	DEBUG_PRINTF("slot %d: unblocking\n", s->num);

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_UNBLOCK);
	OSIF_WRITE(s, OSIF_REG_DATA, (uint32)0);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);	
}

//-----------------------------------------
// helper function: set local FIFO handles
//-----------------------------------------
void osif_set_fifo_handles(reconos_slot_t *s, uint32 fifo_read_index, uint32 fifo_write_index)
{

	DEBUG_PRINTF("slot %d: setting FIFO handles: read: 0x%08X, write: 0x%08X\n", s->num, fifo_read_index, fifo_write_index);

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_SET_FIFO_READ_HANDLE);
	OSIF_WRITE(s, OSIF_REG_DATA, fifo_read_index);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_SET_FIFO_WRITE_HANDLE);
	OSIF_WRITE(s, OSIF_REG_DATA, fifo_write_index);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
}

//-----------------------------------------
// helper function: reset osif
//-----------------------------------------
void osif_reset(reconos_slot_t *s)
{

	DEBUG_PRINTF("slot %d: resetting\n", s->num);

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_RESET);
	OSIF_WRITE(s, OSIF_REG_DATA, (uint32)0);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
}
	
//-----------------------------------------
// helper function: set init data
//-----------------------------------------
void osif_set_init_data(reconos_slot_t *s, uint32 data)
{

	DEBUG_PRINTF("slot %d: initializing with data 0x%08X\n", s->num, data);

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_SET_INIT_DATA);
	OSIF_WRITE(s, OSIF_REG_DATA, data);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
}

//-----------------------------------------
// helper function: en/diable bus macros osif
//-----------------------------------------
void osif_set_busmacro(reconos_slot_t *s, int value)
{

	DEBUG_PRINTF("slot %d: ", s->num);
    DEBUG_PRINTF(value ? "enabling bus macros\n" : "disabling bus macros\n");

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_BUSMACRO);
	OSIF_WRITE(s, OSIF_REG_DATA, value ? OSIF_DATA_BUSMACRO_ENABLE :
                                             OSIF_DATA_BUSMACRO_DISABLE);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
}

//-----------------------------------------
// helper function: request_yield
//-----------------------------------------
void osif_request_yield(reconos_slot_t *s)
{

	DEBUG_PRINTF("slot %d: requesting yield\n", s->num);

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_REQUEST_YIELD);
	OSIF_WRITE(s, OSIF_REG_DATA, (uint32)0);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
}


//-----------------------------------------
// helper function: clear_yield
//-----------------------------------------
void osif_clear_yield(reconos_slot_t *s)
{

    DEBUG_PRINTF("slot %d: clearing yield request\n", s->num);

	OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_CLEAR_YIELD);
	OSIF_WRITE(s, OSIF_REG_DATA, (uint32)0);
	OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
}


//-----------------------------------------
// helper function: set resume state and step
//-----------------------------------------
void osif_set_resume(reconos_slot_t *s, osif_task2os_command_t saved_command)
{

    DEBUG_PRINTF("slot %d: setting resume state 0x%02X step %d (data = 0x%08X)\n", 
			s->num, saved_command.saved_state_enc, saved_command.saved_step_enc,
			saved_command.saved_state_enc << 24 | saved_command.saved_step_enc << 22);

    // set resume state
    OSIF_WRITE(s, OSIF_REG_COMMAND, OSIF_CMD_SET_RESUME_STATE);
    OSIF_WRITE(s, OSIF_REG_DATA, saved_command.saved_state_enc << 24 | saved_command.saved_step_enc << 22); 
    OSIF_WRITE(s, OSIF_REG_DONE, OSIF_CMDNEW);
}

//-----------------------------------------
// helper function: read call parameters
//-----------------------------------------
void osif_read_call_parameters( reconos_slot_t *s, osif_task2os_t *request ) {
    *((uint32*)(&(request->command))) = OSIF_READ(s, OSIF_REG_COMMAND);
    request->data = OSIF_READ(s, OSIF_REG_DATA);
    request->datax = OSIF_READ(s, OSIF_REG_DATAX);

    DEBUG_PRINTF("**task in slot %d:**\n  cmd: 0x%08X (code: 0x%02X), data: 0x%08X, datax: 0x%08X\n", s->num, *((uint32*)(&(request->command))), request->command.code, request->data, request->datax);

}

//-----------------------------------------
// helper function: read hwthread signature
//-----------------------------------------
void osif_read_hwthread_signature( reconos_slot_t *s, uint32 *signature ) {
    *signature = OSIF_READ(s, OSIF_REG_SIGNATURE);

    DEBUG_PRINTF("slot %d: reading thread signature: 0x%08X\n", s->num, *signature);
}
