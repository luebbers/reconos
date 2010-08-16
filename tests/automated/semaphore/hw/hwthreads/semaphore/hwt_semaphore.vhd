library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity hwt_semaphore is

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

architecture Behavioral of hwt_semaphore is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	constant C_SEMAPHORE_A : std_logic_vector(31 downto 0) := X"00000000";
	constant C_SEMAPHORE_B : std_logic_vector(31 downto 0) := X"00000001";
	
	type t_state is ( STATE_WAIT_A,
							STATE_POST_B);
	
	signal state : t_state;
begin

	state_proc: process( clk, reset )
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_WAIT_A;
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
						
					when STATE_WAIT_A =>
						reconos_sem_wait(o_osif,i_osif,C_SEMAPHORE_A);
						state <= STATE_POST_B;
						
					when STATE_POST_B =>
						reconos_sem_post(o_osif,i_osif,C_SEMAPHORE_B);
						state <= STATE_WAIT_A;
						
				end case;
			end if;
		end if;
	end process;
end architecture;
