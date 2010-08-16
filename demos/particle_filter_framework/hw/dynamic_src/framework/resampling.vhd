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
--                                                                            --                                                                          --
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


entity resampling is

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
end resampling;

architecture Behavioral of resampling is

  component uf_resampling
    generic (
    C_BURST_AWIDTH : integer := 12;
    C_BURST_DWIDTH : integer := 32
    );
	 
      Port ( 
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

    -- this signal has to be set to '1', if the Framework should write
	 -- the last burst from local RAM into Maim Memory 
    write_burst  : out std_logic;
	 -- write burst done acknowledgement
	 write_burst_done_ack  : out std_logic;
	 -- number of currently written particles
	 written_values : out integer;
	 -- if every particle is resampled, this signal has to be set to '1'
    finished     : out std_logic);
	 end component;


  attribute keep_hierarchy               : string;
  attribute keep_hierarchy of Behavioral : architecture is "true";

  -- ReconOS thread-local mailbox handles
  constant C_MB_START : std_logic_vector(0 to 31) := X"00000000";
  constant C_MB_DONE  : std_logic_vector(0 to 31) := X"00000001";
  constant C_MB_MEASUREMENT  : std_logic_vector(0 to 31) := X"00000002";
  
  -- states
  type state_t is (
	STATE_CHECK, 
	STATE_INIT, 
	STATE_READ_PARTICLES_ADDRESS, 
	STATE_READ_INDEXES_ADDRESS,
	STATE_READ_N, 
	STATE_READ_PARTICLE_SIZE, 
	STATE_READ_MAX_NUMBER_OF_PARTICLES,
	STATE_READ_BLOCK_SIZE, 
	STATE_READ_U_FUNCTION,
	STATE_WAIT_FOR_MESSAGE, 
	STATE_CALCULATE_REMAINING_PARTICLES_1,
	STATE_CALCULATE_REMAINING_PARTICLES_2, 
	STATE_CALCULATE_REMAINING_PARTICLES_3,	  
	STATE_CALCULATE_REMAINING_PARTICLES_4, 
	STATE_CALCULATE_REMAINING_PARTICLES_5, 
	STATE_LOAD_U_INIT, 
	STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_1,
	STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_2, 
	STATE_WRITE_TO_RAM,
	STATE_WRITE_BURST_DECISION, 
	STATE_WRITE_BURST_DECISION_2, 
	STATE_WRITE_BURST,
	STATE_WRITE_DECISION, 
	STATE_READ, 
	STATE_WRITE,
	STATE_WRITE_BURST_DONE_ACK, 
	STATE_SEND_MESSAGE,
	STATE_SEND_MEASUREMENT_1, 
	STATE_SEND_MEASUREMENT_2,
	STATE_SEND_INFO_1,
	STATE_SEND_INFO_2,
	STATE_EXIT
  );
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
                                  X"1F"
  );
  constant decode : decode_t := (
	STATE_CHECK, 
	STATE_INIT, 
	STATE_READ_PARTICLES_ADDRESS, 
	STATE_READ_INDEXES_ADDRESS,
	STATE_READ_N, 
	STATE_READ_PARTICLE_SIZE, 
	STATE_READ_MAX_NUMBER_OF_PARTICLES,
	STATE_READ_BLOCK_SIZE, 
	STATE_READ_U_FUNCTION,
	STATE_WAIT_FOR_MESSAGE, 
	STATE_CALCULATE_REMAINING_PARTICLES_1,
	STATE_CALCULATE_REMAINING_PARTICLES_2, 
	STATE_CALCULATE_REMAINING_PARTICLES_3,	  
	STATE_CALCULATE_REMAINING_PARTICLES_4, 
	STATE_CALCULATE_REMAINING_PARTICLES_5, 
	STATE_LOAD_U_INIT, 
	STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_1,
	STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_2, 
	STATE_WRITE_TO_RAM,
	STATE_WRITE_BURST_DECISION, 
	STATE_WRITE_BURST_DECISION_2, 
	STATE_WRITE_BURST,
	STATE_WRITE_DECISION, 
	STATE_READ, 
	STATE_WRITE,
	STATE_WRITE_BURST_DONE_ACK, 
	STATE_SEND_MESSAGE,
	STATE_SEND_MEASUREMENT_1, 
	STATE_SEND_MEASUREMENT_2,
	STATE_SEND_INFO_1,
	STATE_SEND_INFO_2,
	STATE_EXIT
  );

  -- current state
  signal state : state_t := STATE_CHECK;
  
  -- particle array
  signal particle_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
    -- index array
  signal index_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"10000000";
  signal index_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
    -- resampling function U array
  signal U_array_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"10000000";
  signal U_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  
  -- local RAM address
  signal local_ram_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal local_ram_address_if_write : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  signal local_ram_address_if_read : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  -- local RAM write_address
  signal local_ram_start_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  -- information struct containing array addresses and other information like N, particle size
  signal information_struct : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  
    -- message (received from message box). The number in the message says,
  -- which particle block has to be sampled
  signal message : integer := 1;
  
  -- message2 is message minus one
  signal message2 : integer := 0;
  
  -- block size, is the number of particles in a particle block
  signal block_size : integer := 10;
  
  -- local RAM data (particle weight)
  signal weight_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  
  -- number of particles (set by message box, default = 100)
  signal N : integer := 18;
  
  -- number of particles still to resample
  signal remaining_particles : integer := 0;
  
  -- number of needed bursts
  signal number_of_bursts : integer := 0;
  
  -- size of a particle
  signal particle_size : integer := 8;
  
  -- temp variable
  signal temp  : integer := 0;
  signal temp2 : integer := 0;
  signal temp3 : integer := 0;
  signal temp4 : integer := 0;
  
  -- number of particles to resample
  signal number_of_particles_to_resample : integer := 9;
  
  -- write counter
  signal write_counter : integer := 0;
  
  -- local RAM data
  signal ram_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- start index
  signal start_index : integer := 3;
  
  -- temporary variables
  signal offset : integer := 1;
  signal offset2 : integer := 1;
  
  
  -- time values for start, stop and the difference of both
  --signal time_start       : integer := 0;
  --signal time_stop        : integer := 0;
  --signal time_measurement : integer := 0;

  -----------------------------------------------------------
  -- NEEDED FOR USER ENTITY INSTANCE
  -----------------------------------------------------------
  -- for resampling user process
  -- init
  signal init                         : std_logic := '1';
  -- enable
  signal enable                       : std_logic := '0';
  -- start signal for the resampling user process
  signal particles_loaded             : std_logic := '0';
  -- number of particles in local RAM
  signal  number_of_particles         : integer := 18;
  -- number of particles in total
  signal number_of_particles_in_total : integer := 18;
  -- index of first particles (the particles are sorted increasingly)
  signal start_particle_index         : integer := 0; 
  -- resampling function init
  signal U_init                       : integer := 2000;
  -- address of the last 128 byte burst in local RAM
  signal write_address                : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  -- information if a write burst has been handled by the Framework 
  signal write_burst_done             : std_logic := '0';
  -- the last burst from local RAM into Maim Memory 
  signal write_burst  :  std_logic := '0';
  -- number of currently written index values
  signal written_values : integer := 0;
  -- if every particle is resampled, this signal has to be set to '1'
  signal finished     :  std_logic := '0';
  
    
  -- for switch 1: corrected local ram address. the least bit is inverted, because else the local ram will be used incorrect
  signal o_RAMAddrUserProcess : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  -- for switch 1:corrected local ram address for this importance thread
  signal o_RAMAddrResampling : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  
  -- for switch 2: Write enable, user process
  signal o_RAMWEUserProcess : std_logic := '0';
  -- for switch 2: Write enable, importance
  signal o_RAMWEResampling : std_logic := '0';
  
  -- for switch 3: output ram data, user process
  signal o_RAMDataUserProcess : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
  -- for switch 3: output ram data, importance
  signal o_RAMDataResampling : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
    
  -- write burst done acknowledgement
  signal write_burst_done_ack : std_logic := '0';
    
  
begin

  -- entity of user process
  user_process : uf_resampling
     port map (reset=>reset, clk=>clk, o_RAMAddr=>o_RAMAddrUserProcess, o_RAMData=>o_RAMDataUserProcess, 
	            i_RAMData=>i_RAMData, o_RAMWE=>o_RAMWEUserProcess, o_RAMClk=>o_RAMClk,
	            init=>init, enable=>enable, particles_loaded=>particles_loaded,
					number_of_particles=>number_of_particles,
					number_of_particles_in_total => number_of_particles_in_total,
					start_particle_index=>start_particle_index,
					U_init=>U_init, write_address=>write_address,
					write_burst_done=>write_burst_done, write_burst=>write_burst,
					write_burst_done_ack=>write_burst_done_ack, written_values=>written_values,
					finished=>finished);

  -- burst ram interface 
  -- switch 1: address, correction is needed to avoid wrong addressing
  o_RAMAddr <= o_RAMAddrUserProcess(0 to C_BURST_AWIDTH-2) & not o_RAMAddrUserProcess(C_BURST_AWIDTH-1)
               when enable = '1' else o_RAMAddrResampling(0 to C_BURST_AWIDTH-2) & not o_RAMAddrResampling(C_BURST_AWIDTH-1);

  -- switch 2: write enable
  o_RAMWE <= o_RAMWEUserProcess when enable = '1' else o_RAMWEResampling;
  
  -- switch 3: output ram data
  o_RAMData <= o_RAMDataUserProcess when enable = '1' else o_RAMDataResampling;
  
  number_of_particles_in_total <= N;
  write_address <= "011111100000";

  -----------------------------------------------------------------------------
  --
  --  Reconos State Machine for Resampling: 
  --
  --  1) The index array adress, the number of particles (N) and
  --     the particle size is received by message boxes
  --
  --
  --  2) Waiting for Message m (Start of a Resampling run)
  --     Resample particles of m-th block
  --
  --
  --  3) calcualte the number of particles, which have to be resampled
  --
  --
  --  4) Copy the weight of the particles to the local RAM 
  --
  --
  --  5) The user resampling process is started
  --
  --
  --  6) Every time the user process demands to make a write burst into
  --     the index array, it is done by the Framework
  --
  --
  --  7) If the user process is finished go to step 8
  --
  --
  --  8) Send Message m (Stop of a Resampling run)
  --     Particles of m-th block are resampled
  --
  ------------------------------------------------------------------------------
  state_proc : process(clk, reset)
    
	 -- done signal for Reconos methods
	 variable done : boolean;
	 variable success : boolean;
	 
	 -- signals for N, particle_size and max number of particles which fit in the local RAM
	 variable N_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable particle_size_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	
	 variable U_init_var : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable message_var  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable block_size_var  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	
 	 variable resume_state_enc  : reconos_state_enc_t := (others => '0');
         variable preempted : boolean; 

  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      resume_state_enc := (others => '0');
      done    := false;
      success := false;
      preempted := false;
      state <= STATE_CHECK;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is


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
			  --! init state, receive particle array address
			   reconos_get_init_data_s (done, o_osif, i_osif, information_struct);
				-- CHANGE BACK !!! (1 of 3)
				--reconos_get_init_data_s (done, o_osif, i_osif, particle_array_address);
				enable <= '0';
				init <= '1';
                                if done then 
                                         --state <= STATE_READ_PARTICLES_ADDRESS;
					 state <= STATE_SEND_INFO_1;
					 -- CHANGE BACK !!! (2 of 3)
					 --state <= STATE_WAIT_FOR_MESSAGE;
                                end if;


		when STATE_SEND_INFO_1 =>
                          -- send particles array address
				 reconos_mbox_put(done,success,o_osif,i_osif,C_MB_MEASUREMENT,information_struct);
				 if (done and success) then
                                         state <= STATE_READ_PARTICLES_ADDRESS;				 
				 end if;


			when STATE_READ_PARTICLES_ADDRESS =>
			  --! read particle array address
			   reconos_read_s (done, o_osif, i_osif, information_struct, particle_array_start_address);
            if done then
					--state <= STATE_READ_INDEXES_ADDRESS;
					state <= STATE_SEND_INFO_2;
            end if;


		when STATE_SEND_INFO_2 =>
                          -- send particles array address
				 reconos_mbox_put(done,success,o_osif,i_osif,C_MB_MEASUREMENT,particle_array_start_address);
				 if (done and success) then

                                         state <= STATE_READ_INDEXES_ADDRESS;				 
				 end if;
	
	
			when STATE_READ_INDEXES_ADDRESS =>
			  --! read index array address
			   reconos_read_s (done, o_osif, i_osif, information_struct+4, index_array_start_address);
            if done then
					state <= STATE_READ_N;
            end if; 			
				

			 when STATE_READ_N =>
             --! read number of particles N
				reconos_read (done, o_osif, i_osif, information_struct+8, N_var);
            if done then
            	N <= TO_INTEGER(SIGNED(N_var));
					state <= STATE_READ_PARTICLE_SIZE;
            end if;	           
								
						
			 when STATE_READ_PARTICLE_SIZE =>
				--! read particle size
				reconos_read (done, o_osif, i_osif, information_struct+12, particle_size_var);
            if done then
            	particle_size <= TO_INTEGER(SIGNED(particle_size_var));
					state <= STATE_READ_BLOCK_SIZE;
            end if;					
								

			  when STATE_READ_BLOCK_SIZE =>
            --! read number of particles to resample
				reconos_read (done, o_osif, i_osif, information_struct+16, block_size_var);
            if done then
            	block_size <= TO_INTEGER(SIGNED(block_size_var));
					state <= STATE_READ_U_FUNCTION;
            end if;		


			  when STATE_READ_U_FUNCTION =>
            --! read start index of first particle to resample
				reconos_read_s (done, o_osif, i_osif, information_struct+20, U_array_start_address);
            if done then
			if preempted then
				preempted := false;
				state <= STATE_CALCULATE_REMAINING_PARTICLES_1;
			else
				state <= STATE_WAIT_FOR_MESSAGE;
			end if;
            end if;
			
				
				
          when STATE_WAIT_FOR_MESSAGE =>
			   --! wait for Message, that starts resampling
				reconos_mbox_get(done, success, o_osif, i_osif, C_MB_START, message_var);
				reconos_flag_yield(o_osif, i_osif, encode(STATE_WAIT_FOR_MESSAGE));
				if done then
					if success then
				   		message <= TO_INTEGER(SIGNED(message_var));
						--remaining_particles            <= number_of_particles_to_resample;
						--index_array_address    <= index_array_address;
						--particle_array_address <= particle_array_address;
						local_ram_address <= (others=>'0');
						local_ram_address_if_read <= (others=>'0');
						local_ram_address_if_write <= (others=>'0');
						init <= '1';
						enable <= '0';
						particles_loaded <= '0';
						if preempted then
							state <= STATE_INIT;
						else
							state <= STATE_CALCULATE_REMAINING_PARTICLES_1;
						end if;
						--time_start <= TO_INTEGER(SIGNED(i_timebase));
						-- CHANGE BACK !!! (3 of 3)
						--state <= STATE_NEEDED_BURSTS_1;

					else
						state <= STATE_EXIT;
					end if;
			   	end if;
				
				
		    when STATE_CALCULATE_REMAINING_PARTICLES_1 =>
			   --! calcualte remaining particles
				message2 <= message - 1;
				state <= STATE_CALCULATE_REMAINING_PARTICLES_2;
			
			
		    when STATE_CALCULATE_REMAINING_PARTICLES_2 =>
			   --! calcualte remaining particles
				offset <= message2 * block_size;
            temp2 <= message2 * 4;
				state <= STATE_CALCULATE_REMAINING_PARTICLES_3;
				
				
			when STATE_CALCULATE_REMAINING_PARTICLES_3 =>
			   --! calcualte remaining particles
				temp3 <= offset * 8;
				state <= STATE_CALCULATE_REMAINING_PARTICLES_4;

				
			when STATE_CALCULATE_REMAINING_PARTICLES_4 =>
			   --! calcualte remaining particles
				
				remaining_particles <= N - offset;
				index_array_address <= index_array_start_address + temp3;
            start_index <= offset;
				start_particle_index <= offset;
            temp4       <= offset * particle_size;		
            U_array_address     <= U_array_start_address + temp2;			
				state <= STATE_CALCULATE_REMAINING_PARTICLES_5;
				
				
			 when STATE_CALCULATE_REMAINING_PARTICLES_5 =>
			   --! calcualte remaining particles
				if (remaining_particles > block_size) then
				      number_of_particles_to_resample <= block_size;
					   remaining_particles             <= block_size;
				else
						number_of_particles_to_resample <= remaining_particles;
				end if;
				particle_array_address <= particle_array_start_address + temp4;
				state <= STATE_LOAD_U_INIT;
				
				
				
			 when STATE_LOAD_U_INIT =>
			   --! load U_init
				reconos_read (done, o_osif, i_osif, U_array_address, U_init_var);
            if done then
				    U_init <= TO_INTEGER(SIGNED(U_init_var));
			       state <= STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_1;
					 number_of_particles <= remaining_particles;
			   end if;


         when STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_1 =>
			  --! load weights to local ram, if this is done start the resampling
			  o_RAMWEResampling<= '0';
			  if (remaining_particles > 0) then
			  
			      remaining_particles <= remaining_particles - 1;
					state <= STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_2;
			  else
			      
					enable <= '1';
					particles_loaded <= '1';
					init <= '0';
			      state <= STATE_WRITE_BURST_DECISION;
			  end if;
			  
			  
			when STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_2 =>
			  --! load weights to local ram  
			  reconos_read_s (done, o_osif, i_osif, particle_array_address, weight_data);
            if done then
				    state <= STATE_WRITE_TO_RAM;
			       particle_array_address <= particle_array_address + particle_size;
			   end if;
				
				
		  when STATE_WRITE_TO_RAM =>
			   --! write value to ram
				o_RAMWEResampling<= '1';
				o_RAMAddrResampling <= local_ram_address_if_read;
				o_RAMDataResampling <= weight_data;
				local_ram_address_if_read <= local_ram_address_if_read + 1;
				state <= STATE_LOAD_WEIGHTS_TO_LOCAL_RAM_1;


		    when STATE_WRITE_BURST_DECISION =>
          --! if write burst is demanded by user process, it will be done
					write_burst_done <= '0';
					if (finished = '1') then
					
					    -- everything is finished
					    state <= STATE_SEND_MESSAGE;
						 enable <= '0';
						 particles_loaded <= '0';
						 --time_stop <= TO_INTEGER(SIGNED(i_timebase));
						 --init <= '1';
  
					elsif (write_burst = '1') then
					
					     --state <= STATE_WRITE_BURST;
						  state <= STATE_WRITE_BURST_DECISION_2;
					end if;
					
					
			 when STATE_WRITE_BURST_DECISION_2 =>
			   --! decides if there will be a burst or there will be several writes
				-- NO MORE BURSTS
			   --if (written_values = 16) then
				     -- write only burst, if the burst is full
				--     state <= STATE_WRITE_BURST;
				--else
				
				     local_ram_address_if_write <= write_address;
				     write_counter        <= 2 * written_values;
					  enable <= '0';
				     state  <= STATE_WRITE_DECISION;
				--end if;
			 
			 
		    when STATE_WRITE_BURST =>
            --! write bursts from local ram into index array
			 -- TODO: FIXME!!! WRITES COMMENTED OUT --- CHANGE CHANGE CHANGE
			 --reconos_write_burst(done, o_osif, i_osif, (local_ram_start_address + 8064), index_array_address);
  			 --if done then
					  
					        write_burst_done <= '1';
						index_array_address <= index_array_address + 128;
						state <= STATE_WRITE_BURST_DONE_ACK;
			 --end if;	
					
					
			 when STATE_WRITE_DECISION =>
			   -- decides if there is still something to write	   
				if (write_counter > 0) then	 
			 
			             o_RAMAddrResampling <= local_ram_address_if_write;
				     state <= STATE_READ;
				else
				     write_burst_done <= '1';
					  enable <= '1';
				     state <= STATE_WRITE_BURST_DONE_ACK;
				end if;
			 
	 
			 when STATE_READ =>
			   --! read index values
			   state <= STATE_WRITE;
			 
			 
			 when STATE_WRITE =>
				--! write data to index array
			        -- TODO: FIXME!!! WRITES COMMENTED OUT --- CHANGE CHANGE CHANGE
				reconos_write(done, o_osif, i_osif, index_array_address, i_RAMData);
			        if done then	
				    
					  index_array_address <= index_array_address + 4;
					  local_ram_address_if_write <= local_ram_address_if_write + 1;
					  write_counter <= write_counter - 1;
					  state <= STATE_WRITE_DECISION;
				end if;
					
					
					
		    when STATE_WRITE_BURST_DONE_ACK =>
            --! write bursts from local ram into index array
              if (write_burst_done_ack = '1') then
				  
				     write_burst_done <= '0';				    
					  state <= STATE_WRITE_BURST_DECISION;
				  end if;
				  
			  						  
          when STATE_SEND_MESSAGE =>
			   --! send Message (resampling is finished)
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
				 
				  --    time_measurement <= time_stop - time_start;
				  --    state <= STATE_SEND_MEASUREMENT_2;

				 --else
			         state <= STATE_WAIT_FOR_MESSAGE;
				 --end if;


           --when STATE_SEND_MEASUREMENT_2 =>
			    --! sends time measurement to message box
				 --  send message
				 --reconos_mbox_put(done, success, o_osif, i_osif, C_MB_MEASUREMENT, STD_LOGIC_VECTOR(TO_SIGNED(time_measurement, C_OSIF_DATA_WIDTH)));
				-- if (done and success) then

             --     state <= STATE_WAIT_FOR_MESSAGE;				 
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


