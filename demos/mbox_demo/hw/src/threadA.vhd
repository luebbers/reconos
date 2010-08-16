--
-- threadA.vhd
-- demo thread
-- After waiting on C_SEM_START, it reads a block of 8 kBytes from memory 
-- (using its init_data as address) then sends that data one by one to mail 
-- box C_MBOX_TRANSFER. Both transactions are timed, and sent to C_MBOX_READTIME, 
-- C_MBOX_PUTTIME respectively.
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

entity threadA is

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
end threadA;

architecture Behavioral of threadA is

  -- timer address (FIXME: hardcoded!)
  constant TIMER_ADDR : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"50004000";

  -- ReconOS resources used by this thread
  constant C_SEM_START    : std_logic_vector(0 to 31) := X"00000000";
  constant C_MB_TRANSFER  : std_logic_vector(0 to 31) := X"00000001";
  constant C_MB_READTIME  : std_logic_vector(0 to 31) := X"00000002";
  constant C_MB_PUTTIME   : std_logic_vector(0 to 31) := X"00000003";

  -- OS synchronization state machine states (TODO: measurements!)
  type t_state is (
	STATE_INIT, 
	STATE_WAIT, 
	STATE_READTIME_START, 
	STATE_READ, 
	STATE_READTIME_STOP, 
	STATE_TRANSFER, 
	STATE_PUTTIME_STOP, 
	STATE_POST_READTIME_1, 
	STATE_POST_READTIME_2, 
	STATE_POST_PUTTIME_1,
	STATE_POST_PUTTIME_2
  );
  signal state : t_state := STATE_INIT;

  -- address of data to sort in main memory
  signal address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');

  -- RAM address
  signal RAMAddr : std_logic_vector(0 to C_BURST_AWIDTH-1);


begin

  -- hook up RAM signals
  o_RAMClk  <= clk;
  o_RAMAddr <= RAMAddr(0 to C_BURST_AWIDTH-2) & not RAMAddr(C_BURST_AWIDTH-1);  -- invert LSB of address to get the word ordering right
  o_RAMWE <= '0';
  o_RAMData <= (others => '0');
  


  -- OS synchronization state machine
  state_proc               : process(clk, reset)
    variable done          : boolean;
    variable success       : boolean;
    variable burst_counter : natural range 0 to 8192/128 - 1;		-- transfer 128 bytes at once
    variable trans_counter : natural range 0 to 8192/4 - 1;		-- transfer 4 bytes at once
    -- timing values
    variable readtime_1  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0001";
    variable readtime_2  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0001";
    variable puttime_1 : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0002";
    variable puttime_2 : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0002";
  begin
    if reset = '1' then
      reconos_reset(o_osif, i_osif);
      address <= (others => '0');
      state      <= STATE_INIT;
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
		state <= STATE_WAIT;
	    end if;

          -- wait for start semaphore
          when STATE_WAIT =>
            reconos_sem_wait(o_osif, i_osif, C_SEM_START);
	    burst_counter := 0;
	    state <= STATE_READTIME_START;

	  -- get start time of burst transfer
	  when STATE_READTIME_START =>
              readtime_1 := i_timeBase;
--	    reconos_read(done, o_osif, i_osif, TIMER_ADDR, readtime_1);
--	    if done then
	            state <= STATE_READ;
--	    end if;

            -- read data from main memory into local burst RAM.
          when STATE_READ =>
            reconos_read_burst (done, o_osif, i_osif, std_logic_vector(TO_UNSIGNED(burst_counter*128, C_OSIF_DATA_WIDTH)), address+(burst_counter*128));
            if done then
              if burst_counter = 8192/128 - 1 then
		trans_counter := 0;
		RAMAddr <= (others => '0');
                state <= STATE_READTIME_STOP;
              else
                burst_counter := burst_counter + 1;
              end if;
            end if;

	  -- get stop time of burst transfer
	  when STATE_READTIME_STOP =>
              readtime_2 := i_timeBase;
--	    reconos_read(done, o_osif, i_osif, TIMER_ADDR, readtime_2);
--	    if done then
		puttime_1 := readtime_2;	-- nach der Messung ist vor der Messung :)
                state <= STATE_TRANSFER;
--	    end if;

            -- transfer data across mailbox
	    -- this state also hides the RAM access timing, since this is a multi-cycle
 	    -- command, and the "data" parameter is only transferred in the second cycle.
          when STATE_TRANSFER =>
		reconos_mbox_put(done, success, o_osif, i_osif, C_MB_TRANSFER, i_RAMData);
		if done and success then
			if trans_counter = 8192/4 - 1 then
				state <= STATE_PUTTIME_STOP;
			else
				RAMAddr <= RAMAddr + 1;
				trans_counter := trans_counter + 1;
			end if;
		end if;

	  -- get stop time of FIFO transfer
	  when STATE_PUTTIME_STOP =>
              puttime_2 := i_timeBase;
--	    reconos_read(done, o_osif, i_osif, TIMER_ADDR, puttime_2);
--	    if done then
                state <= STATE_POST_READTIME_1;
--	    end if;

            -- write read time to mailbox
          when STATE_POST_READTIME_1 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_READTIME, readtime_1);
            if done and success then
              state <= STATE_POST_READTIME_2;
            end if;

          when STATE_POST_READTIME_2 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_READTIME, readtime_2);
            if done and success then
              state <= STATE_POST_PUTTIME_1;
            end if;

            -- write transfer time to mailbox
          when STATE_POST_PUTTIME_1 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_PUTTIME, puttime_1);
            if done and success then
              state <= STATE_POST_PUTTIME_2;
            end if;

          when STATE_POST_PUTTIME_2 =>
            reconos_mbox_put(done, success, o_osif, i_osif, C_MB_PUTTIME, puttime_2);
            if done and success then
              state <= STATE_WAIT;
            end if;

          when others =>
            state <= STATE_INIT;
        end case;
      end if;
    end if;
  end process;
end Behavioral;


