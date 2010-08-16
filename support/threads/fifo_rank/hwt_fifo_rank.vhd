library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v1_03_a;
use reconos_v1_03_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hwt_fifo_rank is

	generic (
		C_BURST_AWIDTH : integer := 11;
		C_BURST_DWIDTH : integer := 32
	);
	
	port (
		clk : in std_logic;
		reset : in std_logic;
		i_osif : in osif_os2task_t;
		o_osif : out osif_task2os_t;

		-- burst ram interface
		o_RAMAddr : out std_logic_vector( 0 to C_BURST_AWIDTH-1 );
		o_RAMData : out std_logic_vector( 0 to C_BURST_DWIDTH-1 );
		i_RAMData : in std_logic_vector( 0 to C_BURST_DWIDTH-1 );
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic
	);
end entity;

architecture Behavioral of hwt_fifo_rank is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	constant FRAME_SIZE : natural := 320*240*4;
	constant C_PIX_AWIDTH : natural := 9;
	constant C_LINE_AWIDTH : natural := 9;
	constant C_PIX_PER_LINE : natural := 320;
	
	constant C_MODE_PASSTHROUGH : std_logic_vector(6 downto 0)
	                            := B"0000001";

	constant C_MODE_MEDIAN      : std_logic_vector(6 downto 0)
	                            := B"0000010";
										 										 
	constant C_MODE_RED         : std_logic_vector(6 downto 0)
	                            := B"0000100";

	constant C_MODE_GREEN       : std_logic_vector(6 downto 0)
	                            := B"0001000";

	constant C_MODE_BLUE        : std_logic_vector(6 downto 0)
	                            := B"0010000";
										 		 			 
	
	-- os ressources
	constant C_FIFO_GET_HANDLE    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)
                                   := X"00000000";
	constant C_FIFO_PUT_HANDLE   : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)
                                   := X"00000001";
	
	type t_state is (
					  STATE_INIT,
					  STATE_PREPARE_PUT_LINE,
					  STATE_LOAD_A,
					  STATE_LOAD_B,
					  STATE_LOAD_C,
					  STATE_DISPATCH,
	              STATE_PUT_LINE,
					  STATE_GET_LINE,
					  STATE_READY,
					  STATE_PUT_MEDIAN,
					  STATE_PUT_PASSTHROUGH,
					  STATE_PUT_RED,
					  STATE_PUT_GREEN,
					  STATE_PUT_BLUE,
					  STATE_GET,
                 STATE_FINAL);
	
	signal state : t_state;
	signal next_line : std_logic;
	signal line_sel : std_logic_vector(1 downto 0);
	signal pix_sel : std_logic_vector(C_PIX_AWIDTH - 1 downto 0);
	signal local_addr : std_logic_vector(C_BURST_AWIDTH - 1 downto 0);
	signal last_line : std_logic;
	signal ready : std_logic;
	--signal frame_offset : std_logic_vector(C_PIX_AWIDTH + C_LINE_AWIDTH - 1 downto 0); -- not used
	signal frame_addr : std_logic_vector(31 downto 0);
	signal init_data : std_logic_vector(31 downto 0);
	signal filter_mode : std_logic_vector(6 downto 0);
	
	signal r24 : std_logic_vector(23 downto 0);
	signal g24 : std_logic_vector(23 downto 0);
	signal b24 : std_logic_vector(23 downto 0);
	signal r8 : std_logic_vector(7 downto 0);
	signal g8 : std_logic_vector(7 downto 0);
	signal b8 : std_logic_vector(7 downto 0);
	signal pix_out : std_logic_vector(31 downto 0);
	signal rank_ien : std_logic;
begin

	lag : entity WORK.line_addr_generator
	port map (
		rst => reset,
		next_line => next_line,
		line_sel => line_sel,
		frame_offset => open,
		pix_sel => pix_sel,
		bram_addr => local_addr,
		last_line => last_line,
		ready => ready
	);
	
	rank_r : entity WORK.rank_filter3x3
	port map(
		clk => clk,
		rst => reset,
		shift_in => r24,
		shift_out => r8,
		ien => rank_ien,
		rank => init_data(3 downto 0)
	);
	
	rank_g : entity WORK.rank_filter3x3
	port map(
		clk => clk,
		rst => reset,
		shift_in => g24,
		shift_out => g8,
		ien => rank_ien,
		rank => init_data(3 downto 0)
	);
	
	rank_b : entity WORK.rank_filter3x3
	port map(
		clk => clk,
		rst => reset,
		shift_in => b24,
		shift_out => b8,
		ien => rank_ien,
		rank => init_data(3 downto 0)
	);


	pix_out <= X"00" & b8 & g8 & r8;
	filter_mode <= init_data(30 downto 24);	
	o_RAMAddr <= local_addr(C_BURST_AWIDTH-1 downto 1) & not local_addr(0);
	o_RAMClk <= clk;

	state_proc: process( clk, reset )
		variable done : boolean;
		variable success : boolean;
		variable burst_counter : integer;
		variable pix_a : std_logic_vector(31 downto 0);
		variable pix_b : std_logic_vector(31 downto 0);
		variable pix_c : std_logic_vector(31 downto 0);
		variable invert : std_logic_vector(31 downto 0);
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_INIT;
			frame_addr <= (others => '0');
			next_line <= '0';
			line_sel <= (others => '0');
			pix_sel <= (others => '0');
			burst_counter := 0;
			rank_ien <= '0';
			init_data <= (others => '0');
			invert := (others => '0');
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
					when STATE_INIT =>
						reconos_get_init_data_s (done, o_osif, i_osif, init_data);
						next_line <= '1';
						if done then state <= STATE_GET_LINE; end if;
						
					when STATE_GET_LINE =>
						o_RAMWE <= '0';
						if pix_sel = C_PIX_PER_LINE - 1 then
							pix_sel <= (others => '0');
							next_line <= '0';
							state <= STATE_READY;
						else
							pix_sel <= pix_sel + 1;
							state <= STATE_GET;
						end if;
						
					when STATE_GET =>
						o_RAMwe <= '1';
						reconos_mbox_get_s(done,success,o_osif,i_osif,C_FIFO_GET_HANDLE,o_RAMData);
						if done then
							state <= STATE_GET_LINE;
						end if;

					when STATE_READY =>
						if last_line = '1' then
							state <= STATE_FINAL;
						elsif ready = '0' then
							next_line <= '1';
							state <= STATE_GET_LINE;
						else
							next_line <= '1';
							state <= STATE_PREPARE_PUT_LINE;
						end if;
						
					when STATE_PREPARE_PUT_LINE =>
						state <= STATE_PUT_LINE;
						
					when STATE_PUT_LINE =>
						-- handle output invert
						if init_data(31) = '1' then
							invert := X"FFFFFFFF";
						else
							invert := X"00000000";
						end if;
						
						o_RAMwe <= '0';
						line_sel <= B"00";     -- keep addr -> 0 (default)
						if pix_sel = C_PIX_PER_LINE - 1 then
							pix_sel <= (others => '0');
							state <= STATE_GET_LINE;
						else
							line_sel <= B"01";  -- addr -> 1
							pix_sel <= pix_sel + 1;
							state <= STATE_LOAD_A;
						end if;
						
					when STATE_LOAD_A =>
						line_sel <= B"10";     -- addr -> 2
						pix_a := i_RAMData;    -- load -> 0
						state <= STATE_LOAD_B;
						
					when STATE_LOAD_B =>
						pix_b := i_RAMData;    -- addr -> 0
						line_sel <= B"00";     -- load -> 1
						state <= STATE_LOAD_C;
						
					when STATE_LOAD_C =>
						pix_c := i_RAMData;    -- load -> 2
						--line_sel <= B"00";
						state <= STATE_DISPATCH;
						
					when STATE_DISPATCH =>
						r24 <= pix_a(7 downto 0) & pix_b(7 downto 0) & pix_c(7 downto 0);
						g24 <= pix_a(15 downto 8) & pix_b(15 downto 8) & pix_c(15 downto 8);
						b24 <= pix_a(23 downto 16) & pix_b(23 downto 16) & pix_c(23 downto 16);						
						rank_ien <= '1';
						
						case filter_mode is
							when C_MODE_MEDIAN =>
								state <= STATE_PUT_MEDIAN;
							when C_MODE_PASSTHROUGH =>
								state <= STATE_PUT_PASSTHROUGH;
							when C_MODE_RED =>
								state <= STATE_PUT_RED;
							when C_MODE_GREEN =>
								state <= STATE_PUT_GREEN;
							when C_MODE_BLUE =>
								state <= STATE_PUT_BLUE;
							when others =>
								state <= STATE_PUT_PASSTHROUGH;
						end case;
								
					when STATE_PUT_MEDIAN =>
						rank_ien <= '0';
						reconos_mbox_put(done,success,o_osif,i_osif,C_FIFO_PUT_HANDLE,
								invert xor pix_out);
						if done then
							state <= STATE_PUT_LINE;
						end if;
						
					when STATE_PUT_PASSTHROUGH =>
						reconos_mbox_put(done,success,o_osif,i_osif,C_FIFO_PUT_HANDLE,
								invert xor pix_b);
						if done then
							state <= STATE_PUT_LINE;
						end if;
						
					when STATE_PUT_RED =>
						reconos_mbox_put(done,success,o_osif,i_osif,C_FIFO_PUT_HANDLE,
								invert xor (X"00" & r24));
						if done then
							state <= STATE_PUT_LINE;
						end if;						
					
					when STATE_PUT_GREEN =>
						reconos_mbox_put(done,success,o_osif,i_osif,C_FIFO_PUT_HANDLE,
								invert xor (X"00" & g24));
						if done then
							state <= STATE_PUT_LINE;
						end if;						
					
					when STATE_PUT_BLUE =>
						reconos_mbox_put(done,success,o_osif,i_osif,C_FIFO_PUT_HANDLE,
								invert xor (X"00" & b24));
						if done then
							state <= STATE_PUT_LINE;
						end if;						
					
					when STATE_FINAL =>
						state <= STATE_FINAL;
						
				end case;
			end if;
		end if;
	end process;
end architecture;

