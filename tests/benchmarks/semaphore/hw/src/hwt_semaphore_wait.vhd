--
-- hwt_semaphore_wait.vhd: measure time for semaphore_wait() operation
--
-- This HW thread measures the time it takes to execute a semaphore_wait()
-- operation from hardware.
-- To avoid side effects caused by activity of the delegate after returnung
-- from a sem_wait() call, this thread waits a defined number of clock
-- cycles before and after calling reconos_sem_wait() before exiting the thread
-- This number can be configured using the init_data value. A typical value is
-- 100000, which is equivalent to a millisecond.
--
-- This HW thread uses the dcr_timebase core to do consistent and synchronized
-- measurements of elapsed bus clock cycles.
--
-- Author     Enno Luebbers <enno.luebbers@upb.de>
-- Date       11.02.2008
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
-- 11.02.2008   Enno Luebbers   File created
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_00_a;
use reconos_v2_00_a.reconos_pkg.all;

entity hwt_semaphore_wait is

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

architecture Behavioral of hwt_semaphore_wait is

        attribute keep_hierarchy : string;
        attribute keep_hierarchy of Behavioral: architecture is "true";

        constant C_SEMAPHORE   : std_logic_vector(31 downto 0) := X"00000000";
        constant C_MBOX_RESULT : std_logic_vector(31 downto 0) := X"00000001";
        
        type t_state is ( STATE_INIT,           -- get initial data (delay in clocks)
                          STATE_WAIT_BEFORE,    -- wait before measuring
                          STATE_WAIT_SEM,       -- wait for semaphore
                          STATE_MEASURE,        -- measure elapsed time
                          STATE_WAIT_AFTER,     -- wait after measuring
                          STATE_PUT_RESULT_START,     -- post elapsed time to software mbox
                          STATE_PUT_RESULT_STOP,
                          STATE_EXIT);          -- exit
        
        signal state : t_state;
        signal counter : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
        signal reset_counter : std_logic := '1';
begin

        state_proc: process( clk, reset )
            variable delay   : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable result_start  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable result_stop  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable retval  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
            variable done    : boolean := false;
            variable success : boolean := false;
        begin
                if reset = '1' then
                        reconos_reset( o_osif, i_osif );
                        state <= STATE_INIT;
                        reset_counter <= '1';
                        result_start := (others => '0');
                        result_stop  := (others => '0');
                        retval := (others => '0');
                elsif rising_edge( clk ) then
                        reconos_begin( o_osif, i_osif );
                        if reconos_ready( i_osif ) then
                                case state is
                                        when STATE_INIT =>
                                            reconos_get_init_data(done, o_osif, i_osif, delay);
                                            if done then
                                                reset_counter <= '1';
                                                state <= STATE_WAIT_BEFORE;
                                            end if;

                                        when STATE_WAIT_BEFORE =>
                                            reset_counter <= '0';
                                            if counter >= delay then
                                                reset_counter <= '1';
                                                result_start := i_timeBase;
                                                state <= STATE_WAIT_SEM;
                                            end if;
                                                
                                        when STATE_WAIT_SEM =>
                                            reconos_sem_wait(o_osif,i_osif,C_SEMAPHORE);
                                            state <= STATE_MEASURE;

                                        when STATE_MEASURE =>
                                            result_stop := i_timeBase;
                                            state <= STATE_WAIT_AFTER;

                                        when STATE_WAIT_AFTER =>
                                            reset_counter <= '0';
                                            if counter >= delay then
                                                reset_counter <= '1';
                                                state <= STATE_PUT_RESULT_START;
                                            end if;

                                        when STATE_PUT_RESULT_START =>
                                            reconos_mbox_put(done,
                                                             success,
                                                             o_osif,
                                                             i_osif,
                                                             C_MBOX_RESULT,
                                                             result_start);
                                            if done then
                                                if success then
                                                    state <= STATE_PUT_RESULT_STOP;
                                                else
                                                    retval := X"0000_0001";     -- first mbox_put failed
                                                    state <= STATE_EXIT;
                                                end if;
                                            end if;

                                        when STATE_PUT_RESULT_STOP =>
                                            reconos_mbox_put(done,
                                                             success,
                                                             o_osif,
                                                             i_osif,
                                                             C_MBOX_RESULT,
                                                             result_stop);
                                            if done then
                                                if success then
                                                    retval := X"0000_0000";     -- all is well
                                                    state <= STATE_EXIT;
                                                else
                                                    retval := X"0000_0002";     -- second mbox_put failed
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
