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
    C_TASK_BURST_AWIDTH : integer := 11;
    C_TASK_BURST_DWIDTH : integer := 32
    );

  port (
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
end uf_extract_observation;


architecture Behavioral of uf_extract_observation is

component pipelined_divider
	port (
	clk:  in std_logic;
	ce:   in std_logic;
	aclr: in std_logic;	
	sclr: in std_logic;
	dividend: in std_logic_VECTOR(31 downto 0);
	divisor:  in std_logic_VECTOR(31 downto 0);
	quot: out std_logic_VECTOR(31 downto 0);
	remd: out std_logic_VECTOR(31 downto 0);
	rfd:  out std_logic);
end component;


  type hsv_function is array ( 0 to 255) of integer;

  -- GRANULARITY
  constant GRAN_EXP : integer := 14;
  constant GRANULARITY : integer := 2**GRAN_EXP;
  
  constant hd_values : hsv_function := (
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
     1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
     2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	  4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
	  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
	  6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 
	  7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
	  8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
	  9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
     9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	  9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	  9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	  9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	  9, 9, 9, 9);
	  
   constant sdvd_values : hsv_function := (
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
     0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
     1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,	  
	  2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	  3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 
	  4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 
	  5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 
	  6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 
	  7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 
	  8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	  9, 9, 9, 9, 9, 9);  

  -- states
  type t_state is (STATE_INIT, STATE_READ_PARAMETER, STATE_INIT_HISTOGRAM,
                  STATE_READ_PARTICLE, STATE_ANALYZE_PARTICLE,
		            STATE_CALCULATE_HISTOGRAM, STATE_NORMALIZE_HISTOGRAM,
						STATE_COPY_HISTOGRAM, STATE_FINISH);
  signal state : t_state;
  
  -----------------------------------------------------
  -- signals needed for divider component
  ----------------------------------------------------- 
  -- clock enable
  signal ce : std_logic;
  -- synchronous clear
  signal sclr : std_logic := '0';
  -- asynchronous clear
  signal aclr : std_logic := '0';
  -- dividend
  signal dividend : std_logic_vector(31 downto 0)  := (others => '0');
  -- divisor
  signal divisor : std_logic_vector(31 downto 0)   := "00000000000000000000000000000001";
    -- quotient
  signal quotient : std_logic_vector(31 downto 0)  := (others => '0');  
  -- remainder
  signal remainder : std_logic_vector(31 downto 0) := (others => '0');
  -- ready for data
  signal rfd : std_logic;
  
  
  -- local ram address for interface
  signal local_ram_address_if : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  signal local_ram_start_address_if : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  
  
  
  -- HSV signals
  signal H  : std_logic_vector(0 to 7) := (others => '0');
  signal S  : std_logic_vector(0 to 7) := (others => '0');
  signal V  : std_logic_vector(0 to 7) := (others => '0');
  
  constant S_THRESH : integer := 25;
  constant V_THRESH : integer := 50;
  
  signal hd : natural range 0 to 9 := 0;
  signal sd : natural range 0 to 9 := 0;
  signal vd : natural range 0 to 9 := 0;
  signal value : natural := 0;  
  
  	-- copy histogram
	signal copy_histo_en     : std_logic := '0'; -- handshake signal
	signal copy_histo_done   : std_logic := '0'; -- handshake signal
	signal copy_histo_addr   : std_logic_vector(C_TASK_BURST_AWIDTH-1 downto 0); -- burst ram addr
	signal copy_histo_bucket : std_logic_vector(6 downto 0); -- histogram addr
	signal copy_histo_data   : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');  
  
  	-- update histogram
	signal update_histo_en     : std_logic := '0'; -- handshake signal
	signal update_histo_done   : std_logic := '0'; -- handshake signal
	signal update_histo_addr   : std_logic_vector(C_TASK_BURST_AWIDTH-1 downto 0); -- burst ram addr
	signal update_histo_bucket : std_logic_vector(6 downto 0); -- histogram addr
	
  	-- calculate histogram
	signal calculate_histo_en     : std_logic := '0'; -- handshake signal
	signal calculate_histo_done   : std_logic := '0'; -- handshake signal	
	
  	-- clear histogram
	signal clear_histo_en     : std_logic := '0'; -- handshake signal
	signal clear_histo_done   : std_logic := '0'; -- handshake signal
	signal clear_histo_bucket : std_logic_vector(6 downto 0) := (others => '0'); -- histogram addr  
	
	-- normalize histogram
	signal normalize_histo_en     : std_logic := '0'; -- handshake signal
	signal normalize_histo_done   : std_logic := '0'; -- handshake signal
	signal normalize_histo        : std_logic := '0'; -- set histo_ram value
	signal normalize_histo_value  : std_logic_vector(31 downto 0) := (others=>'0'); -- new normalized histo value
	signal normalize_histo_bucket : std_logic_vector(6 downto 0) := (others => '0'); -- histogram addr  
	
   -- read particle data
   signal read_particle_en     : std_logic := '0'; -- handshake signal
   signal read_particle_done   : std_logic := '0'; -- handshake signal   
   signal read_particle_addr   : std_logic_vector(C_TASK_BURST_AWIDTH-1 downto 0) := (others=>'0');
	
   -- read parameter 
   signal read_parameter_en     : std_logic := '0'; -- handshake signal
   signal read_parameter_done   : std_logic := '0'; -- handshake signal   
   signal read_parameter_addr   : std_logic_vector(C_TASK_BURST_AWIDTH-1 downto 0) := (others=>'0');	

   -- analyze particle
   signal analyze_particle_en     : std_logic := '0'; -- handshake signal
   signal analyze_particle_done   : std_logic := '0'; -- handshake signal

   -- prefetch line
   signal prefetch_line_en      : std_logic := '0'; -- handshake signal
   signal prefetch_line_done    : std_logic := '0'; -- handshake signal
	signal prefetch_line_address : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1); 
	
   -- histogram
   type t_ram is array (109 downto 0) of std_logic_vector(31 downto 0);
   signal histo_ram    : t_ram; -- histogram memory
   signal histo_bucket : std_logic_vector(6 downto 0); -- current histogram bucket
   signal histo_inc    : std_logic := '0'; -- enables incrementing
   signal histo_clear  : std_logic := '0'; -- enables setting to zero
   signal histo_value  : std_logic_vector(31 downto 0); -- value of current bucket
	
	-- particle data
	signal x : integer := 0;
	signal y : integer := 0;
	signal scale : integer := 0;
	signal width  : integer := 0;
	signal height : integer := 0;
	
	-- input data
	-- left upper corner
   signal x1 : integer := 0;
	signal y1 : integer := 0;
	-- right bottom corner
   signal x2 : integer := 0;
	signal y2 : integer := 2;
   -- current pixel	
   signal px : integer := 0;
	signal py : integer := 0;
	
	-- frame values
	signal size_x : integer := 480;
	signal size_y : integer := 360;

   -- temporary signals
   signal temp_x : integer := 0;
   signal temp_y : integer := 0;	
   signal temp : integer := 0;		
	
	-- input data offset
	signal get_data_offset : integer := 0;
	

	-- number of lines
	signal number_of_lines : integer := 0;	
	
	-- length of line
	signal line_length : integer := 0;
	
	-- sum of histogram
	signal sum : integer := 0;
	
	-- signal for counter
	signal i : integer := 0;
	signal j : integer := 0;
	
	
	
begin

  divider : pipelined_divider
  port map ( clk => clk, ce => ce, aclr => aclr, sclr => sclr, dividend => dividend,
   		    	divisor => divisor, quot => quotient, remd => remainder, rfd => rfd);


  -- burst ram interface
  o_RAMClk  <= clk;
  
  ce <= enable;
  
  


-- histogram memory is basically a single port ram with
	-- asynchronous read. the current bucket is incremented each
	-- clock cycle when histo_inc is high, or set to zero when
	-- histo_clear is high.
	-- @author: Andreas Agne, changed by Markus Happe
	histo_value <= histo_ram(CONV_INTEGER(histo_bucket));
	histo_ram_proc : process(clk)
	begin
		if rising_edge(clk) then
		   -- TRY: CLOCKED VERSION
		   --histo_value <= histo_ram(CONV_INTEGER(histo_bucket));
			if histo_inc = '1' then
			   histo_ram(TO_INTEGER(UNSIGNED(histo_bucket))) <= histo_ram(CONV_INTEGER(histo_bucket)) + 1;
			elsif histo_clear = '1' then
				histo_ram(TO_INTEGER(UNSIGNED(histo_bucket))) <= (others=>'0');
			elsif normalize_histo = '1' then
            histo_ram(TO_INTEGER(UNSIGNED(histo_bucket))) <= normalize_histo_value;			
			end if;
		end if;
	end process;
	
	
	-- calculate histogram. Prefetch line. Parallel execution of 
	-- line prefetching (framwork) and histogram calculation (user proc.)
  	calc_histo_proc : process(clk, reset, calculate_histo_en)
		variable step  : natural range 0 to 5;
	begin
		if reset = '1' or calculate_histo_en = '0' then
			step := 0;
		   prefetch_line_en     <= '0';
		   update_histo_en      <= '0';		
			calculate_histo_done <= '0';
		elsif rising_edge(clk) then
			case step is
            -- (i)   prefetch 1st line
            -- (ii)  prefetch next line and update histogram for current line
            -- (iii)	update histogram for last line
				
				when 0 =>
				-- prefetch first line
				   prefetch_line_en <= '1';
					update_histo_en  <= '0';
					number_of_lines <= 1 + y2 - y1;
					py    <= y1;
				   step := step + 1;
					
				when 1 =>
				-- prefetch first line completed
				   if (prefetch_line_done = '1') then   
					    prefetch_line_en <= '0';
						 number_of_lines  <= number_of_lines - 1;
                   step  := step  + 1;						 
					end if;
					
				when 2 => 
				 -- update histogram start
				   update_histo_en  <= '1';
					step := step + 1;					

				when 3 => 
				 -- update histogram stop
				  if (update_histo_done = '1') then   
					    update_histo_en <= '0';
						 step  := step + 1;				 
					end if; 	

            when 4 =>
               -- more lines?
               if (number_of_lines <= 0) then
                    step  := step + 1;
               else
                    step := step - 3;
					     prefetch_line_en <= '1';
						  py <= py + 1;
               end if;				
					
--				when 2 =>
--				  -- start parallel execution, or start last update
--                if (number_of_lines <= 0) then
--						-- last line allready prefetched
--						update_histo_en  <= '1';
--                  prefetch_line_en <= '0';							  
--						step := step + 2;	
--				    else
--						-- more lines to go
--						prefetch_line_en <= '1';
--						update_histo_en  <= '1';
--						py   <= py + 1;
--						step := step + 1;						
--					 end if; 
--				
--				when 3 =>
--				 -- parallel execution completed
--				   if (prefetch_line_done = '1' and update_histo_done = '1') then
--						prefetch_line_en <= '0';
--						update_histo_en  <= '0';
--						number_of_lines  <= number_of_lines - 1;
--                  step :=  step  - 1;				  
--               end if;
--
--             when 4 =>
--              -- last line 				 
--				  if (update_histo_done = '1') then
--				      update_histo_en  <= '0';
--						step := step + 1;
--				  end if;
				  
				 when 5 =>
              -- finished 						  
				  calculate_histo_done <= '1';			
			end case;
		end if;
	end process;
	
			
	-- prefetch pixel line for histogram calculation
  	prefetch_line_proc : process(clk, reset, prefetch_line_en)
		variable step  : natural range 0 to 5;
	begin
		if reset = '1' or prefetch_line_en = '0' then
			step := 0;	
			prefetch_line_done <= '0';
			--receive_data_ack   <= '0';
			get_data_needed    <= '0';
			get_data_length    <= 0;
		elsif rising_edge(clk) then
			case step is
			   -- (i)   calculate get data address, length
				-- (ii)  ask framework for data

				when 0 =>
				 receive_data_ack   <= '0';
				 get_data_needed    <= '0';
				 -- calculate get_data_offset (1 of 3)
				 get_data_offset <= py * 1024;
				step := step + 1;
				 
				when 1 =>
             -- calculate get_data_offset (2 of 3)
				 get_data_offset <= get_data_offset + x1;	
             line_length <= 1 + x2;			 
             step := step + 1;				 

				when 2 =>
             -- calculate get_data_offset (3 of 3)
				 get_data_offset <= get_data_offset * 4;
				 line_length  <= line_length - x1;
             step := step + 1;				 
				 	 
				when 3 => 
				 -- get data by framework, ask framework for data
				 get_data_address <= input_data_address + get_data_offset; 
				 get_data_length  <= line_length * 4;
				 get_data_needed  <= '1';
				 step := step + 1;
				 
				when 4 =>
				 -- receive answer from framework
				 if (receive_data_en = '1') then
				     receive_data_ack <= '1';
					  get_data_needed  <= '0';
					  prefetch_line_address <= receive_data_address;
					  step := step + 1;
				 end if;
				  
				 when 5 =>
              -- finished 	
              receive_data_ack <= '1';				  
				  prefetch_line_done <= '1';			
			end case;
		end if;
	end process;
	
	
	-- update histogram for one line, stored in cache
	update_histogramm : process(clk, reset, update_histo_en, enable)
		variable step  : natural range 0 to 7;
      variable my_step  : natural range 0 to 7;	
	begin
		if reset = '1' or update_histo_en = '0' then
			step := 0;
			my_step := 0;
			histo_inc <= '0';
			update_histo_addr <= (others => '0');
			update_histo_done <= '0';
			update_histo_bucket <= (others => '0');
		elsif rising_edge(clk) then
		 if enable = '0' then
		   -- framework maybe interrupted
			step      := 7;
			histo_inc <= '0';
		 else
			case step is
				-- (i)   load first pixel
				-- (ii)  update histogram for current pixel and load next one (if needed)
				
				when 0 => 
				  -- start to read 1st pixel
				  update_histo_addr <= prefetch_line_address;
				  px <= x1;
				  step := step + 1;
				  my_step := 1;
				
				when 1 => 
				  -- wait one cycle (for local ram data to become valid)
				  step := step + 1;
				  my_step := 2;
				  
			   when 2 => 
				  -- update histogram (1 of 2)
				  --   extract H, S, V values 
				  H(0 to 7) <= i_RamData( 24 to  31);
				  S(0 to 7) <= i_RamData( 16 to  23);
				  V(0 to 7) <= i_RamData(  8 to  15);
				  -- do not increment histogram in this step
				  histo_inc <= '0';
				  -- get next pixel
				  update_histo_addr <= update_histo_addr + 1;
				  step := step + 1;	
              my_step := 3;				  
				
				when 3 => 
				   -- update histogram (2 of 2)
					--   calculate histogram bucket for current pixel and update
               if( S_THRESH <= S and V_THRESH <= V) then
					    update_histo_bucket <= STD_LOGIC_VECTOR(TO_UNSIGNED(((10 
							* sdvd_values(TO_INTEGER(UNSIGNED(S)))) 
							+ hd_values(TO_INTEGER(UNSIGNED(H)))), 7));
					else
					    update_histo_bucket <= STD_LOGIC_VECTOR(TO_UNSIGNED((100 
							+ sdvd_values(TO_INTEGER(UNSIGNED(V)))), 7));					
					end if;
					-- increment histogram value at update_histo_bucket
					histo_inc <= '1';
					-- update current pixel position
					px <= px + 1;
					-- more pixels in line?
					if (x2 <= px) then
					      -- no more pixels
						   step := step + 1;	
							my_step := 4;
					else
					      -- more pixels to go
					      step := step - 1;
							my_step := 2;
					end if;

				when 4 => 
				   -- updating finished
					histo_inc         <= '0';
					update_histo_done <= '1';
					my_step := 4;
					
           when 5 =>
              -- additional wait cycle for step 2
              step := step - 3; 
				  
			  when 6 =>
              -- additional wait cycle for step 3
              step := step - 3; 
			  
			  when 7 =>				  
			    if (my_step = 1) then 
			      step := 0;
			    elsif  (my_step = 2) then 
			      step := 5;
			    elsif  (my_step = 3) then 
			      step := 6;
				 else
				   step := my_step;
			    end if;
				 histo_inc <= '0';
			 end case;
		end if;
	 end if;
	end process;
	
	
	-- signals and processes related to copying the histogram to
	-- burst-ram
	-- @author: Andreas Agne
	copy_histogram : process(clk, reset, copy_histo_en)
		variable step : natural range 0 to 7;
	begin
		if reset = '1' or copy_histo_en = '0' then
			copy_histo_addr <= (others => '0');
			copy_histo_bucket <= (others => '0');
			copy_histo_done <= '0';
			o_RAMWE <= '0';
			copy_histo_data <= (others => '0');
			step := 0;
		elsif rising_edge(clk) then
			case step is	
				
				when 0 => -- set histogram and burst ram addresses to 0
					copy_histo_addr <= (others => '0');
					copy_histo_bucket <= (others => '0');
					step := step + 1;
					
				when 1 => -- copy first word
					copy_histo_addr <= (others => '0');
					copy_histo_bucket <= copy_histo_bucket + 1;
					o_RAMWE <= '1';
					copy_histo_data <= histo_value;
					step := step + 1;
					
				when 2 => -- copy remaining histogram buckets to burst ram
					copy_histo_addr <= copy_histo_addr + 1;
					copy_histo_bucket <= copy_histo_bucket + 1;
					o_RAMWE <= '1';
					copy_histo_data <= histo_value;
					if (108 <= copy_histo_bucket) then
						step := step + 1;
					end if;		

				when 3 => -- wait (1 of 2)
				   o_RAMWE <= '1';
					copy_histo_addr <= copy_histo_addr + 1;
					copy_histo_data <= histo_value;
				   step := step + 1;
					
				when 4 => -- wait (2 of 2)
				   o_RAMWE <= '1';
				   step := step + 1; 			
					
				when 5 => -- write n
				   o_RAMWE <= '1';
					copy_histo_addr <= copy_histo_addr + 1;
					copy_histo_data <= STD_LOGIC_VECTOR(TO_SIGNED(110, 32));
				   step := step + 1; 	

			   when 6 => -- write dummy
				   o_RAMWE <= '1';
					copy_histo_addr <= copy_histo_addr + 1;
					copy_histo_data <= STD_LOGIC_VECTOR(TO_SIGNED(0, 32));
				   step := step + 1; 					
					
				when 7 => -- all buckets copied -> set handshake signal
					copy_histo_done <= '1';
					copy_histo_bucket <= (others => '0');
					o_RAMWE <= '0';
			end case;
		end if;
	end process;
	
	
	
	-- signals and processes related to clearing the histogram
	-- @author: Andreas Agne
	clear_histogram_proc : process(clk, reset, clear_histo_en)
		variable step : natural range 0 to 3;
	begin
		if reset = '1' or clear_histo_en = '0' then
			step := 0;
			histo_clear <= '0';
			clear_histo_bucket <= (others => '0');
			clear_histo_done <= '0';
		elsif rising_edge(clk) then
			case step is
				when 0 => -- enable bucket zeroing
						clear_histo_bucket <= (others => '0');
						histo_clear <= '1';
						step := step + 1;
						
				when 1 => -- visit every bucket
					clear_histo_bucket <= clear_histo_bucket + 1;
					if 108 <= clear_histo_bucket then
						step := step + 1;
					end if;
					
			   when 2 =>
				   step := step + 1;					
				
				when 3 => -- set handshake signal
					histo_clear <= '0';
					clear_histo_bucket <= (others => '0');
					clear_histo_done <= '1';
					
			end case;
		end if;
	end process;
	
	
   -- signals and processes related to normalizing the histograme
	normalize_histogram_proc : process(clk, reset, normalize_histo_en, ce)
		variable step : natural range 0 to 7;
	begin
		if reset = '1' or normalize_histo_en = '0' then
			step := 0;
			normalize_histo_bucket <= (others => '0');
			normalize_histo_done <= '0';
		elsif ce = '0' then
		
		elsif rising_edge(clk) then
			case step is
            
				
				when 0 =>
				 -- init sum calculation
				 i <= 0;
             sum <= 0;
				 step := step + 1;
				 
				when 1 =>
				 -- calculate sum
				 sum <= sum + CONV_INTEGER(histo_ram(i));
				 if (i < 109) then
				    i <= i + 1;
				 else 
				    step := step + 1;
				 end if;
				
				-- init
				when 2 => 
						normalize_histo_bucket <= (others => '0');
						normalize_histo <= '0';
						i <= 0;
						step := step + 1;
															
				-- modify histo_values (histo_value * GRANULARITY) and sum up histogram
				-- first histo_value
				when 3 =>
				       normalize_histo <= '1';
						 -- modify value: value * GRANULARITY
						 normalize_histo_value <= histo_ram(i)(17 downto 0) & "00000000000000";
						 i <= 1;
						 step := step + 1;						
				
				-- other histo_values
				when 4 =>
				       normalize_histo <= '1';
						 -- modify value: value * GRANULARITY
						 normalize_histo_value <= histo_ram(i)(17 downto 0) & "00000000000000";
						 if (i < 109) then
						      i <= i + 1;
						 end if;
						 if (normalize_histo_bucket < 109) then
						      normalize_histo_bucket <= normalize_histo_bucket + 1;
						 else
						      step := step + 1;
						 end if;				 
													
				when 5 => 
				  -- start division
				   normalize_histo <= '0';
					normalize_histo_bucket <= (others => '0');
					divisor  <= STD_LOGIC_VECTOR(TO_SIGNED(sum, 32));
					i <= 0;
					step := step + 1;
					

				when 6 => 
				   -- put all 110 histogram values into pipelined divider.
					-- pipelined divider has a latency of 36 clock cycles
					-- 36 = 32 (width of dividend) + 4 (see: coregen datasheed)
					-- one clock cycle per division
					if (i<110) then
                   -- put histogram values to pipeline				 
						 dividend <= histo_ram(i);
						 i <= i + 1;
               end if;
               if (i > 36) then
					    -- collect division results
						 normalize_histo <= '1';
						 normalize_histo_value <= quotient;
                   if (normalize_histo_bucket < 109 and i > 37) then
						     normalize_histo_bucket <= normalize_histo_bucket + 1;
						 elsif (109 <= normalize_histo_bucket) then
						     step := step + 1;
						 end if;
               end if;					
				
				when 7 => 
				   -- set handshake signal;
					normalize_histo <= '0';
					normalize_histo_bucket <= (others => '0');
					normalize_histo_done <= '1';						
			end case;
		end if;
	end process;
	
	
	     -- reads parameter
       read_parameter_proc: process (clk, reset, read_parameter_en)
         variable step : natural range 0 to 4;
       begin
       
      if reset = '1' or read_parameter_en = '0' then
			step := 0;
			read_parameter_done  <= '0';
         parameter_loaded_ack <= '0';			
		elsif rising_edge(clk) then
			case step is 
			
        when 0 =>		
			 --! read parameter values
			 read_parameter_addr <= local_ram_start_address_if;
			 parameter_loaded_ack <= '0';	
			 step := step + 1;
			 
		  when 1 =>
		    --!  wait one cycle
			 read_parameter_addr <= local_ram_start_address_if + 1;
			 step := step + 1;

		  when 2 =>
		    --! read size_x
			 size_x <= TO_INTEGER(SIGNED(i_RAMData));
			 step := step + 1;
			 			 
		  when 3 =>
		    --! read size_y
			 size_y <= TO_INTEGER(SIGNED(i_RAMData));
			 parameter_loaded_ack <= '1';	
			 step := step + 1;
			 
		  when 4 =>
		    if (parameter_loaded = '0') then
			        read_parameter_done <= '1';
					  parameter_loaded_ack <= '0';	
			 end if;
          end case;
         end if;
       end process;
	

   
     -- reads particle data needed for histogram calculation
       read_particle_proc: process (clk, reset, read_particle_en, ce)
         variable step : natural range 0 to 8;
       begin
       
      if reset = '1' or read_particle_en = '0' then
			step := 0;
			read_particle_done <= '0';
         --local_ram_address_if <= local_ram_start_address_if;
		elsif ce = '0' then
		
		elsif rising_edge(clk) and ce = '1' then
			case step is 
        when 0 =>
          --! increment local ram address to get x value
          local_ram_address_if <= local_ram_start_address_if + 1;
          step := step + 1;
 
        when 1 =>		
			 --! read particle values
			 read_particle_addr <= local_ram_address_if;
			 local_ram_address_if <= local_ram_address_if + 1;
			 step := step + 1;
			 
		  when 2 =>
		    --!  wait one cycle
			 local_ram_address_if <= local_ram_address_if + 1;
			 read_particle_addr <= local_ram_address_if;
			 step := step + 1;

		  when 3 =>
		    --! read x
			 x <= TO_INTEGER(SIGNED(i_RAMData));
			 local_ram_address_if <= local_ram_address_if + 6;
			 read_particle_addr <= local_ram_address_if;
			 step := step + 1;
			 			 
		  when 4 =>
		    --! read y
			 y <= TO_INTEGER(SIGNED(i_RAMData));
			 local_ram_address_if <= local_ram_address_if + 1;
			 read_particle_addr <= local_ram_address_if;
			 step := step + 1;
						 
		  when 5 =>
		    --! read scale
			 scale <= TO_INTEGER(SIGNED(i_RAMData));
			 read_particle_addr <= local_ram_address_if;
			 step := step + 1;

		  when 6 =>
		    --! read width
			 width  <= TO_INTEGER(SIGNED(i_RAMData));
			 step := step + 1;
						 
		  when 7 =>
		    --! read height
			 height <= TO_INTEGER(SIGNED(i_RAMData));
			 step := step + 1;
			 
		  when 8 =>
			 read_particle_done <= '1';
          end case;
         end if;
       end process;
	

     -- analyzes particle data needed for histogram calculation
       analyze_particle_proc: process (clk, reset, analyze_particle_en, ce)
         variable step : natural range 0 to 13;
       begin
       
       if reset = '1' or analyze_particle_en = '0' then
			step := 0;
			analyze_particle_done <= '0';
		elsif ce = '0' then
		
		elsif rising_edge(clk) and ce = '1'  then
			case step is
         when 0 =>		
		      --! calculate upper left corner (x1, y1) and lower bottom corner (x2, y2) of frame piece
				temp_x <= width  - 1;
				temp_y <= height - 1;
		      step := step + 1;
							
		   when 1 => 
		      --! calculate (x1, y1) and (x2, y2)
				temp_x <= temp_x / 2;
		      step := step + 1;
		
		   when 2 => 
		      --! calculate (x1, y1) and (x2, y2)
				temp_y <= temp_y / 2;
		      step := step + 1;
				
		   when 3 => 
		      --! calculate (x1, y1) and (x2, y2)
				temp_x <= temp_x * scale;
		      step := step + 1;
				
		   when 4 => 
		      --! calculate (x1, y1) and (x2, y2)
				temp_y <= temp_y * scale;
		      step := step + 1;				
				
		   when 5 => 
		      --! calculate (x1, y1) and (x2, y2)
				x1 <= x - temp_x;
		      step := step + 1;
				
		   when 6 => 
		      --! calculate (x1, y1) and (x2, y2)
				x2 <= x + temp_x;
				step := step + 1;

		   when 7 => 
		      --! calculate (x1, y1) and (x2, y2)
				y1 <= y - temp_y;
				step := step + 1;

		   when 8 => 
		      --! calculate (x1, y1) and (x2, y2)
				y2 <= y + temp_y;
				step := step + 1;				
				
		   when 9 => 
		      --! calculate (x1, y1) and (x2, y2)
				x1 <= x1 / GRANULARITY;
		      step := step + 1;
				
		   when 10 => 
		      --! calculate (x1, y1) and (x2, y2)
				y1 <= y1 / GRANULARITY;
				if (x1 > size_x-1) then
				   x1 <= size_x - 1;
				elsif (x1 < 0) then
					x1 <= 0;
				end if;
		      step := step + 1;
			
		   when 11 => 
		      --! calculate (x1, y1) and (x2, y2)
				x2 <= x2 / GRANULARITY;
				if (y1 > size_y-1) then
				   y1 <= size_y - 1;
				elsif (y1 < 0) then
					y1 <= 0;
				end if;
		      step := step + 1;
				
		   when 12 => 
		      --! calculate (x1, y1) and (x2, y2)
				y2 <= y2 / GRANULARITY;
				if (x2 > size_x-1) then
				   x2 <= size_x - 1;
				elsif (x2 < 0) then
				   x2 <= 0;
				end if;
				step := step + 1;
				
		   when 13 => 
		      --! finished
            if (y2 > size_y-1) then
				   y2 <= size_y - 1;
				elsif (y2 < 0) then
				   y2 <= 0;
				end if;
            if (y2 < y1) then
				    if (y2 > 0) then
                   y1 <= y2;
                else
					    y1 <= 0;
					 end if;
				end if;				
            if (x2 < x1) then
                x1 <= x2;
            end if;		
		      analyze_particle_done <= '1';
         end case;
       end if;
     end process;
	
	
	-- histogram ram mux
	-- @author: Andreas Agne
	-- updated
	mux_proc: process(update_histo_en, copy_histo_en, clear_histo_en, normalize_histo_en,
	         read_particle_en, read_particle_addr, normalize_histo_bucket,
	         update_histo_addr, update_histo_bucket,
			   copy_histo_addr, copy_histo_bucket, clear_histo_bucket,
				copy_histo_data, read_parameter_en, read_parameter_addr)
		variable addr : std_logic_vector(C_TASK_BURST_AWIDTH - 1 downto 0);
		variable data : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
		variable bucket : std_logic_vector(6 downto 0);
	begin
	   if update_histo_en = '1'  then
			addr := update_histo_addr;
			bucket := update_histo_bucket;
			data := (others => '0');
	   elsif copy_histo_en = '1' then
			addr := copy_histo_addr;
			bucket := copy_histo_bucket;
			data := copy_histo_data;
		elsif clear_histo_en = '1' then
			addr := (others => '0');
			bucket := clear_histo_bucket;
			data := (others => '0');
		elsif normalize_histo_en = '1' then
			addr := (others => '0');
			bucket := normalize_histo_bucket;
			data := (others => '0');
		elsif read_particle_en = '1' then
			addr := read_particle_addr;
			bucket := (others => '0');		
			data := (others => '0');	
		elsif read_parameter_en = '1' then
			addr := read_parameter_addr;
			bucket := (others => '0');		
			data := (others => '0');				
		else
			addr := (others => '0');
			bucket := (others => '0');
			data := (others => '0');
		end if;
                
		o_RAMData <= data;
		o_RAMAddr <= addr(C_TASK_BURST_AWIDTH - 1 downto 0);
		histo_bucket <= bucket;
	end process;
  
  
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--                                                                              --
--  1) initialize histogram, finished = '0'  (if new_particle = '1')            --
--                                                                              --
--  2) read particle data                                                       --
--                                                                              --  
--  3) extract needed information                                               --
--                                                                              --
--  4) calculate histogram                                                      --
--                                                                              -- 
--  5) normalize histogram                                                      --
--                                                                              -- 
--  6) write histogram into local ram                                           --
--                                                                              -- 
--  7) finshed = '1', wait for new_particle = '1'                               --
--                                                                              -- 
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

  state_proc : process(clk, reset)
  begin

  if (reset = '1') then
 
		 state <= STATE_INIT;
		 new_particle_ack <= '0';
		 finished <= '0';

  elsif rising_edge(clk) then
	if init = '1' then
	        state         <= STATE_INIT;
			  new_particle_ack     <= '0';
			  clear_histo_en       <= '0';
			  read_particle_en     <= '0';
			  analyze_particle_en  <= '0';
			  calculate_histo_en   <= '0';
           normalize_histo_en   <= '0';
			  copy_histo_en        <= '0';
			  finished             <= '0';
   elsif enable = '1' then
	    case state is

        when STATE_INIT =>
		     --! init data
			  finished <= '0';
			  calculate_histo_en  <= '0';
			  copy_histo_en    <= '0';
			  read_particle_en <= '0';
           analyze_particle_en  <= '0';
			  normalize_histo_en  <= '0';
			  if (new_particle = '1') then
			     new_particle_ack <= '1';
				  clear_histo_en <= '1';
				  state <= STATE_INIT_HISTOGRAM;
			  elsif (parameter_loaded = '1') then
			     read_parameter_en <= '1';
				  state <= STATE_READ_PARAMETER;
			  end if;
			  

        when STATE_READ_PARAMETER =>
		     --! init histogram
			  if (read_parameter_done = '1') then
			     read_parameter_en    <= '0';
			     state         <= STATE_INIT;
			  end if;			  
		  		
        when STATE_INIT_HISTOGRAM =>
		     --! init histogram
			  if (clear_histo_done = '1') then
			     new_particle_ack <= '0';
			     clear_histo_en   <= '0';		
				  read_particle_en <= '1';
			     state <= STATE_READ_PARTICLE;
			  end if;	
		
		  	
        when STATE_READ_PARTICLE =>		
			 --! read particle values
            if (read_particle_done = '1') then
                  analyze_particle_en <= '1';
                  read_particle_en    <= '0';
                  state <= STATE_ANALYZE_PARTICLE;
            end if; 
								 
        
		  when STATE_ANALYZE_PARTICLE => 
		      --! calculate upper left corner (x1, y1) and lower bottom corner (x2, y2) of frame piece
		      if (analyze_particle_done = '1') then
                  analyze_particle_en    <= '0';
                  calculate_histo_en <= '1';
		            state <= STATE_CALCULATE_HISTOGRAM;					
            end if;


         when STATE_CALCULATE_HISTOGRAM =>
           --  get next pixel for histogram calculation
           if (calculate_histo_done = '1') then
                     calculate_histo_en <= '0';
							normalize_histo_en     <= '1';
							state <= STATE_NORMALIZE_HISTOGRAM;
			  end if;


         when STATE_NORMALIZE_HISTOGRAM =>
			  --! normalize histogram
			  if (normalize_histo_done = '1') then
			        normalize_histo_en <= '0';
				     copy_histo_en      <= '1';
			        state <= STATE_COPY_HISTOGRAM;
			  end if;


         when STATE_COPY_HISTOGRAM =>
			  --! normalize histogram
			  if (copy_histo_done = '1') then
			     copy_histo_en <= '0';
			     state <= STATE_FINISH;
			  end if;
	

		  when STATE_FINISH =>
            --! write finished signal
				finished <= '1';
				if (new_particle = '1') then
		            state <= STATE_INIT;
				end if;


        when others =>
            state <= STATE_INIT;
    end case;
	end if;
  end if;
 
  end process;
end Behavioral;


