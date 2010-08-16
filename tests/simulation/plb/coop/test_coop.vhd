--!
--! \file test_coop.vhd
--!
--! Simulation testbench thread for cooperative multithreading
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       23.04.2009
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 23.04.2009   Enno Luebbers   File created.


library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_coop is

  generic (
    C_BURST_AWIDTH : integer := 11;
    C_BURST_DWIDTH : integer := 32;
    C_SUB_NADD     : integer := 0   -- 0: ADD, 1: SUB
    );

  port (
    clk    : in  std_logic;
    reset  : in  std_logic;
    i_osif : in  osif_os2task_t;
    o_osif : out osif_task2os_t;

    -- burst ram interface
    o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
    o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
    i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
    o_RAMWE   : out std_logic;
    o_RAMClk  : out std_logic
    );
end test_coop;

architecture Behavioral of test_coop is

  -- OS synchronization state machine states
  type state_t is               (STATE_CHECK,
                                 STATE_YIELD,
                                 STATE_POST_YIELD,
                                 STATE_DELAY,
                                 STATE_POST_DELAY,
                                 STATE_LOCK,
                                 STATE_POST_LOCK,
                                 STATE_EXIT);
  type encode_t is array(state_t) of reconos_state_enc_t;
  type decode_t is array(natural range <>) of state_t;
  constant encode : encode_t :=  (X"00",
                                  X"01",
                                  X"02",
                                  X"03",
                                  X"04",
                                  X"05",
                                  X"06",
                                  X"07");
  constant decode : decode_t := (STATE_CHECK,
                                 STATE_YIELD,
                                 STATE_POST_YIELD,
                                 STATE_DELAY,
                                 STATE_POST_DELAY,
                                 STATE_LOCK,
                                 STATE_POST_LOCK,
                                 STATE_EXIT);

  -- resources used by thread
  constant C_SEM_YIELD : std_logic_vector(0 to 31) := X"00000000";
  constant C_SEM_DELAY : std_logic_vector(0 to 31) := X"00000001";
  constant C_SEM_LOCK  : std_logic_vector(0 to 31) := X"00000002";
  constant C_MUTEX     : std_logic_vector(0 to 31) := X"00000003";

  constant C_DELAY : std_logic_vector(0 to 31) := X"0000007F";  -- delay for 128 ticks

  signal state : state_t := STATE_CHECK;

begin

    -- tie RAM signals low (we don't use them)
    o_RAMAddr <= (others => '0');
    o_RAMData <= (others => '0');
    o_RAMWe   <= '0';
    o_RAMClk  <= '0';

  -- OS synchronization state machine
  state_proc : process(clk, reset)
    variable done          : boolean;
    variable success       : boolean;
    variable next_state    : state_t := STATE_CHECK;
    variable resume_state_enc  : reconos_state_enc_t := (others => '0');
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state        <= STATE_CHECK;
      next_state   := STATE_CHECK;
      resume_state_enc := (others => '0');
      done         := false;
      success      := false;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

            when STATE_CHECK =>
                reconos_thread_resume(done, success, o_osif, i_osif, resume_state_enc);
                if done then
                    if success then
                        next_state := decode(to_integer(unsigned(resume_state_enc)));
                    else
                        next_state := STATE_YIELD;
                    end if;
                end if;

            -- test thread_yield()
            when STATE_YIELD => 
                -- on single-cycle calls, saved_state_enc must be set to the _next_ state
                reconos_thread_yield(o_osif, i_osif, encode(STATE_POST_YIELD));
                next_state := STATE_POST_YIELD;

            when STATE_POST_YIELD => 
                reconos_sem_post(o_osif, i_osif, C_SEM_YIELD);
                next_state := STATE_DELAY;
            
            -- test single-cycle blocking yielding call
            when STATE_DELAY =>
                reconos_thread_delay(o_osif, i_osif, C_DELAY);      -- delay via OS
                -- on single-cycle calls, saved_state_enc must be set to the _next_ state
                reconos_flag_yield(o_osif, i_osif, encode(STATE_POST_DELAY));
                next_state := STATE_POST_DELAY;

            when STATE_POST_DELAY => 
                reconos_sem_post(o_osif, i_osif, C_SEM_DELAY);
                next_state := STATE_LOCK;

            -- test multi-cycle blocking yielding call
            when STATE_LOCK => 
                reconos_mutex_lock(done, success, o_osif, i_osif, C_MUTEX);
                -- on multi-cycle calls, saved_state_enc must be set to the _current_ state
                reconos_flag_yield(o_osif, i_osif, encode(STATE_LOCK));
                if done then
                    if success then
                        next_state := STATE_POST_LOCK;
                    else
                        next_state := STATE_EXIT;
                    end if;
                end if;

            when STATE_POST_LOCK => 
                reconos_sem_post(o_osif, i_osif, C_SEM_LOCK);
                next_state := STATE_EXIT;

            when STATE_EXIT =>
                reconos_thread_exit(o_osif, i_osif, X"00000000");

            when others =>
                next_state := STATE_EXIT;

        end case;
        if done then
            state <= next_state;
        end if;
      end if;
    end if;
  end process;
end Behavioral;


