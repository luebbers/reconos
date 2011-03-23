--	very simple arbiter, slot 0 has highest priority, everything else can starve
--  due to lack of better knowledge: no generics are used.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity arbiter is

generic (
	C_NR_SLOTS : integer := 3	-- it is not a "real" generic, e.g., we still have to adapt the number of ports and the number of signals manually
);

port (
	i_ready : in std_logic_vector(0 to C_NR_SLOTS - 1);  	--every thread can tell whether it is ready to accept data

	i_req_0	: in std_logic_vector(0 to C_NR_SLOTS - 1);		--requests vector of thread Nr 0 (0 to 0 is allowed, loops are explicitly allowed)
	i_req_1	: in std_logic_vector(0 to C_NR_SLOTS - 1);		--requests vector of thread Nr. 1. (element 0 = 1 => want to talk with thread 0)
	i_req_2	: in std_logic_vector(0 to C_NR_SLOTS - 1);		--requests vector of thread Nr. 2.
	 
	o_grant_0	: out std_logic_vector(0 to C_NR_SLOTS - 1);	--grant vector to thread NR 0. (element 0 = 1 => allowed to talk to thread 0)
	o_grant_1	: out std_logic_vector(0 to C_NR_SLOTS - 1);	--grant vector to thread NR 1. (element 0 = 1 => allowed to talk to thread 0)
	o_grant_2	: out std_logic_vector(0 to C_NR_SLOTS - 1);	--grant vector to thread Nr 2. (element 0 = 1 => allowed to talk to thread 0)

	clk    : in  std_logic;
	reset  : in  std_logic
);
end arbiter;

architecture Behavioral of arbiter is

	signal req_for_thread_0 : std_logic_vector(0 to C_NR_SLOTS -1); -- request signals for talking with thread 0
	signal req_for_thread_1 : std_logic_vector(0 to C_NR_SLOTS -1); -- element 0 = 1 => thread 0 wants to talk to thread 1
	signal req_for_thread_2 : std_logic_vector(0 to C_NR_SLOTS -1);
	signal grant_for_thread_0 : std_logic_vector(0 to C_NR_SLOTS -1); -- grant signals for talking with thread 0
	signal grant_for_thread_1 : std_logic_vector(0 to C_NR_SLOTS -1); -- element 0 = 1 => thread 0 is allowed to talk to thread 1
	signal grant_for_thread_2 : std_logic_vector(0 to C_NR_SLOTS -1);

	type t_state is (STATE_INIT, STATE_WAIT, STATE_GRANT_0, STATE_GRANT_1, STATE_GRANT_2);
	signal b0_state			: t_state := STATE_INIT;
    signal b0_state_next	: t_state := STATE_INIT;
 	signal b1_state			: t_state := STATE_INIT;
    signal b1_state_next	: t_state := STATE_INIT;
    signal b2_state			: t_state := STATE_INIT;
    signal b2_state_next	: t_state := STATE_INIT;

begin
	-- how could this be done less ugly?...
	req_for_thread_0(0) <= i_req_0(0);	
	req_for_thread_0(1) <= i_req_1(0);	
	req_for_thread_0(2) <= i_req_2(0);
	
	req_for_thread_1(0) <= i_req_0(1);--	'1'
	req_for_thread_1(1) <= i_req_1(1);--	'0'
	req_for_thread_1(2) <= i_req_2(1);-- 	'0'	

	req_for_thread_2(0) <= i_req_0(2);	
	req_for_thread_2(1) <= i_req_1(2);	
	req_for_thread_2(2) <= i_req_2(2);	

	o_grant_0(0) <= grant_for_thread_0(0);
	o_grant_0(1) <= grant_for_thread_1(0);
	o_grant_0(2) <= grant_for_thread_2(0);

	o_grant_1(0) <= grant_for_thread_0(1);
	o_grant_1(1) <= grant_for_thread_1(1);
	o_grant_1(2) <= grant_for_thread_2(1);

	o_grant_2(0) <= grant_for_thread_0(2); --0
	o_grant_2(1) <= grant_for_thread_1(2); --1
	o_grant_2(2) <= grant_for_thread_2(2); --0


	--computes the grant signal for bus_0 (e.g. determines who is allowed to send to the hwthread in slot 0.
	bus_0 : process(req_for_thread_0, b0_state)
	begin
	b0_state_next <= b0_state;
	case b0_state is
	when STATE_INIT =>
		b0_state_next <= STATE_WAIT;
		grant_for_thread_0 <= (others => '0');

	when STATE_WAIT => --highes priority has slot 0 the rest can starve.
		if req_for_thread_0(0) = '1' then
			b0_state_next <= STATE_GRANT_0;
			grant_for_thread_0 <= "100";
		elsif req_for_thread_0(1) = '1' then
			b0_state_next <= STATE_GRANT_1;
			grant_for_thread_0 <= "010";
		elsif req_for_thread_0(2) = '1' then
			b0_state_next <= STATE_GRANT_2;
			grant_for_thread_0 <= "001";
		else
			b0_state_next <= STATE_WAIT;
			grant_for_thread_0 <= "000";
		end if;			

	when STATE_GRANT_0 => --he can send as long as he likes...
		if req_for_thread_0(0) = '0' then
			grant_for_thread_0 <= "000";
			b0_state_next <= STATE_WAIT;
		else
			grant_for_thread_0 <= "100";
			b0_state_next <= STATE_GRANT_0;
		end if;
	
	when STATE_GRANT_1 => --he can send as long as he likes...
		if req_for_thread_0(1) = '0' then
			grant_for_thread_0 <= "000";
			b0_state_next <= STATE_WAIT;
		else
			grant_for_thread_0 <= "010";
			b0_state_next <= STATE_GRANT_1;
		end if;

	when STATE_GRANT_2 => --he can send as long as he likes...
		if req_for_thread_0(2) = '0' then
			grant_for_thread_0 <= "000";
			b0_state_next <= STATE_WAIT;
		else
			grant_for_thread_0 <= "001";
			b0_state_next <= STATE_GRANT_2;
		end if;
	
	when others =>
		b0_state_next <= STATE_INIT;
	end case;
	end process;

--	grant_for_thread_1 <= "100";

	--computes the grant signal for bus_0 (e.g. determines who is allowed to send to the hwthread in slot 0.
	bus_1 : process(req_for_thread_1, b1_state)
	begin
	b1_state_next <= b1_state;
	grant_for_thread_1 <= "000";

	case b1_state is
	when STATE_INIT =>
		b1_state_next <= STATE_WAIT;
		grant_for_thread_1 <= "000";

	when STATE_WAIT => --highes priority has slot 0 the rest can starve.
		if req_for_thread_1(0) = '1' then
			b1_state_next <= STATE_GRANT_0;
			grant_for_thread_1 <= "100";
		elsif req_for_thread_1(1) = '1' then
			b1_state_next <= STATE_GRANT_1;
			grant_for_thread_1 <= "010";
		elsif req_for_thread_1(2) = '1' then
			b1_state_next <= STATE_GRANT_2;
			grant_for_thread_1 <= "001";
		else
			b1_state_next <= STATE_WAIT;
			grant_for_thread_1 <= "000";
		end if;			

	when STATE_GRANT_0 => --he can send as long as he likes...
		if req_for_thread_1(0) = '0' then
			grant_for_thread_1 <= "000";
			b1_state_next <= STATE_WAIT;
		else
			grant_for_thread_1 <= "100";
			b1_state_next <= STATE_GRANT_0;
		end if;
	
	when STATE_GRANT_1 => --he can send as long as he likes...
		if req_for_thread_1(1) = '0' then
			grant_for_thread_1 <= "000";
			b1_state_next <= STATE_WAIT;
		else
			grant_for_thread_1 <= "010";
			b1_state_next <= STATE_GRANT_1;
		end if;

	when STATE_GRANT_2 => --he can send as long as he likes...
		if req_for_thread_1(2) = '0' then
			grant_for_thread_1 <= "000";
			b1_state_next <= STATE_WAIT;
		else
			grant_for_thread_1 <= "001";
			b1_state_next <= STATE_GRANT_2;
		end if;
	
	when others =>
		b1_state_next <= STATE_INIT;
	end case;
	end process;


	bus_2 : process(req_for_thread_2, b2_state)
	begin
	b2_state_next <= b2_state;
	case b2_state is
	when STATE_INIT =>
		b2_state_next <= STATE_WAIT;
		grant_for_thread_2 <= (others => '0');

	when STATE_WAIT => --highes priority has slot 0 the rest can starve.
		if req_for_thread_2(0) = '1' then
			b2_state_next <= STATE_GRANT_0;
			grant_for_thread_2 <= "100";
		elsif req_for_thread_2(1) = '1' then
			b2_state_next <= STATE_GRANT_1;
			grant_for_thread_2 <= "010";
		elsif req_for_thread_2(2) = '1' then
			b2_state_next <= STATE_GRANT_2;
			grant_for_thread_2 <= "001";
		else
			b2_state_next <= STATE_WAIT;
			grant_for_thread_2 <= "000";
		end if;			

	when STATE_GRANT_0 => --he can send as long as he likes...
		if req_for_thread_2(0) = '0' then
			grant_for_thread_2 <= "000";
			b2_state_next <= STATE_WAIT;
		else
			grant_for_thread_2 <= "100";
			b2_state_next <= STATE_GRANT_0;
		end if;
	
	when STATE_GRANT_1 => --he can send as long as he likes...
		if req_for_thread_2(1) = '0' then
			grant_for_thread_2 <= "000";
			b2_state_next <= STATE_WAIT;
		else
			grant_for_thread_2 <= "010";
			b2_state_next <= STATE_GRANT_1;
		end if;

	when STATE_GRANT_2 => --he can send as long as he likes...
		if req_for_thread_2(2) = '0' then
			grant_for_thread_2 <= "000";
			b2_state_next <= STATE_WAIT;
		else
			grant_for_thread_2 <= "001";
			b2_state_next <= STATE_GRANT_2;
		end if;
	
	when others =>
		b2_state_next <= STATE_INIT;
	end case;
	end process;

	memzing : process(clk, reset)
    begin
   	if reset = '1' then
		b0_state <= STATE_INIT;
		b1_state <= STATE_INIT;
		b2_state <= STATE_INIT;

	elsif rising_edge(clk) then
		b0_state <= b0_state_next;
		b1_state <= b1_state_next;
		b2_state <= b2_state_next;
	end if;
	end process;

end Behavioral;

