library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;


---------------------------------------------------------------------------------
--
--     U S E R    F U N C T I O N :    L I K E L I H O O D
--
--
--    One observation and the reference data are loaded into the
--    local RAM by the framework. The start addresses of this
--    observations will be set as input from the Framework.
--
--    The user of the framework knows how a observation is defined.
--    The user defines how to calculate the likelihood between the
--    observation and the reference data.
--
--    If the likelihood is calculated, the finished signal has to
--    be set to '1' and the likelihood value has to be set as ouput.
--
------------------------------------------------------------------------------------

entity uf_likelihood is

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

		-- init signal
		init                         : in std_logic;
		-- enable signal
		enable                       : in std_logic;
		-- start signal for the likelihood user process
		observation_loaded           : in std_logic;
		-- address of reference data
		ref_data_address    : in std_logic_vector(0 to C_BURST_AWIDTH-1);
		-- address of observation
		observation_address : in std_logic_vector(0 to C_BURST_AWIDTH-1);
		-- size of one observation
		observation_size             : in integer;

		-- if the likelihood is calculated, this signal has to be set to '1'
		finished         : out std_logic;
		likelihood_value : out integer
	);
end uf_likelihood;

architecture Behavioral of uf_likelihood is

component square_root_component
	port (
		x_in  : in std_logic_VECTOR(31 downto 0);
		nd    : in std_logic;
		x_out : out std_logic_VECTOR(16 downto 0);
		rdy   : out std_logic;
		--rfd   : out std_logic;
		clk   : in std_logic;
		ce    : in std_logic);
end component;


	-- GRANULARITY
	constant GRANULARITY : integer := 16384;
   
	-- signals for likelihood values
	signal likelihood        : integer := 0;
	signal old_likelihood    : integer := 0;
  
 
	-- states
	type t_state is (initialize,
		no_tracking_needed,
		calc_likelihood,
		load_old_likelihood,
		finish
	);
	  
	-- current state
	signal state : t_state := initialize;

	-- handshake signals
	signal calc_likelihood_en	: std_logic := '0';
	signal calc_likelihood_done	: std_logic := '0';
	signal no_tracking_needed_en		: std_logic := '0';
	signal no_tracking_needed_done	: std_logic := '0';
	signal load_old_likelihood_en	: std_logic := '0';
	signal load_old_likelihood_done	: std_logic := '0';
	
	-- signals for square root component
	signal x_in2 : natural := 0;
	signal x_in  : std_logic_vector(31 downto 0) := (others => '0');
	signal x_out : std_logic_vector(16 downto 0) := (others => '0');
	signal x_out2: natural := 0;
	signal nd    : std_logic := '0';
	signal rdy   : std_logic := '1';
	--signal rfd   : std_logic := '1';
	signal ce    : std_logic := '1';

	signal current_observation_address : std_logic_vector(0 to C_BURST_AWIDTH-1);
	signal max_frequency : integer := 0;
	signal max_amplitude : integer := 0;
	signal amplitude : integer := 0;
	signal tmp_im : integer := 0;
	signal tmp_re : integer := 0;
	signal re : integer := 0;
	signal im : integer := 0;
	signal counter : integer := 0;
	signal length1 : integer := 0;

	-- '1' if no tracking is required, '0' else
	signal no_tracking_is_needed : std_logic := '0';
	signal no_tracking_needed_data : integer := 0;

	-- burst ram connectors for processes
	signal o_RAMAddr_calc		: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_tracking	: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_load		: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	-- step for simulation
	signal the_step : integer := 0;
  
begin

	--! square root calculation
	square_root: square_root_component
		port map (x_in => x_in, nd => nd, x_out => x_out,
			rdy => rdy, --rfd => rfd, 
			clk => clk, ce => ce);



	-- burst ram interface
	o_RAMClk	<= clk;
	o_RAMWE		<= '0';
	o_RAMData	<= (others=>'0');

--! multiplexer for local ram address (outgoing signal)
mux_proc : process(calc_likelihood_en, no_tracking_needed_en, load_old_likelihood_en,
	o_RAMAddr_calc, o_RAMAddr_tracking, o_RAMAddr_load
	)

begin
	if (calc_likelihood_en='1') then
		o_RAMAddr <= o_RAMAddr_calc;
	elsif (no_tracking_needed_en='1') then
		o_RAMAddr <= o_RAMAddr_tracking;
	elsif (load_old_likelihood_en='1') then
		o_RAMAddr <= o_RAMAddr_load;
	else
		o_RAMAddr <= (others=>'0');
	end if;
end process;



-- checks, if tracker is in no_tracking_needed
no_tracking_needed_proc : process(clk, reset, no_tracking_needed_en)
	variable step : natural range 0 to 5;
	variable current_observation_address2 : std_logic_vector(0 to C_BURST_AWIDTH-1);
	--variable no_tracking_needed_data : integer;
	
begin

	if reset = '1' or no_tracking_needed_en = '0' then
		no_tracking_needed_done <= '0';
		o_RAMAddr_tracking  <= (others=>'0');
		--the_step <= 0;
		step := 0;		
	elsif rising_edge(clk) then
		if (enable = '1') then
		--the_step <= step;
		case step is 
			
			when 0 =>		
				--! set address
				current_observation_address2 := observation_address + observation_size;
				step := step + 1;
			 
			when 1 =>
				o_RAMAddr_tracking <= current_observation_address2 - 1;
				step := step + 1;

			when 2 =>
				--! wait one cycle
				step := step + 1;

			when 3 =>
				--! no tracking needed information
				no_tracking_needed_data <= to_integer(signed(i_RAMData));
				step := step + 1;

			when 4 =>
				--! set no_tracking_needed signal
				if (no_tracking_needed_data > 0) then
					no_tracking_is_needed <= '1';
				else
					no_tracking_is_needed <= '0';
				end if;
				step := step + 1;

			when 5 =>
				--! finished
				no_tracking_needed_done <= '1';
		end case;
		end if;
	end if;
end process;



--! loads old likelihood
load_old_likelihood_proc : process(clk, reset, load_old_likelihood_en)
	variable step : natural range 0 to 4;
	variable current_observation_address2 : std_logic_vector(0 to C_BURST_AWIDTH-1);
	
begin

	if reset = '1' or load_old_likelihood_en = '0' then
		load_old_likelihood_done <= '0';
		o_RAMAddr_load	<= (others=>'0');
		step := 0;		
	elsif rising_edge(clk) then
		if (enable = '1') then
		case step is 
			
			when 0 =>		
				--! load observation length
				current_observation_address2 := observation_address + observation_size;
				step := step + 1;
			 
			when 1 =>
				--!  get initial phase data
				o_RAMAddr_load <= current_observation_address2 - 2;
				step := step + 1;

			when 2 =>
				--! wait one cycle
				step := step + 1;

			when 3 =>
				--! read real and imaginary value
				old_likelihood <= to_integer(signed(i_RAMData));
				step := step + 1;

			when 4 =>
				--! finished
				load_old_likelihood_done <= '1';
		end case;
		end if;
	end if;
end process;




-- calculates likelihood
calc_likelihood_proc : process(clk, reset, calc_likelihood_en)
	variable step : natural range 0 to 20;
	
begin

	if (reset = '1' or calc_likelihood_en = '0') then
		calc_likelihood_done <= '0';
		o_RAMAddr_calc	<= (others=>'0');
		step := 0;		
		the_step <= step;
	elsif (rising_edge(clk)) then
		if (enable = '1') then
		the_step <= step;
		case step is 
			
			when 0 =>		
				--! load observation length
				current_observation_address <= observation_address;
				length1 <= observation_size - 2;
				max_amplitude <= 0;
				max_frequency <= 0;
				counter <= 0;
				step := step + 1;
			 
			when 1 =>
				--!  get next fft value
				o_RAMAddr_calc <= current_observation_address;
				step := step + 1;

			when 2 =>
				--! wait one cycle
				step := step + 1;

			when 3 =>
				--! read real and imaginary value
				re <= to_integer(signed(i_RAMData( 0 to 15)));
				im <= to_integer(signed(i_RAMData(16 to 31)));
				step := step + 1;
				
			when 4 =>
				--! wait
				step := step + 1;

			when 5 => 
				--! square real values
				tmp_re <= re * re;
				step := step + 1;
				
			when 6 =>
				--! wait a state between two multiplications
				step := step + 1;
				
			when 7 =>
				--! wait a state between two multiplications
				step := step + 1;

			when 8 =>
				--! square imaginary values
				tmp_im <= im * im;
				step := step + 1;
				
			when 9 =>
				--! wait a state between before the result is needed
				step := step + 1;		

			when 10 =>
				--! wait a state between before the result is needed
				step := step + 1;					
			
			when 11 =>
				--! add tmp results (= squared amplitude)
				amplitude <= tmp_re + tmp_im;
				step := step + 1;
				
			when 12 =>
				--! wait a state between before the result is needed
				step := step + 1;					

			when 13 =>
				--! calc squareroot, more fft values?
				if (amplitude > max_amplitude) then
					max_amplitude <= amplitude;
					max_frequency <= counter;
				end if;
				if (counter < length1 - 1) then
					-- load next value
					current_observation_address <= current_observation_address + 1;
					counter <= counter + 1;
					step := 1;
				else
					step := step + 1;
				end if;

			when 14 =>
				--! set likelihood
				if ((max_frequency > 0) and (max_frequency < 29)) then --for length1=128
					-- calculate sqrt
					x_in2 <= max_amplitude;
					step := step + 1;					
				else
					likelihood <= 5;
					step := step + 6;
				end if;

			when 15 =>
				-- put value into sqrt component
				x_in <= std_logic_vector(to_unsigned(x_in2, 32));
				nd   <= '1';
				step := step + 1;

			when 16 =>
				-- wait for result
				nd <= '0';
				if (rdy='1') then
					step := step + 1;
				end if;

			when 17 =>
				-- put result to likelihood
				x_out2 <= to_integer(unsigned(x_out));
				step := step + 1;
				
			when 18 =>
				-- wait
				step := step + 1;			

			when 19 =>
				-- likelihood = sqrt(max_amplitude)
				likelihood <= x_out2;
				step := step + 1;


--			when 13 =>
--				--! set likelihood
--				if ((max_frequency > 0) and (max_frequency < 29)) then
--					likelihood <= max_amplitude;				
--				else
--					likelihood <= 5;
--				end if;
--				step := 15;
--				
--			when 14 =>
--				step := step + 1;
--
--			when 15 =>
--				step := step + 1;
--
--			when 16 =>
--				step := step + 1;
--
--			when 17 =>
--				step := step + 1;
--				-- end debug
			 
			when 20 =>
				--! finished
				calc_likelihood_done <= '1';
		end case;
		end if;
	end if;
end process;


----------------------------------------------------------------------
----------------------------------------------------------------------
--
-- Likelihood calculation
--
-- (1) Initialize
-- 
-- (2) check, if Beat tracker is needs to track (calc likelihood)
--     yes: go to step 3
--     no:  go to step 4
-- 
-- (3) calculate likelihood, go to step 5
-- 
-- (4) load old likelihood value
-- 
-- (5) give back likelihood value, finish
-- 
----------------------------------------------------------------------
----------------------------------------------------------------------

	ce <= enable;

state_proc : process(clk, reset)

begin

	if (reset = '1') then
		state <= initialize;
		finished <= '0';

	elsif rising_edge(clk) then
		if init = '1' then
			finished <= '0';
			state <= initialize;
	  
		elsif enable = '1' then
			case state is

			when initialize =>
				--! initialize
				finished <= '0';
				if (observation_loaded = '1') then
					no_tracking_needed_en <= '1';
					state <= no_tracking_needed;
				end if;

			when no_tracking_needed =>
				--! check if tracker is in initial state
				if (no_tracking_needed_done = '1') then
					no_tracking_needed_en <= '0';
					if (no_tracking_is_needed='1') then
						load_old_likelihood_en <= '1';
						state <= load_old_likelihood;
					else
						calc_likelihood_en <= '1';
						state <= calc_likelihood;
					end if;
				end if;

			when calc_likelihood =>
				--! calculate likelihood
				if (calc_likelihood_done = '1') then
					calc_likelihood_en <= '0';
					likelihood_value <= likelihood;
					state <= finish;
				end if;

			when load_old_likelihood =>
				--! load old likelihood
				if (load_old_likelihood_done = '1') then
					load_old_likelihood_en <= '0';
					likelihood_value <= old_likelihood;
					state <= finish;
				end if;

			when finish =>
				--! write finished signal and likelihood value
				finished <= '1';
				if (observation_loaded = '1') then
					state <= initialize;
				end if;	

			when others =>
				state <= initialize;
			end case;
		end if;
	end if;
 
end process;
end Behavioral;


