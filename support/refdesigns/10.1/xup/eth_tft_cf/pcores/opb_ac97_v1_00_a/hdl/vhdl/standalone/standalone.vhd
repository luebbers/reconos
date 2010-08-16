-------------------------------------------------------------------------------
-- Filename:        standalone.vhd
--
-- Description:     Sample circuit for doing audio standalone
-- 
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
-- Revision:        $Revision: 1.1 $
-- Date:            $Date: 2005/02/17 20:26:29 $
--
-- History:
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity standalone is
  port (
    ClkIn : in std_logic;
    Reset_n : in std_logic;

    LED : out std_logic_vector(3 downto 0);
    DEBUG : out std_logic_vector(4 downto 0);
 
    -- CODEC signals
    AC97Reset_n : out std_logic;
    AC97Clk   : in  std_logic;          -- master clock for design
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic
    );
end standalone;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;
use opb_ac97_v2_00_a.ac97_if_pkg.all;

architecture imp of standalone is

  signal new_sample : std_logic;
  signal left_channel_0 : std_logic_Vector(15 downto 0) := "0000000000000000";
  signal right_channel_0 : std_logic_Vector(15 downto 0) := "0000000000000000";
  signal left_channel_1 : std_logic_Vector(15 downto 0) := "0000000000000000";
  signal right_channel_1 : std_logic_Vector(15 downto 0) := "0000000000000000";
  signal left_channel_2 : std_logic_Vector(15 downto 0) := "0000000000000000";
  signal right_channel_2 : std_logic_Vector(15 downto 0) := "0000000000000000";
  signal leds_i : std_logic_vector(3 downto 0);

  signal clkin_cntr : unsigned(26 downto 0) := (others => '0');
  signal ac97clk_cntr : unsigned(26 downto 0) := (others => '0');

  signal debug_i : std_logic_vector(3 downto 0);
  signal reset_i : std_logic;

  signal ac97reset_n_i,sync_i,sdata_out_i : std_logic;
  
  component ac97_if is
  port (
    ClkIn : in std_logic;
    Reset : in std_logic;
    
    -- All signals synchronous to ClkIn
    PCM_Playback_Left: in std_logic_vector(15 downto 0);
    PCM_Playback_Right: in std_logic_vector(15 downto 0);
    PCM_Playback_Accept: out std_logic;
    
    PCM_Record_Left: out std_logic_vector(15 downto 0);
    PCM_Record_Right: out std_logic_vector(15 downto 0);
    PCM_Record_Valid: out std_logic;

    Debug : out std_logic_vector(3 downto 0);
    
    AC97Reset_n : out std_logic;        -- AC97Clk
    
    -- CODEC signals (synchronized to AC97Clk)
    AC97Clk   : in  std_logic;
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic

    );
  end component ac97_if;

begin  

  reset_i <= not Reset_n;
  
  delay_PROCESS : process (ClkIn) is
  begin
    if ClkIn'event and ClkIn='1' and new_sample = '1' then
      left_channel_1 <= left_channel_0;
      right_channel_1 <= right_channel_0;

      left_channel_2 <= left_channel_1;
      right_channel_2 <= right_channel_1;
    end if;
  end process;
  
  LED <= not debug_i;
  
  ac97_if_I : ac97_if
  port map (
      ClkIn => ClkIn,
      Reset => Reset_i,
    
      PCM_Playback_Left => left_channel_2,
      PCM_Playback_Right => right_channel_2,
      PCM_Playback_Accept => new_sample,

      PCM_Record_Left => left_channel_0,
      PCM_Record_Right => right_channel_0,
      PCM_Record_Valid => open,

      Debug => debug_i,
      
      AC97Reset_n => AC97Reset_n_i,
      AC97Clk => AC97Clk,
      Sync => sync_i,
      SData_Out => SData_Out_i,
      SData_In => SData_in
    );
  AC97Reset_n <= AC97Reset_n_i;
  Sync <= sync_i;
  SData_Out <= SData_Out_i;
  
  DEBUG(0) <= AC97Clk;
  DEBUG(1) <= AC97Reset_n_i;
  DEBUG(2) <= Sync_i;
  DEBUG(3) <= SData_Out_i;
  DEBUG(4) <= SData_In;

end architecture imp;
  
