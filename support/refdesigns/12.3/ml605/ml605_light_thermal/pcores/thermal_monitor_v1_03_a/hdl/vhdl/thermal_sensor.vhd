		----------------------------------------------------------------------------------
-- Company:   University of Paderborn
-- Engineer:  Markus Happe
-- 
-- Create Date:    12:17:11 02/09/2011 
-- Design Name: 
-- Module Name:    thermal_sensor - Behavioral 
-- Project Name:   Thermal Sensor Net
-- Target Devices: Virtex 6 ML605
-- Tool versions:  12.3
-- Description: thermal sensor: ring oscilator that can be used as a temperature sensor.
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity thermal_sensor is
	generic (C_COUNTER_WIDTH : integer := 18);
	port ( -- clock
		clk : in  std_logic;
		-- reset
		rst : in  std_logic;
		-- enable ring oscilator
		osc_en : in  std_logic;
		-- enable recording
		rec_en : in  std_logic;
		-- data
		data   : out std_logic_vector(C_COUNTER_WIDTH - 1 downto 0);
		-- debug output: ring oscillator output
      osc_sig : out std_logic;
		-- debug output: count signal
		count_sig : out std_logic
	);
end thermal_sensor;

architecture Behavioral of thermal_sensor is

  attribute keep_hierarchy : string;
  attribute keep_hierarchy of Behavioral: architecture is "true";

  component ring_oscillator is
    generic ( C_OSC_SIZE : integer := 11);
    port ( rst : in  std_logic;
	        osc_en  : in  std_logic;
           osc_out : out  std_logic);
  end component;
  
  signal osc_out     : std_logic;
  signal osc_out_old : std_logic;
  signal osc_out_old_2 : std_logic;
  signal rec_en_old  : std_logic;
  signal counter     : std_logic_vector(C_COUNTER_WIDTH-1 downto 0); 

begin

  data <= counter;

  -- ring oscillator
  osc : component ring_oscillator 
          generic map (C_OSC_SIZE => 11)
          port map ( rst => rst, osc_en => osc_en, osc_out => osc_out);

  osc_sig <= osc_out;


  -- process that counts the ring_oscilator and shift them out
  count : process(clk, rst)
  begin
    if rst = '1' then
      -- reset old signals and counter
      rec_en_old <= rec_en;
		osc_out_old <= osc_out;
		osc_out_old_2 <= osc_out;
		counter <= (others=>'0');
		count_sig <= '0';
		--counter <= b"00011100001111";
    elsif rising_edge(clk) then
      -- store old signals for rec_en and osc_out
      rec_en_old <= rec_en;
		osc_out_old <= osc_out; 
		osc_out_old_2 <= osc_out_old;
		count_sig <= '0';
		--counter <= b"10000000000001";--XXX
		-- record a thermal measurement
		if rec_en = '1' then
		   -- if the ring oscillator has a rising edge, increase counter by 1
			--counter <= counter + 1;
			--counter <= b"10000000000001";
			if (osc_out_old='1' and osc_out_old_2='0') then
			    count_sig <= '1';
				 counter <= counter + 1;
			end if;
		   -- reset counter if a new record has started
		   if rec_en_old = '0' then
	         counter <= (others=>'0');
			end if;
		end if;

    end if;   		
  end process;

end Behavioral;