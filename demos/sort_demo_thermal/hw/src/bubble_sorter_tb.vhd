--
-- bubble_sorter_tb.vhd
-- Simulation testbench for bubble_sorter.vhd
--
-- Author:     Enno Luebbers   <luebbers@reconos.de>
-- Date:       28.09.2007
--
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- University of Paderborn, Computer Engineering Group.
--
-- (C) Copyright University of Paderborn 2007.
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;                 -- for UNIFORM, TRUNC

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity bubble_sorter_tb is
  generic (
    G_MAX_SIMULATION_RUNS : integer := 1;
    G_LEN                 : integer := 2048;
    G_AWIDTH              : integer := 11;
    G_DWIDTH              : integer := 32
    );
end bubble_sorter_tb;

architecture testbench of bubble_sorter_tb is

  component burst_ram
    port (
      addra : in  std_logic_vector(10 downto 0);
      addrb : in  std_logic_vector(9 downto 0);
      clka  : in  std_logic;
      clkb  : in  std_logic;
      dina  : in  std_logic_vector(31 downto 0);
      dinb  : in  std_logic_vector(63 downto 0);
      douta : out std_logic_vector(31 downto 0);
      doutb : out std_logic_vector(63 downto 0);
      wea   : in  std_logic;
      web   : in  std_logic
      );
  end component;

  signal clk   : std_logic := '0';
  signal reset : std_logic := '0';

  -- as seen from RAM perspective       
  signal addr_ram    : std_logic_vector(0 to G_AWIDTH-1);
  signal datain_ram  : std_logic_vector(0 to G_DWIDTH-1);
  signal dataout_ram : std_logic_vector(0 to G_DWIDTH-1);
  signal we_ram      : std_logic;

  signal addr_stim    : std_logic_vector(0 to G_AWIDTH-1);
  signal datain_stim  : std_logic_vector(0 to G_DWIDTH-1);
  signal dataout_stim : std_logic_vector(0 to G_DWIDTH-1);
  signal we_stim      : std_logic;

  signal addr_sort    : std_logic_vector(0 to G_AWIDTH-1);
  signal datain_sort  : std_logic_vector(0 to G_DWIDTH-1);
  signal dataout_sort : std_logic_vector(0 to G_DWIDTH-1);
  signal we_sort      : std_logic;

  signal start : std_logic := '0';
  signal done  : std_logic := '0';
  signal sel   : std_logic;

begin

  burst_ram_i : burst_ram
    port map (
      addrb => (others => '0'),
      addra => addr_ram,
      clkb  => '0',
      clka  => clk,
      dinb  => (others => '0'),
      dina  => datain_ram,
      doutb => open,
      douta => dataout_ram,
      web   => '0',
      wea   => we_ram
      );

  sorter : entity work.bubble_sorter
    generic map (
      G_LEN     => G_LEN,
      G_AWIDTH  => G_AWIDTH,
      G_DWIDTH  => G_DWIDTH
      )
    port map (
      clk       => clk,
      reset     => reset,
      o_RAMAddr => addr_sort,
      o_RAMData => datain_sort,
      i_RAMData => dataout_sort,
      o_RAMWE   => we_sort,
      start     => start,
      done      => done
      );

  addr_ram     <= addr_stim   when sel = '0'  else addr_sort;
  datain_ram   <= datain_stim when sel = '0'  else datain_sort;
  we_ram       <= we_stim     when sel <= '0' else we_sort;
  dataout_stim <= dataout_ram;
  dataout_sort <= dataout_ram;

  -- generate clock
  process
  begin
    clk <= not clk;
    wait for 5 ns;
  end process;

  -- generate reset
  reset <= '1', '0' after 55 ns;

  -- init RAM with a few values
  process
    -- Seed values for random generator
    variable seed1, seed2 : positive;
    -- Random real-number value in range 0 to 1.0
    variable rand         : real;
    -- Random integer value in range 0..2^32-1
    variable int_rand     : integer;

    variable addr : std_logic_vector(0 to G_AWIDTH-1);
    variable data : std_logic_vector(0 to G_DWIDTH-1);
    variable a    : std_logic_vector(0 to G_DWIDTH-1);
    variable b    : std_logic_vector(0 to G_DWIDTH-1);

    variable simulation_runs : natural := 0;
  begin

    sel   <= '0';
    start <= '0';
    addr := (others => '1');
    data := std_logic_vector(to_unsigned(G_LEN, data'length));

    wait for 101 ns;

    assert false report "*** New simulation run. Generating random data. ***" severity note;

    for i in 0 to G_LEN-1 loop
      UNIFORM(seed1, seed2, rand);
      -- get a 32 bit random value
      int_rand := integer(TRUNC(rand*100000000.0));

      addr := addr + 1;
      data := std_logic_vector(to_unsigned(int_rand, data'length));
-- data := data - 1;

      datain_stim <= data;
      addr_stim   <= addr;
      we_stim     <= '1';
      wait for 10 ns;
    end loop;
    we_stim       <= '0';

    wait for 50 ns;

    assert false report "*** Starting sort process. ***" severity note;

    sel   <= '1';
    start <= '1';
    wait for 10 ns;
    start <= '0';

    wait until done = '1';
    wait for 3 ns;

    sel       <= '0';
    addr := (others => '0');
    addr_stim <= addr;
    wait for 10 ns;

    assert false report "*** Verifying sorted data. ***" severity note;

    -- verify
    for i in 0 to G_LEN-2 loop

      a    := dataout_stim;
      addr := addr + 1;
      addr_stim <= addr;
      wait for 10 ns;
      b    := dataout_stim;

      assert a <= b report "Data sort check FAILED!" severity note;

    end loop;

    simulation_runs := simulation_runs + 1;

    assert simulation_runs < G_MAX_SIMULATION_RUNS report "*** Simulation finished. This is not an error. ***" severity failure;


  end process;


end testbench;
