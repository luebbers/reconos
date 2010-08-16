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
  type t_state1 is (STATE_INIT,
     STATE_LOAD_PARTICLE_1, STATE_LOAD_PARTICLE_2, STATE_LOAD_WEIGHT, 
	  STATE_CALCULATE_REPLICATION_FACTOR_1, STATE_CALCULATE_REPLICATION_FACTOR_2,
	  STATE_CALCULATE_REPLICATION_FACTOR_3, STATE_CALCULATE_REPLICATION_FACTOR_4,
	  STATE_CALCULATE_REPLICATION_FACTOR_5, STATE_CALCULATE_REPLICATION_FACTOR_6,
	  STATE_WRITE_PARTICLE_INDEX, STATE_WRITE_PARTICLE_REPLICATION,
	  STATE_WRITE_BURST_DECISION, STATE_WRITE_BURST, STATE_WRITE_BURST_DONE_ACK,
	  STATE_WRITE_BURST_DONE_ACK_2, STATE_FINISH);
	  
	-- current state
   signal state1 : t_state1 := STATE_INIT;
  
  
begin

  -- burst ram interface is not used
  -- o_RAMAddr <= (others => '0');
  -- o_RAMData <= (others => '0');
  -- o_RAMWE   <= '0';
  o_RAMClk  <= clk;


  state_proc : process(clk, reset)

  begin

  if (reset = '1') then
 
		  state1 <= STATE_INIT;

  elsif rising_edge(clk) then
   if init = '1' then
	
	        state1    <= STATE_INIT;
			  o_RAMData <= (others=>'0');
			  o_RAMWE   <= '0';
			  o_RAMAddr <= (others => '0');
			  U         <= U_init;
			  
   elsif enable = '1' then
    case state1 is


        when STATE_INIT =>
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
			      
					state1 <= STATE_LOAD_PARTICLE_1;
			  end if;

		
		 -- 0) INIT
		 -- 
		 --    i = 0;   // current particle
		 --    j = 0;   // current replication factor
		 --    k = 0;   // current number of cloned particles
		 --    finished = 0;
		 -- 
       -- 
       -- 1) LOAD_PARTICLE_1/2, LOAD_WEIGHT
		 -- 
		 --    load weight of i-th particle from local memory
		 --    i ++;
		 --  
		 -- 
		 -- 2) CALCULATE_REPLICATION_FACTOR_1-8
		 -- 
		 --     calculate replication factor
		 -- 
		 -- 
		 -- 3) WRITE_PARTICLE_INDEX, WRITE_PARTICLE_REPLICATION
		 -- 
		 --    write particle index + replicationfactor to local ram
		 -- 
		 -- 
		 -- 4) WRITE_BURST
		 --
		 --    write_burst = 1;
		 --    if (write_burst_done)
		 --
		 --         write_burst = 0;
		 --         go to step 4
		 --
		 --
		 -- 5) FINISHED
		 -- 
		 --    finished = 1;
		 --    if (particles_loaded)
		 --         go to step 0;
		 
		
		  
		  when STATE_LOAD_PARTICLE_1 =>
		      --! load a particle
				write_burst <= '0';
				if (number_of_particles <= counter_resampled_particles) then
				      
						state1 <= STATE_WRITE_BURST_DECISION;
						
			   else
				
			         o_RAMAddr <= local_ram_read_address;
				      state1 <= STATE_LOAD_PARTICLE_2;
            end if;
 

		  when STATE_LOAD_PARTICLE_2 =>
				--!needed because reading from local RAM needs two clock steps
			   state1 <= STATE_LOAD_WEIGHT;				
		  
		  
		  when STATE_LOAD_WEIGHT =>
		     --! load particle weight
			   current_particle_weight <= TO_INTEGER(SIGNED(i_RAMData));
		      state1 <= STATE_CALCULATE_REPLICATION_FACTOR_1;
		  		  
		  

		  when STATE_CALCULATE_REPLICATION_FACTOR_1 =>
		    --! calculate replication factor (step 2/6)		  
          temp <= current_particle_weight * number_of_particles_in_total;
			 state1 <= STATE_CALCULATE_REPLICATION_FACTOR_2;
				  	  
		  		  
		  when STATE_CALCULATE_REPLICATION_FACTOR_2 =>
		    --! calculate replication factor (step 2/6)		  
          temp <= temp - U;
		    state1 <= STATE_CALCULATE_REPLICATION_FACTOR_3;	
		    
			 
		  when STATE_CALCULATE_REPLICATION_FACTOR_3 =>
		    --! calculate replication factor (step 3/6)		  
          fact <= temp + GRANULARITY;
			 state1 <= STATE_CALCULATE_REPLICATION_FACTOR_4;
				  
		  
		  when STATE_CALCULATE_REPLICATION_FACTOR_4 =>
		    --! calculate replication factor (step 4/6)		  
          fact <= fact / GRANULARITY;
			 state1 <= STATE_CALCULATE_REPLICATION_FACTOR_5;
		  
		  
		  when STATE_CALCULATE_REPLICATION_FACTOR_5 =>
		    --! calculate replication factor (step 5/6)
          U <= fact * GRANULARITY;
		    state1 <= STATE_CALCULATE_REPLICATION_FACTOR_6;

		  
		  when STATE_CALCULATE_REPLICATION_FACTOR_6 =>
		    --! calculate replication factor (step 6/6)
          U <= U - temp;
			 state1 <= STATE_WRITE_PARTICLE_INDEX;
			 -- todo: change back
			 --state1 <= STATE_WRITE_BURST_DECISION;
			 
			 
		  when STATE_WRITE_PARTICLE_INDEX =>
		    --! read particle from local ram
		    -- copy particle_size / 32 from local RAM to local RAM		        
			 o_RAMWE   <= '1';
			 o_RAMAddr <= local_ram_write_address;
			 o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(counter, C_BURST_DWIDTH));
			 local_ram_write_address <= local_ram_write_address + 1;
			 state1     <= STATE_WRITE_PARTICLE_REPLICATION;
		  
		  
		  when STATE_WRITE_PARTICLE_REPLICATION =>
			 --! needed because reading takes 2 clock steps	  		 
		    o_RAMWE   <= '1';
			 o_RAMAddr <= local_ram_write_address;
			 o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(fact, C_BURST_DWIDTH));
			 local_ram_write_address <= local_ram_write_address + 1;
			 write_counter <= write_counter + 1;
		    state1 <= STATE_WRITE_BURST_DECISION;
		  
		  
		  when STATE_WRITE_BURST_DECISION =>
		    --! write burst to main memory            
			 o_RAMWE   <= '0';
			 if (16 <= write_counter) then
				
			        -- write burst
					  state1 <= STATE_WRITE_BURST;
					  -- todo change back
					  --state1 <= STATE_WRITE_BURST_DECISION;
					  write_counter <= 0;
                 local_ram_write_address <= write_address;
					  written_values <= 16;
					  
			    elsif (number_of_particles <= counter_resampled_particles and write_counter > 0) then
				 
				      -- write burst
					   state1 <= STATE_WRITE_BURST;
					   --todo: changed back
						--state1 <= STATE_WRITE_BURST_DECISION;
						write_counter <= 0;
						--write_burst <= '1';
						written_values <= write_counter;
					  
			    elsif (number_of_particles <= counter_resampled_particles) then
				 
				     state1 <= STATE_FINISH;
					  
				 else
				     
					  -- get next particle
					  counter <= counter + 1;
					  counter_resampled_particles <= counter_resampled_particles + 1;
					  local_ram_read_address <= local_ram_read_address + 1;
					  state1 <= STATE_LOAD_PARTICLE_1;
					  
			end if;
		

		 when STATE_WRITE_BURST =>
			--! write burst to main memory	    
		   
			--write_burst <= '1';
			--written_values <= write_counter;
			--if (rising_edge (write_burst_done)) then
			write_burst <= '1';
			write_burst_done_ack <= '0';
			--change back
			--write_counter <= 0;
		   if (write_burst_done = '1') then
				     write_burst <= '0';
					  state1 <= STATE_WRITE_BURST_DONE_ACK;
			end if;
				 
				 
		 when STATE_WRITE_BURST_DONE_ACK =>
		   --! write burst to main memory
			write_burst_done_ack <= '1';
			write_counter <= 0;
			write_burst <= '0';
			if (write_burst_done = '0') then
			  
			      state1 <= STATE_WRITE_BURST_DONE_ACK_2;
			end if;
--			if (number_of_particles <= counter_resampled_particles) then
--					  
--				      state1 <= STATE_FINISH;
--			else
--                  --todo: changed for hopefully good
--				      --state1 <= STATE_LOAD_PARTICLE_1;
--				      state1 <= STATE_WRITE_BURST_DECISION;
--			end if;
				
				
		 when STATE_WRITE_BURST_DONE_ACK_2 =>
		   --! write burst to main memory
			write_burst_done_ack <= '0';
			if (number_of_particles <= counter_resampled_particles) then
					  
				      state1 <= STATE_FINISH;
			else
                  --todo: changed for hopefully good
				      --state1 <= STATE_LOAD_PARTICLE_1;
				      state1 <= STATE_WRITE_BURST_DECISION;
			end if;
				
				
				
		  when STATE_FINISH =>
		  --! write finished signal            
			 write_burst <= '0';
			 finished <= '1';
			 if (particles_loaded = '1') then
				   state1 <= STATE_INIT;
			 end if;		  
     


        when others =>
            state1 <= STATE_INIT;
    end case;
	end if;
  end if;
 
  end process;
end Behavioral;


