
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:16:35 10/31/2006
-- Design Name:   fast_queue
-- Module Name:   C:/fast_queueProject/src/fast_queue_tb.vhd
-- Project Name:  myProj
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fast_queue
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

ENTITY fast_queue_tb IS
END fast_queue_tb;

ARCHITECTURE behavior OF fast_queue_tb IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT fast_queue
	generic(
	   ADDRESS_BITS	: integer := 2;
   	   DATA_BITS	: integer := 32
	  );
	PORT(
		clk : IN std_logic;
		rst : IN std_logic;
		add_busy : out std_logic;
		remove_busy : out std_logic;
		add : IN std_logic;
		remove : IN std_logic;
		entryToAdd : IN std_logic_vector(0 to 31);    
		headValid : INOUT std_logic;
		full : INOUT std_logic;
		empty : INOUT std_logic;      
		head : OUT std_logic_vector(0 to 31)
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk :  std_logic := '0';
	SIGNAL rst :  std_logic := '0';
	SIGNAL add :  std_logic := '0';
	SIGNAL remove :  std_logic := '0';
	SIGNAL entryToAdd :  std_logic_vector(0 to 31) := (others=>'0');

	--BiDirs
	SIGNAL headValid :  std_logic;
	SIGNAL full :  std_logic;
	SIGNAL empty :  std_logic;
	signal add_busy : std_logic;
	signal remove_busy : std_logic;

	--Outputs
	SIGNAL head :  std_logic_vector(0 to 31);

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: fast_queue
	GENERIC MAP(
		ADDRESS_BITS => 2,
		DATA_BITS => 32
	)
	PORT MAP(
		clk => clk,
		rst => rst,
		add_busy => add_busy,
		remove_busy => remove_busy,
		add => add,
		remove => remove,
		entryToAdd => entryToAdd,
		head => head,
		headValid => headValid,
		full => full,
		empty => empty
	);

	tb : PROCESS
	BEGIN

		-- Wait 100 ns for global reset to finish
		wait for 100 ns;

		-- Place stimulus here
		rst	<= '1';	-- Reset the FIFO
		wait for 20 ns;
		rst	<= '0';
		wait for 20 ns;
		
		
		entryToAdd <= x"1111_1111";	-- Add an entry
		wait for 10 ns;
		add <= '1';
		wait for 20 ns;
		add <= '0';
		wait for 100 ns;

		entryToAdd <= x"2222_2222";	-- Add an entry
		wait for 10 ns;
		add <= '1';
		wait for 20 ns;
		add <= '0';
		wait for 100 ns;

		entryToAdd <= x"3333_3333";	-- Add an entry
		wait for 10 ns;
		add <= '1';
		wait for 20 ns;
		add <= '0';
		wait for 100 ns;

		entryToAdd <= x"4444_4444";	-- Add an entry
		wait for 10 ns;
		add <= '1';
		wait for 20 ns;
		add <= '0';
		wait for 100 ns;
		
		remove <= '1';	-- Remove an entry
		wait for 20 ns;
		remove <= '0';
		wait for 100 ns;

		remove <= '1';	-- Remove an entry
		wait for 20 ns;
		remove <= '0';
		wait for 100 ns;

		remove <= '1';	-- Remove an entry
		wait for 20 ns;
		remove <= '0';
		wait for 100 ns;

		remove <= '1';	-- Remove an entry
		wait for 20 ns;
		remove <= '0';
		wait for 100 ns;

		remove <= '1';	-- Remove an entry
		wait for 20 ns;
		remove <= '0';
		wait for 100 ns;
		
		entryToAdd <= x"5555_5555";	-- Add an entry
		wait for 10 ns;
		add <= '1';
		wait for 20 ns;
		add <= '0';
		wait for 100 ns;		

		remove <= '1';	-- Remove an entry
		wait for 20 ns;
		remove <= '0';
		wait for 100 ns;

		wait; -- will wait forever
	END PROCESS;

	clockProcess : PROCESS
	BEGIN
		clk <= '1';			-- clock cycle 10 ns
		wait for 5 ns;
		clk <= '0';
		wait for 5 ns;		
	END PROCESS;

END;
