///
/// \file osif_comm.h
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
#ifndef __OSIF_COMM_H__
#define __OSIF_COMM_H__

#include <reconos/reconos.h>

void osif_write_result(reconos_slot_t *s, uint32 retval);
void osif_unblock(reconos_slot_t *s);
void osif_set_fifo_handles(reconos_slot_t *s, uint32 fifo_read_index, uint32 fifo_write_index);
void osif_reset(reconos_slot_t *s);
void osif_set_init_data(reconos_slot_t *s, uint32 data);
void osif_set_busmacro(reconos_slot_t *s, int value);
void osif_request_yield(reconos_slot_t *s);
void osif_clear_yield(reconos_slot_t *s);
void osif_set_resume(reconos_slot_t *s, osif_task2os_command_t resume_command);
void osif_read_call_parameters( reconos_slot_t *s, osif_task2os_t *request );
void osif_read_hwthread_signature( reconos_slot_t *s, uint32 *signature );

#endif // __OSIF_COMM_H__
