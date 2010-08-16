#!/usr/bin/env python
#
# \file mkbfmtb.py
#
# Modify BFM testbench for OSIF/HWThread simulation
#
# Manipulates a BFM testbench based on a .sst file for
# bus functional simulation of a osif and hw_thread
#
# vim:foldmethod=marker
#
# The generated stimulus simulates write and read requests initiated by
# a software delegate thread running on the system's CPU.
#
# There are two arguments. The first is the input .sst file, the second
# is the testbench to manipulate.
#
# This script uses a input file (first argument). Each line corresponds to 
# either a stimulus sequence or a wait statement. A line has the following 
# format:
#
# <type> <param1> <param2> ... <paramN>
#
# where type can be one of:
# 
# write_init_data <data>                writes initialization data to the thread data register
#                        of the OS interface
#
# write_unlock [<retval>]                               writes an unlock sequence (ends a
#                                                   blocking OS call. Returns <retval> to the thread, if present
#
# write_resume <state_enc(hex)> <step_enc(bin)>    writes an encoded resume state 
# request_yield                                    requests a yield
# clear_yield                                      cancels a yield request
#
# read_thread_yield                                read a thread yield request 
#
# read_thread_delay <ticks>                        read a thread_delay request
#
# read_shm_wait <shm_id>                reads a shm_wait or shm_post request
# read_shm_post <shm_id>                from the slot; expects <shm_id>
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
# read_mbox_get <mbox_handle>           reads a mailbox (try)get request from the slot;
# read_mbox_tryget <mbox_handle>        expects <mbox_handle>
#
# read_mbox_put <mbox_handle> <val>             reads a mailbox (try)put request from the slot;
# read_mbox_tryput <mbox_handle> <val>  expects <mbox_handle> and <val>
#
# write_fifo_read_handle <handle>       set mbox handle for read (left) FIFO
# write_fifo_write_handle <handle>      set mbox handle for write (right) FIFO
#
# write_busmacro <val>                  enable/disable bus macros (write "00000000" for disable, anything else for enable)
#
#
# wait <timespec>                       wait for <timespec>, with timespec being something like "30 ns", "1 us" etc.
#
# reset                     sends a thread reset command (resets the thread)
#                           note: you need to unblock the thread afterwards!
#
# write_busmacro <value>    set busmacro enable output. 00000000 disables, 00000001 enables.
#
# \author     Enno Luebbers <luebbers@reconos.de>
# \date       21.04.2008
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

#=== IMPORTS ================================= {{{1
import sys
import os
import datetime
import re
import shutil

#=== FUNCTIONS =============================== {{{1

def exitUsage():
        sys.stderr.write("Usage: %s input_file testbench_file\n" % os.path.basename(sys.argv[0]))
        sys.exit(1)

#---------------------------------------------
# main program                            {{{2
#---------------------------------------------
if __name__ == "__main__":
        if len(sys.argv) != 3: exitUsage()
        
        inputFileName = sys.argv[1]
        testbenchFileName = sys.argv[2]

        if not os.path.exists(inputFileName):
            sys.stderr.write("Can't find input file '%s'.\n" % inputFileName)
            sys.exit(-1)

        if not os.path.exists(testbenchFileName):
            sys.stderr.write("Can't find testbench file '%s'.\n" % testbenchFileName)
            sys.exit(-1)

        # match expressions {{{
        expWrInitData = re.compile("write_init_data\s+(\w{8})", re.I)
        expWrUnlock = re.compile("write_unlock", re.I)
        expWrUnlockRetval = re.compile("write_unlock\s+(\w{8})", re.I)
        expWrResume = re.compile("write_resume\s+(\w{2})\s+([01]{2})", re.I)
        expReqYield = re.compile("request_yield", re.I)
        expClrYield = re.compile("clear_yield", re.I)
        expRdYield = re.compile("read_thread_yield", re.I)
        expRdExit = re.compile("read_thread_exit\s+(\w{8})", re.I)
        expRdDelay = re.compile("read_thread_delay\s+(\w{8})", re.I)
        expRdSemPost = re.compile("read_sem_post\s+(\w{8})", re.I)
        expRdSemWait = re.compile("read_sem_wait\s+(\w{8})", re.I)
        expRdMutexLock = re.compile("read_mutex_lock\s+(\w{8})", re.I)
        expRdMutexUnlock = re.compile("read_mutex_unlock\s+(\w{8})", re.I)
        expRdMutexTrylock = re.compile("read_mutex_trylock\s+(\w{8})", re.I)
        expRdMutexRelease = re.compile("read_mutex_release\s+(\w{8})", re.I)
        expWait = re.compile("wait\s+(\d+ ?[munp]?s)", re.I)
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
        expCommentOrWhitespace = re.compile("^\s*$|\s*#.*$", re.I)
        expRdSignature = re.compile("read_signature\s+(\w{8})", re.I)
        # }}}

        inputFile = open(inputFileName, "r")
        outputLines = []

        lineNum = 0
        for line in inputFile.readlines():
                lineNum = lineNum + 1
                foundMatch = False

#-----------------------------------------------------------------------------------
# write_init_data   {{{
#-----------------------------------------------------------------------------------
                m = expWrInitData.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- write init data %s
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_SET_INIT_DATA & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"%s");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);
""" % (m.group(1),m.group(1)))
# }}}                
#-----------------------------------------------------------------------------------
# write_unlock  {{{
#-----------------------------------------------------------------------------------
                m = expWrUnlock.match(line)
                m2 = expWrUnlockRetval.match(line)
                if m2:
                        foundMatch = True
                        outputLines.append("""
        -- write unlock with return value %s
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_UNBLOCK & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"%s");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);
""" % (m2.group(1),m2.group(1)))
                elif m:
                        foundMatch = True
                        outputLines.append("""
        -- write unlock
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_UNBLOCK & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"00000000");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);""")
# }}}                
#-----------------------------------------------------------------------------------
# write_resume      {{{
#-----------------------------------------------------------------------------------
                m = expWrResume.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- set resume state %s
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_SET_RESUME_STATE & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"%s" & "%s00" & X"00000");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);""" % (m.group(1), m.group(1), m.group(2)))
# }}}                
#-----------------------------------------------------------------------------------
# request_yield     {{{
#-----------------------------------------------------------------------------------
                m = expReqYield.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- request yield
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_REQUEST_YIELD & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"00000000");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);""")
# }}}                
#-----------------------------------------------------------------------------------
# clear_yield       {{{
#-----------------------------------------------------------------------------------
                m = expClrYield.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- clear yield
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_CLEAR_YIELD & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"00000000");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);""")
# }}}                
#-----------------------------------------------------------------------------------
# read_sem_post     {{{
#-----------------------------------------------------------------------------------
                m = expRdSemPost.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read semaphore %s post
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_SEM_POST report "*** ERROR: DCR command read mismatch! Expected OSIF_CMD_SEM_POST (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}                
#-----------------------------------------------------------------------------------
# read_sem_wait     {{{
#-----------------------------------------------------------------------------------
                m = expRdSemWait.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read semaphore %s wait
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_SEM_WAIT report "*** ERROR: DCR command read mismatch! Expected OSIF_CMD_SEM_WAIT (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_mutex_lock       {{{
#-----------------------------------------------------------------------------------
                m = expRdMutexLock.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mutex %s lock
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MUTEX_LOCK report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_MUTEX_LOCK (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_mutex_unlock     {{{
#-----------------------------------------------------------------------------------
                m = expRdMutexUnlock.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mutex %s unlock
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MUTEX_UNLOCK report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_MUTEX_UNLOCK (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_mutex_trylock        {{{
#-----------------------------------------------------------------------------------
                m = expRdMutexTrylock.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mutex %s trylock
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MUTEX_TRYLOCK report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_MUTEX_TRYLOCK (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_mutex_release        {{{
#-----------------------------------------------------------------------------------
                m = expRdMutexRelease.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mutex %s release
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MUTEX_RELEASE report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_MUTEX_RELEASE (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# wait      {{{
#-----------------------------------------------------------------------------------
                m = expWait.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        wait for %s;
""" % m.group(1))
# }}}                   
#-----------------------------------------------------------------------------------
# reset     {{{
#-----------------------------------------------------------------------------------
                m = expReset.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- write thread reset request
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_RESET & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"00000000");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);""")
# }}}
#-----------------------------------------------------------------------------------
# write_busmacro        {{{
#-----------------------------------------------------------------------------------
                m = expWrBusmacro.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- write busmacro enable/disable (%s)
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_BUSMACRO & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"%s");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);
""" % (m.group(1),m.group(1)))
# }}}
#-----------------------------------------------------------------------------------
# read_cond_wait        {{{
#-----------------------------------------------------------------------------------
                m = expRdCondWait.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read condvar %s wait
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_COND_WAIT report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_COND_WAIT (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_cond_signal      {{{
#-----------------------------------------------------------------------------------
                m = expRdCondSignal.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read condvar %s signal
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_COND_SIGNAL report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_COND_SIGNAL (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_cond_broadcast       {{{
#-----------------------------------------------------------------------------------
                m = expRdCondBroadcast.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read condvar %s broadcast
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_COND_BROADCAST report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_COND_BROADCAST (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}                
#-----------------------------------------------------------------------------------
# read_mbox_get     {{{
#-----------------------------------------------------------------------------------
                m = expRdMboxGet.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mbox %s get 
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MBOX_GET report "*** ERROR: DCR command read mismatch! Expected OSIF_CMD_MBOX_GET (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}       
#-----------------------------------------------------------------------------------
# read_mbox_tryget      {{{
#-----------------------------------------------------------------------------------
                m = expRdMboxTryget.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mbox %s tryget
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MBOX_TRYGET report "*** ERROR: DCR command read mismatch! Expected OSIF_CMD_MBOX_TRYGET (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}                 
#-----------------------------------------------------------------------------------
# read_mbox_put     {{{
#-----------------------------------------------------------------------------------
                m = expRdMboxPut.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mbox %s put %s
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MBOX_PUT report "*** ERROR: DCR command read mismatch! Expected OSIF_CMD_MBOX_PUT (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR datax read mismatch (SST line %d)! ***" severity WARNING;
""" % (m.group(1),m.group(2),lineNum,m.group(1),lineNum,m.group(2),lineNum))
# }}}                
#-----------------------------------------------------------------------------------
# read_mbox_tryput      {{{
#-----------------------------------------------------------------------------------
                m = expRdMboxTryput.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read mbox %s tryput %s
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_MBOX_TRYPUT report "*** ERROR: DCR command read mismatch! Expected OSIF_CMD_MBOX_TRYPUT (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR datax read mismatch (SST line %d)! ***" severity WARNING;
""" % (m.group(1),m.group(2),lineNum,m.group(1),lineNum,m.group(2),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# write_fifo_read_handle        {{{
#-----------------------------------------------------------------------------------
                m = expWrFifoReadHandle.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- set fifo read handle %s
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_SET_FIFO_READ_HANDLE & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"%s");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);
""" % (m.group(1),m.group(1)))
# }}}               
#-----------------------------------------------------------------------------------
# write_fifo_write_handle       {{{
#-----------------------------------------------------------------------------------
                m = expWrFifoWriteHandle.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- set fifo write handle %s
        OSIF_WRITE(OSIF_REG_COMMAND, OSIF_CMD_SET_FIFO_WRITE_HANDLE & X"000000");
        OSIF_WRITE(OSIF_REG_DATA,    X"%s");
        OSIF_WRITE(OSIF_REG_DONE,    OSIF_CMDNEW);
""" % (m.group(1),m.group(1)))
# }}}       
#-----------------------------------------------------------------------------------
# read_thread_exit     {{{
#-----------------------------------------------------------------------------------
                m = expRdExit.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read thread_exit %s
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_THREAD_EXIT report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_THREAD_EXIT (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_thread_yield     {{{
#-----------------------------------------------------------------------------------
                m = expRdYield.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read thread_yield
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_THREAD_YIELD report "*** ERROR: DCR read mismatch! Expected OSIF_CMD_THREAD_YIELD (SST line %d). ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % lineNum)
# }}}
#-----------------------------------------------------------------------------------
# read_thread_delay     {{{
#-----------------------------------------------------------------------------------
                m = expRdDelay.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read thread_delay %s
        OSIF_READ(OSIF_REG_COMMAND, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = OSIF_CMD_THREAD_DELAY report "*** ERROR: DCR command read mismatch! Expected OSIF_CMD_THREAD_DELAY (SST line %d)." severity WARNING;
        OSIF_READ(OSIF_REG_DATA, dummy);
        assert dummy = X"%s" report "*** ERROR: DCR data read mismatch (SST line %d)! ***" severity WARNING;
        OSIF_READ(OSIF_REG_DATAX, dummy);
""" % (m.group(1),lineNum,m.group(1),lineNum))
# }}}
#-----------------------------------------------------------------------------------
# read_signature     {{{
#-----------------------------------------------------------------------------------
                m = expRdSignature.match(line)
                if m:
                        foundMatch = True
                        outputLines.append("""
        -- read signature %s
        OSIF_READ(OSIF_REG_SIGNATURE, dummy);
        assert dummy(0 to C_OSIF_CMD_WIDTH-1) = X"%s" report "*** ERROR: DCR siganture read mismatch (SST line %d)!" severity WARNING;
""" % (m.group(1),m.group(1),lineNum))
# }}}                
#-----------------------------------------------------------------------------------
# comment or whitespace             {{{
#-----------------------------------------------------------------------------------
                m = expCommentOrWhitespace.match(line)
                if m:
                        foundMatch = True
# }}}
#-----------------------------------------------------------------------------------
                
                if not foundMatch:
                        sys.stderr.write("Parse error at line %d.\n" % lineNum)
                        inputFile.close()
                        sys.exit(-1)

        inputFile.close() 

        testbenchFile = open(testbenchFileName, "r")
        outputBuffer = testbenchFile.readlines();
        testbenchFile.close()
    
        # make backup
        shutil.copy(testbenchFileName, testbenchFileName + ".bak")

        outputFile = open(testbenchFileName, "w")

        fillState = 0       # 0 means output the template, 1 means output the outputlines

        for x in outputBuffer:
            if fillState == 0:
                outputFile.write(x)
                if x == "-- %%%SST_TESTBENCH_START%%%\n":
                    for l in outputLines:
                        outputFile.write(l)
                    fillState = 1
            else:
                if x == "-- %%%SST_TESTBENCH_END%%%\n": 
                    outputFile.write(x)
                    fillState = 0

        outputFile.close()

                
                        
