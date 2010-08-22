------------------------------------------------------------------------------
-- TLB arbiter implementation
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library tlb_arbiter_v2_01_a;
use tlb_arbiter_v2_01_a.all;

entity tlb_arbiter is
	generic
	(
		C_TAG_WIDTH               : integer          := 20;
		C_DATA_WIDTH              : integer          := 21    
	);
	port
	(
		sys_clk               : in  std_logic;
		sys_reset               : in  std_logic;
		
		-- TLB client A
		i_tag_a           : in  std_logic_vector(C_TAG_WIDTH - 1 downto 0);
		i_data_a          : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		o_data_a          : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		i_request_a       : in  std_logic;
		i_we_a            : in  std_logic;
		o_match_a         : out std_logic;
		o_busy_a          : out std_logic;

		-- TLB client B
		i_tag_b           : in  std_logic_vector(C_TAG_WIDTH - 1 downto 0);
		i_data_b          : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		o_data_b          : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		i_request_b       : in  std_logic;
		i_we_b            : in  std_logic;
		o_match_b           : out std_logic;
		o_busy_b          : out std_logic;

		-- TLB
		o_tlb_tag          : out std_logic_vector(C_TAG_WIDTH - 1 downto 0);
		i_tlb_data         : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		o_tlb_data         : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		i_tlb_match        : in  std_logic;
		o_tlb_we           : out std_logic;
		i_tlb_busy         : in  std_logic
	);
end entity;

architecture imp of tlb_arbiter is
	signal active          : std_logic;
	signal counter         : std_logic;
	signal busy_a          : std_logic;
	signal busy_b          : std_logic;
begin
	o_data_a <= i_tlb_data;
	o_data_b <= i_tlb_data;
	o_match_a <= i_tlb_match;
	o_match_b <= i_tlb_match;

--	active <= busy_a = '0' or busy_b = '0';
	active <= not (busy_a and busy_b);

	handle_request : process(sys_clk,sys_reset)
	begin
		if sys_reset = '1' then
			busy_a <= '1';
			busy_b <= '1';
			counter <= '0';
		elsif rising_edge(sys_clk) then
			if active = '1' then -- wait for end of request
				if busy_a = '0' and i_request_a = '0' then busy_a <= '1'; end if;
				if busy_b = '0' and i_request_b = '0' then busy_b <= '1'; end if;
			else           -- check incoming requests
				if    i_request_a = '1' and i_request_b = '1' then
					if counter = '0' then busy_a <= '0'; end if;
					if counter = '1' then busy_b <= '0'; end if;
					counter <= not counter; -- increment counter
				elsif i_request_a = '1' and i_request_b = '0' then
					busy_a <= '0';
				elsif i_request_a = '0' and i_request_b = '1' then
					busy_b <= '0';
				end if;
			end if;
		end if;
	end process;
	
	mux : process(busy_a, busy_b, i_tag_a, i_tag_b, i_data_a, i_data_b, i_we_a, i_we_b, i_tlb_busy)
	begin
		if busy_a = '0' then
			o_tlb_tag   <=  i_tag_a;     -- client to TLB
			o_tlb_data  <=  i_data_a;    -- client to TLB
			o_tlb_we    <=  i_we_a;      -- client to TLB
			o_busy_a    <=  i_tlb_busy;  -- TLB to client
			o_busy_b    <=  '1';
		elsif busy_b = '0' then
			o_tlb_tag   <=  i_tag_b;     -- client to TLB
			o_tlb_data  <=  i_data_b;    -- client to TLB
			o_tlb_we    <=  i_we_b;      -- client to TLB
			o_busy_a    <=  '1';
			o_busy_b    <=  i_tlb_busy;  -- TLB to client
		else
			o_tlb_tag   <=  (others => '0');
			o_tlb_data  <=  (others => '0');
			o_tlb_we    <=  '0';
			o_busy_a    <=  '1';
			o_busy_b    <=  '1';
		end if;
	end process;

end architecture;

