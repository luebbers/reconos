------------------------------------------------------------------------------
-- TLB implementation with asynchronous read and synchronous write.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library osif_tlb_v2_01_a;
use osif_tlb_v2_01_a.all;

entity tlb is
	generic
	(
		C_TAG_WIDTH               : integer          := 20;
		C_DATA_WIDTH              : integer          := 21    
	);
	port
	(
		clk               : in  std_logic;
		rst               : in  std_logic;
		
		i_tag             : in  std_logic_vector(C_TAG_WIDTH - 1 downto 0);
		i_data            : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		o_data            : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		
		i_we              : in  std_logic;
		o_busy            : out std_logic;
		o_wdone           : out std_logic;
		o_match           : out std_logic;
		i_invalidate      : in  std_logic
	);
end entity;

architecture imp of tlb is
	component cam27x32
		port (
			clk          : in  std_logic;
			din          : in  std_logic_vector(26 downto 0);
			we           : in  std_logic;
			wr_addr      : in  std_logic_vector(4 downto 0);
			busy         : out std_logic;
			match        : out std_logic;
			match_addr   : out std_logic_vector(31 downto 0);
			single_match : out std_logic
		);
	end component;

	component cam27x32b
		port (
			clk          : in  std_logic;
			din          : in  std_logic_vector(26 downto 0);
			we           : in  std_logic;
			wr_addr      : in  std_logic_vector(4 downto 0);
			busy         : out std_logic;
			match        : out std_logic;
			match_addr   : out std_logic_vector(31 downto 0);
			single_match : out std_logic
		);
	end component;

	-- content addressable RAM with depth 32 and 27 bit width (~ 3 BRAMS)
	component cam27x32m
		port (
			clk          : in  std_logic;
			din          : in  std_logic_vector(26 downto 0);
			we           : in  std_logic;
			wr_addr      : in  std_logic_vector(4 downto 0);
			busy         : out std_logic;
			match        : out std_logic;
			match_addr   : out std_logic_vector(31 downto 0)
		);
	end component;

	
	constant C_CAM_WIDTH : natural := 27;
	constant C_CAM_DEPTH : natural := 32;
	
	-- data entries
	type rpn_array_t is array(C_CAM_DEPTH - 1 downto 0) of std_logic_vector(C_DATA_WIDTH - 1 downto 0);
		
	signal din               : std_logic_vector(C_CAM_WIDTH - 1 downto 0);
	signal pad               : std_logic_vector(C_CAM_WIDTH - 1 - C_TAG_WIDTH downto 0);
	signal waddr             : std_logic_vector(4 downto 0);
	signal match             : std_logic;
	signal match_addr        : std_logic_vector(4 downto 0);
	signal multi_match_addr  : std_logic_vector(C_CAM_DEPTH - 1 downto 0);
	signal busy              : std_logic;
	signal data_rpn          : rpn_array_t;
	signal data_valid        : std_logic_vector(C_CAM_DEPTH - 1 downto 0);
	signal we                : std_logic;
begin

	pad <= (others => '0');
	din <= i_tag & pad;
	o_busy <= busy;
	
	--output_or : process(match_addr, data_rpn, data_valid, match)
		--variable tmp : std_logic_vector(C_DATA_WIDTH - 1 downto 0);
	--begin
		--if rising_edge(clk) then
			o_data <= data_rpn(CONV_INTEGER(match_addr));
			o_match <= data_valid(CONV_INTEGER(match_addr)) and match;
		--end if;	
	--end process;
	
	write_sync : process(clk, rst, i_invalidate)
		variable step : integer range 0 to 1;
	begin
		if rst = '1' or i_invalidate = '1' then
			data_valid <= (others => '0');
			step := 0;
		elsif rising_edge(clk) then
			we <= '0';
			case step is
				when 0 =>
					o_wdone <= '0';
					if i_we = '1' and busy = '0' then
						data_rpn(CONV_INTEGER(waddr)) <= i_data;
						data_valid(CONV_INTEGER(waddr)) <= '1';
						we <= '1';
						step := 1;
					end if;
				when 1 =>
					waddr <= waddr + 1;
					o_wdone <= '1';
					step := 0;
			end case;
		end if;
	end process;

	i_match_encoder : entity osif_tlb_v2_01_a.match_encoder
	port map (
		i_multi_match  =>  multi_match_addr,
		i_mask         =>  data_valid,
		o_match_addr   =>  match_addr,
		o_match        =>  match
	);
	
	i_cam27x32 : cam27x32m
	port map (
		clk          => clk,
		din          => din,
		we           => we,
		wr_addr      => waddr,
		busy         => busy,
		--match        => match,
		match_addr   => multi_match_addr
	);
	
end architecture;

