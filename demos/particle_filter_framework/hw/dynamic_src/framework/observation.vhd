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
	finished         : out std_logic
	);
  end component;


  attribute keep_hierarchy               : string;
  attribute keep_hierarchy of Behavioral : architecture is "true";

  -- ReconOS thread-local mailbox handles
  constant C_MB_START : std_logic_vector(0 to 31) := X"00000000";
  constant C_MB_DONE  : std_logic_vector(0 to 31) := X"00000001";
  constant C_MB_MEASUREMENT  : std_logic_vector(0 to 31) := X"00000002";
  constant C_MB_EXIT         : std_logic_vector(0 to 31) := X"00000003";
  
  -- states
  type state_t is (
	STATE_CHECK,
	STATE_INIT, 
	STATE_READ_PARTICLE_ADDRESS, 
	STATE_READ_NUMBER_OF_PARTICLES,
        STATE_READ_PARTICLE_SIZE, 
	STATE_READ_BLOCK_SIZE, 
	STATE_READ_OBSERVATION_SIZE,
	STATE_NEEDED_BURSTS, 
	STATE_NEEDED_BURSTS_2, 
	STATE_LENGTH_LAST_BURST,
	STATE_LENGTH_LAST_BURST_2, 
	STATE_READ_OBSERVATION_ARRAY_ADDRESS,
	STATE_READ_INPUT_DATA_LINK_ADDRESS, 
	STATE_READ_PARAMETER_SIZE,
	STATE_READ_PARAMETER_ADDRESS, 
	STATE_COPY_PARAMETER,
	STATE_COPY_PARAMETER_2, 
	STATE_COPY_PARAMETER_3,
	STATE_COPY_PARAMETER_ACK, 
	STATE_WAIT_FOR_MESSAGE, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_1, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_2,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_3, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_4,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_5, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_6,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_7, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_8,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_9,
	STATE_READ_INPUT_DATA_ADDRESS, 
	STATE_READ_NEXT_PARTICLE,
	STATE_START_EXTRACT_OBSERVATION, 
	STATE_START_EXTRACT_OBSERVATION_WAIT,
	STATE_EXTRACT_OBSERVATION,
	STATE_GET_INPUT_DATA, 
	STATE_CACHE_HIT, 
	STATE_CACHE_MISS, 
	STATE_CACHE_MISS_2,
	STATE_LOAD_WORD, 
	STATE_LOAD_WORD_2, 
	STATE_WRITE_WORD_BACK, 
	STATE_WRITE_WORD_ACK,
	STATE_WRITE_OBSERVATION, 
	STATE_WRITE_OBSERVATION_2, 
	STATE_WRITE_OBSERVATION_3, 
	STATE_WRITE_OBSERVATION_4, 
	STATE_MORE_PARTICLES, 
	STATE_MORE_PARTICLES_2, 
	STATE_SEND_MESSAGE, 
	STATE_SEND_MEASUREMENT_1, 
	STATE_SEND_MEASUREMENT_2,
	STATE_EXIT  
	); -- 51 states = 0x00 - 0x32
type encode_t is array(state_t) of reconos_state_enc_t;
  type decode_t is array(natural range <>) of state_t;
  constant encode : encode_t :=  (X"00",
                                  X"01",
                                  X"02",
                                  X"03",
                                  X"04",
                                  X"05",
                                  X"06",
                                  X"07",
                                  X"08",
                                  X"09",
                                  X"0A",
                                  X"0B",
                                  X"0C",
                                  X"0D",
                                  X"0E",
                                  X"0F",
                                  X"10",
                                  X"11",
                                  X"12",
                                  X"13",
                                  X"14",
                                  X"15",
                                  X"16",
                                  X"17",
                                  X"18",
                                  X"19",
                                  X"1A",
                                  X"1B",
                                  X"1C",
                                  X"1D",
                                  X"1E",
                                  X"1F",
                                  X"20",
                                  X"21",
                                  X"22",
                                  X"23",
                                  X"24",
                                  X"25",
                                  X"26",
                                  X"27",
                                  X"28",
                                  X"29",
                                  X"2A",
                                  X"2B",
                                  X"2C",
                                  X"2D",
                                  X"2E",
                                  X"2F",
                                  X"30",
                                  X"31",
                                  X"32",
                                  X"33"
  );
  constant decode : decode_t := (
	STATE_CHECK,
	STATE_INIT, 
	STATE_READ_PARTICLE_ADDRESS, 
	STATE_READ_NUMBER_OF_PARTICLES,
        STATE_READ_PARTICLE_SIZE, 
	STATE_READ_BLOCK_SIZE, 
	STATE_READ_OBSERVATION_SIZE,
	STATE_NEEDED_BURSTS, 
	STATE_NEEDED_BURSTS_2, 
	STATE_LENGTH_LAST_BURST,
	STATE_LENGTH_LAST_BURST_2, 
	STATE_READ_OBSERVATION_ARRAY_ADDRESS,
	STATE_READ_INPUT_DATA_LINK_ADDRESS, 
	STATE_READ_PARAMETER_SIZE,
	STATE_READ_PARAMETER_ADDRESS, 
	STATE_COPY_PARAMETER,
	STATE_COPY_PARAMETER_2, 
	STATE_COPY_PARAMETER_3,
	STATE_COPY_PARAMETER_ACK, 
	STATE_WAIT_FOR_MESSAGE, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_1, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_2,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_3, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_4,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_5, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_6,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_7, 
	STATE_CALCULATE_REMAINING_OBSERVATIONS_8,
	STATE_CALCULATE_REMAINING_OBSERVATIONS_9,
	STATE_READ_INPUT_DATA_ADDRESS, 
	STATE_READ_NEXT_PARTICLE,
	STATE_START_EXTRACT_OBSERVATION, 
	STATE_START_EXTRACT_OBSERVATION_WAIT,
	STATE_EXTRACT_OBSERVATION,
	STATE_GET_INPUT_DATA, 
	STATE_CACHE_HIT, 
	STATE_CACHE_MISS, 
	STATE_CACHE_MISS_2,
	STATE_LOAD_WORD, 
	STATE_LOAD_WORD_2, 
	STATE_WRITE_WORD_BACK, 
	STATE_WRITE_WORD_ACK,
	STATE_WRITE_OBSERVATION, 
	STATE_WRITE_OBSERVATION_2, 
	STATE_WRITE_OBSERVATION_3, 
	STATE_WRITE_OBSERVATION_4, 
	STATE_MORE_PARTICLES, 
	STATE_MORE_PARTICLES_2, 
	STATE_SEND_MESSAGE, 
	STATE_SEND_MEASUREMENT_1, 
	STATE_SEND_MEASUREMENT_2,
	STATE_EXIT 
	);


  -- current state
  signal state : state_t := STATE_CHECK;
  
  -- particle array
  signal particle_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1); -- := "00010000000000000000000000000000";
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
  signal local_ram_cache_address    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := "00000000000000000001111110000000";	 
  signal local_ram_cache_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := "011111100000";	 
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
  --signal time_start       : integer := 0;
  --signal time_stop        : integer := 0;
  --signal time_measurement : integer := 0;
  
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
  

begin

  -- entity of user process
  user_process : uf_extract_observation
     port map (reset=>reset, clk=>clk, o_RAMAddr=>o_RAMAddrExtractObservation,
	            o_RAMData=>o_RAMDataExtractObservation, i_RAMData=>i_RAMData, 
					o_RAMWE=>o_RAMWEExtractObservation, o_RAMClk=>o_RAMClk,
					parameter_loaded=>parameter_loaded, parameter_loaded_ack=>parameter_loaded_ack,
					new_particle=>new_particle, new_particle_ack=>new_particle_ack, 
					input_data_address=>input_data_address, input_data_needed=>input_data_needed,
					word_data_en=>word_data_en, word_address=>word_address, 
               word_data=>word_data, word_data_ack=>word_data_ack, 					
	            init=>init, enable=>enable, finished=>finished);


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
  --  1) read data from information struct
  --  
  --  2) receive message m
  --  
  --  3) set current address for input data
  --  
  --  4) load current particle (into local ram, starting address (others=>'0'))
  --  
  --  5) start user process for observation extraction
  --  
  --  6) wait for finished signal of user process
  --  
  --  7) write observation into main memory (from local ram, starting address (others=>'0'))
  --  
  --  8) if more particle need to be processed
  --          go to step 4
  --     else
  --          go to step 9
  --
  --  9) send message m
  --
  --  9*) send measurement  
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
 	 variable resume_state_enc  : reconos_state_enc_t := (others => '0');
	 variable preempted : boolean; 

	 
  begin
    if reset = '1' then
      reconos_reset_with_signature(o_osif, i_osif, X"0B0B0B0B");
      resume_state_enc := (others => '0');
      done    := false;
      success := false;
      preempted := false;
      state <= STATE_CHECK;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case (state) is


            when STATE_CHECK =>
                reconos_thread_resume(done, success, o_osif, i_osif, resume_state_enc);
		if done then
               		if success then
                    		-- preempted
				preempted := true;
 				state <= decode(to_integer(unsigned(resume_state_enc)));
                	else
				-- unpreempted
				state <= STATE_INIT;
                	end if;
		end if;


          when STATE_INIT =>
			  --! init state, receive information struct
				reconos_get_init_data_s (done, o_osif, i_osif, information_struct);
            		if done then 
				     local_ram_cache_address <= "00000000000000000001111110000000";	 
				     local_ram_cache_address_if <= "011111100000"; 
				     enable <= '0';
				     local_ram_address    <= (others => '0');
				     local_ram_address_if <= (others => '0');
				     init <= '1';
				     new_particle <= '0';
					  parameter_loaded <= '0';
				    -- CHANGE CHANGE CHANGE
				    state <= STATE_READ_PARTICLE_ADDRESS;
					 --state <= STATE_WAIT_FOR_MESSAGE;
					 -- END OF CHANGE CHANGE CHANGE
					 -- CHANGE 2 OF 7
					      --state <= STATE_NEEDED_BURSTS;
					 -- END CHANGE
            		end if;
				
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 1: READ INFORMATION_STRUCT 
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			
			


			when STATE_READ_PARTICLE_ADDRESS =>
			  --! read particle array address
			   reconos_read_s (done, o_osif, i_osif, information_struct, particle_array_start_address);
            if done then
					state <= STATE_READ_NUMBER_OF_PARTICLES;
            end if;
	
		
			 when STATE_READ_NUMBER_OF_PARTICLES =>
             --! read number of particles N
				reconos_read (done, o_osif, i_osif, information_struct+4, N_var);
            if done then
            	N <= TO_INTEGER(SIGNED(N_var));
					state <= STATE_READ_PARTICLE_SIZE;
            end if;	           
				
								
			 when STATE_READ_PARTICLE_SIZE =>
				--! read particle size
				reconos_read (done, o_osif, i_osif, information_struct+8, particle_size_var);
            if done then
            	particle_size <= TO_INTEGER(SIGNED(particle_size_var));
					state <= STATE_READ_BLOCK_SIZE;
            end if;

				
			 when STATE_READ_BLOCK_SIZE =>
				--! read particle size
				reconos_read (done, o_osif, i_osif, information_struct+12, block_size_var);
            if done then
            	block_size <= TO_INTEGER(SIGNED(block_size_var));
					state <= STATE_READ_OBSERVATION_SIZE;
            end if;
				
				
			 when STATE_READ_OBSERVATION_SIZE =>
            --! read observation size
				reconos_read (done, o_osif, i_osif, information_struct+16, observation_size_var);
            if done then
            	observation_size <= TO_INTEGER(SIGNED(observation_size_var));
					state <= STATE_NEEDED_BURSTS;
            end if;	
				
				
			 when STATE_NEEDED_BURSTS =>
            --! calculate needed bursts
            number_of_bursts_remember <= observation_size / 128;
            state <= STATE_LENGTH_LAST_BURST;
				

          when STATE_LENGTH_LAST_BURST =>
            --! calculate number of reads (1 of 2)
				length_of_last_burst <= observation_size mod 128;            
				state <= STATE_LENGTH_LAST_BURST_2;


          when STATE_LENGTH_LAST_BURST_2 =>
            --! calculate number of reads (2 of 2)
            length_of_last_burst <= length_of_last_burst / 8;
            state <= STATE_READ_OBSERVATION_ARRAY_ADDRESS;
				-- CHANGE 3 OF 7
                --state <= STATE_WAIT_FOR_MESSAGE;
            -- END CHANGE					 


	       when STATE_READ_OBSERVATION_ARRAY_ADDRESS =>
			   --! read observation array address
			   reconos_read_s (done, o_osif, i_osif, information_struct+20, observation_array_start_address);
            if done then
					state <= STATE_READ_INPUT_DATA_LINK_ADDRESS;
            end if;

	
	       when STATE_READ_INPUT_DATA_LINK_ADDRESS =>
			   --! read observation array address
			   reconos_read_s (done, o_osif, i_osif, information_struct+24, input_data_link_address);
            if done then
					--state <= STATE_WAIT_FOR_MESSAGE;
               state <= STATE_READ_PARAMETER_SIZE;
				end if;
				
				
			 when STATE_READ_PARAMETER_SIZE =>
			   --! read parameter size
				reconos_read (done, o_osif, i_osif, information_struct+28, parameter_size_var);
            if done then
				   parameter_size <= TO_INTEGER(SIGNED(parameter_size_var));
					state <= STATE_READ_PARAMETER_ADDRESS;
            end if;
				
				
			 when STATE_READ_PARAMETER_ADDRESS =>
			   --! read parameter size
				reconos_read_s (done, o_osif, i_osif, information_struct+32, parameter_address);
            if done then
					state <= STATE_COPY_PARAMETER;
				   local_ram_address_if <= local_ram_start_address_if;
            end if;			

				
				
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 1: READ PARAMETERS 
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


			 when STATE_COPY_PARAMETER =>
			   --! read parameter size
				o_RAMWEObservation <= '0';
				if (parameter_size > 0) then
				   parameter_size <= parameter_size - 1;
				   state          <= STATE_COPY_PARAMETER_2;
				else
					state            <= STATE_COPY_PARAMETER_ACK;
					parameter_loaded <= '1';
					enable           <= '1';
					init             <= '0';
				end if;


			 when STATE_COPY_PARAMETER_2 =>
			   --! read parameter size
				reconos_read_s (done, o_osif, i_osif, parameter_address, ram_data);
            if done then
					state <= STATE_COPY_PARAMETER_3;
            end if;	


			 when STATE_COPY_PARAMETER_3 =>
			   --! read parameter size
				parameter_address    <= parameter_address + 4;
				local_ram_address_if <= local_ram_address_if + 1;
				enable               <= '0';
            o_RAMWEObservation   <= '1';
				o_RAMAddrObservation <= local_ram_address_if;
				o_RAMDataObservation <= ram_data;
            state <= STATE_COPY_PARAMETER;	


			 when STATE_COPY_PARAMETER_ACK =>
			   --! read parameter size
				if (parameter_loaded_ack = '1') then
					enable <= '0';
					init   <= '1';
					parameter_loaded <= '0';
					local_ram_address      <= (others => '0');
					local_ram_address_if   <= (others => '0');
					if preempted then
						preempted := false;
						state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_1;
					else
						state <= STATE_WAIT_FOR_MESSAGE;
					end if;	
            			end if;						
				
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 2: WAIT FOR MESSAGE
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------				
		    when STATE_WAIT_FOR_MESSAGE =>
			   --! wait for semaphore to start resampling
				reconos_mbox_get(done, success, o_osif, i_osif, C_MB_START, message_var);
				reconos_flag_yield(o_osif, i_osif, encode(STATE_WAIT_FOR_MESSAGE));
				if done then
				 if success then
				      message <= TO_INTEGER(SIGNED(message_var));
						-- init signals
						local_ram_address      <= (others => '0');
						local_ram_address_if   <= (others => '0');
						enable     <= '0';
						init       <= '1';
						--time_start <= TO_INTEGER(SIGNED(i_timebase));
						parameter_loaded <= '0';
						if preempted then
							state <= STATE_INIT;
						else
							state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_1;
						end if;
                                        else
							state <= STATE_EXIT;
                                   end if;
				 end if;


          when STATE_CALCULATE_REMAINING_OBSERVATIONS_1 =>
            --! calculates particle array address and number of particles to sample
				message2 <= message-1;
				temp <= 0;
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_2;


			 when STATE_CALCULATE_REMAINING_OBSERVATIONS_2 =>
            --! calculates particle array address and number of particles to sample
				--temp <= message2 * block_size; -- timing error for virtex 4 ("18 setup errors")
				if (message2 > 0) then
				
						temp <= temp + block_size;
						message2 <= message2 - 1;
				else
						-- temp = (message-1) * block_size
						state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_3;
				end if;
				
				
			 when STATE_CALCULATE_REMAINING_OBSERVATIONS_3 =>
            --! calculates particle array address and number of particles to sample
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_4;

				
			when STATE_CALCULATE_REMAINING_OBSERVATIONS_4 =>
            --! calculates particle array address and number of particles to sample
				temp2 <= temp * particle_size;
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_5;	
				
			when STATE_CALCULATE_REMAINING_OBSERVATIONS_5 =>
            --! calculates particle array address and number of particles to sample
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_6;					


			when STATE_CALCULATE_REMAINING_OBSERVATIONS_6 =>
            --! calculates particle array address and number of particles to sample
				temp3 <= temp * observation_size;
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_7;	

			when STATE_CALCULATE_REMAINING_OBSERVATIONS_7 =>
            --! calculates particle array address and number of particles to sample
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_8;				
				
			when STATE_CALCULATE_REMAINING_OBSERVATIONS_8 =>
            --! calculates particle array address and number of particles to sample
				particle_array_address    <= particle_array_start_address    + temp2;
				observation_array_address <= observation_array_start_address + temp3;
            remaining_observations    <= N - temp;
				state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_9;	


			 when STATE_CALCULATE_REMAINING_OBSERVATIONS_9 =>
            --! calculates particle array address and number of particles to sample
            if (remaining_observations > block_size) then
				
				     remaining_observations <= block_size;
				end if;
            state <= STATE_READ_INPUT_DATA_ADDRESS;					
	

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 3: READ CURRENT INPUT DATA ADDRESS
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

	       when STATE_READ_INPUT_DATA_ADDRESS =>
			   --! read reference data address
	    reconos_read_s (done, o_osif, i_osif, input_data_link_address, input_data_address);
            if done then
	                 state <= STATE_READ_NEXT_PARTICLE;
            end if;
            -- CHANGE 5 of 7
				   -- input data address: 0x20000000
               --input_data_address     <=    "00100000000000000000000000000000";
               -- the particle array address: 0x10000000            
               --particle_array_address <=    "00010000000000000000000000000000";

				   -- the observation array address: 0x11000000
               --observation_array_address <= "00010001000000000000000000000000";  				
               --state <= STATE_READ_NEXT_PARTICLE;
				-- END CHANGE
				
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 4: WRITE PARTICLE INTO CURRENT RAM
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	


         when STATE_READ_NEXT_PARTICLE =>
			  --! read next particle to local ram (writing the first 128 bytes to the local ram)
                          -- CHANGE CHANGE CHANGE
			  reconos_read_burst(done, o_osif, i_osif, local_ram_start_address, particle_array_address);
  			      if done then
			  		  particle_array_address  <= particle_array_address + particle_size;
					  -- CHANGE CHANGE CHANGE
					  state <= STATE_START_EXTRACT_OBSERVATION;
					  --state <= STATE_WRITE_OBSERVATION;
					  -- END OF CHANGE CHANGE CHANGE
			     end if;
                            -- END OF CHANGE CHANGE CHANGE


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
----				
----        STEP 5: START OBSERVATION EXTRACTION
----
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------			
						

          when STATE_START_EXTRACT_OBSERVATION =>
            --! start the user process 
			   init <= '0';
			   enable <= '1';
			   new_particle <= '1';
			   state <= STATE_START_EXTRACT_OBSERVATION_WAIT;
				
				
			when STATE_START_EXTRACT_OBSERVATION_WAIT =>
		     --! user process needs to start the execution
			  -- CHANGE CHANGE CHANGE
			    if new_particle_ack = '1' then 
				     new_particle <= '0';
			        state <= STATE_EXTRACT_OBSERVATION;
				 end if;
           -- END OF CHANGE CHANGE CHANGE
				 
		
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 6: WAIT FOR OBSERVATION EXTRACTION TO FINISH / ANSWER DATA CALLS INBETWEEN
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	
				 
			
			when STATE_EXTRACT_OBSERVATION =>			
            --! check if observation is finished, or it input data is needed (from cache)
				if finished = '1' then
				     -- observation finished
				     enable <= '0';
					  init   <= '1';
					  new_particle <= '0';
			        state  <= STATE_WRITE_OBSERVATION;
				elsif input_data_needed = '1' then
				     
				      state  <= STATE_GET_INPUT_DATA;				
				end if;
				
				
			when STATE_GET_INPUT_DATA =>			
            --! get input data at word_address (and write it into word_data)
				enable <= '0';
				cache_offset  <= 0;
				if (cache_min <= word_address) and (word_address < cache_max) then
				  -- cache hit
				  state <= STATE_CACHE_HIT;
				  --current_address <= cache_min;
				  current_address  <= word_address - cache_min;
				else
				  -- cache miss
				  state <= STATE_CACHE_MISS;
				end if;
				
			
			when STATE_CACHE_HIT =>
			  --! calculate the correct position in the local ram
			    cache_offset <= TO_INTEGER(UNSIGNED(current_address)) / 4;
				 state <= STATE_LOAD_WORD;				
			
				
			when STATE_CACHE_MISS =>
                          --! check if word address is double aligned        			
                           if (word_address(29) = '0') then
                                  -- word address is double-word aligned (needed for read bursts)
				                      cache_min <= word_address;
				                      cache_max <= word_address + 128;
                                  cache_offset <= 0;
                           else
                                  -- word address is NOT double-word aligned => cache_min has to be adjusted
                                  cache_min <= word_address - 4;
							             cache_max <= word_address + 124;
                                  cache_offset <= 1;
                           end if;
                           state <= STATE_CACHE_MISS_2;


			when STATE_CACHE_MISS_2 =>			
                 --! reads 128 byte input burst into local ram cache
				     reconos_read_burst(done, o_osif, i_osif, local_ram_cache_address, cache_min);
  			        if done then
                                        state <= STATE_LOAD_WORD;
			        end if;
                   
						 
		   when STATE_LOAD_WORD =>
			  --! load word data
			  o_RAMAddrObservation <= local_ram_cache_address_if + cache_offset;
			  state <= STATE_LOAD_WORD_2;		
		
			
		   when STATE_LOAD_WORD_2 =>
			  --! load word data (wait one cycle)
		--	  state <= STATE_LOAD_WORD_3;		
		--	  
		--	  
		--   when STATE_LOAD_WORD_3 =>
		--	  --! load word data (get word)
		--	  word_data <= i_RAMData;
			  state <= STATE_WRITE_WORD_BACK;


         when STATE_WRITE_WORD_BACK =>
			  --! activate user process and transfer the word
			  enable <= '1';
			  word_data_en <= '1';
			  word_data <= i_RAMData;
			  state  <= STATE_WRITE_WORD_ACK;
			  
			when STATE_WRITE_WORD_ACK =>
			  --! wait for acknowledgement
			  if word_data_ack = '1' then	  
			      word_data_en <= '0';
					state <= STATE_EXTRACT_OBSERVATION;
			  end if;
			  

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 7: WRITE OBSERVATION TO MAIN MEMORY
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			
			


          when STATE_WRITE_OBSERVATION => 			 
		      --! write observation (init)
				number_of_bursts  <= number_of_bursts_remember;
				local_ram_address <= local_ram_start_address;
				--write_histo_en <= '1';
				state <= STATE_WRITE_OBSERVATION_2;


          when STATE_WRITE_OBSERVATION_2 => 			 
		      --! write observation (check burst number)
				if number_of_bursts > 0 then
				    -- more full bursts needed
				    state <= STATE_WRITE_OBSERVATION_3;
					 number_of_bursts <= number_of_bursts - 1;
				elsif length_of_last_burst > 0 then
				    -- last burst needed (not full)
					 temp4 <= length_of_last_burst * 8;
				    state <= STATE_WRITE_OBSERVATION_4;			 
				else
				    -- no last burst needed (which is not full)
				    state <= STATE_MORE_PARTICLES;
				end if;
				
				
			 when STATE_WRITE_OBSERVATION_3 => 			 
		      --! write observation (write bursts)
				reconos_write_burst(done, o_osif, i_osif, local_ram_address, observation_array_address);
  			      if done then
					  observation_array_address  <= observation_array_address  + 128;
					  local_ram_address          <= local_ram_address          + 128;
					  state <= STATE_WRITE_OBSERVATION_2;
				   end if;
				
			
			 when STATE_WRITE_OBSERVATION_4 => 			 
		      --! write observation (write last burst)
				reconos_write_burst_l(done, o_osif, i_osif, local_ram_address, observation_array_address, length_of_last_burst);
  			      if done then
					  state <= STATE_MORE_PARTICLES;
					  observation_array_address  <= observation_array_address  + temp4;
					  local_ram_address    <= local_ram_address    + temp4;					  				  
				   end if;	


				
				
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 8: MORE PARTICLES?
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

         when STATE_MORE_PARTICLES =>
           --! check if more particles need an observation
			  remaining_observations <= remaining_observations - 1;
           state <= STATE_MORE_PARTICLES_2;
			  
			
	      when STATE_MORE_PARTICLES_2 =>
           --! check if more particles need an observation
           if (remaining_observations > 0) then
                  state <= STATE_READ_NEXT_PARTICLE;
           else
                  --time_stop <= TO_INTEGER(SIGNED(i_timeBase));
						state <= STATE_SEND_MESSAGE;
           end if;
						
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 9: SEND MESSAGE
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			
									
											
          when STATE_SEND_MESSAGE =>
			   --! post semaphore (importance is finished)
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_DONE, STD_LOGIC_VECTOR(TO_SIGNED(message, C_OSIF_DATA_WIDTH)));
            if done and success then
						enable <= '0';
						init <= '1';
						state <= STATE_SEND_MEASUREMENT_1;
				end if;	


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 9*: SEND MEASURMENT 
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			
			

          when STATE_SEND_MEASUREMENT_1 =>
			    --! sends time measurement to message box
				reconos_mbox_tryget(done, success, o_osif, i_osif, C_MB_EXIT, message_var);
				if done then
					if success then
						state <= STATE_EXIT;
					else
						state <= STATE_WAIT_FOR_MESSAGE;
					end if;
				end if;

				 --  send only, if time start < time stop. Else ignore this measurement
				 --if (time_start < time_stop) then
				 --	time_measurement <= time_stop - time_start;
				 --	state <= STATE_SEND_MEASUREMENT_2;
				 --else
			         --     state <= STATE_WAIT_FOR_MESSAGE;
				 --end if;


           when STATE_SEND_MEASUREMENT_2 =>
			    --! sends time measurement to message box
				 --  send message
				 --reconos_mbox_put(done, success, o_osif, i_osif, C_MB_MEASUREMENT, 
				 --	STD_LOGIC_VECTOR(TO_SIGNED(time_measurement, C_OSIF_DATA_WIDTH)));
				 --if (done and success) then
 					state <= STATE_WAIT_FOR_MESSAGE;				 
				 --end if;					
					
           when STATE_EXIT =>
		reconos_thread_exit(o_osif, i_osif, X"00000000");	
	

          when others =>
            state <= STATE_WAIT_FOR_MESSAGE;
        end case;		  
		  	  
      end if;
    end if;
  end process;
   
end Behavioral;
