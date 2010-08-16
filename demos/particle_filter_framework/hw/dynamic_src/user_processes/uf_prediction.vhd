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
--    The 8kb local RAM is filled with as many particles as possible.
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
  
  -- factors for prediction fucntion
  constant A1: integer :=  2;
  constant A2: integer := -1;
  constant B0: integer :=  1;
  
  -- local RAM read/write address
  signal local_ram_address  : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  signal particle_start_address  : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
  
  -- particle counter
  signal counter : integer := 0;
   
  -- signals for new values
  signal x_new : integer := 0;
  signal y_new : integer := 0;
  signal s_new : integer := 0;
  
  -- particle data
  signal x : integer := 0;
  signal y : integer := 0;
  signal s : integer := 0;
  
  signal x_old : integer := 0;
  signal y_old : integer := 0;
  signal s_old : integer := 0;
  
  signal x0 : integer := -1;
  signal y0 : integer := -1;
  
  -- parameters
  signal SIZE_X : integer := 480;
  signal SIZE_Y : integer := 360;
  
  signal TRANS_X_STD : integer := 16384;
  signal TRANS_Y_STD : integer := 8192;
  signal TRANS_S_STD : integer := 16;
  
  -- temporary signals
  signal tmp1 : integer := 0;
  signal tmp2 : integer := 0;
  signal tmp3 : integer := 0;
  signal tmp4 : integer := 0;
  signal tmp5 : integer := 0;
  signal tmp6 : integer := 0;
  
  
  -- states
  type t_state is (STATE_INIT,
     STATE_LOAD_PARAMETER_1, STATE_LOAD_PARAMETER_2, STATE_LOAD_SIZE_X,
	  STATE_LOAD_SIZE_Y, STATE_LOAD_TRANS_X_STD, STATE_LOAD_TRANS_Y_STD,
	  STATE_LOAD_TRANS_S_STD, STATE_SAMPLING, STATE_LOAD_PARTICLE_DECISION,
	  STATE_LOAD_PARTICLE_1, STATE_LOAD_PARTICLE_2,
	  STATE_LOAD_X, STATE_LOAD_Y, STATE_LOAD_S,
	  STATE_LOAD_XP, STATE_LOAD_YP, STATE_LOAD_YP_2, STATE_LOAD_SP, 
	  STATE_LOAD_SP_2, STATE_LOAD_X0, STATE_LOAD_Y0,
	  STATE_CALCULATE_NEW_DATA_1, STATE_CALCULATE_NEW_DATA_2, STATE_CALCULATE_NEW_DATA_3,
	  STATE_CALCULATE_NEW_DATA_4, STATE_CALCULATE_NEW_DATA_5, STATE_CALCULATE_NEW_DATA_6,
	  STATE_CALCULATE_NEW_DATA_7, STATE_WRITE_X, STATE_WRITE_Y, STATE_WRITE_S,
	  STATE_WRITE_XP, STATE_WRITE_YP, STATE_WRITE_SP,   
	  STATE_FINISH);
	  
	-- current state
   signal state : t_state := STATE_INIT;
	
	-- needed for pseudo random entity
	signal enable_pseudo : std_logic := '0';
	signal load : std_logic := '0';
   signal seed : std_logic_vector(31 downto 0) := (others => '0');
   signal pseudoR : std_logic_vector(31 downto 0) := (others => '0');
	
	-- pseudo number as integer;
   signal pseudo : integer := 0; 
  
begin

pseudo_r : pseudo_random
      port map (reset=>reset, clk=>clk, enable=>enable_pseudo, load=>load, seed=>seed, pseudoR=>pseudoR);



  -- burst ram interface
  o_RAMClk  <= clk;


  state_proc : process(clk, reset)

  begin

  if (reset = '1') then
 
       seed <= X"7A3E0426";
		 load <= '1';
       enable_pseudo <= '1';
		 state <= STATE_INIT;
		 finished <= '0';
		 x0 <= -1;

  elsif rising_edge(clk) then
   enable_pseudo <= enable;
	load <= '0';
	if init = '1' then
	
	        state <= STATE_INIT;
			  finished <= '0';
			  o_RAMData <= (others=>'0');
			  o_RAMWE <= '0';
			  o_RAMAddr <= (others => '0');
			  
   elsif enable = '1' then
    case state is

        --! init data
        when STATE_INIT =>
			  local_ram_address <= (others => '0');			  
			  counter  <= 0;
			  finished <= '0';
			  o_RAMWE  <= '0';
			  
			  if (particles_loaded = '1') then
			      -- TODO:  C H A N G E !!! (3 of 3)
					-- CHANGE BACK !!! (2 of 2)
					state <= STATE_LOAD_PARAMETER_1;
					--state <= STATE_SAMPLING;
			  end if;


		  --! load parameter 1/2
        when STATE_LOAD_PARAMETER_1 => 
		    
           o_RAMWE <= '0';			 
           o_RAMAddr <= local_ram_address;
			  local_ram_address <= local_ram_address + 1;
			  state <= STATE_LOAD_PARAMETER_2;
			  
			  
			--! load parameter 2/2
        when STATE_LOAD_PARAMETER_2 => 
		    
           o_RAMAddr <= local_ram_address;
			  local_ram_address <= local_ram_address + 1;
			  state <= STATE_LOAD_SIZE_X; 

 
         --! load parameter SIZE_X
         when STATE_LOAD_SIZE_X => 
			
			    SIZE_X <= TO_INTEGER(SIGNED(i_RAMData));
				 o_RAMAddr <= local_ram_address;
			    local_ram_address <= local_ram_address + 1;
			    state <= STATE_LOAD_SIZE_Y; 


         --! load parameter SIZE_Y
         when STATE_LOAD_SIZE_Y =>
			
			    SIZE_Y <= TO_INTEGER(SIGNED(i_RAMData));
				 o_RAMAddr <= local_ram_address;
			    local_ram_address <= local_ram_address + 1;
			    state <= STATE_LOAD_TRANS_X_STD;


         --! load parameter TRANS_X_STD
         when STATE_LOAD_TRANS_X_STD =>
			
			    TRANS_X_STD <= TO_INTEGER(SIGNED(i_RAMData));
				 o_RAMAddr <= local_ram_address;
			    local_ram_address <= local_ram_address + 1;
			    state <= STATE_LOAD_TRANS_Y_STD;
				 

         --! load parameter TRANS_Y_STD
         when STATE_LOAD_TRANS_Y_STD =>
			
			    TRANS_Y_STD <= TO_INTEGER(SIGNED(i_RAMData));
			    state <= STATE_LOAD_TRANS_S_STD;
				 
				 
         --! load parameter TRANS_S_STD
         when STATE_LOAD_TRANS_S_STD =>
			
			    TRANS_S_STD <= TO_INTEGER(SIGNED(i_RAMData));
			    state <= STATE_SAMPLING;
			
			
			when STATE_SAMPLING =>
			
			    -- first 32 are saved for parameter, the 33th is the first weight
				 -- => 33 - the first x value
			    local_ram_address <= "000000100001";
			    particle_start_address <= "000000100001";
				 o_RAMWE <= '0';
				 finished <= '0';
				 counter <= 0;
				 --x0 <= -1;
			    state <= STATE_LOAD_PARTICLE_DECISION;
          			
						
			--! decision if another particle has to be sampled
			when STATE_LOAD_PARTICLE_DECISION =>
			
			   o_RAMWE <= '0';
			   if (counter < number_of_particles) then
				
				    state <= STATE_LOAD_PARTICLE_1;
					 local_ram_address <= particle_start_address;
				else
				
				    state <= STATE_FINISH;
				end if;
				
				
		  --! load particle data 1/2
		  when STATE_LOAD_PARTICLE_1 =>
		  
				o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				state <= STATE_LOAD_PARTICLE_2;
				 

		  --! load particle data 2/2
		  when STATE_LOAD_PARTICLE_2 =>
		  
				o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				state <= STATE_LOAD_X;
				
			
		  --! load particle data: x
		  when STATE_LOAD_X =>
		  
		      x <= TO_INTEGER(SIGNED(i_RAMData));
				o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				state <= STATE_LOAD_Y;
				
				

		  --! load particle data: y
		  when STATE_LOAD_Y =>
		  
		      y <= TO_INTEGER(SIGNED(i_RAMData));
				o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				state <= STATE_LOAD_S;
				
				
		  --! load particle data: s
		  when STATE_LOAD_S =>
		  
		      s <= TO_INTEGER(SIGNED(i_RAMData));
				o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				pseudo <= TO_INTEGER(SIGNED(pseudoR));
				state <= STATE_LOAD_XP;
				
				
		  --! load particle data: xp
		  when STATE_LOAD_XP =>
		  
		      x_old <= TO_INTEGER(SIGNED(i_RAMData));
				o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				pseudo <= pseudo / 16;
				state <= STATE_LOAD_YP;
				
				
		  --! load particle data: yp
		  when STATE_LOAD_YP =>
		  
		      y_old <= TO_INTEGER(SIGNED(i_RAMData));
				pseudo <= TO_INTEGER(SIGNED(pseudoR));
				--tmp2  <= pseudo mod 16384;
				----tmp2  <= pseudo mod 65536;
				tmp2  <= pseudo mod 32768;
				state <= STATE_LOAD_YP_2;
				
				
			--! load particle data: yp
		  when STATE_LOAD_YP_2 =>
	
	         o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				--tmp2  <= tmp2 - 8192;
				----tmp2  <= tmp2 - 32768;
				tmp2  <= tmp2 - 16384;
				state <= STATE_LOAD_SP;	
							
				
		  --! load particle data: sp
		  when STATE_LOAD_SP =>
		  
		      s_old <= TO_INTEGER(SIGNED(i_RAMData));
				pseudo <= TO_INTEGER(SIGNED(pseudoR));
				----tmp4  <= pseudo mod 8192;
				tmp4  <= pseudo mod 32768;
				--tmp4  <= pseudo mod 16384;
				state <= STATE_LOAD_SP_2;


		  --! load particle data: sp
		  when STATE_LOAD_SP_2 =>
		  
				----tmp4  <= tmp4 - 4096;
				tmp4  <= tmp4 - 16384;
				--tmp4  <= tmp4 - 8192;
				o_RAMAddr <= local_ram_address;
				local_ram_address <= local_ram_address + 1;
				if (x0 > -1 ) then
				   -- x0, y0 loaded before
				   state <= STATE_CALCULATE_NEW_DATA_1;
				else
				   -- x0, y0 not loaded yet
				   state <= STATE_LOAD_X0;
            end if;					
				
				
		  --! load particle data: x0
		  when STATE_LOAD_X0 =>
		  
		      x0 <= TO_INTEGER(SIGNED(i_RAMData));
				state <= STATE_LOAD_Y0;
				
				
		  --! load particle data: y0
		  when STATE_LOAD_Y0 =>
		  
		      y0 <= TO_INTEGER(SIGNED(i_RAMData));
				state <= STATE_CALCULATE_NEW_DATA_1;
				
				
       --! calculate new data (1/7)
		 --
		 --  x_new  = A1 * (x  - x0) + A2 * (x_old - x0)
		 --           + B0 * pseudo_gaussian (TRANS_X_STD) + p->x0;
		 --
		 --  y_new and s_new are calculated in a similar way
		 --  this equation is splitted up into four states
		 --
		 --  A 6th and 7th state is used for correction
		 --
       when STATE_CALCULATE_NEW_DATA_1 =>
		      
				-- calculate new x
		      x_new <= x     - x0;
				tmp1  <= x_old - x0;
				--tmp2  <= (pseudo mod 16384) - 8192; -- calculated with different pseudonumber
				
				-- calcualte new y
				y_new <= y     - y0;
				tmp3  <= y_old - y0;
				--tmp4  <= (pseudo mod 8192) - 4096; -- calculated with different pseudonumber
				
				-- calculate new s
				s_new <= s     - GRANULARITY;
				tmp5  <= s_old - GRANULARITY;
				tmp6  <= pseudo mod 16;	
		      --tmp6  <= pseudo mod 64;
				state <= STATE_CALCULATE_NEW_DATA_2;


       --! calculate new data (2/7)
       when STATE_CALCULATE_NEW_DATA_2 =>
		 
		      tmp6 <= tmp6 - 8;
				--tmp6 <= tmp6 - 32;
		      state <= STATE_CALCULATE_NEW_DATA_3;
				
				
		 --! calculate new data (3/7)
       when STATE_CALCULATE_NEW_DATA_3 =>
		 
		      -- calculate new x
		      x_new <= A1 * x_new;
				tmp1  <= A2 * tmp1;
				tmp2  <= - B0 * tmp2;
				
				-- calculate new y
		      y_new <= A1 * y_new;
				tmp3  <= A2 * tmp3;
				tmp4  <= B0 * tmp4;
				
				-- calculate new s
		      s_new <= A1 * s_new;
				tmp5  <= A2 * tmp5;
				tmp6  <= B0 * tmp6;
				
		      state <= STATE_CALCULATE_NEW_DATA_4;
				
								
       --! calculate new data (4/7)
       when STATE_CALCULATE_NEW_DATA_4 =>
		 
		      -- calcualte new x
		      x_new <= x_new + tmp1;
				tmp2  <= tmp2  + x0;
				
				-- calcualte new y
		      y_new <= y_new + tmp3;
				tmp4  <= tmp4  + y0;
				
				-- calcualte new s
		      s_new <= s_new + tmp5;
				tmp6  <= tmp6  + GRANULARITY;				
				
		      state <= STATE_CALCULATE_NEW_DATA_5;
				
				
       --! calculate new data (5/7)
       when STATE_CALCULATE_NEW_DATA_5 =>
		 
		      -- calculate new x
		      x_new <= x_new + tmp2;
				
				-- calculate new y
		      y_new <= y_new + tmp4;
				
				-- calculate new s
		      s_new <= s_new + tmp6;
				
		      state <= STATE_CALCULATE_NEW_DATA_6;
				
				
       --! calculate new data (6/7): correction
       when STATE_CALCULATE_NEW_DATA_6 =>
		 
		      -- correct new x
		      if (x_new < 0) then
				            x_new <= 0;		 
				elsif ((SIZE_X * GRANULARITY) <= x_new) then
				            x_new <= SIZE_X * GRANULARITY;
				end if;
				
				-- correct new y
				if (y_new < 0) then
				  		      y_new <= 0;
				elsif ((SIZE_Y * GRANULARITY) <= y_new) then
				   	      y_new <= SIZE_Y * GRANULARITY;
				end if;
				
				-- correct new s
				if (s_new < 0) then
				            s_new <= 0;					
				elsif (s_new <= (GRANULARITY / 8)) then				
				            s_new <= GRANULARITY / 8;
            elsif ((8*GRANULARITY) <= s_new) then
                        s_new <= 8 * GRANULARITY;
				end if;
				
		      state <= STATE_CALCULATE_NEW_DATA_7;
				
		
		--! calculate new data (7/7): correction
       when STATE_CALCULATE_NEW_DATA_7 =>
		 
		      -- correct new x
		      if (x_new = (SIZE_X * GRANULARITY)) then
				
				            x_new <= x_new - 1;
				end if;
				-- correct new y
			   if (y_new = (SIZE_Y * GRANULARITY)) then
				
				            y_new <= y_new - 1;
				end if;
		      state <= STATE_WRITE_X;

				
				
		 --! write sampled particle: x
       when STATE_WRITE_X =>
		 
		      o_RAMWE <= '1';
				o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(x_new, C_BURST_DWIDTH));
				o_RAMAddr <= particle_start_address;
		      state <= STATE_WRITE_Y;	


		 --! write sampled particle: y
       when STATE_WRITE_Y =>
		 
				o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(y_new, C_BURST_DWIDTH));
				o_RAMAddr <= particle_start_address + 1;
		      state <= STATE_WRITE_S;	
				
				
		 --! write sampled particle: s
       when STATE_WRITE_S =>
		 
				o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(s_new, C_BURST_DWIDTH));
				o_RAMAddr <= particle_start_address + 2;
		      state <= STATE_WRITE_XP;	
				
				
		 --! write sampled particle: xp
       when STATE_WRITE_XP =>
		 
				o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(x, C_BURST_DWIDTH));
				o_RAMAddr <= particle_start_address + 3;
		      state <= STATE_WRITE_YP;	
				
				
		 --! write sampled particle: yp
       when STATE_WRITE_YP =>
		 
            o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(y, C_BURST_DWIDTH));
				o_RAMAddr <= particle_start_address + 4;
		      state <= STATE_WRITE_SP;	
				
				
		 --! write sampled particle: sp
       when STATE_WRITE_SP =>
		 
		      o_RAMData <= STD_LOGIC_VECTOR(TO_SIGNED(s, C_BURST_DWIDTH));
				o_RAMAddr <= particle_start_address + 5;
				particle_start_address <= particle_start_address + particle_size;
				counter <= counter + 1;
		      state <= STATE_LOAD_PARTICLE_DECISION;	

				
        -- write finished signal
		  when STATE_FINISH =>
            
            o_RAMWE <= '0';
				finished <= '1';
				if (particles_loaded = '1') then
				
				        state <= STATE_SAMPLING;
				end if;	


        when others =>
            state <= STATE_INIT;
    end case;
	end if;
  end if;
 
  end process;
end Behavioral;


