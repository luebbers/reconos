--
-- \file reconos_pkg.vhd
--
-- ReconOS package
--
-- Contains type definitions and functions for hardware OS services in VHDL
--
-- \author     Enno Luebbers <luebbers@reconos.de>
-- \date       27.06.2006
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of ReconOS (http://www.reconos.de).
-- Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
-- All rights reserved.
-- 
-- ReconOS is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
-- 
-- ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
----------------------------------------------------------------------------
--
-- Major changes
-- 27.06.2006  Enno Luebbers        File created
-- 30.06.2006  Enno Luebbers        added shared memory data types
-- 17.07.2006  Enno Luebbers        merged osif and shm interfaces
-- 18.07.2006  Enno Luebbers        implemented shared memory reads
-- 03.08.2006  Enno Luebbers        Added commands for shared memory
--                                  initialization (PLB busmaster)
-- 04.07.2007  Enno Luebbers        Added support for multi-cycle
--                                  commands, tidied code (command_decoder)
-- 10.07.2007  Enno Luebbers        Added support for auxiliary thread "data"
-- 11.07.2007  Enno Luebbers        Added support for mutexes
-- xx.07.2007  Enno Luebbers        Added support for condition variables
-- xx.09.2007  Enno Luebbers        added support for mailboxes
-- 04.10.2007  Enno Luebbers        added support for local mailboxes
-- 09.02.2008  Enno Luebbers        implemented thread_exit() call
-- 19.04.2008  Enno Luebbers        added handshaking between command_decoder
--                                  and HW thread
-- 04.08.2008  Andreas Agne         implemented mq send and receive functions
-- 22.08.2010  Andreas Agne         added MMU related command codes
--*************************************************************************/

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package reconos_pkg is

--######################## CONSTANTS #########################

  -- width of shared memory ports      FIXME: this should be configurable per task
  --constant C_SHARED_MEM_DWIDTH : natural := 32;
  --constant C_SHARED_MEM_AWIDTH : natural := 26;  -- maximum of 64MBytes shared memory

  -- width of OSIF commands, data registers
  constant C_OSIF_CMD_WIDTH       : natural := 8;
  constant C_OSIF_DATA_WIDTH      : natural := 32;
  constant C_OSIF_STATE_ENC_WIDTH : natural := 8;   -- max 256 state
  constant C_OSIF_DATA_BURSTLEN_WIDTH : natural := 10;

  -- number of bits in communication records
  constant C_OSIF_OS2TASK_REC_WIDTH : natural := C_OSIF_CMD_WIDTH + C_OSIF_DATA_WIDTH + 5 + 2;
  constant C_OSIF_TASK2OS_REC_WIDTH : natural := C_OSIF_CMD_WIDTH + C_OSIF_DATA_WIDTH + C_OSIF_STATE_ENC_WIDTH + 3;

  -- OSIF flags
  constant C_OSIF_FLAGS_WIDTH     : natural := 8;   -- flags (such as ready to yield)
  constant C_OSIF_FLAGS_YIELD_BITPOS : natural := 0;



  -- FIXME: DEPRECATED -- this is not necessarily true and is subject to change
  --                      upon further extensions
  -- a OSIF shared memory command is structured as follows:
  -- bit     0: request is blocking (0)
  constant C_OSIF_CMD_BLOCKING_BITPOS              : natural := 0;
  -- bit     1: request is handled by hardware (1)
  constant C_OSIF_CMD_REQUEST_HANDLED_BY_HW_BITPOS : natural := 1;
  -- bit     2: request is a memory request (1)
  constant C_OSIF_CMD_MEMORY_REQUEST_BITPOS        : natural := 2;
  -- bit     3: request is a read request
  constant C_OSIF_CMD_MEMORY_DIRECTION_BITPOS      : natural := 3;
  -- bit     4: request is a burst request
  constant C_OSIF_CMD_BURST_BITPOS                 : natural := 4;
  -- bits 6-31: address of memory request
--  constant C_OSIF_CMD_SHM_ADDRESS_BITPOS           : natural := C_OSIF_CMD_WIDTH-C_SHARED_MEM_AWIDTH;
  -- FIXME: the lower two bits of the address should always read '0'. (in case of burst start addresses, the three lower bits)

  -- maximum steps a multicycle command can take
  constant C_MAX_MULTICYCLE_STEPS : natural := 4;
  constant C_OSIF_STEP_ENC_WIDTH : natural := 2;   -- max 4 steps
  constant C_STEP_RESUME : natural := C_MAX_MULTICYCLE_STEPS-1; -- step in which to resume multi-cycle commands

  -- common constants
  constant C_RECONOS_FAILURE : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"00000000";
  constant C_RECONOS_SUCCESS : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"00000001";

  ---------------------------------------------------
  -- task2os commands
  ---------------------------------------------------

  ----- non-blocking commands (MSB cleared)  -----

  -- post semaphore
  constant OSIF_CMD_SEM_POST : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"00";
  -- write to shared memory
--  constant OSIF_CMD_SHM_WRITE_PREFIX       : std_logic_vector(0 to C_OSIF_CMD_SHM_ADDRESS_BITPOS-1) := X"6" & "00";
  -- read from shared memory
--  constant OSIF_CMD_SHM_READ_PREFIX        : std_logic_vector(0 to C_OSIF_CMD_SHM_ADDRESS_BITPOS-1) := X"7" & "00";
  -- initiate write burst to shared memory
--  constant OSIF_CMD_SHM_WRITE_BURST_PREFIX : std_logic_vector(0 to C_OSIF_CMD_SHM_ADDRESS_BITPOS-1) := X"6" & "10";
  -- initiate read burst from shared memory
--  constant OSIF_CMD_SHM_READ_BURST_PREFIX  : std_logic_vector(0 to C_OSIF_CMD_SHM_ADDRESS_BITPOS-1) := X"7" & "10";

  -- read word from memory
  constant OSIF_CMD_READ        : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"48";
  -- write word to memory
  constant OSIF_CMD_WRITE       : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"49";
  -- initiate read burst from shared memory
  constant OSIF_CMD_READ_BURST  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"4A";
  -- initiate write burst to shared memory
  constant OSIF_CMD_WRITE_BURST : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"4B";
  
  -- read thread data (from thread initialization)
  constant OSIF_CMD_GET_INIT_DATA : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"40";

  -- mutex unlock
  constant OSIF_CMD_MUTEX_UNLOCK  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"02";
  -- mutex release
  constant OSIF_CMD_MUTEX_RELEASE : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"03";
  -- signal condition variable
  constant OSIF_CMD_COND_SIGNAL : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"04";
  -- broadcast condition variable
  constant OSIF_CMD_COND_BROADCAST : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"05";

  -- thread resume
 constant OSIF_CMD_THREAD_RESUME  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"10";

  ----- blocking commands (MSB set)     -----

  -- wait on semaphore
  constant OSIF_CMD_SEM_WAIT      : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"81";
  -- mutex lock
  constant OSIF_CMD_MUTEX_LOCK    : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"82";
  -- mutex trylock (blocking because hardware has to wait for the return value)
  constant OSIF_CMD_MUTEX_TRYLOCK : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"83";
  -- wait on condition variable
  constant OSIF_CMD_COND_WAIT     : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"84";

  -- mbox get
  constant OSIF_CMD_MBOX_GET      : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"85";
  -- mbox tryget (blocking because hardware has to wait for the return value)
  constant OSIF_CMD_MBOX_TRYGET   : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"86";
  -- mbox put
  constant OSIF_CMD_MBOX_PUT      : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"87";
  -- mbox tryput (blocking because hardware has to wait for the return value)
  constant OSIF_CMD_MBOX_TRYPUT   : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"88";
  -- mq send
  constant OSIF_CMD_MQ_SEND       : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"8A";
  -- mq receive
  constant OSIF_CMD_MQ_RECEIVE    : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"8C";
  -- thread_delay
  constant OSIF_CMD_THREAD_DELAY  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"8D";
  
  -- thread exit (blocking to prevent further activity, never returns)
  constant OSIF_CMD_THREAD_EXIT   : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"F0";
  -- thread yield   (NOTE: only _potentially_ blocking)
  constant OSIF_CMD_THREAD_YIELD  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"F1";

-- FIXME: DEPRECATED!
  -- local mbox tryget
  constant OSIF_CMD_MBOX_TRYGET_LOCAL  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"41";
  -- local mbox tryput
  constant OSIF_CMD_MBOX_TRYPUT_LOCAL  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"42";

  -- mmu exceptions
  constant OSIF_CMD_MMU_FAULT            : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"4C";
  constant OSIF_CMD_MMU_ACCESS_VIOLATION : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"4D";




  ---------------------------------------------------
  -- os2task commands
  ---------------------------------------------------

  -- end blocking request
  constant OSIF_CMD_UNBLOCK : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"00";

  -- set thread data (on initialization)
  constant OSIF_CMD_SET_INIT_DATA : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"01";
  
  -- reset thread (and block it)
  constant OSIF_CMD_RESET : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"02";
  
  -- enable/disable busmacros
  constant OSIF_CMD_BUSMACRO : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"03";
  constant OSIF_DATA_BUSMACRO_DISABLE : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"00000000";
  
  -- set local FIFO handles
  constant OSIF_CMD_SET_FIFO_READ_HANDLE   : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"04";
  constant OSIF_CMD_SET_FIFO_WRITE_HANDLE  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"05";

  -- control yield/resume state
  constant OSIF_CMD_SET_RESUME_STATE : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"06";
  constant OSIF_CMD_CLEAR_RESUME_STATE : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"07";
  constant OSIF_CMD_REQUEST_YIELD : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"08";
  constant OSIF_CMD_CLEAR_YIELD : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"09";

  -- mmu initialization and exception handling
  constant OSIF_CMD_MMU_SETPGD           : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"0A";
  constant OSIF_CMD_MMU_REPEAT           : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"0B";
  constant OSIF_CMD_MMU_RESET            : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1) := X"0C";

--######################## TYPES #########################

  ---------------------------------------------------
  -- communication records
  ---------------------------------------------------
  -- Note: These signals should be set and read synchronously.
  --       Use the reconos_* procedures and functions.
  -- Note: If you change the OSIF or SHM interface definitions,
  --       remember to adjust the C_*_REC_WIDTH constants above

  -- OS to task communication
  type osif_os2task_t is record
    command  : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);  -- command identifier
    data     : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);   -- attached data
    busy     : std_logic;               -- OS interface busy
    blocking : std_logic;               -- executing blocking OS call
    ack      : std_logic;               -- acknowledge (for asynchronous communication)
    req_yield: std_logic;
    valid    : std_logic;               -- command valid (new command)
    step     : natural range 0 to C_MAX_MULTICYCLE_STEPS-1;  -- for multi-cycle commands
  end record;

  -- task to OS communication
  type osif_task2os_t is record
    command : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);  -- command identifier
    data    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);  -- attached data
    request : std_logic;                -- request indicator (high for 1 cycle)
    yield   : std_logic;                -- yield indicator (thread can be removed)
    saved_state_enc : std_logic_vector(0 to C_OSIF_STATE_ENC_WIDTH-1);   -- saved state when yielding
    error   : std_logic;                -- error indicator
  end record;

-------------------------
  
  -- standard state encoding
  subtype reconos_state_enc_t is std_logic_vector(0 to C_OSIF_STATE_ENC_WIDTH-1);
  subtype reconos_step_enc_t is std_logic_vector(0 to C_OSIF_STEP_ENC_WIDTH-1);

--######################## FUNCTIONS & PROCEDURES #########################

  function to_std_logic_vector (osif_os2task : osif_os2task_t) return std_logic_vector;
  function to_std_logic_vector (osif_task2os : osif_task2os_t) return std_logic_vector;
  function to_osif_os2task_t (vector         : std_logic_vector) return osif_os2task_t;
  function to_osif_task2os_t (vector         : std_logic_vector) return osif_task2os_t;

  function reconos_ready (osif_os2task : osif_os2task_t) return boolean;

  procedure reconos_reset (signal osif_task2os : out osif_task2os_t;
                           osif_os2task        :     osif_os2task_t);
                           
  procedure reconos_reset_with_signature (signal osif_task2os : out osif_task2os_t;
                                          osif_os2task        : in  osif_os2task_t;
                                          signature           : in std_logic_vector(0 to 31) );

  procedure reconos_begin (signal osif_task2os : out osif_task2os_t;
                           osif_os2task        :     osif_os2task_t);

  function reconos_check_yield (osif_os2task : osif_os2task_t) return boolean;

  procedure reconos_sem_post (signal osif_task2os : out osif_task2os_t;
                              osif_os2task        : in  osif_os2task_t;
                              handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_sem_wait (signal osif_task2os : out osif_task2os_t;
                              osif_os2task        : in  osif_os2task_t;
                              handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_write (variable completed  : out boolean;
                           signal osif_task2os : out osif_task2os_t;
                           signal osif_os2task : in  osif_os2task_t;
                           address             : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                           data                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_read (variable completed    : out boolean;
                          signal   osif_task2os : out osif_task2os_t;
                          signal   osif_os2task : in  osif_os2task_t;
                          address               : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                          variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_read_s (variable completed  : out boolean;
                            signal osif_task2os : out osif_task2os_t;
                            signal osif_os2task : in  osif_os2task_t;
                            address             : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                            signal data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_write_burst (variable completed  : out boolean;
                                 signal osif_task2os : out osif_task2os_t;
                                 signal osif_os2task : in  osif_os2task_t;
                                 my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                 target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_read_burst (variable completed  : out boolean;
                                signal osif_task2os : out osif_task2os_t;
                                signal osif_os2task : in  osif_os2task_t;
                                my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_write_burst_l (variable completed  : out boolean;
                                 signal osif_task2os : out osif_task2os_t;
                                 signal osif_os2task : in  osif_os2task_t;
                                 my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                 target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                 burst_length        : in  natural range 2 to 512);

  procedure reconos_read_burst_l (variable completed  : out boolean;
                                signal osif_task2os : out osif_task2os_t;
                                signal osif_os2task : in  osif_os2task_t;
                                my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                burst_length        : in  natural range 2 to 512);

  procedure reconos_get_init_data (variable completed    : out boolean;
                                   signal   osif_task2os : out osif_task2os_t;
                                   signal   osif_os2task : in  osif_os2task_t;
                                   variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_get_init_data_s (variable completed  : out boolean;
                                     signal osif_task2os : out osif_task2os_t;
                                     signal osif_os2task : in  osif_os2task_t;
                                     signal data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));


  procedure reconos_mutex_lock(variable completed    : out boolean;
                               variable success      : out boolean;
                               signal   osif_task2os : out osif_task2os_t;
                               signal   osif_os2task : in  osif_os2task_t;
                               handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mutex_trylock(variable completed    : out boolean;
                                  variable success      : out boolean;
                                  signal   osif_task2os : out osif_task2os_t;
                                  signal   osif_os2task : in  osif_os2task_t;
                                  handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mutex_unlock(signal osif_task2os : out osif_task2os_t;
                                 signal osif_os2task : in  osif_os2task_t;
                                 handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mutex_release(signal osif_task2os : out osif_task2os_t;
                                  signal osif_os2task : in  osif_os2task_t;
                                  handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));
                                  
  procedure reconos_cond_wait(variable completed    : out boolean;
                              variable success      : out boolean;
                              signal   osif_task2os : out osif_task2os_t;
                              signal   osif_os2task : in  osif_os2task_t;
                              handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));
                              
  procedure reconos_cond_signal(signal osif_task2os : out osif_task2os_t;
                                signal osif_os2task : in  osif_os2task_t;
                                handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));
                              
  procedure reconos_cond_broadcast(signal osif_task2os : out osif_task2os_t;
                                   signal osif_os2task : in  osif_os2task_t;
                                   handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));
                              
  procedure reconos_mbox_get(variable completed    : out boolean;
                             variable success      : out boolean;
                             signal   osif_task2os : out osif_task2os_t;
                             signal   osif_os2task : in  osif_os2task_t;
                             handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mbox_get_s(variable completed    : out boolean;
                               variable success      : out boolean;
                               signal   osif_task2os : out osif_task2os_t;
                               signal   osif_os2task : in  osif_os2task_t;
                               handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                               signal   data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mbox_tryget(variable completed    : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mbox_tryget_s(variable completed    : out boolean;
                                  variable success      : out boolean;
                                  signal   osif_task2os : out osif_task2os_t;
                                  signal   osif_os2task : in  osif_os2task_t;
                                  handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                  signal   data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mbox_put(variable completed    : out boolean;
                             variable success      : out boolean;
                             signal   osif_task2os : out osif_task2os_t;
                             signal   osif_os2task : in  osif_os2task_t;
                             handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             data                  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));
  
  procedure reconos_mq_send(variable completed    : out boolean;
                            variable success      : out boolean;
                            signal   osif_task2os : out osif_task2os_t;
                            signal   osif_os2task : in  osif_os2task_t;
                            handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                            offset                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                            length                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mq_receive(variable completed    : out boolean;
                            variable success      : out boolean;
                            signal   osif_task2os : out osif_task2os_t;
                            signal   osif_os2task : in  osif_os2task_t;
                            handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                            offset                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                            length                : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));


  procedure reconos_mbox_tryput(variable completed    : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                data                  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));


--------- FIXME: local mbox operations only for testing
---------        they should really be handled by the 'regular' mailbox procedures

  procedure reconos_mbox_tryget_local(variable completed    : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mbox_tryget_local_s(variable completed    : out boolean;
                                  variable success      : out boolean;
                                  signal   osif_task2os : out osif_task2os_t;
                                  signal   osif_os2task : in  osif_os2task_t;
                                  handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                  signal   data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_mbox_tryput_local(variable completed    : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                data                  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

  procedure reconos_thread_exit(signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                         retval       : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));    

  procedure reconos_flag_yield(signal   osif_task2os : out osif_task2os_t;
                                    osif_os2task : in  osif_os2task_t;
                                 saved_state_enc        : in  reconos_state_enc_t);

  procedure reconos_thread_yield(signal   osif_task2os : out osif_task2os_t;
                                 signal   osif_os2task : in  osif_os2task_t;
                                 saved_state_enc        : in  reconos_state_enc_t);

  procedure reconos_thread_resume(variable completed : out boolean;
                                 variable success         : out boolean;
                                 signal   osif_task2os     : out osif_task2os_t;
                                 signal   osif_os2task     : in  osif_os2task_t;
                                 variable resume_state_enc : out reconos_state_enc_t);

  procedure reconos_thread_delay(signal   osif_task2os : out osif_task2os_t;
                                 signal   osif_os2task : in  osif_os2task_t;
                                 delay        : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1));

--================ TOOL FUNCTIONS ==================
-- FIXME: this should be in seperate package
  function reduce_or (input : std_logic_vector) return std_logic;

end reconos_pkg;


package body reconos_pkg is

  ---------------------------------------------------
  -- to_std_logic_vector: converts a osif_os2task_t or 
  --                              osif_task2os_t record
  --                      to a std_logic_vector
  ---------------------------------------------------
  function to_std_logic_vector (osif_os2task : osif_os2task_t) return std_logic_vector is
  begin
    return osif_os2task.command & osif_os2task.data & osif_os2task.busy & osif_os2task.blocking & osif_os2task.ack & osif_os2task.req_yield & osif_os2task.valid & std_logic_vector(TO_UNSIGNED(osif_os2task.step, 2));
  end;

  function to_std_logic_vector (osif_task2os : osif_task2os_t) return std_logic_vector is
  begin
    return osif_task2os.command & 
    osif_task2os.data & 
    osif_task2os.request & 
    osif_task2os.yield & 
    osif_task2os.saved_state_enc &
    osif_task2os.error;
  end;


  ---------------------------------------------------
  -- to_osif_(os2(task)2os)_t: converts a std_logic_vector
  --                                     to the appropriate record
  ---------------------------------------------------
  function to_osif_os2task_t (vector : std_logic_vector) return osif_os2task_t is
    variable rec : osif_os2task_t;
    variable i, j : natural;
  begin
    i := vector'low; j := i + C_OSIF_CMD_WIDTH;
    rec.command  := vector(i to j-1);
    
    i := j; j := i + C_OSIF_DATA_WIDTH;
    rec.data     := vector(i to j-1);
    
    i := j; j := i + 1;
    rec.busy     := vector(i);
    
    i := j; j := i + 1;
    rec.blocking := vector(i);

    i := j; j := i + 1;
    rec.ack      := vector(i);
    
    i := j; j := i + 1;
    rec.req_yield := vector(i);
    
    i := j; j := i + 1;
    rec.valid    := vector(i);
    
    i := j; j := i + 2;
    rec.step     := TO_INTEGER(unsigned(vector(i to j-1)));  -- 2 bits for step
    return rec;
  end;

  function to_osif_task2os_t (vector : std_logic_vector) return osif_task2os_t is
    variable rec : osif_task2os_t;
    variable i, j : natural;
  begin
    i := vector'low; j := i + C_OSIF_CMD_WIDTH;
    rec.command := vector(i to j-1);
    
    i := j; j := i + C_OSIF_DATA_WIDTH;
    rec.data    := vector(i to j-1);
    
    i := j; j := i + 1;
    rec.request := vector(i);
    
    i := j; j := i + 1;
    rec.yield := vector(i);
    
    i := j; j := i + C_OSIF_STATE_ENC_WIDTH;
    rec.saved_state_enc := vector(i to j-1);

    i := j; j := i + 1;
    rec.error   := vector(i);
    
    return rec;
  end;


  ---------------------------------------------------
  -- reconos_ready: check whether OSIF is ready 
  --
  -- osif_os2task: OSIF os2task channel
  --
  -- returns false if OSIF is busy or there is
  -- a blocking OS call running, true otherwise
  ---------------------------------------------------
  function reconos_ready (osif_os2task : osif_os2task_t) return boolean is
  begin
    if osif_os2task.blocking = '1' or osif_os2task.busy = '1' then
      return false;
    else
      return true;
    end if;
  end;


  ---------------------------------------------------
  -- reconos_reset_with_signature: reset task2os interface and set hwthread
  -- signature.
  --
  -- should be used in the "if reset"-clause of
  -- the osif communication process in a user task.
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  ---------------------------------------------------
  procedure reconos_reset_with_signature (signal osif_task2os : out osif_task2os_t;
                           osif_os2task        : in  osif_os2task_t;
                           signature           : in std_logic_vector(0 to 31) ) is
  begin
    osif_task2os.command <= (others => '0');
    osif_task2os.data    <= signature;
    osif_task2os.request <= '0';
    osif_task2os.yield   <= '0';
    osif_task2os.saved_state_enc <= (others => '0');
    osif_task2os.error   <= '0';
  end;


  ---------------------------------------------------
  -- reconos_reset: reset task2os interface
  --
  -- should be used in the "if reset"-clause of
  -- the osif communication process in a user task.
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  ---------------------------------------------------
  procedure reconos_reset (signal osif_task2os : out osif_task2os_t;
                           osif_os2task        : in  osif_os2task_t) is
  begin
      reconos_reset_with_signature(osif_task2os, osif_os2task, X"00000000");
  end;


  ---------------------------------------------------
  -- reconos_begin: every-cycle signal assignments
  --
  -- contains assignments that need to be run on
  -- every clock cycle
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  ---------------------------------------------------
  procedure reconos_begin (signal osif_task2os : out osif_task2os_t;
                           osif_os2task        : in  osif_os2task_t) is
  begin
	  osif_task2os.request <= '0';
          osif_task2os.yield   <= '0';
  end;

  ---------------------------------------------------
  -- reconos_check_yield: check whether OS requests yield
  --
  -- osif_os2task: OSIF os2task channel
  --
  -- returns true if OS has set the req_yield flag, false otherwise
  ---------------------------------------------------
  function reconos_check_yield (osif_os2task : osif_os2task_t) return boolean is
  begin
      if osif_os2task.req_yield = '1' then
      return true;
    else
      return false;
    end if;
  end;

  ---------------------------------------------------
  -- reconos_flag_yield: signal possible yield
  --
  -- this signals the OS that this thread has no
  -- state and could be removed
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- saved_state_enc : encoded state to resume in
  ---------------------------------------------------
  procedure reconos_flag_yield (signal osif_task2os : out osif_task2os_t;
                           osif_os2task        : in  osif_os2task_t;
                           saved_state_enc     : in reconos_state_enc_t ) is
  begin
          osif_task2os.yield   <= '1';
          osif_task2os.saved_state_enc <= saved_state_enc;
  end;

  ---------------------------------------------------
  -- reconos_sem_post: post a counting semaphore
  --
  -- equivalent to eCos' cyg_semaphore_post()
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : ReconOS handle identifier
  ---------------------------------------------------
  procedure reconos_sem_post (signal osif_task2os : out osif_task2os_t;
                              osif_os2task        : in  osif_os2task_t;
                              handle              : in  std_logic_vector(0 to 31)) is
  begin
    osif_task2os.command <= OSIF_CMD_SEM_POST;
    osif_task2os.data    <= handle;
    osif_task2os.request <= '1';

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;


  ---------------------------------------------------
  -- reconos_sem_wait: wait for a counting semaphore
  --
  -- equivalent to eCos' cyg_semaphore_wait()
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel

  -- handle      : ReconOS handle identifier
  ---------------------------------------------------
  procedure reconos_sem_wait (signal osif_task2os : out osif_task2os_t;
                              osif_os2task        : in  osif_os2task_t;
                              handle              : in  std_logic_vector(0 to 31)) is
  begin
    osif_task2os.command <= OSIF_CMD_SEM_WAIT;
    osif_task2os.data    <= handle;
    osif_task2os.request <= '1';

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;

  ---------------------------------------------------
  -- reconos_thread_delay: wait for a specified number of 'ticks'
  --
  -- equivalent to eCos' cyg_thread_delay()
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel

  -- delay       : number of ticks to wait
  ---------------------------------------------------
  procedure reconos_thread_delay (signal osif_task2os : out osif_task2os_t;
                                  signal osif_os2task : in  osif_os2task_t;
                                  delay               : in  std_logic_vector(0 to 31)) is
  begin
    osif_task2os.command <= OSIF_CMD_THREAD_DELAY;
    osif_task2os.data    <= delay;
    osif_task2os.request <= '1';

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;
--------------- multi-cycle functions   --------------

  ---------------------------------------------------
  -- reconos_write: write to system memory
  ---
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- address     : system memory address
  -- data        : data to write
  ---------------------------------------------------
  procedure reconos_write (variable completed  : out boolean;
                           signal osif_task2os : out osif_task2os_t;
                           signal osif_os2task : in  osif_os2task_t;
                           address             : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                           data                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is

  begin
    osif_task2os.command <= OSIF_CMD_WRITE;
    osif_task2os.request <= '1';
    completed            := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= address;

      when 1 => osif_task2os.data <= data;
                completed := true;

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_write             


  ---------------------------------------------------
  -- reconos_read: read from system memory
  ---
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- address     : system memory address
  -- data        : signal to read data into
  ---------------------------------------------------
  
  procedure reconos_read (variable completed    : out boolean;
                          signal   osif_task2os : out osif_task2os_t;
                          signal   osif_os2task : in  osif_os2task_t;
                          address               : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                          variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is

  begin
    osif_task2os.command <= OSIF_CMD_READ;
    osif_task2os.request <= '1';
    completed            := false;
    data                 := (others => '0');

    case osif_os2task.step is
      when 0 => osif_task2os.data <= address;

      when 1 => data := osif_os2task.data;
                completed := true;

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_read


  ---------------------------------------------------
  -- reconos_read: read from system memory
  ---
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- address     : system memory address
  -- data        : signal to read data into
  ---------------------------------------------------
  
  procedure reconos_read_s (variable completed  : out boolean;
                            signal osif_task2os : out osif_task2os_t;
                            signal osif_os2task : in  osif_os2task_t;
                            address             : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                            signal data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is

    variable tmp  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    variable done : boolean;
  begin
    
    reconos_read(done, osif_task2os, osif_os2task, address, tmp);
    data      <= tmp;
    completed := done;
    
  end;  -- reconos_read_s

  ---------------------------------------------------
  -- reconos_write_burst: write a burst to system memory (16x64 Bit)
  --
  -- retained for compatibility reasons
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed     : goes '1' when last cycle completed
  -- osif_task2os  : OSIF task2os channel
  -- osif_os2task  : OSIF os2task channel
  -- my_address    : local burst ram address (in bytes!)
  -- target_address: system memory address
  ---------------------------------------------------
  procedure reconos_write_burst (variable completed  : out boolean;
                                 signal osif_task2os : out osif_task2os_t;
                                 signal osif_os2task : in  osif_os2task_t;
                                 my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                 target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is

  begin
      reconos_write_burst_l(completed, 
                            osif_task2os, 
                            osif_os2task, 
                            my_address, 
                            target_address, 
                            16);
  end;  -- reconos_write_burst



  ---------------------------------------------------
  -- reconos_read_burst: read a burst from system memory (16x64 Bit)
  --
  -- retained for compatibility reasons
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed     : goes '1' when last cycle completed
  -- osif_task2os  : OSIF task2os channel
  -- osif_os2task  : OSIF os2task channel
  -- my_address    : local burst ram address (in bytes!)
  -- target_address: system memory address
  ---------------------------------------------------
  procedure reconos_read_burst (variable completed  : out boolean;
                                signal osif_task2os : out osif_task2os_t;
                                signal osif_os2task : in  osif_os2task_t;
                                my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is

  begin
      reconos_read_burst_l(completed, 
                            osif_task2os, 
                            osif_os2task, 
                            my_address, 
                            target_address, 
                            16);
  end;  -- reconos_read_burst


  ---------------------------------------------------
  -- reconos_write_burst_l: write a burst to system memory with specified burst length
  ---
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed     : goes '1' when last cycle completed
  -- osif_task2os  : OSIF task2os channel
  -- osif_os2task  : OSIF os2task channel
  -- my_address    : local burst ram address (in bytes!)
  -- target_address: system memory address
  -- burst_length  : length of the burst in 64bit transfers (=cycles)
  ---------------------------------------------------
  procedure reconos_write_burst_l (variable completed  : out boolean;
                                 signal osif_task2os : out osif_task2os_t;
                                 signal osif_os2task : in  osif_os2task_t;
                                 my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                 target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                 burst_length        : in  natural range 2 to 512) is

  begin
    osif_task2os.command <= OSIF_CMD_WRITE_BURST;
    osif_task2os.request <= '1';
    completed            := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= my_address;

      when 1 => osif_task2os.data <= target_address;

      when 2 => osif_task2os.data(C_OSIF_DATA_WIDTH-C_OSIF_DATA_BURSTLEN_WIDTH to C_OSIF_DATA_WIDTH-1) <= std_logic_vector(to_unsigned(burst_length, C_OSIF_DATA_BURSTLEN_WIDTH));
                completed := true;

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_write_burst_l



  ---------------------------------------------------
  -- reconos_read_burst_l: read a burst from system memory with specified length
  ---
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed     : goes '1' when last cycle completed
  -- osif_task2os  : OSIF task2os channel
  -- osif_os2task  : OSIF os2task channel
  -- my_address    : local burst ram address (in bytes!)
  -- target_address: system memory address
  -- burst_length  : length of the burst in 64bit transfers (=cycles)
  ---------------------------------------------------
  procedure reconos_read_burst_l (variable completed  : out boolean;
                                signal osif_task2os : out osif_task2os_t;
                                signal osif_os2task : in  osif_os2task_t;
                                my_address          : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                target_address      : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                burst_length        : in  natural range 2 to 512) is

  begin
    osif_task2os.command <= OSIF_CMD_READ_BURST;
    osif_task2os.request <= '1';
    completed            := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= my_address;

      when 1 => osif_task2os.data <= target_address;

      when 2 => osif_task2os.data(C_OSIF_DATA_WIDTH-C_OSIF_DATA_BURSTLEN_WIDTH to C_OSIF_DATA_WIDTH-1) <= std_logic_vector(to_unsigned(burst_length, C_OSIF_DATA_BURSTLEN_WIDTH));
                completed := true;

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_read_burst_l




  ---------------------------------------------------
  -- reconos_mutex_lock: attain a lock on a mutex
  --
  -- If the mutex is already locked, wait (blocking) until its release
  -- Returns '1' in "success" if mutex lock was successful, otherwise '0'
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully locked, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : mutex to lock
  ---------------------------------------------------
  procedure reconos_mutex_lock(variable completed    : out boolean;
                               variable success      : out boolean;
                               signal   osif_task2os : out osif_task2os_t;
                               signal   osif_os2task : in  osif_os2task_t;
                               handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MUTEX_LOCK;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;

      when 1 =>
        completed := true;
        if osif_os2task.data = C_RECONOS_FAILURE then
          success := false;
        else
          success := true;
        end if;
        
      when C_STEP_RESUME =>
          -- wait step for resuming

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mutex_lock


  ---------------------------------------------------
  -- reconos_mutex_trylock: try attaining a lock on a mutex
  --
  -- If the mutex is already locked, return immediately (do not wait)
  -- Returns '1' in "success" if mutex lock was successful, otherwise '0'
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully locked, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : mutex to lock
  ---------------------------------------------------
-- this is implemented as a blocking call, to be able to receive a return value
  procedure reconos_mutex_trylock(variable completed    : out boolean;
                                  variable success      : out boolean;
                                  signal   osif_task2os : out osif_task2os_t;
                                  signal   osif_os2task : in  osif_os2task_t;
                                  handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is

  begin
    osif_task2os.command <= OSIF_CMD_MUTEX_TRYLOCK;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;

      when 1 =>
        completed := true;
        if osif_os2task.data = C_RECONOS_FAILURE then
          success := false;
        else
          success := true;
        end if;
        
      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mutex_trylock
  
  

  ---------------------------------------------------
  -- reconos_mutex_unlock: unlock a previously locked mutex
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : mutex to unlock
  ---------------------------------------------------
  procedure reconos_mutex_unlock(signal osif_task2os : out osif_task2os_t;
                                 signal osif_os2task : in  osif_os2task_t;
                                 handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MUTEX_UNLOCK;
    osif_task2os.request <= '1';
    osif_task2os.data    <= handle;

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;  -- reconos_mutex_unlock
  


  ---------------------------------------------------
  -- reconos_mutex_release: release all threads waiting on this mutex
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : mutex to release
  ---------------------------------------------------
  procedure reconos_mutex_release(signal osif_task2os : out osif_task2os_t;
                                  signal osif_os2task : in  osif_os2task_t;
                                  handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MUTEX_RELEASE;
    osif_task2os.request <= '1';
    osif_task2os.data    <= handle;

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;  -- reconos_mutex_release



  ---------------------------------------------------
  -- reconos_get_init_data: read thread init data
  --
  -- "thread init data" is a 32 bit value that is passed to
  -- the thread creation function (i.e. reconos_hwthread_create()).
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- data        : variable to read data into
  ---------------------------------------------------
  procedure reconos_get_init_data (variable completed    : out boolean;
                                   signal   osif_task2os : out osif_task2os_t;
                                   signal   osif_os2task : in  osif_os2task_t;
                                   variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is

  begin
    osif_task2os.command <= OSIF_CMD_GET_INIT_DATA;
    osif_task2os.request <= '1';
    completed            := false;
    data                 := (others => '0');

    case osif_os2task.step is
      when 0 => null;

      when 1 => data := osif_os2task.data;
                completed := true;

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_get_init_data


  ---------------------------------------------------
  -- reconos_get_init_data_s: read thread init data into signal
  --
  -- "thread init data" is a 32 bit value that is passed to
  -- the thread creation function (i.e. reconos_hwthread_create()).
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- data        : signal to read data into
  ---------------------------------------------------
  procedure reconos_get_init_data_s (variable completed  : out boolean;
                                     signal osif_task2os : out osif_task2os_t;
                                     signal osif_os2task : in  osif_os2task_t;
                                     signal data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
    variable tmp  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    variable done : boolean;
  begin
    
    reconos_get_init_data(done, osif_task2os, osif_os2task, tmp);
    data      <= tmp;
    completed := done;

  end;  -- reconos_get_init_data



  ---------------------------------------------------
  -- reconos_cond_wait: wait for condition change
  --
  -- This implicitly unlocks the mutex associated with the condition variable "handle".
  -- waits blocking until someone "signals" the condition variable
  -- Returns '1' in "success" if mutex lock was successful, otherwise '0'
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully locked, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to wait for
  ---------------------------------------------------
  procedure reconos_cond_wait(variable completed    : out boolean;
                              variable success      : out boolean;
                              signal   osif_task2os : out osif_task2os_t;
                              signal   osif_os2task : in  osif_os2task_t;
                              handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_COND_WAIT;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;

      when 1 =>
        completed := true;
        if osif_os2task.data = C_RECONOS_FAILURE then
          success := false;
        else
          success := true;
        end if;
        
      when C_STEP_RESUME =>
          -- wait step for resuming

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_cond_wait
                              
                              
                              
  ---------------------------------------------------
  -- reconos_cond_signal: wake next thread waiting on condition variable
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  ---------------------------------------------------
  procedure reconos_cond_signal(signal osif_task2os : out osif_task2os_t;
                                signal osif_os2task : in  osif_os2task_t;
                                handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_COND_SIGNAL;
    osif_task2os.request <= '1';
    osif_task2os.data    <= handle;

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;  -- reconos_cond_signal



  ---------------------------------------------------
  -- reconos_cond_signal: wake all threads waiting on condition variable
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  ---------------------------------------------------
  procedure reconos_cond_broadcast(signal osif_task2os : out osif_task2os_t;
                                   signal osif_os2task : in  osif_os2task_t;
                                   handle              : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_COND_BROADCAST;
    osif_task2os.request <= '1';
    osif_task2os.data    <= handle;

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;  -- reconos_cond_broadcast



  ---------------------------------------------------
  -- reconos_mbox_get: retrieve message from mailbox
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Blocks if mailbox is empty.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : variable to read message into
  ---------------------------------------------------
  procedure reconos_mbox_get(variable completed    : out boolean;
                             variable success      : out boolean;
                             signal   osif_task2os : out osif_task2os_t;
                             signal   osif_os2task : in  osif_os2task_t;
                             handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MBOX_GET;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;
    data                 := (others => '0');

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;
		
		when 1 => null;

      when 2 =>
        completed := true;
--        if osif_os2task.data = C_RECONOS_FAILURE then
	if osif_os2task.valid = '0' then
          success := false;
        else
          success := true;
          data := osif_os2task.data;
        end if;
        
      when C_STEP_RESUME =>
          -- wait step for resuming

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mbox_get



  ---------------------------------------------------
  -- reconos_mbox_get_s: retrieve message from mailbox into a signal
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Blocks if mailbox is empty.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : signal to read message into
  ---------------------------------------------------
  procedure reconos_mbox_get_s(variable completed    : out boolean;
                               variable success      : out boolean;
                               signal   osif_task2os : out osif_task2os_t;
                               signal   osif_os2task : in  osif_os2task_t;
                               handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                               signal   data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
    variable tmp         : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    variable done        : boolean;
    variable success_tmp : boolean;
  begin
    
    reconos_mbox_get(done, success_tmp, osif_task2os, osif_os2task, handle, tmp);
    data      <= tmp;
    completed := done;
    success   := success_tmp;

  end;  -- reconos_mbox_get_s




  ---------------------------------------------------
  -- reconos_mbox_tryget: retrieve message from mailbox, if available
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Returns immediately (non-blocking). If mailbox is empty,
  -- success is '0'.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : variable to read message into
  ---------------------------------------------------
  procedure reconos_mbox_tryget(variable completed    : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MBOX_TRYGET;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;
    data                 := (others => '0');

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;
		
		when 1 => null;		-- wait state for hardware FIFO access

      when 2 =>
        completed := true;
        if osif_os2task.valid = '0' then
          success := false;
        else
          success := true;
          data := osif_os2task.data;
        end if;
        
      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mbox_tryget


  ---------------------------------------------------
  -- reconos_mbox_tryget_s: retrieve message from mailbox, if available,
  --                        into a signal
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Returns immediately (non-blocking). If mailbox is empty,
  -- success is '0'.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : signal to read message into
  ---------------------------------------------------
  procedure reconos_mbox_tryget_s(variable completed    : out boolean;
                                  variable success      : out boolean;
                                  signal   osif_task2os : out osif_task2os_t;
                                  signal   osif_os2task : in  osif_os2task_t;
                                  handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                  signal   data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
    variable tmp         : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    variable done        : boolean;
    variable success_tmp : boolean;
  begin
    
    reconos_mbox_tryget(done, success_tmp, osif_task2os, osif_os2task, handle, tmp);
    data      <= tmp;
    completed := done;
    success   := success_tmp;

  end;  -- reconos_mbox_tryget_s


  ---------------------------------------------------
  -- reconos_mbox_put: send message to a mailbox
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Blocks, if mailbox full.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : variable to read message into
  ---------------------------------------------------
  procedure reconos_mbox_put(variable completed    : out boolean;
                             variable success      : out boolean;
                             signal   osif_task2os : out osif_task2os_t;
                             signal   osif_os2task : in  osif_os2task_t;
                             handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             data                  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MBOX_PUT;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;
      
      when 1 => osif_task2os.data <= data;

      when 2 =>
        completed := true;
--        if osif_os2task.data = C_RECONOS_FAILURE then
	if osif_os2task.valid = '0' then
          success := false;
        else
          success := true;
        end if;
        
      when C_STEP_RESUME =>
          -- wait step for resuming

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mbox_put


  ---------------------------------------------------
  -- reconos_mq_receive: receive message from a message queue
  --
  -- The message is stored in local bram
  -- Blocks, if mailbox is empty.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : handle of the mq
  -- offset      : byte offset of the message in local ram
  -- length      : length of the message in bytes
  ---------------------------------------------------
  procedure reconos_mq_receive(variable completed    : out boolean;
                             variable success      : out boolean;
                             signal   osif_task2os : out osif_task2os_t;
                             signal   osif_os2task : in  osif_os2task_t;
                             handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             offset                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             length                : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MQ_RECEIVE;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;
      
      -- hack: save one cycle by packing offset and length in one word; assume C_OSIF_DATA_WIDTH = 32
      when 1 => osif_task2os.data <= offset(16 to 31) & X"0000";

      when 2 =>
        completed := true;
	length := osif_os2task.data;
	if osif_os2task.valid = '0' then
          success := false;
        else
          success := true;
        end if;
        
      when C_STEP_RESUME =>
          -- wait step for resuming

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mq_receive


  ---------------------------------------------------
  -- reconos_mq_send: send message to a message queue
  --
  -- The message is stored in local bram
  -- Blocks, if mailbox is full.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- offset      : byte offset of the message in local ram
  -- length      : length of the message in bytes
  ---------------------------------------------------
  procedure reconos_mq_send(variable completed    : out boolean;
                             variable success      : out boolean;
                             signal   osif_task2os : out osif_task2os_t;
                             signal   osif_os2task : in  osif_os2task_t;
                             handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             offset                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                             length                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MQ_SEND;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;
      
      -- hack: save one cycle by packing offset and length in one word; assume C_OSIF_DATA_WIDTH = 32
      when 1 => osif_task2os.data <= offset(16 to 31) & length(16 to 31);

      when 2 =>
        completed := true;
	if osif_os2task.valid = '0' then
          success := false;
        else
          success := true;
        end if;
        
      when C_STEP_RESUME =>
          -- wait step for resuming

      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mq_send


  ---------------------------------------------------
  -- reconos_mbox_tryput: send message to a mailbox, if possible
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Returns immediately (non-blocking). If mailbox is full,
  -- success is '0'.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : variable to read message into
  ---------------------------------------------------
  procedure reconos_mbox_tryput(variable completed    : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                data                  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MBOX_TRYPUT;
    osif_task2os.request <= '1';
    completed            := false;
    success              := false;

    case osif_os2task.step is
      when 0 => osif_task2os.data <= handle;
      
      when 1 => osif_task2os.data <= data;

      when 2 =>
        completed := true;
        if osif_os2task.valid = '0' then
          success := false;
        else
          success := true;
        end if;
        
      when others => osif_task2os.error <= '1';  -- this shouldn't happen
    end case;
  end;  -- reconos_mbox_tryput


  ---------------------------------------------------
  -- reconos_mbox_tryget_local: retrieve message from local mailbox, if available
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Returns immediately (non-blocking). If mailbox is empty,
  -- success is '0'.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : variable to read message into
  ---------------------------------------------------
  procedure reconos_mbox_tryget_local(variable completed : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                variable data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MBOX_TRYGET_LOCAL;
    osif_task2os.request <= '1';
	 success := false;
	 data := X"AFFEDEAD";
	 completed := false;
	 
	 case osif_os2task.step is
		when 0 => null;
		
		when 1 => null;
			
		when 2 =>
			if osif_os2task.valid = '1' then
				success              := true;
			else
				success              := false;
			end if;
			data                 := osif_os2task.data;
			completed := true;

      when others => osif_task2os.error <= '1';  -- this shouldn't happen

	 end case;

  end;  -- reconos_mbox_tryget_local



  ---------------------------------------------------
  -- reconos_mbox_tryget_local_s: retrieve message from mailbox, if available,
  --                        into a signal
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Returns immediately (non-blocking). If mailbox is empty,
  -- success is '0'.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : signal to read message into
  ---------------------------------------------------
  procedure reconos_mbox_tryget_local_s(variable completed : out boolean;
                                  variable success      : out boolean;
                                  signal   osif_task2os : out osif_task2os_t;
                                  signal   osif_os2task : in  osif_os2task_t;
                                  handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                  signal   data         : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
    variable tmp         : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    variable success_tmp : boolean;
	 variable done : boolean;
  begin
    
    reconos_mbox_tryget_local(done, success_tmp, osif_task2os, osif_os2task, handle, tmp);
    data      <= tmp;
    completed := done;
    success   := success_tmp;

  end;  -- reconos_mbox_tryget_local_s



  ---------------------------------------------------
  -- reconos_mbox_tryput_local: send message to a mailbox, if possible
  --
  -- A message consists of 32 bits which may point to
  -- a memory location.
  -- Returns immediately (non-blocking). If mailbox is full,
  -- success is '0'.
  --
  --     !!! multi-cycle command, see MultiCycleCommands in the ReconOS Wiki !!!
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : '1' if successfully retrieved, else '0'
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- handle      : condition variable to signal on
  -- data        : variable to read message into
  ---------------------------------------------------
  procedure reconos_mbox_tryput_local(variable completed : out boolean;
                                variable success      : out boolean;
                                signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                handle                : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
                                data                  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_MBOX_TRYPUT_LOCAL;
    osif_task2os.data <= data;
    osif_task2os.request <= '1';
	 success := false;
	 completed := false;
	 
	 case osif_os2task.step is
		when 0 => 
			
		when 1 =>
			if osif_os2task.valid = '1' then
				success              := true;
			else
				success              := false;
			end if;
			completed := true;

      when others => osif_task2os.error <= '1';  -- this shouldn't happen

	 end case;
  end;  -- reconos_mbox_tryput_local




  ---------------------------------------------------
  -- reconos_thread_exit: terminate a hardware thread
  --
  -- This call blocks the hardware thread and causes
  -- the corresponding delegate thread to terminate.
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- retval      : return value
  ---------------------------------------------------
  procedure reconos_thread_exit(signal   osif_task2os : out osif_task2os_t;
                                signal   osif_os2task : in  osif_os2task_t;
                                         retval       : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)) is
  begin
    osif_task2os.command <= OSIF_CMD_THREAD_EXIT;
    osif_task2os.data    <= retval;
    osif_task2os.request <= '1';

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;




  ---------------------------------------------------
  -- reconos_thread_yield: tell the operating system
  --                       that the current thread has
  --                       no internal state and could be
  --                       interrupted and removed
  --
  -- If there are no HW threads waiting to execute,
  -- this is essentially a NOOP, and will not cause
  -- an interrupt. Therefore, this call is safe to
  -- be invoked every time the thread has no internal
  -- state, since it incurs very little overhead.
  -- This implies a call to reconos_flag_yield().
  --
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- saved_state_enc: binary encoded value of OSIF
  --                 sync FSM state (where to resume)
  ---------------------------------------------------
  procedure reconos_thread_yield(signal   osif_task2os : out osif_task2os_t;
                                 signal   osif_os2task : in  osif_os2task_t;
                                 saved_state_enc        : in  reconos_state_enc_t) is

  begin
    osif_task2os.command <= OSIF_CMD_THREAD_YIELD;
    osif_task2os.data    <= (others => '0');
    osif_task2os.request <= '1';
    reconos_flag_yield( osif_task2os, osif_os2task, saved_state_enc );

    if osif_os2task.step /= 0 then
      osif_task2os.error <= '1';
    end if;
  end;

  ---------------------------------------------------
  -- reconos_thread_resume: ask the operating system
  --      whether this thread has just been resumed
  --
  -- completed   : goes '1' when last cycle completed
  -- success     : true, if thread was resumed
  --               false, if it was newly created
  -- osif_task2os: OSIF task2os channel
  -- osif_os2task: OSIF os2task channel
  -- resume_state_enc: binary encoded value of OSIF
  --                 sync FSM state (where to resume)
  ---------------------------------------------------
  procedure reconos_thread_resume(variable completed : out boolean;
                                 variable success         : out boolean;
                                 signal   osif_task2os     : out osif_task2os_t;
                                 signal   osif_os2task     : in  osif_os2task_t;
                                 variable resume_state_enc : out reconos_state_enc_t) is

  begin
    osif_task2os.command <= OSIF_CMD_THREAD_RESUME;
    osif_task2os.data <= (others => '0');
    osif_task2os.request <= '1';
    success := false;
    completed := false;
    resume_state_enc     := (others => '0');

    case osif_os2task.step is
        when 0 => 

        when 1 =>
            if osif_os2task.valid = '1' then
                success              := true;
                resume_state_enc     := osif_os2task.data(0 to C_OSIF_STATE_ENC_WIDTH-1);
            else
                success              := false;
                resume_state_enc     := (others => '0');
            end if;
            completed := true;

        when others => osif_task2os.error <= '1';  -- this shouldn't happen

    end case;
  end;

  ---------------------------------------------------
  -- reduce_or: or all input signals together
  --
  -- input: vector of signals to reduce
  -- len  : length of input vector
  -- 
  -- Returns result of OR operation
  ---------------------------------------------------
  function reduce_or (input : std_logic_vector) return std_logic is

    variable result : std_logic := '0';

  begin
    for i in input'high to input'low loop
      result := result or input(i);
    end loop;
    return result;
  end;


end reconos_pkg;
