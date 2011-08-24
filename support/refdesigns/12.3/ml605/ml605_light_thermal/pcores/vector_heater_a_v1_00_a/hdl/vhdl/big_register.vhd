library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.numeric_std.all;


entity big_register is
  generic
  (
       C_REGISTER_LENGTH : integer := 10000
  );
  port
  (
       clk     : in std_logic;
		 rst     : in std_logic;
		 ce      : in std_logic; -- clock enable
		 xor_sig : out std_logic -- xor of all register bits
	 
	);
end entity big_register;


architecture behavioral of big_register is

  signal vector : std_logic_vector(0 to C_REGISTER_LENGTH-1);

begin

  -- for active heater: invert vector and write number of 1s vector into output signal
  change_vector : process (rst, clk) is
  variable bit_temp : std_logic;
  begin
    if rst = '1' then
	    vector(1 to C_REGISTER_LENGTH-1) <= (others=>'0');
		 vector(0) <= '1';
		 xor_sig <= '0';
	 elsif rising_edge(clk) then
	    if ce = '1' then
	        vector <= not vector;
			  bit_temp := '0';
		     for i in 0 to C_REGISTER_LENGTH-1 loop
			     bit_temp := bit_temp xor vector(i);
	        end loop;
			  xor_sig <= bit_temp;
		 end if;
	 end if;
  end process;


end behavioral;
