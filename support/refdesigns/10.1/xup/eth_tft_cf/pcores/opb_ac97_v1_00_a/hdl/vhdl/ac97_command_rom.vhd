-------------------------------------------------------------------------------
-- Filename:        ac97_fifo.vhd
--
-- Description:     This module provides a simple FIFO interface for the AC97
--                  module and provides an asyncrhonous interface for a
--                  higher level module that is not synchronous with the AC97
--                  clock (Bit_Clk).
--
--                  This module will handle all of the initial commands
--                  for the AC97 interface.
--
--                  This module provides a bus independent interface so the
--                  module can be used for more than one bus interface.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              ac97_core
--                 ac97_timing
--              srl_fifo
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- Revision:        $$
-- Date:            $$
--
-- History:
--   Mike Wirthlin  
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;

  -- Command format V R AAAAAAA DDDDDDDD DDDDDDDD
  -- V = Valid command (1 = valid, 0 = invalid)
  -- R = Read (1=read, 0=write)
  -- A = Address (7 bits)
  -- D = Data (16 bits)

  -- '1' & X"000000"; Write 0x0 to 0x0 (reset registers)
  -- '1' & X"020808"; Write 0x808 to 0x2 (master volume 0db gain)
  -- '1' & X"040808"; Write 0x808 to 0x4 (headphone vol)
  -- '1' & X"0a8000"; Write 0x8000 to 0xa (mute PC beep)
  -- '0' & X"180808"; Write 0x808 to 0x18 pcmoutvol (amp out line)
  -- '1' & X"1a0404"; Write 0x404 to 0x1a  record source (line in for left and right)
  -- '1' & X"1c0008"; Write (0x1c,0x008); // record gain (8 steps of 1.5 dB = +12.0 dB)

entity ac97_command_rom is
  generic (
    COMMAND_0: std_logic_vector(24 downto 0) := '1' & X"000000";
    COMMAND_1: std_logic_vector(24 downto 0) := '1' & X"020808";
    COMMAND_2: std_logic_vector(24 downto 0) := '1' & X"040808";
    COMMAND_3: std_logic_vector(24 downto 0) := '1' & X"0a8000";
    COMMAND_4: std_logic_vector(24 downto 0) := '1' & X"180808";
    COMMAND_5: std_logic_vector(24 downto 0) := '1' & X"1a0404";
    COMMAND_6: std_logic_vector(24 downto 0) := '1' & X"1c0a0a";
    COMMAND_7: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_8: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_9: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_A: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_B: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_C: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_D: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_E: std_logic_vector(24 downto 0) := '0' & X"000000";
    COMMAND_F: std_logic_vector(24 downto 0) := '0' & X"000000"
    );
  port (
    ClkIn : in std_logic;

    ROMAddr : in std_logic_vector(3 downto 0);
    ROMData : out std_logic_vector(24 downto 0)

    );
end entity ac97_command_rom;


architecture IMP of ac97_command_rom is

  type command_ram_type is array(15 downto 0) of std_logic_vector(24 downto 0);
  constant command_rom : command_ram_type := (
    COMMAND_F, COMMAND_E, COMMAND_D, COMMAND_C,
    COMMAND_B, COMMAND_A, COMMAND_9, COMMAND_8,
    COMMAND_7, COMMAND_6, COMMAND_5, COMMAND_4,
    COMMAND_3, COMMAND_2, COMMAND_1, COMMAND_0
    );

begin
  -- ROM_STYLE
  process (ClkIn)
  begin
    if ClkIn'event and CLkIn='1' then
      ROMData <= command_rom(CONV_INTEGER(ROMAddr));
    end if;
  end process;

end architecture IMP;
