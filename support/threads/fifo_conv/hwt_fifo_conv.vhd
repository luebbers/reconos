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

entity hwt_fifo_conv is

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

architecture Behavioral of hwt_fifo_conv is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	constant C_PIX_AWIDTH : natural := 9;
	constant C_LINE_AWIDTH : natural := 9;
	constant C_PIX_PER_LINE : natural := 320;
		
	-- os ressources
	constant C_FIFO_GET_HANDLE    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)
                                   := X"00000000";
	constant C_FIFO_PUT_HANDLE   : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)
                                   := X"00000001";
	
	type t_state is (
					  STATE_INIT,
					  STATE_READ_KERNEL,
					  STATE_PREPARE_PUT_LINE,
					  STATE_LOAD_A,
					  STATE_LOAD_B,
					  STATE_LOAD_C,
					  STATE_DISPATCH,
	              STATE_PUT_LINE,
					  STATE_GET_LINE,
					  STATE_READY,
					  STATE_PUT_LAPLACE,
					  STATE_GET,
					  STATE_PUT_LAPLACE_WAIT,
					  STATE_PUT_LAPLACE_WAIT2,
                 STATE_FINAL);
	
	signal state : t_state;
	signal next_line : std_logic;
	signal line_sel : std_logic_vector(1 downto 0);
	signal pix_sel : std_logic_vector(C_PIX_AWIDTH - 1 downto 0);
	signal local_addr : std_logic_vector(C_BURST_AWIDTH - 1 downto 0);
	signal last_line : std_logic;
	signal ready : std_logic;
	signal init_data : std_logic_vector(31 downto 0);
	
	signal r24 : std_logic_vector(23 downto 0);
	signal g24 : std_logic_vector(23 downto 0);
	signal b24 : std_logic_vector(23 downto 0);
	signal r8 : std_logic_vector(7 downto 0);
	signal g8 : std_logic_vector(7 downto 0);
	signal b8 : std_logic_vector(7 downto 0);
	signal pix_out : std_logic_vector(31 downto 0);
	signal conv_ien : std_logic;
	signal kernel : std_logic_vector(80 downto 0);
	
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
	
	conv_r : entity WORK.conv_filter3x3
	port map(
		clk => clk,
		rst => reset,
		shift_in => r24,
		shift_out => r8,
		ien => conv_ien,
		kernel => kernel
	);
	
	conv_g : entity WORK.conv_filter3x3
	port map(
		clk => clk,
		rst => reset,
		shift_in => g24,
		shift_out => g8,
		ien => conv_ien,
		kernel => kernel
	);
	
	conv_b : entity WORK.conv_filter3x3
	port map(
		clk => clk,
		rst => reset,
		shift_in => b24,
		shift_out => b8,
		ien => conv_ien,
		kernel => kernel
	);


	pix_out <= X"00" & b8 & g8 & r8;
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
		variable tmp : std_logic_vector(31 downto 0);
		variable kernel_counter : integer range 0 to 15;
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_INIT;
			next_line <= '0';
			line_sel <= (others => '0');
			pix_sel <= (others => '0');
			conv_ien <= '0';
			init_data <= (others => '0');
			kernel_counter := 0;
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
					when STATE_INIT =>
						reconos_get_init_data_s (done, o_osif, i_osif, init_data);
						next_line <= '1';
						if done then state <= STATE_READ_KERNEL; end if;
					
					when STATE_READ_KERNEL =>
						reconos_read(done, o_osif, i_osif,
                            init_data + 4*kernel_counter, tmp);
						if done then
							kernel(9*kernel_counter + 8 downto 9*kernel_counter) <= tmp(8 downto 0);
							kernel_counter := kernel_counter + 1;
							if kernel_counter = 9 then
								kernel_counter := 0;
								state <= STATE_GET_LINE;
							end if;
						end if;

					
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
						state <= STATE_DISPATCH;
						
					when STATE_DISPATCH =>
						r24 <= pix_a(7 downto 0) & pix_b(7 downto 0) & pix_c(7 downto 0);
						g24 <= pix_a(15 downto 8) & pix_b(15 downto 8) & pix_c(15 downto 8);
						b24 <= pix_a(23 downto 16) & pix_b(23 downto 16) & pix_c(23 downto 16);						
						conv_ien <= '1';
						state <= STATE_PUT_LAPLACE_WAIT;

								
					when STATE_PUT_LAPLACE_WAIT =>
						conv_ien <= '0';
						state <= STATE_PUT_LAPLACE_WAIT2;
						
					when STATE_PUT_LAPLACE_WAIT2 =>
						state <= STATE_PUT_LAPLACE;
								
					when STATE_PUT_LAPLACE =>
						reconos_mbox_put(done,success,o_osif,i_osif,C_FIFO_PUT_HANDLE,
								pix_out);
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
