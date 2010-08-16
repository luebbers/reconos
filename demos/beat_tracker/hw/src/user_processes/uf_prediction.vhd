library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


---------------------------------------------------------------------------------
--
--     U S E R    F U N C T I O N :    P R E D I C T I O N
--
--
--    The particles are loaded into the local RAM by the Framework.
--    The 16kb local RAM is filled with as many particles as possible.
--    There will not be any space between the particles.
--
--    The user of the framework knows how a particle is defined and
--    he defines here, how the next state is going to be predicted.
--    In the end the user has to overwrite every particle with the
--    sampled particle.
--
--    If this has be done for every particle, the finshed signal
--    has to be set to '1'. A new run of the prediction will be
--    started if new particles are loaded to the local RAM and
--    the signal particles_loaded is equal to '1'.
--
--    Because this function depends on parameter, additional
--    parameter can be given to the framework, which copies
--    them into the first 128 byte of the local RAM.
--
------------------------------------------------------------------------------------

entity uf_prediction is

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

		init                         : in std_logic;
		enable                       : in std_logic;
		-- start signal for the prediction user process
		particles_loaded             : in std_logic;
		-- number of particles in local RAM
		number_of_particles          : in integer;
		-- size of one particle
		particle_size                : in integer;	 
		-- if every particle is sampled, this signal has to be set to '1'
		finished     : out std_logic
	);
end uf_prediction;

architecture Behavioral of uf_prediction is

	component pseudo_random is
	Port ( reset : in  STD_LOGIC;
		clk : in  STD_LOGIC;
		enable : in  STD_LOGIC;
		load : in  STD_LOGIC;
		seed : in  STD_LOGIC_VECTOR(31 downto 0);
		pseudoR : out  STD_LOGIC_VECTOR(31 downto 0));
	end component;

	-- GRANULARITY
	constant GRANULARITY :integer := 16384;
  
	-- handshake signals for processes
	--signal load_parameter_en  : std_logic := '0';
	--signal load_parameter_done  : std_logic := '0';
	signal sample_en  : std_logic := '0';
	signal sample_done  : std_logic := '0';
   
	-- burst ram interface access for processes
	signal o_RAMAddr_sample  : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	--signal o_RAMAddr_load_param  : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMWE_sample  : std_logic := '0';
  
	-- states
	type t_state is (
		initialize,
		--load_parameter,
		sample,
		finish
	);
	  
	-- current state
	signal state : t_state := initialize;
	
	-- needed for pseudo random entity
	signal enable_pseudo : std_logic := '0';
	signal load : std_logic := '0';
	signal seed : std_logic_vector(31 downto 0) := (others => '0');
	signal pseudoR : std_logic_vector(31 downto 0) := (others => '0');

	-- signals needed for beat tracking
	signal interval_min : std_logic_vector(0 to 31) := (others => '0');
	signal initial_phase : std_logic_vector(0 to 31) := (others => '0');	
	signal next_beat : std_logic_vector(0 to 31) := (others => '0');
	signal last_beat : std_logic_vector(0 to 31) := (others => '0');
	signal tempo : std_logic_vector(0 to 31) := (others => '0');	
	signal noise1 : std_logic_vector(0 to 3) := (others => '0');
	signal noise2 : std_logic_vector(0 to 5) := (others => '0');
	signal the_step : integer := 0;
  
begin

pseudo_r : pseudo_random
	port map (reset=>reset, clk=>clk, enable=>enable_pseudo, load=>load, seed=>seed, pseudoR=>pseudoR);

	-- burst ram interface
	o_RAMClk	<= clk;
	o_RAMWE		<= o_RAMWE_sample when sample_en = '1' else '0';
	o_RAMAddr	<= o_RAMAddr_sample when sample_en = '1' else (others=>'0');


---- loads parameter needed by sampling process
--load_parameter_proc : process(clk, reset, load_parameter_en)
--	variable step : natural range 0 to 3;
--begin
--
--	if reset = '1' or load_parameter_en = '0' then
--		load_parameter_done  <= '0';
--		step := 0;		
--	elsif rising_edge(clk) then
--		case step is 
--			
--			when 0 =>		
--				--! load parameter values
--				o_RAMAddr_load_param <= (others=>'0');	
--				step := step + 1;
--			 
--			when 1 =>
--				--!  wait one cycle
--				step := step + 1;
--
--			when 2 =>
--				--! load interval min (first 32 bits)
--				interval_min_addr(0 to 31) <= i_RAMData(0 to 31);
--				step := step + 1;
--			 
--			when 3 =>
--			        load_parameter_done <= '1';
--		end case;
--	end if;
--end process;


-- samples particles
sample_proc : process(clk, reset, sample_en)
	variable step : natural range 0 to 17;
	variable num : integer;
	variable particle_address : std_logic_vector(0 to C_BURST_AWIDTH-1);
	
begin
       
	if reset = '1' or sample_en = '0' then
		sample_done  <= '0';
		o_RAMWE_sample <= '0';
		o_RAMAddr_sample <= (others=>'0');
		o_RAMData <= (others=>'0');
		step := 0;
		the_step <= 0;		
	elsif rising_edge(clk) then
		the_step <= step;	
		case step is 
			
			when 0 =>
				--! how many particles need to be read?
				num := number_of_particles;
				particle_address := (others=>'0');
				step := step + 1;

			when 1 =>
				--! calcualte 1st particle address
				particle_address := particle_address + 32; -- 32*4 bytes for parameter
				step := step + 1;

			when 2 =>
				--! no more particles to process?
				if (num <= 0) then
					-- finished sampling
					step := 17;
				else
					-- more particles to process
					num := num - 1;
					step := step + 1;
				end if;

			when 3 =>		
				--! read particle data
				o_RAMAddr_sample <= particle_address + 2;	
				step := step + 1;
			 
			when 4 =>
				--!  wait one cycle
				o_RAMAddr_sample <= particle_address + 4;
				step := step + 1;

			when 5 =>
				--! read next beat position
				o_RAMAddr_sample <= particle_address + 5;
				next_beat <= i_RAMData;
				step := step + 1;
			 			 
			when 6 =>
				--! read tempo
				o_RAMAddr_sample <= particle_address + 6;
				tempo <= i_RAMData;
				step := step + 1;

			when 7 =>
				--! read interval_min
				initial_phase <= i_RAMData;
				step := step + 1;
				
			when 8 =>
				--! read interval_min
				interval_min <= i_RAMData;
				if (initial_phase > 0) then
					-- no samplig
					step := 17;
				else
					step := step + 1;
				end if;

			when 9 =>
				--! sampling needed (only if interval_min > next beat position)
				if (interval_min > next_beat) then
					-- sampling needed
					step := step + 1;
				else
					-- no (more) sampling needed
					step := step + 4; -- write value
				end if;

			when 10 =>
				--! update last beat
				last_beat(0 to 31) <= next_beat(0 to 31);
				noise1 (0 to 3) <= pseudoR(3)&pseudoR(2)&pseudoR(1)&pseudoR(0);
				step := step + 1;

			when 11 =>
				--! sample next beat
				next_beat(0 to 31) <= std_logic_vector(unsigned(next_beat) + unsigned(tempo));
				if (pseudoR(4)='1') then
					tempo(0 to 31) <= std_logic_vector(unsigned(tempo) + unsigned(noise1));
				else
					tempo(0 to 31) <= std_logic_vector(unsigned(tempo) - unsigned(noise1));
				end if;
				noise2 (0 to 5) <= pseudoR(5)&pseudoR(4)&pseudoR(3)&pseudoR(2)&pseudoR(1)&pseudoR(0);
				step := step + 1;
				

			when 12 =>
				--! add some noise
				if (pseudoR(6)='1') then
					next_beat(0 to 31) <= std_logic_vector(unsigned(next_beat) + unsigned(noise2));
				else
					next_beat(0 to 31) <= std_logic_vector(unsigned(next_beat) - unsigned(noise2));
				end if;
				step := step - 3;

			when 13 =>
				--! write sampled values: next beat
				o_RAMWE_sample <= '1';
				o_RAMAddr_sample <= particle_address + 2;
				o_RAMData <= next_beat;
				step := step + 1;

			when 14 =>
				--! write sampled values: last beat
				o_RAMWE_sample <= '1';
				o_RAMAddr_sample <= particle_address + 3;
				o_RAMData <= last_beat;
				step := step + 1;

			when 15 =>
				--! write sampled values: tempo
				o_RAMWE_sample <= '1';
				o_RAMAddr_sample <= particle_address + 4;
				o_RAMData <= tempo;
				step := step + 1;

			when 16 =>
				--! finished writing
				o_RAMWE_sample <= '0';
				particle_address := particle_address + particle_size;
				step := 2;
			 
			when 17 =>
				o_RAMWE_sample <= '0';
			        sample_done <= '1';
		end case;
         end if;
end process;


main_proc : process(clk, reset)
begin

	if (reset = '1') then
		seed <= X"7A3E0426";
		load <= '1';
		enable_pseudo <= '1';
		sample_en <= '0';
		--load_parameter_en <= '0';
		finished <= '0';
		state <= initialize;

	elsif rising_edge(clk) then
		enable_pseudo <= enable;
		load <= '0';
		if (init = '1') then
			finished <= '0';
			sample_en <= '0';
			--load_parameter_en <= '0';
			state <= initialize;			  
		elsif enable = '1' then
			case state is

				--! (1) initialize
				when initialize =>
					finished <= '0';
					sample_en <= '0';
					if (particles_loaded = '1') then
						--load_parameter_en <= '1';
						--state <= load_parameter;
						sample_en <= '1';
						state <= sample;
					end if;

--				--! (2) load parameter
--				when load_parameter =>
--					if (load_parameter_done = '1') then
--						load_parameter_en <= '0';
--						sample_en <= '1';
--						state <= sample;
--					end if;
	
				--! (3) sample data
				when sample =>
					finished <= '0';
					if (sample_done = '1') then
						sample_en <= '0';
						state <= finish;
					end if;
				
				--! (4) sampling finished
				when finish => 
					finished <= '1';
					if (particles_loaded = '1') then
						sample_en <= '1';
						state <= sample;
					end if;	

 				when others =>
					state <= initialize;
			end case;
		end if;
	end if;
 
end process;
end Behavioral;


