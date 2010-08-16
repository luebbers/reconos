
------------
-- pcore top level wrapper
-- generated at 2008-02-11 12:40:48.826899 by 'mkhwtask.py hwt_semaphore_post 1 ../src/hwt_semaphore_post.vhd'
------------
	
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_00_a;
use reconos_v2_00_a.reconos_pkg.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hw_task is
	generic (
		C_BUS_BURST_AWIDTH : integer := 13;		-- Note: This addresses bytes
		C_BUS_BURST_DWIDTH : integer := 64;
		C_TASK_BURST_AWIDTH : integer := 11;     -- this addresses 32Bit words
		C_TASK_BURST_DWIDTH : integer := 32
	);

	port (
		clk : in std_logic;
		reset : in std_logic;
		i_osif_flat : in std_logic_vector;
		o_osif_flat : out std_logic_vector;
		
		-- burst mem interface
		i_burstAddr : in std_logic_vector(0 to C_BUS_BURST_AWIDTH-1);
		i_burstData : in std_logic_vector(0 to C_BUS_BURST_DWIDTH-1);
		o_burstData : out std_logic_vector(0 to C_BUS_BURST_DWIDTH-1);
		i_burstWE   : in std_logic;

      -- time base
      i_timeBase : in std_logic_vector( 0 to C_OSIF_DATA_WIDTH-1 )
		
	);
	
end hw_task;

architecture structural of hw_task is
	
	component burst_ram
		port (
		addra: IN std_logic_VECTOR(10 downto 0);
		addrb: IN std_logic_VECTOR(9 downto 0);
		clka: IN std_logic;
		clkb: IN std_logic;
		dina: IN std_logic_VECTOR(31 downto 0);
		dinb: IN std_logic_VECTOR(63 downto 0);
		douta: OUT std_logic_VECTOR(31 downto 0);
		doutb: OUT std_logic_VECTOR(63 downto 0);
		wea: IN std_logic;
		web: IN std_logic
	);
	end component;
	
	signal o_osif_flat_i : std_logic_vector(0 to 41);
	signal i_osif_flat_i : std_logic_vector(0 to 44);
	signal o_osif : osif_task2os_t;
	signal i_osif : osif_os2task_t;
	
	signal task2burst_Addr : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
	signal task2burst_Data : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
	signal burst2task_Data : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
	signal task2burst_WE   : std_logic;
	signal task2burst_Clk  : std_logic;
	
	attribute keep_hierarchy : string;
	attribute keep_hierarchy of structural: architecture is "true";

begin

	-- connect top level signals
	o_osif_flat <= o_osif_flat_i;
	i_osif_flat_i <= i_osif_flat;
	
	-- (un)flatten osif records
	o_osif_flat_i <= to_std_logic_vector(o_osif);
	i_osif <= to_osif_os2task_t(i_osif_flat_i);
	
	-- instantiate user task
	hwt_semaphore_post_i : entity hwt_semaphore_post
	port map (
		clk => clk,
		reset => reset,
		i_osif => i_osif,
		o_osif => o_osif,
		o_RAMAddr => task2burst_Addr,
		o_RAMData => task2burst_Data,
		i_RAMData => burst2task_Data,
		o_RAMWE => task2burst_WE,
		o_RAMClk => task2burst_Clk,
		i_timeBase => i_timeBase
	);
				 
	burst_ram_i : burst_ram
		port map (
			addra => task2burst_Addr,
			addrb => i_burstAddr(0 to C_BUS_BURST_AWIDTH-1 -3),		-- RAM is addressing 64Bit values
			clka => task2burst_Clk,
			clkb => clk,
			dina => task2burst_Data,
			dinb => i_burstData,
			douta => burst2task_Data,
			doutb => o_burstData,
			wea => task2burst_WE,
			web => i_burstWE
		);

end structural;
