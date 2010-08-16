-- *************************
-- Message Manager
-- (Prototype)
--
-- Written by Jason Agron
-- *************************
-- FIXMEs:
-- * Add in support for full-handshaking (user -> queue -> back to user)
-- * Change underlying queue structure to be faster (eliminate useless states)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity message_manager is
generic(
	START_WITH_TOKEN	: integer := 0;
	QUEUE_ADDRESS_WIDTH : integer := 9;
	DATA_WIDTH 			: integer := 32;
	CHANNEL_ID_WIDTH 	: integer := 8;
	SENDER_ID_WIDTH 	: integer := 8
);
port(
	-- System-Level Control Ports
	clk		: in std_logic;
	reset	: in std_logic;

	-- User Interface Ports
	i_request		: in std_logic;
	i_user_opcode	: in std_logic_vector(0 to 7);
	i_user_data		: in std_logic_vector(0 to DATA_WIDTH-1);
	i_user_channel	: in std_logic_vector(0 to CHANNEL_ID_WIDTH-1);
	i_user_sender	: in std_logic_vector(0 to SENDER_ID_WIDTH-1);
	o_user_data		: out std_logic_vector(0 to DATA_WIDTH-1);
	o_user_channel	: out std_logic_vector(0 to CHANNEL_ID_WIDTH-1);
	o_user_sender	: out std_logic_vector(0 to SENDER_ID_WIDTH-1);
	o_busy			: out std_logic;
	o_send_ready	: out std_logic;
	o_recv_ready	: out std_logic;

	-- System Ports - Incoming Packet Interface
	i_packet_data		: in std_logic_vector(0 to DATA_WIDTH-1);
	i_packet_channel	: in std_logic_vector(0 to CHANNEL_ID_WIDTH-1);
	i_packet_sender		: in std_logic_vector(0 to SENDER_ID_WIDTH-1);
	i_packet_valid		: in std_logic;

	-- System Ports -- Token Interface
	i_token : in std_logic;
	o_token : out std_logic;

	-- System Ports - Outgoing Packet Interface
	o_packet_data		: out std_logic_vector(0 to DATA_WIDTH-1);
	o_packet_channel	: out std_logic_vector(0 to CHANNEL_ID_WIDTH-1);
	o_packet_sender		: out std_logic_vector(0 to SENDER_ID_WIDTH-1);
	o_packet_valid		: out std_logic
);
end entity message_manager;

architecture IMP of message_manager is

	-- *****************************
	-- Function Definitions
	-- *****************************
	-- Form a packet from it's components
	function form_packet(
						channel : std_logic_vector(0 to CHANNEL_ID_WIDTH - 1);
						sender	: std_logic_vector(0 to SENDER_ID_WIDTH - 1);
						data	: std_logic_vector(0 to DATA_WIDTH - 1)
						) return std_logic_vector is
	begin
		return (channel & sender & data);
	end function form_packet;

	-- Extract data field from a formed packet
	function get_packet_data(formed_packet : std_logic_vector(0 to CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1)) return std_logic_vector is
	begin
		return formed_packet((CHANNEL_ID_WIDTH + SENDER_ID_WIDTH) to (CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1));
	end function get_packet_data;

	-- Extract sender field from a formed packet
	function get_packet_sender(formed_packet : std_logic_vector(0 to CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1)) return std_logic_vector is
	begin
		return formed_packet((CHANNEL_ID_WIDTH) to (CHANNEL_ID_WIDTH + SENDER_ID_WIDTH - 1));
	end function get_packet_sender;

	-- Extract channel field from a formed packet
	function get_packet_channel(formed_packet : std_logic_vector(0 to CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1)) return std_logic_vector is
	begin
		return formed_packet(0 to (CHANNEL_ID_WIDTH - 1));
	end function get_packet_channel;

	-- *****************************
	-- Component declaration for queue IP
	-- *****************************
	COMPONENT fast_queue
	generic(
	   ADDRESS_BITS	: integer := 9;
   	   DATA_BITS	: integer := 32
	  );
	PORT(
		clk			: in std_logic;
		rst			: in std_logic;
		add_busy		: out std_logic;
		remove_busy		: out std_logic;
		add			: in std_logic;
		remove		: in std_logic;
		entryToAdd	: in std_logic_vector(0 to DATA_BITS-1);
		head		: out std_logic_vector(0 to DATA_BITS-1);
		headValid	: out std_logic;
		full		: out std_logic;
		empty		: out std_logic	
	);
	END COMPONENT;
 
	-- **********************************
	-- Constant Defintions
	-- **********************************
	-- Message Manager Opcodes
	constant RESET_SEND_QUEUE : std_logic_vector(0 to 7) := x"01";
	constant RESET_RECV_QUEUE : std_logic_vector(0 to 7) := x"02";
	constant REGISTER_CHANNEL : std_logic_vector(0 to 7) := x"03";
	constant SEND_PACKET	  : std_logic_vector(0 to 7) := x"04";
	constant RECV_PACKET	  : std_logic_vector(0 to 7) := x"05";
	constant REGISTER_SENDER  : std_logic_vector(0 to 7) := x"06";
	constant GET_QUEUE_STATUS : std_logic_vector(0 to 7) := x"07";

	-- Pseudonyms for token values
	constant NO_TOKEN	: std_logic := '0';
	constant HAS_TOKEN	: std_logic	:= '1';
	
	-- Pseudonyms for token counter values
	constant COUNTER_OUT_OF_TIME : std_logic_vector(0 to QUEUE_ADDRESS_WIDTH -1) := (others => '0');
	constant COUNTER_RESET_VALUE : std_logic_vector(0 to QUEUE_ADDRESS_WIDTH -1) := (others => '1');

	-- **********************************
	-- Internal registers and signals
	-- **********************************
	-- Registers to hold channel to listen for and sender ID
	signal listen_channel, listen_channel_next : std_logic_vector(0 to CHANNEL_ID_WIDTH - 1);
	signal sender_id, sender_id_next : std_logic_vector(0 to SENDER_ID_WIDTH - 1);

	-- Registers used to detect incoming (valid) packets
	signal i_packet_valid_d1, incoming_packet : std_logic;
	
	-- Token register and token down counter
	signal token_register	: std_logic;
	signal token_counter	: std_logic_vector(0 to QUEUE_ADDRESS_WIDTH - 1); -- Decrementing token counter (limits the number of packets that can be sent at once) 

	-- Signals used to connect SEND QUEUE
	signal send_queue_reset : std_logic;
	signal send_queue_add	: std_logic;
	signal send_queue_add_busy, send_queue_remove_busy	: std_logic;
	signal send_queue_remove : std_logic;
	signal send_queue_entry_to_add, send_queue_entry_to_add_next : std_logic_vector(0 to CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1);
	signal send_queue_head : std_logic_vector(0 to CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1);
	signal send_queue_head_valid : std_logic;
	signal send_queue_full : std_logic;
	signal send_queue_empty : std_logic;

	-- Signals used to connect RECV QUEUE
	signal recv_queue_reset : std_logic;
	signal recv_queue_add	: std_logic;
	signal recv_queue_add_busy, recv_queue_remove_busy	: std_logic;
	signal recv_queue_remove : std_logic;
	signal recv_queue_entry_to_add : std_logic_vector(0 to CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1);
	signal recv_queue_head : std_logic_vector(0 to CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH - 1);
	signal recv_queue_head_valid : std_logic;
	signal recv_queue_full : std_logic;
	signal recv_queue_empty : std_logic;

	-- Signals used to return data to user (b/c outputs are registered)
	signal out_busy, out_busy_next		: std_logic;
	signal out_user_data, out_user_data_next	: std_logic_vector(0 to DATA_WIDTH-1);
	signal out_user_channel, out_user_channel_next	: std_logic_vector(0 to CHANNEL_ID_WIDTH-1);
	signal out_user_sender, out_user_sender_next	: std_logic_vector(0 to SENDER_ID_WIDTH-1);

	-- **************************
	-- State definition for FSM
	-- **************************
	type state_type is (
		IDLE,
		RESET_MM,
		CMD_RESET_SEND_QUEUE,
		CMD_RESET_RECV_QUEUE,
		CMD_REGISTER_CHANNEL,
		CMD_REGISTER_SENDER,
		CMD_SEND_PACKET,
		CMD_RECV_PACKET,
		CMD_GET_QUEUE_STATUS
	);

	signal current_state, next_state : state_type := IDLE;

begin

-- ********************************************************
-- Instantiations of receive (RECV) and send (SEND) queues
-- ********************************************************
SEND_QUEUE : fast_queue
generic map(
	ADDRESS_BITS => QUEUE_ADDRESS_WIDTH,
	DATA_BITS	 => (CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH) 
)
port map(
	clk 	=> clk,
	rst 	=> send_queue_reset,
	add_busy	=> send_queue_add_busy,
	remove_busy	=> send_queue_remove_busy,
	add 	=> send_queue_add,
	remove 	=> send_queue_remove,
	entryToAdd => send_queue_entry_to_add,
	head	=> send_queue_head,
	headValid => send_queue_head_valid,
	full	=> send_queue_full,
	empty => send_queue_empty
);

RECV_QUEUE : fast_queue
generic map(
	ADDRESS_BITS => QUEUE_ADDRESS_WIDTH,
	DATA_BITS	 => (CHANNEL_ID_WIDTH + SENDER_ID_WIDTH + DATA_WIDTH) 
)
port map(
	clk 	=> clk,
	rst 	=> recv_queue_reset,
	add_busy	=> recv_queue_add_busy,
	remove_busy	=> recv_queue_remove_busy,
	add 	=> recv_queue_add,
	remove 	=> recv_queue_remove,
	entryToAdd => recv_queue_entry_to_add,
	head	=> recv_queue_head,
	headValid => recv_queue_head_valid,
	full	=> recv_queue_full,
	empty => recv_queue_empty
);

-- ************************************************************
-- Set up status signals for user
-- ************************************************************
o_send_ready	<= (not out_busy) and (not send_queue_full) and (not send_queue_add_busy);
o_recv_ready	<= (not out_busy) and (recv_queue_head_valid);

o_user_data	<= out_user_data;
o_user_channel <= out_user_channel;
o_user_sender	<= out_user_sender;
o_busy	<= out_busy;

-- ************************************************************
-- Process:	USER_COMMAND_CONTROLLER
-- Purpose:	FSM Controller for processing user-driven commands
-- ************************************************************
USER_COMMAND_CONTROLLER : process (clk) is
begin
	if (clk'event and clk = '1') then
		if (reset = '1') then
			-- Reset all FSM variables
			current_state			<= RESET_MM;
			listen_channel			<= (others => '0');
			send_queue_entry_to_add	<= (others => '0');
			out_user_data				<= (others => '0');
			out_user_channel			<= (others => '0');
			out_user_sender			<= (others => '0');
			out_busy					<= '0';
			sender_id				<= (others => '0');			
		else
			-- Transition all FSM variables
			current_state			<= next_state;
			listen_channel			<= listen_channel_next;
			send_queue_entry_to_add	<= send_queue_entry_to_add_next;
			out_user_data				<= out_user_data_next;
			out_user_channel			<= out_user_channel_next;
			out_user_sender			<= out_user_sender_next;
			out_busy					<= out_busy_next;
			sender_id				<= sender_id_next;
		end if;
	end if;
end process USER_COMMAND_CONTROLLER;

-- *****************************************************
-- Process:	USER_COMMAND_CONTROLLER_LOGIC
-- Purpose:	FSM Logic to processs user-driven commands
-- *****************************************************
USER_COMMAND_CONTROLLER_LOGIC : process (
current_state, listen_channel, send_queue_entry_to_add, i_request,
i_user_opcode, i_user_channel, i_user_sender, i_user_data, recv_queue_head,
sender_id, send_queue_empty, send_queue_full, send_queue_add_busy,
send_queue_remove_busy, recv_queue_empty, recv_queue_full, recv_queue_add_busy,
recv_queue_remove_busy, send_queue_head_valid, recv_queue_head_valid, out_user_data, out_user_channel, out_user_sender
) is
begin
	-- Set default values for FSM signals
	send_queue_add		<= '0';
	send_queue_reset	<= '0';
	send_queue_entry_to_add_next	<= send_queue_entry_to_add;

	recv_queue_reset	<= '0';
	recv_queue_remove	<= '0';

	--out_user_data_next <= (others => '0');
	--out_user_channel_next <= (others => '0');
	--out_user_sender_next <= (others => '0');
	out_user_data_next <= out_user_data;
	out_user_channel_next <= out_user_channel;
	out_user_sender_next <= out_user_sender;
	out_busy_next			<= '0';

	listen_channel_next 	<= listen_channel;
	sender_id_next			<= sender_id;
	
	-- FSM Logic:
	case (current_state) is

		-- ************************
		-- IDLE State
		-- ************************
		when IDLE =>
			-- Check if a request is coming in and check the opcode...
			if (i_request = '1') then
				case (i_user_opcode) is
					when RESET_SEND_QUEUE =>
						send_queue_reset	<= '1';
						next_state			<= CMD_RESET_SEND_QUEUE;
						out_busy_next				<= '1';
	
					when RESET_RECV_QUEUE =>
						recv_queue_reset	<= '1';
						next_state			<= CMD_RESET_RECV_QUEUE;
						out_busy_next				<= '1';


					when REGISTER_CHANNEL =>
						listen_channel_next	<= i_user_channel;
						next_state			<= CMD_REGISTER_CHANNEL; 
						out_busy_next	<= '1';

					when REGISTER_SENDER =>
						sender_id_next		<= i_user_sender;
						next_state			<= CMD_REGISTER_SENDER; 
						out_busy_next	<= '1';

					when SEND_PACKET	  =>
--						send_queue_entry_to_add_next	<= form_packet(i_user_channel, sender_id, i_user_data);		-- Use existing senderID register
						send_queue_entry_to_add_next	<= form_packet(i_user_channel, i_user_sender, i_user_data);	-- Use fresh senderID coming from user
						next_state				<= CMD_SEND_PACKET;
						out_busy_next <= '1';

					when RECV_PACKET	  =>
						out_user_data_next <= get_packet_data(recv_queue_head);
						out_user_channel_next <= get_packet_channel(recv_queue_head);
						out_user_sender_next <= get_packet_sender(recv_queue_head);
						next_state				<= CMD_RECV_PACKET;
						out_busy_next 	<= '1';

					when GET_QUEUE_STATUS =>
						next_state		<= CMD_GET_QUEUE_STATUS;
						out_busy_next		<= '1';
					

					when others			  =>
						next_state		<= IDLE;
						out_busy_next 	<= '1';
				end case;
			-- If no request is coming in then just stay in the IDLE state
			else
				next_state <= IDLE;
				out_busy_next <= '0';
			end if;

		-- ************************
		-- RESET SEND QUEUE
		-- ************************
		when CMD_RESET_SEND_QUEUE =>
			send_queue_reset	<= '1';

			out_busy_next <= '1';			
			next_state	<= IDLE;

		-- ************************
		-- RESET RECV QUEUE
		-- ************************
		when CMD_RESET_RECV_QUEUE =>
			recv_queue_reset	<= '1';

			out_busy_next <= '1';			
			next_state	<= IDLE;

		-- ************************
		-- REGISTER CHANNEL ID
		-- ************************
		when CMD_REGISTER_CHANNEL =>
			out_busy_next <= '0';
			next_state <= IDLE;

		-- ************************
		-- REGISTER SENDER ID
		-- ************************
		when CMD_REGISTER_SENDER =>
			out_busy_next <= '0';
			next_state <= IDLE;

		-- ************************
		-- SEND PACKET
		-- ************************
		when CMD_SEND_PACKET =>
			send_queue_add	<= '1';

			out_busy_next <= '1';
			next_state	<= IDLE;	

		-- ************************
		-- RECEIVE PACKET
		-- ************************
		when CMD_RECV_PACKET	=>
			out_user_data_next <= get_packet_data(recv_queue_head);
			out_user_channel_next <= get_packet_channel(recv_queue_head);
			out_user_sender_next <= get_packet_sender(recv_queue_head);
		
			recv_queue_remove	<= '1';	

			out_busy_next	<= '1';
			next_state	<= IDLE;

		-- ************************
		-- GET QUEUE STATUS
		-- ************************
		when CMD_GET_QUEUE_STATUS =>
			out_user_data_next	<=	x"00000" & "00" & 
									(send_queue_empty & send_queue_full & send_queue_add_busy & send_queue_remove_busy & send_queue_head_valid) &
			 					 	(recv_queue_empty & recv_queue_full & recv_queue_add_busy & recv_queue_remove_busy & recv_queue_head_valid);

			out_busy_next	<= '0';
			next_state <= IDLE;

		-- ************************
		-- RESET MESSAGE MANAGER
		-- ************************
		when RESET_MM =>
			send_queue_reset	<= '1';
			recv_queue_reset	<= '1';

			out_busy_next <= '1';
			next_state	<= IDLE;

		when others => 
			-- Should never come here!!!!
			next_state	<= RESET_MM;
	end case;
end process USER_COMMAND_CONTROLLER_LOGIC;

-- *****************************************************
-- Process:	TOKEN_ANALYSIS
-- Purpose:	To capture and process tokens as needed
-- *****************************************************
TOKEN_ANALYSIS : process (clk) is
begin
	if (clk'event and clk = '1') then
		-- Reset all token logic
		if (reset = '1') then
			-- Implement the initial token holder logic
			if (START_WITH_TOKEN = 1) then 
				token_register	<= HAS_TOKEN;
			else
				token_register	<= NO_TOKEN;
			end if;

			-- Reset token counter and output token value
			token_counter	<= COUNTER_RESET_VALUE;
			o_token			<= NO_TOKEN;

		else
			-- If we have the token and it is time to give it up
			if (token_register = HAS_TOKEN and token_counter = COUNTER_OUT_OF_TIME) then
				-- Reset the counter
				token_counter	<= COUNTER_RESET_VALUE; 
				-- Give up the token
				token_register	<= NO_TOKEN;	
				-- Transfer the token down the line
				o_token			<= HAS_TOKEN;
		
			-- If we have the token, but we don't need the token (nothing in the send queue)
			elsif (token_register = HAS_TOKEN and send_queue_empty = '1') then
				-- Keep the token counter at it's reset value
				token_counter	<= COUNTER_RESET_VALUE; 
				-- Give up the token
				token_register	<= NO_TOKEN;
				-- Transfer the token down the line
				o_token			<= HAS_TOKEN;
		 
			-- If we have the token and it is not yet time to give it up
			elsif (token_register = HAS_TOKEN) then
				-- Decrement the token counter
				token_counter	<= token_counter - 1;
				-- Keep the token
				token_register	<= HAS_TOKEN;
				-- Don't pass the token down the line
				o_token			<= NO_TOKEN;
		
			-- Otherwise
			else
				-- Keep the token counter at it's reset value
				token_counter	<= COUNTER_RESET_VALUE; 
				-- Keep monitoring for incoming tokens
				token_register	<= i_token;
				-- Don't pass a token down the line
				o_token			<= NO_TOKEN;
			end if;	
		end if;
	end if;
end process TOKEN_ANALYSIS;

-- *****************************************************
-- Process: INCOMING_PACKET_DETECTOR 
-- Purpose:	Detects incoming valid incoming packets
-- *****************************************************
INCOMING_PACKET_DETECTOR : process (clk) is
begin
	if (clk'event and clk = '1') then
		if (reset = '1') then
			i_packet_valid_d1	<= '0';
		else
			i_packet_valid_d1	<= i_packet_valid;
		end if;
	end if;
end process INCOMING_PACKET_DETECTOR;
incoming_packet <= i_packet_valid and (not i_packet_valid_d1);	-- Detects positive edges

-- *****************************************************
-- Process: INCOMING_PACKET_CONTROLLER	 
-- Purpose:	Incoming Packet Filtering
-- *****************************************************
INCOMING_PACKET_CONTROLLER : process (clk) is
begin
	if (clk'event and clk = '1') then
		-- If a valid packet is coming in and it matches the channel we are listening on, capture it
		if (incoming_packet = '1' and i_packet_channel = listen_channel and i_packet_sender /= sender_id) then
			recv_queue_add 			<= '1';
			recv_queue_entry_to_add <= form_packet(i_packet_channel, i_packet_sender, i_packet_data);
		else
			recv_queue_add 			<= '0';
			recv_queue_entry_to_add <= (others => '0');
		end if;
	end if;
end process INCOMING_PACKET_CONTROLLER;

-- *****************************************************
-- Process: OUTGOING_PACKET_CONTROLLER	 
-- Purpose:	Outgoing Packet Filtering
-- *****************************************************
OUTGOING_PACKET_CONTROLLER : process (clk) is
begin
	if (clk'event and clk = '1') then
		-- If we don't have a token, then just forward packets from incoming port to outgoing port (unless the packet is one that we sent, packet has cycled)
		if (token_register = NO_TOKEN and i_packet_sender /= sender_id) then
			o_packet_data		<= i_packet_data;
			o_packet_channel	<= i_packet_channel;
			o_packet_sender		<= i_packet_sender;
			o_packet_valid		<= i_packet_valid;
			send_queue_remove	<= '0';
		-- If we do have a token and we have packets to send, then send them
		elsif ((token_register = HAS_TOKEN) and (send_queue_head_valid = '1')) then
			o_packet_data		<= get_packet_data(send_queue_head);
			o_packet_channel	<= get_packet_channel(send_queue_head);
			o_packet_sender		<= get_packet_sender(send_queue_head);
			o_packet_valid		<= '1';
			send_queue_remove	<= '1';
		-- Otherwise, drive valid line to low
		else
			o_packet_data		<= (others => '0');
			o_packet_channel	<= (others => '0');
			o_packet_sender		<= (others => '0');
			o_packet_valid		<= '0';
			send_queue_remove	<= '0';
		end if;
	end if;
end process OUTGOING_PACKET_CONTROLLER;


end architecture IMP;
