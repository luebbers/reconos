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
--                                                                            -- --                                                                            --
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


entity observation is

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
	 
		-- CHANGE 1 OF 7
		-- time base
		--i_timeBase : in std_logic_vector( 0 to C_OSIF_DATA_WIDTH-1 )
		-- END CHANGE
	);
end observation;


architecture Behavioral of observation is

	component uf_extract_observation is
 		Port( 
			clk    : in  std_logic;
			reset  : in  std_logic;

			-- burst ram interface
			o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
			o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
			i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
			o_RAMWE   : out std_logic;
			o_RAMClk  : out std_logic;

			-- init signal
			init                         : in std_logic;
			-- enable signal
			enable                       : in std_logic;	
			-- parameters loaded
			parameter_loaded             : in std_logic; 
			parameter_loaded_ack         : out std_logic; 	 
			-- new particle loaded
			new_particle                 : in std_logic; 
			new_particle_ack             : out std_logic; 
			-- input data address
			input_data_address           : in std_logic_vector(0 to 31);
			input_data_needed            : out std_logic; 
			-- get word data
			word_data_en                 : in std_logic;
			word_address                 : out std_logic_vector(0 to 31);  
			word_data                    : in std_logic_vector(0 to 31);   
			word_data_ack                : out std_logic;
			-- if the observation is calculated, this signal has to be set to '1'
			finished	                    : out std_logic
		);
	end component;
	
--	  -------------------------------------------------------------------
--  --
--  --  ICON core component declaration
--  --
--  -------------------------------------------------------------------
--  component icon
--    port
--    (
--      control0    :   out std_logic_vector(35 downto 0)
--    );
--  end component;
--  
--	-------------------------------------------------------------------
--	--
--	--  ILA core component declaration
--	--
--	-------------------------------------------------------------------
--	component ila
--	port
--	(
--		control     : in    std_logic_vector(35 downto 0);
--		clk         : in    std_logic;
--		data        : in    std_logic_vector(31 downto 0);
--		trig0       : in    std_logic_vector(31 downto 0)
--	);
--	end component;


	attribute keep_hierarchy               : string;
	attribute keep_hierarchy of Behavioral : architecture is "true";

	-- ReconOS thread-local mailbox handles
	constant C_MB_START : std_logic_vector(0 to 31) := X"00000000";
	constant C_MB_DONE  : std_logic_vector(0 to 31) := X"00000001";
	constant C_MB_MEASUREMENT  : std_logic_vector(0 to 31) := X"00000002";

	-- states
	type t_state is (initialize, read_particle_address, read_number_of_particles,
		read_particle_size, read_block_size, read_observation_size,
		needed_bursts, needed_bursts_2, calculate_last_burst_length,
		calculate_last_burst_length_2, read_observation_address,
		read_input_data_link_address, read_parameter_size,
		read_parameter_address, copy_parameter,
		copy_parameter_2, copy_parameter_3,
		copy_parameter_ack, wait_for_message, 
		calculate_remaining_observations_1, calculate_remaining_observations_2,
		calculate_remaining_observations_3, calculate_remaining_observations_4,
		calculate_remaining_observations_5, calculate_remaining_observations_6,
		calculate_remaining_observations_7, calculate_remaining_observations_8,	
		calculate_remaining_observations_9, 
		read_input_data_address, read_next_particle, read_next_particle_2,
		read_next_particle_3, read_next_particle_4, read_next_particle_5,
		read_next_particle_6, read_next_particle_7,
		start_extract_observation, start_extract_observation_wait,
		extract_observation,
		get_input_data, cache_hit, cache_miss, cache_miss_2,
		cache_miss_3, cache_miss_4, cache_miss_5, cache_miss_6, 
		cache_miss_7, cache_miss_8,
		load_word, load_word_2, 
		write_word_back, write_word_ack,
		write_observation, write_observation_2, 
		write_observation_3, write_observation_4, 
		write_observation_5, write_observation_6,
		more_particles, more_particles_2, send_message, 
		send_measurement_1, send_measurement_2 );

	-- current state
	signal state : t_state := initialize;

	-- particle array
	signal particle_array_start_address:std_logic_vector(0 to C_OSIF_DATA_WIDTH-1):="00010000000000000000000000000000";
	signal particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- observation array
	signal observation_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal observation_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- load address, either reference data address or an observation array address
	signal load_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- local RAM address  
	signal local_ram_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal local_ram_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	--local RAM cache addresses
	signal local_ram_cache_address:std_logic_vector(0 to C_OSIF_DATA_WIDTH-1):="00000000000000000001111110000000";	 
	signal current_local_ram_cache_address:std_logic_vector(0 to C_OSIF_DATA_WIDTH-1):=(others => '0');
	signal local_ram_cache_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := "111111100000";	 
	signal current_local_ram_cache_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');	 
	signal cache_min : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal cache_max : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- local RAM data
	signal ram_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- information struct containing array addresses and other information like observation size
	signal information_struct : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- lin/pointer to memory word, where the input address is stored 
	signal input_data_link_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
	-- number of observations
	signal remaining_observations : integer := 2;

	-- number of needed bursts
	signal number_of_bursts : integer := 3;
	
	-- number of reads
	signal number_of_reads : integer := 0;
	
	-- read counter 
	signal read_counter : integer := 0;

	-- number of needed bursts to be remembered
	signal number_of_bursts_remember : integer := 3; 

	-- length of last burst
	signal length_of_last_burst : integer := 7;

	-- size of a particle
	signal particle_size : integer := 32;

	-- number of particles
	signal N : integer := 20;

	-- size of a observation
	signal observation_size : integer := 40;

	-- temporary integer signals
	signal temp  : integer := 0;
	signal temp2 : integer := 0;
	signal temp3 : integer := 0;
	signal temp4 : integer := 0; 
	signal cache_offset : integer := 0;  

	-- local ram address for interface
	signal local_ram_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal local_ram_start_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	-- number of particles in a particle block
	signal block_size : integer := 2;

	-- current particle data
	signal particle_data : integer := 0;

	--  parameter address
	signal parameter_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 

	-- parameter size
	signal parameter_size : integer := 0;

	-- parameter loaded
	signal parameter_loaded : std_logic := '0';  

	-- parameters acknowledged by user process
	signal parameter_loaded_ack : std_logic; -- := '0';

	-- message m, m stands for the m-th number of particle block
	signal message : integer := 1;

	-- message2 is message minus one
	signal message2 : integer := 0;

	-- offset for observation array
	signal observation_offset : integer := 0;

	-- time values for start, stop and the difference of both
	signal time_start       : integer := 0;
	signal time_stop        : integer := 0;
	signal time_measurement : integer := 0;
	
	signal counter : integer := 0;

	-----------------------------------------------------------
	-- NEEDED FOR USER ENTITY INSTANCE
	-----------------------------------------------------------
	-- for likelihood user process
	-- init
	signal init                         : std_logic := '1';
	-- enable
	signal enable                       : std_logic := '0';
	-- new particle loaded
	signal new_particle                 : std_logic := '0';  
	-- new particle loaded - ackowledgement
	signal new_particle_ack             : std_logic := '1';  
	-- input data address
 	signal input_data_address  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	-- input data needed signal
	signal input_data_needed : std_logic := '0';  
	-- word data enable
	signal word_data_en : std_logic := '0';
	-- word data address
	signal word_data : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
	-- word address
	signal word_address :  std_logic_vector(0 to 31) := (others => '0');
	-- word_ack
	signal word_data_ack : std_logic := '0';
	-- if the observation is extracted, this signal is set to '1'
	signal finished     :  std_logic := '1';

	--current address
	signal current_address  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

	-- for switch 1: corrected local ram address. the least bit is inverted,
	--  because else the local ram will be used incorrect
	signal o_RAMAddrExtractObservation : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	-- for switch 1:corrected local ram address for this observation thread
	signal o_RAMAddrObservation : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	-- for switch 2: Write enable, user process
	signal o_RAMWEExtractObservation  : std_logic := '0';
	-- for switch 2: Write enable, observation
	signal o_RAMWEObservation : std_logic := '0';

	-- for switch 3: output ram data, user process
	signal o_RAMDataExtractObservation : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
	-- for switch 3: output ram data, observation
	signal o_RAMDataObservation : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');


--  -------------------------------------------------------------------
--  --
--  --  ICON core signal declarations
--  --
--  -------------------------------------------------------------------
--  signal control0       : std_logic_vector(35 downto 0);
--
--
--  -------------------------------------------------------------------
--  --
--  --  ILA core signal declarations
--  --
--  -------------------------------------------------------------------
--  signal data       : std_logic_vector(31 downto 0);
  signal trig0      : std_logic_vector(31 downto 0);


begin


 
--	-------------------------------------------------------------------
--	--
--	--  ICON core instance
--	--
--	-------------------------------------------------------------------
--	i_icon : icon
--		port map
--		(
--			control0    => control0
--		);
--	 
--
--	-------------------------------------------------------------------
--	--
--	--  ILA core instance
--	--
--	-------------------------------------------------------------------
--	i_ila : ila
--	port map
--	(
--		control   => control0,
--		clk       => clk,
--		data      => data,
--		trig0     => trig0
--	);	 
--	 
--	 data <= trig0;

	-------------------------------------------------------------------
	--
	--  User Process
	--
	-------------------------------------------------------------------
	user_process : uf_extract_observation
		port map (reset=>reset, clk=>clk, o_RAMAddr=>o_RAMAddrExtractObservation,
			o_RAMData=>o_RAMDataExtractObservation, i_RAMData=>i_RAMData, 
			o_RAMWE=>o_RAMWEExtractObservation, o_RAMClk=>o_RAMClk,
			parameter_loaded=>parameter_loaded, parameter_loaded_ack=>parameter_loaded_ack,
			new_particle=>new_particle, new_particle_ack=>new_particle_ack, 
			input_data_address=>input_data_address, input_data_needed=>input_data_needed,
			word_data_en=>word_data_en, word_address=>word_address, 
 			word_data=>word_data, word_data_ack=>word_data_ack, 					
			init=>init, enable=>enable, 
			finished=>finished);


	-- switch 1: address, correction is needed to avoid wrong addressing
	o_RAMAddr <= o_RAMAddrExtractObservation(0 to C_BURST_AWIDTH-2) & not o_RAMAddrExtractObservation(C_BURST_AWIDTH-1)
 	when enable = '1' else o_RAMAddrObservation(0 to C_BURST_AWIDTH-2) & not o_RAMAddrObservation(C_BURST_AWIDTH-1);

	-- switch 2: write enable
	o_RAMWE <= o_RAMWEExtractObservation when enable = '1' else o_RAMWEObservation;

	-- switch 3: output ram data
	o_RAMData <= o_RAMDataExtractObservation when enable = '1' else o_RAMDataObservation;


-----------------------------------------------------------------------------
--
--  ReconOS State Machine for Observation: 
--  
-----------------------------------------------------------------------------
--  
--  (1) read data from information struct
--  
--  (2) receive message m
--  
--  (3) set current address for input data
--  
--  (4) load current particle (into local ram, starting address (others=>'0'))
--  
--  (5) start user process for observation extraction
--  
--  (6) wait for finished signal of user process
--  
--  (7) write observation into main memory (from local ram, starting address (others=>'0'))
--  
--  (8) if more particle need to be processed
--          go to step 4
--      else
--          go to step 9
--
--  (9) send message m
--
--  (9*) send measurement  
--  
------------------------------------------------------------------------------
state_proc : process(clk, reset)
    
	-- done signal for Reconos methods
	variable done : boolean;

	-- success signal for Reconos method, which gets a message box
	variable success : boolean;
	 
	-- signals for particle_size and observation size
	variable N_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	variable particle_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	
	variable observation_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	variable block_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	variable parameter_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	variable message_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 
begin
	if reset = '1' then
		reconos_reset(o_osif, i_osif);
		state <= initialize;
	elsif rising_edge(clk) then
		reconos_begin(o_osif, i_osif);
 		if reconos_ready(i_osif) then
			case (state) is

			when initialize =>
				--! init state, receive information struct
				trig0 <= X"00000000";
				reconos_get_init_data_s (done, o_osif, i_osif, information_struct);
				if done then 
					enable <= '0';
					local_ram_address    <= (others => '0');
					local_ram_address_if <= (others => '0');
					init <= '1';
					new_particle <= '0';
					-- CHANGE CHANGE CHANGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					state <= read_particle_address;
					--state <= wait_for_message;
					-- END OF CHANGE CHANGE CHANGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					-- CHANGE 2 OF 7!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					--state <= needed_bursts;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
					-- END CHANGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				end if;

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 1: READ INFORMATION_STRUCT 
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			


			when read_particle_address =>
				trig0 <= X"00000001";
				--! read particle array address
				reconos_read_s (done, o_osif, i_osif, information_struct, particle_array_start_address);
				if done then
					state <= read_number_of_particles;
 				end if;

			when read_number_of_particles =>
				trig0 <= X"00000002";
  				--! read number of particles N
				reconos_read (done, o_osif, i_osif, information_struct+4, N_var);
				if done then
					N <= TO_INTEGER(SIGNED(N_var));
					state <= read_particle_size;
				end if;	           
						
			when read_particle_size =>
				trig0 <= X"00000003";
				--! read particle size
				reconos_read (done, o_osif, i_osif, information_struct+8, particle_size_var);
				if done then
					particle_size <= TO_INTEGER(SIGNED(particle_size_var));
					state <= read_block_size;
				end if;
	
			when read_block_size =>
				trig0 <= X"00000004";
				--! read particle size
				reconos_read (done, o_osif, i_osif, information_struct+12, block_size_var);
				if done then
					block_size <= TO_INTEGER(SIGNED(block_size_var));
					state <= read_observation_size;
				end if;
		
			when read_observation_size =>
				trig0 <= X"00000005";
				--! read observation size
				reconos_read (done, o_osif, i_osif, information_struct+16, observation_size_var);
				if done then
  					observation_size <= TO_INTEGER(SIGNED(observation_size_var));
					state <= needed_bursts;
				end if;	
	
			when needed_bursts =>
				trig0 <= X"00000006";
				--! calculate needed bursts
				--number_of_bursts_remember <= observation_size / 128;
				state <= calculate_last_burst_length;

			when calculate_last_burst_length =>
				trig0 <= X"00000007";
				--! calculate number of reads (1 of 2)
				--length_of_last_burst <= observation_size mod 128;            
				state <= calculate_last_burst_length_2;

			when calculate_last_burst_length_2 =>
				trig0 <= X"00000008";
				--! calculate number of reads (2 of 2)
				--length_of_last_burst <= length_of_last_burst / 8;
				number_of_reads <= observation_size / 4;
				state <= read_observation_address;
				-- CHANGE 3 OF 7
				--state <= wait_for_message;
				-- END CHANGE					 

			when read_observation_address =>
				trig0 <= X"00000009";
				--! read observation array address
				reconos_read_s (done,o_osif,i_osif,information_struct+20,observation_array_start_address);
				if done then
					state <= read_input_data_link_address;
				end if;

			when read_input_data_link_address =>
				trig0 <= X"0000000A";
				--! read observation array address
				reconos_read_s (done, o_osif, i_osif, information_struct+24, input_data_link_address);
				if done then
					--state <= wait_for_message;
					state <= read_parameter_size;
				end if;

			when read_parameter_size =>
				trig0 <= X"0000000B";
				--! read parameter size
				reconos_read (done, o_osif, i_osif, information_struct+28, parameter_size_var);
				if done then
					parameter_size <= TO_INTEGER(SIGNED(parameter_size_var));
					state <= read_parameter_address;
				end if;
				
				
			when read_parameter_address =>
				trig0 <= X"0000000C";
				--! read parameter size
				reconos_read_s (done, o_osif, i_osif, information_struct+32, parameter_address);
				if done then
					state <= copy_parameter;
					local_ram_address_if <= local_ram_start_address_if;
				end if;			


		
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 1: READ PARAMETERS 
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


			when copy_parameter =>
				trig0 <= X"0000000D";
				--! read parameter size
				o_RAMWEObservation <= '0';
				if (parameter_size > 0) then
					parameter_size <= parameter_size - 1;
					state          <= copy_parameter_2;
				else
					state            <= copy_parameter_ack;
					parameter_loaded <= '1';
					enable           <= '1';
					init             <= '0';
				end if;

			when copy_parameter_2 =>
				trig0 <= X"0000000E";
				--! read parameter size
				reconos_read_s (done, o_osif, i_osif, parameter_address, ram_data);
				if done then
					state <= copy_parameter_3;
				end if;	

			when copy_parameter_3 =>
				trig0 <= X"0000000F";
				--! read parameter size
				parameter_address    <= parameter_address + 4;
				local_ram_address_if <= local_ram_address_if + 1;
				enable               <= '0';
				o_RAMWEObservation   <= '1';
				o_RAMAddrObservation <= local_ram_address_if;
				o_RAMDataObservation <= ram_data;
				state <= copy_parameter;	

			when copy_parameter_ack =>
				trig0 <= X"00000010";
				--! read parameter size
				if (parameter_loaded_ack = '1') then
					enable <= '0';
					init   <= '1';
					parameter_loaded <= '0';
					state  <= wait_for_message;	
				end if;						


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 2: WAIT FOR MESSAGE
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------				

			when wait_for_message =>
				trig0 <= X"00000011";
				--! wait for semaphore to start resampling
				reconos_mbox_get(done, success, o_osif, i_osif, C_MB_START, message_var);
				if done and success then
					message <= TO_INTEGER(SIGNED(message_var));
					-- init signals
					local_ram_address      <= (others => '0');
					local_ram_address_if   <= (others => '0');
					enable     <= '0';
					init       <= '1';
					--time_start <= TO_INTEGER(SIGNED(i_timebase));
					--N <= 100; -- TODO: ONLY FOR SIMULATION
					--number_of_reads <= 130; -- TODO: ONLY FOR SIMULATION
					--block_size <= 10; -- TODO: ONLY FOR SIMULATION
					--particle_size <= 32; -- TODO: ONLY FOR SIMULATION
					--observation_size <= 520; -- TODO: ONLY FOR SIMULATION
					--particle_array_start_address <= X"10000000"; -- TODO: ONLY FOR SIMULATION
					--observation_array_start_address <= X"20000000"; -- TODO: ONLY FOR SIMULATION
					state      <= calculate_remaining_observations_1;
				end if;

			when calculate_remaining_observations_1 =>
				trig0 <= X"00000012";
  				--! calculates particle array address and number of particles to sample
				message2 <= message-1;
				state <= calculate_remaining_observations_2;

			when calculate_remaining_observations_2 =>
				trig0 <= X"00000013";
				--! calculates particle array address and number of particles to sample
				temp <= message2 * block_size;
				state <= calculate_remaining_observations_3;
				
			when calculate_remaining_observations_3 =>
				trig0 <= X"00000014";
				--! wait
				state <= calculate_remaining_observations_4;			

			when calculate_remaining_observations_4 =>
				trig0 <= X"00000015";
				--! calculates particle array address and number of particles to sample
				temp2 <= temp * particle_size;
				state <= calculate_remaining_observations_5;	
				
			when calculate_remaining_observations_5 =>
				trig0 <= X"00000016";
				--! wait
				state <= calculate_remaining_observations_6;	
				
			when calculate_remaining_observations_6 =>
				trig0 <= X"00000017";
				temp3 <= temp * observation_size;
				state <= calculate_remaining_observations_7;	
				
			when calculate_remaining_observations_7 =>
				trig0 <= X"00000018";
				--! wait
				state <= calculate_remaining_observations_8;	
	
			when calculate_remaining_observations_8 =>
				trig0 <= X"00000019";
				--! calculates particle array address and number of particles to sample
				particle_array_address    <= particle_array_start_address    + temp2;
				observation_array_address <= observation_array_start_address + temp3;
 				remaining_observations    <= N - temp;
				state <= calculate_remaining_observations_9;	

			when calculate_remaining_observations_9 =>
				trig0 <= X"0000001A";
				--! calculates particle array address and number of particles to sample
				if (remaining_observations > block_size) then
					remaining_observations <= block_size;
				end if;
				state <= read_input_data_address;					


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 3: READ CURRENT INPUT DATA ADDRESS
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


			when read_input_data_address =>
				trig0 <= X"0000001B";
				--! read reference data address
				reconos_read_s (done, o_osif, i_osif, input_data_link_address, input_data_address);
				if done then
					current_local_ram_cache_address <= (others=>'0');
					current_local_ram_cache_address_if <= (others=>'0');
					state <= read_next_particle;
					-- TODO: CHANGE CHANGE CHANGE
					--state <= read_next_particle_2;					
				end if;
  				-- CHANGE 5 of 7
				-- input data address: 0x20000000
				--input_data_address     <=    "00100000000000000000000000000000";
				-- the particle array address: 0x10000000            
				--particle_array_address <=    "00010000000000000000000000000000";
				-- the observation array address: 0x11000000
				--observation_array_address <= "00010001000000000000000000000000";
				--state <= read_next_particle;
				-- END CHANGE

	
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 4: WRITE PARTICLE INTO CURRENT RAM
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	


			when read_next_particle =>
				trig0 <= X"0000001C";
				--! read next particle to local ram (writing the first 128 bytes to the local ram)
    				-- CHANGE CHANGE CHANGE
				--reconos_read_burst(done,o_osif,i_osif,local_ram_start_address,particle_array_address);
 				--if done then
					--particle_array_address  <= particle_array_address + particle_size;
					-- CHANGE CHANGE CHANGE
					--state <= start_extract_observation;
					local_ram_address_if <= (others => '0');
					read_counter <= particle_size / 4;
					state <= read_next_particle_2;
					--state <= write_observation;
					-- END OF CHANGE CHANGE CHANGE
				--end if;
				-- END OF CHANGE CHANGE CHANGE
				
			when read_next_particle_2 =>	
				trig0 <= X"0000001D";			
				--! checks, if more reads are needed
				if (read_counter >  0) then
					read_counter <= read_counter - 1;
					state <= read_next_particle_3;
				else
					-- no more reads: start user process
					--particle_array_address  <= particle_array_address + particle_size;
					state <= start_extract_observation;
					-- CHANGE CHANGE CHANGE - TODO REMOVE
					--state <= write_observation;
					--state <= send_message;
					--state <= more_particles;
				end if;
				
			when read_next_particle_3 =>	
				trig0 <= X"0000001E";			
				--! read 4 bytes
				reconos_read_s(done, o_osif, i_osif, particle_array_address, ram_data);
				if done then
    					state <= read_next_particle_4;
				end if;
				
			when read_next_particle_4 =>
				trig0 <= X"0000001F";
				--! wait							
    			state <= read_next_particle_5;	
				
			when read_next_particle_5 =>	
				trig0 <= X"00000020";
				--! write 4 bytes	to local ram		
				o_RAMWEObservation <= '1';
				o_RAMAddrObservation <= local_ram_address_if;
				o_RAMDataObservation <= ram_data;
    			state <= read_next_particle_6;

			when read_next_particle_6 =>	
				trig0 <= X"00000021";			
				--! wait			
				o_RAMWEObservation <= '0';
				particle_array_address <= particle_array_address + 4;
				local_ram_address_if <= local_ram_address_if + 1;
    			state <= read_next_particle_7;				
				
			when read_next_particle_7 =>		
				trig0 <= X"00000022";			
				--! wait							
    			state <= read_next_particle_2;			


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
----				
----        STEP 5: START OBSERVATION EXTRACTION
----
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------			


			when start_extract_observation =>
				trig0 <= X"00000023";
				--! start the user process 
				init <= '0';
				enable <= '1';
				new_particle <= '1';
				state <= start_extract_observation_wait;

			when start_extract_observation_wait =>
				trig0 <= X"00000024";
				--! user process needs to start the execution
				-- CHANGE CHANGE CHANGE
				if new_particle_ack = '1' then 
					new_particle <= '0';
					state <= extract_observation;
				end if;
				-- END OF CHANGE CHANGE CHANGE

	
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 6: WAIT FOR OBSERVATION EXTRACTION TO FINISH / ANSWER DATA CALLS INBETWEEN
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	


			when extract_observation =>
				trig0 <= X"00000025";			
				--! check if observation is finished, or it input data is needed (from cache)
				if finished = '1' then
					-- observation finished
					enable <= '0';
					init   <= '1';
					new_particle <= '0';
					state  <= write_observation;
				elsif input_data_needed = '1' then
				     
					state  <= get_input_data;				
				end if;

			when get_input_data =>
				trig0 <= X"00000026";			
				--! get input data at word_address (and write it into word_data)
				--enable <= '0';
				--cache_offset  <= 0;
				--if (cache_min <= word_address) and (word_address < cache_max) then
				--	-- cache hit
				--	state <= cache_hit;
				--	--current_address <= cache_min;
				--	current_address  <= word_address - cache_min;
				--else
				--	-- cache miss
					state <= cache_miss;
				--end if;

--			when cache_hit =>
--				trig0 <= X"00000027";
--				--! calculate the correct position in the local ram
--				cache_offset <= TO_INTEGER(UNSIGNED(current_address)) / 4;
--				state <= load_word;				
--
--			when cache_miss =>
--				trig0 <= X"00000028";
-- 				--! check if word address is double aligned        			
--				if (word_address(29) = '0') then
--					-- word address is double-word aligned (needed for read bursts)
--					cache_min <= word_address;
--					cache_max <= word_address + 128;
--					cache_offset <= 0;
--				else
--					-- word address is NOT double-word aligned => cache_min has to be adjusted
--					cache_min <= word_address - 4;
--					cache_max <= word_address + 124;
--					cache_offset <= 1;
--				end if;
--				state <= cache_miss_2;
--				-- TODO: CHANGE CHANGE CHANGE
--				--cache_min <= word_address;
--				--cache_max <= word_address + 128;
--				--cache_offset <= 0;
--				--current_local_ram_cache_address <= word_address;
--				--current_local_ram_cache_address_if <= local_ram_cache_address_if;	
--				--read_counter <= 0;
--				--state <= cache_miss_3;
--				
--
--			when cache_miss_2 =>	
--				trig0 <= X"00000029";		
--				--! reads 128 byte input burst into local ram cache
--				reconos_read_burst(done, o_osif, i_osif, local_ram_cache_address, cache_min);
--				if done then
--    					state <= load_word;
--				end if;
--				
--			when cache_miss_3 =>		
--				trig0 <= X"0000002A";	
--				--! checks, if more reads are needed
--				if (read_counter <  31) then
--					read_counter <= read_counter + 1;
--					state <= cache_miss_4;
--				else
--					state <= load_word;
--				end if;
--				
--			when cache_miss_4 =>	
--				trig0 <= X"0000002B";		
--				--! read 4 bytes			
--				reconos_read_s(done, o_osif, i_osif, current_local_ram_cache_address, ram_data);
--				if done then
--    					state <= cache_miss_5;
--				end if;
--				
--			when cache_miss_5 =>	
--				trig0 <= X"0000002C";		
--				--! wait
--    			state <= cache_miss_6;				
--				
--			when cache_miss_6 =>		
--				trig0 <= X"0000002D";	
--				--! write 4 bytes	to local ram		
--				o_RAMWEObservation <= '1';
--				o_RAMAddrObservation <= current_local_ram_cache_address_if;
--				o_RAMDataObservation <= ram_data;
--    			state <= cache_miss_7;
--
--			when cache_miss_7 =>		
--				trig0 <= X"0000002E";	
--				--! wait			
--				o_RAMWEObservation <= '0';
--				current_local_ram_cache_address <= current_local_ram_cache_address + 4;
--				current_local_ram_cache_address_if <= current_local_ram_cache_address_if + 1;
--    			state <= cache_miss_8;				
--				
--			when cache_miss_8 =>	
--				trig0 <= X"0000002F";		
--				--! wait							
--    			state <= cache_miss_3;				
--		 
--			when load_word =>
--				trig0 <= X"00000030";
--				--! load word data
--				o_RAMAddrObservation <= local_ram_cache_address_if + cache_offset;
--				state <= load_word_2;		
--
--			when load_word_2 =>
--				trig0 <= X"00000031";
--				--! load word data (wait one cycle)
----				state <= load_word_3;		
----
----			when load_word_3 =>
----				trig0 <= X"00000032";
----				--! load word data (get word)
----				word_data <= i_RAMData;
--				state <= write_word_back;


			when cache_miss =>
				--! wait
				state <= cache_miss_2;

			when cache_miss_2 =>
				reconos_read_s(done, o_osif, i_osif, word_address, word_data);
				if done then
    					state <= cache_miss_3;
				end if;

			when cache_miss_3 =>
				--! wait
				state <= cache_miss_4;
				
			when cache_miss_4 =>
				--! wait
				state <= write_word_back;
				

			when write_word_back =>
				trig0 <= X"00000033";
				--! activate user process and transfer the word
				enable <= '1';
				word_data_en <= '1';
				--word_data <= i_RAMData;
				state  <= write_word_ack;

			when write_word_ack =>
				trig0 <= X"00000034";
				--! wait for acknowledgement
				-- TODO CHANGE CHANGE CHANGE - BACK
				--if word_data_ack = '1' then	  
					word_data_en <= '0';
					state <= extract_observation;
				--end if;
			  

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 7: WRITE OBSERVATION TO MAIN MEMORY
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			

			when write_observation => 
				trig0 <= X"00000035";
				--! init write process
				counter <= 0;
				local_ram_address_if <= (others=>'0');
				state <= write_observation_2;
				
			when write_observation_2 => 
				trig0 <= X"00000036";
				--! more writing to do?
				if (counter < number_of_reads) then
					counter <= counter + 1;
					state <= write_observation_3;
				else
					-- writing finished
					state <= more_particles;
					-- TODO: CHANGE CHANGE CHANGE: REMOVE
					--state <= send_message;
				end if;
				
			when write_observation_3 => 
				trig0 <= X"00000037";
				--! get local ram data
				o_RAMAddrObservation <= local_ram_address_if;
				state <= write_observation_4;
				
			when write_observation_4 => 
				trig0 <= X"00000038";
				--! wait (needed to receive local ram data -> offset)
				state <= write_observation_5;
				
			when write_observation_5 =>
				trig0 <= X"00000039";			
				--! write
				reconos_write(done, o_osif, i_osif, observation_array_address, i_RAMData);
				if done then
					observation_array_address  <= observation_array_address  + 4;
					local_ram_address_if       <= local_ram_address_if       + 1;
					state <= write_observation_6;
				end if;
				
			when write_observation_6 => 
				trig0 <= X"0000003A";
				--! wait				
				state <= write_observation_2;

----			when write_observation => 			 
----				--! write observation (init)
----				number_of_bursts  <= number_of_bursts_remember;
----				local_ram_address <= local_ram_start_address;
----				--write_histo_en <= '1';
----				state <= write_observation_2;
----
----			when write_observation_2 => 			 
----				--! write observation (check burst number)
----				if number_of_bursts > 0 then
----					-- more full bursts needed
----					state <= write_observation_3;
----					number_of_bursts <= number_of_bursts - 1;
----				elsif length_of_last_burst > 0 then
----					-- last burst needed (not full)
----					temp4 <= length_of_last_burst * 8;
----					state <= write_observation_4;			 
----				else
----					-- no last burst needed (which is not full)
----					state <= more_particles;
----				end if;
----
----			when write_observation_3 => 			 
----				--! write observation (write bursts)
----				reconos_write_burst(done, o_osif, i_osif, local_ram_address, observation_array_address);
----				if done then
----					observation_array_address  <= observation_array_address  + 128;
----					local_ram_address          <= local_ram_address          + 128;
----					state <= write_observation_2;
----				end if;
----
----			when write_observation_4 => 			 
----				--! write observation (write last burst)
----				reconos_write_burst_l(done,o_osif,i_osif,local_ram_address,
----					observation_array_address, length_of_last_burst);
----				if done then
----					observation_array_address  <= observation_array_address  + temp4;
----					local_ram_address    <= local_ram_address    + temp4;
----					state <= more_particles;
----				end if;	


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 8: MORE PARTICLES?
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

			when more_particles =>
				trig0 <= X"0000003B";
				--! check if more particles need an observation
				remaining_observations <= remaining_observations - 1;
				state <= more_particles_2;

			when more_particles_2 =>
				trig0 <= X"0000003C";
				--! check if more particles need an observation
				if (remaining_observations > 0) then
 					state <= read_next_particle;
				else
					--time_stop <= TO_INTEGER(SIGNED(i_timeBase));
					state <= send_message;
				end if;
					
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 9: SEND MESSAGE
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			

								
			when send_message =>
				trig0 <= X"0000003D";
				--! post semaphore (importance is finished)
				reconos_mbox_put(done, success, o_osif, i_osif, C_MB_DONE, 
					--input_data_address);
					STD_LOGIC_VECTOR(TO_SIGNED(message, C_OSIF_DATA_WIDTH)));
				if done and success then
					enable <= '0';
					init <= '1';
					--state <= send_measurement_1;
					state <= wait_for_message;
				end if;	


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 9*: SEND MEASURMENT 
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			


--			when send_measurement_1 =>
--				trig0 <= X"00000000";
--				--! sends time measurement to message box
--				--  send only, if time start < time stop. Else ignore this measurement
--				--if (time_start < time_stop) then
--					--time_measurement <= time_stop - time_start;
--					--state <= send_measurement_2;
--				--else
--					state <= wait_for_message;
--				--end if;
--
--			when send_measurement_2 =>
--				trig0 <= X"00000000";
--				--! sends time measurement to message box
--				--reconos_mbox_put(done, success, o_osif, i_osif, C_MB_MEASUREMENT, 
--					--STD_LOGIC_VECTOR(TO_SIGNED(time_measurement, C_OSIF_DATA_WIDTH)));
--				--if (done and success) then
--				state <= wait_for_message;				 
--				--end if;					

			when others =>
				trig0 <= X"00000000";
				state <= wait_for_message;
			end case;		  
		  	  
		end if;
	end if;
end process;

end Behavioral;
