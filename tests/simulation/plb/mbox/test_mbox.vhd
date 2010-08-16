library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_mbox is

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
end test_mbox;

architecture Behavioral of test_mbox is

  constant C_MB_IN  : std_logic_vector(0 to 31) := X"00000000";
  constant C_MB_OUT : std_logic_vector(0 to 31) := X"00000001";

  type t_state is (STATE_GET, STATE_PUT);

  signal state : t_state := STATE_GET;
  signal data  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal data_inv : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
 
begin

  o_RAMAddr <= (others => '0');
  o_RAMData <= (others => '0');
  o_RAMWE   <= '0';
  o_RAMClk  <= clk;
  
  data_inv <= not data;
  
  state_proc : process(clk, reset)
    variable done : boolean;
    variable success : boolean;
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state <= STATE_GET;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

          when STATE_GET =>
            reconos_mbox_get_s(done, success, o_osif, i_osif, C_MB_IN, data);
            if done then
                state <= STATE_PUT;
            end if;
            
          when STATE_PUT =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_OUT, data_inv);
            if done then
                state <= STATE_GET;
            end if;

          when others =>
            state <= STATE_GET;
        end case;
      end if;
    end if;
  end process;
end Behavioral;


