-- *************************************************************************
-- File:	queue.vhd
-- Purpose:	Implements a queue (FIFO) usiing inferred BRAM.
-- Author:	Jason Agron
-- *************************************************************************

-- *************************************************************************
-- Library declarations
-- *************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;

library Unisim;
use Unisim.all;
library Unisim;
use Unisim.all;

-- *************************************************************************
-- Entity declaration
-- *************************************************************************
entity fast_queue is
  generic (
	ADDRESS_BITS	: integer := 9;
	DATA_BITS	: integer := 32
	);
  port (
	clk		: in std_logic;
	rst		: in std_logic;
	add_busy	: out std_logic;
	remove_busy	: out std_logic;
	add		: in std_logic;
	remove		: in std_logic;
	entryToAdd	: in std_logic_vector(0 to DATA_BITS-1);
	head		: out std_logic_vector(0 to DATA_BITS-1);
	headValid	: out std_logic;
	full		: out std_logic;
	empty		: out std_logic	
	);
end entity fast_queue;

-- *************************************************************************
-- Architecture declaration
-- *************************************************************************
architecture implementation of fast_queue is

	-- Declare the component for the inferred BRAM
	component infer_bram_dual_port is
	  generic (
	    ADDRESS_BITS	: integer := 9;
	    DATA_BITS	: integer := 32
	    );
	  port (
	    CLKA 	: in std_logic; 
	    ENA   	: in std_logic; 
	    WEA   	: in std_logic;
	    ADDRA 	: in std_logic_vector(0 to ADDRESS_BITS - 1); 
	    DIA   	: in std_logic_vector(0 to DATA_BITS - 1);
	    DOA   	: out  std_logic_vector(0 to DATA_BITS - 1);
	
	    CLKB 	: in std_logic; 
	    ENB   	: in std_logic; 
	    ADDRB 	: in std_logic_vector(0 to ADDRESS_BITS - 1); 
	    DOB   	: out  std_logic_vector(0 to DATA_BITS - 1)
	    );
	end component infer_bram_dual_port;

	-- Internal signals to hook up to output ports
	signal empty_int, full_int, headValid_int : std_logic;

	-- Signals to hook up to the inferred BRAM
	signal ena, enb, wea	: std_logic;
	signal addra, addrb	: std_logic_vector(0 to ADDRESS_BITS-1);
	signal dia,  doa, dob	: std_logic_vector(0 to DATA_BITS-1);

	-- ENQ FSM registers
	signal tailPtr, tailPtr_next, nextFreePtr, nextFreePtr_next	: std_logic_vector(0 to ADDRESS_BITS-1);
	
	-- DEQ FSM registers
	signal headPtr, headPtr_next	: std_logic_vector(0 to ADDRESS_BITS-1);
	signal deq_busy, deq_busy_next	: std_logic;
	signal enq_busy, enq_busy_next	: std_logic;

	-- Enqueue state enumeration
	type enq_state_type is
		(
			reset,
			idle,
			finishAdd
		);			
				
	signal currentEnqState, nextEnqState : enq_state_type := idle;
	
	-- Dequeue state enumeration
	type deq_state_type is
		(
			reset,
			idle,
			finishRemove
		);			
				
	signal currentDeqState, nextDeqState : deq_state_type := idle;

-- *********************************************************
-- *********************************************************
-- *********************************************************
begin

-- Connect up status signals to output ports
empty		<= empty_int;
full		<= full_int;
headValid 	<= headValid_int;
add_busy		<= enq_busy;
remove_busy		<= deq_busy;

-- Instantiation of the BRAM block to hold the queue data structure
queue_BRAM : infer_bram_dual_port
  	generic map (
    	ADDRESS_BITS               => ADDRESS_BITS,
		DATA_BITS                  => DATA_BITS
	)
	port map (
    	CLKA                       => clk,
		ENA                        => ena,
		WEA                        => wea,
		ADDRA                      => addra,
		DIA                        => dia,
		DOA                        => doa,	
	   CLKB                       => clk,
		ENB                        => enb,
		ADDRB                      => addrb,
		DOB                        => dob
	 );

-- Connect head output to data output B of RAM
head <= dob;

-- Status Process
-- Calculate FULL/EMPTY status
STATUS : process
--(clk, rst, tailPtr, headPtr, nextFreePtr, deq_busy) is
(clk, rst, tailPtr, headPtr, nextFreePtr, deq_busy_next) is
begin
	if (clk'event and clk = '1') then
		if (rst = '1') then
			full_int		<= '0';
			empty_int		<= '1';			
		else
			-- Check "full" condition
			if (nextFreePtr = headPtr) then
				full_int <= '1';
			else
				full_int <= '0';
			end if;
				
			-- Check "empty" condition
			--		* headValid = (not empty) and (not deq_busy)
			if (tailPtr = headPtr) then
				empty_int <= '1';
				--headValid_int <= '0' and (not deq_busy);
				headValid_int <= '0' and (not deq_busy_next);
			else
				empty_int <= '0';
				headValid_int <= '1' and (not deq_busy_next);
				--headValid_int <= '1' and (not deq_busy);
			end if;

		end if;
	end if;
end process STATUS;

-- Syncrhonous ENQ FSM Process
-- Control state transitions of ENQ FSM
SYNCH_ENQ : process
(clk, rst, nextEnqState) is
begin
	if (clk'event and clk = '1') then
		if (rst = '1') then
			-- Reset state
			currentEnqState	<= reset;
			tailPtr				<= (others => '0');
--			nextFreePtr			<= (others => '0');
			nextFreePtr			<= conv_std_logic_vector(1,ADDRESS_BITS);
			enq_busy			<= '0';
		else
			-- Transition state
			currentEnqState	<= nextEnqState;
			tailPtr				<= tailPtr_next;
			nextFreePtr			<= nextFreePtr_next;
			enq_busy			<= enq_busy_next;
		end if;
	end if;
end process SYNCH_ENQ;

-- Combinational ENQ FSM Process
-- State machine logic for ENQ FSM
COMB_ENQ : process
(currentEnqState, add, entryToAdd, tailPtr, full_int) is
begin
	-- Setup default values for FSM signals
	nextEnqState	<= currentEnqState;
	tailPtr_next	<= tailPtr;
	nextFreePtr_next <= tailPtr + 1;

	enq_busy_next	<= '0';

	addra	<= tailPtr;
	wea		<= '0';
	ena		<= '0';
	dia		<= entryToAdd;

	-- FSM case statement
	case (currentEnqState) is
		when reset =>
			-- Reset state
			tailPtr_next	<= (others => '0');
			--nextFreePtr			<= (others => '0');
			nextFreePtr_next	<= conv_std_logic_vector(1,ADDRESS_BITS);

			-- Move to idle state
			nextEnqState	<= idle;

		when idle =>
			-- If request to add and queue isn't full
			if (add = '1' and full_int ='0') then

				-- Write entry to BRAM
				addra	<= tailPtr;
				wea	<= '1';
				ena	<= '1';
				dia	<= entryToAdd;

				-- Increment tailPtr
				tailPtr_next	<= tailPtr + 1;
				enq_busy_next	<= '1';

				nextEnqState	<= finishAdd;
			-- Otherwise, stay in the idle state
			else
				enq_busy_next	<= '0';
				nextEnqState	<= idle;
			end if;

		when finishAdd =>
			-- Used for delay
			enq_busy_next	<= '0';
			nextEnqState	<= idle;

		when others =>
			nextEnqState	<= reset;
	end case;
	
end process COMB_ENQ;

-- Syncrhonous DEQ FSM Process
-- Control state transitions of DEQ FSM
SYNCH_DEQ : process
(clk, rst, nextDeqState) is
begin
	if (clk'event and clk = '1') then
		if (rst = '1') then
			-- Reset state
			currentDeqState	<= reset;
			headPtr			<= (others => '0');
			deq_busy		<= '0';
		else
		-- Transition state
			currentDeqState	<= nextDeqState;
			headPtr			<= headPtr_next;
			deq_busy		<= deq_busy_next;
		end if;
	end if;
end process SYNCH_DEQ;

-- Combinational DEQ FSM Process
-- State machine logic for DEQ FSM
COMB_DEQ : process
(currentDeqState, remove, headPtr, headValid_int, empty_int) is
begin
	-- Setup default values for FSM signals
	nextDeqState	<= currentDeqState;
	headPtr_next	<= headPtr;
	deq_busy_next 	<= '0';

	addrb	<= headPtr;
	enb	<= '1';

	-- FSM case statement
	case (currentDeqState) is
		when reset =>
			-- Reset state
			headPtr_next	<= (others => '0');
			deq_busy_next	<= '0';

			-- Move to idle state
			nextDeqState	<= idle;

		when idle =>
			-- If request to remove and queue isn't empty
			if (remove = '1' and empty_int = '0') then
				deq_busy_next	<= '1';
				headPtr_next	<= headPtr + 1;
				nextDeqState	<= finishRemove;
			-- Otherwise stay in idle state
			else
				deq_busy_next	<= '0';
				nextDeqState	<= idle;
			end if;

		when finishRemove =>
			-- Used for delay
			deq_busy_next	<= '0';
			nextDeqState	<= idle;

		when others =>
			nextDeqState	<= reset;
	end case;
	
end process COMB_DEQ;

end architecture implementation;
