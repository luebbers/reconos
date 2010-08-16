--!
--! \file wait_and_yield.vhd
--!
--! Benchmark for cooperative multithreading
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       13.03.2009
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 13.03.2009   Enno Luebbers   File created.


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

entity wait_and_yield is

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
end wait_and_yield;

architecture Behavioral of wait_and_yield is

  -- OS synchronization state machine states
  type state_t is                (STATE_CHECK,
                                  STATE_INIT,
                                  STATE_WAIT_BEFORE,
                                  STATE_DELAY,
                                  STATE_RESUME,
                                  STATE_WAIT_AFTER,
                                  STATE_EXIT); 
  type encode_t is array(state_t) of reconos_state_enc_t;
  type decode_t is array(natural range <>) of state_t;
  constant encode : encode_t :=  (X"00",
                                  X"01",
                                  X"02",
                                  X"03",
                                  X"04",
                                  X"05",
                                  X"06");
  constant decode : decode_t := (STATE_CHECK,
                                  STATE_INIT,
                                  STATE_WAIT_BEFORE,
                                  STATE_DELAY,
                                  STATE_RESUME,
                                  STATE_WAIT_AFTER,
                                  STATE_EXIT); 

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
    variable delay         : std_logic_vector(0 to C_OSIF_DATA_WIDTH/2-1) := (others => '0');
    variable wait_before_after : std_logic_vector(0 to C_OSIF_DATA_WIDTH/2-2) := (others => '0');      -- possible values: 0..32767 (x 1.31 ms)
    variable do_yield      : std_logic := '0';
    variable counter       : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
    variable init_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state        <= STATE_CHECK;
      next_state   := STATE_CHECK;
      resume_state_enc := (others => '0');
      done         := false;
      success      := false;
      delay        := (others => '0');
      wait_before_after := (others => '0');
      do_yield     := '0';
      counter      := (others => '0');
      init_data    := (others => '0');
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

            when STATE_CHECK =>
                reconos_thread_resume(done, success, o_osif, i_osif, resume_state_enc);
                if success then
                    next_state := decode(to_integer(unsigned(resume_state_enc)));
                else
                    next_state := STATE_INIT;
                end if;

            when STATE_INIT =>
                reconos_get_init_data(done, o_osif, i_osif, init_data);
                do_yield := init_data(0);
                wait_before_after := init_data(1 to 15);
                delay := init_data(16 to 31);
                counter := wait_before_after & "0" & X"0000";  -- x 1.31 ms
                next_state := STATE_WAIT_BEFORE;

            when STATE_WAIT_BEFORE => 
                if counter = X"00000000" then
                    next_state := STATE_DELAY;
                else
                    counter := counter - 1;
                end if;

            when STATE_DELAY =>
                reconos_thread_delay(o_osif, i_osif, (X"0000" & delay));      -- delay for 'delay' timer ticks
                if do_yield = '1' then
                    reconos_flag_yield(o_osif, i_osif, encode(STATE_RESUME));
                end if;
                counter := wait_before_after & "0" & X"0000";  -- x 1.31 ms
                next_state := STATE_WAIT_AFTER;

            when STATE_RESUME =>
                reconos_get_init_data(done, o_osif, i_osif, init_data);
                wait_before_after := init_data(1 to 15);
                counter := wait_before_after & "0" & X"0000"; -- x 1.31 ms
                next_state := STATE_WAIT_AFTER;

            when STATE_WAIT_AFTER => 
                if counter = X"00000000" then
                    next_state := STATE_EXIT;
                else
                    counter := counter - 1;
                end if;

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


