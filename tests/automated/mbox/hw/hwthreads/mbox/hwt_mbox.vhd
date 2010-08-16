----------------------------------------------------------------------------------
-- Company: 
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hwt_mbox is

  generic (
    C_BURST_AWIDTH : integer := 12;
    C_BURST_DWIDTH : integer := 32
    );

  port (
    clk    : in  std_logic;
    reset  : in  std_logic;
    i_osif : in  osif_os2task_t;
    o_osif : out osif_task2os_t;

    -- burst ram interface
    o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
    o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
    i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
    o_RAMWE   : out std_logic;
    o_RAMClk  : out std_logic
    );
end hwt_mbox;

architecture Behavioral of hwt_mbox is

  attribute keep_hierarchy               : string;
  attribute keep_hierarchy of Behavioral : architecture is "true";

  constant C_MBOX_GET : std_logic_vector(0 to 31) := X"00000000";
  constant C_MBOX_PUT : std_logic_vector(0 to 31) := X"00000001";

  type t_state is (STATE_GET, STATE_PUT, STATE_INC);

  -- do not rely on initial values here, they won't work with
  -- partial reconfiguration
  signal state : t_state;
  signal value : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
begin

  -- burst ram interface is not used
  o_RAMAddr <= (others => '0');
  o_RAMData <= (others => '0');
  o_RAMWE   <= '0';
  o_RAMClk  <= clk;
  
  state_proc : process(clk, reset)
    variable done : boolean;
    variable success : boolean;
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state <= STATE_GET;
      value <= X"00AFFE00";
		
    elsif rising_edge(clk) then
      
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

          when STATE_GET =>
            reconos_mbox_get_s(done, success, o_osif, i_osif, C_MBOX_GET, value);
	    if done and success then state <= STATE_INC; end if;
				
	 when STATE_PUT =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_PUT, value);
	    if done and success then 
	    	state <= STATE_GET; 
	    end if;

	 when STATE_INC =>
	    value <= value + 1;
	    state <= STATE_PUT;

	 when others => state <= STATE_GET;
				
        end case;
      end if;
    end if;
  end process;
end Behavioral;

