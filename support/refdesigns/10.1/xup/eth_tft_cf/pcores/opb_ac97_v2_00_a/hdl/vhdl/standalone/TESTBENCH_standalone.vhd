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
-- Date:            $Date: 2005/02/18 15:30:22 $
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
  
  component standalone is
  port (
    ClkIn : in std_logic;
    Reset_n : in std_logic;
    LED : out std_logic_vector(3 downto 0);
    DEBUG : out std_logic_vector(4 downto 0);
                                 
    -- CODEC signals
    AC97Reset_n   : out  std_logic;          -- master clock for design
    AC97Clk   : in  std_logic;          -- master clock for design
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
  signal ac97_reset_n, fast_clk, reset_n : std_logic;
  
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
    reset_n <= '0';
    wait for 5 us;
    reset_n <= '1';
    wait;
  end process;

  uut : standalone
  port map (
    ClkIn => fast_clk,
    Reset_n => reset_n,
    LED => open,
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
