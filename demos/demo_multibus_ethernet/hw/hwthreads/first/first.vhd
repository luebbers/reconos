--!
--! \file first.vhd 
--!
--! \author     Ariane Keller
--! \date       29.07.2009
-- Demo file for the multibus. This file will be executed in slot 1.
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity first is

	generic (
   		C_BURST_AWIDTH 	: integer := 11;
    	C_BURST_DWIDTH 	: integer := 32;
    	C_NR_SLOTS 		: integer := 3
	);

	port ( 
    	-- user defined signals: use the signal names defined in the system.ucf file!
		-- user defined signals only work if they are before the reconos signals!

		-- Signals for the Multibus		
		ready_0			: out std_logic;
    	req_0 			: out std_logic_vector(0 to 3 -1);
    	grant_0 		: in std_logic_vector(0 to 3 - 1);
    	data_0			: out std_logic_vector(0 to 3 * 32 - 1);
    	sof_0			: out std_logic_vector(0 to C_NR_SLOTS - 1);
    	eof_0			: out std_logic_vector(0 to C_NR_SLOTS - 1);
    	src_rdy_0 		: out std_logic_vector(0 to C_NR_SLOTS - 1);
    	dst_rdy_0 		: in std_logic_vector(0 to C_NR_SLOTS - 1);

    	busdata_0		: in std_logic_vector(0 to 32 - 1);
    	bussof_0 		: in std_logic;
   		buseof_0 		: in std_logic;
    	bus_dst_rdy_0 	: out std_logic;
    	bus_src_rdy_0 	: in std_logic;
    	--- end user defined ports

		-- normal reconOS signals
    	clk    			: in  std_logic;
    	reset  			: in  std_logic;
    	i_osif 			: in  osif_os2task_t;
    	o_osif 			: out osif_task2os_t;

    	-- burst ram interface
    	o_RAMAddr 		: out std_logic_vector(0 to C_BURST_AWIDTH-1);
    	o_RAMData 		: out std_logic_vector(0 to C_BURST_DWIDTH-1);
    	i_RAMData 		: in  std_logic_vector(0 to C_BURST_DWIDTH-1);
    	o_RAMWE   		: out std_logic;
    	o_RAMClk  		: out std_logic;
    	-- second ram
    	o_RAMAddr_x 	: out std_logic_vector(0 to C_BURST_AWIDTH-1);
    	o_RAMData_x 	: out std_logic_vector(0 to C_BURST_DWIDTH-1);
    	i_RAMData_x 	: in  std_logic_vector(0 to C_BURST_DWIDTH-1); -- 32 bit
    	o_RAMWE_x   	: out std_logic;
    	o_RAMClk_x  	: out std_logic
	);
end first;

architecture Behavioral of first is
    -------------
    -- constants
    ------------
    constant C_MBOX_HANDLE_SW_HW 	: std_logic_vector(0 to 31) := X"00000000";
    constant C_MBOX_HANDLE_HW_SW 	: std_logic_vector(0 to 31) := X"00000001";

    -----------------
    -- state machines
    -----------------
    type os_state is (	STATE_INIT, 
						STATE_SEND_ANSWER, 
						STATE_GET_COMMAND, 
						STATE_DECODE);
    signal os_sync_state : os_state	:= STATE_INIT;

	type s_state is (	S_STATE_INIT, 
						S_STATE_WAIT, 
						S_STATE_LOCK, 
						S_STATE_SEND_FIRST, 
						S_STATE_INTERM);
	signal send_to_0_state 			: s_state;
	signal send_to_0_state_next 	: s_state;

	signal send_to_1_state 			: s_state;
	signal send_to_1_state_next 	: s_state;

	signal send_to_2_state 			: s_state;
	signal send_to_2_state_next 	: s_state;

	type r_state is (	R_STATE_INIT, 
						R_STATE_COUNT);
	signal receive_state			: r_state;
	signal receive_state_next 		: r_state;
	

    ---------------------
    -- Signal declaration
    ---------------------
    -- bus signals (for communication between hw threats
    signal to_0_data : std_logic_vector(0 to 32 - 1);
    signal to_1_data : std_logic_vector(0 to 32 - 1);
    signal to_2_data : std_logic_vector(0 to 32 - 1);

    signal to_0_sof : std_logic;
    signal to_1_sof : std_logic;
    signal to_2_sof : std_logic;

    signal to_1_eof : std_logic;
    signal to_2_eof : std_logic;
    signal to_0_eof : std_logic;

	signal received_counter 	: natural;
	signal received_counter_next: natural;

	signal start_to_0			: std_logic;	
	signal s_0_counter 			: natural;
	signal s_0_counter_next		: natural;

	signal start_to_1			: std_logic;	
	signal s_1_counter 			: natural;
	signal s_1_counter_next		: natural;

	signal start_to_2			: std_logic;	
	signal s_2_counter 			: natural;
	signal s_2_counter_next		: natural;

	--end signal declaration

    begin
   
	--default assignements
	-- we don't need the memories
  	o_RAMAddr <= (others => '0');
    o_RAMData <= (others => '0');
    o_RAMWE   <= '0';
    o_RAMClk  <= '0';

    o_RAMAddr_x <= (others => '0');
    o_RAMData_x <= (others => '0');
    o_RAMWE_x   <= '0';
    o_RAMClk_x  <= '0';
  
	data_0 <= to_0_data & to_1_data & to_2_data;
	ready_0 <= '0'; -- unused?
	-----------------
    -- State machines
    -----------------
	receiving : process(busdata_0, bussof_0, buseof_0, bus_src_rdy_0, 
						receive_state, received_counter)
	begin
		bus_dst_rdy_0 <= '1';
		receive_state_next <= receive_state;
		received_counter_next <= received_counter;
		case receive_state is
		when R_STATE_INIT =>
			received_counter_next <= 0;
			receive_state_next <= R_STATE_COUNT;
		
		when R_STATE_COUNT =>	
			if bussof_0 = '1' then
				received_counter_next <= received_counter + 1;
			end if;
		end case;
	end process;

	send_to_0 : process(start_to_0, send_to_0_state, s_0_counter, grant_0)
	begin
		src_rdy_0(0) <= '0';
		to_0_data <= (others => '0');
		sof_0(0) <= '0';
		eof_0(0) <= '0';
		req_0(0) <= '0';
		send_to_0_state_next <= send_to_0_state;
		s_0_counter_next <= s_0_counter;

 	case send_to_0_state is
    when S_STATE_INIT =>
		send_to_0_state_next <= S_STATE_WAIT;
		s_0_counter_next <= 0;

	when S_STATE_WAIT =>
		if start_to_0 = '1' then
			send_to_0_state_next <= S_STATE_LOCK;
		end if;

	when S_STATE_LOCK =>
		req_0(0) <= '1';--req has to be high as long as we send packets.			
		if grant_0(0) = '0' then
			send_to_0_state_next <= S_STATE_LOCK;
		else
			send_to_0_state_next <= S_STATE_SEND_FIRST;
		end if;

	when S_STATE_SEND_FIRST =>
		src_rdy_0(0) <= '1';
		sof_0(0) <= '1';
		to_0_data <= (others => '1');
		s_0_counter_next <= s_0_counter + 1;
		send_to_0_state_next <= S_STATE_INTERM;
		req_0(0) <= '1';
	
	when S_STATE_INTERM =>
		req_0(0) <= '1';
		src_rdy_0(0) <= '1';
		to_0_data <= (others => '0');
		if s_0_counter = 15 then
			s_0_counter_next <= 0;
			send_to_0_state_next <= S_STATE_WAIT;
			eof_0(0) <= '1';
		else
			s_0_counter_next <= s_0_counter + 1;
		end if;
	when others =>
		send_to_0_state_next <= S_STATE_INIT;

	end case;
	end process;

	send_to_1 : process(start_to_1, send_to_1_state, s_1_counter, grant_0)
	begin
		src_rdy_0(1) <= '0';
		to_1_data <= (others => '0');
		sof_0(1) <= '0';
		eof_0(1) <= '0';
		req_0(1) <= '0';
		send_to_1_state_next <= send_to_1_state;
		s_1_counter_next <= s_1_counter;

 	case send_to_1_state is
    when S_STATE_INIT =>
		send_to_1_state_next <= S_STATE_WAIT;
		s_1_counter_next <= 0;

	when S_STATE_WAIT =>
		if start_to_1 = '1' then
			send_to_1_state_next <= S_STATE_LOCK;
		end if;

	when S_STATE_LOCK =>
		req_0(1) <= '1';			
		if grant_0(1) = '0' then
			send_to_1_state_next <= S_STATE_LOCK;
		else
			send_to_1_state_next <= S_STATE_SEND_FIRST;
		end if;

	when S_STATE_SEND_FIRST =>
		src_rdy_0(1) <= '1';		
		sof_0(1) <= '1';
		to_1_data <= (others => '1');
		s_1_counter_next <= s_1_counter + 1;
		send_to_1_state_next <= S_STATE_INTERM;
		req_0(1) <= '1';
	
	when S_STATE_INTERM =>
		req_0(1) <= '1';
		src_rdy_0(1) <= '1';
		to_1_data <= (others => '0');
		if s_1_counter = 15 then 
			s_1_counter_next <= 0;
			send_to_1_state_next <= S_STATE_WAIT;
			eof_0(1) <= '1';
		else
			s_1_counter_next <= s_1_counter + 1;
		end if;
	when others =>
		send_to_1_state_next <= S_STATE_INIT;
	end case;
	end process;

	send_to_2 : process(start_to_2, send_to_2_state, s_2_counter, grant_0)
	begin
		src_rdy_0(2) <= '0';
		to_2_data <= (others => '0');
		sof_0(2) <= '0';
		eof_0(2) <= '0';
		req_0(2) <= '0';
		send_to_2_state_next <= send_to_2_state;
		s_2_counter_next <= s_2_counter;

 	case send_to_2_state is
    when S_STATE_INIT =>
		send_to_2_state_next <= S_STATE_WAIT;
		s_2_counter_next <= 0;

	when S_STATE_WAIT =>
		if start_to_2 = '1' then
			send_to_2_state_next <= S_STATE_LOCK;
		end if;

	when S_STATE_LOCK =>
		req_0(2) <= '1';			
		if grant_0(2) = '0' then
			send_to_2_state_next <= S_STATE_LOCK;
		else
			send_to_2_state_next <= S_STATE_SEND_FIRST;
		end if;

	when S_STATE_SEND_FIRST =>
		src_rdy_0(2) <= '1';
		sof_0(2) <= '1';
		to_2_data <= (others => '1');
		s_2_counter_next <= s_2_counter + 1;
		send_to_2_state_next <= S_STATE_INTERM;
		req_0(2) <= '1';
	
	when S_STATE_INTERM =>
		req_0(2) <= '1';
		src_rdy_0(2) <= '1';
		to_2_data <= (others => '0');
		if s_2_counter = 15 then
			s_2_counter_next <= 0;
			send_to_2_state_next <= S_STATE_WAIT;
			eof_0(2) <= '1';
		else
			s_2_counter_next <= s_2_counter + 1;
		end if;
	when others =>
		send_to_2_state_next <= S_STATE_INIT;

	end case;
	end process;

    -- memzing process
    -- updates all the registers
    proces_mem : process(clk, reset)
    begin
        if reset = '1' then
			send_to_0_state <= S_STATE_INIT;
			s_0_counter <= 0;
			send_to_1_state <= S_STATE_INIT;
			s_1_counter <= 0;
			send_to_2_state <= S_STATE_INIT;
			s_2_counter <= 0;
			receive_state <= R_STATE_INIT;
			received_counter <= 0;

        elsif rising_edge(clk) then
			send_to_0_state <= send_to_0_state_next;
			s_0_counter <= s_0_counter_next;
			send_to_1_state <= send_to_1_state_next;
			s_1_counter <= s_1_counter_next;
			send_to_2_state <= send_to_2_state_next;
			s_2_counter <= s_2_counter_next;
			receive_state <= receive_state_next;
			received_counter <= received_counter_next;

        end if;
    end process;


    -- OS synchronization state machine
    -- this has to have this special format!
    state_proc : process(clk, reset)
    variable success		: boolean;
    variable done	        : boolean;
	variable sw_command 	: std_logic_vector(0 to C_OSIF_DATA_WIDTH - 1);

    begin
        if reset = '1' then
            reconos_reset_with_signature(o_osif, i_osif, X"ABCDEF01");
            os_sync_state      <= STATE_INIT;
			start_to_0 <= '0';
			start_to_1 <= '0';
			start_to_2 <= '0';

        elsif rising_edge(clk) then
		reconos_begin(o_osif, i_osif);
        if reconos_ready(i_osif) then
        case os_sync_state is
        when STATE_INIT =>
				os_sync_state <= STATE_GET_COMMAND;
				start_to_0 <= '0';
				start_to_1 <= '0';
				start_to_2 <= '0';

        when STATE_SEND_ANSWER =>
				reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_HANDLE_HW_SW, 
						std_logic_vector(to_unsigned(received_counter,C_OSIF_DATA_WIDTH)));
	            if done then
    	        	os_sync_state <= STATE_GET_COMMAND;
        	    end if;
		
        when STATE_GET_COMMAND =>
			reconos_mbox_get(done, success, o_osif, i_osif, C_MBOX_HANDLE_SW_HW, sw_command);
            if done and success then
                os_sync_state <= STATE_DECODE;
            end if;

        when STATE_DECODE =>
            --default: command not known
            os_sync_state <= STATE_GET_COMMAND;
			-- element 0 indicates whether this thread should send to slot 0,
			-- element 1 indicates whether this thread should send to slot 1,
			-- element 6 indicates whether the receive counter from the bus interface 
			-- should be reported
			if sw_command(6) = '1' then
	         	os_sync_state <= STATE_SEND_ANSWER;
         	else
				if sw_command(0) = '1' then
					start_to_0 <= '1';
				else
					start_to_0 <= '0';
				end if;

				if sw_command(1) = '1' then
					start_to_1 <= '1';
				else
					start_to_1 <= '0';
				end if;

				if sw_command(2) = '1' then
					start_to_2 <= '1';
				else
					start_to_2 <= '0';
				end if;
			end if;

        when others =>
            os_sync_state <= STATE_INIT;
        end case;
        end if;
        end if;
    end process;
end Behavioral;


