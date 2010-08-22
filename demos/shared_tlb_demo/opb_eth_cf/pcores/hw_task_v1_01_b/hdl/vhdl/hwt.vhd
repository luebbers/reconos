----------------------------------------------------------------------------------
-- Company: 
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hwt is
	
	generic (
		C_BURST_AWIDTH : integer := 12;
		C_BURST_DWIDTH : integer := 32
	);
	
	port (
		clk    : in  std_logic;
		reset  : in  std_logic;
		i_osif : in  osif_os2task_t;
		o_osif : out osif_task2os_t;
		
		-- burst ram interface
		o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
		o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
		i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic
	);
	
end entity;

architecture Behavioral of hwt is

	attribute keep_hierarchy               : string;
	attribute keep_hierarchy of Behavioral : architecture is "true";
	
	constant C_MBOX_GET : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0) := X"00000000";
	constant C_MBOX_PUT : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0) := X"00000001";

	type t_state is (
		STATE_GET_ITERATIONS,
		STATE_GET_ADDR,
	--	STATE_DEBUG,
	--	STATE_DEBUG2,
	--	STATE_DEBUG3,
		STATE_READ,
		STATE_COMPUTE_ADDR_1,
		STATE_COMPUTE_ADDR_2,
		STATE_SEND_RESULT,
		STATE_END
	);

	signal state       : t_state;
--	signal addr        : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
--	signal iterations  : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
--	signal counter     : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
--	signal seed        : std_logic_vector(15 downto 0);
--	signal input       : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
--	signal base_page   : std_logic_vector(19 downto 0);
--	signal offset      : std_logic_vector(11 downto 0);
begin
	-- burst ram interface is not used
	o_RAMAddr <= (others => '0');
	o_RAMData <= (others => '0');
	o_RAMWE   <= '0';
	o_RAMClk  <= clk;
	
	state_proc : process(clk, reset)
		variable addr        : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
		variable iterations  : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
		variable counter     : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
		variable seed        : std_logic_vector(15 downto 0);
		variable input       : std_logic_vector(C_OSIF_DATA_WIDTH-1 downto 0);
		variable base_page   : std_logic_vector(19 downto 0);
		variable offset      : std_logic_vector(11 downto 0);
		variable done : boolean;
		variable success : boolean;
	begin
		if reset = '1' then
			reconos_reset(o_osif, i_osif);
			state <= STATE_GET_ITERATIONS;
			addr := (others => '0');
			iterations := (others => '0');
			counter := (others => '0');
			seed := (others => '0');
			input := (others => '0');
			base_page := (others => '0');
			offset := (others => '0');
		elsif rising_edge(clk) then
			
			reconos_begin(o_osif, i_osif);
			
			if reconos_ready(i_osif) then
				case state is
				
				when STATE_GET_ITERATIONS =>
					reconos_mbox_get(done, success, o_osif, i_osif, C_MBOX_GET, iterations);
					if done then state <= STATE_GET_ADDR; end if;

				when STATE_GET_ADDR =>
					reconos_mbox_get(done, success, o_osif, i_osif, C_MBOX_GET, addr);
					if done and success then
						base_page := addr(31 downto 12); -- 0x480028
						offset := addr(11 downto 0);     -- 0x000
						state <= STATE_READ;
					end if;
				
--				when STATE_DEBUG =>
--					reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_PUT, addr); -- 0x48028000
--					if done and success then state <= STATE_READ; end if;
	
				when STATE_READ =>
					reconos_read(done, o_osif, i_osif, addr, input);
					if done then
						if counter = iterations then
							state <= STATE_SEND_RESULT;
						else
							state <= STATE_COMPUTE_ADDR_1;
							counter := counter + 1;
						end if;
					end if;

--				when STATE_DEBUG2 =>
--					reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_PUT, addr); -- 0x48028000
--					if done and success then state <= STATE_COMPUTE_ADDR_1; end if;

				when STATE_COMPUTE_ADDR_1 =>
					-- LFSR p(x) = x^16 + x^14 + x^13 + x^11 + 1
					seed := seed xor input(15 downto 0); -- 0 
					seed := ('0' & seed(15 downto 1)) xor (seed(0) & '0' & seed(0) & seed(0) & '0' & seed(0) & b"0000000000"); -- 0
					state <= STATE_COMPUTE_ADDR_2;

--				when STATE_DEBUG3 =>
--					reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_PUT, addr); -- 0x48028000
--					if done and success then state <= STATE_COMPUTE_ADDR_2; end if;
	
				when STATE_COMPUTE_ADDR_2 =>
					addr := (base_page + seed(5 downto 0)) & offset; -- 0x480028 000 
					state <= STATE_READ;
				
				when STATE_SEND_RESULT =>
					reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_PUT, X"5555" & seed);
					if done then state <= STATE_END; end if;

				when STATE_END =>

				end case;
			end if;
		end if;
	end process;
end Behavioral;

