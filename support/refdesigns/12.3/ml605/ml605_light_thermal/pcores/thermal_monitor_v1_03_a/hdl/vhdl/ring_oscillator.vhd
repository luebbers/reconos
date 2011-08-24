----------------------------------------------------------------------------------
-- Company:  University of Paderborn
-- Engineer: Markus Happe
-- 
-- Create Date:    15:04:59 02/09/2011 
-- Design Name: 
-- Module Name:    ring_oscillator - Behavioral 
-- Project Name:   Thermal Sensor Net
-- Target Devices: Virtex 6 ML605
-- Tool versions:  12.3
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity ring_oscillator is
    -- generic for size of ring oscillator ( = number of inverters)
    generic ( C_OSC_SIZE : integer := 11);
    port ( 
	    -- reset
	    rst     : in  std_logic;
		 -- enable
       osc_en  : in  std_logic;
		 -- outgoing signal
       osc_out : out std_logic);
end ring_oscillator;

architecture Behavioral of ring_oscillator is

  attribute keep_hierarchy : string;
  attribute keep_hierarchy of Behavioral: architecture is "true";

  component delay_comp is
    port ( rst   : in   std_logic;
           x_in  : in   std_logic;
           x_out : out  std_logic);
  end component;
  
  component inv_comp is
    port ( rst   : in   std_logic;
           x_in  : in   std_logic;
           x_out : out  std_logic);
  end component; 

  signal x : std_logic_vector (1*C_OSC_SIZE downto 0);
  attribute KEEP : string; 
  attribute KEEP of x : signal is "true"; 
  
  signal toggle           : std_logic;
  signal clk_div2         : std_logic;
  
  attribute INIT : string; 
  attribute INIT of div2_lut : label is "1"; 

begin
	
	 osc_out <= clk_div2;

    toggle_flop: FD
    port map ( D => toggle,
             Q => clk_div2,
             C => x(0)
				 );

    div2_lut: LUT2
    --synthesies translate_off
    generic map (INIT => X"1")
    --synthesies translate_on
    port map( I0 => rst,
            I1 => clk_div2,
             O => toggle 
				 );
				 
    out_lut: AND2
    port map( I0 => osc_en,
            I1 => x(1*C_OSC_SIZE),
             O => x(0)
    );
	
	-- ring oscillator
	ring : for i in 0 to C_OSC_SIZE - 1 generate
	
	begin
	
--	    delay_1 : delay_comp 
--         port map( 
--           rst   => rst,
--           x_in  => x(0+(i*3)), 
--           x_out => x(1+(i*3))
--         );
--
--	    delay_2 : delay_comp 
--         port map( 
--           rst   => rst,
--           x_in  => x(1+(i*3)), 
--           x_out => x(2+(i*3))
--         );
			
--	    delay_3 : delay_comp 
--         port map( 
--           rst   => rst,
--           x_in  => x(2+(i*5)), 
--           x_out => x(3+(i*5))
--         );
--			
--	    delay_4 : delay_comp 
--         port map( 
--           rst   => rst,
--           x_in  => x(3+(i*5)), 
--           x_out => x(4+(i*5))
--         );
			
	    inv_1 : inv_comp 
         port map( 
           rst   => rst,
           x_in  => x(0+(i*1)), 
           x_out => x(1+(i*1))
         );	
	
	end generate ring;
	
end Behavioral;
