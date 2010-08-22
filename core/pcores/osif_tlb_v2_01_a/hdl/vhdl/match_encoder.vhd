------------------------------------------------------------------------------
-- priority encoder with mask input and match output
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity match_encoder is
	port
	(
		i_multi_match : in  std_logic_vector(31 downto 0);
		i_mask        : in  std_logic_vector(31 downto 0);
		o_match       : out std_logic;
		o_match_addr  : out std_logic_vector(4 downto 0)
	);

--      force priority encoder macro extraction:
--	
--	attribute priority_extract: string;
--	attribute priority_extract of match_encoder: entity is "force";

end entity;

architecture imp of match_encoder is
	signal m : std_logic_vector(31 downto 0);
begin

	m <= i_multi_match and i_mask;
	
	o_match <= '0' when m = X"00000000" else '1';
	
	o_match_addr <= "00000" when m( 0) = '1' else
	                "00001" when m( 1) = '1' else
	                "00010" when m( 2) = '1' else
	                "00011" when m( 3) = '1' else
	                "00100" when m( 4) = '1' else
	                "00101" when m( 5) = '1' else
	                "00110" when m( 6) = '1' else
	                "00111" when m( 7) = '1' else
	                "01000" when m( 8) = '1' else
	                "01001" when m( 9) = '1' else
	                "01010" when m(10) = '1' else
	                "01011" when m(11) = '1' else
	                "01100" when m(12) = '1' else
	                "01101" when m(13) = '1' else
	                "01110" when m(14) = '1' else
	                "01111" when m(15) = '1' else
	                "10000" when m(16) = '1' else
	                "10001" when m(17) = '1' else
	                "10010" when m(18) = '1' else
	                "10011" when m(19) = '1' else
	                "10100" when m(20) = '1' else
	                "10101" when m(21) = '1' else
	                "10110" when m(22) = '1' else
	                "10111" when m(23) = '1' else
	                "11000" when m(24) = '1' else
	                "11001" when m(25) = '1' else
	                "11010" when m(26) = '1' else
	                "11011" when m(27) = '1' else
	                "11100" when m(28) = '1' else
	                "11101" when m(29) = '1' else
	                "11110" when m(30) = '1' else
	                "11111" when m(31) = '1' else
	                "-----";

end architecture;


