///
/// \file kapi_cpuhwt.h
///
/// \author     Robert Meiche
/// \date       27.8.2007
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


#ifndef RECONOS_CPU_HWT_LIB_H		/* prevent circular inclusions */
#define RECONOS_CPU_HWT_LIB_H		/* by using protection macros */

#ifdef __cplusplus
extern "C" {
#endif

#include "xparameters.h"
#include "xio_dcr.h"

#ifdef CPU_HWT_LIB_PPC405
#define DCR_BASEADDR 0x18  //This is hardcoded in CPU_HWT->CPU_OSIF_ADAPTER PCORE

//Commands
#define WRITE(Reg, Val) XIo_DcrOut(Reg, Val)
#define READ(Reg)  XIo_DcrIn(Reg)
#define WAIT  waitOnNewCommandSignal()
#define INIT  WRITE(COMMANDREG, 0x6)
//Registers CPU -> osif_adapter
#define COMMANDREG  DCR_BASEADDR
#define DATAREG  DCR_BASEADDR+0x01
#define ADDRREG  DCR_BASEADDR+0x03
#define DONEREG  DCR_BASEADDR+0x02

//Registers osif_adapter -> CPU
#define NEWCOMMANDREG  DCR_BASEADDR+0x03
#define RETURNDATAREG  DCR_BASEADDR+0x01
#define DEBUGREG	   DCR_BASEADDR

#else
 #error "Hier stimmt was nicht!"
#endif /*end of definitions for PPC405 */

//ReconOS COMMANDS
#define RECONOS_GET_INIT_DATA  0x1
#define RECONOS_MUTEX_RELEASE  0x2
#define RECONOS_MUTEX_TRYLOCK  0x3
#define RECONOS_MUTEX_LOCK     0x4
#define RECONOS_MUTEX_UNLOCK   0x5
// 6,7 are reserved for sw_reset and init
#define RECONOS_SEM_POST       0x8
#define RECONOS_SEM_WAIT       0x9
#define RECONOS_COND_SIGNAL    0xA
#define RECONOS_COND_BROADCAST 0xB
#define RECONOS_COND_WAIT      0xC
#define RECONOS_MBOX_GET	   0xD
#define RECONOS_MBOX_PUT	   0xE
#define RECONOS_MBOX_TRYGET    0xF
#define RECONOS_MBOX_TRYPUT    0x10
#define RECONOS_THREAD_RESUME  0x11
#define RECONOS_THREAD_EXIT    0x12
#define RECONOS_THREAD_DELAY   0x13
#define RECONOS_THREAD_YIELD   0x14


//Function prototypes
void waitOnNewCommandSignal();
Xuint32 getInitData();
int cyg_mutex_lock(Xuint32* mutex);
void cyg_mutex_unlock(Xuint32* mutex);
void cyg_mutex_release(Xuint32* mutex);
int cyg_mutex_trylock(Xuint32* mutex);
void cyg_semaphore_post(Xuint32* sem);
int cyg_semaphore_wait(Xuint32* sem);
void cyg_cond_signal(Xuint32* cond);
void cyg_cond_broadcast(Xuint32* cond);
int cyg_cond_wait(Xuint32* cond);
void* cyg_mbox_get(Xuint32 handle);
int cyg_mbox_put(Xuint32 handle, void* data);
void* cyg_mbox_tryget(Xuint32 handle);
int cyg_mbox_tryput(Xuint32 handle, Xuint32 data);
void cyg_thread_exit();
void cyg_thread_resume(Xuint32 thread);
void cyg_thread_delay(Xuint32 delay);
void cyg_thread_yield();

#ifdef __cplusplus
}
#endif

#endif /* end of protection macro */
