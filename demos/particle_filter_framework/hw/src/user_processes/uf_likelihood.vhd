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
	 -- start signal for the likelihood user process
	 observation_loaded           : in std_logic;
	 -- address of reference data
	 ref_data_address    : in std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
	 -- address of observation
	 observation_address : in std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
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
	  rfd   : out std_logic;
	  clk   : in std_logic;
	  ce    : in std_logic);
end component;


  -- GRANULARITY
  constant GRANULARITY : integer := 16384;
  
  -- type for likelihood look up table
  type likelihood_function is array ( 0 to 128) of integer;
  
  -- likelihood look up table
--  constant likelihood_values : likelihood_function := (
--     1, 1, 1, 1, 1, 1, 2, 2, 2, 3,
--     3, 3, 4, 5, 5, 6, 7, 8, 9, 10,
--     12, 13, 15, 17, 20, 22, 25, 29, 33, 37,
--     42, 48, 54, 61, 70, 79, 90, 102, 115, 130,
--     148, 168, 190, 215, 244, 277, 314, 356, 403, 457,
--     518, 586, 665, 753, 854, 967, 1096, 1242, 1408, 1595,
--     1808, 2048, 2321, 2630, 2980, 3377, 3827, 4337, 4914, 5569,
--     6310, 7150, 8103, 9181, 10404, 11789, 13359, 15138, 17154, 19438,
--     22026, 24959, 28282, 32048, 36315, 41150, 46630, 52838, 59874, 67846,
--     76879, 87116, 98715, 111859, 126753, 143630, 162754, 184425, 208981, 236806,
--     268337, 304065, 344551, 390428, 442413, 501320, 568070, 643707, 729416, 826537,
--     936589, 1061294, 1202604, 1362729, 1544174, 1749778, 1982759, 2246760, 2545913, 2884897,
--     3269017, 3704281, 4197501, 4756392, 5389698, 6107328, 6920509, 7841965, 8886110);

constant likelihood_values : likelihood_function := (
      1, 1, 1, 1, 1, 1, 1, 1, 1, 2,
      2, 2, 2, 2, 3, 3, 3, 4, 4, 4,
      5, 5, 6, 6, 7, 8, 8, 9, 10, 11,
      12, 13, 14, 15, 17, 18, 20, 21, 23, 25,
      28, 30, 33, 35, 39, 42, 46, 50, 54, 59,
      64, 70, 76, 82, 90, 97, 106, 115, 125, 136,
      148, 161, 175, 190, 207, 225, 244, 265, 289, 314,
      341, 371, 403, 438, 476, 518, 563, 611, 665, 722,
      785, 854, 928, 1008, 1096, 1191, 1295, 1408, 1530, 1663,
      1808, 1965, 2135, 2321, 2523, 2742, 2980, 3240, 3521, 3827,
      4160, 4521, 4914, 5341, 5806, 6310, 6859, 7455, 8103, 8807,
      9572, 10404, 11308, 12291, 13359, 14520, 15782, 17154, 18644, 20265,
      22026, 23940, 26021, 28282, 30740, 33411, 36315, 39471, 42901 );
  
  -- LAMBDA
  --constant LAMBDA : integer := 16.0;
  
  -- local RAM addresses
  signal current_ref_data_address    : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  signal current_observation_address : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
  
  -- particle counter
  signal counter : integer := 0;
   
  -- signals for histogram values
  signal ref_value         : integer := 0;
  signal observation_value : integer := 0;
  -- sum of all values
  signal sum               : integer := 0;
  -- root of sum
  signal sum_root          : integer := 0;
  --signal pow               : integer := 0;
  signal sum_update        : integer := 0;
  signal likelihood        : integer := 0;
  
 
  -- states
  type t_state is (STATE_INIT, STATE_LOAD_VALUES_DECISION, STATE_LOAD_VALUES_1,
     STATE_LOAD_VALUES_2, STATE_LOAD_HIST_1, STATE_LOAD_HIST_2,
     STATE_CALCULATE_SUM_UPDATE_1, STATE_CALCULATE_SUM_UPDATE_2, 
	  STATE_CALCULATE_SUM_UPDATE_3, STATE_CALCULATE_SUM_UPDATE_4,
	  STATE_CALCULATE_SUM_UPDATE_5, STATE_CALCULATE_SUM_UPDATE_6,	  
	  STATE_UPDATE_SUM, STATE_CALCULATE_LIKELIHOOD_1,
	  STATE_CALCULATE_LIKELIHOOD_2, STATE_CALCULATE_LIKELIHOOD_3,
	  STATE_CALCULATE_LIKELIHOOD_4, STATE_CALCULATE_LIKELIHOOD_5,
	  STATE_CALCULATE_LIKELIHOOD_6, STATE_CALCULATE_LIKELIHOOD_7,
	  STATE_FINISH);
	  
	-- current state
   signal state : t_state := STATE_INIT;
	
	-- signals for square root component
	signal x_in2 : natural := 0;
	signal x_in3 : natural := 0;
	signal x_in  : std_logic_vector(31 downto 0) := (others => '0');
	signal x_out : std_logic_vector(16 downto 0) := (others => '0');
	signal x_out2: natural := 0;
	signal x_out3: natural := 0;
	signal nd    : std_logic := '0';
	signal rdy   : std_logic := '1';
	signal rfd   : std_logic := '1';
	signal ce    : std_logic := '1';
	
  
begin

--! square root calculation
square_root: square_root_component
		port map (x_in => x_in, nd => nd, x_out => x_out,
    		       rdy => rdy, rfd => rfd, clk => clk, ce => ce);



  -- burst ram interface
  o_RAMWE   <= '0';
  o_RAMClk  <= clk;

--
-- Likelihood calculation
--
-- 0) i = 0;
--    sum = 0.0;
-- 
-- 1) if ( i < 110 ) then
--        go to step 2
--    else
--        go to step 6
--    end if
-- 
-- 2) hist1 = reference_histogram[i]
-- 
-- 3) hist2 = observation_histogram[i]
-- 
-- 4) sum_update = sqrt ((hist1 * hist2) / GRANULARITY)
-- 
-- 5) sum += sum_update
--    i++
--    go to step 1
-- 
-- 6) likelihood = exp (- LAMBDA * (1.0 - sum))
-- 

  ce <= enable;

  state_proc : process(clk, reset)

  begin

  if (reset = '1') then
 
		 state <= STATE_INIT;
		 finished <= '0';

  elsif rising_edge(clk) then
	if init = '1' then
	
	        state <= STATE_INIT;
			  finished <= '0';
			  o_RAMData <= (others=>'0');
			  o_RAMAddr <= (others => '0');
			  
   elsif enable = '1' then
	    case state is

        --! init data
        when STATE_INIT =>
		  
			  counter  <= 0;
			  finished <= '0';
			  current_ref_data_address    <= ref_data_address;
			  --sum <= 0.0;
			  sum <= 0;
			  current_observation_address <= observation_address;
			  if (observation_loaded = '1') then
			        state <= STATE_LOAD_VALUES_DECISION;
			  end if;
			  
		
		  --! if not all histogram values are loaded and calculated, then do it.
		  --  Else calculate likelihood
		  when STATE_LOAD_VALUES_DECISION =>
		  
		     if (counter < observation_size) then
			  
			       state <= STATE_LOAD_VALUES_1;
			  else
			  
			       state <= STATE_CALCULATE_LIKELIHOOD_1;
			  end if;
			  
		  
		  --! load histogram value 1 of 2
		  when STATE_LOAD_VALUES_1 =>
		  
		       o_RAMAddr <= current_ref_data_address;
				 state <= STATE_LOAD_VALUES_2;
			
			
		  --! load histogram value 2 of 2
		  when STATE_LOAD_VALUES_2 =>
		  
		       o_RAMAddr <= current_observation_address;
				 state <= STATE_LOAD_HIST_1;
				 
				 
		  --! load reference histogram value
		  when STATE_LOAD_HIST_1 =>		  
		  
		       ref_value <= TO_INTEGER(SIGNED(i_RAMData));
				 state <= STATE_LOAD_HIST_2;
				 
				 
		  --! load observation histogram value
		  when STATE_LOAD_HIST_2 =>		  
		  
		       observation_value <= TO_INTEGER(SIGNED(i_RAMData));
				 state <= STATE_CALCULATE_SUM_UPDATE_1;


        --! calculate sum update (1 of 6): product = ref_hist * observation_hist
        when STATE_CALCULATE_SUM_UPDATE_1 =>
		  
		       --sum_update <= ref_value * observation_value;
				 --state      <= STATE_UPDATE_SUM;
				 --! TODO: CHANGE BACK (1 of 1)
             ref_value <= ref_value * observation_value;
				 state <= STATE_CALCULATE_SUM_UPDATE_2;

				 
        --! calculate sum update (2 of 6): sum_update = product
        when STATE_CALCULATE_SUM_UPDATE_2 =>
		  
		       --sum_update <= real(ref_value);
				 --sum_update <= ref_value;
				 x_in2 <= ref_value;
				 --if (rfd = '1') then
				 state <= STATE_CALCULATE_SUM_UPDATE_3;
				 --end if;


	        --! calculate sum update (3 of 6): get sqrt (1/3)
        when STATE_CALCULATE_SUM_UPDATE_3 =>
		  
             --sum_update <= sum_update / GRANULARITY;
				 --sum_update <= sum_update / 512;
				 --state <= STATE_UPDATE_SUM;
				 x_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(x_in2, 32));
				 nd   <= '1';
				 state <= STATE_CALCULATE_SUM_UPDATE_4;
				 
				 
	        --! calculate sum update (4 of 6): get sqrt (2/3)
        when STATE_CALCULATE_SUM_UPDATE_4 =>
		  
		       --sum_update <= sqrt(sum_update);
				 
				 nd <= '0';
				 if (rdy = '1') then 
				      state <= STATE_CALCULATE_SUM_UPDATE_5;
				 end if;
				 
				 
		        --! calculate sum update (5 of 6): get sqrt (3/3)
        when STATE_CALCULATE_SUM_UPDATE_5 =>
		  
		       --sum_update <= sqrt(sum_update);
				 
				 x_out2 <= TO_INTEGER(UNSIGNED(x_out));
             state <= STATE_CALCULATE_SUM_UPDATE_6;				 


		        --! calculate sum update (6 of 6): sum_update = sqrt (ref_value * observation_value)
        when STATE_CALCULATE_SUM_UPDATE_6 =>
		  
		       --sum_update <= sqrt(sum_update);
				 -- needs correction
				 --sum_update <= ref_value;
				 -- CHANGE BACK (5 of 6) !!! 
				 sum_update <= x_out2;
				 state <= STATE_UPDATE_SUM;			 


        --! update sum (+= sum_update) and update counter and current addresses
        when STATE_UPDATE_SUM =>

              --sum <= sum + sum_update;
				  sum <= sum + sum_update;
				  counter <= counter + 1;
				  current_ref_data_address    <= current_ref_data_address    + 1;
				  current_observation_address <= current_observation_address + 1;
              state <= STATE_LOAD_VALUES_DECISION;


        --! calculate likelihood (1 of 7): 
        when STATE_CALCULATE_LIKELIHOOD_1 =>

             x_in3 <= sum;
				 --pow <= sum / 2048;
				 --CHANGE BACK (6 of 6) !!! 
				 --pow <= sum / 32;
             state <= STATE_CALCULATE_LIKELIHOOD_2; 
		
		
        --! calculate likelihood (2 of 7): 
        when STATE_CALCULATE_LIKELIHOOD_2 =>

             -------likelihood <= - LAMBDA * likelihood;
				 x_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(x_in3, 32));
				 nd   <= '1';
--				 if (pow > 20) then 
--				         pow <= 20;
--				 elsif (pow < 0) then
--				         pow <= 0;
--             end if;
--				 likelihood <= 1;
				 state <= STATE_CALCULATE_LIKELIHOOD_3; 
				 
				 
        --! calculate likelihood (3 of 7): 
        when STATE_CALCULATE_LIKELIHOOD_3 =>
		  
		       nd <= '0';
				 if (rdy = '1') then 
				      state <= STATE_CALCULATE_LIKELIHOOD_4;
				 end if;

--             if (pow > 0) then
--				 
--				      likelihood <= likelihood * 3;
--				      pow <= pow - 1;
--				 else
--				      
--						state <= STATE_FINISH;
--				 end if;
             --likelihood <= exp(likelihood);
				 --likelihood <= 3**(likelihood/2048);
             --state <= STATE_FINISH; 	

				 
        --! calculate likelihood (4 of 7): 
        when STATE_CALCULATE_LIKELIHOOD_4 =>
		  
               x_out3 <= TO_INTEGER(UNSIGNED(x_out));
				   state <= STATE_CALCULATE_LIKELIHOOD_5;
					
					

					
	        --! calculate likelihood (5 of 7): 
        when STATE_CALCULATE_LIKELIHOOD_5 =>
		  
               sum_root <= x_out3;
				   state <= STATE_CALCULATE_LIKELIHOOD_6;


	        --! calculate likelihood (6 of 7): 
        when STATE_CALCULATE_LIKELIHOOD_6 =>
		  
               if (sum_root > 128) then
					
					    sum_root <= 128;
						 
				   elsif (sum_root < 0) then
					
					    sum_root <= 0;
					end if;
				   state <= STATE_CALCULATE_LIKELIHOOD_7;	


	        --! calculate likelihood (7 of 7): 
        when STATE_CALCULATE_LIKELIHOOD_7 =>
		  
               likelihood <= likelihood_values(sum_root);
				   state <= STATE_FINISH;					
					

        --! write finished signal and likelihood value
		  when STATE_FINISH =>
            
				finished <= '1';
				--likelihood_value <= integer(GRANULARITY * likelihood);
				likelihood_value <= likelihood;
				--likelihood_value <= 12;
				if (observation_loaded = '1') then
				
				        state <= STATE_INIT;
				end if;	


        when others =>
            state <= STATE_INIT;
    end case;
	end if;
  end if;
 
  end process;
end Behavioral;


