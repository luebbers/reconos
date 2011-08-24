------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

library thermal_monitor_v1_03_a;
use thermal_monitor_v1_03_a.all;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
	generic
	(
		--C_NUM_SENSORS                  : integer              := 100;
		-- Bus protocol parameters, do not add to or delete
		C_SLV_DWIDTH                   : integer              := 32;
		C_NUM_REG                      : integer              := 1
	);
	port
	(
		Bus2IP_Clk                     : in  std_logic;
		Bus2IP_Reset                   : in  std_logic;
		Bus2IP_Data                    : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
		Bus2IP_BE                      : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
		Bus2IP_RdCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
		Bus2IP_WrCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
		IP2Bus_Data                    : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
		IP2Bus_RdAck                   : out std_logic;
		IP2Bus_WrAck                   : out std_logic;
		IP2Bus_Error                   : out std_logic;
		
		sample_clk                     : in std_logic
	);

	attribute SIGIS : string;
	attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
	attribute SIGIS of sample_clk    : signal is "CLK";
	attribute SIGIS of Bus2IP_Reset  : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
--   component icon
--     port (
--       CONTROL0 : inout std_logic_vector(35 downto 0));
--   end component;
--	
--	------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
--   component chipscope_ila
--      port (
--      CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
--      CLK   : IN STD_LOGIC;
--      TRIG0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
--      TRIG1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG8 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--      TRIG9 : IN STD_LOGIC_VECTOR(31 DOWNTO 0));
--   end component;

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of IMP: architecture is "true";

	constant C_NUM_SENSORS           : integer := C_NUM_REG;
	constant C_OSC_INIT_CYCLES       : integer := 1024*8;
	constant C_OSC_MEASURE_CYCLES    : integer := 131072; --8192;
	constant C_ADDR_WIDTH            : integer := integer(ceil(log2(real(C_NUM_SENSORS))));
	constant C_COUNTER_WIDTH         : integer := integer(ceil(log2(real(2*C_OSC_MEASURE_CYCLES))));

	-- sensor net interface

	type data_t is array(0 to C_NUM_SENSORS - 1) of std_logic_vector (C_COUNTER_WIDTH - 1 downto 0);
	
	-- data signals from all sensors
	signal data_net : data_t;
	-- debug signals for sensors
	signal osc_sig_net   : std_logic_vector (C_NUM_SENSORS - 1 downto 0);
	signal count_sig_net : std_logic_vector (C_NUM_SENSORS - 1 downto 0);
	-- data to bus logic
	signal data_out : std_logic_vector(C_COUNTER_WIDTH - 1 downto 0);
	-- enable signal for ring oscillators
	signal osc_en     : std_logic;
	-- enable signal to oscillation counters
	signal rec_en     : std_logic;
	
	-- running = '1' during measurement
	shared variable running  : std_logic;
	
	-- icon + ila signals
--	signal control0 : std_logic_vector(35 downto 0);
--	signal trig0 : std_logic_vector(3 downto 0);
--	signal trig1 : std_logic_vector(31 downto 0);
--	signal trig2 : std_logic_vector(31 downto 0);
--	signal trig3 : std_logic_vector(31 downto 0);
--	signal trig4 : std_logic_vector(31 downto 0);
--	signal trig5 : std_logic_vector(31 downto 0);
--	signal trig6 : std_logic_vector(31 downto 0);
--	signal trig7 : std_logic_vector(31 downto 0);
--	signal trig8 : std_logic_vector(31 downto 0);
--	signal trig9 : std_logic_vector(31 downto 0);
	
begin
   -- instantiate ila and icon;
--	icon_i : icon
--    port map (
--      CONTROL0 => control0);
--		
--   ila_i : chipscope_ila
--    port map (
--       CONTROL => control0,
--       CLK => sample_clk,
--       TRIG0 => trig0,
--       TRIG1 => trig1,
--       TRIG2 => trig2,
--       TRIG3 => trig3,
--       TRIG4 => trig4,
--       TRIG5 => trig5,
--       TRIG6 => trig6,
--       TRIG7 => trig7,
--       TRIG8 => trig8,
--       TRIG9 => trig9);
--		 
--	trig0(3) <= osc_en;
--	trig0(2) <= rec_en;
--	trig0(1) <= Bus2IP_Reset;
--	trig0(0) <= sample_clk;


	-- Note: contrary to the documentation read and write ack signals can not be tied to '1'.
	--       This would lead to the bus being locked forever.

	-- connect data_out to bus logic
	IP2Bus_Data(C_SLV_DWIDTH - 1 downto C_COUNTER_WIDTH) <= (others => '0');
	IP2Bus_Data(C_COUNTER_WIDTH - 1 downto 0) <= data_out;

	-- array of thermal sensors
	thermal_sensors : for i in C_NUM_SENSORS - 1 downto 0 generate
	begin
		sensor : entity thermal_sensor 
		generic map (C_COUNTER_WIDTH => C_COUNTER_WIDTH)
		port map ( 
			clk => sample_clk,
			rst => Bus2IP_Reset,
			rec_en => rec_en,
			osc_en => osc_en,
			data => data_net(i),
			osc_sig   => osc_sig_net(i),
			count_sig => count_sig_net(i)
		);
		
	end generate thermal_sensors;
	
--   debug_proc : process (osc_sig_net, count_sig_net) is 
--	 variable i : std_logic;
--	begin
--	  for i in 0 to C_NUM_SENSORS - 1 loop
--	   if i < 16 then
--		  trig1(2*i)         <= osc_sig_net(i);
--		  trig1(2*i+1)       <= count_sig_net(i);
--		elsif i < 32 then
--		  trig2(2*(i-16))    <= osc_sig_net(i);
--		  trig2(2*(i-16)+1)  <= count_sig_net(i);
--		elsif i < 48 then
--		  trig3(2*(i-32))    <= osc_sig_net(i);
--		  trig3(2*(i-32)+1)  <= count_sig_net(i);
--		elsif i < 64 then
--		  trig4(2*(i-48))    <= osc_sig_net(i);
--		  trig4(2*(i-48)+1)  <= count_sig_net(i);
--		elsif i < 80 then
--		  trig5(2*(i-64))    <= osc_sig_net(i);
--		  trig5(2*(i-64)+1)  <= count_sig_net(i);
--		elsif i < 96 then
--        trig6(2*(i-80))    <= osc_sig_net(i);
--		  trig6(2*(i-80)+1)  <= count_sig_net(i);
--      elsif i < 112 then
--		  trig7(2*(i-96))    <= osc_sig_net(i);
--		  trig7(2*(i-96)+1)  <= count_sig_net(i);
--		elsif i < 128 then
--		  trig8(2*(i-112))   <= osc_sig_net(i);
--		  trig8(2*(i-112)+1) <= count_sig_net(i);
--		elsif i < 144 then
--        trig9(2*(i-128))   <= osc_sig_net(i);
--		  trig9(2*(i-128)+1) <= count_sig_net(i);
--      end if;
--	  end loop;
--	end process;

	-- mux sensor signals to data_out, generate read ack
	process(data_net) is
	begin
		IP2Bus_RdAck <= '0';
		data_out <= (others => '0');
		for i in C_NUM_SENSORS - 1 downto 0 loop
			if Bus2IP_RdCE(i) = '1' then
				data_out <= data_net(i);
				if running = '0' then
					IP2Bus_RdAck <= '1';
				end if;
			end if;
		end loop;
	end process;

	-- measurement process, generate write ack
	process(Bus2IP_Clk, Bus2IP_Reset) is
		variable counter : integer range 0 to (2*(C_OSC_INIT_CYCLES + C_OSC_MEASURE_CYCLES));
		--variable running : std_logic;
		variable ack : std_logic;
	begin
		if Bus2IP_Reset = '1' then
			counter := 0;
			running := '1';
			osc_en <= '0';
			rec_en <= '0';
			IP2Bus_WrAck <= '0';
		elsif rising_edge(Bus2IP_Clk) then
			
			-- generate write ack
			
			IP2Bus_WrAck <= '0';
			ack := '0';
			for i in C_NUM_REG - 1 downto 0 loop 
				ack := ack or Bus2IP_WrCE(i);
			end loop;
			IP2Bus_WrAck <= ack;
			
			-- oscillator timing
			
			if ack = '1' then
				if running = '0' then counter := 0; end if;
				running := '1';
			end if;
			
			-- wait for oscillators to settle to a constant frequency, then perform measurement
			if running = '1' then
				counter := counter + 1;
				osc_en <= '1';
				if counter > C_OSC_INIT_CYCLES then
					rec_en <= '1';
				end if;
				if counter = C_OSC_INIT_CYCLES + C_OSC_MEASURE_CYCLES then
					running := '0';
					rec_en <= '0';
					osc_en <= '0';
				end if;
			end if;
		end if;
	end process;

	-- no errors since all reads and writes are valid
	IP2Bus_Error <= '0';

end IMP;
