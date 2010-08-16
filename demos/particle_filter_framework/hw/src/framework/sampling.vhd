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


entity sampling is

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
	 
	 -- time base
    i_timeBase : in std_logic_vector( 0 to C_OSIF_DATA_WIDTH-1 )
    );
end sampling;

architecture Behavioral of sampling is

  component uf_prediction is
  
    Port( clk    : in  std_logic;
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
	       -- start signal for the prediction user process
	       particles_loaded             : in std_logic;
	       -- number of particles in local RAM
          number_of_particles          : in integer;
	       -- size of one particle
          particle_size                : in integer;
          -- if every particle is sampled, this signal has to be set to '1'
          finished     : out std_logic);
	 end component;


  attribute keep_hierarchy               : string;
  attribute keep_hierarchy of Behavioral : architecture is "true";

  -- ReconOS thread-local mailbox handles
  constant C_MB_START        : std_logic_vector(0 to 31) := X"00000000";
  constant C_MB_DONE         : std_logic_vector(0 to 31) := X"00000001";
  constant C_MB_MEASUREMENT  : std_logic_vector(0 to 31) := X"00000002";
  
  -- states
  type t_state is (STATE_INIT, STATE_READ_PARTICLES_ADDRESS, STATE_READ_N,
     STATE_READ_PARTICLE_SIZE, STATE_READ_MAX_NUMBER_OF_PARTICLES, STATE_READ_BLOCK_SIZE,
	  STATE_READ_PARAMETER_ADDRESS, STATE_READ_PARAMETER ,STATE_WAIT_FOR_MESSAGE,
	  STATE_CALCULATE_REMAINING_PARTICLES_1, STATE_CALCULATE_REMAINING_PARTICLES_2,
	  STATE_CALCULATE_REMAINING_PARTICLES_3, STATE_CALCULATE_REMAINING_PARTICLES_4, 
	  STATE_NEEDED_BURSTS_1, STATE_NEEDED_BURSTS_2, STATE_NEEDED_BURSTS_3,
	  STATE_NEEDED_BURSTS_4, STATE_COPY_PARTICLE_BURST_DECISION, STATE_COPY_PARTICLE_BURST, 
	  --STATE_COPY_PARTICLE_BURST_2, STATE_COPY_PARTICLE_BURST_3, STATE_COPY_PARTICLE_BURST_4,
	  STATE_PREDICTION, STATE_PREDICTION_DONE,
	  STATE_WRITE_BURST_DECISION, STATE_WRITE_BURST,
	  STATE_CALCULATE_WRITES_1, STATE_CALCULATE_WRITES_2, STATE_CALCULATE_WRITES_3,
	  STATE_CALCULATE_WRITES_4, STATE_WRITE_DECISION, STATE_READ, STATE_WRITE,
	  STATE_SEND_MESSAGE, STATE_SEND_MEASUREMENT_1, STATE_SEND_MEASUREMENT_2);

  -- current state
  signal state : t_state := STATE_INIT;
  
  -- particle array
  signal particle_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal current_particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- parameter array address
  signal parameter_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- local RAM address
  signal local_ram_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- local RAM data
  signal ram_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

  -- local RAM write_address
  signal local_ram_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

  -- information struct containing array addresses and other information like N, particle size
  signal information_struct : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- number of particles (set by message box, default = 100)
  signal N : integer := 4;
  
  -- number of particles still to resample
  signal remaining_particles : integer := 4;
  
  -- number of needed bursts
  signal number_of_bursts : integer := 0;
  
   -- number of needed bursts to be remembered (for writing back)
  signal number_of_bursts_remember : integer := 0; 
  
  -- size of a particle
  signal particle_size : integer := 48;
  
  -- temp variable
  signal temp : integer := 0;
  signal temp2 : integer := 0;
  signal temp3 : integer := 0;
  signal offset : integer := 0;
  
  -- start particle index
  signal start_particle_index : integer := 0;
  
  -- maximum number of particles, which fit into the local RAM (minus 128 byte)
  signal max_number_of_particles : integer := 168;
  
  -- number of bytes, which are not written with valid particle data
  signal diff : integer := 0;
  
  -- number of writes
  signal number_of_writes : integer := 0;
  
  -- local ram address for interface
  signal local_ram_address_if_read : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  signal local_ram_address_if_write : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  signal local_ram_start_address_if : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');

  -- message (received from message box). The number in the message says,
  -- which particle block has to be sampled
  signal message : integer := 1;
  
  -- message2 is message minus one
  signal message2 : integer := 0;
  
  -- block size, is the number of particles in a particle block
  signal block_size : integer := 10;
  
  -- time values for start, stop and the difference of both
  signal time_start       : integer := 0;
  signal time_stop        : integer := 0;
  signal time_measurement : integer := 0;
  
  signal particle_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

  -----------------------------------------------------------
  -- NEEDED FOR USER ENTITY INSTANCE
  -----------------------------------------------------------
  -- for prediction user process
  -- init
  signal init                         : std_logic := '1';
  -- enable
  signal enable                       : std_logic := '0';
  -- start signal for the resampling user process
  signal particles_loaded             : std_logic := '0';
  -- number of particles in local RAM
  signal  number_of_particles         : integer := 4;
  -- size of one particle
  signal particle_size_2              : integer := 0;
  -- if every particle is resampled, this signal has to be set to '1'
  signal finished     :  std_logic := '0';
  -- corrected local ram address. the least bit is inverted, because else the local ram will be used incorrect


  -- for switch 1: corrected local ram address. the least bit is inverted, because else the local ram will be used incorrect
  signal o_RAMAddrPrediction : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  -- for switch 1:corrected local ram address for this importance thread
  signal o_RAMAddrSampling : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  
  -- for switch 2: Write enable, user process
  signal o_RAMWEPrediction : std_logic := '0';
  -- for switch 2: Write enable, importance
  signal o_RAMWESampling : std_logic := '0';
  
  -- for switch 3: output ram data, user process
  signal o_RAMDataPrediction : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');
  -- for switch 3: output ram data, importance
  signal o_RAMDataSampling : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');
    

  
begin

  -- entity of user process
  user_process : uf_prediction
     port map (reset=>reset, clk=>clk, o_RAMAddr=>o_RAMAddrPrediction, o_RAMData=>o_RAMDataPrediction, 
	            i_RAMData=>i_RAMData, o_RAMWE=>o_RAMWEPrediction, o_RAMClk=>o_RAMClk,
	            init=>init, enable=>enable, particles_loaded=>particles_loaded,
					number_of_particles=>number_of_particles,
               particle_size=>particle_size_2, finished=>finished);
					
				


  -- burst ram interface 
  -- switch 1: address, correction is needed to avoid wrong addressing
  o_RAMAddr <= o_RAMAddrPrediction(0 to C_TASK_BURST_AWIDTH-2) & not o_RAMAddrPrediction(C_TASK_BURST_AWIDTH-1)
               when enable = '1' else o_RAMAddrSampling(0 to C_TASK_BURST_AWIDTH-2) & not o_RAMAddrSampling(C_TASK_BURST_AWIDTH-1);

  -- switch 2: write enable
  o_RAMWE <= o_RAMWEPrediction when enable = '1' else o_RAMWESampling;
  
  -- switch 3: output ram data
  o_RAMData <= o_RAMDataPrediction when enable = '1' else o_RAMDataSampling;
    
  

  -----------------------------------------------------------------------------
  --
  --  Reconos State Machine for Sampling: 
  --
  --  1) The Parameter are copied to the first 128 bytes of the local RAM
  --     Other information are set
  --
  --
  --  2) Waiting for Message m (Start of a Sampling run)
  --     Message m: sample particles of m-th particle block
  --
  --
  --  3) The number of needed bursts is calculated to fill the local RAM
  --     The number only differs from 63, if it is for the last particles,
  --     which fit into the local ram.
  --
  --
  --  4) The particles are copied into the local RAM by burst reads 
  --
  --
  --  5) The user prediction process is run
  --
  --
  --  6) After prediction the particles are written back to Main Memory.
  --     Since there can be several sampling threads, there has to be
  --     special treatment for the last 128 byte, which are written
  --     in 4 byte blocks and not in a 128 byte burst.
  --
  --
  --  7) If the user process is finished and more particle need to be
  --     sampled, then go to step 3 else to step 8
  --
  --
  --  8) Send message m (Stop of a Sampling run)
  --     Particles of m-th particle block are sampled
  --
  ------------------------------------------------------------------------------
  state_proc : process(clk, reset)
    
	 -- done signal for Reconos methods
	 variable done : boolean;

    -- success signal for Reconos method, which gets a message box
	 variable success : boolean;
	 
	 -- signals for N, particle_size and max number of particles which fit in the local RAM
	 variable N_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable particle_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	
	 variable max_number_of_particles_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable block_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
	 variable message_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state <= STATE_INIT;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is


          when STATE_INIT =>
			  --! init state, receive particle array address
			   -- TODO:  C H A N G E !!! (1 of 3)
				reconos_get_init_data_s (done, o_osif, i_osif, information_struct);
				--reconos_get_init_data_s (done, o_osif, i_osif, particle_array_start_address);
				enable <= '0';
				local_ram_address <= (others => '0');
				local_ram_start_address <= (others => '0');
				init <= '1';
				particles_loaded <= '0';
            if done then 
				    -- TODO:  C H A N G E !!! (2 of 3)
                state <= STATE_READ_PARTICLES_ADDRESS;
					 --state <= STATE_WAIT_FOR_MESSAGE;
            end if;


			when STATE_READ_PARTICLES_ADDRESS =>
			  --! read particle array address
			   reconos_read_s (done, o_osif, i_osif, information_struct, particle_array_start_address);
            if done then
					state <= STATE_READ_N;
            end if;
	
		
			 when STATE_READ_N =>
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
					state <= STATE_READ_MAX_NUMBER_OF_PARTICLES;
            end if;					
								
				
			 when STATE_READ_MAX_NUMBER_OF_PARTICLES =>
            --! read max number of particles, which fit into 63 bursts (128 bytes per burst)
				reconos_read (done, o_osif, i_osif, information_struct+12, max_number_of_particles_var);
            if done then
            	particle_size_2 <= particle_size / 4;
					max_number_of_particles <= TO_INTEGER(SIGNED(max_number_of_particles_var));
					state <= STATE_READ_BLOCK_SIZE;
            end if;	
				
					
			when STATE_READ_BLOCK_SIZE =>
            --! read bock size, this is the size of how many particles are in one block.
				--  A message sends the block number
				reconos_read (done, o_osif, i_osif, information_struct+16, block_size_var);
            if done then
            	block_size <= TO_INTEGER(SIGNED(block_size_var));
					--state <= STATE_WAIT_FOR_MESSAGE;
					-- CHANGE BACK !!! (1 of 2)
					state <= STATE_READ_PARAMETER_ADDRESS;
            end if;	
				

			when STATE_READ_PARAMETER_ADDRESS =>
			  --! read parameter array address
			   reconos_read_s (done, o_osif, i_osif, information_struct+20, parameter_array_address);
            if done then
					state <= STATE_READ_PARAMETER;
            end if; 

				
			 when STATE_READ_PARAMETER =>
            --! copy all parameter in one burst
			   reconos_read_burst(done, o_osif, i_osif, local_ram_start_address, parameter_array_address);
            if done then
					state <= STATE_WAIT_FOR_MESSAGE;
            end if;	

				
		    when STATE_WAIT_FOR_MESSAGE =>
			   --! wait for message, that starts Sampling
				reconos_mbox_get(done, success, o_osif, i_osif, C_MB_START, message_var);
				
				if done and success then
				      message <= TO_INTEGER(SIGNED(message_var));
						-- init signals
						particles_loaded <= '0';
						enable <= '0';
						init <= '1';
						time_start <= TO_INTEGER(SIGNED(i_timebase));
						state <= STATE_CALCULATE_REMAINING_PARTICLES_1;
				end if;
				
				
			 when STATE_CALCULATE_REMAINING_PARTICLES_1 =>
            --! calculates particle array address and number of particles to sample
            
            message2    <= message-1;
            state <= STATE_CALCULATE_REMAINING_PARTICLES_2;
				
		
		    when STATE_CALCULATE_REMAINING_PARTICLES_2 =>
            --! calculates particle array address and number of particles to sample
            
            remaining_particles    <= message2 * block_size;
            state <= STATE_CALCULATE_REMAINING_PARTICLES_3;
				
				
		   when STATE_CALCULATE_REMAINING_PARTICLES_3 =>
            --! calculates particle array address and number of particles to sample
            
            remaining_particles    <= N - remaining_particles;
			   particle_array_address <= particle_array_start_address;
            state <= STATE_CALCULATE_REMAINING_PARTICLES_4;


			 when STATE_CALCULATE_REMAINING_PARTICLES_4 =>
            --! calculates particle array address and number of particles to sample
            
            if (remaining_particles > block_size) then
				
				     remaining_particles <= block_size;
				end if;
				current_particle_array_address <= particle_array_start_address;
            state <= STATE_NEEDED_BURSTS_1;				


		    when STATE_NEEDED_BURSTS_1 =>
			   --! decision how many bursts are needed
					local_ram_address <= local_ram_start_address + 128;
					local_ram_address_if_read <= local_ram_start_address_if + 32;
					particles_loaded <= '0';
				   enable <= '0';
				   init <= '1';
					--start_particle_index <= N - remaining_particles;
					start_particle_index <= message2 * block_size;
			      if (remaining_particles <= 0) then
					
                    state <= STATE_SEND_MESSAGE;
						  time_stop <= TO_INTEGER(SIGNED(i_timeBase));
               else				 
								
				        temp <=  remaining_particles * particle_size;
				        state <= STATE_NEEDED_BURSTS_2;
					end if;
					
					
		when STATE_NEEDED_BURSTS_2 =>
			   --! decision how many bursts are needed
			    offset <= start_particle_index * particle_size;
				 state <= STATE_NEEDED_BURSTS_3;
					
					
		 when STATE_NEEDED_BURSTS_3 =>
			   --! decision how many bursts are needed
					current_particle_array_address <= particle_array_start_address + offset;
			      particle_array_address         <= particle_array_start_address + offset;
					if (temp >= 8064) then --8064 = 63*128
			            --copy as much particles as possible
				         number_of_bursts          <= 63;
							number_of_bursts_remember <= 63;
							number_of_particles <= max_number_of_particles;
							state <= STATE_COPY_PARTICLE_BURST_DECISION;
					else
					      -- copy only remaining particles
							number_of_bursts          <= temp / 128;
							number_of_bursts_remember <= temp / 128;
							number_of_particles <= remaining_particles;
							state <= STATE_NEEDED_BURSTS_4;
					end if;
					
					
			when STATE_NEEDED_BURSTS_4 =>
			   --! decision how many bursts are needed
				 number_of_bursts <= number_of_bursts + 1;
				 number_of_bursts_remember <= number_of_bursts_remember + 1;
				 state <= STATE_COPY_PARTICLE_BURST_DECISION;
			 
			 
		    when STATE_COPY_PARTICLE_BURST_DECISION =>
            --! check if another burst is needed
			    if (number_of_bursts > 63) then
			 
				   number_of_bursts <= 63;
			 
             elsif (number_of_bursts > 0) then
			 	 
			      number_of_bursts <= number_of_bursts - 1;
					state <= STATE_COPY_PARTICLE_BURST;

			    elsif (remaining_particles <= 0) then
				 
				    -- check it
					 state <= STATE_SEND_MESSAGE;
					 time_stop <= TO_INTEGER(SIGNED(i_timeBase));
				 
				 else
			 
			      remaining_particles <= remaining_particles - number_of_particles;
    				state <= STATE_PREDICTION;
					enable <= '1';
					particles_loaded <= '1';
					init <= '0';
			    end if;


		    when STATE_COPY_PARTICLE_BURST =>
            --! read another burst
			   -- NO MORE BURSTS
			   --temp3 <= 32;
				--state <= STATE_COPY_PARTICLE_BURST_2;
			 reconos_read_burst(done, o_osif, i_osif, local_ram_address, current_particle_array_address);
          if done then
              state <= STATE_COPY_PARTICLE_BURST_DECISION;
				  --if (local_ram_address < 8064) then
				         local_ram_address <= local_ram_address + 128;
				  --end if;
				  current_particle_array_address <= current_particle_array_address + 128;
          end if;

			 
--		    when STATE_COPY_PARTICLE_BURST_2 =>
--            --! read another burst
--			   -- NO MORE BURSTS
--				enable <= '0';
--				o_RAMWESampling<= '0';
--			   if (temp3 > 0) then
--				
--				    state <= STATE_COPY_PARTICLE_BURST_3;
--				    temp3 <= temp3 - 1;
--				else
--				
--				    state <= STATE_COPY_PARTICLE_BURST_DECISION;
--				end if;
--				
--				
--			 when STATE_COPY_PARTICLE_BURST_3 =>
--            --! read another burst
--			   -- NO MORE BURSTS
--			   --! load data to local ram  
--			  reconos_read_s (done, o_osif, i_osif, particle_array_address, particle_data);
--            if done then
--				    state <= STATE_COPY_PARTICLE_BURST_4;
--			       particle_array_address <= particle_array_address + 4;
--			   end if;
--				
--			
--			when STATE_COPY_PARTICLE_BURST_4 =>
--			   --! write particle data to local ram
--				o_RAMWESampling<= '1';
--				o_RAMAddrSampling <= local_ram_address_if_read;
--				o_RAMDataSampling <= particle_data;
--				local_ram_address_if_read <= local_ram_address_if_read + 1;
--				state <= STATE_COPY_PARTICLE_BURST_2;

			 
			 when STATE_PREDICTION =>
			   --! start prediction user process and wait until prediction is finished
				init <= '0';
				enable <= '1';
				particles_loaded <= '0';
				if (finished = '1') then
				
				    state <= STATE_PREDICTION_DONE;
				end if;
				
				
			 when STATE_PREDICTION_DONE =>
			   --! start prediction user process and wait until it is finished
				init <= '1';
				enable <= '0';
				particles_loaded <= '0';
				current_particle_array_address <= particle_array_address;
				local_ram_address <= local_ram_start_address + 128;
				local_ram_address_if_write <= local_ram_start_address_if + 32;
				number_of_bursts <= number_of_bursts_remember;
				state <= STATE_WRITE_BURST_DECISION;			


		    when STATE_WRITE_BURST_DECISION =>
          --! if write burst is demanded by user process, it will be done
					if (number_of_bursts > 63) then

                   number_of_bursts <= 63;

               --else
					-- NO MORE BURSTS
               elsif (number_of_bursts > 1) then						 

					    state <= STATE_WRITE_BURST;
  
					elsif (number_of_bursts <= 1) then
					     number_of_bursts <= 0;
					     state <= STATE_CALCULATE_WRITES_1;
						  diff <= (number_of_bursts_remember * 128);
					end if;


		    when STATE_WRITE_BURST =>
          --! write bursts from local ram into index array
					reconos_write_burst(done, o_osif, i_osif, local_ram_address, current_particle_array_address);
  			      if done then
					        local_ram_address <= local_ram_address + 128;
							  local_ram_address_if_write <= local_ram_address_if_write + 32;
							  current_particle_array_address <= current_particle_array_address + 128;
							  number_of_bursts <= number_of_bursts - 1;
							  state <= STATE_WRITE_BURST_DECISION;
					end if;	
					
					
          when STATE_CALCULATE_WRITES_1 =>
			 --! calculates number of writes (1/4)			
					temp2 <= number_of_particles * particle_size;
               --state <= STATE_CALCULATE_WRITES_4;					
					-- NO MORE BURSTS
					state <= STATE_CALCULATE_WRITES_2;	


          when STATE_CALCULATE_WRITES_2 =>
			 --! calculates number of writes (2/4)			
					diff <= diff - temp2;					 
					state <= STATE_CALCULATE_WRITES_3;	 
			 

			 when STATE_CALCULATE_WRITES_3 =>
			 --! calculates number of writes (3/4)
               number_of_writes <= 128 - diff;
               state <= STATE_CALCULATE_WRITES_4;
			 
			 
			 when STATE_CALCULATE_WRITES_4 =>
			 --! calculates number of writes (4/4)
               -- NO MORE BURSTS
					number_of_writes <= number_of_writes / 4;
					--number_of_writes <= temp2 / 4;
               state <= STATE_WRITE_DECISION;

								
          when STATE_WRITE_DECISION =>
			 --! decide if a reconos write is needed
			   if (number_of_writes <= 0) then

                 state <= STATE_NEEDED_BURSTS_1;
					 
            else
                 -- read local ram data
                 state <= STATE_READ;
					  o_RAMAddrSampling <= local_ram_address_if_write;
					  
				end if;			 


			 when STATE_READ =>
			   --! read 4 byte from local RAM
			   number_of_writes <= number_of_writes - 1;
			   --local_ram_address_if <= local_ram_address_if + 1;
			   o_RAMAddrSampling <= local_ram_address_if_write;
			   state <= STATE_WRITE;  
			  
			 
			 when STATE_WRITE =>
			 --! write 4 byte to particle array in main memory
			 reconos_write(done, o_osif, i_osif, current_particle_array_address, i_RAMData);
			 if done then
				  local_ram_address_if_write <= local_ram_address_if_write + 1;
				  current_particle_array_address <= current_particle_array_address + 4;
				  if  (number_of_writes <= 0) then
				  
				        state <= STATE_NEEDED_BURSTS_1;
				  else
				  
				        o_RAMAddrSampling <= local_ram_address_if_write;
				        state <= STATE_READ;
              end if;						  
			 end if;
			 				  
			  						  
          when STATE_SEND_MESSAGE =>
			 --! send message i (sampling is finished)
				  reconos_mbox_put(done, success, o_osif, i_osif, C_MB_DONE, STD_LOGIC_VECTOR(TO_SIGNED(message, C_OSIF_DATA_WIDTH)));
				  if done and success then
						  enable <= '0';
						  init <= '1';
						  particles_loaded <= '0';
						  state <= STATE_SEND_MEASUREMENT_1;
              end if;
				  
			  
			    
           when STATE_SEND_MEASUREMENT_1 =>
			    --! sends time measurement to message box
				 --  send only, if time start < time stop. Else ignore this measurement
				 --if (time_start < time_stop) then
				 
				 --     time_measurement <= time_stop - time_start;
				 --     state <= STATE_SEND_MEASUREMENT_2;

				 --else
			         
						state <= STATE_WAIT_FOR_MESSAGE;
				 --end if;


--           when STATE_SEND_MEASUREMENT_2 =>
--			    --! sends time measurement to message box
--				 --  send message
--				 reconos_mbox_put(done, success, o_osif, i_osif, C_MB_MEASUREMENT, STD_LOGIC_VECTOR(TO_SIGNED(time_measurement, C_OSIF_DATA_WIDTH)));
--				 if (done and success) then
--
--                  state <= STATE_WAIT_FOR_MESSAGE;				 
--				 end if;				 


          when others =>
            state <= STATE_WAIT_FOR_MESSAGE;
        end case;
		  
		  	  
      end if;
    end if;
  end process;
   
end Behavioral;


