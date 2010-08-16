--!
--! \file just_wait.vhd
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

entity just_wait is

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
end just_wait;

architecture Behavioral of just_wait is

  -- OS synchronization state machine states
  type state_t is                (STATE_INIT,
                                  STATE_WAIT,
                                  STATE_EXIT); 
  type encode_t is array(state_t) of reconos_state_enc_t;
  type decode_t is array(natural range <>) of state_t;
  constant encode : encode_t :=  (X"00",
                                  X"01",
                                  X"03");
  constant decode : decode_t := (STATE_INIT,
                                  STATE_WAIT,
                                  STATE_EXIT); 

  signal state : state_t := STATE_INIT;



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
    variable next_state    : state_t := STATE_INIT;
    variable wait_time : std_logic_vector(0 to C_OSIF_DATA_WIDTH/2-2);      -- possible values: 0..32767 (x 6553 us)
    variable counter       : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    variable init_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state        <= STATE_INIT;
      next_state   := STATE_INIT;
      done         := false;
      success      := false;
      wait_time := (others => '0');
      counter      := (others => '0');
      init_data    := (others => '0');
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

            when STATE_INIT =>
                reconos_get_init_data(done, o_osif, i_osif, init_data);
                wait_time := init_data(17 to 31);
                counter := wait_time & "0" & X"0000"; -- x 1.31 ms
                next_state := STATE_WAIT;

            when STATE_WAIT => 
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


