#!/usr/bin/env python
#
# \file mkbfl.py
#
# Generates a bus functional language (.bfl) file
#
# Generates a bus functional language (.bfl) file for
# bus functional simulation of a osif and hw_thread.
#
# The generated stimulus simulates write and read requests initiated by
# a software delegate thread running on the system's CPU.
#
# This script uses a input file (first argument). Each line corresponds to 
# either a stimulus sequence or a wait statement. A line has the following 
# format:
#
# <type> <param1> <param2> ... <paramN>
#
# where type can be one of:
# 
# write_init_data <data>		writes initialization data to the thread data register
#                        of the OS interface
#
# write_unlock [<retval>]				writes an unlock sequence (ends a
#					            blocking OS call. Returns <retval> to the thread, if present
#
# read_shm_wait <shm_id>		reads a shm_wait or shm_post request
# read_shm_post <shm_id>		from the slot; expects <shm_id>
#
# read_mutex_lock <mutex_id>    reads a mutex_lock/unlock/trylock/release
# read_mutex_unlock <mutex_id>  request from the slot; expects <mutex_id>
# read_mutex_trylock <mutex_id>
# read_mutex_release <mutex_id>
#
# read_cond_wait <condvar_id>        reads a condition variable wait/signal/
# read_cond_signal <condvar_id>      broadcast request from the slot; expects
# read_cond_broadcast <condvar_id>      <condvar_id>
#
# read_mbox_get <mbox_handle> 		reads a mailbox (try)get request from the slot;
# read_mbox_tryget <mbox_handle>	expects <mbox_handle>
#
# read_mbox_put <mbox_handle> <val>		reads a mailbox (try)put request from the slot;
# read_mbox_tryput <mbox_handle> <val>	expects <mbox_handle> and <val>
#
# write_fifo_read_handle <handle>       set mbox handle for read (left) FIFO
# write_fifo_write_handle <handle>      set mbox handle for write (right) FIFO
#
# write_busmacro <val>			enable/disable bus macros (write "00000000" for disable, anything else for enable)
#
#
# wait <cycles>				waits <cycles> cycles (THIS IS BUGGY)
#
# wait_bfm <LEVEL>			waits on a BFM sync on line <LEVEL>
#
# send_bfm <LEVEL>			sends a BFM sync on line <LEVEL>
#
# reset                     sends a thread reset command (resets the thread)
#                           note: you need to unblock the thread afterwards!
#
# write_busmacro <value>    set busmacro enable output. 00000000 disables, 00000001 enables.
#
# TODO: read_burst, write_burst, read_shm, write_shm
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       04.10.2007
#
#---------------------------------------------------------------------------
# %%%RECONOS_COPYRIGHT_BEGIN%%%
# 
# This file is part of ReconOS (http://www.reconos.de).
# Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
# All rights reserved.
# 
# ReconOS is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
# 
# ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License along
# with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
# 
# %%%RECONOS_COPYRIGHT_END%%%
#---------------------------------------------------------------------------
#

import sys
import os
import datetime
import re

defaultDelay = 30	# default delay between commands

def exitUsage():
	sys.stderr.write("Usage: %s input_file\n" % sys.argv[0])
	sys.exit(1)

if __name__ == "__main__":
	if len(sys.argv) != 2: exitUsage()
	
	inputFileName = sys.argv[1]

	bfmHeader = """
------------------------------------------------------------------------------
-- Description:       Sample BFL command script to test hardware task
-- Date:              %s
-- Created by:        %s %s
------------------------------------------------------------------------------


--
-- Define Alias
--

-- Byte Enable Alias
set_alias(IGNOR = 00000000)
set_alias(BYTE0 = 10000000)
set_alias(BYTE1 = 01000000)
set_alias(BYTE2 = 00100000)
set_alias(BYTE3 = 00010000)
set_alias(BYTE4 = 00001000)
set_alias(BYTE5 = 00000100)
set_alias(BYTE6 = 00000010)
set_alias(BYTE7 = 00000001)
set_alias(BYTE8 = 10000000)
set_alias(BYTE9 = 01000000)
set_alias(BYTEA = 00100000)
set_alias(BYTEB = 00010000)
set_alias(BYTEC = 00001000)
set_alias(BYTED = 00000100)
set_alias(BYTEE = 00000010)
set_alias(BYTEF = 00000001)
set_alias(HWRD0 = 11000000)
set_alias(HWRD2 = 00110000)
set_alias(HWRD4 = 00001100)
set_alias(HWRD6 = 00000011)
set_alias(HWRD8 = 11000000)
set_alias(HWRDA = 00110000)
set_alias(HWRDC = 00001100)
set_alias(HWRDE = 00000011)
set_alias(WORD0 = 11110000)
set_alias(WORD4 = 00001111)
set_alias(WORD8 = 11110000)
set_alias(WORDC = 00001111)
set_alias(DWORD = 11111111)

-- PLB BE aliases (fixed length burst)
set_alias(IBURST   = 00000000)
set_alias(FBURST2  = 00010000)
set_alias(FBURST3  = 00100000)
set_alias(FBURST4  = 00110000)
set_alias(FBURST5  = 01000000)
set_alias(FBURST6  = 01010000)
set_alias(FBURST7  = 01100000)
set_alias(FBURST8  = 01110000)
set_alias(FBURST9  = 10000000)
set_alias(FBURST10 = 10010000)
set_alias(FBURST11 = 10100000)
set_alias(FBURST12 = 10110000)
set_alias(FBURST13 = 11000000)
set_alias(FBURST14 = 11010000)
set_alias(FBURST15 = 11100000)
set_alias(FBURST16 = 11110000)

-- PLB Size Alias
set_alias(SINGLE_NORMAL  = 0000)
set_alias(CACHELN_4WRD   = 0001)
set_alias(CACHELN_8WRD   = 0010)
set_alias(CACHELN_16WRD  = 0011)
set_alias(BYTE_BURST     = 1000)
set_alias(HLFWORD_BURST  = 1001)
set_alias(WORD_BURST     = 1010)
set_alias(DBLWORD_BURST  = 1011)
set_alias(QUADWORD_BURST = 1100)
set_alias(OCTWORD_BURST  = 1101)

-- UUT Address Space Alias
set_alias(USER_SLAVE_BASEADDR       = 30000000)
set_alias(USER_MASTER_BASEADDR      = 30000100)

-- Memory Address Space Alias
set_alias(MEM0_BASEADDR = 10000000)
set_alias(MEM1_BASEADDR = 20000000)

-- UUT User Slave Register(s)
set_alias(SLAVE_REG0 = 30000000)
set_alias(SLAVE_REG0_BE = WORD0)
set_alias(SLAVE_REG1 = 30000004)
set_alias(SLAVE_REG1_BE = WORD4)
set_alias(SLAVE_REG2 = 30000008)
set_alias(SLAVE_REG2_BE = WORD8)

set_alias(SLAVE_DREG0 = 30000100)
set_alias(SLAVE_DREG0_BE = WORD0)
set_alias(SLAVE_DREG1 = 30000104)
set_alias(SLAVE_DREG1_BE = WORD4)

set_alias(SLAVE_BURST = 30001000)

-- UUT User Master Register(s)
set_alias(MASTER_CONTROL_REG = 30000100)
set_alias(MASTER_CONTROL_REG_BE = BYTE0)
set_alias(MASTER_STATUS_REG = 30000101)
set_alias(MASTER_STATUS_REG_BE = BYTE1)
set_alias(MASTER_IP2IP_ADDR_REG = 30000104)
set_alias(MASTER_IP2IP_ADDR_REG_BE = WORD4)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE0 = 30000104)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE0_BE = BYTE4)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE1 = 30000105)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE1_BE = BYTE5)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE2 = 30000106)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE2_BE = BYTE6)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE3 = 30000107)
set_alias(MASTER_IP2IP_ADDR_REG_BYTE3_BE = BYTE7)
set_alias(MASTER_IP2BUS_ADDR_REG = 30000108)
set_alias(MASTER_IP2BUS_ADDR_REG_BE = WORD8)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE0 = 30000108)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE0_BE = BYTE8)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE1 = 30000109)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE1_BE = BYTE9)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE2 = 3000010A)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE2_BE = BYTEA)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE3 = 3000010B)
set_alias(MASTER_IP2BUS_ADDR_REG_BYTE3_BE = BYTEB)
set_alias(MASTER_LENGTH_REG = 3000010C)
set_alias(MASTER_LENGTH_REG_BE = HWRDC)
set_alias(MASTER_LENGTH_REG_BYTE0 = 3000010C)
set_alias(MASTER_LENGTH_REG_BYTE0_BE = BYTEC)
set_alias(MASTER_LENGTH_REG_BYTE1 = 3000010D)
set_alias(MASTER_LENGTH_REG_BYTE1_BE = BYTED)
set_alias(MASTER_BE_REG = 3000010E)
set_alias(MASTER_BE_REG_BE = BYTEE)
set_alias(MASTER_GO_PORT = 3000010F)
set_alias(MASTER_GO_PORT_BE = BYTEF)

--
-- Data Alias
--

-- Common Data
set_alias(ALL_CLEARED         = 00000000)

-- Data for IP Master
set_alias(MASTER_STAT_DONE    = 00800000)       -- user logic master operation done
set_alias(MASTER_STAT_BUSY    = 00400000)       -- user logic master is busy
set_alias(MASTER_STAT_CLEAR   = 00000000)       -- user logic master status is clear
set_alias(MASTER_CNTL_RDBRST  = 90000000)       -- burst read without bus lock
set_alias(MASTER_CNTL_WRBRST  = 50000000)       -- burst write without bus lock
set_alias(MASTER_CNTL_RDSNGL  = 80000000)       -- single read without bus lock
set_alias(MASTER_CNTL_WRSNGL  = 40000000)       -- single write without bus lock
set_alias(MASTER_LEN_128      = 0080FF0A)       -- transfer 128 bytes
set_alias(MASTER_LEN_0        = 0000FF0A)       -- transfer 0 bytes

--
-- BFL/VHDL communication alias
--

set_alias(NOP        = 0)
set_alias(START      = 1)
set_alias(STOP       = 2)
set_alias(WAIT_IN    = 3)
set_alias(WAIT_OUT   = 4)
set_alias(ASSERT_IN  = 5)
set_alias(ASSERT_OUT = 6)
set_alias(ASSIGN_IN  = 7)
set_alias(ASSIGN_OUT = 8)
set_alias(RESET_WDT  = 9)
set_alias(INTERRUPT  = 31)

--
-- Initialize the PLB Slave as slave memory ...
--
-- Note:
--
-- 	The instance name for bfm_memory is duplicated in the path due to the
-- 	wrapper level inserted by SimGen to support mixed language simulation.
--

set_device(path = /bfm_system/bfm_memory/bfm_memory/slave, device_type = plb_slave)
configure(ssize = 01)

-- initialize the source data memory (first 16 locations) ...
mem_init(addr = 10000000, data = 00010203)
mem_init(addr = 10000004, data = 04050607)
--mem_init(addr = 10000000, data = 20000000)
--mem_init(addr = 10000004, data = 10000000)
mem_init(addr = 10000008, data = 08090A0B)
mem_init(addr = 1000000C, data = 0C0D0E0F)
mem_init(addr = 10000010, data = 10111213)
mem_init(addr = 10000014, data = 14151617)
mem_init(addr = 10000018, data = 18191A1B)
mem_init(addr = 1000001C, data = 1C1D1E1F)
mem_init(addr = 10000020, data = 20212223)
mem_init(addr = 10000024, data = 24252627)
mem_init(addr = 10000028, data = 28292A2B)
mem_init(addr = 1000002C, data = 2C2D2E2F)
mem_init(addr = 10000030, data = 30313233)
mem_init(addr = 10000034, data = 34353637)
mem_init(addr = 10000038, data = 38393A3B)
mem_init(addr = 1000003C, data = 3C3D3E3F)
mem_init(addr = 10000040, data = 40414243)
mem_init(addr = 10000044, data = 44454647)
mem_init(addr = 10000048, data = 48494A4B)
mem_init(addr = 1000004C, data = 4C4D4E4F)
mem_init(addr = 10000050, data = 50515253)
mem_init(addr = 10000054, data = 54555657)
mem_init(addr = 10000058, data = 58595A5B)
mem_init(addr = 1000005C, data = 5C5D5E5F)
mem_init(addr = 10000060, data = 60616263)
mem_init(addr = 10000064, data = 64656667)
mem_init(addr = 10000068, data = 68696A6B)
mem_init(addr = 1000006C, data = 6C6D6E6F)
mem_init(addr = 10000070, data = 70717273)
mem_init(addr = 10000074, data = 74757677)
mem_init(addr = 10000078, data = 78797A7B)
mem_init(addr = 1000007C, data = 7C7D7E7F)
mem_init(addr = 10000080, data = 80818283)
mem_init(addr = 10000084, data = 84858687)
mem_init(addr = 10000088, data = 88898A8B)
mem_init(addr = 1000008C, data = 8C8D8E8F)

-- initialize the destination data memory (first 16 locations) ...
mem_init(addr = 20000000, data = DEADBEEF)
mem_init(addr = 20000004, data = DEADBEEF)
mem_init(addr = 20000008, data = DEADBEEF)
mem_init(addr = 2000000C, data = DEADBEEF)
mem_init(addr = 20000010, data = DEADBEEF)
mem_init(addr = 20000014, data = DEADBEEF)
mem_init(addr = 20000018, data = DEADBEEF)
mem_init(addr = 2000001C, data = DEADBEEF)
mem_init(addr = 20000020, data = DEADBEEF)
mem_init(addr = 20000024, data = DEADBEEF)
mem_init(addr = 20000028, data = DEADBEEF)
mem_init(addr = 2000002C, data = DEADBEEF)
mem_init(addr = 20000030, data = DEADBEEF)
mem_init(addr = 20000034, data = DEADBEEF)
mem_init(addr = 20000038, data = DEADBEEF)
mem_init(addr = 2000003C, data = DEADBEEF)
mem_init(addr = 20000040, data = DEADBEEF)
mem_init(addr = 20000044, data = DEADBEEF)
mem_init(addr = 20000048, data = DEADBEEF)
mem_init(addr = 2000004C, data = DEADBEEF)
mem_init(addr = 20000050, data = DEADBEEF)
mem_init(addr = 20000054, data = DEADBEEF)
mem_init(addr = 20000058, data = DEADBEEF)
mem_init(addr = 2000005C, data = DEADBEEF)
mem_init(addr = 20000060, data = DEADBEEF)
mem_init(addr = 20000064, data = DEADBEEF)
mem_init(addr = 20000068, data = DEADBEEF)
mem_init(addr = 2000006C, data = DEADBEEF)
mem_init(addr = 20000070, data = DEADBEEF)
mem_init(addr = 20000074, data = DEADBEEF)
mem_init(addr = 20000078, data = DEADBEEF)
mem_init(addr = 2000007C, data = DEADBEEF)


--
-- Initialize the PLB Master as master processor ...
--
-- Note:
--
-- 	The instance name for bfm_processor is duplicated in the path due to the
-- 	wrapper level inserted by SimGen to support mixed language simulation.
--

set_device(path = /bfm_system/bfm_processor/bfm_processor/master, device_type = plb_master)
configure(msize = 01)

-------------------------------------------------------------------------------
-- Start Testing ...
-------------------------------------------------------------------------------

wait(level = START)""" % (datetime.datetime.today().isoformat(" "), sys.argv[0], inputFileName)

	# match expressions
	expWrInitData = re.compile("write_init_data\s+(\w{8})", re.I)
	expWrUnlock = re.compile("write_unlock", re.I)
	expWrUnlockRetval = re.compile("write_unlock\s+(\w{8})", re.I)
	expRdSemPost = re.compile("read_sem_post\s+(\w{8})", re.I)
	expRdSemWait = re.compile("read_sem_wait\s+(\w{8})", re.I)
	expRdMutexLock = re.compile("read_mutex_lock\s+(\w{8})", re.I)
	expRdMutexUnlock = re.compile("read_mutex_unlock\s+(\w{8})", re.I)
	expRdMutexTrylock = re.compile("read_mutex_trylock\s+(\w{8})", re.I)
	expRdMutexRelease = re.compile("read_mutex_release\s+(\w{8})", re.I)
	expWait = re.compile("wait\s+(\d+)", re.I)
	expWaitBfm = re.compile("wait_bfm\s+(\w+)", re.I)
	expSendBfm = re.compile("send_bfm\s+(\w+)", re.I)
	expReset = re.compile("reset", re.I)
	expWrBusmacro = re.compile("write_busmacro\s+(\w{8})", re.I)
	expRdCondWait = re.compile("read_cond_wait\s+(\w{8})", re.I)
	expRdCondSignal = re.compile("read_cond_signal\s+(\w{8})", re.I)
	expRdCondBroadcast = re.compile("read_cond_broadcast\s+(\w{8})", re.I)
	expRdMboxGet = re.compile("read_mbox_get\s+(\w{8})", re.I)
	expRdMboxTryget = re.compile("read_mbox_tryget\s+(\w{8})", re.I)
	expRdMboxPut = re.compile("read_mbox_put\s+(\w{8})\s+(\w{8})", re.I)
	expRdMboxTryput = re.compile("read_mbox_tryput\s+(\w{8})\s+(\w{8})", re.I)
	expWrFifoReadHandle = re.compile("write_fifo_read_handle\s+(\w{8})", re.I)
	expWrFifoWriteHandle = re.compile("write_fifo_write_handle\s+(\w{8})", re.I)

	nextDelay = defaultDelay

	inputFile = open(inputFileName, "r")
	print bfmHeader
	for line in inputFile.readlines():

		m = expWrInitData.match(line)
		if m:
			print """
-- write init data %s
mem_update(addr = SLAVE_REG0, data = 01000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = FFFFFFFF)
write(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
write(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
write(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay
		
		m = expWrUnlock.match(line)
		m2 = expWrUnlockRetval.match(line)
		if m2:
			print """
-- write unlock with return value %s
mem_update(addr = SLAVE_REG0, data = 00000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = FFFFFFFF)
write(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
write(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
write(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m2.group(1),m2.group(1),nextDelay)
			nextDelay = defaultDelay
		elif m:
			print """
-- write unlock
mem_update(addr = SLAVE_REG0, data = 00000000)
mem_update(addr = SLAVE_REG1, data = 00000000)
mem_update(addr = SLAVE_REG2, data = FFFFFFFF)
write(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
write(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
write(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % nextDelay
			nextDelay = defaultDelay
        
		m = expRdSemPost.match(line)
		if m:
			print """
-- read semaphore %s post
mem_update(addr = SLAVE_REG0, data = 00000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay
		
		m = expRdSemWait.match(line)
		if m:
			print """
-- read semaphore %s wait
mem_update(addr = SLAVE_REG0, data = 81000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expRdMutexLock.match(line)
		if m:
			print """
-- read mutex %s lock
mem_update(addr = SLAVE_REG0, data = 82000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expRdMutexUnlock.match(line)
		if m:
			print """
-- read mutex %s unlock
mem_update(addr = SLAVE_REG0, data = 02000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expRdMutexTrylock.match(line)
		if m:
			print """
-- read mutex %s trylock
mem_update(addr = SLAVE_REG0, data = 83000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expRdMutexRelease.match(line)
		if m:
			print """
-- read mutex %s release
mem_update(addr = SLAVE_REG0, data = 04000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expWait.match(line)
		if m:
			nextDelay = m.group(1)
			
		m = expWaitBfm.match(line)
		if m:
			print """
--- wait for BFM sync pulse on level %s
wait(level = %s)""" % (m.group(1), m.group(1))

		m = expSendBfm.match(line)
		if m:
			print """
--- send BFM sync pulse on level %s
send(level = %s)""" % (m.group(1), m.group(1))

		m = expReset.match(line)
		if m:
			print """
-- write thread reset request
mem_update(addr = SLAVE_REG0, data = 02000000)
mem_update(addr = SLAVE_REG1, data = 00000000)
mem_update(addr = SLAVE_REG2, data = FFFFFFFF)
write(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
write(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
write(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % nextDelay
			nextDelay = defaultDelay

		m = expWrBusmacro.match(line)
		if m:
			print """
-- write busmacro enable/disable (%s)
mem_update(addr = SLAVE_REG0, data = 03000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = FFFFFFFF)
write(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
write(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
write(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expRdCondWait.match(line)
		if m:
			print """
-- read condvar %s wait
mem_update(addr = SLAVE_REG0, data = 84000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expRdCondSignal.match(line)
		if m:
			print """
-- read condvar %s signal
mem_update(addr = SLAVE_REG0, data = 04000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay

		m = expRdCondBroadcast.match(line)
		if m:
			print """
-- read condvar %s broadcast
mem_update(addr = SLAVE_REG0, data = 05000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay
		
		m = expRdMboxGet.match(line)
		if m:
			print """
-- read mbox %s get 
mem_update(addr = SLAVE_REG0, data = 85000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay
		
		m = expRdMboxTryget.match(line)
		if m:
			print """
-- read mbox %s tryget
mem_update(addr = SLAVE_REG0, data = 86000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = 00000000)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay
		
		m = expRdMboxPut.match(line)
		if m:
			print """
-- read mbox %s put %s
mem_update(addr = SLAVE_REG0, data = 87000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = %s)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(2),m.group(1),m.group(2),nextDelay)
			nextDelay = defaultDelay
		
		m = expRdMboxTryput.match(line)
		if m:
			print """
-- read mbox %s tryput %s
mem_update(addr = SLAVE_REG0, data = 88000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = %s)
read(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
read(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
read(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(2),m.group(1),m.group(2),nextDelay)
			nextDelay = defaultDelay

		m = expWrFifoReadHandle.match(line)
		if m:
			print """
-- set fifo read handle %s
mem_update(addr = SLAVE_REG0, data = 04000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = FFFFFFFF)
write(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
write(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
write(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay
		
		m = expWrFifoWriteHandle.match(line)
		if m:
			print """
-- set fifo write handle %s
mem_update(addr = SLAVE_REG0, data = 05000000)
mem_update(addr = SLAVE_REG1, data = %s)
mem_update(addr = SLAVE_REG2, data = FFFFFFFF)
write(addr = SLAVE_REG0, size = SINGLE_NORMAL, be = SLAVE_REG0_BE, req_delay = %s)
write(addr = SLAVE_REG1, size = SINGLE_NORMAL, be = SLAVE_REG1_BE)
write(addr = SLAVE_REG2, size = SINGLE_NORMAL, be = SLAVE_REG2_BE)""" % (m.group(1),m.group(1),nextDelay)
			nextDelay = defaultDelay
		
		
			
	print """
send(level = STOP)

-------------------------------------------------------------------------------
-- End of Testing ...
-------------------------------------------------------------------------------"""
