library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity hwt_condvar is

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

architecture Behavioral of hwt_condvar is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	constant C_MUTEX_A : std_logic_vector(31 downto 0) := X"00000000";
	constant C_CONDVAR_A : std_logic_vector(31 downto 0) := X"00000001";
	constant C_MUTEX_B : std_logic_vector(31 downto 0) := X"00000002";
	constant C_CONDVAR_B : std_logic_vector(31 downto 0) := X"00000003";
	
	type t_state is ( STATE_MUTEX_A_LOCK,
							STATE_CONDVAR_A_WAIT,
							STATE_MUTEX_A_UNLOCK,
							STATE_MUTEX_B_LOCK,
							STATE_CONDVAR_B_SIGNAL,
							STATE_MUTEX_B_UNLOCK);
	
	signal state : t_state;
begin

	state_proc: process( clk, reset )
		variable done: boolean;
		variable success: boolean;
		variable addr : std_logic_vector(31 downto 0);
		variable data : std_logic_vector(31 downto 0);
		variable counter : integer range 0 to 25000001;
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_MUTEX_A_LOCK;
			done := false;
			success := false;
			counter := 0;
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
		
					when STATE_MUTEX_A_LOCK =>
						reconos_mutex_lock(done, success, o_osif, i_osif, C_MUTEX_A);
						if done then state <= STATE_CONDVAR_A_WAIT; end if;
					
					when STATE_CONDVAR_A_WAIT =>
						reconos_cond_wait(done, success, o_osif, i_osif, C_CONDVAR_A);
                  if done then state <= STATE_MUTEX_A_UNLOCK; end if;
					
					when STATE_MUTEX_A_UNLOCK =>
						reconos_mutex_unlock(o_osif, i_osif, C_MUTEX_A);
						state <= STATE_MUTEX_B_LOCK;
					
					when STATE_MUTEX_B_LOCK =>
						reconos_mutex_lock(done, success, o_osif, i_osif, C_MUTEX_B);
						if done then state <= STATE_CONDVAR_B_SIGNAL; end if;			

					when STATE_CONDVAR_B_SIGNAL =>
						reconos_cond_signal(o_osif, i_osif, C_CONDVAR_B);
                  state <= STATE_MUTEX_B_UNLOCK;
						
					when STATE_MUTEX_B_UNLOCK =>
						reconos_mutex_unlock(o_osif, i_osif, C_MUTEX_B);
						state <= STATE_MUTEX_A_LOCK;
						
				end case;
			end if;
		end if;
	end process;
end architecture;

