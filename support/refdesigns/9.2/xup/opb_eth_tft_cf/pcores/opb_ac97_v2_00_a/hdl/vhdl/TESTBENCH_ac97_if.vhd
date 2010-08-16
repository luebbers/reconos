-------------------------------------------------------------------------------
-- TESTBENCH_standalone.vhd
-------------------------------------------------------------------------------
-- Filename:        TESTBENCH_standalone.vhd
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
-- Date:            $Date: 2005/02/18 15:30:21 $
--
-- History:
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity TESTBENCH_standalone is
end TESTBENCH_standalone;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;
use opb_ac97_v2_00_a.testbench_ac97_package.all;

architecture behavioral of TESTBENCH_standalone is
  
component ac97_if is
  port (
    ClkIn : in std_logic;
    Reset : in std_logic;
    
    PCM_Playback_Left: in std_logic_vector(15 downto 0);
    PCM_Playback_Right: in std_logic_vector(15 downto 0);
    PCM_Playback_Accept: out std_logic;
    
    PCM_Record_Left: out std_logic_vector(15 downto 0);
    PCM_Record_Right: out std_logic_vector(15 downto 0);
    PCM_Record_Valid: out std_logic;

    Debug : out std_logic_Vector(3 downto 0);
    
    AC97Reset_n : out std_logic;        -- AC97Clk
    AC97Clk   : in  std_logic;
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic

    );

end component;

  component ac97_model is
  port (
    AC97Reset_n   : in  std_logic;         
    Bit_Clk   : out  std_logic;
    Sync      : in std_logic;
    SData_Out : in std_logic;
    SData_In  : out  std_logic
    );
  end component;

  signal bit_clk, sync, sdata_out, sdata_in : std_logic;
  signal ac97_reset_n, fast_clk, reset : std_logic;
  signal pcm_play_left, pcm_play_right : std_logic_vector(15 downto 0);
  signal pcm_record_left, pcm_record_right : std_logic_vector(15 downto 0) := (others => '0');
                                                                             

  begin  -- behavioral

  clk_PROCESS : process is
  begin
    fast_clk <= '0';
    wait for 5 ns;
    fast_clk <= '1';
    wait for 5 ns;    
  end process;

  reset_PROCESS : process is
  begin
    reset <= '1';
    wait for 5 us;
    reset <= '0';
    wait;
  end process;

  uut : ac97_if
  port map (

    ClkIn => fast_clk,
    Reset => reset,
    
    PCM_Playback_Left => pcm_play_left,
    PCM_Playback_Right => pcm_play_right,
    PCM_Playback_Accept => open,
    
    PCM_Record_Left => pcm_record_left,
    PCM_Record_Right => pcm_record_right,
    PCM_Record_Valid => open,

    Debug => open,
    
    AC97Reset_n => ac97_reset_n,
    AC97Clk => Bit_Clk,
    Sync => Sync,
    SData_Out => SData_Out,
    SData_In => SData_In

    );

  uut_1 : ac97_model
  port map (
    -- CODEC signals
    AC97Reset_n => ac97_reset_n,
    Bit_Clk => Bit_Clk,
    Sync => Sync,
    SData_Out => SData_Out,
    SData_In => SData_In
    );

end behavioral;
