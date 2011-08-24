----------------------------------------------------------------------------------
-- Company:   University of Paderborn
-- Engineer:  Markus Happe
-- 
-- Create Date:    16:04:47 02/09/2011 
-- Design Name: 
-- Module Name:    inv_comp - Behavioral 
-- Module Name:    delay_comp - Behavioral 
-- Project Name:   Thermal Sensor Net
-- Target Devices: Virtex 6 ML605
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity inv_comp is
    port ( rst   : in   std_logic;
	        x_in  : in   std_logic;
           x_out : out  std_logic);
end inv_comp;

architecture Behavioral of inv_comp is

  attribute keep_hierarchy : string;
  attribute keep_hierarchy of Behavioral: architecture is "true";
  signal x : std_logic;
  attribute KEEP : string; 
  attribute KEEP of x : signal is "true";
  attribute INIT : string; 
  attribute INIT of invert_lut  : label is "B"; 
  
begin

  x_out <= x;
  
  invert_lut: LUT2
  --synthesies translate_off
    generic map (INIT => X"B") 
    --synthesies translate_on
    port map( I0 => rst,
            I1 => x_in,
             O => x
  );

end Behavioral;

