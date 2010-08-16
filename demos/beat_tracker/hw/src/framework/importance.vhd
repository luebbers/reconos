library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--        //////   /////////    ///////      ///////                          --
--       //           //       //     //     //    //                         --
--       //           //       //     //     //    //                         --
--        /////       //       //     //     ///////                          --
--            //      //       //     //     //                               --
--            //      //       //     //     //                               --
--       //////       //        ///////      //                               --
--                                                                            -- 
--                                                                            --
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------- 
--                                                                            -- 
--                                                                            --                                                                            --
--  !!! THIS IS PART OF THE HARDWARE FRAMEWORK !!!                            --
--                                                                            --
--  DO NOT CHANGE THIS ENTITY/FILE UNLESS YOU WANT TO CHANGE THE FRAMEWORK    --
--                                                                            --
--  USERS OF THE FRAMEWORK SHALL ONLY MODIFY USER FUNCTIONS/PROCESSES,        --
--  WHICH ARE ESPECIALLY MARKED (e.g by the prefix "uf_" in the filename)     --
--                                                                            --
--                                                                            --
--  Author: Markus Happe                                                      --
--                                                                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


entity importance is

	generic (
		C_BURST_AWIDTH : integer := 12;
		C_BURST_DWIDTH : integer := 32
	);

	port (
		clk    : in  std_logic;
		reset  : in  std_logic;
		i_osif : in  osif_os2task_t;
		o_osif : out osif_task2os_t;

		-- burst ram interface
		o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
		o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
		i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic--;

		-- time base
		--i_timeBase : in std_logic_vector( 0 to C_OSIF_DATA_WIDTH-1 )
	);
end importance;

architecture Behavioral of importance is

	component uf_likelihood is
	Port(	clk    : in  std_logic;
		reset  : in  std_logic;

		-- burst ram interface
		o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
		o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
		i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic;

		init                         : in std_logic;
		enable                       : in std_logic;
		observation_loaded           : in std_logic;
		ref_data_address    : in std_logic_vector(0 to C_BURST_AWIDTH-1);
		observation_address : in std_logic_vector(0 to C_BURST_AWIDTH-1);
		observation_size             : in integer;

		finished         : out std_logic;
		likelihood_value : out integer
	);
	end component;


	attribute keep_hierarchy               : string;
	attribute keep_hierarchy of Behavioral : architecture is "true";

	-- ReconOS thread-local mailbox handles
	constant C_MB_START : std_logic_vector(0 to 31) := X"00000000";
	constant C_MB_DONE  : std_logic_vector(0 to 31) := X"00000001";
	constant C_MB_MEASUREMENT  : std_logic_vector(0 to 31) := X"00000002";

	-- states
	type t_state is (initialize, read_particle_address,
		read_number_of_particles, read_particle_size, read_block_size,
		wait_one_cycle, read_observation_size, needed_bursts, needed_bursts_2,
		needed_reads_1, needed_reads_2, read_observation_address,
		read_ref_data_address, wait_for_message,
		calculate_remaining_observations_1, calculate_remaining_observations_2,
		calculate_remaining_observations_3, calculate_remaining_observations_4, 
		calculate_remaining_observations_5, calculate_remaining_observations_6,
		calculate_remaining_observations_7, calculate_remaining_observations_8, 
		calculate_remaining_observations_9, calculate_remaining_observations_10, 
		calculate_remaining_observations_11, calculate_remaining_observations_12, 	
		load_observation, 
		load_burst_decision, load_burst, load_read_decision,
		load_read, load_read_wait, write_to_ram, wait_after_write,
		wait_after_write_2, wait_after_write_3, load_last_burst,
		load_observation_data_decision, load_observation_data_decision_2,
		load_observation_data_decision_3, load_observation_data_decision_4, 
		load_observation_data_decision_5, --load_observation_data_decision_6,
		--load_observation_data_decision_7,
		likelihood, likelihood_done, write_likelihood, 
		send_message, send_measurement_1, send_measurement_2 
	);

	-- current state
	signal state : t_state := initialize;

	-- particle array
	signal particle_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- observation array
	signal observation_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal observation_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');


	-- reference data
	signal reference_data_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- load address, either reference data address or an observation array address
	signal load_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- local RAM address
	signal local_ram_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal local_ram_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- local RAM data
	signal ram_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- information struct containing array addresses and other information like observation size
	signal information_struct : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- number of particles / observations (set by message box, default = 100)
	signal N : integer := 10;

	-- number of observations
	signal remaining_observations : integer := 10;

	-- number of needed bursts
	signal number_of_bursts : integer := 0;

	-- number of needed bursts to be remembered
	signal number_of_bursts_remember : integer := 0; 

	-- size of a particle
	signal particle_size : integer := 4;

	-- size of a observation
	signal observation_size : integer := 40;

	-- temporary integer signals
	signal temp : integer := 0;
	signal temp2 : integer := 0;
	signal temp3 : integer := 0;
	signal temp4 : integer := 0;
	signal temp5 : integer := 0;
	signal offset : integer := 0;

	-- start observation index
	--signal start_observation_index : integer := 0;

	-- number of reads
	signal number_of_reads : integer := 0;

	-- number of needed reads to be remembered
	signal number_of_reads_remember : integer := 0; 

	-- set to '1', if after the first run the reference data + the first observation is loaded
	signal second_run : std_logic := '0';
  
	-- local ram address for interface
	signal local_ram_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal local_ram_start_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	-- number of particles in a particle block
	signal block_size : integer := 10;

	-- message m, m stands for the m-th number of particle block
	signal message : integer := 1;

	-- message2 is message minus one
	signal message2 : integer := 0;

	-- number of observations, where importance has to be calculated (max = block size)
	signal number_of_calculations : integer := 10;

	-- offset for observation array
	signal observation_offset : integer := 0;

	-- time values for start, stop and the difference of both
	signal time_start       : integer := 0;
	signal time_stop        : integer := 0;
	signal time_measurement : integer := 0;

	-----------------------------------------------------------
	-- NEEDED FOR USER ENTITY INSTANCE
	-----------------------------------------------------------
	-- for likelihood user process
	-- init
	signal init                         : std_logic := '1';
	-- enable
	signal enable                       : std_logic := '0';
	-- start signal for the likelihood user process
	signal observation_loaded             : std_logic := '0';
	-- size of one observation
	signal observation_size_2              : integer := 0;
	-- reference data address
	signal ref_data_address    : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	-- observation data address
	signal observation_address  : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	-- if the likelihood value is calculated, this signal is set to '1'
	signal finished     :  std_logic := '0';
	-- likelihood value
	signal likelihood_value : integer;-- := 5;

	-- for switch 1: corrected local ram address. the least bit is inverted, 
	-- because else the local ram will be used incorrect
	signal o_RAMAddrLikelihood : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	-- for switch 1:corrected local ram address for this importance thread
	signal o_RAMAddrImportance : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  
	-- for switch 2: Write enable, user process
	signal o_RAMWELikelihood : std_logic := '0';
	-- for switch 2: Write enable, importance
	signal o_RAMWEImportance : std_logic := '0';

	-- for switch 3: output ram data, user process
	signal o_RAMDataLikelihood : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
	-- for switch 3: output ram data, importance
	signal o_RAMDataImportance : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');


begin

	-- entity of user process
	user_process : uf_likelihood
	port map (reset=>reset, clk=>clk, o_RAMAddr=>o_RAMAddrLikelihood, o_RAMData=>o_RAMDataLikelihood, 
		i_RAMData=>i_RAMData, o_RAMWE=>o_RAMWELikelihood, o_RAMClk=>o_RAMClk,
		init=>init, enable=>enable, observation_loaded=>observation_loaded,
		ref_data_address=>ref_data_address, observation_address=>observation_address,
		observation_size=>observation_size_2, finished=>finished, likelihood_value=>likelihood_value);


	-- switch 1: address, correction is needed to avoid wrong addressing
	o_RAMAddr <= o_RAMAddrLikelihood(0 to C_BURST_AWIDTH-2) & not o_RAMAddrLikelihood(C_BURST_AWIDTH-1)
 	when enable = '1' else o_RAMAddrImportance(0 to C_BURST_AWIDTH-2) & not o_RAMAddrImportance(C_BURST_AWIDTH-1);

	-- switch 2: write enable
	o_RAMWE <= o_RAMWELikelihood when enable = '1' else o_RAMWEImportance;

	-- switch 3: output ram data
	o_RAMData <= o_RAMDataLikelihood when enable = '1' else o_RAMDataImportance;

	observation_size_2 <= observation_size / 4;


-----------------------------------------------------------------------------
--
--  Reconos State Machine for Importance: 
--
--  1) Information are set (like particle array address and 
--     particle and observation size)
--
--
--  2) Waiting for Message m (Start of a Importance run)
--     Calculate likelihood values for particles of m-th particle block
--     i = 0
--
--
--  3) Calculate if block size particles should be calculated
--     or less (iff last particle block)
--
--
--  4) The Reference Histogram ist copied to the local ram
--
--
--  5) If there is still a observation left (i < counter) then
--          go to step 6;
--     else
--          go to step 9;
--     end if
--
--
--  6) The observation is copied into the local ram
--
--
--  7) Start and run likelihood user process
--     i++;
--
--
--  8) After likelihood user process is finished,
--     write back the weight to particle array
--     go to step 5;
--
--
--  9) Send Message m (Stop of a Importance run)
--     Likelihood values for particles of m-th particle block calculated
--
------------------------------------------------------------------------------
state_proc : process(clk, reset)
    
	-- done signal for Reconos methods
	variable done : boolean;

	-- success signal for Reconos method, which gets a message box
	variable success : boolean;
	 
	-- signals for N, particle_size and observation size
	variable N_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	variable particle_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	
	variable observation_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	variable block_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	variable message_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 
begin
	if reset = '1' then
		reconos_reset(o_osif, i_osif);
		state <= initialize;
	elsif rising_edge(clk) then
 		reconos_begin(o_osif, i_osif);
		if reconos_ready(i_osif) then
			case state is

			when initialize =>
				--! init state, receive information struct
				reconos_get_init_data_s (done, o_osif, i_osif, information_struct);
				-- CHANGE BACK (1 of 6) !!! 
				--reconos_get_init_data_s (done, o_osif, i_osif, particle_array_start_address);
				if done then 
					enable <= '0';
					local_ram_address    <= (others => '0');
					local_ram_address_if <= (others => '0');
					init <= '1';
					observation_loaded <= '0';
					state <= read_particle_address;
					-- CHANGE BACK (2 of 6) !!! 
					--state <= needed_bursts;
				end if;


			when read_particle_address =>
				--! read particle array address
				reconos_read_s (done, o_osif, i_osif, information_struct, particle_array_start_address);
				if done then
					state <= read_number_of_particles;
				end if;
	
		
			when read_number_of_particles =>
				--! read number of particles N
				reconos_read (done, o_osif, i_osif, information_struct+4, N_var);
				if done then
					N <= TO_INTEGER(SIGNED(N_var));
					state <= read_particle_size;
				end if;	           
				
								
			when read_particle_size =>
				--! read particle size
				reconos_read (done, o_osif, i_osif, information_struct+8, particle_size_var);
				if done then
 					particle_size <= TO_INTEGER(SIGNED(particle_size_var));
					state <= read_block_size;
				end if;

				
			when read_block_size =>
				--! read particle size
				reconos_read (done, o_osif, i_osif, information_struct+12, block_size_var);
				if done then
					block_size <= TO_INTEGER(SIGNED(block_size_var));
					state <= wait_one_cycle;
				end if;
				
			when wait_one_cycle =>
				--! wait one cycle
				state <= read_observation_size;
				
				
			when read_observation_size =>
				--! read observation size
				reconos_read (done, o_osif, i_osif, information_struct+16, observation_size_var);
				if done then
					observation_size <= TO_INTEGER(SIGNED(observation_size_var));
					state <= needed_bursts;
				end if;	
				
				
			when needed_bursts =>
				--! calculate needed bursts
				--number_of_bursts_remember <= observation_size / 128;
				temp4 <= observation_size / 4;
				state <= needed_bursts_2;


			when needed_bursts_2 =>
				--! calculate needed bursts
				observation_address <= local_ram_address_if + temp4;
				state <= needed_reads_1;
				

			when needed_reads_1 =>
 				--! calculate number of reads (1 of 2)
				--number_of_reads_remember <= observation_size mod 128;
				-- changed (new) [2 lines]
				number_of_reads_remember <= observation_size;
				number_of_bursts_remember <= 0;
				state <= needed_reads_2;


			when needed_reads_2 =>
				--! calculate number of reads (2 of 2)
				--number_of_reads_remember <= number_of_reads_remember / 8;
				number_of_reads_remember <= number_of_reads_remember / 4;
				state <= read_observation_address;	


			when read_observation_address =>
				--! read observation array address
				reconos_read_s (done,o_osif,i_osif,information_struct+20,observation_array_start_address);
				if done then
					state <= read_ref_data_address;
				end if;
				-- CHANGE BACK (3 of 6) !!!
				--observation_array_start_address <= X"10000000";
				--state <= read_ref_data_address;
	
	
			when read_ref_data_address =>
				--! read reference data address
				reconos_read_s (done, o_osif, i_osif, information_struct+24, reference_data_address);
				if done then
					state <= wait_for_message;
				end if;			 				  
				-- CHANGE BACK (4 of 6) !!!
				--reference_data_address <= X"10000040";		
				--state <= wait_for_message; 	
				

				
			when wait_for_message =>
				--! wait for semaphore to start resampling
				reconos_mbox_get(done, success, o_osif, i_osif, C_MB_START, message_var);
				if done and success then
					message <= TO_INTEGER(SIGNED(message_var));
					-- init signals
					local_ram_address      <= (others => '0');
					local_ram_address_if   <= (others => '0');
					observation_loaded     <= '0';
					enable     <= '0';
					init       <= '1';
					second_run <= '0';
					--time_start <= TO_INTEGER(SIGNED(i_timebase));
					--observation_array_start_address <= X"10000000"; -- TODO: ONLY FOR SIMULATION
					--reference_data_address <= X"20000000"; -- TODO: ONLY FOR SIMULATION
					--observation_address <= local_ram_start_address_if + 14 + 2; -- TODO: ONLY FOR SIMULATION
					--observation_size <= 56;			-- TODO: ONLY FOR SIMULATION
					--block_size <= 2;					-- TODO: ONLY FOR SIMULATION
					--number_of_bursts_remember <= 0; -- TODO: ONLY FOR SIMULATION
					--number_of_reads_remember <= 14; -- TODO: ONLY FOR SIMULATION
					state <= calculate_remaining_observations_1;
					--state <= send_message;
				 end if;


			when calculate_remaining_observations_1 =>
				--! calculates particle array address and number of particles to sample
				message2 <= message-1;
				temp <= 0;
 				state <= calculate_remaining_observations_2;
				
			when calculate_remaining_observations_2 =>
				--! wait
				if (message2 > 0) then
					temp <= temp + block_size;
					state <= calculate_remaining_observations_3;
				else
					state <= calculate_remaining_observations_4;
				end if;

			when calculate_remaining_observations_3 =>
				--! calculates particle array address and number of particles to sample
				--temp <= message2 * block_size;
				message2 <= message2  - 1;
				state <= calculate_remaining_observations_2;
				
			when calculate_remaining_observations_4 =>
				--! wait
				temp5 <= temp;
				temp3 <= 0;
				state <= calculate_remaining_observations_5;				
				
				
			when calculate_remaining_observations_5 =>
				--! calculates particle array address and number of particles to sample
				temp2 <= temp * particle_size;
				state <= calculate_remaining_observations_6;	
				
			when calculate_remaining_observations_6 =>
				--! wait
				state <= calculate_remaining_observations_7;	
				
			when calculate_remaining_observations_7 =>
				--! calculate offset
				--temp3 <= temp * observation_size;
				if (temp5 > 0) then
					temp3 <= temp3 + observation_size;				
					state <= calculate_remaining_observations_8;
				else
					state <= calculate_remaining_observations_9;
				end if;
				
			when calculate_remaining_observations_8 =>
				--! wait
				temp5 <= temp5 - 1;
				state <= calculate_remaining_observations_7;	
				
				
			when calculate_remaining_observations_9 =>
				--! calculates particle array address and number of particles to sample
				remaining_observations    <= N - temp;
				state <= calculate_remaining_observations_10;	

			when calculate_remaining_observations_10 =>
				--! calculates particle array address and number of particles to sample
				particle_array_address    <= particle_array_start_address    + temp2;
				state <= calculate_remaining_observations_11;	
				
			when calculate_remaining_observations_11 =>
				--! calculates particle array address and number of particles to sample
				observation_array_address <= observation_array_start_address + temp3;
				state <= calculate_remaining_observations_12;

			when calculate_remaining_observations_12 =>
				--! calculates particle array address and number of particles to sample
				if (remaining_observations > block_size) then
					remaining_observations <= block_size;
					number_of_calculations <= block_size;
				else
					number_of_calculations <= remaining_observations;
				end if;
				state <= load_observation;					
						
						
			when load_observation =>
				--! prepare to load an observation to local ram
				number_of_bursts <= number_of_bursts_remember;
				number_of_reads  <= number_of_reads_remember;
				load_address <= reference_data_address;
				state <=  load_burst_decision;


			when load_burst_decision =>
				--! decision if a burst is needed
				if (number_of_bursts > 0) then
					state <= load_burst;
					number_of_bursts <= number_of_bursts - 1;
				else
					state <= load_read_decision;
				end if;
			 

			when load_burst =>
				--! load bursts of observation
				reconos_read_burst(done, o_osif, i_osif, local_ram_address, load_address);
				if done then
					local_ram_address         <= local_ram_address         + 128;
					load_address              <= load_address              + 128;
					local_ram_address_if      <= local_ram_address_if      + 32;
					state <= load_burst_decision;
				end if;
			 
			 
			when load_read_decision =>
				--! decision if a read into local ram is needed
				o_RAMWEImportance <= '0';
				if (number_of_reads > 0) then
					state <= load_read;
					--state <= load_last_burst;
				elsif (second_run = '1') then
					state <= likelihood;
				else
					second_run <= '1';
					state <= load_observation_data_decision;
				end if;

			when load_last_burst =>
				--! load last burst
--				reconos_read_burst_l(done,o_osif,i_osif,local_ram_address,load_address,number_of_reads);
--				if done then
--					local_ram_address         <= local_ram_address         + (number_of_reads * 8);
--					load_address              <= load_address              + (number_of_reads * 8);
--					local_ram_address_if      <= local_ram_address_if      + (number_of_reads * 2);
--					number_of_reads <= 0;
					state <= load_read_decision;
				--end if;

 			when load_read =>
				--! load reads of observation
				reconos_read_s(done, o_osif, i_osif, load_address, ram_data);
				if done then
					load_address <= load_address + 4;
					number_of_reads <= number_of_reads - 1;
					state <= load_read_wait;
				end if;
				
			when load_read_wait =>
				--! wait
				state <= write_to_ram;
				
				
			when write_to_ram =>
				--! write value to ram
				o_RAMWEImportance<= '1';
				o_RAMAddrImportance <= local_ram_address_if;
				o_RAMDataImportance <= ram_data;
				local_ram_address_if <= local_ram_address_if + 1;
				state <= wait_after_write;
				
				
			when wait_after_write =>
				-- wait
				o_RAMWEImportance<= '0';
				state <= wait_after_write_2;
				
				
			when wait_after_write_2 =>
				-- wait 
				state <= wait_after_write_3;


			when wait_after_write_3 =>
				-- wait
				state <= load_read_decision;
				
				
			when load_observation_data_decision =>
				--! first step of calculation of observation address
				observation_offset <= number_of_calculations - remaining_observations;
 				state <= load_observation_data_decision_2;
				
			when load_observation_data_decision_2 =>
				--! wait
				state <= load_observation_data_decision_3;
				
			when load_observation_data_decision_3 =>
				--! decide, if there is another observation to be handled, else post semaphore
				local_ram_address    <= local_ram_start_address + observation_size;
				local_ram_address_if <=	observation_address;
				number_of_bursts     <= number_of_bursts_remember;
				number_of_reads      <= number_of_reads_remember;
				offset <= observation_offset * observation_size ;
				state <= load_observation_data_decision_4;			
				
				
			when load_observation_data_decision_4 =>
				--! wait
				state <= load_observation_data_decision_5;
				
				
			when load_observation_data_decision_5 =>
				--! decide, if there is another observation to be handled, else post semaphore
				load_address <= observation_array_address + offset;
				if (remaining_observations > 0) then
					state <= load_burst_decision;
				else
					--time_stop <= TO_INTEGER(SIGNED(i_timeBase));
					state <= send_message;
				end if;


			when likelihood =>
				--! start and run likelihood user process		 
				--init <= '0';
				--enable <= '1';
				observation_loaded <= '1';
				state <= likelihood_done;


			when likelihood_done =>
				--! wait until the likelihood user process is finished	 
				observation_loaded <= '0';
				--if (finished = '1') then
					enable <= '0';
					init   <= '1';
					state  <= write_likelihood;
					remaining_observations <= remaining_observations - 1;
				--end if;


			when write_likelihood => 			 
				--! write likelihood value into the particle array
				reconos_write(done, o_osif, i_osif, particle_array_address, 
					STD_LOGIC_VECTOR(TO_SIGNED(likelihood_value, C_OSIF_DATA_WIDTH)));
				if done and success then
					particle_array_address <= particle_array_address + particle_size;
					state <= load_observation_data_decision;
				end if;						
						
						
			when send_message =>
				--! post semaphore (importance is finished)
				reconos_mbox_put(done, success, o_osif, i_osif, C_MB_DONE, 
					STD_LOGIC_VECTOR(TO_SIGNED(message, C_OSIF_DATA_WIDTH)));
				if done and success then
					enable <= '0';
					init <= '1';
					observation_loaded <= '0';
					state <= send_measurement_1;
				end if;	


			when send_measurement_1 =>
				--! sends time measurement to message box
				--  send only, if time start < time stop. Else ignore this measurement
				--if (time_start < time_stop) then
					--time_measurement <= time_stop - time_start;
					--state <= send_measurement_2;
				--else
				state <= wait_for_message;
				--end if;


--			when send_measurement_2 =>
--				--! sends time measurement to message box
--				--  send message
--				reconos_mbox_put(done, success, o_osif, i_osif, C_MB_MEASUREMENT, 
--					STD_LOGIC_VECTOR(TO_SIGNED(time_measurement, C_OSIF_DATA_WIDTH)));
--				if (done and success) then
--					state <= wait_for_message;				 
--				end if;					
						

			when others =>
				state <= wait_for_message;
 			end case;		  
		  	  
		end if;
	end if;
end process;
   
end Behavioral;
