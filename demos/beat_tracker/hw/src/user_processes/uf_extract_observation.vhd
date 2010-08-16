library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;


---------------------------------------------------------------------------------
--
--     U S E R    F U N C T I O N :    E X T R A C T    O B S E R V A T I O N
--
--
--    The user function calcualtes a observation for a particle
--    A pointer to the input data is given. The user process can
--    ask for data at a specific address.
--
--    Thus, all needed data can be loaded into the entity. Thus, 
--    the observation can be calculated via input data. When no more
--    data is needed, the observation is stored into the local ram.
--
--    If the observation is stored in the ram, the finished signal has
--    to be set to '1'.
--
------------------------------------------------------------------------------------

entity uf_extract_observation is

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
		finished                     : out std_logic
	);
end uf_extract_observation;


architecture Behavioral of uf_extract_observation is

	-- fft component (uses radix-4 algorithm)
	component xfft_v5_0
	port (
		clk		: in std_logic;
		ce		: in std_logic;
		sclr		: in std_logic;
		start		: in std_logic;
		xn_re		: in std_logic_vector(15 downto 0);
		xn_im		: in std_logic_vector(15 downto 0);
		fwd_inv		: in std_logic;
		fwd_inv_we	: in std_logic;
		scale_sch	: in std_logic_vector(13 downto 0);
		scale_sch_we	: in std_logic;
		rfd		: out std_logic;
		xn_index	: out std_logic_vector(6 downto 0);
		busy		: out std_logic;
		edone		: out std_logic;
		done		: out std_logic;
		dv		: out std_logic;
		xk_index	: out std_logic_vector(6 downto 0);
		xk_re		: out std_logic_vector(15 downto 0);
		xk_im		: out std_logic_vector(15 downto 0)
		);
	end component;

	-- signals for fft core
	-- incoming signals
	signal ce		: std_logic := '0';
	signal sclr		: std_logic := '0';
	signal start		: std_logic := '0';
	signal xn_re		: std_logic_vector(15 downto 0) := (others => '0');
	signal xn_im		: std_logic_vector(15 downto 0) := (others => '0');
	signal fwd_inv		: std_logic := '1';
	signal fwd_inv_we	: std_logic := '0';
	signal scale_sch	: std_logic_vector(13 downto 0) := "01101010101010";
	signal scale_sch_we	: std_logic := '0';
	--outgoing signals
	signal rfd		: std_logic;
	signal xn_index		: std_logic_vector(6 downto 0);
	signal busy		: std_logic;
	signal edone		: std_logic;
	signal done		: std_logic;
	signal dv		: std_logic;
	signal xk_index		: std_logic_vector(6 downto 0);
	signal xk_re		: std_logic_vector(15 downto 0);
	signal xk_im		: std_logic_vector(15 downto 0);
	-- additional signals for fft
	signal my_xn_index	: std_logic_vector(6 downto 0);
	signal address : std_logic_vector(0 to C_BURST_AWIDTH-1);


	-- states
	type t_state is (initialize,
		load_parameter,
		initial_phase,
		interval,
		calc_start_index,
		get_measurement,
		calc_fft,
		write_no_tracking_needed,
 		finish
	);
	signal state : t_state := initialize;
	
	-- is a new observation required
	signal is_in_initial_phase	: std_logic := '0';
	signal is_in_interval		: std_logic := '1';
	signal no_tracking_is_needed	: std_logic := '0';

	-- handshake signals
	signal initial_phase_en			: std_logic := '0';
	signal initial_phase_done		: std_logic := '0';
	signal interval_en			: std_logic := '0';
	signal interval_done			: std_logic := '0';
	signal calc_start_index_en		: std_logic := '0';
	signal calc_start_index_done		: std_logic := '0';
	signal get_measurement_en		: std_logic := '0';
	signal get_measurement_done		: std_logic := '0';
	signal calc_fft_en			: std_logic := '0';
	signal calc_fft_done			: std_logic := '0';
	signal write_no_tracking_needed_en	: std_logic := '0';
	signal write_no_tracking_needed_done	: std_logic := '0';
	signal load_parameter_en		: std_logic := '0';
	signal load_parameter_done		: std_logic := '0';

	-- burst ram access for processes
	signal o_RAMAddr_initial	: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_interval	: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_get		: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_fft		: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_write		: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_param		: std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	signal o_RAMData_get		: std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
	signal o_RAMData_fft		: std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
	signal o_RAMData_write		: std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');

	signal o_RAMWE_get		: std_logic := '0';
	signal o_RAMWE_fft		: std_logic := '0';
	signal o_RAMWE_write		: std_logic := '0';

	signal observation_size		: integer := 130;
	signal measurement_size		: integer := 8192;
	signal start_index		: integer := 0;
	signal old_likelihood		: std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
	signal interval_min 		: std_logic_vector(0 to 31) := (others => '0');
	signal interval_max 		: std_logic_vector(0 to 31) := (others => '0');
	signal next_beat 		: std_logic_vector(0 to 31) := (others => '0');	
	

begin

	-- fft core
	my_fft_core : xfft_v5_0
		port map (
			clk	=> clk,
			ce	=> ce,
			sclr	=> sclr,
			start	=> start,
			xn_re	=> xn_re,
			xn_im	=> xn_im,
			fwd_inv	=> fwd_inv,
			fwd_inv_we	=> fwd_inv_we,
			scale_sch	=> scale_sch,
			scale_sch_we	=> scale_sch_we,
			rfd	=> rfd,
			xn_index	=> xn_index,
			busy	=> busy,
			edone	=> edone,
			done	=> done,
			dv	=> dv,
			xk_index	=> xk_index,
			xk_re	=> xk_re,
			xk_im	=> xk_im
		);


	-- burst ram interface
	o_RAMClk  <= clk;
	--o_RAMWE   <= o_RAMWE_write   when (write_no_tracking_needed_en='1') else o_RAMWE_fft;
	--o_RAMData <= o_RAMData_write when (write_no_tracking_needed_en='1') else o_RAMData_fft;  
	--ce <= enable;

--! multiplexer for local ram address (outgoing signals)
mux_proc : process(calc_fft_en, initial_phase_en, interval_en, write_no_tracking_needed_en, 
	get_measurement_en, load_parameter_en, o_RAMAddr_get, o_RAMAddr_param,
	o_RAMAddr_initial, o_RAMAddr_interval, o_RAMAddr_fft, o_RAMAddr_write,
	o_RAMWE_get, o_RAMWE_fft, o_RAMWE_write, o_RAMData_get, o_RAMData_fft, o_RAMData_write 
	)

begin
	if (calc_fft_en='1') then
		o_RAMAddr <= o_RAMAddr_fft;
		o_RAMData <= o_RAMData_fft;
		o_RAMWE   <= o_RAMWE_fft;
	elsif (get_measurement_en='1') then
		o_RAMAddr <= o_RAMAddr_get;
		o_RAMData <= o_RAMData_get;
		o_RAMWE   <= o_RAMWE_get;
	elsif (initial_phase_en='1') then
		o_RAMAddr <= o_RAMAddr_initial;
		o_RAMData <= (others=>'0');
		o_RAMWE   <= '0';
	elsif (interval_en='1') then
		o_RAMAddr <= o_RAMAddr_interval;
		o_RAMData <= (others=>'0');
		o_RAMWE   <= '0';
	elsif (write_no_tracking_needed_en='1') then
		o_RAMAddr <= o_RAMAddr_write;
		o_RAMData <= o_RAMData_write;
		o_RAMWE   <= o_RAMWE_write;
	elsif (load_parameter_en='1') then
		o_RAMAddr <= o_RAMAddr_param;
		o_RAMData <= (others=>'0');
		o_RAMWE   <= '0';
	else
		o_RAMAddr <= (others=>'0');
		o_RAMData <= (others=>'0');
		o_RAMWE   <= '0';
	end if;
end process;



-- (2) loads parameter: observation size
load_parameter_proc : process(clk, reset, load_parameter_en)
	variable step : natural range 0 to 6;

	
begin

	if reset = '1' or load_parameter_en = '0' then
		load_parameter_done <= '0';
		o_RAMAddr_param <= (others=>'0');
		step := 0;		
	elsif rising_edge(clk) then
		case step is 
			 
			when 0 =>
				--!  get size parameter
				o_RAMAddr_param <= (others=>'0');
				step := step + 1;

			when 1 =>
				--! wait one cycle
				o_RAMAddr_param <= o_RAMAddr_param + 1;
				step := step + 1;

			when 2 =>
				--! read real and imaginary value
				measurement_size <= to_integer(signed(i_RAMData));
				step := step + 1;

			when 3 =>
				--! read real and imaginary value
				observation_size <= to_integer(signed(i_RAMData));
				step := step + 1;

			when 4 =>
				measurement_size <= measurement_size / 4;
				step := step + 1;

			when 5 =>
				observation_size <= observation_size / 4;
				step := step + 1;

			when 6 =>
				--! finished
				load_parameter_done <= '1';
		end case;
	end if;
end process;


-- (3) checks, if tracker is in initial phase
initial_phase_proc : process(clk, reset, initial_phase_en)
	variable step : natural range 0 to 5;
	variable initial_phase_data : integer := 0;
	variable current_particle_address2 : std_logic_vector(0 to C_BURST_AWIDTH-1);

	
begin

	if reset = '1' or initial_phase_en = '0' then
		initial_phase_done <= '0';
		o_RAMAddr_initial <= (others=>'0');
		step := 0;		
	elsif rising_edge(clk) then
		case step is 
			
			when 0 =>		
				--! set address 
				current_particle_address2 := (others=>'0');
				step := step + 1;
			 
			when 1 =>
				--!  
				o_RAMAddr_initial <= current_particle_address2 + 5;
				step := step + 1;

			when 2 =>
				--! wait one cycle
				step := step + 1;

			when 3 =>
				--! get data
				initial_phase_data := to_integer(signed(i_RAMData));
				step := step + 1;

			when 4 =>
				--! set initial phase signal
				if (initial_phase_data > 0) then
					is_in_initial_phase <= '1';
				else
					is_in_initial_phase <= '0';
				end if;
				step := step + 1;

			when 5 =>
				--! finished
			        initial_phase_done <= '1';
		end case;
	end if;
end process;


-- (4) checks, if tracker is in interval 
interval_proc : process(clk, reset, interval_en)
	variable step : natural range 0 to 9;
	
begin

	if reset = '1' or interval_en = '0' then
		interval_done <= '0';
		o_RAMAddr_interval <= (others=>'0');
		step := 0;		
	elsif rising_edge(clk) then
		case step is 

			when 0 =>		
				--! set address 
				o_RAMAddr_interval <= (others=>'0');
				step := step + 1;
			 
			when 1 =>
				--!  
				o_RAMAddr_interval <= o_RAMAddr_interval + 1;
				step := step + 1;

			when 2 =>
				--! wait one cycle
				o_RAMAddr_interval <= o_RAMAddr_interval + 1;
				step := step + 1;

			when 3 =>
				--! get old likelihood
				old_likelihood(0 to 31) <= i_RAMData(0 to 31);
				o_RAMAddr_interval <= o_RAMAddr_interval + 4;
				step := step + 1;

			when 4 =>
				--! get data
				o_RAMAddr_interval <= o_RAMAddr_interval + 1;
				next_beat(0 to 31) <= i_RAMData(0 to 31);
				step := step + 1;

			when 5 =>
				--! get data
				interval_min(0 to 31) <= i_RAMData(0 to 31);
				step := step + 1;

			when 6 =>
				--! get data
				interval_max(0 to 31) <= i_RAMData(0 to 31);
				step := step + 1;

			when 7 =>
				--! check interval boundaries: min
				if (interval_min <= next_beat) then
					step := step + 1;
				else
					is_in_interval <= '0';
					step := step + 2;
				end if;

			when 8 =>
				--! check interval boundaries: max
				if (next_beat <= interval_max) then
					is_in_interval <= '1';
				else
					is_in_interval <= '0';
				end if;
				step := step + 1;

			when 9 =>
				--! finished
				interval_done <= '1';
		end case;
	end if;
end process;



-- (5) calculates start index for measurement
calc_start_index_proc : process(clk, reset, calc_start_index_en)
	variable step : natural range 0 to 7;
	variable difference : std_logic_vector(0 to 31);
	variable start_max : integer;
	
begin

	if reset = '1' or calc_start_index_en = '0' then
		calc_start_index_done <= '0';
		step := 0;		
	elsif rising_edge(clk) then
		case step is 

			when 0 =>		
				--! calcualte difference
				difference(0 to 31) := std_logic_vector(unsigned(next_beat) - unsigned(interval_min));
				step := step + 1;
				
			when 1 => 
				--! wait
				step := step + 1;

			when 2 =>		
				--! convert to integer
				start_index <= to_integer(unsigned(difference(0 to 31)));
				step := step + 1;

			when 3 => 
				--! wait
				step := step + 1;			

			when 4 =>		
				--! convert to integer
				start_index <= start_index / 4;
				step := step + 1;

			when 5 =>		
				--! convert to integer
				if (start_index < 0) then
					start_index <= 0;
				end if;
				start_max := measurement_size - 64; -- fft expects 128 values a 2 bytes = 64*4 bytes
				step := step + 1;		

			when 6 =>		
				--! convert to integer
				if (start_index > start_max) then -- 
					start_index <= start_max;
				end if;
				step := step + 1;		

			when 7 =>
				--! finished
				calc_start_index_done <= '1';
		end case;
	end if;
end process;


-- (6) gets measurement and writes it into local ram (starting at "100000000000")
get_measurement_proc : process(clk, reset, get_measurement_en)
	variable step : natural range 0 to 11;
	variable i : natural;
	variable address2 : std_logic_vector(0 to 31);
	variable address_offset : natural;
	
begin

	if reset = '1' or get_measurement_en = '0' then
		word_data_ack <= '0';
		o_RAMWE_get <= '0';
		input_data_needed <= '0';
		get_measurement_done <= '0';
		step := 0;		
	elsif rising_edge(clk) then
		case step is 

			when 0 =>		
				--! init
				i := 0;
				o_RAMWE_get <= '0';
				word_data_ack <= '0';
				input_data_needed <= '0';
				address_offset := 4*start_index;
				step := step + 1;		

			when 1 =>
				step := step + 1;
				
			when 2 =>				
				address2 := input_data_address + address_offset;
				step := step + 1;

			when 3 =>		
				--! init
				if (i < 64) then -- 128 samples a 2 byte = 64 * 4 bytes
					step := step + 1;
				else
					-- done
					step := 11;
				end if;

			when 4 =>
				--! start loop body
				-- ask framework for data
				-- TODO (1/2): CHANGE CHANGE CHANGE - BACK
				address_offset := 4*i;
				step := step + 1;

			when 5 =>
				step := step + 1;

			when 6 =>
				input_data_needed <= '1';
				word_address <= address2 + address_offset;
				step := step + 1;				

			when 7 =>
				--! wait for data
				-- TODO (2/2): CHANGE CHANGE CHANGE - BACK
				if (word_data_en='1') then
					input_data_needed <= '0';
					step := step + 1;
				end if;
				
			when 8 =>
				--! wait
				step := step + 1;

			when 9 =>
				--! write date to local ram and acknowledge data
				o_RAMWE_get	<= '1';
				o_RAMAddr_get	<= "100000000000" + i;
				-- reverse byte order
				o_RAMData_get(0 to 31) <= word_data(8 to 15)&word_data(0 to 7)&
								word_data(24 to 31)&word_data(16 to 23);
								
				-- TODO: CHANGE CHANGE CHANGE - BACK
				--o_RAMAddr_get	<= "000000000000" + i;
				--o_RAMData_get(0 to 31) <= word_data(0 to 31);
				word_data_ack <= '1';
				step := step + 1;

			when 10 =>
				--! end of loop body
				word_data_ack <= '0';
				o_RAMWE_get <= '0';
				i := i + 1;
				step := 1;	 

			when 11 =>
				--! finished
				get_measurement_done <= '1';
		end case;
	end if;
end process;


-- (7) calculates fast fourier transformation
--  fast fourier transformation (fft) of '128' samples (format: 16 bit wide, signed)
--  output: '128' FFT VALUES
--          - real component      (format: 16 bit wide, signed (?))
--          - imaginary component (format: 16 bit wide, signed (?)) 
calc_fft_proc : process(clk, reset, calc_fft_en)
	variable step : natural range 0 to 9;

	
begin

	if reset = '1' or calc_fft_en = '0' then
		calc_fft_done <= '0';
		start	<= '0';
		o_RAMWE_fft	<= '0';
		xn_im	<= (others=>'0');
		xn_re	<= (others=>'0');
		ce 	<= '0';
		fwd_inv	<= '1';
		sclr	<= '1'; -- TRY THIS
		step := 0;		
	elsif rising_edge(clk) then
		case step is 			 

			when 0 => 
				--! fill fft core with data
				-- set start signal
				sclr	<= '0';	
				ce	<= '1';					
				fwd_inv	<= '1';
				fwd_inv_we <= '1';
				o_RAMWE_fft <= '0';
				o_RAMAddr_fft <= "100000000000";
				address <= "100000000000";
				xn_im    <= (others=>'0');
				step := step + 1;

			when 1 => 
				--! set start signal				
				start	<= '1';
				fwd_inv_we <= '0';
				o_RAMWE_fft <= '0';
				my_xn_index <= xn_index;					
				step := step + 1;

			when 2 => 
				--! start filling the incoming data pipeline 
				-- (read left sample (16 of 32 bits));	
				xn_re(15 downto 0) <= i_RAMData(16)&i_RAMData(17)&i_RAMData(18)&i_RAMData(19)&i_RAMData(20)&i_RAMData(21)&i_RAMData(22)&i_RAMData(23)&i_RAMData(24)&i_RAMData(25)&i_RAMData(26)&i_RAMData(27)&i_RAMData(28)&i_RAMData(29)&i_RAMData(30)&i_RAMData(31);
				o_RAMAddr_fft <= address + 1;
				address <= address + 1;
				step := step + 1;

			when 3 =>
				--! start filling the incoming data pipeline
				-- (read right sample (16 of 32 bits));
				xn_re(15 downto 0) <= i_RAMData(0)&i_RAMData(1)&i_RAMData(2)&i_RAMData(3)&i_RAMData(4)&i_RAMData(5)&i_RAMData(6)&i_RAMData(7)&i_RAMData(8)&i_RAMData(9)&i_RAMData(10)&i_RAMData(11)&i_RAMData(12)&i_RAMData(13)&i_RAMData(14)&i_RAMData(15);
				my_xn_index <= xn_index + 1;
				step := step + 1;

			when 4 => 
				--! samples are arriving (read left sample (16 of 32 bits))	
				start <= '0';	
				xn_re(15 downto 0) <= i_RAMData(16)&i_RAMData(17)&i_RAMData(18)&i_RAMData(19)&i_RAMData(20)&i_RAMData(21)&i_RAMData(22)&i_RAMData(23)&i_RAMData(24)&i_RAMData(25)&i_RAMData(26)&i_RAMData(27)&i_RAMData(28)&i_RAMData(29)&i_RAMData(30)&i_RAMData(31);
				my_xn_index <= xn_index + 1;
				o_RAMAddr_fft <= address + 1; 
				address <= address + 1;
				step := step + 1;

			when 5 => 
				--! samples are arriving (read right sample (16 of 32 bits));
				xn_re(15 downto 0) <= i_RAMData(0)&i_RAMData(1)&i_RAMData(2)&i_RAMData(3)&i_RAMData(4)&i_RAMData(5)&i_RAMData(6)&i_RAMData(7)&i_RAMData(8)&i_RAMData(9)&i_RAMData(10)&i_RAMData(11)&i_RAMData(12)&i_RAMData(13)&i_RAMData(14)&i_RAMData(15);
				if (busy='0') then
					my_xn_index <= xn_index + 1;
					step := step - 1;
				else					
					step := step + 1;
				end if;

			when 6 =>
				--! wait for results
				if (edone = '1') then
					o_RAMAddr_fft <= address - 1;
					address <= address - 1;
					start <= '1';
					o_RAMWE_fft <= '0';
					step := step + 1;
				end if;				

			when 7 =>
				--! get data and write them back
				--o_RAMData_fft(0 to 31) <= xk_re(15 downto 0) & xk_im(15 downto 0);
				o_RAMData_fft(0 to 31) <= xk_re(15)&xk_re(14)&xk_re(13)&xk_re(12)&xk_re(11)&xk_re(10)&xk_re(9)&xk_re(8)&xk_re(7)&xk_re(6)&xk_re(5)&xk_re(4)&xk_re(3)&xk_re(2)&xk_re(1)&xk_re(0)&xk_im(15)&xk_im(14)&xk_im(13)&xk_im(12)&xk_im(11)&xk_im(10)&xk_im(9)&xk_im(8)&xk_im(7)&xk_im(6)&xk_im(5)&xk_im(4)&xk_im(3)&xk_im(2)&xk_im(1)&xk_im(0);
				--o_RAMAddr_fft(0 to 11) <= "0" & xk_index(10 downto 0);
				o_RAMAddr_fft(0 to 11) <= "00000"&xk_index(6)&xk_index(5)&xk_index(4)&xk_index(3)&xk_index(2)&xk_index(1)&xk_index(0);
				o_RAMWE_fft <= '1';	
				if (busy='1') then				
					step := step + 1;
				end if;

			when 8 =>
				--o_RAMData_fft(0 to 31) <= xk_re(15 downto 0) & xk_im(15 downto 0);
				o_RAMData_fft(0 to 31) <= xk_re(15)&xk_re(14)&xk_re(13)&xk_re(12)&xk_re(11)&xk_re(10)&xk_re(9)&xk_re(8)&xk_re(7)&xk_re(6)&xk_re(5)&xk_re(4)&xk_re(3)&xk_re(2)&xk_re(1)&xk_re(0)&xk_im(15)&xk_im(14)&xk_im(13)&xk_im(12)&xk_im(11)&xk_im(10)&xk_im(9)&xk_im(8)&xk_im(7)&xk_im(6)&xk_im(5)&xk_im(4)&xk_im(3)&xk_im(2)&xk_im(1)&xk_im(0);
				--o_RAMAddr_fft(0 to 11) <= "0" & xk_index(10 downto 0);
				o_RAMAddr_fft(0 to 11) <= "00000"&xk_index(6)&xk_index(5)&xk_index(4)&xk_index(3)&xk_index(2)&xk_index(1)&xk_index(0);
				if (dv='0') then
					o_RAMWE_fft <= '0';			
					step := step + 1;
				else
					o_RAMWE_fft <= '1';
				end if;

			when 9 =>
				--! finish fft process
				o_RAMWE_fft	<= '0';	
				start		<= '0';	
				sclr		<= '1';			
				calc_fft_done	<= '1';
		end case;
	end if;
end process;


-- (8)  writes no_tracking_needed information
write_no_tracking_needed_proc : process(clk, reset, write_no_tracking_needed_en)
	variable step : natural range 0 to 4;
	variable current_observation_address : std_logic_vector(0 to C_BURST_AWIDTH-1);
	
begin

	if reset = '1' or write_no_tracking_needed_en = '0' then
		write_no_tracking_needed_done <= '0';
		o_RAMAddr_write <= (others=>'0');
		o_RAMWE_write <= '0';
		step := 0;		
	elsif rising_edge(clk) then
		case step is 

			when 0 =>		
				--! init
				current_observation_address := (others=>'0');
				o_RAMWE_write <= '0';
				step := step + 1;

			when 1 =>		
				--! calc address
				current_observation_address := current_observation_address + observation_size;
				step := step + 1;

			when 2 =>		
				--! write old likelihood
				o_RAMWE_write	<= '1';
				o_RAMAddr_write <= current_observation_address - 2;
				o_RAMData_write <= old_likelihood;
				step := step + 1;

			when 3 =>		
				--! write no tracking is needed information
				o_RAMWE_write	<= '1';
				o_RAMAddr_write <= current_observation_address - 1;
				o_RAMData_write <= "0000000000000000000000000000000"&no_tracking_is_needed;
				step := step + 1;		 

			when 4 =>
				--! finished
				o_RAMWE_write <= '0';
				write_no_tracking_needed_done <= '1';
		end case;
	end if;
end process;




----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- 
--  (1) initialize, finished = '0'  (if new_particle = '1')
--  
--  (2) load parameter (observation size)
--
--  (3) check, if tracker in initial phase
--      yes: no tracking needed go to step 7 
--      no:  go to step 4
--
--  (4) check, if estimated beat in current interval
--      yes: go to step 5
--      no:  no tracking needed go to step 7 
--
--  (5) calculate start index
--
--  (6) get measurement
--
--  (7) calculate fft
--
--  (8) write information: no_tracking_is_needed (0/no or 1/yes)
--
--  (9) finished = '1', wait for new_particle = '1'
--  
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

main_proc : process(clk, reset)
begin

	if (reset = '1') then
		new_particle_ack  <= '0';
		finished <= '0';
		state <= initialize;

	elsif rising_edge(clk) then
		if init = '1' then
			state <= initialize;
			no_tracking_is_needed <= '0';
			finished <= '0';
           	  
   		elsif enable = '1' then
			case state is

			when initialize =>
				--! (1) init data
				finished <= '0';
				parameter_loaded_ack <= '0';
				no_tracking_is_needed <= '0';
				if (new_particle = '1') then
					new_particle_ack <= '1';
					initial_phase_en <= '1';
					state <= initial_phase;
				elsif (parameter_loaded = '1') then
					load_parameter_en <= '1';
					state <= load_parameter;
				end if;

			when load_parameter =>
				--! (2) calculates start index position in measurement
				if (load_parameter_done = '1') then
					parameter_loaded_ack <= '1';
					load_parameter_en <= '0';
					state <= initialize;
				end if;

			when initial_phase =>
				--! (3) check if tracker is in initial phase
				new_particle_ack <= '0';
				if (initial_phase_done = '1') then
					initial_phase_en <= '0';
					if (is_in_initial_phase='1') then
						no_tracking_is_needed <= '1';
						write_no_tracking_needed_en <= '1';
						state <= write_no_tracking_needed;
					else
						no_tracking_is_needed <= '0';
						interval_en <= '1';
						state <= interval;
					end if;
				end if;

			when interval =>
				--! (4) check if tracker is in current interval
				if (interval_done = '1') then
					interval_en <= '0';
					if (is_in_interval='1') then
						no_tracking_is_needed <= '0';
						calc_start_index_en <= '1';
						state <= calc_start_index;
					else
						no_tracking_is_needed <= '1';
						write_no_tracking_needed_en <= '1';
						state <= write_no_tracking_needed;
					end if;
				end if;

			when calc_start_index =>
				--! (5) calculates start index position in measurement
				if (calc_start_index_done = '1') then
					calc_start_index_en <= '0';
					get_measurement_en <= '1';
					state <= get_measurement;
					--calc_fft_en <= '1';
					--state <= calc_fft;
				end if;

			when get_measurement =>
				--! (6) gets needed part of measurement via framework
				if (get_measurement_done = '1') then
					get_measurement_en <= '0';
					--write_no_tracking_needed_en <= '1';
					--state <= write_no_tracking_needed;
					calc_fft_en <= '1';
					state <= calc_fft;
				end if;

			when calc_fft =>
				--! (7) calculates fft from framework
				if (calc_fft_done = '1') then
					calc_fft_en <= '0';
					write_no_tracking_needed_en <= '1';
					state <= write_no_tracking_needed;
				end if;

			when write_no_tracking_needed =>
				--! (8) writes no_tracking_need_information into observation
				if (write_no_tracking_needed_done = '1') then
					write_no_tracking_needed_en <= '0';
					state <= finish;
				end if;

			when finish =>
				--! (9) write finished signal
				finished <= '1';
				if (new_particle = '1') then
					state <= initialize;
				end if;

			when others =>
				state <= initialize;
			end case;
		end if;
	end if;

end process;
end Behavioral;

