-- condition variable test
-- modeled after the eCos condvar example
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

entity test_condvar is

  generic (
    C_BURST_AWIDTH : integer := 11;
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
end test_condvar;

architecture Behavioral of test_condvar is

  constant C_MY_MUTEX   : std_logic_vector(0 to 31) := X"00000000";
  constant C_MY_CONDVAR : std_logic_vector(0 to 31) := X"00000001";

  type t_state is (STATE_INIT, STATE_LOCK, STATE_READ, STATE_WAIT, STATE_WRITE, STATE_UNLOCK);

  signal state : t_state := STATE_INIT;
  signal res_count : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal init_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
begin

  -- burst ram interface is not used
  o_RAMAddr <= (others => '0');
  o_RAMData <= (others => '0');
  o_RAMWE   <= '0';
  o_RAMClk  <= '0';

  state_proc : process(clk, reset)
    variable done : boolean;
    variable success : boolean;
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state <= STATE_INIT;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

          when STATE_INIT =>
            reconos_get_init_data_s (done, o_osif, i_osif, init_data);  -- get address of res_count
            if done then 
                state <= STATE_LOCK;
            end if;
            
          when STATE_LOCK =>
            reconos_mutex_lock (done, success, o_osif, i_osif, C_MY_MUTEX);
            if done and success then
                state <= STATE_READ;
            end if;

          when STATE_READ =>
            reconos_read_s(done, o_osif, i_osif, init_data, res_count);
            if done then
              state <= STATE_WAIT;
            end if;
            
          when STATE_WAIT =>
            if res_count = X"00000000" then
                reconos_cond_wait(done, success, o_osif, i_osif, C_MY_CONDVAR);
                if done and success then
                    state <= STATE_READ;
                end if;
            else
                state <= STATE_WRITE;
            end if;

          when STATE_WRITE =>
            reconos_write(done, o_osif, i_osif, init_data, res_count - 1);
            if done then 
              state <= STATE_UNLOCK;
            end if;
            
          when STATE_UNLOCK =>
            reconos_mutex_unlock (o_osif, i_osif, C_MY_MUTEX);
            state <= STATE_LOCK;

          when others =>
            state <= STATE_INIT;
        end case;
      end if;
    end if;
  end process;
end Behavioral;


