-------------------------------------------------------------------------------------
-- Copyright (c) 2006, University of Kansas - Hybridthreads Group
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
--     * Redistributions of source code must retain the above copyright notice,
--       this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright notice,
--       this list of conditions and the following disclaimer in the documentation
--       and/or other materials provided with the distribution.
--     * Neither the name of the University of Kansas nor the name of the
--       Hybridthreads Group nor the names of its contributors may be used to
--       endorse or promote products derived from this software without specific
--       prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity parallel is
	generic
	(
		-- The number of input bits into the priority encoder
		INPUT_BITS	: integer	:= 128;

		-- The number of output bits from the priority encoder.
		-- For correct operation the number of output bits should be
		-- any number greater than or equal to log2( INPUT_BITS ).
		OUTPUT_BITS	: integer	:= 7;

		-- The number of bits to consider at a time.
		-- This number should be less that INPUT_BITS and should divide
		-- INPUT_BITS evenly.
		CHUNK_BITS	: integer	:= 32
	);
	port
	(
		clk			: in  std_logic;
		rst			: in  std_logic;

		input		: in  std_logic_vector(0 to INPUT_BITS - 1);
		enable		: in  std_logic;
	
		output		: out std_logic_vector(0 to OUTPUT_BITS - 1)
	);
end entity parallel;

-------------------------------------------------------------------------------
-- architecture
-------------------------------------------------------------------------------
architecture imp of parallel is
	type find_state is ( narrow_search, prior_encode, prior_read );

	-- Find the log base 2 of a natural number.
	-- This function works for both synthesis and simulation
	function log2( N : in natural ) return positive is
	begin
		if N <= 2 then
			return 1;
		else
			return 1 + log2(N/2);
		end if;
	end;

	-- Determine if any bit in the array is set.
	-- If any of the bits are set then '1' is returned,
	-- otherwise '0' is returned.
	function bit_set( data : in std_logic_vector ) return std_logic is
	begin
		for i in data'range loop
			if( data(i) = '1' ) then
				return '1';
			end if;
		end loop;
				
		return '0';
	end function;

	-- Return the array slice that is used for a given chunk index
	function bit_range( data : in std_logic_vector; index : in integer ) return std_logic_vector is
	begin
		return data( (index * CHUNK_BITS) to ((index + 1) * CHUNK_BITS) - 1 );
	end function;

	-- Given the number of INPUT_BITS and the number of CHUNK_BITS we
	-- can determine the number of chunks we will need to look at.
	constant CHUNK_NUM	: integer	:= INPUT_BITS / CHUNK_BITS;

	-- Given the number of CHUNK_BITS we can determine the number of output
	-- bits that the priority encoder is going to return.
	constant CHUNK_OUT	: integer	:= log2( CHUNK_BITS );

	-- The number of EXTRA bits is the number of extra bits that we number add
	-- to the output of the priority encoder to get the real output.
	constant EXTRA_BITS	: integer	:= OUTPUT_BITS - CHUNK_OUT;

	-- Enable signal delayed by 1 clock cycle
	signal enable_d1	: std_logic;
	
	-- Encoder finished flag
	signal encoder_finished, encoder_finished_next : std_logic;
	
	-- These two signals control the state transitions in the FSM which
	-- produces the output for this entity.
	signal find_current : find_state;
	signal find_next	: find_state;

	-- These signals are the input signals into the priority encoder.
	signal pri_in		: std_logic_vector(0 to CHUNK_BITS - 1);
	signal pri_in_next	: std_logic_vector(0 to CHUNK_BITS - 1);

	-- This signal is the output from the priority encoder.
	signal pri_out		: std_logic_vector(0 to CHUNK_OUT - 1 );

	-- This is the overall output from the design. It could be removed
	-- by just assigning to output instead, however, that would mean that
	-- output would need to be an inout signal instead of just an out.
	signal best			: std_logic_vector(0 to OUTPUT_BITS - 1);
	signal best_next	: std_logic_vector(0 to OUTPUT_BITS - 1);
	
	-- These signals are used to narrow our search for the highest priority.
	signal narrow		: std_logic_vector(0 to CHUNK_NUM - 1);
	signal narrow_next	: std_logic_vector(0 to CHUNK_NUM - 1);

	-- This forces the synthesizer to recognize the pri_out signal as the
	-- output from a priority encoder. XST documentation says that the
	-- synthesizer will recognize a priority encoder by setting this to
	-- "yes" but will not actually generate a priority encoder unless this
	-- is set to "force".
	attribute PRIORITY_EXTRACT : string;
	attribute PRIORITY_EXTRACT of pri_out: signal is "force";

begin

	-- Output the best priority
	output	<= best;

	-- This process is the priority encoder. It will determine the highest bits
	-- set in the array pri_in and will return its index on the signal pri_out.
	--
	-- Notice that this process is NOT sensitive to the clock. This process
	-- would not be recognized as a priority encoder if it were sensitive to
	-- the clock.
	priority_encoder : process ( pri_in ) is
	begin
		-- The default output. It no bits are set in the array (or if only
		-- bit 0 is set) then this is the value returned.
		pri_out	<= (others => '0');

		-- This statement loops over the entire array and finds the index of the
		-- highest bit set. The index of the highest bit set is then converted
		-- into a std_logic_vector and output onto pri_out.
		--
		-- Notice that the loop starts at the highest index and proceeds to the
		-- lowest index. This is because in our system the lower the bit index
		-- the higher the priority.
		for i in pri_in'high downto 0 loop
			if( pri_in(i) = '1' ) then
				pri_out <= std_logic_vector( to_unsigned(i, pri_out'length) );
			end if;
		end loop;
	end process priority_encoder;

	-- This process controls the state transition from the current state
	-- to the next state (and also handles reset). It also takes care of
	-- transitioning FSM inputs to there next values.
	find_best_next : process ( clk, rst, find_next ) is
	begin
		if( rising_edge(clk) ) then
			if( rst = '1' ) then
				find_current 	<= narrow_search;
				best			<= (others => '0');
				pri_in			<= (others => '0');
				narrow			<= (others => '0');
				encoder_finished	<= '0';
			else
				find_current 	<= find_next;
				best			<= best_next;
				pri_in			<= pri_in_next;
				narrow			<= narrow_next;
				encoder_finished	<= encoder_finished_next;
			end if;
		end if;
	end process find_best_next;

	delay_reg : process(clk) is
	begin
		if clk'event and clk = '1' then
			if rst = '1' then
				enable_d1	<= '0';
			else
				enable_d1	<= enable;
			end if;
		end if;
	end process delay_reg;

	-- This process implements the FSM logic. It is broken into three states.
	-- NARROW_SEARCH:
	--   This state narrows the priority search by taking each chunk of the input and
	--   or'ing all of the chunks bits together. This provides an indication of which
	--   chunk of the input contains the highest priority.
	--
	--   This allows use to use a smaller priority encoder as the expense of a 2 clock
	--   cycle delay. However, the smaller priority encoder provides significant savings
	--   in terms of slice utilization.
	--
	-- PRIOR_ENCODE:
	--   This state determines which of the chunks contains the highest priority input and
	--   then places that chunk's input bits onto the priority encoders input lines. If no
	--   bits in the input array are set then the priority encoders input lines are NOT
	--   changed.
	--
	-- PRIOR_READ:
	--   This state reads the data off of the priority encoder and then adds the extra bits
	--   needed to produce the full priority value. This is done because the priority encoder
	--   returns the index of the highest bit of the selected chunk but we want the index
	--   of the highest bit set in the input not in the chunk.
	--
	--   Luckily, the translation from chunk index to input index it straight forward because
	--   chunks are just non-overlapping slices of the input array.
	find_best_logic : process( find_current, input, best, pri_in, narrow, pri_out, enable, enable_d1, encoder_finished ) is
	begin
		find_next 		<= find_current;
		best_next		<= best;
		pri_in_next		<= pri_in;
		narrow_next		<= narrow;
		encoder_finished_next		<= encoder_finished;

		case find_current is
			when narrow_search =>
				-- Begin when there is an edge on the enable line
				if( (enable xor enable_d1) = '1' ) then
					encoder_finished_next	<= '0';

					for i in narrow'high downto 0 loop
						narrow_next(i) 	<= bit_set( bit_range( input, i ) );
					end loop;

					find_next <= prior_encode;
				end if;

			when prior_encode =>
				for i in narrow'high downto 0 loop
					if( narrow(i) = '1' ) then
						pri_in_next <= bit_range( input, i );
						--exit;
					end if;
				end loop;

				find_next <= prior_read;

			when prior_read =>
				for i in narrow'high downto 0 loop
					if( narrow(i) = '1' ) then
						best_next	<= std_logic_vector(to_unsigned(i,EXTRA_BITS)) & pri_out;
					end if;
				end loop;

				encoder_finished_next	<= '1';
				find_next 	<= narrow_search;
		end case;
	end process find_best_logic;
end architecture imp;
