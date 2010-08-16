library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_00_a;
use reconos_v2_00_a.reconos_pkg.all;

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
    C_TASK_BURST_AWIDTH : integer := 11;
    C_TASK_BURST_DWIDTH : integer := 32
    );

  port (
    clk    : in  std_logic;
    reset  : in  std_logic;
    i_osif : in  osif_os2task_t;
    o_osif : out osif_task2os_t;

    -- burst ram interface
    o_RAMAddr : out std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
    o_RAMData : out std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
    i_RAMData : in  std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
    o_RAMWE   : out std_logic;
    o_RAMClk  : out std_logic;
	 
	 -- CHANGE 1 OF 7
	   -- time base
    i_timeBase : in std_logic_vector( 0 to C_OSIF_DATA_WIDTH-1 )
    -- END CHANGE
	 );
end observation;


architecture Behavioral of observation is

  component uf_extract_observation is
  
    Port( 
	 clk    : in  std_logic;
    reset  : in  std_logic;

    -- burst ram interface
    o_RAMAddr : out std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
    o_RAMData : out std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
    i_RAMData : in  std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
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
    -- input/measurement data address
    input_data_address           : in std_logic_vector(0 to 31);
	 -- get data block
	 get_data_needed              : out std_logic; 
	 get_data_address             : out std_logic_vector(0 to 31);
	 get_data_length              : out integer;	 
	 -- receive data block
	 receive_data_en              : in std_logic;
	 receive_data_address         : in std_logic_vector(0 to C_TASK_BURST_AWIDTH-1); 
    -- recieved data	 
	 receive_data_ack             : out std_logic;
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
  
  -- states
  type t_state is (STATE_INIT, 
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
		  STATE_READ_NEXT_PARTICLE,
		  STATE_READ_NEXT_PARTICLE_2,
		  STATE_READ_NEXT_PARTICLE_3,	
		  STATE_READ_NEXT_PARTICLE_4,
		  STATE_CALCULATE_REMAINING_OBSERVATIONS_1, 
		  STATE_CALCULATE_REMAINING_OBSERVATIONS_2,
		  STATE_CALCULATE_REMAINING_OBSERVATIONS_3, 
		  STATE_CALCULATE_REMAINING_OBSERVATIONS_4,
		  STATE_CALCULATE_REMAINING_OBSERVATIONS_5, 
		  STATE_READ_INPUT_DATA_ADDRESS,
		  STATE_START_EXTRACT_OBSERVATION, 
		  STATE_START_EXTRACT_OBSERVATION_WAIT,
		  STATE_EXTRACT_OBSERVATION,
        STATE_GET_DATA, 
		  STATE_GET_DATA_2, 
		  STATE_GET_DATA_3, 
		  STATE_GET_DATA_4, 
		  STATE_GET_DATA_5, 
		  STATE_GET_DATA_6, 
		  STATE_GET_DATA_ACK,  
		  STATE_GET_DATA_ACK_2,
		  STATE_WRITE_OBSERVATION, 
		  STATE_WRITE_OBSERVATION_2, 
        STATE_WRITE_OBSERVATION_3, 
		  STATE_WRITE_OBSERVATION_4, 
		  STATE_MORE_PARTICLES, 
		  STATE_MORE_PARTICLES_2, 
		  STATE_SEND_MESSAGE, 
		  STATE_SEND_MEASUREMENT_1, 
		  STATE_SEND_MEASUREMENT_2 );

  -- current state
  signal state : t_state := STATE_INIT;
  
  -- particle array
  signal particle_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
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
  --signal local_ram_cache_address    : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := "00000000000000000001111110000000";	 
  --signal local_ram_cache_address_if : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1)    := "11111100000";	 
  signal local_ram_address_part_1_if       : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := "00000000000";	 
  signal local_ram_address_part_2_if       : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := "10000000000";	 
  signal local_ram_address_current_part_if : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := "10000000000";	 
  --signal cache_min : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  --signal cache_max : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
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
  signal particle_size : integer := 64;
  
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
  signal local_ram_address_if : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  signal local_ram_start_address_if : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  
  -- number of particles in a particle block
  signal block_size : integer := 2;
  
   -- counter for particle data
  signal counter : integer := 0; 
  
  -- current particle data
  signal particle_data : integer := 0;
  
  --  parameter address
  signal parameter_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
  
  -- parameter size
  signal parameter_size : integer := 0;
  
  -- parameter loaded
  signal parameter_loaded : std_logic := '0';  
  
  -- parameters acknowledged by user process
  signal parameter_loaded_ack : std_logic := '0';
  
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
  
  -----------------------------------------------------------
  -- NEEDED FOR USER ENTITY INSTANCE
  -----------------------------------------------------------
  -- for user process
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
  -- input data length
  signal get_data_length  : integer := 0;
  -- input data needed signal
  signal get_data_needed  : std_logic := '0';  
  -- word data address
  signal get_data_address : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');
  -- word data enable
  signal receive_data_en  : std_logic := '0';
  -- word address
  signal receive_data_address :  std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  -- word_ack
  signal receive_data_ack : std_logic := '0';
  -- if the observation is extracted, this signal is set to '1'
  signal finished         :  std_logic := '1';
  
  -- number of get data bursts
  signal number_of_data_bursts     : integer := 0; 
  -- length of last get data burst
  signal length_of_last_data_burst : integer := 0; 
  -- data burst counter
  signal data_burst_counter        : integer := 0; 
  
  --current address
  signal current_address  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
   
  -- for switch 1: corrected local ram address. the least bit is inverted,
--  --  because else the local ram will be used incorrect
  signal o_RAMAddrExtractObservation : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  -- for switch 1:corrected local ram address for this observation thread
  signal o_RAMAddrObservation : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  
  -- for switch 2: Write enable, user process
  signal o_RAMWEExtractObservation  : std_logic := '0';
  -- for switch 2: Write enable, observation
  signal o_RAMWEObservation : std_logic := '0';
  
  -- for switch 3: output ram data, user process
  signal o_RAMDataExtractObservation : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');
  -- for switch 3: output ram data, observation
  signal o_RAMDataObservation : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');



begin

  -- entity of user process
  user_process : uf_extract_observation
     port map (reset=>reset, clk=>clk, o_RAMAddr=>o_RAMAddrExtractObservation,
	            o_RAMData=>o_RAMDataExtractObservation, i_RAMData=>i_RAMData, 
					o_RAMWE=>o_RAMWEExtractObservation, o_RAMClk=>o_RAMClk,
					parameter_loaded=>parameter_loaded, parameter_loaded_ack=>parameter_loaded_ack,
					new_particle=>new_particle, new_particle_ack=>new_particle_ack, 
					input_data_address=>input_data_address, get_data_needed=>get_data_needed,
					get_data_address=>get_data_address, get_data_length=>get_data_length,
					receive_data_en=>receive_data_en, receive_data_address=>receive_data_address, 
               receive_data_ack=>receive_data_ack, 					
	            init=>init, enable=>enable, finished=>finished);


--  -- switch 1: address, correction is needed to avoid wrong addressing
    o_RAMAddr <= o_RAMAddrExtractObservation(0 to C_TASK_BURST_AWIDTH-2) & not o_RAMAddrExtractObservation(C_TASK_BURST_AWIDTH-1)
               when enable = '1' else o_RAMAddrObservation(0 to C_TASK_BURST_AWIDTH-2) & not o_RAMAddrObservation(C_TASK_BURST_AWIDTH-1);
--
  -- switch 2: write enable
  o_RAMWE <= o_RAMWEExtractObservation when enable = '1' else o_RAMWEObservation;
--  
  -- switch 3: output ram data
  o_RAMData <= o_RAMDataExtractObservation when enable = '1' else o_RAMDataObservation;
  
  
  
  
  -----------------------------------------------------------------------------
  --
  --  ReconOS State Machine for Observation: 
  --  
  -----------------------------------------------------------------------------
  --  
  --  1) read data from information struct + load parameter
  --  
  --  2) receive message m
  --  
  --  3) set current address for input data
  --  
  --  4) load current particle (into local rahttp://www.eintracht.de/aktuell/m, starting address (others=>'0'))
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
	 --variable get_data_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable particle_data_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	 
	 variable observation_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable block_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable parameter_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable message_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state <= STATE_INIT;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case (state) is


          when STATE_INIT =>
			  --! init state, receive information struct
				reconos_get_init_data_s (done, o_osif, i_osif, information_struct);
            if done then 
				     enable <= '0';
					  parameter_loaded <= '0';
				     local_ram_address    <= (others => '0');
				     local_ram_address_if <= (others => '0');
				     init <= '1';
				     new_particle <= '0';
				    state <= STATE_READ_PARTICLE_ADDRESS;
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
				   new_particle <= '0';
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
                  state  <= STATE_WAIT_FOR_MESSAGE;	
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
				if done and success then
				      message <= TO_INTEGER(SIGNED(message_var));
						-- init signals
						local_ram_address      <= (others => '0');
						local_ram_address_if   <= (others => '0');
						enable     <= '0';
						init       <= '1';
						parameter_loaded <= '0';
						--time_start <= TO_INTEGER(SIGNED(i_timebase));				
						state      <= STATE_CALCULATE_REMAINING_OBSERVATIONS_1;
				 end if;


          when STATE_CALCULATE_REMAINING_OBSERVATIONS_1 =>
            --! calculates particle array address and number of particles to sample
				message2 <= message-1;
				time_start <= TO_INTEGER(SIGNED(i_timebase));
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_2;


			 when STATE_CALCULATE_REMAINING_OBSERVATIONS_2 =>
            --! calculates particle array address and number of particles to sample
				temp <= message2 * block_size;
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_3;
				
				
			when STATE_CALCULATE_REMAINING_OBSERVATIONS_3 =>
            --! calculates particle array address and number of particles to sample
				temp2 <= temp * particle_size;
				temp3 <= temp * observation_size;
            state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_4;	
				
				
			when STATE_CALCULATE_REMAINING_OBSERVATIONS_4 =>
            --! calculates particle array address and number of particles to sample
				particle_array_address    <= particle_array_start_address    + temp2;
				observation_array_address <= observation_array_start_address + temp3;
            remaining_observations    <= N - temp;
				state <= STATE_CALCULATE_REMAINING_OBSERVATIONS_5;	


			 when STATE_CALCULATE_REMAINING_OBSERVATIONS_5 =>
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
			  counter <= particle_size / 4;
			  local_ram_address_if <= local_ram_start_address_if;
			  state <= STATE_READ_NEXT_PARTICLE_2;
			  
         when STATE_READ_NEXT_PARTICLE_2 =>
			  --! read next particle to local ram (writing the first 128 bytes to the local ram)
			  o_RAMWEObservation <= '0';
			  if (counter > 0) then
			        state <= STATE_READ_NEXT_PARTICLE_3;
                 counter <= counter - 1;
           else
                 state  <= STATE_START_EXTRACT_OBSERVATION;
           end if;

         when STATE_READ_NEXT_PARTICLE_3 =>
			  --! read next particle to local ram (writing the first 128 bytes to the local ram)
			  	reconos_read (done, o_osif, i_osif, particle_array_address, particle_data_var);
            if done then
	                 state <= STATE_READ_NEXT_PARTICLE_4;
						  particle_data <= TO_INTEGER(SIGNED(particle_data_var));
						  particle_array_address  <= particle_array_address + 4;
            end if;
				
         when STATE_READ_NEXT_PARTICLE_4 =>
			  --! read next particle to local ram (writing the first 128 bytes to the local ram)
           o_RAMWEObservation <= '1';
           o_RAMAddrObservation <= local_ram_address_if;
			  local_ram_address_if <= local_ram_address_if + 1;
           o_RAMDataObservation <= STD_LOGIC_VECTOR(TO_SIGNED(particle_data, 32));				
           state <= STATE_READ_NEXT_PARTICLE_2;		
				
				
			  
	

--         when STATE_READ_NEXT_PARTICLE =>
--			  --! read next particle to local ram (writing the first 128 bytes to the local ram)
--			  reconos_read_burst(done, o_osif, i_osif, local_ram_start_address, particle_array_address);
--  			      if done then
--			  		  particle_array_address  <= particle_array_address + particle_size;
--					  state <= STATE_START_EXTRACT_OBSERVATION;
--			     end if;

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
				elsif get_data_needed = '1' then				     
				     state  <= STATE_GET_DATA;						  
				end if;
				
	

			when STATE_GET_DATA =>
			 --! calculate number of full bursts and length of last bursts
			 number_of_data_bursts     <= get_data_length / 4;
			 state <= STATE_GET_DATA_2;
			 

			when STATE_GET_DATA_2 =>
			 --! calculate number of full bursts and length of last bursts
			 if (local_ram_address_current_part_if = local_ram_address_part_1_if) then
			        local_ram_address <= local_ram_start_address + 4096;
					  local_ram_address_if <= local_ram_address_part_2_if;
					  local_ram_address_current_part_if <= local_ram_address_part_2_if; 
			 else
			        local_ram_address <= local_ram_start_address;
					  local_ram_address_if <= local_ram_address_part_1_if;
					  local_ram_address_current_part_if <= local_ram_address_part_1_if;
			 end if;
			 --number_of_data_bursts <= number_of_data_bursts + 2;
			 current_address <= get_data_address;
			 state <= STATE_GET_DATA_3;


			when STATE_GET_DATA_3 =>
			 --! calculate number of full bursts and length of last bursts
			  o_RAMWEObservation <= '0';
			  enable <= '1';
			  if (number_of_data_bursts > 0) then
			        state <= STATE_GET_DATA_4;
                 number_of_data_bursts <= number_of_data_bursts - 1;
           else
                 state  <= STATE_GET_DATA_ACK;
           end if;

         when STATE_GET_DATA_4 =>
			  --! read next particle to local ram (writing the first 128 bytes to the local ram)
			  	reconos_read_s (done, o_osif, i_osif, current_address, ram_data);
            if done then
	                 state <= STATE_GET_DATA_5;
						  current_address <= current_address + 4;
            end if;
				
         when STATE_GET_DATA_5 =>
			  --! read next particle to local ram (writing the first 128 bytes to the local ram)
			  enable <= '0';
           o_RAMWEObservation   <= '1';
           o_RAMAddrObservation <= local_ram_address_if;
			  local_ram_address_if <= local_ram_address_if + 1;
           o_RAMDataObservation <= ram_data;				
           state <= STATE_GET_DATA_3;		
			 
			 
			when STATE_GET_DATA_ACK =>
			  --! wait for acknowledgement 
			  receive_data_en <= '1';
			  receive_data_address <= local_ram_address_current_part_if;
			  enable <= '1';	
			  state <= STATE_GET_DATA_ACK_2;
		              	   			  
			when STATE_GET_DATA_ACK_2 =>
			  --! wait for acknowledgement
			  if receive_data_ack = '1' then	  
			      receive_data_en <= '0';
					state <= STATE_EXTRACT_OBSERVATION;
			  end if;				
				
	
--			when STATE_GET_DATA =>
--			 --! calculate number of full bursts and length of last bursts
--			 number_of_data_bursts     <= get_data_length / 128;
--			 length_of_last_data_burst <= get_data_length mod 128;
--			 state <= STATE_GET_DATA_2;
--			 
--
--			when STATE_GET_DATA_2 =>
--			 --! calculate number of full bursts and length of last bursts
--			 if (length_of_last_data_burst > 0) then
--			        length_of_last_data_burst <= length_of_last_data_burst + 8;
--			 end if;
--			 if (local_ram_address_current_part_if = local_ram_address_part_1_if) then
--			        local_ram_address <= local_ram_start_address + 4096;
--					  local_ram_address_current_part_if <= local_ram_address_part_2_if; 
--			 else
--			        local_ram_address <= local_ram_start_address;
--					  local_ram_address_current_part_if <= local_ram_address_part_1_if;
--			 end if;
--			 state <= STATE_GET_DATA_3;
--
--
--			when STATE_GET_DATA_3 =>
--			 --! calculate number of full bursts and length of last bursts
--			 length_of_last_data_burst <= length_of_last_data_burst / 8;
--			 data_burst_counter <= 0;
--			 if (get_data_address(29) = '0') then
--			     -- double word aligned address
--			     current_address       <= get_data_address;
--				  receive_data_address <= local_ram_address_current_part_if;
--			 else
--			     -- no double aligned address (=> change it)
--			     current_address <= get_data_address - 4;
--				  receive_data_address <= local_ram_address_current_part_if + 1;				  
--			 end if;
--			 state <= STATE_GET_DATA_4;
--			 
--
--			when STATE_GET_DATA_4 =>
--			 --! read full data burst / last data burst
--			 if (data_burst_counter < number_of_data_bursts) then
--			     state <= STATE_GET_DATA_5;
--              data_burst_counter <= data_burst_counter + 1; 			  
--			 else
--			     if (length_of_last_data_burst > 0) then
--				        state <= STATE_GET_DATA_6;
--				  else
--				        state <= STATE_GET_DATA_ACK;
--				  end if;
--			 end if;
--			 
--			 
--			when STATE_GET_DATA_5 =>
--			 --! read full data burst
--			 reconos_read_burst(done, o_osif, i_osif, local_ram_address, current_address);
--  			 if done then
--			       current_address   <= current_address   + 128;
--					 local_ram_address <= local_ram_address + 128;
--                state <= STATE_GET_DATA_4;
--			 end if;
--			 
--			 
--			when STATE_GET_DATA_6 =>
--			 --! read last data burst (with defined length)
--          reconos_read_burst_l(done, o_osif, i_osif, local_ram_address, current_address, length_of_last_data_burst);
--  			 if done then
--					  state <= STATE_GET_DATA_ACK;
--		    end if;
--			 
--			 
--			when STATE_GET_DATA_ACK =>
--			  --! wait for acknowledgement 
--			  receive_data_en <= '1';
--			  state <= STATE_GET_DATA_ACK_2;
--		              	   			  
--			when STATE_GET_DATA_ACK_2 =>
--			  --! wait for acknowledgement
--			  if receive_data_ack = '1' then	  
--			      receive_data_en <= '0';
--					state <= STATE_EXTRACT_OBSERVATION;
--			  end if;
			  
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
			  enable <= '0';
			  
			
	      when STATE_MORE_PARTICLES_2 =>
           --! check if more particles need an observation
           if (remaining_observations > 0) then
                  state <= STATE_READ_NEXT_PARTICLE;
           else
                  time_stop <= TO_INTEGER(SIGNED(i_timeBase));
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
				 --  send only, if time start < time stop. Else ignore this measurement
				 if (time_start < time_stop) then
				 
				     time_measurement <= time_stop - time_start;
				     state <= STATE_SEND_MEASUREMENT_2;
             
				 else
			         state <= STATE_WAIT_FOR_MESSAGE;
				 end if;


           when STATE_SEND_MEASUREMENT_2 =>
			    --! sends time measurement to message box
				 --  send message
				 reconos_mbox_put(done, success, o_osif, i_osif, C_MB_MEASUREMENT, STD_LOGIC_VECTOR(TO_SIGNED(time_measurement, C_OSIF_DATA_WIDTH)));
				 if (done and success) then
                    state <= STATE_WAIT_FOR_MESSAGE;			  
				 end if;					
						

          when others =>
            state <= STATE_WAIT_FOR_MESSAGE;
        end case;		  
		  	  
      end if;
    end if;
  end process;
   
end Behavioral;
