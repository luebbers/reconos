--**************************************************************************
-- $Id$
--
-- hwt_build_histo.vhd: ReconOS package
--
-- This hardware thread creates a histogram over a sequence of bytes. The
-- input is received in a sequence of blocks via a posix message queue.
-- After receiving the last block, the histogram is send to the outgoing
-- message queue.
--
-- Author : Andreas Agne <agne@upb.de>
-- Created: 1.8.2008
--*************************************************************************/

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity hwt_build_histo is

	generic (
		C_BURST_AWIDTH : integer := 11;
		C_BURST_DWIDTH : integer := 32
	);
	
	port (
		clk    : in  std_logic;
		reset  : in  std_logic;
		i_osif : in  osif_os2task_t;
		o_osif : out osif_task2os_t;

		-- burst ram interface
		o_RAMAddr : out std_logic_vector( C_BURST_AWIDTH-1 downto 0);
		o_RAMData : out std_logic_vector( C_BURST_DWIDTH-1 downto 0);
		i_RAMData : in  std_logic_vector( C_BURST_DWIDTH-1 downto 0);
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic
	);
	
end entity;

architecture Behavioral of hwt_build_histo is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	constant C_MQ_IN  : std_logic_vector(31 downto 0) := X"00000000";
	constant C_MQ_OUT : std_logic_vector(31 downto 0) := X"00000001";

	-- ReconOS state machine
	type t_state is (
		STATE_INIT,
		STATE_CLEAR_HISTOGRAM,
		STATE_RECV_NUM_BLOCKS,
		STATE_SAVE_NUM_BLOCKS,
		STATE_LOOP,
		STATE_RECV_BLOCK,
		STATE_UPDATE_HISTOGRAM,
		STATE_COPY_HISTOGRAM,
		STATE_SEND_RESULT,
		STATE_FINAL);
		
	signal state : t_state;
	
	signal block_size : std_logic_vector(31 downto 0); -- size of the last received block
	
	-- update histogram
	signal update_histo_en     : std_logic; -- handshake signal
	signal update_histo_done   : std_logic; -- handshake signal
	signal update_histo_addr   : std_logic_vector(C_BURST_AWIDTH-1 downto 0); -- burst ram addr
	signal update_histo_bucket : std_logic_vector(7 downto 0); -- histogram addr
	
	-- copy histogram
	signal copy_histo_en     : std_logic; -- handshake signal
	signal copy_histo_done   : std_logic; -- handshake signal
	signal copy_histo_addr   : std_logic_vector(C_BURST_AWIDTH-1 downto 0); -- burst ram addr
	signal copy_histo_bucket : std_logic_vector(7 downto 0); -- histogram addr
	
	-- clear histogram
	signal clear_histo_en     : std_logic; -- handshake signal
	signal clear_histo_done   : std_logic; -- handshake signal
	signal clear_histo_bucket : std_logic_vector(7 downto 0); -- histogram addr
	
	-- histogram
	type t_ram is array (255 downto 0) of std_logic_vector(31 downto 0);
	signal histo_ram    : t_ram; -- histogram memory
	signal histo_bucket : std_logic_vector(7 downto 0); -- current histogram bucket
	signal histo_inc    : std_logic; -- enables incrementing
	signal histo_clear  : std_logic; -- enables setting to zero
	signal histo_value  : std_logic_vector(31 downto 0); -- value of current bucket
	signal histo_value_max : std_logic_vector(31 downto 0);
	signal histo_value16 : std_logic_vector(15 downto 0);
begin
	-- connect burst-ram to clk:
	o_RAMClk  <= clk;
	
	-- histogram memory is basically a single port ram with
	-- asynchronous read. the current bucket is incremented each
	-- clock cycle when histo_inc is high, or set to zero when
	-- histo_clear is high.
	histo_value <= histo_ram(CONV_INTEGER(histo_bucket));
	process(clk, reset)
		variable tmp : std_logic_vector(31 downto 0);
	begin
		if reset = '1' then
			tmp := (others => '0');
			histo_value_max <= (others => '0');
		elsif rising_edge(clk) then
			if histo_inc = '1' then
				if tmp > histo_value_max then
					histo_value_max <= tmp;
				end if;
				tmp := histo_value + 1;
				histo_ram(CONV_INTEGER(histo_bucket)) <= tmp;
			elsif histo_clear = '1' then
				histo_ram(CONV_INTEGER(histo_bucket)) <= (others => '0');
				tmp := (others => '0');
				histo_value_max <= (others => '0');
			end if;
		end if;
	end process;
	
	process(histo_value, histo_value_max)
		variable max_bit : natural range 15 to 31;
	begin
		max_bit := 15;
		for i in 16 to 31 loop
			if histo_value_max(i) = '1' then
				max_bit := i;
			end if;
		end loop;
		
		histo_value16 <= histo_value(max_bit downto max_bit - 15);
		
	end process;
	
	-- signals and processes related to updating the histogram from
	-- burst-ram data
	update_histogramm : process(clk, reset, update_histo_en)
		variable step : natural range 0 to 7;
	begin
		if reset = '1' or update_histo_en = '0' then
			step := 0;
			histo_inc <= '0';
			update_histo_addr <= (others => '0');
			update_histo_done <= '0';
			update_histo_bucket <= (others => '0');
		elsif rising_edge(clk) then
			case step is
				when 0 => -- set burst ram address to 0
					update_histo_addr <= (others => '0');
					step := step + 1;
					
				when 1 => -- wait until address is valid
					step := step + 1;
					
				when 2 => -- turn on histogram incrementing, first byte
					histo_inc <= '1';
					update_histo_bucket <= i_ramdata(7 downto 0);
					step := step + 1;
					
				when 3 => -- second byte
					update_histo_bucket <= i_ramdata(15 downto 8);
					step := step + 1;
					
				when 4 => -- load next word from burst ram, third byte
					update_histo_bucket <= i_ramdata(23 downto 16);
					if update_histo_addr + 1 < block_size(31 downto 2) then
						update_histo_addr <= update_histo_addr + 1;
						step := step + 1;
					else
						step := 6;
					end if;
					
				when 5 => -- last byte in word, continue
					update_histo_bucket <= i_ramdata(31 downto 24);
					step := 2;
				
				when 6 => -- last byte in word, end of block
					update_histo_bucket <= i_ramdata(31 downto 24);
					step := step + 1;
					
				when 7 => -- turn off histogram incrementing, set handshake signal
					histo_inc <= '0';
					update_histo_done <= '1';
					
			end case;
		end if;
	end process;
	
	-- signals and processes related to copying the histogram to
	-- burst-ram
	copy_histogram : process(clk, reset, copy_histo_en)
		variable step : natural range 0 to 5;
	begin
		if reset = '1' or copy_histo_en = '0' then
			copy_histo_addr <= (others => '0');
			copy_histo_bucket <= (others => '0');
			copy_histo_done <= '0';
			o_ramwe <= '0';
			step := 0;
		elsif rising_edge(clk) then
			case step is
				when 0 => -- set histogram and burst ram addresses to 0
					copy_histo_addr <= (others => '0');
					copy_histo_bucket <= (others => '0');
					step := step + 1;
				
				when 1 =>
					o_ramdata(31 downto 16) <= histo_value16;
					copy_histo_bucket <= copy_histo_bucket + 1;
					step := step + 1;
				
				when 2 => -- copy first word
					copy_histo_addr <= (others => '0');
					copy_histo_bucket <= copy_histo_bucket + 1;
					o_ramwe <= '1';
					o_ramdata(15 downto 0) <= histo_value16;
					step := step + 1;
					
				when 3 =>
					o_ramdata(31 downto 16) <= histo_value16;
					copy_histo_addr <= copy_histo_addr + 1;
					copy_histo_bucket <= copy_histo_bucket + 1;
					step := step + 1;
					
				when 4 => -- copy remaining histogram buckets to burst ram
					copy_histo_bucket <= copy_histo_bucket + 1;
					o_ramwe <= '1';
					o_ramdata(15 downto 0) <= histo_value16;
					if copy_histo_addr >= 127 then
						step := step + 1;
					else
						step := 3;
					end if;
					
				when 5 => -- all buckets copied -> set handshake signal
					copy_histo_done <= '1';
					o_ramwe <= '0';
			end case;
		end if;
	end process;
	
	-- signals and processes related to clearing the histogram
	clear_histogram : process(clk, reset, clear_histo_en)
		variable step : natural range 0 to 2;
	begin
		if reset = '1' or clear_histo_en = '0' then
			step := 0;
			histo_clear <= '0';
			clear_histo_bucket <= (others => '0');
			clear_histo_done <= '0';
		elsif rising_edge(clk) then
			case step is
				when 0 => -- enable bucket zeroing
						clear_histo_bucket <= (others => '0');
						histo_clear <= '1';
						step := step + 1;
						
				when 1 => -- visit every bucket
					clear_histo_bucket <= clear_histo_bucket + 1;
					if clear_histo_bucket = 255 then
						step := step + 1;
					end if;
				
				when 2 => -- set handshake signal
					histo_clear <= '0';
					clear_histo_done <= '1';
					
			end case;
		end if;
	end process;
	
	
	-- histogram ram mux
	process(update_histo_en, copy_histo_en, clear_histo_en, update_histo_addr, update_histo_bucket,
			copy_histo_addr, copy_histo_bucket, clear_histo_bucket)
		variable addr : std_logic_vector(C_BURST_AWIDTH - 1 downto 0);
		variable bucket : std_logic_vector(7 downto 0);
	begin
		if update_histo_en = '1' then
			addr := update_histo_addr;
			bucket := update_histo_bucket;
		elsif copy_histo_en = '1' then
			addr := copy_histo_addr;
			bucket := copy_histo_bucket;
		elsif clear_histo_en = '1' then
			addr := (others => '0');
			bucket := clear_histo_bucket;
		else
			addr := (others => '0');
			bucket := (others => '0');
		end if;
		
		o_RAMAddr <= addr(C_BURST_AWIDTH - 1 downto 1) & not addr(0);
		histo_bucket <= bucket;
		
	end process;

	
	-- the os interaction state machine performs the following sequential program:
	--
	-- set all histogram buckets to 0
	-- receive the numer of blocks to process
	-- for each block:
	--     receive block
	--     update histogram
	-- copy histogram to burst ram
	-- send histogram
	--
	state_proc: process( clk, reset )
		variable done : boolean;
		variable success : boolean;
		variable num_blocks : std_logic_vector(31 downto 0);
		variable len : std_logic_vector(31 downto 0);
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_INIT;
			done := false;
			success := false;
			num_blocks := (others => '0');
			block_size <= (others => '0');
			len := (others => '0');
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
					when STATE_INIT =>
						clear_histo_en <= '1';
						state <= STATE_CLEAR_HISTOGRAM;
						--reconos_get_init_data(done, o_osif, i_osif, offset);
						--if done then state <= STATE_FILL; end if;

					when STATE_CLEAR_HISTOGRAM =>
						if clear_histo_done = '1' then
							clear_histo_en <= '0';
							state <= STATE_RECV_NUM_BLOCKS;
						end if;

					when STATE_RECV_NUM_BLOCKS =>
						reconos_mq_receive(done, success, o_osif, i_osif, C_MQ_IN, X"00000000", len);
						if done then
							state <= STATE_SAVE_NUM_BLOCKS;
						end if;
						
					when STATE_SAVE_NUM_BLOCKS =>
						num_blocks := i_ramdata;
						state <= STATE_LOOP;
						
					when STATE_LOOP =>
						if num_blocks = 0 then
							copy_histo_en <= '1';
							state <= STATE_COPY_HISTOGRAM;
						else
							state <= STATE_RECV_BLOCK;
						end if;

					when STATE_RECV_BLOCK =>
						reconos_mq_receive(done, success, o_osif, i_osif, C_MQ_IN, X"00000000", len);
						if done then
							state <= STATE_UPDATE_HISTOGRAM;
							block_size <= len;
							update_histo_en <= '1';
						end if;
						
					when STATE_UPDATE_HISTOGRAM =>
						if update_histo_done = '1' then
							update_histo_en <= '0';
							num_blocks := num_blocks - 1;
							state <= STATE_LOOP;
						end if;
					
					when STATE_COPY_HISTOGRAM =>
						if copy_histo_done = '1' then
							copy_histo_en <= '0';
							state <= STATE_SEND_RESULT;
						end if;
						
					when STATE_SEND_RESULT =>
						len := X"00000200";
						reconos_mq_send(done,success,o_osif, i_osif, C_MQ_OUT, X"00000000", len);
						if done then
							state <= STATE_FINAL;
						end if;

					when others =>

				end case;
			end if;
		end if;
	end process;
end architecture;
