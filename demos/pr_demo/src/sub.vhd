--!
--! \file sub.vhd
--!
--! Demo thread for partial reconfiguration
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       27.01.2009
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 27.01.2009   Enno Luebbers   File created.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sub is

  generic (
    C_BURST_AWIDTH : integer := 11;
    C_BURST_DWIDTH : integer := 32;
    C_SUB_NADD     : integer := 1   -- 0: ADD, 1: SUB
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
end sub;

architecture Behavioral of sub is

  -- OS synchronization state machine states
  type t_state is (STATE_INIT, STATE_READ, STATE_WRITE, STATE_EXIT);
  signal state : t_state := STATE_INIT;

  -- address of data to process in main memory
  signal address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others =>  '0');
  signal result : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);

begin

    -- tie RAM signals low (we don't use them)
    o_RAMAddr <= (others => '0');
    o_RAMData <= (others => '0');
    o_RAMWe   <= '0';
    o_RAMClk  <= '0';

    -- calculate result in parallel
    result <= data + 1 when C_SUB_NADD = 0 else data - 1;

  -- OS synchronization state machine
  state_proc               : process(clk, reset)
    variable done          : boolean;
    variable next_state    : t_state := STATE_INIT;
  begin
    if reset = '1' then
      reconos_reset_with_signature(o_osif, i_osif, X"12345678");
      state      <= STATE_INIT;
      next_state := STATE_INIT;
      done       := false;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

            -- read target address from init data
            when STATE_INIT =>
                reconos_get_init_data_s(done, o_osif, i_osif, address);
                next_state := STATE_READ;

            -- read data from target address
            when STATE_READ => 
                reconos_read_s(done, o_osif, i_osif, address, data);
                next_state := STATE_WRITE;

            -- write result to target address
            when STATE_WRITE => 
                reconos_write(done, o_osif, i_osif, address, result);
                next_state := STATE_EXIT;

            -- terminate
            when STATE_EXIT => 
                reconos_thread_exit(o_osif, i_osif, C_RECONOS_SUCCESS); 

          when others =>
                next_state := STATE_INIT;

        end case;
        if done then
            state <= next_state;
        end if;
      end if;
    end if;
  end process;
end Behavioral;


