--!
--! \file command_decoder.vhd
--!
--! Handles commands coming from the HW thread and their return values
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       04.07.2007
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- Copyright (c) 2008, Computer Engineering Group, University of
-- Paderborn. 
-- 
-- For details regarding licensing and redistribution, see COPYING.  If
-- you did not receive a COPYING file as part of the distribution package
-- containing this file, you can get it at http://www.reconos.de/COPYING.
-- 
-- This software is provided "as is" without express or implied warranty,
-- and with no claim as to its suitability for any particular purpose.
-- The copyright owner or the contributors shall not be liable for any
-- damages arising out of the use of this software.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major changes
-- 04.07.2007  Enno Luebbers        File created
-- 11.07.2007  Enno Luebbers        added mutex commands
-- 27.07.2007  Enno Luebbers        added condvar commands
-- 25.09.2007  Enno Luebbers               added mbox commands
-- 15.10.2007  Enno Luebbers        added hardware mbox routing
-- 09.02.2008  Enno Luebbers        added thread_exit() call
-- 19.04.2008  Enno Luebbers        added handshaking between command_decoder
--                                  and HW thread
-- 23.04.2008  Enno Luebbers        streamlined handshaking
--
------------------------------------------------------------------------------
--
-- Handshaking description between command_decoder and hardware threads:
--
-- To allow the command decoder to block the hardware thread's FSM, the 
-- busy or blocking signal must arrive at the hardware thread before the
-- next step of its FSM is executed. This was previously (up to around
-- rev. 570) done by clocking the command decoder on the falling edge.
-- This introduced timing difficulties, especially when using partial
-- reconfiguration.
-- Now, the command_decoder ist again clocked on the rising edge of the 
-- clock. Therefore, the hardware thread's FSM must wait one cycle at
-- every request to allow a possible busy/blocking signal to be
-- synchronously asserted by the command decoder, trading performance
-- for relaxed timing constraints. This is achieved by latching the
-- busy signal on an incoming request inside the thread (hw_task.vhd),
-- until an ack arrives from the command decoder.
-- The request_seen signal doubles as the acknowledge signal to the thread.


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity command_decoder is
    generic (
        C_BASEADDR       :    std_logic_vector := X"FFFFFFFF";
        -- Bus protocol parameters
        C_AWIDTH         :    integer          := 32;
        C_DWIDTH         :    integer          := 32;
        C_PLB_AWIDTH     :    integer          := 32;
        C_PLB_DWIDTH     :    integer          := 64;
        C_BURST_AWIDTH   :    integer          := 13;  -- 1024 x 64 Bit = 8192 Bytes = 2^13 Bytes
        C_BURST_BASEADDR :    std_logic_vector := X"FFFFFFFF";
        C_FIFO_DWIDTH    :    integer          := 32
        );
    port (
        i_clk            : in std_logic;
        i_reset          : in std_logic;
        i_osif           : in osif_task2os_t;

        o_osif             : out osif_os2task_t;
        --o_step       : out natural range 0 to C_MAX_MULTICYCLE_STEPS-1;
        o_sw_request       : out std_logic;
        i_request_blocking : in  std_logic;
        i_release_blocking : in  std_logic;
        i_init_data        : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);

        -- bus_master interface
        o_bm_my_addr         : out std_logic_vector(0 to C_AWIDTH-1);
        o_bm_target_addr     : out std_logic_vector(0 to C_AWIDTH-1);
        o_bm_read_req        : out std_logic;  -- single word
        o_bm_write_req       : out std_logic;  -- single word
        o_bm_burst_read_req  : out std_logic;  -- n x 64Bit burst
        o_bm_burst_write_req : out std_logic;  -- n x 64Bit burst
        o_bm_burst_length    : out std_logic_vector(0 to 4);  -- number of burst beats (n)
        i_bm_busy            : in  std_logic;
        i_bm_read_done       : in  std_logic;
        i_bm_write_done      : in  std_logic;

        -- slave registers interface
        i_slv_busy             : in  std_logic;
        i_slv_bus2osif_command : in  std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);
        i_slv_bus2osif_data    : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        i_slv_bus2osif_shm     : in  std_logic_vector(0 to C_DWIDTH-1);
        o_slv_osif2bus_command : out std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);
        o_slv_osif2bus_data    : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        o_slv_osif2bus_datax   : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        o_slv_osif2bus_shm     : out std_logic_vector(0 to C_DWIDTH-1);
        o_hwthread_signature   : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) ;

        -- fifo manager interface
        o_fifo_read_remove : out std_logic;
        i_fifo_read_data   : in  std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifo_read_wait   : in  std_logic;
        o_fifo_write_add   : out std_logic;
        o_fifo_write_data  : out std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifo_write_wait  : in  std_logic;

        -- fifo handles
        i_fifo_read_handle  : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        i_fifo_write_handle : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);

        -- yield/resume interface
        i_resume            : in std_logic;
        i_yield             : in std_logic;     -- OS requests yield
        o_yield             : out std_logic;    -- thread yields
        o_saved_state_enc   : out reconos_state_enc_t;
        o_saved_step_enc    : out reconos_step_enc_t;
        i_resume_state_enc  : in reconos_state_enc_t;
        i_resume_step_enc   : in reconos_step_enc_t

        );
end command_decoder;



architecture behavioral of command_decoder is

    signal step_enable  : std_logic                                   := '0';
    signal step_clear   : std_logic                                   := '0';
    signal step         : natural range 0 to C_MAX_MULTICYCLE_STEPS-1 := 0;
    signal blocking     : std_logic                                   := '1';
    signal busy         : std_logic                                   := '0';
    signal request_seen : std_logic                                   := '0';
    signal failure      : std_logic                                   := '0';
    -- fifo routing
    signal fifo_local   : std_logic                                   := '0';

begin



    o_osif.step       <= step;
    o_osif.busy       <= busy or i_slv_busy or i_bm_busy;-- or i_osif.request;
    o_osif.blocking   <= blocking;
    o_osif.ack        <= request_seen;
    o_osif.req_yield  <= i_yield;
    o_osif.command    <= i_slv_bus2osif_command;
    o_saved_state_enc <= reconos_state_enc_t(i_osif.saved_state_enc);
    o_saved_step_enc  <= reconos_step_enc_t(TO_UNSIGNED(step, C_OSIF_STEP_ENC_WIDTH));

    o_fifo_write_data <= i_osif.data;

    retval_mux : process(i_osif, step,
                         i_slv_bus2osif_shm, i_slv_bus2osif_data,
                         i_init_data,
                         i_fifo_read_data,
                         i_fifo_read_wait,
                         i_fifo_write_wait)
    begin
        -- default assignment
        o_osif.data  <= X"AFFE1010";    -- for debugging purposes
        o_osif.valid <= '0';

        case i_osif.command is
            when OSIF_CMD_READ =>
                if step = 1 then
                    o_osif.data  <= i_slv_bus2osif_shm;
                    o_osif.valid <= '1';
                end if;

            when OSIF_CMD_GET_INIT_DATA =>
                if step = 1 then
                    o_osif.data  <= i_init_data;
                    o_osif.valid <= '1';
                end if;

            when OSIF_CMD_MUTEX_LOCK =>
                if step = 1 then
                    o_osif.data  <= i_slv_bus2osif_data;
                    o_osif.valid <= '1';
                end if;

            when OSIF_CMD_MUTEX_TRYLOCK =>
                if step = 1 then
                    o_osif.data  <= i_slv_bus2osif_data;
                    o_osif.valid <= '1';
                end if;

            when OSIF_CMD_MBOX_GET =>
                if step = 2 then
                    if fifo_local = '1' then
                        -- local hardware FIFO access
                        if i_fifo_read_wait = '1' or failure = '1' then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= i_fifo_read_data;
                            o_osif.valid <= '1';
                        end if;
                    else
                        -- global software FIFO access
                        if i_slv_bus2osif_data = C_RECONOS_FAILURE then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= i_slv_bus2osif_data;
                            o_osif.valid <= '1';
                        end if;
                    end if;
                end if;

                -- identical to MBOX_GET!
            when OSIF_CMD_MBOX_TRYGET =>
                if step = 2 then
                    if fifo_local = '1' then
                        -- local hardware FIFO access
                        if i_fifo_read_wait = '1' or failure = '1' then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= i_fifo_read_data;
                            o_osif.valid <= '1';
                        end if;
                    else
                                        -- global software FIFO access
                        if i_slv_bus2osif_data = C_RECONOS_FAILURE then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= i_slv_bus2osif_data;
                            o_osif.valid <= '1';
                        end if;
                    end if;
                end if;

            when OSIF_CMD_MBOX_PUT =>
                if step = 2 then
                    if fifo_local = '1' then
                        -- local hardware FIFO access
                        if i_fifo_write_wait = '1' or failure = '1' then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= C_RECONOS_SUCCESS;
                            o_osif.valid <= '1';
                        end if;
                    else
                        -- global software FIFO access
                        if i_slv_bus2osif_data = C_RECONOS_FAILURE then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= C_RECONOS_SUCCESS;
                            o_osif.valid <= '1';
                        end if;
                    end if;
                end if;

            when OSIF_CMD_MQ_SEND =>
                if step = 2 then
                    if i_slv_bus2osif_data = C_RECONOS_FAILURE then
                        o_osif.data  <= C_RECONOS_FAILURE;
                        o_osif.valid <= '0';
                    else
                        o_osif.data  <= C_RECONOS_SUCCESS;
                        o_osif.valid <= '1';
                    end if;
                end if;


            when OSIF_CMD_MQ_RECEIVE =>
                if step = 2 then
                    if i_slv_bus2osif_data = C_RECONOS_FAILURE then
                        o_osif.data  <= C_RECONOS_FAILURE;
                        o_osif.valid <= '0';
                    else
                        o_osif.data  <= i_slv_bus2osif_data;
                        o_osif.valid <= '1';
                    end if;
                end if;


                -- identical to MBOX_PUT!
            when OSIF_CMD_MBOX_TRYPUT =>
                if step = 2 then
                    if fifo_local = '1' then
                        -- local hardware FIFO access
                        if i_fifo_write_wait = '1' or failure = '1' then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= C_RECONOS_SUCCESS;
                            o_osif.valid <= '1';
                        end if;
                    else
                        -- global software FIFO access
                        if i_slv_bus2osif_data = C_RECONOS_FAILURE then
                            o_osif.data  <= C_RECONOS_FAILURE;
                            o_osif.valid <= '0';
                        else
                            o_osif.data  <= C_RECONOS_SUCCESS;
                            o_osif.valid <= '1';
                        end if;
                    end if;
                end if;

            when OSIF_CMD_THREAD_RESUME =>
                if step = 1 then
                    if i_resume = '1' then
                        o_osif.data  <= i_resume_state_enc & X"000000";
                        o_osif.valid <= '1';
                    else
                        o_osif.data  <= (others => '0');
                        o_osif.valid <= '0';
                    end if;
                end if;

            when others => null;
        end case;
    end process;



    sync_decode : process(i_clk, i_reset)
    begin

        if i_reset = '1' then

            o_bm_my_addr           <= (others => '0');
            o_bm_target_addr       <= (others => '0');
            step                   <= 0;
            o_bm_read_req          <= '0';
            o_bm_write_req         <= '0';
            o_bm_burst_read_req    <= '0';
            o_bm_burst_write_req   <= '0';
            o_bm_burst_length      <= (others => '0');
            o_slv_osif2bus_command <= (others => '0');
            o_slv_osif2bus_data    <= (others => '0');
            o_slv_osif2bus_datax   <= (others => '0');
            o_slv_osif2bus_shm     <= (others => '0');
            o_sw_request           <= '0';
            o_fifo_read_remove     <= '0';
            o_fifo_write_add       <= '0';
            busy                   <= '0';
            blocking               <= '1';
            request_seen           <= '0';
            failure                <= '0';
            fifo_local             <= '0';
            o_yield                <= '0';


        elsif rising_edge(i_clk) then

            -- default signal assignments
            o_bm_read_req        <= '0';
            o_bm_write_req       <= '0';
            o_bm_burst_read_req  <= '0';
            o_bm_burst_write_req <= '0';
            o_sw_request         <= '0';
            o_fifo_read_remove   <= '0';
            o_fifo_write_add     <= '0';
            busy                 <= '0';

            if i_osif.request = '0' and request_seen = '1' then
                -- reset request_seen after request went away
                request_seen <= '0';

            elsif i_osif.request = '1' and request_seen = '0' then
                -- mark request as seen
                request_seen <= '1';
                
                -- retain yield flag
                o_yield         <= i_osif.yield;

                case i_osif.command is

                    ----------
                    -- single memory read
                    ----------
                    when OSIF_CMD_READ =>
                        case step is
                            when 0     =>
                                o_bm_read_req    <= '1';
                                o_bm_my_addr     <= C_BASEADDR;
                                o_bm_target_addr <= i_osif.data;
                                busy             <= '1';  -- busy until read completion
                                step             <= 1;

                            when 1 =>
-- o_osif.data <= i_slv_bus2osif_shm;   -- this has to be done before step 1 (see retval_mux)
                                step <= 0;  -- last step.

                            when others => null;

                        end case;  -- CMD_READ

                        ----------
                        -- single memory write
                        ----------
                    when OSIF_CMD_WRITE =>
                        case step is
                            when 0      =>
                                o_bm_my_addr     <= C_BASEADDR;
                                o_bm_target_addr <= i_osif.data;
                                step             <= 1;

                            when 1 =>
                                o_slv_osif2bus_shm <= i_osif.data;
                                o_bm_write_req     <= '1';
                                busy               <= '1';  -- busy until write completion
                                step               <= 0;

                            when others => null;

                        end case;

                        ----------
                        -- burst memory read with specified length
                        ----------
                    when OSIF_CMD_READ_BURST =>
                        case step is
                            when 0           =>
                                o_bm_my_addr <= C_BURST_BASEADDR(0 to C_PLB_AWIDTH-C_BURST_AWIDTH-1) & i_osif.data(C_PLB_AWIDTH-C_BURST_AWIDTH to C_PLB_AWIDTH-1);
                                step         <= 1;

                            when 1 =>
                                o_bm_target_addr <= i_osif.data;
                                step             <= 2;

                            when 2 =>
                                o_bm_burst_read_req <= '1';
                                o_bm_burst_length   <= i_osif.data(C_OSIF_DATA_WIDTH-5 to C_OSIF_DATA_WIDTH-1);
                                busy                <= '1';  -- busy until read completion
                                step                <= 0;

                            when others => null;
                        end case;

                        ----------
                        -- burst memory write with specified length
                        ----------
                    when OSIF_CMD_WRITE_BURST =>
                        case step is
                            when 0            =>
                                o_bm_my_addr <= C_BURST_BASEADDR(0 to C_PLB_AWIDTH-C_BURST_AWIDTH-1) & i_osif.data(C_PLB_AWIDTH-C_BURST_AWIDTH to C_PLB_AWIDTH-1);
                                step         <= 1;

                            when 1 =>
                                o_bm_target_addr <= i_osif.data;
                                step             <= 2;

                            when 2 =>
                                o_bm_burst_write_req <= '1';
                                o_bm_burst_length    <= i_osif.data(C_OSIF_DATA_WIDTH-5 to C_OSIF_DATA_WIDTH-1);
                                busy                 <= '1';  -- busy until write completion
                                step                 <= 0;

                            when others => null;
                        end case;

                        ----------
                        -- get thread data
                        ----------
                    when OSIF_CMD_GET_INIT_DATA =>
                        case step is
                            when 0              =>
                                -- data is put on o_osif.data in the retval mux above
                                -- so we don't need to do anything here
                                step <= 1;

                            when 1 =>
                                -- or here
                                step <= 0;

                            when others => null;
                        end case;

                        ----------
                        -- mutex lock
                        ----------
                    when OSIF_CMD_MUTEX_LOCK                      =>
                        case step is
                            when 0                                =>
                                o_slv_osif2bus_command <= i_osif.command;
                                o_slv_osif2bus_data    <= i_osif.data;
                                o_slv_osif2bus_datax   <= (others => '0');
                                o_sw_request           <= '1';
                                busy                   <= '1';
                                blocking               <= '1';
                                step                   <= 1;

                            when 1 =>
                                -- data is put on o_osif.data in the retval mux above
                                step <= 0;

                            when others => null;

                        end case;

                        ----------
                        -- mutex trylock
                        ----------
                    when OSIF_CMD_MUTEX_TRYLOCK                   =>
                        case step is
                            when 0                                =>
                                o_slv_osif2bus_command <= i_osif.command;
                                o_slv_osif2bus_data    <= i_osif.data;
                                o_slv_osif2bus_datax   <= (others => '0');
                                o_sw_request           <= '1';
                                busy                   <= '1';
                                blocking               <= '1';
                                step                   <= 1;

                            when 1 =>
                                -- data is put on o_osif.data in the retval mux above
                                step <= 0;

                            when others => null;

                        end case;

                        ----------
                        -- condvar wait
                        ----------
                    when OSIF_CMD_COND_WAIT                       =>
                        case step is
                            when 0                                =>
                                o_slv_osif2bus_command <= i_osif.command;
                                o_slv_osif2bus_data    <= i_osif.data;
                                o_slv_osif2bus_datax   <= (others => '0');
                                o_sw_request           <= '1';
                                busy                   <= '1';
                                blocking               <= '1';
                                step                   <= 1;

                            when 1 =>
                                -- data is put on o_osif.data in the retval mux above
                                step <= 0;

                            when others => null;

                        end case;


                        ----------
                        -- mbox get
                        -- in case of hardware FIFO access, this blocking call 
                        -- does not use the 'busy' or 'blocking' signals, but
                        -- keeps looping inside the same multi-cycle step.
                        -- this is similar to polling, but since it is done
                        -- locally, it's not as bad.
                        -- because of the local hardware FIFO access,
                        -- this needs to be a two-cycle-command because we need to
                        -- wait one cycle to wait for the wait line to assert
                        -- after reading the last value. It also simplifies the
                        -- return value transmission
                        ----------
                    when OSIF_CMD_MBOX_GET                            =>
                        case step is
                            when 0                                    =>
                                        -- local hardware FIFO
                                if i_osif.data = i_fifo_read_handle then
                                    fifo_local             <= '1';
                                        -- if read FIFO is available, read data from it
                                    if i_fifo_read_wait = '0' then
                                        o_fifo_read_remove <= '1';
                                        step               <= 1;
                                        -- if FIFO is busy, keep trying
                                    else
                                        step               <= 0;
                                    end if;
                                else
                                        -- global software FIFO
                                    fifo_local             <= '0';
                                    o_slv_osif2bus_command <= i_osif.command;
                                    o_slv_osif2bus_data    <= i_osif.data;
                                    o_slv_osif2bus_datax   <= (others => '0');
                                    o_sw_request           <= '1';
                                    busy                   <= '1';
                                    blocking               <= '1';
                                    step                   <= 2;  -- skip step 1
                                end if;

                            when 1 =>   -- wait state for hardware FIFO access
                                step <= 2;

                            when 2 =>
                                fifo_local <= '0';
                                failure    <= '0';
                                        -- data is put on o_osif.data in the retval mux above
                                step       <= 0;

                            when others => null;

                        end case;


                        ----------
                        -- mbox tryget
                        -- because of the local hardware FIFO access,
                        -- this needs to be a two-cycle-command because we need to
                        -- wait one cycle to wait for the wait line to assert
                        -- after reading the last value. It also simplifies the
                        -- return value transmission
                        ----------
                    when OSIF_CMD_MBOX_TRYGET =>

                        case step is
                            when 0                                    =>
                                        -- local hardware FIFO
                                if i_osif.data = i_fifo_read_handle then
                                    fifo_local             <= '1';
                                        -- if read FIFO is available, read data from it
                                    if i_fifo_read_wait = '0' then
                                        o_fifo_read_remove <= '1';
                                        step               <= 1;
                                    else
                                        failure            <= '1';
                                        step               <= 2;  -- skip waiting
                                    end if;
                                else
                                        -- global software FIFO
                                    fifo_local             <= '0';
                                    o_slv_osif2bus_command <= i_osif.command;
                                    o_slv_osif2bus_data    <= i_osif.data;
                                    o_slv_osif2bus_datax   <= (others => '0');
                                    o_sw_request           <= '1';
                                    busy                   <= '1';
                                    blocking               <= '1';
                                    step                   <= 2;  -- skip step 1
                                end if;

                            when 1 =>   -- wait state for hardware FIFO access
                                step <= 2;

                            when 2 =>
                                fifo_local <= '0';
                                failure    <= '0';
                                        -- data is put on o_osif.data in the retval mux above
                                step       <= 0;

                            when others => null;

                        end case;

                        ----------
                        -- mbox put
                        -- in case of hardware FIFO access, this blocking call 
                        -- does not use the 'busy' or 'blocking' signals, but
                        -- keeps looping inside the same multi-cycle step.
                        -- this is similar to polling, but since it is done
                        -- locally, it's not as bad
                        ----------
                    when OSIF_CMD_MBOX_PUT =>
                        case step is
                            when 0         =>
                                if i_osif.data = i_fifo_write_handle then
                                        -- local hardware FIFO access
                                    fifo_local             <= '1';
                                        -- if FIFO is busy, keep trying
                                    if i_fifo_write_wait = '1' then
                                        step               <= 0;
                                    else
                                        step               <= 1;
                                    end if;
                                else
                                        -- global software FIFO access
                                    fifo_local             <= '0';
                                    o_slv_osif2bus_command <= i_osif.command;
                                    o_slv_osif2bus_data    <= i_osif.data;
                                    step                   <= 1;
                                end if;

                            when 1 =>
                                if fifo_local = '1' then
                                        -- local hardware FIFO access
                                        -- if FIFO is busy, keep trying
                                    if i_fifo_write_wait = '0' then
                                        o_fifo_write_add <= '1';
                                        step             <= 2;
                                    else
                                        step             <= 1;
                                    end if;
                                else
                                        -- global software FIFO access
                                    o_slv_osif2bus_datax <= i_osif.data;
                                    o_sw_request         <= '1';
                                    busy                 <= '1';
                                    blocking             <= '1';
                                    step                 <= 2;
                                end if;

                            when 2 =>
                                fifo_local <= '0';
                                failure    <= '0';
                                        -- return value is put on o_osif.data in the retval mux above
                                step       <= 0;

                            when others => null;

                        end case;


                        -------
                        -- mq send
                        ----------
                    when OSIF_CMD_MQ_SEND =>
                        case step is
                            when 0        =>
                                fifo_local             <= '0';
                                o_slv_osif2bus_command <= i_osif.command;
                                o_slv_osif2bus_data    <= i_osif.data;
                                step                   <= 1;

                            when 1 =>
                                o_slv_osif2bus_datax <= i_osif.data;
                                o_sw_request         <= '1';
                                busy                 <= '1';
                                blocking             <= '1';
                                step                 <= 2;

                            when 2 =>
                                fifo_local <= '0';
                                failure    <= '0';
                                -- return value is put on o_osif.data in the retval mux above
                                step       <= 0;

                            when others => null;

                        end case;


                        -------
                        -- mq receive
                        ----------
                    when OSIF_CMD_MQ_RECEIVE =>
                        case step is
                            when 0           =>
                                fifo_local             <= '0';
                                o_slv_osif2bus_command <= i_osif.command;
                                o_slv_osif2bus_data    <= i_osif.data;
                                step                   <= 1;

                            when 1 =>
                                -- global software FIFO access
                                o_slv_osif2bus_datax <= i_osif.data;
                                o_sw_request         <= '1';
                                busy                 <= '1';
                                blocking             <= '1';
                                step                 <= 2;

                            when 2 =>
                                fifo_local <= '0';
                                failure    <= '0';
                                        -- return value is put on o_osif.data in the retval mux above
                                step       <= 0;

                            when others => null;

                        end case;




                        ----------
                        -- mbox tryput
                        ----------
                    when OSIF_CMD_MBOX_TRYPUT =>
                        case step is
                            when 0            =>
                                if i_osif.data = i_fifo_write_handle then
                                        -- local hardware FIFO access
                                    fifo_local             <= '1';
                                    if i_fifo_write_wait = '1' then
                                        failure            <= '1';
                                        step               <= 2;
                                    else
                                        step               <= 1;
                                    end if;
                                else
                                        -- global software FIFO access
                                    fifo_local             <= '0';
                                    o_slv_osif2bus_command <= i_osif.command;
                                    o_slv_osif2bus_data    <= i_osif.data;
                                    step                   <= 1;
                                end if;

                            when 1 =>
                                if fifo_local = '1' then
                                        -- local hardware FIFO access
                                    if i_fifo_write_wait = '0' then
                                        o_fifo_write_add <= '1';
                                    else
                                        failure          <= '1';
                                    end if;
                                else
                                        -- global software FIFO access
                                    o_slv_osif2bus_datax <= i_osif.data;
                                    o_sw_request         <= '1';
                                    busy                 <= '1';
                                    blocking             <= '1';
                                end if;
                                step                     <= 2;

                            when 2 =>
                                fifo_local <= '0';
                                failure    <= '0';
                                        -- return value is put on o_osif.data in the retval mux above
                                step       <= 0;

                            when others => null;

                        end case;

                        ----------
                        -- get thread resume state
                        ----------
                    when OSIF_CMD_THREAD_RESUME =>
                        case step is
                            when 0              =>
                                -- data is put on o_osif.data in the retval mux above
                                -- so we don't need to do anything here
                                step <= 1;

                            when 1 =>
                                step <= 0;
                                if (i_resume = '1') then
                                    -- block since we are always resuming in or after
                                    -- a blocking call
                                    blocking <= '1';
                                    -- if we resume inside a multi-cycle command (step /= 0),
                                    -- we need to insert a resume step for reaquiring handshake 
                                    -- between thread FSM and retval mux
                                    if i_resume_step_enc /= "00" then
                                        step <= C_STEP_RESUME;
                                    end if;
                                end if;
                                

                            when others => null;
                        end case;


                        ----------
                        -- thread_yield
                        ----------
                    when OSIF_CMD_THREAD_YIELD                       =>
                        if i_yield = '1' then
                            blocking <= '1';
                            o_slv_osif2bus_command <= i_osif.command;
                            o_slv_osif2bus_data    <= i_osif.data;  -- this is the encoded saved state
                            o_slv_osif2bus_datax   <= (others => '0');
                            o_sw_request           <= '1';
                            busy                   <= '1';
                        end if;

                        ----------
                        -- other commands (all single-cycle and software-handled)
                        -- this includes:
                        --  OSIF_CMD_SEM_POST 
                        --  OSIF_CMD_SEM_WAIT 
                        --  OSIF_CMD_MUTEX_UNLOCK 
                        --  OSIF_CMD_MUTEX_RELEASE
                        --  OSIF_CMD_COND_SIGNAL
                        --  OSIF_CMD_COND_BROADCAST 
                        --  OSIF_CMD_THREAD_EXIT
                        --  OSIF_CMD_THREAD_DELAY
                        ----------
                    when others                           =>  -- software-handled single-cycle requests do not need special handling
                        -- blocking?
                        if i_osif.command(C_OSIF_CMD_BLOCKING_BITPOS) = '1' then
                            blocking           <= '1';
                        end if;
                        o_slv_osif2bus_command <= i_osif.command;
                        o_slv_osif2bus_data    <= i_osif.data;
                        o_slv_osif2bus_datax   <= (others => '0');
                        o_sw_request           <= '1';
                        busy                   <= '1';

                end case;

                -- implement wait step for resuming
                if step = C_STEP_RESUME then
                    step <= natural(TO_INTEGER(unsigned(i_resume_step_enc)));
                end if;

            end if;  -- request = '1'

            -- FIXME: check for races between i_request_blocking (from SW) and i_osif.request (from HW).
            if i_request_blocking = '1' then
                blocking <= '1';
            elsif i_release_blocking = '1' then
                blocking <= '0';
            end if;

        end if;  -- reset

    end process;

    ------------------------------------------------
    -- get_signature: retrieve signature from hardware thread
    -- and output it to DCR registers
    --
    -- NOTE: this works also (in fact, only) during a reset
    -- reset needs to be high for several cycles in order for the signature
    -- data to propagate through any synchronous bus macros. This is done
    -- in osif_core which manages the thread reset
    ------------------------------------------------
    get_signature : process( i_clk, i_reset )
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then       -- task is in reset state
                o_hwthread_signature <= i_osif.data;
            end if;
        end if;
    end process ; -- get_signature


end behavioral;
