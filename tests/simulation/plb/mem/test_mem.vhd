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

entity test_mem is

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
end test_mem;

architecture Behavioral of test_mem is

  constant C_READ_MEM  : std_logic_vector(0 to 31) := X"10000004";
  constant C_WRITE_MEM : std_logic_vector(0 to 31) := X"20000004";

  type t_state is (STATE_INIT, STATE_READ_SINGLE, STATE_WRITE_SINGLE, STATE_READ_BURST, 
                   STATE_ADD, STATE_ADD_INC, STATE_WRITE_BURST, STATE_EXIT);

  signal state : t_state := STATE_INIT;
  signal in_value : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal out_value : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal init_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  signal RAMAddr : std_logic_vector(0 to C_BURST_AWIDTH-1) ;
begin

  -- burst ram interface is not used
  o_RAMAddr <= RAMAddr;
  o_RAMData <= i_RAMData + init_data;
  o_RAMClk  <= clk;


  out_value <= in_value + init_data;
  
  -- for i in 0 to 15 do
  --    read a 32-bit word from 10000000 + i
  --    add 0x01010101 to it (or whatever is in init_data)
  --    write it to 20000000 + i
  
  
  state_proc : process(clk, reset)
    variable counter : integer range 0 to 512;
    variable done : boolean;
    variable success : boolean;
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      state <= STATE_INIT;
      counter := 0;
      RAMAddr <= (others => '0');
      o_RAMWE   <= '0';
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

          when STATE_INIT =>
            reconos_get_init_data_s (done, o_osif, i_osif, init_data);
            if done then 
                counter := 0;
                state <= STATE_READ_SINGLE;
            end if;
            
          when STATE_READ_SINGLE =>
            reconos_read_s(done, o_osif, i_osif, C_READ_MEM + counter, in_value);
            if done then
                state <= STATE_WRITE_SINGLE;
            end if;

          when STATE_WRITE_SINGLE =>
            reconos_write(done, o_osif, i_osif, C_WRITE_MEM + counter, out_value);
            if done then 
                if counter = 15 then
                    counter := 2;                   -- bursts work only from 2 data beats up
                    state <= STATE_READ_BURST;
                else
                    counter := counter + 1;
                    state <= STATE_READ_SINGLE;
                end if;
            end if;
            
            
            when STATE_READ_BURST =>
              reconos_read_burst_l( done, o_osif, i_osif, X"00000000", C_READ_MEM, counter);
              if done then
                  state <= STATE_ADD;
                  RAMAddr <= (others => '0');
              end if;
              
              when STATE_ADD =>
                  if RAMAddr = counter*2 then
                      state <= STATE_WRITE_BURST;
                  else
                      o_RAMWE <= '1';
                      state <= STATE_ADD_INC;
                  end if;
                  
              when STATE_ADD_INC =>
                   o_RAMWE <= '0';
                   RAMAddr <= RAMAddr + 1;
                   state <= STATE_ADD;

              when STATE_WRITE_BURST =>
                reconos_write_burst_l( done, o_osif, i_osif, X"00000000", C_WRITE_MEM, counter);
                if done then
                    if counter = 512 then
                        counter := 0;
                        state <= STATE_EXIT;
                    else
                        counter := counter + 1;
                        state <= STATE_READ_BURST;
                    end if;
                end if;

            
          when STATE_EXIT =>
            reconos_thread_exit (o_osif, i_osif, C_RECONOS_SUCCESS);
            state <= STATE_EXIT;

          when others =>
            state <= STATE_INIT;
        end case;
      end if;
    end if;
  end process;
end Behavioral;


