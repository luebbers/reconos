--!
--! \file osif_core.vhd
--!
--! OSIF logic and interface to IPIF
--!
--! The osif_core contains processes for OS request handling. Also, it
--! instantiates the DCR slave module, which manages communication 
--! between the CPU and the OSIF.
--!
--! There are two sets of registers, one for each direction (logic to bus
--! and bus to logic). Each set has the a register for command, data, 
--! and extended data; the bus to logic set has another handshake register
--! indicating an incoming request from the DCR bus.
--!
--! Communication with the user task goes through the osif_task2os and
--! osif_os2task data structures, which are converted to std_logic_vectors
--! at the module interface, because XPS cannot handle VHDL records. An
--! incoming request from a task to perform an operating system call
--! is signalled by the request line of the task2os record. Requests can be
--! divided into two categories: 
--!
--!    - those that are handled in hardware without microprocessor 
--!      involvement (like shared memory accesses), and
--!    - those that have to be handled in the microprocessor
--!
--! The first are handled directly within osif_core (and its submodules),
--! whereas the latter cause an interrupt to the microprocessor, preempt
--! any running processes there and wake up a software thread, which then
--! acts on behalf of the hardware thread.
--!
--!
--!
--!                                                     
--!                                                      
--!                    Memory bus interface                 fifo_manager
--!   Memory              (master/slave)                   
--!    Bus     <----------------------------+                     ^
--! (e.g. PLB)                              |                     |
--!                                         |    +----------------+
--!                                  _______|____|____ 
--!                                 |                 |
--!   clk, reset ------------------>| command_decoder |
--!                                 |_________________|
--!                                         |    |
--!                                         |    +----------------+
--!  Hardware                               |                _____|__________
--!   Thread  <-----------------------------+               |                |
--!             Hardware Thread Control Interface           | dcr_slave_regs |
--!                                                         |________________|
--!                                                                ^
--!                                                                |
--!                                                                V
--!                                                              D C R
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       08.12.2008
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
-- Major changes
-- 01.08.2006  Enno Luebbers     File created (from opb_reconos_slot_v1_00_c)
-- 03.08.2006  Enno Luebbers     Added PLB bus master (moved to v1.01.a),
--                               removed BRAM interface
-- 04.08.2006  Enno Luebbers     moved user_logic to toplevel
-- 07.08.2006  Enno Luebbers     moved logic to separate modules
--                               (bus_master, bus_slave_regs)
-- xx.10.2007  Enno Luebbers     added local FIFO manager
-- 23.11.2007  Enno Luebbers     moved slave registers to DCR
-- 08.12.2008  Enno Luebbers     modularized (moved memory bus controller
--                               to separate module)
-- 10.12.2008  Enno Luebbers     moved and renamed from user_logic to osif_core
--
--*************************************************************************/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library proc_common_v1_00_b;
--use proc_common_v1_00_b.proc_common_pkg.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

library osif_core_v2_03_a;
use osif_core_v2_03_a.all;

entity osif_core is
    generic
    (
        -- Bus protocol parameters
        C_AWIDTH              :     integer          := 32;
        C_DWIDTH              :     integer          := 32;
        C_PLB_AWIDTH          :     integer          := 32;
        C_PLB_DWIDTH          :     integer          := 64;
        C_NUM_CE              :     integer          := 2;
        C_BURST_AWIDTH        :     integer          := 13;  -- 1024 x 64 Bit = 8192 Bytes = 2^13 Bytes
        C_THREAD_RESET_CYCLES :     natural          := 10;  -- number of cycles the thread reset is held
        C_FIFO_DWIDTH         :     integer          := 32;
        C_BURSTLEN_WIDTH      :     integer          := 5;  -- max 16x64 bit bursts
        C_DCR_BASEADDR        :     std_logic_vector := "1111111111";
        C_DCR_HIGHADDR        :     std_logic_vector := "0000000000";
        C_DCR_AWIDTH          :     integer          := 10;
        C_DCR_DWIDTH          :     integer          := 32;
        C_TLB_TAG_WIDTH       :     integer          := 20;
        C_TLB_DATA_WIDTH      :     integer          := 21;
        C_ENABLE_MMU          :     boolean          := true;
        C_MMU_STAT_REGS       :     boolean          := false;
        C_DCR_ILA             :     integer          := 0  -- 0: no debug ILA, 1: include debug chipscope ILA for DCR debugging
    );
    port
    (
        sys_clk               : in  std_logic;
        sys_reset             : in  std_logic;
        interrupt             : out std_logic;
        busy                  : out std_logic;
        blocking              : out std_logic;
        -- task interface
        task_clk              : out std_logic;
        task_reset            : out std_logic;
        osif_os2task_vec      : out std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
        osif_task2os_vec      : in  std_logic_vector(0 to C_OSIF_TASK2OS_REC_WIDTH-1);
        
        -- FIFO manager access signals
        -- left (read) FIFO
        o_fifomgr_read_remove : out std_logic;
        i_fifomgr_read_data   : in std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifomgr_read_wait   : in std_logic;
        -- right (write) FIFO
        o_fifomgr_write_add   : out std_logic;
        o_fifomgr_write_data  : out std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifomgr_write_wait  : in std_logic;
        
        -- memory access signals
        o_mem_singleData  : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        i_mem_singleData  : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        o_mem_localAddr   : out std_logic_vector(0 to C_AWIDTH-1);
        o_mem_targetAddr  : out std_logic_vector(0 to C_AWIDTH-1);
        o_mem_singleRdReq : out std_logic;
        o_mem_singleWrReq : out std_logic;
        o_mem_burstRdReq  : out std_logic;
        o_mem_burstWrReq  : out std_logic;
        o_mem_burstLen    : out std_logic_vector(0 to C_BURSTLEN_WIDTH-1);
        
        i_mem_busy   : in std_logic;
        i_mem_rdDone : in std_logic;
        i_mem_wrDone : in std_logic;
        
        
        -- bus macro control
        o_bm_enable : out std_logic;
        
        -- tlb interface
        i_tlb_rdata    : in  std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
        o_tlb_wdata    : out std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
        o_tlb_tag      : out std_logic_vector(C_TLB_TAG_WIDTH - 1 downto 0);
        i_tlb_match    : in  std_logic;
        o_tlb_we       : out std_logic;
        i_tlb_busy     : in  std_logic;
        o_tlb_request  : out std_logic;
        
        -- dcr bus protocol ports
        o_dcrAck   : out std_logic;
        o_dcrDBus  : out std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrABus  : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
        i_dcrDBus  : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrRead  : in  std_logic;
        i_dcrWrite : in  std_logic;
        i_dcrICON  : in  std_logic_vector(35 downto 0)

    );
end entity osif_core;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of osif_core is


--#################################################################################################################
    
    
    -------
    -- OS signals
    -------
    -- between os and task
    signal osif_os2task : osif_os2task_t;
    signal osif_task2os : osif_task2os_t;
    
    -- FIXME: is there a better way than a handshake register?
    signal os2task_newcmd     : std_logic := '0';
    signal request_blocking   : std_logic := '0';
    signal request_unblocking : std_logic := '0';
    -- signal os2task_reset : std_logic := '0';
    signal task2os_error      : std_logic := '0';  -- FIXME: this is being ignored
    
    -- dirty flag signals indicating unread data in read registers
    signal slv_busy        : std_logic;
    signal post_sw_request : std_logic;
    
    --
    signal cdec_post       : std_logic;
    signal mmu_post        : std_logic;
    signal mmu_exception   : std_logic;
    signal cdec_command : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1)  := (others => '0');  -- task2os command
    signal cdec_data    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');  -- task2os data
    signal cdec_datax   : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');  -- task2os data
        
    
    ---------
    -- slave register signals (put on DCR)
    ---------
    signal slv_bus2osif_command : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);
    signal slv_bus2osif_data    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    signal slv_bus2osif_done    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    signal slv_osif2bus_command : std_logic_vector(0 to C_OSIF_CMD_WIDTH-1)  := (others => '0');  -- task2os command
    signal slv_osif2bus_flags : std_logic_vector(0 to C_OSIF_FLAGS_WIDTH-1);
    signal slv_osif2bus_saved_state_enc : std_logic_vector(0 to C_OSIF_STATE_ENC_WIDTH-1);
    signal slv_osif2bus_saved_step_enc : std_logic_vector(0 to C_OSIF_STEP_ENC_WIDTH-1);
    signal slv_osif2bus_data    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');  -- task2os data
    signal slv_osif2bus_datax   : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');  -- task2os data
    signal slv_osif2bus_signature : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');  -- hwthread signature
    
    ---------
    -- status registers
    ---------
    signal thread_init_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);  -- thread data (passed at initialization)
    
    
    ---------
    -- local FIFO handles (used for FIFO message routing)
    ---------
    signal fifo_read_handle  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    signal fifo_write_handle : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    
    ---------
    -- thread reset counter
    ---------
    signal reset_counter  : natural range 0 to C_THREAD_RESET_CYCLES-1 := C_THREAD_RESET_CYCLES-1;
    signal request_reset  : std_logic;
    signal thread_reset_i : std_logic;
    
    
    ---------
    -- signals for cooperative multithreading
    ---------
    signal thread_is_resuming : std_logic;
    signal yield_request  : std_logic;          -- request from OS to yield
    signal yield_flag     : std_logic;          -- if '!', thread can yield
    signal saved_state_enc : reconos_state_enc_t;
    signal saved_step_enc : reconos_step_enc_t;
    signal resume_state_enc : reconos_state_enc_t;
    signal resume_step_enc : reconos_step_enc_t;
    
    -- mmu diagnosis
    signal mmu_tlb_miss_count   : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
    signal mmu_tlb_hit_count    : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
    signal mmu_page_fault_count : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
    
    signal mmu_state_fault            : std_logic;
    signal mmu_state_access_violation : std_logic;
    
    -- mmu configuration and state
    signal mmu_setpgd                 : std_logic;
    signal mmu_repeat                 : std_logic;
    signal mmu_config_data            : std_logic_vector(0 to 31); 
    
    signal cdec_srrq : std_logic;
    signal cdec_swrq : std_logic;
    signal cdec_brrq : std_logic;
    signal cdec_bwrq : std_logic;
    signal cdec_laddr : std_logic_vector(31 downto 0);
    signal cdec_raddr : std_logic_vector(31 downto 0);
    
    signal mmu_data   : std_logic_vector(31 downto 0);
    signal mmu_busy   : std_logic;
    signal mmu_wrDone : std_logic;
    signal mmu_rdDone : std_logic;
begin

    enable_mmu : if C_ENABLE_MMU generate
        handle_mmu_exception : process(sys_clk, sys_reset, mmu_exception)
            variable step : integer range 0 to 1;
        begin
            if sys_reset = '1' then
                mmu_post <= '0';
                step := 0;
            elsif rising_edge(sys_clk) then
                case step is
                    when 0 =>
                        if mmu_exception = '1' then
                            mmu_post <= '1';
                            step := 1;
                        end if;
    
                    when 1 =>
                        mmu_post <= '0';
                        if mmu_exception = '0' then
                            step := 0;
                        end if;
                end case;
            end if;
        end process;
        
        post_mux : process(mmu_state_fault, mmu_exception,cdec_command, cdec_data, cdec_datax, mmu_data, cdec_post, mmu_post)
        begin
            if mmu_exception = '0' then
                slv_osif2bus_command <= cdec_command;
                slv_osif2bus_data    <= cdec_data;
                slv_osif2bus_datax   <= cdec_datax;
                post_sw_request      <= cdec_post;
            else
                if mmu_state_fault = '1' then
                    slv_osif2bus_command <= OSIF_CMD_MMU_FAULT;
                else
                    slv_osif2bus_command <= OSIF_CMD_MMU_ACCESS_VIOLATION;
                end if;
                
                slv_osif2bus_data    <= mmu_data;
                slv_osif2bus_datax   <= X"22221111";
                post_sw_request      <= mmu_post;
                        
            end if;
        end  process;
        
        mmu_exception <= mmu_state_fault or mmu_state_access_violation;
        --post_sw_request <= cdec_post or mmu_post;
        interrupt <= post_sw_request or cdec_post;
        
        i_mmu : entity osif_core_v2_03_a.mmu
        generic map
        (
            --C_BASEADDR            => C_BASEADDR,
            C_AWIDTH              => C_AWIDTH,
            C_DWIDTH              => C_DWIDTH,
            C_MMU_STAT_REGS       => C_MMU_STAT_REGS
        )
        
        port map
        (
            clk               => sys_clk,
            rst               => sys_reset,
            
            -- incoming memory interface
            i_swrq            => cdec_swrq, --
            i_srrq            => cdec_srrq, --
            i_bwrq            => cdec_bwrq, --
            i_brrq            => cdec_brrq, --
            
            i_addr            => cdec_raddr,--
            i_laddr           => cdec_laddr,--
            o_data            => mmu_data, --
            
            o_busy            => mmu_busy,--
            o_rdone           => mmu_rdDone,--
            o_wdone           => mmu_wrDone,--
            
            -- outgoing memory interface
            o_swrq            => o_mem_singleWrReq,
            o_srrq            => o_mem_singleRdReq,
            o_bwrq            => o_mem_burstWrReq,
            o_brrq            => o_mem_burstRdReq,
                    
            o_addr            => o_mem_targetAddr,
            o_laddr           => o_mem_localAddr,
            i_data            => i_mem_singleData,
            
            i_busy            => i_mem_busy,
            i_rdone           => i_mem_rdDone,
            i_wdone           => i_mem_wrDone,
            
            -- configuration interface
            i_cfg             => mmu_config_data,
            i_setpgd          => mmu_setpgd,
            i_repeat          => mmu_repeat,
            
            -- interrupts
            o_state_fault            => mmu_state_fault,
            o_state_access_violation => mmu_state_access_violation,
    
            -- tlb interface
            i_tlb_match       => i_tlb_match,
            i_tlb_busy        => i_tlb_busy,
            --i_tlb_wdone       => i_tlb_wdone,
            o_tlb_we          => o_tlb_we,
            i_tlb_data        => i_tlb_rdata,
            o_tlb_data        => o_tlb_wdata,
            o_tlb_tag         => o_tlb_tag,
            o_tlb_request     => o_tlb_request,
        
            -- diagnosis
            o_tlb_miss_count    => mmu_tlb_miss_count,
            o_tlb_hit_count     => mmu_tlb_hit_count,
            o_page_fault_count  => mmu_page_fault_count
        );
    end generate;
    
    disable_mmu : if not C_ENABLE_MMU generate
        interrupt <= cdec_post;
        o_mem_singleWrReq <= cdec_swrq;
        o_mem_singleRdReq <= cdec_srrq;
        o_mem_burstWrReq  <= cdec_bwrq;
        o_mem_burstRdReq  <= cdec_brrq;
        o_mem_targetAddr  <= cdec_raddr;
        o_mem_localAddr   <= cdec_laddr;
        mmu_data          <= i_mem_singleData;
        mmu_busy          <= i_mem_busy;
        mmu_rdDone        <= i_mem_rdDone;
        mmu_wrDone        <= i_mem_wrDone;
        mmu_config_data            <= (others => '0');
        mmu_setpgd                 <= '0';
        mmu_repeat                 <= '0';
        mmu_state_fault            <= '0';
        mmu_state_access_violation <= '0';
        mmu_tlb_miss_count         <= (others => '0');
        mmu_tlb_hit_count          <= (others => '0');
        mmu_page_fault_count       <= (others => '0');
        o_tlb_we                   <= '0';
        o_tlb_wdata                <= (others => '0');
        o_tlb_tag                  <= (others => '0');
        o_tlb_request              <= '0';
    end generate;
    -- ################### MODULE INSTANTIATIONS ####################
    
    
    -----------------------------------------------------------------------
    -- dcr_slave_regs_inst: DCR bus slave instatiation
    --
    -- Handles access to the various registers.
    -- NOTE: While slv_bus2osif_* signals are latched by bus_slave_regs,
    --       the slv_osif2bus_* signals MUST BE STABLE until the transaction
    --       is complete (busy goes low for s/w OS requests or the shm bus
    --       bus master transaction completes).
    -----------------------------------------------------------------------
    dcr_slave_regs_inst : entity osif_core_v2_03_a.dcr_slave_regs
    generic map (
        C_DCR_BASEADDR       => C_DCR_BASEADDR,
        C_DCR_HIGHADDR       => C_DCR_HIGHADDR,
        C_DCR_AWIDTH         => C_DCR_AWIDTH,
        C_DCR_DWIDTH         => C_DCR_DWIDTH,
        C_NUM_REGS           => 4,
        C_ENABLE_MMU         => C_ENABLE_MMU,
        C_INCLUDE_ILA        => C_DCR_ILA
    )
    port map (
        clk                  => sys_clk,
        reset                => thread_reset_i,  --sys_reset,
        o_dcrAck             => o_dcrAck,
        o_dcrDBus            => o_dcrDBus,
        i_dcrABus            => i_dcrABus,
        i_dcrDBus            => i_dcrDBus,
        i_dcrRead            => i_dcrRead,
        i_dcrWrite           => i_dcrWrite,
        i_dcrICON            => i_dcrICON,
        -- user registers
        i_osif2bus_command => slv_osif2bus_command,
        i_osif2bus_flags   => slv_osif2bus_flags,
        i_osif2bus_saved_state_enc =>  slv_osif2bus_saved_state_enc,
        i_osif2bus_saved_step_enc =>  slv_osif2bus_saved_step_enc,
        i_osif2bus_data    => slv_osif2bus_data,
        i_osif2bus_datax   => slv_osif2bus_datax,
        i_osif2bus_signature => slv_osif2bus_signature,
        o_bus2osif_command => slv_bus2osif_command,
        o_bus2osif_data    => slv_bus2osif_data,
        o_bus2osif_done    => slv_bus2osif_done,
        
        i_tlb_miss_count   => mmu_tlb_miss_count,
        i_tlb_hit_count    => mmu_tlb_hit_count,
        i_page_fault_count => mmu_page_fault_count,
        
        -- additional user interface
        o_newcmd             => os2task_newcmd,
        i_post               => post_sw_request,
        o_busy               => slv_busy
        --o_interrupt          => interrupt
    );
    
    -----------------------------------------------------------------------
    -- command_decoder_inst: command decoder instatiation
    --
    -- Handles decoding the commands from the HW thread.
    -- NOTE: the command decoder is completely asynchronous. It also
    --       handles the setting and releasing of the osif_os2task.busy
    --       and .blocking signals.
    -----------------------------------------------------------------------
    command_decoder_inst : entity osif_core_v2_03_a.command_decoder
    generic map (
        C_AWIDTH               => C_AWIDTH,
        C_DWIDTH               => C_DWIDTH,
        C_PLB_AWIDTH           => C_PLB_AWIDTH,
        C_PLB_DWIDTH           => C_PLB_DWIDTH,
        C_BURST_AWIDTH         => C_BURST_AWIDTH,
        C_FIFO_DWIDTH          => C_FIFO_DWIDTH,
        C_BURSTLEN_WIDTH       => C_BURSTLEN_WIDTH
    )
    port map (
        i_clk                  => sys_clk,
        i_reset                => thread_reset_i,  -- Bus2IP_Reset,
        i_osif                 => osif_task2os,
        o_osif                 => osif_os2task,
        o_sw_request           => cdec_post,
        i_request_blocking     => request_blocking,
        i_release_blocking     => request_unblocking,
        i_init_data            => thread_init_data,
        o_bm_my_addr           => cdec_laddr,
        o_bm_target_addr       => cdec_raddr,
        o_bm_read_req          => cdec_srrq,
        o_bm_write_req         => cdec_swrq,
        o_bm_burst_read_req    => cdec_brrq,
        o_bm_burst_write_req   => cdec_bwrq,
        o_bm_burst_length      => o_mem_burstLen,
        i_bm_busy              => mmu_busy,
        i_bm_read_done         => mmu_rdDone,
        i_bm_write_done        => mmu_wrDone,
        i_slv_busy             => slv_busy,
        i_slv_bus2osif_command => slv_bus2osif_command,
        i_slv_bus2osif_data    => slv_bus2osif_data,
        i_slv_bus2osif_shm     => mmu_data,
        o_slv_osif2bus_command => cdec_command,
        o_slv_osif2bus_data    => cdec_data,
        o_slv_osif2bus_datax   => cdec_datax,
        o_slv_osif2bus_shm     => o_mem_singleData,
        o_hwthread_signature   => slv_osif2bus_signature,
        o_fifo_read_remove     => o_fifomgr_read_remove,
        i_fifo_read_data       => i_fifomgr_read_data,
        i_fifo_read_wait       => i_fifomgr_read_wait,
        o_fifo_write_add       => o_fifomgr_write_add,
        o_fifo_write_data      => o_fifomgr_write_data,
        i_fifo_write_wait      => i_fifomgr_write_wait,
        i_fifo_read_handle     => fifo_read_handle,
        i_fifo_write_handle    => fifo_write_handle,
        
        i_resume => thread_is_resuming,
        i_yield  => yield_request,
        o_yield  => yield_flag,
        o_saved_state_enc => saved_state_enc,
        o_saved_step_enc => saved_step_enc,
        i_resume_state_enc => resume_state_enc,
        i_resume_step_enc => resume_step_enc
    
    );
    
    
    
    -- ################### CONCURRENT ASSIGNMENTS ####################
    
    -----------------------------------------------------------------------
    -- User task signal routing
    --
    -- The user task is supplied with a dedicated clock and reset signal,
    -- just in case we want to use them later.
    -----------------------------------------------------------------------
    task_clk       <= sys_clk;          --Bus2IP_Clk;
    thread_reset_i <= '1' when reset_counter > 0 else '0';
    task_reset     <= thread_reset_i;
    
    -- OSIF record to vector conversion (because EDK cannot handle records)
    osif_os2task_vec <= to_std_logic_vector(osif_os2task);
    osif_task2os     <= to_osif_task2os_t(osif_task2os_vec);
    
    -- FIXME: ignoring task error
    task2os_error <= osif_task2os.error;
    
    -- flags and yield control
    slv_osif2bus_flags <= yield_flag & "0000000";
    slv_osif2bus_saved_state_enc <= saved_state_enc;
    slv_osif2bus_saved_step_enc <= saved_step_enc;
    
    -- drive debug signals
    busy     <= osif_os2task.busy;
    blocking <= osif_os2task.blocking;
    
    
    
    -- ################### PROCESSES ####################
    
    -----------------------------------------------------------------------
    -- handle_os2task_response: Handles incoming OS commands
    --
    -- Especially the OSIF_CMD_UNBLOCK command, which signals that a
    -- blocking OS call has returned.
    -----------------------------------------------------------------------
    -- FIXME: does this have to be synchronous?
    handle_os2task_response : process(sys_clk, sys_reset)
    begin
        if sys_reset = '1' then
            request_blocking   <= '0';
            request_unblocking <= '0';
            request_reset      <= '0';
            o_bm_enable        <= '0';  -- bus macros are disabled by default!
            thread_init_data   <= (others => '0');
            thread_is_resuming <= '0';  -- per default, the thread is not resumed, but created/started
            resume_state_enc   <= (others => '0');
            resume_step_enc    <= (others => '0');
            yield_request      <= '0';
        elsif rising_edge(sys_clk) then
            
            -- also reset everything on a synchronous thread_reset!
            if thread_reset_i = '1' then
                request_blocking   <= '0';
                request_unblocking <= '0';
                request_reset      <= '0';
                --                o_bm_enable        <= '0';  -- do not disable bus macros on a thread reset (would break signature read)
                thread_init_data   <= (others => '0');
                thread_is_resuming <= '0';  -- per default, the thread is not resumed, but created/started
                resume_state_enc   <= (others => '0');
                resume_step_enc    <= (others => '0');
                --    yield_request      <= '0';        -- yield_request is persistent across resets!
            end if;
            
            request_blocking   <= '0';
            request_unblocking <= '0';
            request_reset      <= '0';
            mmu_setpgd       <= '0';
            mmu_repeat       <= '0';
            
            if os2task_newcmd = '1' then
                case slv_bus2osif_command(0 to C_OSIF_CMD_WIDTH-1) is
                    when OSIF_CMD_UNBLOCK =>
                        request_unblocking <= '1';
                        
                    when OSIF_CMD_SET_INIT_DATA =>
                        thread_init_data     <= slv_bus2osif_data;
                        
                    when OSIF_CMD_RESET =>
                        request_blocking <= '1';
                        request_reset <= '1';
                        
                    when OSIF_CMD_BUSMACRO =>
                        if slv_bus2osif_data = OSIF_DATA_BUSMACRO_DISABLE then -- disable
                            o_bm_enable <= '0';
                        else
                            o_bm_enable <= '1';  -- enable
                        end if;
                    
                    when OSIF_CMD_SET_FIFO_READ_HANDLE =>
                        fifo_read_handle <= slv_bus2osif_data;
                    
                    when OSIF_CMD_SET_FIFO_WRITE_HANDLE =>
                        fifo_write_handle <= slv_bus2osif_data;
                    
                    when OSIF_CMD_SET_RESUME_STATE =>
                        resume_state_enc   <= slv_bus2osif_data(0 to C_OSIF_STATE_ENC_WIDTH-1);
                        resume_step_enc    <= slv_bus2osif_data(C_OSIF_STATE_ENC_WIDTH to C_OSIF_STATE_ENC_WIDTH+C_OSIF_STEP_ENC_WIDTH-1);
                        thread_is_resuming <= '1';
                        
                    -- FIXME: do we need this?
                    when OSIF_CMD_CLEAR_RESUME_STATE => 
                        resume_state_enc <= (others => '0');
                        resume_step_enc  <= (others => '0');
                        thread_is_resuming <= '0';
                        
                    when OSIF_CMD_REQUEST_YIELD =>
                        yield_request <= '1';
                    
                    when OSIF_CMD_CLEAR_YIELD =>
                        yield_request <= '0';
                    
                    when OSIF_CMD_MMU_SETPGD =>
                        mmu_setpgd <= '1';
                        mmu_config_data <= slv_bus2osif_data;
                        
                    when OSIF_CMD_MMU_REPEAT =>
                        mmu_repeat <= '1';
                        
                    when others =>
                    
                end case;
            end if;
        end if;
    end process;
    
    
    -----------------------------------------------------------------------
    -- reset_proc: handles reset of software thread
    -----------------------------------------------------------------------
    reset_proc: process(sys_clk, sys_reset)
    begin
        if sys_reset = '1' then
            reset_counter <= C_THREAD_RESET_CYCLES-1;
        elsif rising_edge(sys_clk) then
            if request_reset = '1' then
                reset_counter <= C_THREAD_RESET_CYCLES-1;
            elsif reset_counter > 0 then
                reset_counter <= reset_counter - 1;
            end if;
        end if;
    end process;
    
    
    

end IMP;
