library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity hwt_memcopy is

	generic (
		C_BURST_AWIDTH : integer := 12;
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

architecture Behavioral of hwt_memcopy is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	--constant C_MBOX : std_logic_vector(31 downto 0) := X"00000000"; -- debug
	
	type t_state is ( STATE_INIT,
							--STATE_SEND_INIT_DATA, -- debug
							STATE_READ_SRC,
							STATE_READ_DST,
							STATE_READ_SIZE,
							--STATE_SEND_SRC, -- debug
							--STATE_SEND_DST, -- debug
							--STATE_SEND_SIZE, -- debug
							STATE_READ_BURST,
							STATE_WRITE_BURST,
							STATE_READ_WORD,
							STATE_WRITE_WORD,
							STATE_DONE,
							--STATE_SEND_DONE, -- debug
							STATE_FINAL);
	
	signal state : t_state;
begin

	state_proc: process( clk, reset )
		variable args : std_logic_vector(31 downto 0);
		variable src : std_logic_vector(31 downto 0);
		variable dst : std_logic_vector(31 downto 0);
		variable size : std_logic_vector(31 downto 0);
		variable tmp : std_logic_vector(31 downto 0);
		variable done : boolean;
		variable success : boolean;
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_INIT;
			args := (others => '0');
			src := (others => '0');
			dst := (others => '0');
			size := (others => '0');
			tmp := (others => '0');
			done := false;
			success := false;
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
					when STATE_INIT =>
						reconos_get_init_data(done, o_osif, i_osif, args);
						if done then state <= STATE_READ_SRC; end if;
					--	if done then state <= STATE_SEND_INIT_DATA; end if; -- debug
				
					--------------------------------------------
					-- when STATE_SEND_INIT_DATA =>
					--	reconos_mbox_put(done,success,o_osif,i_osif,C_MBOX, args);
					--	if done then state <= STATE_READ_SRC; end if;
					--------------------------------------------
				
					when STATE_READ_SRC =>
						reconos_read(done, o_osif, i_osif, args, src);
						if done then state <= STATE_READ_DST; end if;
						
					when STATE_READ_DST =>
						reconos_read(done, o_osif, i_osif, args + 4, dst);
						if done then state <= STATE_READ_SIZE; end if;
						
					when STATE_READ_SIZE =>
						reconos_read(done, o_osif, i_osif, args + 8, size);
						if done then state <= STATE_READ_BURST; end if;
					--	if done then state <= STATE_SEND_SRC; end if;
						
					----------------------------------------
					-- when STATE_SEND_SRC =>
					--	reconos_mbox_put(done,success,o_osif,i_osif,C_MBOX, src);
					--	if done then state <= STATE_SEND_DST; end if;
					
					-- when STATE_SEND_DST =>
					--	reconos_mbox_put(done,success,o_osif,i_osif,C_MBOX, dst);
					--	if done then state <= STATE_SEND_SIZE; end if;
				
					-- when STATE_SEND_SIZE =>
					--	reconos_mbox_put(done,success,o_osif,i_osif,C_MBOX, size);
					--	if done then state <= STATE_READ_BURST; end if;
					----------------------------------------
						
					when STATE_READ_BURST =>
						if (size >= 128) and (src(2 downto 0) = B"000") then
							reconos_read_burst (done, o_osif, i_osif, X"00000000", src);
                     if done then
								state <= STATE_WRITE_BURST;
								src := src + 128;
							end if;
						else
							state <= STATE_READ_WORD;
						end if;
						
					when STATE_WRITE_BURST =>
						reconos_write_burst (done, o_osif, i_osif, X"00000000", dst);
						if done then
							state <= STATE_READ_BURST;
					--		state <= STATE_SEND_SRC; -- debug
							dst := dst + 128;
							size := size - 128;
						end if;
						
					when STATE_READ_WORD =>
						if size > 0 then
							reconos_read(done, o_osif, i_osif, src, tmp);
							if done then
								state <= STATE_WRITE_WORD;
								src := src + 4;
							end if;
						else
							state <= STATE_DONE;
						end if;
						
					when STATE_WRITE_WORD =>
						reconos_write(done, o_osif, i_osif, dst, tmp);
						if done then
							state <= STATE_READ_BURST;
					--		state <= STATE_SEND_SRC; -- debug
							dst := dst + 4;
							size := size - 4;
						end if;
					
					when STATE_DONE =>
						reconos_write(done, o_osif, i_osif, args + 8, X"00000000");
						state <= STATE_FINAL;
					--	state <= STATE_SEND_DONE; -- debug
					
					--------------------------------------------
					-- when STATE_SEND_DONE =>
					--	reconos_mbox_put(done,success,o_osif,i_osif,C_MBOX, X"0112358D");
					--	if done then state <= STATE_FINAL; end if;
					--------------------------------------------
				
					when STATE_FINAL =>
						state <= STATE_FINAL;
								
						
						
				end case;
			end if;
		end if;
	end process;
end architecture;
