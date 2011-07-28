--!
--! \file thread.vhd
--!
--! Demo thread for partial reconfiguration (pr_msg_demo)
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       10.02.2011
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 10.02.2011   Enno Luebbers   File created.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity thread is

  generic (
    C_BURST_AWIDTH : integer := 11;
    C_BURST_DWIDTH : integer := 32;
    C_THREAD_NUM   : integer := 0   -- equals position in chain
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
end thread;

architecture Behavioral of thread is

	-- OS synchronization state machine states
  	type t_state is (STATE_INIT, STATE_RECV, STATE_SETBIT, STATE_NOTIFY, STATE_SEND, STATE_EXIT);
  	signal state : t_state := STATE_INIT;

	-- buffer for modifying messages
	signal msg : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
	
	-- number of repeat cycles
	signal repeat_count : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
	
	-- signature
	signal sig : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	
	constant C_MB_IN     : std_logic_vector(0 to 31) := X"00000000";
	constant C_MB_OUT    : std_logic_vector(0 to 31) := X"00000001";
	constant C_MB_NOTIFY : std_logic_vector(0 to 31) := X"00000002";
  
begin

    -- tie RAM signals low (we don't use them)
    o_RAMAddr <= (others => '0');
    o_RAMData <= (others => '0');
    o_RAMWe   <= '0';
    o_RAMClk  <= '0';

	sig(C_THREAD_NUM) <= '1';

  -- OS synchronization state machine
  	state_proc                 : process(clk, reset)
    	variable done          : boolean;
    	variable success       : boolean;
    	variable next_state    : t_state := STATE_INIT;
  	begin
    
		if reset = '1' then
      		reconos_reset_with_signature(o_osif, i_osif, sig);
      		state      <= STATE_INIT;
      		next_state := STATE_INIT;
      		done       := false;
    	elsif rising_edge(clk) then
      		reconos_begin(o_osif, i_osif);
      		if reconos_ready(i_osif) then
        	case state is

            -- read number of repeats from init data
            when STATE_INIT =>
                reconos_get_init_data_s(done, o_osif, i_osif, repeat_count);
                next_state := STATE_RECV;

            -- read data in message box
            when STATE_RECV => 
                reconos_mbox_get_s(done, success, o_osif, i_osif, C_MB_IN, msg);
                next_state := STATE_SETBIT;

            -- set message bit
            when STATE_SETBIT => 
				msg(C_THREAD_NUM) <= '1';
                next_state := STATE_NOTIFY;

            -- notify main()
            when STATE_NOTIFY => 
                reconos_mbox_put(done, success, o_osif, i_osif, C_MB_NOTIFY, sig);
                next_state := STATE_SEND;

            -- send modified message to next message box
            when STATE_SEND => 
                reconos_mbox_put(done, success, o_osif, i_osif, C_MB_OUT, msg);
				if repeat_count = 0 then
                	next_state := STATE_EXIT;
				else
					repeat_count <= repeat_count - 1;
                	next_state := STATE_RECV;
				end if;

            -- terminate
            when STATE_EXIT => 
                reconos_thread_exit(o_osif, i_osif, C_RECONOS_SUCCESS); 

          when others =>
                next_state := STATE_INIT;

        end case;
        if done then
            state <= next_state;
        end if;
      end if;
    end if;
  end process;
end Behavioral;


