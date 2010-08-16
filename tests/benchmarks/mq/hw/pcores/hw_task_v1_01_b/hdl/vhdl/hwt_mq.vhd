--!
--! \file hwt_mq.vhd
--!
--! POSIX message queue through MMIO'd burst RAM benchmark
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       24.11.2008
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 24.11.2008   Enno Luebbers   File adapted from mq automated test by Andreas

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity hwt_mq is

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
		o_RAMClk  : out std_logic;
                o_inv_RAM : out std_logic;  -- inverts the RAM output on the OSIF side
                i_timebase : in std_logic_vector( 0 to C_OSIF_DATA_WIDTH-1 )
	);
	
end entity;

architecture Behavioral of hwt_mq is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	
	constant C_MEM_PAD : std_logic_vector(C_BURST_AWIDTH-1 downto 0) := (others => '0');
	constant C_MEM_SIZE : std_logic_vector(31 downto 0) := X"00000000" + ('1' & C_MEM_PAD);
        constant C_DELAY : std_logic_vector(31 downto 0) := X"00002000";    -- 8192 cycles

	type t_state is (
		STATE_INIT,
		STATE_FILL,
		STATE_FILL_2,
		STATE_FILL_3,
                STATE_GET_STARTTIME_RECV,
		STATE_MQ_RECEIVE,
                STATE_GET_STOPTIME_RECV,
		STATE_MQ_SEND,
                STATE_GET_STOPTIME_SEND,
                STATE_DELAY,
                STATE_SEND_STARTTIME_RECV,
                STATE_SEND_STOPTIME_RECV,
                STATE_SEND_STARTTIME_SEND,
                STATE_SEND_STOPTIME_SEND,
                STATE_ERROR
            );
	
	constant C_MQ_A : std_logic_vector(31 downto 0) := X"00000000";
	constant C_MQ_B : std_logic_vector(31 downto 0) := X"00000001";
        constant C_MBOX_TIMES : std_logic_vector(31 downto 0) := X"00000002";

	signal state : t_state;
	signal counter : std_logic_vector(31 downto 0);
        signal starttime_recv : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        signal stoptime_recv : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        signal starttime_send : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        signal stoptime_send : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
begin

	o_RAMAddr <= counter(C_BURST_AWIDTH - 1 downto 1) & not counter(0);
	--o_RAMData <= (others => '0');
	o_RAMData(C_BURST_DWIDTH - C_BURST_AWIDTH to C_BURST_DWIDTH - 1) <= counter;
	o_RAMClk  <= clk;

	state_proc: process( clk, reset )
		variable done : boolean;
		variable success : boolean;
                variable errno : natural range 0 to 255;
		variable len : std_logic_vector(31 downto 0);
		variable tmp : std_logic_vector(31 downto 0);
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_INIT;
			counter <= (others => '0');
			done := false;
			success := false;
			len := X"deadbeef";
                        o_inv_RAM <= '0';
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
					when STATE_INIT =>
                                                counter <= (others => '0');
						state <= STATE_FILL;

					when STATE_FILL =>
                                                -- clear burst RAM
						counter <= counter + 1;
						o_RAMWe <= '0';
						state <= STATE_FILL_2;

					when STATE_FILL_2 =>
						if counter = C_MEM_SIZE then
							state <= STATE_GET_STARTTIME_RECV;
							counter <= (others => '0');
						else
							state <= STATE_FILL_3;
						end if;

					when STATE_FILL_3 =>
						o_RAMWe <= '1';
						state <= STATE_FILL;

                                        when STATE_GET_STARTTIME_RECV =>
                                                starttime_recv <= i_timebase;
                                                state <= STATE_MQ_RECEIVE;
				
					-- receive data from C_MQ_A
					when STATE_MQ_RECEIVE =>
						reconos_mq_receive(done,success,o_osif, i_osif,
								C_MQ_A, X"00000000", len);
						if done then
                                                    if success then
							state <= STATE_GET_STOPTIME_RECV;
                                                    else
                                                        errno := 1;
                                                        state <= STATE_ERROR;
                                                    end if;
						end if;

                                        when STATE_GET_STOPTIME_RECV =>
                                                stoptime_recv <= i_timebase;
                                                starttime_send <= i_timebase;
                                                state <= STATE_MQ_SEND;
		
					-- send data to C_MQ_B
					when STATE_MQ_SEND =>

                                                o_inv_RAM <= '1';   -- invert the received data
						reconos_mq_send(done,success,o_osif, i_osif,
								C_MQ_B, X"00000000", len);
						if done then
                                                    if success then
							state <= STATE_GET_STOPTIME_SEND;
                                                        o_inv_RAM <= '0';
                                                    else
                                                        errno := 2;
                                                        state <= STATE_ERROR;
                                                    end if;
						end if;

                                        when STATE_GET_STOPTIME_SEND =>
                                                stoptime_send <= i_timebase;
                                                state <= STATE_DELAY;

                                        when STATE_DELAY =>
                                            -- wait so that we don't disturb the mq_receive in software
                                                if counter >= C_DELAY then
                                                    counter <= (others => '0');
                                                    state <= STATE_SEND_STARTTIME_RECV;
                                                else
                                                    counter <= counter + 1;
                                                end if;

                                        when STATE_SEND_STARTTIME_RECV =>
                                                reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_TIMES, starttime_recv);
                                                if done then
                                                    if success then
                                                        state <= STATE_SEND_STOPTIME_RECV;
                                                    else
                                                        errno := 3;
                                                        state <= STATE_ERROR;
                                                    end if;
                                                end if;

                                        when STATE_SEND_STOPTIME_RECV =>
                                                reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_TIMES, stoptime_recv);
                                                if done then
                                                    if success then
                                                        state <= STATE_SEND_STARTTIME_SEND;
                                                    else
                                                        errno := 3;
                                                        state <= STATE_ERROR;
                                                    end if;
                                                end if;

                                        when STATE_SEND_STARTTIME_SEND =>
                                                reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_TIMES, starttime_send);
                                                if done then
                                                    if success then
                                                        state <= STATE_SEND_STOPTIME_SEND;
                                                    else
                                                        errno := 3;
                                                        state <= STATE_ERROR;
                                                    end if;
                                                end if;

                                        when STATE_SEND_STOPTIME_SEND =>
                                                reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_TIMES, stoptime_send);
                                                if done then
                                                    if success then
                                                        state <= STATE_INIT;
                                                    else
                                                        errno := 3;
                                                        state <= STATE_ERROR;
                                                    end if;
                                                end if;

                                        when STATE_ERROR =>
                                            reconos_thread_exit(o_osif, i_osif, STD_LOGIC_VECTOR(CONV_UNSIGNED(errno, C_OSIF_DATA_WIDTH)));

					when others =>

				end case;
			end if;
		end if;
	end process;
end architecture;
