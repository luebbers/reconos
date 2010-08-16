///
/// \file kapi_cpuhwt.c
///
/// \author     Robert Meiche
/// \date       27.8.2009
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


#include "kapi_cpuhwt.h"

void waitOnNewCommandSignal()
{
	volatile Xuint8 newcommand=0;

	while(newcommand != 1)
	{
		newcommand = READ(NEWCOMMANDREG);
	}
}

Xuint32 getInitData()
{

	WRITE(COMMANDREG, RECONOS_GET_INIT_DATA);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
	//Return initdata
	return READ(RETURNDATAREG);
}

void cyg_mutex_release(Xuint32 *mutex)
{
	WRITE(COMMANDREG, RECONOS_MUTEX_RELEASE);
	WRITE(ADDRREG, *mutex);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

int cyg_mutex_trylock(Xuint32* mutex)
{
	WRITE(COMMANDREG, RECONOS_MUTEX_TRYLOCK);
	WRITE(ADDRREG, *mutex);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);

	return 1;
}

int cyg_mutex_lock(Xuint32* mutex)
{
	WRITE(COMMANDREG, RECONOS_MUTEX_LOCK);
	WRITE(ADDRREG, *mutex);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
	/*
	 *TODO: Error handling
	 */
	return 1;
}

void cyg_mutex_unlock(Xuint32* mutex)
{
	WRITE(COMMANDREG, RECONOS_MUTEX_UNLOCK);
	WRITE(ADDRREG, *mutex);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

void cyg_semaphore_post(Xuint32* sem)
{
	WRITE(COMMANDREG, RECONOS_SEM_POST);
	WRITE(ADDRREG, *sem);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

int cyg_semaphore_wait(Xuint32* sem)
{
	WRITE(COMMANDREG, RECONOS_SEM_WAIT);
	WRITE(ADDRREG, *sem);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);

	return 1;
}

void cyg_cond_signal(Xuint32* cond)
{
	WRITE(COMMANDREG, RECONOS_COND_SIGNAL);
	WRITE(ADDRREG, *cond);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

void cyg_cond_broadcast(Xuint32* cond)
{
	WRITE(COMMANDREG, RECONOS_COND_BROADCAST);
	WRITE(ADDRREG, *cond);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

int cyg_cond_wait(Xuint32* cond)
{
	WRITE(COMMANDREG, RECONOS_COND_WAIT);
	WRITE(ADDRREG, *cond);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);

	return 1;
}

void* cyg_mbox_get(Xuint32 handle)
{
	WRITE(COMMANDREG, RECONOS_MBOX_GET);
	WRITE(ADDRREG, handle);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);

	return (void *)(READ(RETURNDATAREG));
}

int cyg_mbox_put(Xuint32 handle, void* data)
{
	WRITE(COMMANDREG, RECONOS_MBOX_PUT);
	WRITE(ADDRREG, handle);
	WRITE(DATAREG, data);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);

	return 1;
}

void* cyg_mbox_tryget(Xuint32 handle)
{
	WRITE(COMMANDREG, RECONOS_MBOX_TRYGET);
	WRITE(ADDRREG, handle);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);

	return (void *)(READ(RETURNDATAREG));
}

int cyg_mbox_tryput(Xuint32 handle, Xuint32 data)
{
	WRITE(COMMANDREG, RECONOS_MBOX_TRYPUT);
	WRITE(ADDRREG, handle);
	WRITE(DATAREG, data);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);

	return 1;
}

void cyg_thread_resume(Xuint32 thread)
{
	WRITE(COMMANDREG, RECONOS_THREAD_RESUME);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

void cyg_thread_exit()
{
	WRITE(COMMANDREG, RECONOS_THREAD_EXIT);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

void cyg_thread_delay(Xuint32 delay)
{
	WRITE(COMMANDREG, RECONOS_THREAD_DELAY);
	WRITE(DATAREG, delay);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}

void cyg_thread_yield()
{
	WRITE(COMMANDREG, RECONOS_THREAD_YIELD);
	WRITE(DONEREG, 0x1);
	//wait until osif_adapter set newcommand.
	WAIT;
	//now set donereg to 0
	WRITE(DONEREG, 0x0);
}



