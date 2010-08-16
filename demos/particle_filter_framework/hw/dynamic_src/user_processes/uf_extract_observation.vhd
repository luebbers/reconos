library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.MATH_REAL.ALL;


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
                  STATE_READ_PARTICLE, STATE_ANALYZE_PARTICLE, STATE_CALCULATE_HISTOGRAM,
                  STATE_GET_PIXEL,STATE_UPDATE_HISTOGRAM, STATE_CHECK_FINISHED, 
                  STATE_NORMALIZE_HISTOGRAM, STATE_COPY_HISTOGRAM,
                  STATE_FINISH);
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
  signal local_ram_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  signal local_ram_start_address_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  
  
  
  -- HSV signals
  signal H  : std_logic_vector(0 to 7) := (others => '0');
  signal S  : std_logic_vector(0 to 7) := (others => '0');
  signal V  : std_logic_vector(0 to 7) := (others => '0');
  
  signal H_store  : std_logic_vector(0 to 7) := (others => '0');
  signal S_store  : std_logic_vector(0 to 7) := (others => '0');
  signal V_store  : std_logic_vector(0 to 7) := (others => '0'); 
  
  constant S_THRESH : integer := 25;
  constant V_THRESH : integer := 50;
  
  signal hd : natural range 0 to 9 := 0;
  signal sd : natural range 0 to 9 := 0;
  signal vd : natural range 0 to 9 := 0;
  signal value : natural := 0;  
  
  	-- copy histogram
	signal copy_histo_en     : std_logic := '0'; -- handshake signal
	signal copy_histo_done   : std_logic := '0'; -- handshake signal
	signal copy_histo_addr   : std_logic_vector(C_BURST_AWIDTH-1 downto 0); -- burst ram addr
	signal copy_histo_bucket : std_logic_vector(6 downto 0); -- histogram addr
	signal copy_histo_data   : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');  
  
  	-- update histogram
	signal update_histo_en     : std_logic := '0'; -- handshake signal
	signal update_histo_done   : std_logic := '0'; -- handshake signal
	signal update_histo_addr   : std_logic_vector(C_BURST_AWIDTH-1 downto 0); -- burst ram addr
	signal update_histo_bucket : std_logic_vector(6 downto 0); -- histogram addr
	
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
   signal read_particle_addr   : std_logic_vector(C_BURST_AWIDTH-1 downto 0) := (others=>'0');

   -- analyze particle
   signal analyze_particle_en     : std_logic := '0'; -- handshake signal
   signal analyze_particle_done   : std_logic := '0'; -- handshake signal
	
	-- read parameter 
   signal read_parameter_en     : std_logic := '0'; -- handshake signal
   signal read_parameter_done   : std_logic := '0'; -- handshake signal   
   signal read_parameter_addr   : std_logic_vector(C_BURST_AWIDTH-1 downto 0) := (others=>'0');
	
	
	-- calculate histogram 
   signal calc_histo_en     : std_logic := '0'; -- handshake signal
   signal calc_histo_done   : std_logic := '0'; -- handshake signal   

   -- get_pixel
   signal get_pixel_en     : std_logic := '0'; -- handshake signal
   signal get_pixel_done   : std_logic := '0'; -- handshake signal
	
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
	
   -- current pixel	
   signal size_x : integer := 480;
	signal size_y : integer := 360;	

   -- temporary signals
   signal temp_x : integer := 0;
   signal temp_y : integer := 0;	
   signal temp : integer := 0;		
	
	-- input data offset
	signal input_data_offset : integer := 0;
	
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
	-- @author: Andreas Agne
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
  	
	
	-- signals and processes related to updating the histogram from
	-- burst-ram data
	update_histo_proc : process(clk, reset, update_histo_en)
		variable step  : natural range 0 to 3;

	begin
		if reset = '1' or update_histo_en = '0' then
			step := 0;
			histo_inc <= '0';
			update_histo_addr <= (others => '0');
			update_histo_done <= '0';
			update_histo_bucket <= (others => '0');
		elsif rising_edge(clk) then
			case step is

				when 0 => -- calculate hd
				   hd <=   hd_values(TO_INTEGER(UNSIGNED(H_store)));
					sd <= sdvd_values(TO_INTEGER(UNSIGNED(S_store)));
					vd <= sdvd_values(TO_INTEGER(UNSIGNED(V_store)));
					step := step + 1;	
					
				when 1 => -- calculate histogram position
				   if( S_THRESH <= S and V_THRESH <= V) then	
					   value <= 10 * sd + hd;
					else
					   value <= 100 + vd;
					end if;
					step := step + 1;
 
				when 2 => -- increment histogram value
					histo_inc <= '1';
					update_histo_bucket <= STD_LOGIC_VECTOR(TO_UNSIGNED(value, 7));
					step := step + 1;			
					
				when 3 => -- turn off histogram incrementing, set handshake signal
					histo_inc <= '0';
					update_histo_done <= '1';

--				when 0 => -- calculate hd
--				        hd <=   hd_values(TO_INTEGER(UNSIGNED(H)));
--					step := step + 1;	
--
--				when 1 => -- calculate sd
--					sd <= sdvd_values(TO_INTEGER(UNSIGNED(S)));
--					step := step + 1;	
--					
--				when 2 => -- calculate vd
--					vd <= sdvd_values(TO_INTEGER(UNSIGNED(V)));
--					step := step + 1;	
--					
--				when 3 => -- calculate histogram position (1 of 2)
--				   if( S_THRESH <= S and V_THRESH <= V) then	
--   		 			   value <= 10 * sd;
--					else
--					   value <= 100 + vd;
--					end if;
--					step := step + 1;
--					
--				when 4 => -- calculate histogram position (2 of 2)
--					if( S_THRESH <= S and V_THRESH <= V) then
--						value <= value + hd;
--					end if;			
--					step := step + 1;
--					 
--				when 5 => -- increment histogram value
--					histo_inc <= '1';
--					update_histo_bucket <= STD_LOGIC_VECTOR(TO_UNSIGNED(value, 7));
--					step := step + 1;			
--					
--				when 6 => -- turn off histogram incrementing, set handshake signal
--					histo_inc <= '0';
--					update_histo_done <= '1';					
			end case;
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
	
	
	
		-- signals and processes related to calculating the histogram
	calc_histo_proc : process(clk, reset, calc_histo_en)
		variable step : natural range 0 to 5;
	begin
		if reset = '1' or calc_histo_en = '0' then
			step := 0;
			H_store(0 to 7) <= (others => '0');
			S_store(0 to 7) <= (others => '0');			
			V_store(0 to 7) <= (others => '0');			
			update_histo_en <= '0';
			get_pixel_en    <= '0';			
			calc_histo_done <= '0';
			
		elsif rising_edge(clk) then
			case step is
				when 0 => -- get 1st pixel
						px <= x1;
						py <= y1;
						get_pixel_en    <= '1';
						update_histo_en <= '0';
						step := step + 1;
						
				when 1 => -- first pixel stored
				   if (get_pixel_done = '1') then
					     H_store(0 to 7) <= H(0 to 7);
						  S_store(0 to 7) <= S(0 to 7);
						  V_store(0 to 7) <= V(0 to 7);
					     get_pixel_en    <= '0';
						  update_histo_en <= '0';
						  px <= px + 1;
				        step := step + 1;
					 end if;
					
			   when 2 => -- start parallel execution or last update
				   
					if (px > x2 and y2 <= py) then
				     -- finished: last update
					  step := step + 2;
					  update_histo_en <= '1';
					  get_pixel_en    <= '0';	
                 
				   elsif (px > x2 and py <  y2) then
				     -- next row
				     px <= x1;
				     py <= py + 1;
					  -- read next pixel and update histogram for last one
                 get_pixel_en    <= '1';
                 update_histo_en <= '1';	
				     step := step + 1;					  
				   else
				     -- default: read next pixel and update histogram for last one
				     get_pixel_en    <= '1';
                 update_histo_en <= '1';	
				     step := step + 1;
				   end if;				
				
				
				when 3 => -- parallel execution finished
				   if (update_histo_done = '1' and get_pixel_done = '1' ) then
				         
                     get_pixel_en    <= '0';
                     update_histo_en <= '0';
							H_store(0 to 7) <= H(0 to 7);
						   S_store(0 to 7) <= S(0 to 7);
						   V_store(0 to 7) <= V(0 to 7);
                     px <= px + 1;									
							step := step - 1;
					 end if;

					
				when 4 => -- last histogram update
				   if (update_histo_done = '1') then
					     update_histo_en <= '0';
						  get_pixel_en    <= '0';
				        step := step + 1;
					end if;
					
				
				when 5 => -- set handshake signal
			      update_histo_en <= '0';
			      get_pixel_en    <= '0';		               
					calc_histo_done <= '1';					
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
	
	
   -- signals and processes related to normalizing the histograme
	normalize_histogram_proc : process(clk, reset, normalize_histo_en, ce)
		variable step : natural range 0 to 7;
	begin
		if reset = '1' or normalize_histo_en = '0' then
			step := 0;
			normalize_histo_bucket <= (others => '0');
			normalize_histo_done <= '0';
			divisor <= "00000000000000000000000000000001";
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
         variable step : natural range 0 to 17;
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
		      --! wait
		      step := step + 1;

		   when 5 => 
		      --! wait
		      step := step + 1;
				
		   when 6 => 
		      --! calculate (x1, y1) and (x2, y2)
				temp_y <= temp_y * scale;
		      step := step + 1;	

		   when 7 => 
		      --! wait
		      step := step + 1;

		   when 8 => 
		      --! wait
		      step := step + 1;				
				
		   when 9 => 
		      --! calculate (x1, y1) and (x2, y2)
				x1 <= x - temp_x;
		      step := step + 1;
				
		   when 10 => 
		      --! calculate (x1, y1) and (x2, y2)
				x2 <= x + temp_x;
				step := step + 1;

		   when 11 => 
		      --! calculate (x1, y1) and (x2, y2)
				y1 <= y - temp_y;
				step := step + 1;

		   when 12 => 
		      --! calculate (x1, y1) and (x2, y2)
				y2 <= y + temp_y;
				step := step + 1;				
				
		   when 13 => 
		      --! calculate (x1, y1) and (x2, y2)
				x1 <= x1 / GRANULARITY;
		      step := step + 1;
				
		   when 14 => 
		      --! calculate (x1, y1) and (x2, y2)
				y1 <= y1 / GRANULARITY;
				if (x1 < 0) then
					x1 <= 0;
				end if;
		      step := step + 1;
			
		   when 15 => 
		      --! calculate (x1, y1) and (x2, y2)
				x2 <= x2 / GRANULARITY;
				if (y1 < 0) then
					y1 <= 0;
				end if;
		      step := step + 1;
				
		   when 16 => 
		      --! calculate (x1, y1) and (x2, y2)
				if (x2 > size_x - 1) then
				    x2 <= size_x - 1;
				end if;
				y2 <= y2 / GRANULARITY;
				step := step + 1;
				
		   when 17 => 
		      --! finished	
				if (y2 > size_y - 1) then
				    y2 <= size_y - 1;
				end if;				
		      analyze_particle_done <= '1';
         end case;
       end if;
     end process;



     -- get next pixel needed for histogram calculation
       get_pixel_proc: process (clk, reset, get_pixel_en, ce)
         variable step : natural range 0 to 5;
       begin
       
       if reset = '1' or get_pixel_en = '0' then
			step := 0;
			get_pixel_done <= '0';
         --word_address <= (others=>'0');
         word_data_ack     <= '0';
		elsif ce = '0' then
		
		elsif rising_edge(clk)  then
			case step is
				when 0 =>
					--! calculate offset for input data (1 of 3)
					input_data_offset <= 1024 * py;
					--input_data_offset <= 512 * py;
					step := step + 1;
			  
         	when 1 =>
					--! calculate offset for input data (2 of 3)
					input_data_offset <= input_data_offset + px;
					step := step + 1;

         	when 2 =>
					--! calculate offset for input data (3 of 3)
					input_data_offset <= input_data_offset * 4;
					step := step + 1;  	

        		when 3 =>
		         --! read pixel data using entitiy ports
					input_data_needed <= '1';
					word_address <= input_data_address + input_data_offset;
					step := step + 1;
			 		
        		when 4 =>
		          --! receive pixel data
					if word_data_en = '1' then
						input_data_needed <= '0';
						word_data_ack     <= '1';
						step := step + 1;		  
           		end if;
			  
        		when 5 =>
		        --! split pixel data to H,S,V signals
					H(0 to 7) <= word_data( 24 to  31);
					S(0 to 7) <= word_data( 16 to  23);
					V(0 to 7) <= word_data(  8 to  15);
					get_pixel_done <= '1';
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
				read_parameter_en, read_parameter_addr,
				copy_histo_data)
		variable addr : std_logic_vector(C_BURST_AWIDTH - 1 downto 0);
		variable data : std_logic_vector(0 to C_BURST_DWIDTH-1);
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
		o_RAMAddr <= addr(C_BURST_AWIDTH - 1 downto 0);
		histo_bucket <= bucket;
	end process;
  
  

----------------------------------------------------------------------------------
-- 
--  1) initialize histogram, finished = '0'  (if new_particle = '1')
--  
--  2) read particle data
--  
--  3) extract needed information
--  
--  4) calculate input address, read pixel data (using entity ports)
--  
--  5) update histogram
--   
--  6) more pixel to load
--          go to step 4
--     else
--          go to step 7
--  
--  7) normalize histogram
--  
--  8) write histogram into local ram
--  
--  9) finshed = '1', wait for new_particle = '1'
--  
----------------------------------------------------------------------------------


  state_proc : process(clk, reset)
  begin

  if (reset = '1') then
 
		 state <= STATE_INIT;
		 new_particle_ack  <= '0';
		 read_parameter_en <= '0';
		 finished <= '0';

  elsif rising_edge(clk) then
 	
	if init = '1' then
	
	        state <= STATE_INIT;
			  finished <= '0';
			  clear_histo_en <= '0';         
			  
   elsif enable = '1' then
	
	    case state is

        when STATE_INIT =>
		     --! init data
			  finished <= '0';
			  calc_histo_en  <= '0';
			  copy_histo_en    <= '0';
			  read_particle_en <= '0';
           analyze_particle_en  <= '0';
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

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 1: INIT HISTOGRAM
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------			  

        when STATE_INIT_HISTOGRAM =>
		     --! init histogram
			  if (clear_histo_done = '1') then
			     new_particle_ack <= '0';
			     clear_histo_en <= '0';			  
			     state <= STATE_READ_PARTICLE;
                             read_particle_en <= '1';
			  end if;	


--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
----				
----        STEP 2: READ PARTICLE
----
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------			
		  	
        when STATE_READ_PARTICLE =>		
			 --! read particle values
                         if (read_particle_done = '1') then
                               analyze_particle_en <= '1';
                               read_particle_en <= '0';
                               state <= STATE_ANALYZE_PARTICLE;
                         end if; 
					
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 3: ANALYZE PARTICLE
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	
        
		  when STATE_ANALYZE_PARTICLE => 
		      --! calculate upper left corner (x1, y1) and lower bottom corner (x2, y2) of frame piece
		      if (analyze_particle_done = '1') then
                            analyze_particle_en <= '0';
                            --get_pixel_en <= '1';
                            --px <= x1;
			                   --py <= y1;
		                      --state <= STATE_GET_PIXEL;	
									 calc_histo_en <= '1';
									 state <= STATE_CALCULATE_HISTOGRAM;										 
                      end if;

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 4: GET PIXEL
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

         when STATE_CALCULATE_HISTOGRAM =>
           --  get next pixel for histogram calculation
                      if (calc_histo_done = '1') then
                            calc_histo_en <= '0';						
									 normalize_histo_en <= '1';
									state <= STATE_NORMALIZE_HISTOGRAM;			
                      end if;	
							 
--       when STATE_GET_PIXEL =>
--           --  get next pixel for histogram calculation
--                      if (get_pixel_done = '1') then
--                            get_pixel_en <= '0';
--                            update_histo_en <= '1';
--	                           state <= STATE_UPDATE_HISTOGRAM;			
--                     end if;	  

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
----				
----        STEP 5: HISTOGRAM UPDATE
----
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------	
--
--           when STATE_UPDATE_HISTOGRAM =>
--			    --! update histogram
--			    if update_histo_done = '1' then
--							update_histo_en <= '0';
--							px <= px + 1;
--							state <= STATE_CHECK_FINISHED;
--				 end if;

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 6: MORE PIXEL?
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	

--          when STATE_CHECK_FINISHED =>
--			    --! checks if more pixel have to be loaded
--				if    (px > x2 and y2 <= py) then
--				     -- finished
--				     normalize_histo_en <= '1';
--				     state <= STATE_NORMALIZE_HISTOGRAM;
--                 -- CHANGE CHANGE CHANGE
--				     --copy_histo_en <= '1';
--			        --state <= STATE_COPY_HISTOGRAM;
--                 -- END OF CHANGE CHANGE CHANGE
--				 elsif (px > x2 and py <  y2) then
--				     -- next row
--				     px <= x1;
--				     py <= py + 1;
--				     state <= STATE_GET_PIXEL;	
--                                     get_pixel_en <= '1';				  
--				 else
--				     -- default: next pixel
--				     state <= STATE_GET_PIXEL;
--                                     get_pixel_en <= '1';
--				 end if;

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
----				
----        STEP 7: NORMALIZE HISTOGRAM
----
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------	

         when STATE_NORMALIZE_HISTOGRAM =>
			  --! normalize histogram
			  if (normalize_histo_done = '1') then
			     normalize_histo_en <= '0';
				  copy_histo_en <= '1';
			     state <= STATE_COPY_HISTOGRAM;
			  end if;

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 8: WRITE HISTOGRAM TO LOCAL RAM
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	

         when STATE_COPY_HISTOGRAM =>
			  --! normalize histogram
			  if (copy_histo_done = '1') then
			     copy_histo_en <= '0';
			     state <= STATE_FINISH;
			  end if;
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--				
--        STEP 9: HISTOGRAM CALCULATION FINISHED; WAIT FOR NEW_PARTICLE
--
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------	

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


