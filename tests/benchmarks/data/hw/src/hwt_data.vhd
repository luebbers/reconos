--
-- threadA.vhd
-- measurement thread
--
-- Author:     Enno Luebbers   <luebbers@reconos.de>
-- Date:       18.02.2008
--
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- University of Paderborn, Computer Engineering Group.
--
-- (C) Copyright University of Paderborn 2008.
--
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library reconos_v2_00_a;
use reconos_v2_00_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hwt_data is

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
             o_RAMClk  : out std_logic;

             -- external timebase
             i_timeBase : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)
         );
end hwt_data;

architecture Behavioral of hwt_data is

    -- timer address (FIXME: hardcoded!)
    constant TIMER_ADDR : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"50004000";

    -- ReconOS resources used by this thread
    constant C_MB_TRANSFER  : std_logic_vector(0 to 31) := X"00000000";
    constant C_MB_RESULT    : std_logic_vector(0 to 31) := X"00000001";

    -- OS synchronization state machine states
    type t_state is (
    STATE_INIT,     -- load configuration address
    STATE_READ_SRC,     -- load source address
    STATE_READ_DST,    -- load destination address
    STATE_READ_BLKSIZE,    -- load transfer size
    STATE_WAIT,     -- wait (not used)
    STATE_READTIME_START, -- measure start time
    STATE_READ_MBOX,        -- read data from mbox
    STATE_INC_ADDR,
    STATE_READ_MEM_SINGLE,  -- read data from memory (single word)
    STATE_READ_MEM_BURST,   -- read data from memory (burst)
    STATE_READTIME_STOP, 
    STATE_WRITE_MBOX,       -- write data to mbox
    STATE_WRITE_MEM_SINGLE, -- write data to memory (single word)
    STATE_WRITE_MEM_BURST,  -- write data to memory (burst)
    STATE_WRITETIME_STOP,   -- measure stop time
    STATE_POST_READTIME_1, -- post times
    STATE_POST_READTIME_2, 
    STATE_POST_WRITETIME_1,
    STATE_POST_WRITETIME_2,
    STATE_EXIT
);
signal state : t_state := STATE_INIT;

-- address of data in main memory

-- RAM address
signal RAMAddr : std_logic_vector(0 to C_BURST_AWIDTH-1);


begin

    -- hook up RAM signals
    o_RAMClk  <= clk;
    o_RAMAddr <= RAMAddr(0 to C_BURST_AWIDTH-2) & not RAMAddr(C_BURST_AWIDTH-1);  -- invert LSB of address to get the word ordering right
                                                                                  --    o_RAMWE <= '0';
                                                                                  --    o_RAMData <= (others => '0');



    -- OS synchronization state machine
    state_proc               : process(clk, reset)
        variable done          : boolean;
        variable success       : boolean;
        variable burst_counter : natural range 0 to 8192/128 - 1;		-- transfer 128 bytes at once
        variable trans_counter : natural range 0 to 8192/4 - 1;		-- transfer 4 bytes at once
                                                                 -- addresses
        variable conf_address  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
        variable src_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
        variable dst_address : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
        variable block_size  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
        -- timing values
        variable readtime_1  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0001";
        variable readtime_2  : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0001";
        variable writetime_1 : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0002";
        variable writetime_2 : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := X"AFFE0002";
        variable burstlen_bytes  : natural range 1 to 128;
        variable burstlen_cycles : natural range 1 to 16;
        variable bursts : natural range 0 to 8192/128 - 1;
    begin
        if reset = '1' then
            reconos_reset(o_osif, i_osif);
            src_address := (others => '0');
            dst_address := (others => '0');
            state      <= STATE_INIT;
            o_RAMWE <= '0';
            o_RAMData <= (others => '0');
            burst_counter := 0;
            trans_counter := 0;
        elsif rising_edge(clk) then
            reconos_begin(o_osif, i_osif);
            if reconos_ready(i_osif) then
                case state is
                    -- read init data (address of configuration struct)
                    when STATE_INIT =>
                        reconos_get_init_data(done, o_osif, i_osif, conf_address);
                        if done then
                            state <= STATE_READ_SRC;
                        end if;

                    -- read source address (0 means mbox)
                    when STATE_READ_SRC =>
                        reconos_read(done, o_osif, i_osif, conf_address, src_address);
                        if done then
                            state <= STATE_READ_DST;
                        end if;

                    -- read destination address (0 means mbox)
                    when STATE_READ_DST =>
                        reconos_read(done, o_osif, i_osif, conf_address, dst_address);
                        if done then
                            state <= STATE_READ_BLKSIZE;
                        end if;

                    -- read block size (in bytes)
                    when STATE_READ_BLKSIZE =>
                        reconos_read(done, o_osif, i_osif, conf_address, block_size);
                        if done then
                            state <= STATE_WAIT;
                        end if;

                    -- wait 
                    when STATE_WAIT =>
                        burst_counter := 0;
                        state <= STATE_READTIME_START;

                    -- get start time of burst transfer, decide on mechanism (single, mbox, burst)
                    when STATE_READTIME_START =>
                        readtime_1 := i_timeBase;
                        if src_address = X"0000_0000" then
                            -- read from mailbox
                            state <= STATE_READ_MBOX;
                        else
                            if block_size = 4 then
                                RAMAddr <= (others => '0');
                                state <= STATE_READ_MEM_SINGLE;
                            else
                                if block_size < 128 then
                                    burstlen_bytes := conv_integer(block_size);
                                    bursts <= 1;
                                else
                                    burstlen_bytes := 128;
                                    bursts := conv_integer(block_size)/8;
                                end if;
                                burstlen_cycles := burstlen_bytes/8;
                                state <= STATE_READ_MEM_BURST;
                            end if;
                        end if;

                    -- read single word into burst ram
                    when STATE_READ_MEM_SINGLE =>
                        reconos_thread_exit(o_osif, i_osif, X"0000_0001");
--                        reconos_read_s(done, o_osif, i_osif, src_address, o_RAMData);
--                        if done then
--                            o_RAMWE <= '1';
--                            state <= STATE_READTIME_STOP;
--                        end if;

                    -- read data from main memory into local burst RAM.
                    when STATE_READ_MEM_BURST =>
                        reconos_thread_exit(o_osif, i_osif, X"0000_0002");
--                        reconos_read_burst_l (done, 
--                        o_osif, 
--                        i_osif, 
--                        std_logic_vector(TO_UNSIGNED(burst_counter*burstlen_bytes, C_OSIF_DATA_WIDTH)), 
--                        src_address+(burst_counter*burstlen_bytes),
--                        burstlen_cycles
--                    );
--                    if done then
--                        if burst_counter = bursts - 1 then
--                            trans_counter := 0;
--                            RAMAddr <= (others => '0');
--                            state <= STATE_READTIME_STOP;
--                        else
--                            burst_counter := burst_counter + 1;
--                        end if;
--                    end if;

          -- read data from mbox into local burst RAM
                when STATE_READ_MBOX =>
                        reconos_thread_exit(o_osif, i_osif, X"0000_0003");
--                    o_RAMWE <= '0';
--                    reconos_mbox_get_s(done, success, o_osif, i_osif, C_MB_TRANSFER, o_RAMData);
--                    if done and success then
--                        o_RAMWE <= '1';
--                        if trans_counter = conv_integer(block_size)/4 - 1 then
--                            burst_counter := 0;
--                            state <= STATE_READTIME_STOP;
--                        else
--                            state <= STATE_INC_ADDR;
--                            trans_counter := trans_counter + 1;
--                        end if;
--                    end if;

                -- increment RAM address for writing to BRAM
                when STATE_INC_ADDR =>
                    o_RAMWE <= '0';
                    RAMAddr <= RAMAddr + 1;	-- note that this is delayed by one clock cycle
                    state <= STATE_READ_MBOX;

                    -- get stop time of burst transfer
                when STATE_READTIME_STOP =>
                    o_RAMWE <= '0';
                    RAMAddr <= (others => '0');
                    readtime_2 := i_timeBase;
                    writetime_1 := readtime_2;	-- nach der Messung ist vor der Messung :)
                    if dst_address = X"0000_0000" then
                            -- write from mailbox
                        state <= STATE_WRITE_MBOX;
                    else
                        if block_size = 4 then
                            RAMAddr <= (others => '0');
                            state <= STATE_WRITE_MEM_SINGLE;
                        else
                            if block_size < 128 then
                                burstlen_bytes := conv_integer(block_size);
                                bursts := 1;
                            else
                                burstlen_bytes := 128;
                                bursts := conv_integer(block_size)/8;
                            end if;
                            burstlen_cycles := burstlen_bytes/8;
                            state <= STATE_WRITE_MEM_BURST;
                        end if;
                    end if;

            -- transfer data across mailbox
            -- this state also hides the RAM access timing, since this is a multi-cycle
            -- command, and the "data" parameter is only transferred in the second cycle.
                when STATE_WRITE_MBOX =>
                    reconos_mbox_put(done, success, o_osif, i_osif, C_MB_TRANSFER, i_RAMData);
                    if done and success then
                        if trans_counter = conv_integer(block_size)/4 - 1 then
                            state <= STATE_WRITETIME_STOP;
                        else
                            RAMAddr <= RAMAddr + 1;
                            trans_counter := trans_counter + 1;
                        end if;
                    end if;

                    -- write single word from burst ram to memory
                when STATE_WRITE_MEM_SINGLE =>
                    reconos_write(done, o_osif, i_osif, dst_address, i_RAMData);
                    if done then
                        o_RAMWE <= '1';
                        state <= STATE_WRITETIME_STOP;
                    end if;

                    -- write data from burst RAM into main memory 
                when STATE_WRITE_MEM_BURST =>
                    reconos_write_burst_l (done, 
                    o_osif, 
                    i_osif, 
                    std_logic_vector(TO_UNSIGNED(burst_counter*burstlen_bytes, C_OSIF_DATA_WIDTH)), 
                    dst_address+(burst_counter*burstlen_bytes),
                    burstlen_cycles
                );
                if done then
                    if burst_counter = bursts - 1 then
                        trans_counter := 0;
                        RAMAddr <= (others => '0');
                        state <= STATE_READTIME_STOP;
                    else
                        burst_counter := burst_counter + 1;
                    end if;
                end if;

            -- get stop time of FIFO transfer
                when STATE_WRITETIME_STOP =>
                    writetime_2 := i_timeBase;
                    state <= STATE_POST_READTIME_1;

            -- write read time to mailbox
                when STATE_POST_READTIME_1 =>
                    reconos_mbox_put(done, success, o_osif, i_osif, C_MB_RESULT, readtime_1);
                    if done and success then
                        state <= STATE_POST_READTIME_2;
                    end if;

                when STATE_POST_READTIME_2 =>
                    reconos_mbox_put(done, success, o_osif, i_osif, C_MB_RESULT, readtime_2);
                    if done and success then
                        state <= STATE_POST_WRITETIME_1;
                    end if;

            -- write transfer time to mailbox
                when STATE_POST_WRITETIME_1 =>
                    reconos_mbox_put(done, success, o_osif, i_osif, C_MB_RESULT, writetime_1);
                    if done and success then
                        state <= STATE_POST_WRITETIME_2;
                    end if;

                when STATE_POST_WRITETIME_2 =>
                    reconos_mbox_put(done, success, o_osif, i_osif, C_MB_RESULT, writetime_2);
                    if done and success then
                        state <= STATE_EXIT;
                    end if;

                when STATE_EXIT =>
                    reconos_thread_exit( o_osif, i_osif, X"0000_1111" );

                when others =>
                    state <= STATE_INIT;
            end case;
        end if;
    end if;
end process;
end Behavioral;


