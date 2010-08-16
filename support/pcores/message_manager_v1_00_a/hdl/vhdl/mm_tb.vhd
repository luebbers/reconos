
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:23:53 10/16/2007
-- Design Name:   message_manager
-- Module Name:   /users/jagron/message_manager/src//mm_tb.vhd
-- Project Name:  my_ise_proj
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: message_manager
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY mm_tb_vhd IS
END mm_tb_vhd;

ARCHITECTURE behavior OF mm_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT message_manager
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		i_request : IN std_logic;
		i_user_opcode : IN std_logic_vector(0 to 7);
		i_user_data : IN std_logic_vector(0 to 31);
		i_user_channel : IN std_logic_vector(0 to 7);
		i_user_sender : IN std_logic_vector(0 to 7);
		i_packet_data : IN std_logic_vector(0 to 31);
		i_packet_channel : IN std_logic_vector(0 to 7);
		i_packet_sender : IN std_logic_vector(0 to 7);
		i_packet_valid : IN std_logic;
		i_token : IN std_logic;          
		o_user_data : OUT std_logic_vector(0 to 31);
		o_user_channel : OUT std_logic_vector(0 to 7);
		o_user_sender : OUT std_logic_vector(0 to 7);
		o_busy : OUT std_logic;
		o_send_ready	: out std_logic;
		o_recv_ready	: out std_logic;
		o_token : OUT std_logic;
		o_packet_data : OUT std_logic_vector(0 to 31);
		o_packet_channel : OUT std_logic_vector(0 to 7);
		o_packet_sender : OUT std_logic_vector(0 to 7);
		o_packet_valid : OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk :  std_logic := '0';
	SIGNAL reset :  std_logic := '0';
	SIGNAL i_request :  std_logic := '0';
	SIGNAL i_packet_valid :  std_logic := '0';
	SIGNAL i_token :  std_logic := '0';
	SIGNAL i_user_opcode :  std_logic_vector(0 to 7) := (others=>'0');
	SIGNAL i_user_data :  std_logic_vector(0 to 31) := (others=>'0');
	SIGNAL i_user_channel :  std_logic_vector(0 to 7) := (others=>'0');
	SIGNAL i_user_sender :  std_logic_vector(0 to 7) := (others=>'0');
	SIGNAL i_packet_data :  std_logic_vector(0 to 31) := (others=>'0');
	SIGNAL i_packet_channel :  std_logic_vector(0 to 7) := (others=>'0');
	SIGNAL i_packet_sender :  std_logic_vector(0 to 7) := (others=>'0');

	--Outputs
	SIGNAL o_user_data :  std_logic_vector(0 to 31);
	SIGNAL o_user_channel :  std_logic_vector(0 to 7);
	SIGNAL o_user_sender :  std_logic_vector(0 to 7);
	SIGNAL o_busy :  std_logic;
	signal o_send_ready : std_logic;
	signal o_recv_ready : std_logic;
	SIGNAL o_token :  std_logic;
	SIGNAL o_packet_data :  std_logic_vector(0 to 31);
	SIGNAL o_packet_channel :  std_logic_vector(0 to 7);
	SIGNAL o_packet_sender :  std_logic_vector(0 to 7);
	SIGNAL o_packet_valid :  std_logic;


BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: message_manager PORT MAP(
		clk => clk,
		reset => reset,
		i_request => i_request,
		i_user_opcode => i_user_opcode,
		i_user_data => i_user_data,
		i_user_channel => i_user_channel,
		i_user_sender => i_user_sender,
		o_user_data => o_user_data,
		o_user_channel => o_user_channel,
		o_user_sender => o_user_sender,
		o_busy => o_busy,
		o_send_ready => o_send_ready,
		o_recv_ready => o_recv_ready,
		i_packet_data => i_packet_data,
		i_packet_channel => i_packet_channel,
		i_packet_sender => i_packet_sender,
		i_packet_valid => i_packet_valid,
		i_token => i_token,
		o_token => o_token,
		o_packet_data => o_packet_data,
		o_packet_channel => o_packet_channel,
		o_packet_sender => o_packet_sender,
		o_packet_valid => o_packet_valid
	);

	tb : PROCESS

	 procedure send_packet(channel: in std_logic_vector(0 to 7); sender : in std_logic_vector(0 to 7); data : in std_logic_vector(0 to 31)) is
	 begin
		-- Send a packet
		wait until clk = '0' and o_send_ready = '1';
			i_user_sender	<= sender;
			i_user_channel	<= channel;
			i_user_data		<= data;
			i_user_opcode	<= x"04";
			i_request	<= '1';
		wait until o_busy = '1' and clk = '1';
			i_request	<= '0';
		wait until clk = '0';
			i_user_sender	<= (others => '0');
			i_user_channel	<= (others => '0');
			i_user_data		<= (others => '0');
			i_user_opcode	<= (others => '0');
		wait until clk = '1';
	end procedure send_packet;

	 procedure recv_packet is
	 begin
		-- Receive a packet
		wait until clk = '0' and o_recv_ready = '1';
			i_user_sender	<= (others => '0');
			i_user_channel	<= (others => '0');
			i_user_data		<= (others => '0');
			i_user_opcode	<= x"05";
			i_request	<= '1';
		wait until o_busy = '1' and clk = '1';
			i_request	<= '0';
		wait until clk = '0';
			i_user_sender	<= (others => '0');
			i_user_channel	<= (others => '0');
			i_user_data		<= (others => '0');
			i_user_opcode	<= (others => '0');
		wait until clk = '1';
	end procedure recv_packet;

	 procedure register_sender(sender: in std_logic_vector(0 to 7)) is
	 begin
		-- Register sender
		wait until clk = '0' and o_busy = '0';
			i_user_sender	<= sender;
			i_user_opcode	<= x"06";
			i_request	<= '1';
		wait until o_busy = '1' and clk = '1';
			i_request	<= '0';
		wait until clk = '0';
			i_user_sender	<= (others => '0');
			i_user_opcode	<= (others => '0');
		wait until clk = '1';
	end procedure register_sender;

	 procedure register_channel(channel: in std_logic_vector(0 to 7)) is
	 begin
		-- Register channel
		wait until clk = '0' and o_busy = '0';
			i_user_channel	<= channel;
			i_user_opcode	<= x"03";
			i_request	<= '1';
		wait until o_busy = '1' and clk = '1';
			i_request	<= '0';
		wait until clk = '0';
			i_user_channel	<= (others => '0');
			i_user_opcode	<= (others => '0');
		wait until clk = '1';
	end procedure register_channel;


	BEGIN

		-- Wait 100 ns for global reset to finish
		wait for 100 ns;

		-- Reset the MM
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
		wait for 100 ns;

		wait for 100 ns;
	
		-- Register a channel
		register_sender(x"AD");
		wait for 50 ns;
		register_channel(x"0A");
		wait for 50 ns;

		-- Send Packets
		send_packet(x"11",x"BB",x"DEADBEEF");
		wait for 50 ns;
		send_packet(x"22",x"EE",x"CAFEBABE");
		wait for 50 ns;
		send_packet(x"33",x"11",x"22222222");

		-- Receive token
		i_token <= '1';
		wait for 20 ns;
		i_token <= '0';

		-- Send Packets
		wait for 20 ns;
		send_packet(x"44",x"44",x"22222222");

		-- Send Packets (This one should arrive after the send queue has emptied, and we have released the token, so it shouldn't be sent)
		wait for 400 ns;
		send_packet(x"55",x"BB",x"33333333");

		-- Receive Packets from outside world

		i_packet_data <= x"AAAAAAAA";	-- Wrong channel, shouldn't receive, but should forward
		i_packet_sender <= x"01";
		i_packet_channel <= x"0B";
		i_packet_valid	<= '1';
		wait for 20 ns;
		i_packet_valid	<= '0';

		wait for 100 ns;
		i_packet_data <= x"91919191";	-- Right channel, should receive, and should forward
		i_packet_sender <= x"01";
		i_packet_channel <= x"0A";
		i_packet_valid	<= '1';
		wait for 100 ns;
		i_packet_valid	<= '0';

		wait for 100 ns;
		i_packet_data <= x"23232323";	-- Right channel, should receive, and should forward
		i_packet_sender <= x"01";
		i_packet_channel <= x"0A";
		i_packet_valid	<= '1';
		wait for 100 ns;
		i_packet_valid	<= '0';

		wait for 100 ns;
		i_packet_data <= x"85858585";	-- Sent by me, shouldn't receive or forward
		i_packet_sender <= x"AD";
		i_packet_channel <= x"0A";
		i_packet_valid	<= '1';
		wait for 20 ns;
		i_packet_valid	<= '0';
		wait for 20 ns;

		-- Receive token again
		i_token <= '1';
		wait for 20 ns;
		i_token <= '0';
		wait for 100 ns;
		-- Now the last remaining packet should be sent out

		-- Ask the system for a packet (the one that was received earlier)
		recv_packet;
		recv_packet;

		wait; -- will wait forever
	END PROCESS;

	clk_proc : process (clk)
	begin
		clk <= (not clk) after 10 ns;		
	end process clk_proc;

END;
