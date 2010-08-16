library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


---------------------------------------------------------------------------------
--
--     U S E R    F U N C T I O N :    R E S A M P L I N G
--
--    In many cases, this function does not have to be changed.
--    Only if you want/need to change/adjust the resampling algorithm
--    you can change it here.
--
--    Here the Residual Systematic Resampling Algorithm is used.
--    It is not easy to change to a complete other resampling algorithm,
--    because the framework is adjusted to use a algorithm, which
--    only uses one cycle of iterations and so without any correction cycle.
--
--    Some basic information about the resampling user function:
--
--    The particle weights are loaded into the local RAM by the Framework
--    The first 63 * 128 bytes (of 64 * 128 bytes) are filled with
--    all the particle weights needed. There will not be any space
--    between the particle weights.
--
--    The last 128 bytes are used for the resampling.
--    The user has to store two values for every particle.
--       1. the index of the particle              (as integer)
--       2. the replication factor of the particle (as integer)
--    The ordering of this two values must not be changed, 
--    because it is used later for the sampling step. 
--
--    The two integer values (also known as index_type) are written
--    into the last 128 byte. Since two integer values need 8 bytes,
--    information about 16 particles can be written into the last 128 bytes
--    of the local ram before they have to be written by the Framework.
--
--    The outgoing signal write_burst has to be '1', if the the indexes
--    and replication factors should be written into the Main Memory.
--    This should only happen, if the information about 16
--    particles is resampled or the last particle has been resampled.
-- 
--    The incoming signal write_burst_done is equal to '1', if the
--    Framework has written the information to the Main Memory
--  
--    If resampling is finished the outgoing signal finish has to be set to '1'.
--    A new run of the resampling will be started if the next particles are
--    loaded into local RAM. This is the case when the incoming signal
--    particles_loaded is equal to '1'.
--
------------------------------------------------------------------------------------

entity uf_resampling is

	generic (
		C_BURST_AWIDTH : integer := 12;
		C_BURST_DWIDTH : integer := 32
	);

	port (
		clk    : in  std_logic;
		reset  : in  std_logic;

		-- burst ram interface
		o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
		o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
		i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic;

		-- additional incoming signals
		-- init signal
		init                         : in std_logic;
		-- enable signal
		enable                       : in std_logic;
		-- start signal for the resampling user process
		particles_loaded             : in std_logic;
		-- number of particles in local RAM
		number_of_particles          : in integer;
		-- number of particles in total
		number_of_particles_in_total : in integer;
		-- index of first particles (the particles are sorted increasingly)
		start_particle_index         : in integer; 
		-- resampling function init
		U_init                       : in integer;
		-- address of the last 128 byte burst in local RAM
		write_address                : in std_logic_vector(0 to C_BURST_AWIDTH-1);
		-- information if a write burst has been handled by the Framework 
		write_burst_done             : in std_logic;
	 
		-- additional outgoing signals
		-- this signal has to be set to '1', if the Framework should write
		-- the last burst from local RAM into Maim Memory 
		write_burst  : out std_logic;
		-- write burst done acknowledgement
		write_burst_done_ack  : out std_logic;
		-- number of currently written particles
		written_values : out integer;
		-- if every particle is resampled, this signal has to be set to '1'
		finished     : out std_logic
	);
end uf_resampling;

architecture Behavioral of uf_resampling is

	-- GRANULARITY
	constant GRANULARITY :integer := 16384;

	-- local RAM read/write address
	signal local_ram_read_address  : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal local_ram_write_address : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	-- particle counter
	signal counter : integer := 0;

	-- particle counter for allready resampled particles at all
	signal counter_resampled_particles : integer := 0;

	-- write counter (used bytes)
	signal write_counter :integer := 0;

	-- current particle weight
	signal current_particle_weight : integer := 0;

	-- signals needed for residual systematic resampling
	signal temp : integer := 0;
	signal fact : integer := 0; -- replication factor
	signal U    : integer := 0;

	-- states
	type t_state is (initialize,
		load_particle_1, load_particle_2, load_weight, 
		calculate_replication_factor_1, calculate_replication_factor_2,
		calculate_replication_factor_3, calculate_replication_factor_4,
		calculate_replication_factor_5, calculate_replication_factor_6,
		write_particle_index, write_particle_replication,
		write_burst_decision, write_burst, write_burst_done_ack,
		write_burst_done_ack_2, finish
	);

	-- current state
	signal state : t_state := initialize;


begin

	-- burst ram clock
	o_RAMClk  <= clk;



---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
--		
-- (0) initialize
-- 
--	i = 0;   // current particle
--	j = 0;   // current replication factor
--	k = 0;   // current number of cloned particles
--	finished = 0;
-- 
-- 
-- (1) load particle and weight
-- 
--	load weight of i-th particle from local memory
--	i ++;
--  
-- 
-- (2) calculate replication
-- 
--	calculate replication factor
-- 
-- 
-- (3) write particle index and replication
-- 
--	write particle index + replicationfactor to local ram
-- 
-- 
-- (4) write burst
--
--	write_burst = 1;
--	if (write_burst_done)
--		write_burst = 0;
--		go to step 4
--
--
-- (5) finished
-- 
--	finished = 1;
--	if (particles_loaded)
--		go to step 0;
--
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

state_proc : process(clk, reset)

begin

	if (reset = '1') then
		state <= initialize;
  	elsif rising_edge(clk) then
		if init = '1' then
			state    <= initialize;
			o_RAMData <= (others=>'0');
			o_RAMWE   <= '0';
			o_RAMAddr <= (others => '0');
			U         <= U_init;
			  
	elsif enable = '1' then
		case state is

			when initialize =>
				--! init data  
				local_ram_read_address  <= (others => '0');
				local_ram_write_address <= write_address;
				counter_resampled_particles    <= 0;
				counter                        <= start_particle_index;
				current_particle_weight  <= 0;
				temp <= 0;
				fact <= 0;
				--U    <= U_init;
				write_counter <= 0;
				written_values <= 0;
				write_burst <= '0';
				finished <= '0';
				o_RAMWE  <= '0';
				if (particles_loaded = '1') then
					state <= load_particle_1;
				end if;		
		  
			when load_particle_1 =>
				--! load a particle
				write_burst <= '0';
				if (number_of_particles <= counter_resampled_particles) then
					state <= write_burst_decision;
						
				else
					o_RAMAddr <= local_ram_read_address;
					state <= load_particle_2;
				end if;

			when load_particle_2 =>
				--!needed because reading from local RAM needs two clock steps
				state <= load_weight;				
 
			when load_weight =>
				--! load particle weight
				current_particle_weight <= TO_INTEGER(SIGNED(i_RAMData));
				state <= calculate_replication_factor_1;

			when calculate_replication_factor_1 =>
				--! calculate replication factor (step 2/6)		  
				temp <= current_particle_weight * number_of_particles_in_total;
				state <= calculate_replication_factor_2;

			when calculate_replication_factor_2 =>
				--! calculate replication factor (step 2/6)		  
				temp <= temp - U;
				state <= calculate_replication_factor_3;	

			when calculate_replication_factor_3 =>
				--! calculate replication factor (step 3/6)		  
				fact <= temp + GRANULARITY;
				state <= calculate_replication_factor_4;

			when calculate_replication_factor_4 =>
				--! calculate replication factor (step 4/6)		  
				fact <= fact / GRANULARITY;
				state <= calculate_replication_factor_5;

			when calculate_replication_factor_5 =>
				--! calculate replication factor (step 5/6)
				U <= fact * GRANULARITY;
				state <= calculate_replication_factor_6;

			when calculate_replication_factor_6 =>
				--! calculate replication factor (step 6/6)
				U <= U - temp;
				state <= write_particle_index;
				-- todo: change back
				--state <= write_burst_decision;

			when write_particle_index =>
				--! read particle from local ram
				-- copy particle_size / 32 from local RAM to local RAM		        
				o_RAMWE   <= '1';
				o_RAMAddr <= local_ram_write_address;
				o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(counter, C_BURST_DWIDTH));
				local_ram_write_address <= local_ram_write_address + 1;
				state     <= write_particle_replication;

			when write_particle_replication =>
				--! needed because reading takes 2 clock steps	  		 
				o_RAMWE   <= '1';
				o_RAMAddr <= local_ram_write_address;
				o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(fact, C_BURST_DWIDTH));
				local_ram_write_address <= local_ram_write_address + 1;
				write_counter <= write_counter + 1;
				state <= write_burst_decision;

			when write_burst_decision =>
				--! write burst to main memory            
				o_RAMWE   <= '0';
				if (16 <= write_counter) then
					-- write burst
					state <= write_burst;
					-- todo change back
					--state <= write_burst_decision;
					write_counter <= 0;
					local_ram_write_address <= write_address;
					written_values <= 16;  
				elsif (number_of_particles <= counter_resampled_particles and write_counter > 0) then
					-- write burst
					state <= write_burst;
					--todo: changed back
					--state <= write_burst_decision;
					write_counter <= 0;
					--write_burst <= '1';
					written_values <= write_counter;
				elsif (number_of_particles <= counter_resampled_particles) then
					state <= finish;  
				else
					-- get next particle
					counter <= counter + 1;
					counter_resampled_particles <= counter_resampled_particles + 1;
					local_ram_read_address <= local_ram_read_address + 1;
					state <= load_particle_1;
				end if;

			when write_burst =>
				--! write burst to main memory	    
				--write_burst <= '1';
				--written_values <= write_counter;
				write_burst <= '1';
				write_burst_done_ack <= '0';
				--change back
				--write_counter <= 0;
				if (write_burst_done = '1') then
					write_burst <= '0';
					state <= write_burst_done_ack;
				end if;
	 
			when write_burst_done_ack =>
				--! write burst to main memory
				write_burst_done_ack <= '1';
				write_counter <= 0;
				write_burst <= '0';
				if (write_burst_done = '0') then
					state <= write_burst_done_ack_2;
				end if;				
				
			when write_burst_done_ack_2 =>
				--! write burst to main memory
				write_burst_done_ack <= '0';
				if (number_of_particles <= counter_resampled_particles) then  
					state <= finish;
				else
					--todo: changed for hopefully good
					--state <= load_particle_1;
					state <= write_burst_decision;
				end if;

			when finish =>
				--! write finished signal            
				write_burst <= '0';
				finished <= '1';
				if (particles_loaded = '1') then
					state <= initialize;
				end if;		  

 			when others =>
				state <= initialize;
 			end case;
		end if;
	end if;
 
end process;
end Behavioral;


