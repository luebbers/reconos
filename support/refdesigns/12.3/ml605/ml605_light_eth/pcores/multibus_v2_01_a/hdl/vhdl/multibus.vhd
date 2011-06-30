-- Implementation of a multibus for three hardware threads 
-- (due to lack of better knowledge we did not use generics...). 
-- The bus assumes that an arbiter decides which thread is allowed to send
-- and simply connects the corresponding threads.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity multibus is

generic (
	C_NR_SLOTS : integer := 3	-- it is not a "real" generic, e.g., we still have to adapt the number of ports and the number of signals manually
);

port (
	i_grant_0	: in std_logic_vector(0 to C_NR_SLOTS - 1);	--grant vector to thread NR 0. (element 0 = 1 => allowed to talk to thread 0)
	i_grant_1	: in std_logic_vector(0 to C_NR_SLOTS - 1);	--grant vector to thread NR 1. (element 0 = 1 => allowed to talk to thread 0)
	i_grant_2	: in std_logic_vector(0 to C_NR_SLOTS - 1);	--grant vector to thread Nr 2. (element 0 = 1 => allowed to talk to thread 0)

	o_busdata_0	: out std_logic_vector(0 to 32 - 1); 	-- these are the outgoing signals (data goes to slot 0)
	o_busdata_1	: out std_logic_vector(0 to 32 - 1);
	o_busdata_2	: out std_logic_vector(0 to 32 - 1);

	o_bussof_0	: out std_logic; 	-- these are the outgoing signals (data goes to slot 0)
	o_bussof_1	: out std_logic;
	o_bussof_2	: out std_logic;

	o_buseof_0	: out std_logic; 	-- these are the outgoing signals (data goes to slot 0)
	o_buseof_1	: out std_logic;
	o_buseof_2	: out std_logic;

	i_data_0 	: in std_logic_vector(0 to C_NR_SLOTS * 32 - 1);	--data that comes from thread 0, first 32 bit go to thread 0, second 32 bit go to thread 1, etc
	i_data_1	: in std_logic_vector(0 to C_NR_SLOTS * 32 - 1);
	i_data_2	: in std_logic_vector(0 to C_NR_SLOTS * 32 - 1);

	i_sof_0	: in std_logic_vector(0 to C_NR_SLOTS - 1);
	i_sof_1	: in std_logic_vector(0 to C_NR_SLOTS - 1);
	i_sof_2	: in std_logic_vector(0 to C_NR_SLOTS - 1);

	i_eof_0	: in std_logic_vector(0 to C_NR_SLOTS - 1);
	i_eof_1	: in std_logic_vector(0 to C_NR_SLOTS - 1);
	i_eof_2	: in std_logic_vector(0 to C_NR_SLOTS - 1);

	i_src_rdy_0 : in std_logic_vector(0 to C_NR_SLOTS - 1);
	i_src_rdy_1 : in std_logic_vector(0 to C_NR_SLOTS - 1);
	i_src_rdy_2 : in std_logic_vector(0 to C_NR_SLOTS - 1);

	o_dst_rdy_0 : out std_logic_vector(0 to C_NR_SLOTS - 1);
	o_dst_rdy_1 : out std_logic_vector(0 to C_NR_SLOTS - 1);
	o_dst_rdy_2 : out std_logic_vector(0 to C_NR_SLOTS - 1);

	i_bus_dst_rdy_0 : in std_logic;
	i_bus_dst_rdy_1 : in std_logic;
	i_bus_dst_rdy_2 : in std_logic;

	o_bus_src_rdy_0 : out std_logic;
	o_bus_src_rdy_1 : out std_logic;
	o_bus_src_rdy_2 : out std_logic;


	clk    : in  std_logic;
	reset  : in  std_logic
);
end multibus;

architecture Behavioral of multibus is

	signal grant_for_thread_0 : std_logic_vector(0 to C_NR_SLOTS -1); -- grant signals for talking with thread 0
	signal grant_for_thread_1 : std_logic_vector(0 to C_NR_SLOTS -1); -- element 0 = 1 => thread 0 is allowed to talk to thread 1
	signal grant_for_thread_2 : std_logic_vector(0 to C_NR_SLOTS -1);
	signal data_for_thread_0 : std_logic_vector(0 to C_NR_SLOTS * 32 - 1); --the data that goes to slot 0
	signal data_for_thread_1 : std_logic_vector(0 to C_NR_SLOTS * 32 - 1); --first 32 bit from thread 0, second 32 bit from thread 1, third 32 bit from thread 2
	signal data_for_thread_2 : std_logic_vector(0 to C_NR_SLOTS * 32 - 1); 

	signal sof_for_thread_0 : std_logic_vector(0 to C_NR_SLOTS -1); -- grant signals for talking with thread 0
	signal sof_for_thread_1 : std_logic_vector(0 to C_NR_SLOTS -1); -- element 0 = 1 => thread 0 is allowed to talk to thread 1
	signal sof_for_thread_2 : std_logic_vector(0 to C_NR_SLOTS -1);

	signal eof_for_thread_0 : std_logic_vector(0 to C_NR_SLOTS -1); -- grant signals for talking with thread 0
	signal eof_for_thread_1 : std_logic_vector(0 to C_NR_SLOTS -1); -- element 0 = 1 => thread 0 is allowed to talk to thread 1
	signal eof_for_thread_2 : std_logic_vector(0 to C_NR_SLOTS -1);

	signal src_rdy_for_thread_0 : std_logic_vector(0 to C_NR_SLOTS -1); --the source is ready to send data to thread 0 (for flow control)
	signal src_rdy_for_thread_1 : std_logic_vector(0 to C_NR_SLOTS -1); --the source is ready to send data to thread 0 (for flow control)
	signal src_rdy_for_thread_2 : std_logic_vector(0 to C_NR_SLOTS -1); --the source is ready to send data to thread 0 (for flow control)

begin
	-- how could this be done less ugly?...
	grant_for_thread_0(0) <= i_grant_0(0);
	grant_for_thread_1(0) <= i_grant_0(1);
	grant_for_thread_2(0) <= i_grant_0(2);

	grant_for_thread_0(1) <= i_grant_1(0);
	grant_for_thread_1(1) <= i_grant_1(1);
	grant_for_thread_2(1) <= i_grant_1(2);

	grant_for_thread_0(2) <= i_grant_2(0); 
	grant_for_thread_1(2) <= i_grant_2(1); 
	grant_for_thread_2(2) <= i_grant_2(2); 

	sof_for_thread_0(0) <= i_sof_0(0);
	sof_for_thread_1(0) <= i_sof_0(1);
	sof_for_thread_2(0) <= i_sof_0(2);

	sof_for_thread_0(1) <= i_sof_1(0);
	sof_for_thread_1(1) <= i_sof_1(1);
	sof_for_thread_2(1) <= i_sof_1(2);

	sof_for_thread_0(2) <= i_sof_2(0);
	sof_for_thread_1(2) <= i_sof_2(1);
	sof_for_thread_2(2) <= i_sof_2(2);

	eof_for_thread_0(0) <= i_eof_0(0);
	eof_for_thread_1(0) <= i_eof_0(1);
	eof_for_thread_2(0) <= i_eof_0(2);

	eof_for_thread_0(1) <= i_eof_1(0);
	eof_for_thread_1(1) <= i_eof_1(1);
	eof_for_thread_2(1) <= i_eof_1(2);

	eof_for_thread_0(2) <= i_eof_2(0);
	eof_for_thread_1(2) <= i_eof_2(1);
	eof_for_thread_2(2) <= i_eof_2(2);

	data_for_thread_0(0 to 32 -1) <= i_data_0(0 to 32 - 1);
	data_for_thread_0(32 to 64 -1) <= i_data_1(0 to 32 - 1);
	data_for_thread_0(64 to 96 -1) <= i_data_2(0 to 32 - 1);

	data_for_thread_1(0 to 32 -1) <= i_data_0(32 to 64 -1);
	data_for_thread_1(32 to 64 -1) <= i_data_1(32 to 64 -1);
	data_for_thread_1(64 to 96 -1) <= i_data_2(32 to 64 -1);

	data_for_thread_2(0 to 32 -1) <= i_data_0(64 to 96 -1);
	data_for_thread_2(32 to 64 -1) <= i_data_1(64 to 96 -1);
	data_for_thread_2(64 to 96 -1) <= i_data_2(64 to 96 -1);

	src_rdy_for_thread_0(0) <= i_src_rdy_0(0);
	src_rdy_for_thread_1(0) <= i_src_rdy_0(1);
	src_rdy_for_thread_2(0) <= i_src_rdy_0(2);

	src_rdy_for_thread_0(1) <= i_src_rdy_1(0);
	src_rdy_for_thread_1(1) <= i_src_rdy_1(1);
	src_rdy_for_thread_2(1) <= i_src_rdy_1(2);

	src_rdy_for_thread_0(2) <= i_src_rdy_2(0);
	src_rdy_for_thread_1(2) <= i_src_rdy_2(1);
	src_rdy_for_thread_2(2) <= i_src_rdy_2(2);

	o_dst_rdy_0(0) <= i_bus_dst_rdy_0;
	o_dst_rdy_1(0) <= i_bus_dst_rdy_0;
	o_dst_rdy_2(0) <= i_bus_dst_rdy_0;

	o_dst_rdy_0(1) <= i_bus_dst_rdy_1;
	o_dst_rdy_1(1) <= i_bus_dst_rdy_1;
	o_dst_rdy_2(1) <= i_bus_dst_rdy_1;

	o_dst_rdy_0(2) <= i_bus_dst_rdy_2;
	o_dst_rdy_1(2) <= i_bus_dst_rdy_2;
	o_dst_rdy_2(2) <= i_bus_dst_rdy_2;


	bus_0 : process(data_for_thread_0, grant_for_thread_0, sof_for_thread_0, eof_for_thread_0, src_rdy_for_thread_0)
	variable low 	: natural;
	variable high 	: natural;
	begin
	o_busdata_0 <= (others => '0');
	o_bussof_0 <= '0';
	o_buseof_0 <= '0';
	o_bus_src_rdy_0 <= '0';
	for i in grant_for_thread_0'range loop
		if (grant_for_thread_0(i) = '1') then
			low := i * 32;
			high := (i + 1) * 32;
			o_busdata_0 <= data_for_thread_0(low to high - 1);
			o_bussof_0 <= sof_for_thread_0(i);
			o_buseof_0 <= eof_for_thread_0(i);
			o_bus_src_rdy_0 <= src_rdy_for_thread_0(i);
		end if;
	end loop;
	end process;

	--hard coded slot 0 to slot 1
--	o_busdata_1 <= data_for_thread_1(0 to 31);
--	o_bussof_1 <= sof_for_thread_1(0);
--	o_buseof_1 <= eof_for_thread_1(0);
--	o_bus_src_rdy_1 <= src_rdy_for_thread_1(0);


--alternate version in case the for loop version does not work	
--	o_busdata_1 <= data_for_thread_1(0 to 31) when grant_for_thread_1 = "100" else
--					data_for_thread_1(32 to 63) when grant_for_thread_1 = "010" else
--					data_for_thread_1(64 to 95) when grant_for_thread_1 = "001" else
--					(others => '0');


	bus_1 : process(data_for_thread_1, grant_for_thread_1, sof_for_thread_1, eof_for_thread_1, src_rdy_for_thread_1)
	variable low 	: natural;
	variable high 	: natural;
	begin
	o_busdata_1 <= (others => '0');
	o_bussof_1 <= '0';
	o_buseof_1 <= '0';
	o_bus_src_rdy_1 <= '0';
	for i in grant_for_thread_1'range loop
		if (grant_for_thread_1(i) = '1') then
			low := i * 32;
			high := (i + 1) * 32;
			o_busdata_1 <= data_for_thread_1(low to high - 1);
			o_bussof_1 <= sof_for_thread_1(i);
			o_buseof_1 <= eof_for_thread_1(i);
			o_bus_src_rdy_1 <= src_rdy_for_thread_1(i);
		end if;
	end loop;
	end process;

	bus_2 : process(data_for_thread_2, grant_for_thread_2,sof_for_thread_2, eof_for_thread_2, src_rdy_for_thread_2)
	variable low 	: natural;
	variable high 	: natural;
	begin
	o_busdata_2 <= (others => '0');
	o_bussof_2 <= '0';
	o_buseof_2 <= '0';
	o_bus_src_rdy_2 <= '0';
	for i in grant_for_thread_2'range loop
		if (grant_for_thread_2(i) = '1') then
			low := i * 32;
			high := (i + 1) * 32;
			o_busdata_2 <= data_for_thread_2(low to high - 1);
			o_bussof_2 <= sof_for_thread_2(i);
			o_buseof_2 <= eof_for_thread_2(i);
			o_bus_src_rdy_2 <= src_rdy_for_thread_2(i);			
		end if;
	end loop;
	end process;
end Behavioral;


