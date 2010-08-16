-------------------------------------------------------------------------------
-- Filename:        ac97_if_pkg.vhd
--
-- Description:     
-- 
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- Revision:        $Revision: 1.1 $
-- Date:            $Date: 2005/02/18 15:30:22 $
--
-- History:
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


package ac97_if_pkg is
  constant AC97_CMD_LENGTH : integer := 25;

  -- Command format V R AAAAAAA DDDDDDDD DDDDDDDD
  -- V = Valid command (1 = valid, 0 = invalid)
  -- R = Read (1=read, 0=write)
  -- A = Address (7 bits)
  -- D = Data (16 bits)

  -- Write 0x0 to 0x0 (reset registers)
  constant RESET_REGISTERS_CMD :
    std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '1' & X"000000";
  -- Write 0x808 to 0x2 (master volume 0db gain)
  constant MASTER_VOLUME_GAIN_CMD : std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '1' & X"020808";
  -- Write 0x808 to 0x4 (headphone vol)
  constant HEADPHONE_VOLUME_GAIN_CMD : std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '1' & X"040808";
  -- Write 0x8000 to 0xa (mute PC beep)
  constant MUTE_PC_BEEP_CMD : std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '1' & X"0a8000";
  -- Write 0x808 to 0x18 pcmoutvol (amp out line)
  constant PCMOUT_VOLUME_CMD : std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '0' & X"180808";
  -- Write 0x404 to 0x1a  record source (line in for left and right)
  constant RECORD_SOURCE_CMD : std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '1' & X"1a0404";
  -- Write (0x1c,0x008); // record gain (8 steps of 1.5 dB = +12.0 dB)
  constant RECORD_GAIN_CMD : std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '1' & X"1c0008";
  constant EMPTY_CMD : std_logic_vector(AC97_CMD_LENGTH-1 downto 0)
    := '0' & X"000000";

end ac97_if_pkg;

package body ac97_if_pkg is
end ac97_if_pkg;

