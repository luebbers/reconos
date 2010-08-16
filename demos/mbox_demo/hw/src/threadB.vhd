--
-- threadB.vhd
-- demo thread
-- Waiting on its local read FIFO, this thread will transfer 8 kB of data
-- from the FIFO to its burst RAM, and then burst that to a main memory
-- address determined by its init data.
-- Both transactions are timed, and sent to C_MBOX_GETTIME, 
-- C_MBOX_WRITETIME respectively.
--
-- NOTE: These measurements may not be entirely accurate due to the bus load
-- incurred by the OS commands.
--
-- Author:     Enno Luebbers   <luebbers@reconos.de>
-- Date:       15.10.2007
--
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- University of Paderborn, Computer Engineering Group.
--
-- (C) Copyright University of Paderborn 2007.
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity threadB is

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
    o_RAMClk  : out std_logic;
	 
	 i_timeBase : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)
    );
end threadB;

architecture Behavioral of threadB is

  -- timer address (FIXME: hardcoded!)
  constant TIMER_ADDR : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"50004000";

  -- ReconOS resources used by this thread
  constant C_MB_TRANSFER  : std_logic_vector(0 to 31) := X"00000000";
  constant C_MB_GETTIME   : std_logic_vector(0 to 31) := X"00000001";
  constant C_MB_WRITETIME : std_logic_vector(0 to 31) := X"00000002";

  -- OS synchronization state machine states (TODO: measurements!)
  type t_state is (
	STATE_INIT, 
	STATE_GETTIME_START, 
	STATE_TRANSFER, 
	STATE_GETTIME_STOP, 
	STATE_WRITE, 
	STATE_WRITETIME_STOP, 
	STATE_POST_GETTIME_1, 
	STATE_POST_GETTIME_2, 
	STATE_POST_WRITETIME_1,
	STATE_POST_WRITETIME_2,
        STATE_ERROR
  );
  signal state : t_state := STATE_INIT;

  -- address of data to sort in main memory
  signal address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

  -- timing values
  signal gettime   : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0001";
  signal writetime : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0002";

  -- RAM address
  signal RAMAddr : std_logic_vector(0 to C_BURST_AWIDTH-1);
  signal RAMAddr_d1 : std_logic_vector(0 to C_BURST_AWIDTH-1);	-- delay by one


begin

  -- hook up RAM signals
  o_RAMClk  <= clk;
  o_RAMAddr <= RAMAddr_d1(0 to C_BURST_AWIDTH-2) & not RAMAddr_d1(C_BURST_AWIDTH-1);  -- invert LSB of address to get the word ordering right
  

  -- delay RAM address
  delay_proc : process(clk)
  begin
    if rising_edge(clk) then
	RAMAddr_d1 <= RAMAddr;
    end if;
  end process;


  -- OS synchronization state machine
  state_proc               : process(clk, reset)
    variable done          : boolean;
    variable success       : boolean;
    variable burst_counter : natural range 0 to 8192/128 - 1;		-- transfer 128 bytes at once
    variable trans_counter : natural range 0 to 8192/4 - 1;		-- transfer 4 bytes at once
    -- timing values
    variable writetime_1  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0001";
    variable writetime_2  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0001";
    variable gettime_1 : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0002";
    variable gettime_2 : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0002";
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      address <= (others => '0');
      state      <= STATE_INIT;
		o_RAMWE <= '0';
		o_RAMData <= (others => '0');
      burst_counter := 0;
      trans_counter := 0;
    elsif rising_edge(clk) then
      reconos_begin(o_osif, i_osif);
      if reconos_ready(i_osif) then
        case state is

	  -- read init data
          when STATE_INIT =>
	    reconos_get_init_data_s(done, o_osif, i_osif, address);
            if done then
		trans_counter := 0;
		RAMAddr <= (others => '0');
		state <= STATE_GETTIME_START;
	    end if;

	  -- get start time of FIFO transfer
	  when STATE_GETTIME_START =>
              gettime_1 := i_timeBase;
--	    reconos_read(done, o_osif, i_osif, TIMER_ADDR, gettime_1);
--	    if done then
	            state <= STATE_TRANSFER;
--	    end if;


            -- transfer data across mailbox
	    -- this state also hides the RAM access timing, since this is a multi-cycle
 	    -- command, and the "data" parameter is only transferred in the second cycle.
          when STATE_TRANSFER =>
		o_RAMWE <= '0';
                if trans_counter = 0 then
                    gettime_1 := i_timeBase;
                end if;
		reconos_mbox_get_s(done, success, o_osif, i_osif, C_MB_TRANSFER, o_RAMData);
                if done then
                    if success then
			o_RAMWE <= '1';
			if trans_counter = 8192/4 - 1 then
				burst_counter := 0;
				state <= STATE_GETTIME_STOP;
			else
				RAMAddr <= RAMAddr + 1;	-- note that this is delayed by one clock cycle
				trans_counter := trans_counter + 1;
			end if;
                    else -- no success
                        state <= STATE_ERROR;
                    end if;
		end if;

	  -- get stop time of FIFO transfer
	  when STATE_GETTIME_STOP =>
	    o_RAMWE <= '0';
            gettime_2 := i_timeBase;
--	    reconos_read(done, o_osif, i_osif, TIMER_ADDR, gettime_2);
--	    if done then
		    writetime_1 := gettime_2;
                    state <= STATE_WRITE;
--	    end if;

            -- write data from local burst RAM into main memory
          when STATE_WRITE =>
            reconos_write_burst (done, o_osif, i_osif, std_logic_vector(TO_UNSIGNED(burst_counter*128, C_OSIF_DATA_WIDTH)), address+(burst_counter*128));
            if done then
              if burst_counter = 8192/128 - 1 then
                state <= STATE_WRITETIME_STOP;
              else
                burst_counter := burst_counter + 1;
              end if;
            end if;

	  -- get stop time of burst transfer
	  when STATE_WRITETIME_STOP =>
              writetime_2 := i_timeBase;
--	    reconos_read(done, o_osif, i_osif, TIMER_ADDR, writetime_2);
--	    if done then
	            state <= STATE_POST_GETTIME_1;
--	    end if;

            -- write transfer time to mailbox
          when STATE_POST_GETTIME_1 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_GETTIME, gettime_1);
            if done and success then
              state <= STATE_POST_GETTIME_2;
            end if;

          when STATE_POST_GETTIME_2 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_GETTIME, gettime_2);
            if done and success then
              state <= STATE_POST_WRITETIME_1;
            end if;

            -- write write time to mailbox
          when STATE_POST_WRITETIME_1 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_WRITETIME, writetime_1);
            if done and success then
		state <= STATE_POST_WRITETIME_2;
            end if;

          when STATE_POST_WRITETIME_2 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_WRITETIME, writetime_2);
            if done and success then
		trans_counter := 0;
		RAMAddr <= (others => '0');
		state <= STATE_TRANSFER;
            end if;

          when STATE_ERROR =>
              reconos_thread_exit(o_osif, i_osif, X"00000" & RAMAddr);

          when others =>
            state <= STATE_INIT;
        end case;
      end if;
    end if;
  end process;
end Behavioral;


