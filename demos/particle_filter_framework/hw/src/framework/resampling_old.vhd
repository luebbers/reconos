library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.STD_LOGIC_ARITH.all;
--use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v1_03_a;
use reconos_v1_03_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity resampling is

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
    o_RAMClk  : out std_logic
    );
end resampling;

architecture Behavioral of resampling is

  attribute keep_hierarchy               : string;
  attribute keep_hierarchy of Behavioral : architecture is "true";

  -- resources:
    -- semaphores
  constant C_SEM_WAIT : std_logic_vector(0 to 31) := X"00000000";
  constant C_SEM_POST : std_logic_vector(0 to 31) := X"00000001";
    -- message box
  constant C_MB_START : std_logic_vector(0 to 31) := X"00000002";
  
  constant GRANULARITY :integer := 16384;

  -- states
  type t_state is (STATE_INIT, STATE_GET_MB, STATE_READ_N_1, STATE_READ_N_2,
     STATE_READ_PARTICLE_SIZE_1, STATE_READ_PARTICLE_SIZE_2,
     STATE_SEM_WAIT, STATE_LOAD_PARTICLE, STATE_LOAD_W, STATE_CALCULATE_BEST_PARTICLE,
     STATE_RESAMPLING, STATE_LOAD_WEIGHT, STATE_CALCULATE_CLONE_FACTOR_1,
	  STATE_CALCULATE_CLONE_FACTOR_2, STATE_CALCULATE_CLONE_FACTOR_3, STATE_CALCULATE_CLONE_FACTOR_4,
	  STATE_CLONE_PARTICLE, STATE_CLONE_PARTICLE_READ, STATE_CLONE_PARTICLE_WRITE,
	  STATE_CORRECTION_READ, STATE_CORRECTION, STATE_CORRECTION_WRITE, STATE_SEM_POST);

  -- current state
  signal state : t_state := STATE_SEM_WAIT;
  
  -- input, output
  signal in_value : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal out_value : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- particle array
  signal particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
  signal current_particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- old particle array
  signal old_particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
  signal current_old_particle_array_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- local RAM address
  signal local_ram_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  -- message box
  signal mb_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  -- number of particles (set by message box, default = 100)
  signal N : integer := 100;
  
  -- size of a particle
  signal particle_size : integer := 128;
  
  -- particle counter
  signal counter : integer;
  
  -- particle counter for clone factor
  signal counter_clone_factor : integer;
  
  -- particle counter for cloned particles at all
  signal counter_cloned_particles : integer;
  
  -- current particle weight
  signal current_particle_weight : integer;
  
  -- sum of particle weights
  signal sum_of_particle_weights : integer;
  
  -- current clone factor
  signal current_clone_factor : integer;
  
  -- best particle
  signal best_particle_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
  signal highest_particle_weight : integer;
  
  --signal init_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  
  
  
begin

  -- burst ram interface is not used
  o_RAMAddr <= (others => '0');
  o_RAMData <= (others => '0');
  o_RAMWE   <= '0';
  o_RAMClk  <= clk;


  state_proc : process(clk, reset)
    
	 -- done signal for Reconos methods
	 variable done : boolean;

    -- success signal for Reconos method, which gets a message box
	 variable success : boolean;
	 
	 -- signals for particle weight, N, particle_size and old_particle_array_address
	 variable particle_weight_sig : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable N_sig : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	 variable particle_size_sig : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	
	 variable old_particle_array_address_sig : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');	 
	 --variable factor : integer;
	 
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
			   reconos_get_init_data_s (done, o_osif, i_osif, particle_array_address);
            if done then 
                state <= STATE_GET_MB;
					 --state <= STATE_SEM_WAIT;
            end if;
	
	
			when STATE_GET_MB =>
			  --! receive message box
            --reconos_mbox_get_s(done, success, o_osif, i_osif, C_MB_START, mb_address);
				reconos_mbox_get_s(done, success, o_osif, i_osif, C_MB_START, old_particle_array_address);
            if done then
				    --old_particle_array_address <= mb_address;
                state <= STATE_READ_N_1;
            end if;				
				

			 when STATE_READ_N_1 =>
            --! read variable N (= # of particles)
            reconos_mbox_get_s (done, success, o_osif, i_osif, C_MB_START, mb_address);
            if done then
					state <= STATE_READ_N_2;
            end if;
				
				
		    when STATE_READ_N_2 =>
            --! read variable N (= # of particles)
				reconos_read (done, o_osif, i_osif, mb_address, N_sig);
            if done then
            	N <= TO_INTEGER(SIGNED(N_sig));
					state <= STATE_READ_PARTICLE_SIZE_1;
            end if;
				
						
			 when STATE_READ_PARTICLE_SIZE_1 =>
            --! read particle size
            reconos_mbox_get_s (done, success, o_osif, i_osif, C_MB_START, mb_address);
            if done then
					state <= STATE_READ_PARTICLE_SIZE_2;
            end if;		
				
				
			 when STATE_READ_PARTICLE_SIZE_2 =>
            --! read particle size
				reconos_read (done, o_osif, i_osif, mb_address, particle_size_sig);
            if done then
            	particle_size <= TO_INTEGER(SIGNED(particle_size_sig));
					state <= STATE_SEM_WAIT;
            end if;	
				

          when STATE_SEM_WAIT =>
			   --! wait for semaphore
            reconos_sem_wait (o_osif, i_osif, C_SEM_WAIT);
            state <= STATE_LOAD_PARTICLE;
				--state <= STATE_SEM_POST;


          when STATE_LOAD_PARTICLE =>
			  --! set current array addresses to the first elements in the arrays
			      -- and init sum of weights
              current_old_particle_array_address <= old_particle_array_address;
				  current_particle_array_address <= particle_array_address;
				  --sum_of_particle_weights <= 0;
				  counter <= 0;
				  highest_particle_weight <= 0;
				  best_particle_address <= old_particle_array_address;
              state <= STATE_LOAD_W;
				  --state <= STATE_RESAMPLING;


          when STATE_LOAD_W =>
			   --! load weight of current particle
            reconos_read(done, o_osif, i_osif, current_old_particle_array_address, particle_weight_sig);
            if done then
              state <= STATE_CALCULATE_BEST_PARTICLE;
				  current_particle_weight <= TO_INTEGER(SIGNED(particle_weight_sig));
				  counter <= counter + 1;
            end if;
				
				
		     when STATE_CALCULATE_BEST_PARTICLE =>
			  --! calculate the sum of all particle weights
				  --sum_of_particle_weights <= sum_of_particle_weights + current_particle_weight;
				  
				  if (current_particle_weight > highest_particle_weight) then
						 -- remember best position 
					    highest_particle_weight <= current_particle_weight;
					    best_particle_address <= current_old_particle_array_address;
				  end if;
						 
				  if (counter < N) then
						 current_old_particle_array_address <= current_old_particle_array_address + particle_size;
				       state <= STATE_LOAD_W;
				  else
				       state <= STATE_RESAMPLING;
						 --state <= STATE_SEM_POST;
				  end if;
				  
				  
			 -- 
			 -- THE RESAMPLING PART IN DETAIL  
			 -- 
			 -- 0) STATE_RESAMPLING: 
			 -- 
			 --    init addresses and counter
			 --    i = 0;  // old_particles
			 --    k = 0;  // particles
			 -- 
			 -- 
			 -- 1) STATE_LOAD_WEIGHT: 
			 -- 
			 --    load weight of i-th old particle
			 --    i++
			 -- 
			 -- 
			 -- 2) STATE_CALCULATE_CLONE_FACTOR
			 -- 
			 --    calculate clone factor = round (w * N / sum_weights)
			 --    j = 0;   // clone factor counter
			 -- 
			 -- 
			 -- 3) STATE_CLONE_PARTICLE
			 -- 
			 --    if (i > N) then
			 --
			 --        if (k < N) then
			 --            go to step 6  // not enough particles cloned, but no more old particles
			 --        else			 
			 --        		go to end	  // enough particles cloned 
			 --        end if			 
			 --
			 --	 elsif (N <= k) then
			 --          
			 --			 go to end       // enough particles cloned
			 --
			 --    elsif (clone_factor <= j)
			 --   
			 --          go to step 1    // no more cloning needed for this particle, get next
			 --
			 --    elsif (j < clone_factor)
			 --
			 --          if (j == 0) 
			 -- 
			 --              go to step 4    // first load particle to local RAM
			 --
			 --          else  
			 --
			 --              go to step 5    // particle allready loaded to local RAM 
			 --
			 --          end if
			 --
			 --    end if
			 -- 
			 -- 
			 -- 4) STATE_CLONE_PARTICLE_READ
			 -- 
			 --    read old particle [i] to local RAM
			 -- 
			 -- 
			 -- 5) STATE_CLONE_PARTICLE_WRITE
			 -- 
			 --    write local RAM to particle [k]
			 --    k++
			 --    j++
			 --    go to step 3
			 -- 			 
			 -- 
			 -- 6) STATE_CORRECTION_READ
			 -- 
			 -- 	 read best particle to local RAM
			 -- 
			 -- 			 
			 -- 7) STATE_CORRECTION
			 -- 
			 --    if (k <= N) then
			 --       go to step 8
			 --    else
			 --       go to end
			 --    end if
			 -- 
			 -- 
			 -- 8) STATE_CORRECTION_WRITE
			 -- 
			 --      write best particle to particles[k];
			 --      k++;
			 --      go to step 7
				  
				  
          when STATE_RESAMPLING =>
			  --! init counter and array addresses
              current_old_particle_array_address <= old_particle_array_address;
				  current_particle_array_address <= particle_array_address;
				  counter <= 0;
				  counter_cloned_particles <= 0;
              state <= STATE_LOAD_WEIGHT;
				  
				  
          when STATE_LOAD_WEIGHT =>
			   --! load weight of current particle
            reconos_read(done, o_osif, i_osif, current_old_particle_array_address, particle_weight_sig);
            if done then
              state <= STATE_CALCULATE_CLONE_FACTOR_1;
				  current_particle_weight <= TO_INTEGER(SIGNED(particle_weight_sig));
				  counter <= counter + 1;
            end if;


          when STATE_CALCULATE_CLONE_FACTOR_1 =>
			   --! calculate the factor the current particle has to be cloned
              current_clone_factor <= 2 * N * current_particle_weight;
				  state <= STATE_CALCULATE_CLONE_FACTOR_2;
				  
				  
		   when STATE_CALCULATE_CLONE_FACTOR_2 =>
			   --! calculate the factor the current particle has to be cloned
				  current_clone_factor <= current_clone_factor / GRANULARITY;
				  state <= STATE_CALCULATE_CLONE_FACTOR_3;
				
				
          when STATE_CALCULATE_CLONE_FACTOR_3 =>
			   --! calculate the factor the current particle has to be cloned
				  current_clone_factor <= current_clone_factor + 1;
				  state <= STATE_CALCULATE_CLONE_FACTOR_4;
	
	
          when STATE_CALCULATE_CLONE_FACTOR_4 =>
			   --! calculate the factor the current particle has to be cloned
				  current_clone_factor <= current_clone_factor / 2;
				  counter_clone_factor <= 0;
				  state <= STATE_CLONE_PARTICLE;				  
				
		     when STATE_CLONE_PARTICLE =>
			  --! clone partice as often as needed
			  
			  if (counter > N) then
			     
				  if (counter_cloned_particles < N) then
				     -- there are not enough clones, so correct it
				     state <= STATE_CORRECTION_READ;
				     --state <= STATE_SEM_POST;
				  
				  else
                 -- everything finished, because there are enough clones
                 state <= STATE_SEM_POST;

				  end if;
				  
			  elsif (N <= counter_cloned_particles) then
			  
			     -- everything finished, because there are enough clones
              state <= STATE_SEM_POST;
			  				  
			  elsif (current_clone_factor <= counter_clone_factor) then
			  
			     -- get next particle 
				  state <= STATE_LOAD_WEIGHT;
				  current_old_particle_array_address <= current_old_particle_array_address + particle_size;
			  
			  elsif (counter_clone_factor < current_clone_factor) then
			    
				  if (counter_clone_factor = 0) then
                 -- first load the particle to local RAM
				     state <= STATE_CLONE_PARTICLE_READ;
				  
				  else
				     -- later, the particles can be just written
				     state <= STATE_CLONE_PARTICLE_WRITE;
				  end if;
				 
			  end if;


          when STATE_CLONE_PARTICLE_READ =>
			  --! load old particles [counter] to local RAM
			  reconos_read_burst(done, o_osif, i_osif, local_ram_address, current_old_particle_array_address);
           if done then
              state <= STATE_CLONE_PARTICLE_WRITE;			  
            end if;
			  
			  
          when STATE_CLONE_PARTICLE_WRITE =>
			  --! write particles [counter_cloned_particles] from RAM
           reconos_write_burst(done, o_osif, i_osif, local_ram_address, current_particle_array_address);
           if done then
              state <= STATE_CLONE_PARTICLE;
				  counter_clone_factor <= counter_clone_factor + 1;
				  counter_cloned_particles <= counter_cloned_particles + 1;
				  current_particle_array_address <= current_particle_array_address + particle_size;
           end if;

			  
			  when STATE_CORRECTION_READ =>
           --! load best particle

              --reconos_read_burst(done, o_osif, i_osif, local_ram_address, old_particle_array_address);
              reconos_read_burst(done, o_osif, i_osif, local_ram_address, best_particle_address);
				  if done then
				       state <= STATE_CORRECTION;
              end if;
			  


			  when STATE_CORRECTION =>
			  --! if less than N particles are cloned, clone another particle (the best one)
			  if (counter_cloned_particles <= N) then
               -- write correction
					state <= STATE_CORRECTION_WRITE;
			  else
			  	  
			     -- correction finished, N particles are cloned
			     state <= STATE_SEM_POST;
			  end if;
			  
			  
			 when STATE_CORRECTION_WRITE =>
			 --! CLONE PARTICLE
			 -- particles_array[counter_cloned_particles] <= old_particle_array[best]
			 	--PUT IT AWAY
				--reconos_write_burst(done, o_osif, i_osif, local_ram_address, current_particle_array_address);
            if done then
                  state <= STATE_CORRECTION;
						counter_cloned_particles <= counter_cloned_particles + 1;
					   current_particle_array_address <= current_particle_array_address + particle_size;
            end if;						
				  						  
    
          when STATE_SEM_POST =>
            reconos_sem_post (o_osif, i_osif, C_SEM_POST);
            state <= STATE_SEM_WAIT;


          when others =>
            state <= STATE_SEM_WAIT;
        end case;
      end if;
    end if;
  end process;
end Behavioral;


