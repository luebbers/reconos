--
-- hwt_mutex.vhd: measure time for mutex_lock/unlock() operation
--
-- This HW thread measures the time it takes to execute a mutex_unlock()
-- operation from hardware.
-- To avoid side effects caused by activity of the delegate after returnung
-- from a mutex_unlock() call, this thread waits a defined number of clock
-- cycles between consecutive calls to reconos_mutex_unlock(). This number can
-- be configured using the init_data value. A typical value is 100000, which
-- is equivalent to a millisecond.
--
-- This HW thread uses the dcr_timebase core to do consistent and synchronized
-- measurements of elapsed bus clock cycles.
--
-- Author     Enno Luebbers <enno.luebbers@upb.de>
-- Date       12.02.2008
--
-- For detailed documentation of the functions, see the associated header
-- file or the documentation (if such a header exists).
--
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- University of Paderborn, Computer Engineering Group 
--
-- (C) Copyright University of Paderborn 2007. Permission to copy,
-- use, modify, sell and distribute this software is granted provided
-- this copyright notice appears in all copies. This software is
-- provided "as is" without express or implied warranty, and with no
-- claim as to its suitability for any purpose.
--
---------------------------------------------------------------------------
-- Major Changes:
--
-- 12.02.2008   Enno Luebbers   File created
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_00_a;
use reconos_v2_00_a.reconos_pkg.all;

entity hwt_mutex is

        generic (
                C_BURST_AWIDTH : integer := 11;
                C_BURST_DWIDTH : integer := 32
        );
        
        port (
                clk : in std_logic;
                reset : in std_logic;
                i_osif : in osif_os2task_t;
                o_osif : out osif_task2os_t;

                -- burst ram interface
                o_RAMAddr : out std_logic_vector( 0 to C_BURST_AWIDTH-1 );
                o_RAMData : out std_logic_vector( 0 to C_BURST_DWIDTH-1 );
                i_RAMData : in std_logic_vector( 0 to C_BURST_DWIDTH-1 );
                o_RAMWE   : out std_logic;
                o_RAMClk  : out std_logic;

                -- time base
                i_timeBase : in std_logic_vector( 0 to C_OSIF_DATA_WIDTH-1 )
        );
        
end entity;

architecture Behavioral of hwt_mutex is

        attribute keep_hierarchy : string;
        attribute keep_hierarchy of Behavioral: architecture is "true";

        constant C_MUTEX       : std_logic_vector(31 downto 0) := X"00000000";
        constant C_SEM_POST    : std_logic_vector(31 downto 0) := X"00000001";
        constant C_SEM_WAIT    : std_logic_vector(31 downto 0) := X"00000002";
        constant C_MBOX_RESULT : std_logic_vector(31 downto 0) := X"00000003";
        
        type t_state is ( STATE_INIT,               -- get initial data (delay in clocks)
                          STATE_WAIT_BEFORE_LOCK,   -- wait before measuring
                          STATE_MUTEX_LOCK,         -- lock mutex
                          STATE_MEASURE_LOCK,       -- measure elapsed time
                          STATE_WAIT_AFTER_LOCK,    -- wait after measuring
                          STATE_SEM_POST,           -- post semaphore
                          STATE_SEM_WAIT,           -- wait for semaphore from main()
                          STATE_WAIT_BEFORE_UNLOCK, -- wait before measuring
                          STATE_MUTEX_UNLOCK,       -- unlock mutex
                          STATE_MEASURE_UNLOCK,     -- measure elapsed time
                          STATE_WAIT_AFTER_UNLOCK,  -- wait after measuring
                          STATE_PUT_LOCK_START,     -- post elapsed time to software mbox
                          STATE_PUT_LOCK_STOP,
                          STATE_PUT_UNLOCK_START,
                          STATE_PUT_UNLOCK_STOP,
                          STATE_EXIT);          -- exit
        
        signal state : t_state;
        signal counter : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
        signal reset_counter : std_logic := '1';
begin

        state_proc: process( clk, reset )
            variable delay   : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable lock_start  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable lock_stop  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable unlock_start  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable unlock_stop  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable retval  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable done    : boolean := false;
            variable success : boolean := false;
        begin
                if reset = '1' then
                        reconos_reset( o_osif, i_osif );
                        state <= STATE_INIT;
                        reset_counter <= '1';
                        lock_start := (others => '0');
                        lock_stop  := (others => '0');
                        unlock_start := (others => '0');
                        unlock_stop  := (others => '0');
                        retval := (others => '0');
                elsif rising_edge( clk ) then
                        reconos_begin( o_osif, i_osif );
                        if reconos_ready( i_osif ) then
                                case state is
                                        when STATE_INIT =>
                                            reconos_get_init_data(done, o_osif, i_osif, delay);
                                            reset_counter <= '1';
                                            if done then
                                                state <= STATE_WAIT_BEFORE_LOCK;
                                            end if;

                                    when STATE_WAIT_BEFORE_LOCK =>
                                        reset_counter <= '0';
                                        if counter >= delay then
                                            reset_counter <= '1';
                                            lock_start := i_timeBase;
                                            state <= STATE_MUTEX_LOCK;
                                        end if;
                                            
                                    when STATE_MUTEX_LOCK =>
                                        reconos_mutex_lock(done, success, o_osif, i_osif, C_MUTEX);
                                        if done then
                                            if success then
                                                state <= STATE_MEASURE_LOCK;
                                            else
                                                retval := X"0000_0001";         -- mutex lock failed
                                                state <= STATE_EXIT;
                                            end if;
                                        end if;

                                    when STATE_MEASURE_LOCK =>
                                        lock_stop := i_timeBase;
                                        state <= STATE_WAIT_AFTER_LOCK;

                                    when STATE_WAIT_AFTER_LOCK =>
                                        reset_counter <= '0';
                                        if counter >= delay then
                                            reset_counter <= '1';
                                            state <= STATE_SEM_POST;
                                        end if;

                                    when STATE_SEM_POST =>
                                        reconos_sem_post(o_osif, i_osif, C_SEM_POST);
                                        state <= STATE_SEM_WAIT;

                                    when STATE_SEM_WAIT =>
                                        reconos_sem_wait(o_osif, i_osif, C_SEM_WAIT);
                                        state <= STATE_WAIT_BEFORE_UNLOCK;

                                    when STATE_WAIT_BEFORE_UNLOCK =>
                                        reset_counter <= '0';
                                        if counter >= delay then
                                            reset_counter <= '1';
                                            unlock_start := i_timeBase;
                                            state <= STATE_MUTEX_UNLOCK;
                                        end if;
                                            
                                    when STATE_MUTEX_UNLOCK =>
                                        reconos_mutex_unlock(o_osif, i_osif, C_MUTEX);
                                        state <= STATE_MEASURE_UNLOCK;

                                    when STATE_MEASURE_UNLOCK =>
                                        unlock_stop := i_timeBase;
                                        state <= STATE_WAIT_AFTER_UNLOCK;

                                        when STATE_WAIT_AFTER_UNLOCK =>
                                            reset_counter <= '0';
                                            if counter >= delay then
                                                reset_counter <= '1';
                                                state <= STATE_PUT_LOCK_START;
                                            end if;

                                        when STATE_PUT_LOCK_START =>
                                            reconos_mbox_put(done,
                                                             success,
                                                             o_osif,
                                                             i_osif,
                                                             C_MBOX_RESULT,
                                                             lock_start);
                                            if done then
                                                if success then
                                                    state <= STATE_PUT_LOCK_STOP;
                                                else
                                                    retval := X"0000_0002";     -- first mbox_put failed
                                                    state <= STATE_EXIT;
                                                end if;
                                            end if;

                                        when STATE_PUT_LOCK_STOP =>
                                            reconos_mbox_put(done,
                                                             success,
                                                             o_osif,
                                                             i_osif,
                                                             C_MBOX_RESULT,
                                                             lock_stop);
                                            if done then
                                                if success then
                                                    state <= STATE_PUT_UNLOCK_START;
                                                else
                                                    retval := X"0000_0003";     -- second mbox_put failed
                                                    state <= STATE_EXIT;
                                                end if;
                                            end if;

                                        when STATE_PUT_UNLOCK_START =>
                                            reconos_mbox_put(done,
                                                             success,
                                                             o_osif,
                                                             i_osif,
                                                             C_MBOX_RESULT,
                                                             unlock_start);
                                            if done then
                                                if success then
                                                    state <= STATE_PUT_UNLOCK_STOP;
                                                else
                                                    retval := X"0000_0004";     -- third mbox_put failed
                                                    state <= STATE_EXIT;
                                                end if;
                                            end if;

                                        when STATE_PUT_UNLOCK_STOP =>
                                            reconos_mbox_put(done,
                                                             success,
                                                             o_osif,
                                                             i_osif,
                                                             C_MBOX_RESULT,
                                                             unlock_stop);
                                            if done then
                                                if success then
                                                    retval := X"0000_0000";     -- all is well
                                                    state <= STATE_EXIT;
                                                else
                                                    retval := X"0000_0005";     -- fourth mbox_put failed
                                                    state <= STATE_EXIT;
                                                end if;
                                            end if;

                                        when STATE_EXIT =>
                                            reconos_thread_exit(o_osif, i_osif, retval);
                                                
                                end case;
                        end if;
                end if;
        end process;

        --
        -- counter process to wait cycles
        --
        counter_proc : process(clk, reset)
        begin
            if reset = '1' then
                counter <= (others => '0');
            elsif rising_edge(clk) then
                if reset_counter = '1' then
                    counter <= (others => '0');
                else
                    counter <= counter + 1;
                end if;
            end if;
        end process;


end architecture;


