----------------------------------------------------------------------------------
-- Company:   University of Paderborn
-- Engineer:  Markus Happe
-- 
-- Create Date:    16:03:25 02/09/2011 
-- Design Name: 
-- Module Name:    delay_comp - Behavioral 
-- Project Name:   Thermal Sensor Net
-- Target Devices: Virtex 6 ML605
-- Tool versions:  12.3
-- Description: delay lut for ring oscillator
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

library UNISIM;
use UNISIM.VComponents.all;

entity delay_comp is
    Port ( rst   : in   std_logic;
           x_in  : in   std_logic;
           x_out : out  std_logic);
end delay_comp;

architecture Behavioral of delay_comp is

  signal x : std_logic;
  attribute KEEP : string; 
  attribute KEEP of x : signal is "true"; 
  --attribute INIT : string; 
  --attribute INIT of delay_lut  : label is "4"; 

begin

  x_out <= x;
  delay_lut: LUT2
  --synthesis translate_off
    generic map (INIT => X"4")
  --synthesis translate_on
  port map( I0 => rst,
            I1 => x_in,
             O => x
   );

end Behavioral;
