--!
--! \file mem_plb46.vhd
--!
--! Memory bus interface for the 64-bit PLB v34.
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       08.12.2008
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of ReconOS (http://www.reconos.de).
-- Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
-- All rights reserved.
-- 
-- ReconOS is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
-- 
-- ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 08.12.2008   Enno Luebbers   File created.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

library xps_osif_v2_01_a;
use xps_osif_v2_01_a.all;



entity mem_plb46 is
    generic
        (
            -- Bus protocol parameters
            C_AWIDTH       : integer          := 32;
            C_DWIDTH       : integer          := 32;
            C_PLB_AWIDTH   : integer          := 32;
            C_PLB_DWIDTH   : integer          := 64;
            --C_NUM_CE         :    integer          := 2;
            C_BURST_AWIDTH : integer          := 13  -- 1024 x 64 Bit = 8192 Bytes = 2^13 Bytes
            );
    port
        (
            clk   : in std_logic;
            reset : in std_logic;

            -- data interface           ---------------------------

            -- burst mem interface
            o_burstAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
            o_burstData : out std_logic_vector(0 to C_PLB_DWIDTH-1);
            i_burstData : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
            o_burstWE   : out std_logic;
            o_burstBE   : out std_logic_vector(0 to C_PLB_DWIDTH/8-1);

            -- single word data input/output
            i_singleData : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
            -- osif2bus 
            o_singleData : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
            -- bus2osif

            -- control interface        ------------------------

            -- addresses for master transfers
            i_localAddr  : in std_logic_vector(0 to C_AWIDTH-1);
            i_targetAddr : in std_logic_vector(0 to C_AWIDTH-1);

            -- single word transfer requests
            i_singleRdReq : in std_logic;
            i_singleWrReq : in std_logic;

            -- burst transfer requests
            i_burstRdReq : in std_logic;
            i_burstWrReq : in std_logic;
            i_burstLen   : in std_logic_vector(0 to 11);  -- number of bytes to transfer (0..4096)

            -- status outputs
            o_busy   : out std_logic;
            o_rdDone : out std_logic;
            o_wrDone : out std_logic;


            -- PLBv34 bus interface     -----------------------------------------

            -- Bus protocol ports, do not add to or delete
            Bus2IP_Clk             : in  std_logic;
            Bus2IP_Reset           : in  std_logic;
            Bus2IP_MstError        : in  std_logic;
            Bus2IP_MstLastAck      : in  std_logic;
            Bus2IP_MstRdAck        : in  std_logic;
            Bus2IP_MstWrAck        : in  std_logic;
            Bus2IP_MstRetry        : in  std_logic;
            Bus2IP_MstTimeOut      : in  std_logic;
            Bus2IP_Mst_CmdAck      : in  std_logic;
            Bus2IP_Mst_Cmplt       : in  std_logic;
            Bus2IP_Mst_Error       : in  std_logic;
            Bus2IP_Mst_Cmd_Timeout : in  std_logic;
            IP2Bus_Addr            : out std_logic_vector(0 to C_AWIDTH-1);
            IP2Bus_MstBE           : out std_logic_vector(0 to C_PLB_DWIDTH/8-1);
            IP2Bus_MstBurst        : out std_logic;
            IP2Bus_MstBusReset     : out std_logic;
            IP2Bus_MstBusLock      : out std_logic;
            IP2Bus_MstNum          : out std_logic_vector(0 to 11);
            IP2Bus_MstRdReq        : out std_logic;
            IP2Bus_MstWrReq        : out std_logic;

            -- LocalLink Interface
            Bus2IP_MstRd_d         : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
            Bus2IP_MstRd_rem       : in  std_logic_vector(0 to C_PLB_DWIDTH/8-1);
            Bus2IP_MstRd_sof_n     : in  std_logic;
            Bus2IP_MstRd_eof_n     : in  std_logic;
            Bus2IP_MstRd_src_rdy_n : in  std_logic;
            Bus2IP_MstRd_src_dsc_n : in  std_logic;
            IP2Bus_MstRd_dst_rdy_n : out std_logic;
            IP2Bus_MstRd_dst_dsc_n : out std_logic;
            IP2Bus_MstWr_d         : out std_logic_vector(0 to C_PLB_DWIDTH-1);
            IP2Bus_MstWr_rem       : out std_logic_vector(0 to C_PLB_DWIDTH/8-1);
            IP2Bus_MstWr_sof_n     : out std_logic;
            IP2Bus_MstWr_eof_n     : out std_logic;
            IP2Bus_MstWr_src_rdy_n : out std_logic;
            IP2Bus_MstWr_src_dsc_n : out std_logic;
            Bus2IP_MstWr_dst_rdy_n : in  std_logic;
            Bus2IP_MstWr_dst_dsc_n : in  std_logic
            );
end entity mem_plb46;


architecture arch of mem_plb46 is

    constant BYTES_PER_BEAT : integer := C_PLB_DWIDTH/8;


-- signals for master model command interface state machine
    type   CMD_CNTL_SM_TYPE is (CMD_IDLE, CMD_RUN, CMD_WAIT_FOR_DATA, CMD_DONE);
    signal mst_cmd_sm_state          : CMD_CNTL_SM_TYPE;
    signal mst_cmd_sm_set_done       : std_logic;
    signal mst_cmd_sm_set_error      : std_logic;
    signal mst_cmd_sm_set_timeout    : std_logic;
    signal mst_cmd_sm_busy           : std_logic;
    signal mst_cmd_sm_clr_go         : std_logic;
    signal mst_cmd_sm_rd_req         : std_logic;
    signal mst_cmd_sm_wr_req         : std_logic;
    signal mst_cmd_sm_reset          : std_logic;
    signal mst_cmd_sm_bus_lock       : std_logic;
    signal mst_cmd_sm_ip2bus_addr    : std_logic_vector(0 to C_PLB_AWIDTH-1);
    signal mst_cmd_sm_ip2bus_be      : std_logic_vector(0 to C_PLB_DWIDTH/8-1);
    signal mst_cmd_sm_xfer_type      : std_logic;
    signal mst_cmd_sm_xfer_length    : std_logic_vector(0 to 11);
    signal mst_cmd_sm_start_rd_llink : std_logic;
    signal mst_cmd_sm_start_wr_llink : std_logic;
-- signals for master model read locallink interface state machine
    type   RD_LLINK_SM_TYPE is (LLRD_IDLE, LLRD_GO);
    signal mst_llrd_sm_state         : RD_LLINK_SM_TYPE;
    signal mst_llrd_sm_dst_rdy       : std_logic;
-- signals for master model write locallink interface state machine
    type   WR_LLINK_SM_TYPE is (LLWR_IDLE, LLWR_SNGL_INIT, LLWR_SNGL, LLWR_BRST_INIT, LLWR_BRST, LLWR_BRST_LAST_BEAT);
    signal mst_llwr_sm_state         : WR_LLINK_SM_TYPE;
    signal mst_llwr_sm_src_rdy       : std_logic;
    signal mst_llwr_sm_sof           : std_logic;
    signal mst_llwr_sm_eof           : std_logic;
    signal mst_llwr_byte_cnt         : integer;
    signal bram_offset               : integer;
    signal mst_fifo_valid_write_xfer : std_logic;
    signal mst_fifo_valid_read_xfer  : std_logic;
    signal mst_fifo_valid_read_xfer_d1  : std_logic;

    signal mst_xfer_length      : std_logic_vector(0 to 11);
    signal mst_cntl_rd_req      : std_logic;
    signal mst_cntl_wr_req      : std_logic;
    signal mst_cntl_bus_lock    : std_logic;
    signal mst_cntl_burst       : std_logic;
    signal mst_ip2bus_addr      : std_logic_vector(0 to C_PLB_AWIDTH-1);
    signal mst_ip2bus_be        : std_logic_vector(0 to 7);  -- FIXME: Hardcoded for 64 bit master
    signal mst_go               : std_logic;
    signal xfer_cross_wrd_bndry : std_logic;

    signal rolled_MstRd_d       : std_logic_vector(0 to C_PLB_DWIDTH-1);
    signal rolled_mst_ip2bus_be : std_logic_vector(0 to 7);

    signal be_offset : integer range 0 to 7;
    
    signal prefetch_data : std_logic_vector(0 to C_PLB_DWIDTH-1) ;
    signal burstData_current : std_logic_vector(0 to C_PLB_DWIDTH-1) ;
    signal prefetch_first : std_logic;
    signal save_first : std_logic;


begin

    -- get byte enable offset from target address
    be_offset <= TO_INTEGER(ieee.numeric_std.unsigned(i_targetAddr(C_AWIDTH-3 to C_AWIDTH-1)));

    mst_reg : process(Bus2IP_Clk, Bus2IP_Reset)
        constant BE_32 : std_logic_vector := X"F0";
    begin
        if Bus2IP_Reset = '1' then
            mst_xfer_length      <= (others => '0');
            mst_cntl_rd_req      <= '0';
            mst_cntl_wr_req      <= '0';
            mst_ip2bus_addr      <= (others => '0');
            mst_ip2bus_be        <= (others => '0');
            mst_cntl_burst       <= '0';
            xfer_cross_wrd_bndry <= '0';
            mst_go               <= '0';
        elsif rising_edge(Bus2IP_Clk) then

            if (i_burstRdReq = '1' or i_burstWrReq = '1') then  -- if incoming burst request
                mst_xfer_length      <= i_burstLen(3 to 11) & "000";    -- burst length in bytes
                mst_cntl_rd_req      <= i_burstRdReq;  -- read request
                mst_cntl_wr_req      <= i_burstWrReq;  -- write request
                mst_ip2bus_addr      <= i_targetAddr;  -- target address
                mst_cntl_burst       <= '1';  -- burst
                xfer_cross_wrd_bndry <= '0';  -- bursts can't cross word boundary
                mst_ip2bus_be        <= X"00";  -- bursts do not look at BE
                mst_go               <= '1';
            elsif (i_singleRdReq = '1' or i_singleWrReq = '1') then
                mst_cntl_rd_req <= i_singleRdReq;      -- read request
                mst_cntl_wr_req <= i_singleWrReq;      -- write request
                mst_ip2bus_addr <= i_targetAddr;       -- target address
                mst_cntl_burst  <= '0';       -- no burst
                mst_ip2bus_be   <= std_logic_vector(ieee.numeric_std.unsigned(BE_32) srl be_offset);  -- calc byte enables from address
                if be_offset > 4 then
                    -- 32 Bit transfer across 64 Bit boundary, we need to split this
                    xfer_cross_wrd_bndry <= '1';
                end if;
                mst_go <= '1';
            elsif mst_cmd_sm_set_done = '1' and xfer_cross_wrd_bndry = '1' then  -- if last transfer was a single word that crossed a 64bit boundary
                xfer_cross_wrd_bndry <= '0';  -- repeat transfer with remaining data
                mst_ip2bus_addr      <= i_targetAddr + 8-be_offset;  -- new target address
                mst_ip2bus_be        <= std_logic_vector(ieee.numeric_std.unsigned(BE_32) sll 8-be_offset);  -- remaining byte enables
                mst_go               <= '1';
            elsif mst_cmd_sm_clr_go = '1' then
                mst_go <= '0';
            end if;
        end if;
    end process;

-- command_decoder protocol to mst_* protocol conversion assignments
    mst_cntl_bus_lock <= '0';           -- never lock the bus

-- user logic master command interface assignments
    IP2Bus_MstRdReq    <= mst_cmd_sm_rd_req;
    IP2Bus_MstWrReq    <= mst_cmd_sm_wr_req;
    IP2Bus_Addr        <= mst_cmd_sm_ip2bus_addr;
    IP2Bus_MstBE       <= mst_cmd_sm_ip2bus_be;
    IP2Bus_MstBurst    <= mst_cmd_sm_xfer_type;
    IP2Bus_MstNum      <= mst_cmd_sm_xfer_length;
    IP2Bus_MstBusLock  <= mst_cmd_sm_bus_lock;
    IP2Bus_MstBusReset <= mst_cmd_sm_reset;

-- handshake output signals
    o_busy   <= mst_cmd_sm_busy or mst_go or i_singleRdReq or i_singleWrReq or i_burstRdReq or i_burstWrReq or mst_cmd_sm_set_done;
    o_rdDone <= mst_cmd_sm_set_done and mst_cntl_rd_req and not xfer_cross_wrd_bndry;
    o_wrDone <= mst_cmd_sm_set_done and mst_cntl_wr_req and not xfer_cross_wrd_bndry;

--implement master command interface state machine
    MASTER_CMD_SM_PROC : process(Bus2IP_Clk) is
    begin

        if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then

                -- reset condition
                mst_cmd_sm_state          <= CMD_IDLE;
                mst_cmd_sm_clr_go         <= '0';
                mst_cmd_sm_rd_req         <= '0';
                mst_cmd_sm_wr_req         <= '0';
                mst_cmd_sm_bus_lock       <= '0';
                mst_cmd_sm_reset          <= '0';
                mst_cmd_sm_ip2bus_addr    <= (others => '0');
                mst_cmd_sm_ip2bus_be      <= (others => '0');
                mst_cmd_sm_xfer_type      <= '0';
                mst_cmd_sm_xfer_length    <= (others => '0');
                mst_cmd_sm_set_done       <= '0';
                mst_cmd_sm_set_error      <= '0';
                mst_cmd_sm_set_timeout    <= '0';
                mst_cmd_sm_busy           <= '0';
                mst_cmd_sm_start_rd_llink <= '0';
                mst_cmd_sm_start_wr_llink <= '0';

            else

                -- default condition
                mst_cmd_sm_clr_go         <= '0';
                mst_cmd_sm_rd_req         <= '0';
                mst_cmd_sm_wr_req         <= '0';
                mst_cmd_sm_bus_lock       <= '0';
                mst_cmd_sm_reset          <= '0';
                mst_cmd_sm_ip2bus_addr    <= (others => '0');
                mst_cmd_sm_ip2bus_be      <= (others => '0');
                mst_cmd_sm_xfer_type      <= '0';
                mst_cmd_sm_xfer_length    <= (others => '0');
                mst_cmd_sm_set_done       <= '0';
                mst_cmd_sm_set_error      <= '0';
                mst_cmd_sm_set_timeout    <= '0';
                mst_cmd_sm_busy           <= '1';
                mst_cmd_sm_start_rd_llink <= '0';
                mst_cmd_sm_start_wr_llink <= '0';

                -- state transition
                case mst_cmd_sm_state is

                    -- waiting for transfer
                    when CMD_IDLE =>
                        if (mst_go = '1') then  -- new transfer initiated?
                            mst_cmd_sm_state  <= CMD_RUN;  -- go to RUN state
                            mst_cmd_sm_clr_go <= '1';  -- clear go register (REMOVEME)
                            if (mst_cntl_rd_req = '1') then  -- read request?
                                mst_cmd_sm_start_rd_llink <= '1';  -- start ll read
                            elsif (mst_cntl_wr_req = '1') then  -- write request?
                                mst_cmd_sm_start_wr_llink <= '1';  -- start ll write
                            end if;
                        else
                            mst_cmd_sm_state <= CMD_IDLE;  -- otherwise, stay here and do nothing
                            mst_cmd_sm_busy  <= '0';
                        end if;

                        -- transfer initiated
                    when CMD_RUN =>
                        if (Bus2IP_Mst_CmdAck = '1' and Bus2IP_Mst_Cmplt = '0') then  -- command acknowledged and not completed?
                            mst_cmd_sm_state <= CMD_WAIT_FOR_DATA;  -- go to WAIT_FOR_DATA state
                        elsif (Bus2IP_Mst_Cmplt = '1') then  -- command completed?
                            mst_cmd_sm_state <= CMD_DONE;  -- go to DONE state
                            if (Bus2IP_Mst_Cmd_Timeout = '1') then  -- was it a timeout?
                                -- PLB address phase timeout
                                mst_cmd_sm_set_error   <= '1';  -- set error and timeout flags
                                mst_cmd_sm_set_timeout <= '1';
                            elsif (Bus2IP_Mst_Error = '1') then  -- was it an error
                                -- PLB data transfer error
                                mst_cmd_sm_set_error <= '1';  -- set only the error flag
                            end if;
                        else
                            mst_cmd_sm_state       <= CMD_RUN;  -- if it wasn't acknowledged or completed yet (i.e. new request)
                            mst_cmd_sm_rd_req      <= mst_cntl_rd_req;  -- set read and write request flags
                            mst_cmd_sm_wr_req      <= mst_cntl_wr_req;
                            mst_cmd_sm_ip2bus_addr <= mst_ip2bus_addr;  -- set target address
                            mst_cmd_sm_ip2bus_be   <= mst_ip2bus_be;  -- set byte enables
                            mst_cmd_sm_xfer_type   <= mst_cntl_burst;  -- set transfer type
                            mst_cmd_sm_xfer_length <= mst_xfer_length;  -- set transfer length (in bytes?)
                            mst_cmd_sm_bus_lock    <= mst_cntl_bus_lock;  -- set bus lock (always 0?)
                        end if;  -- and stay in RUN state (i.e. wait for acceptance/abort)

                        -- transfer request accepted, transfer in progress
                    when CMD_WAIT_FOR_DATA =>
                        if (Bus2IP_Mst_Cmplt = '1') then  -- transfer completed?
                            mst_cmd_sm_state <= CMD_DONE;  -- go to DONE state
                        else            -- otherwise
                            mst_cmd_sm_state <= CMD_WAIT_FOR_DATA;  -- stay here
                        end if;

                        -- transfer completed or aborted
                    when CMD_DONE =>
                        mst_cmd_sm_state    <= CMD_IDLE;  -- go to IDLE state
                        mst_cmd_sm_set_done <= '1';  -- signal that we're done
                        mst_cmd_sm_busy     <= '0';  -- and not busy

                        -- default catchall
                    when others =>
                        mst_cmd_sm_state <= CMD_IDLE;
                        mst_cmd_sm_busy  <= '0';

                end case;

            end if;
        end if;

    end process MASTER_CMD_SM_PROC;


----------------------------------------------------
-- LOCAL LINK INTERFACE
----------------------------------------------------

-- user logic master read locallink interface assignments
    IP2Bus_MstRd_dst_rdy_n <= not(mst_llrd_sm_dst_rdy);
    IP2Bus_MstRd_dst_dsc_n <= '1';      -- do not throttle data

-- implement a simple state machine to enable the
-- read locallink interface to transfer data
    LLINK_RD_SM_PROCESS : process(Bus2IP_Clk) is
    begin

        if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then

                -- reset condition
                mst_llrd_sm_state   <= LLRD_IDLE;
                mst_llrd_sm_dst_rdy <= '0';  -- not ready to read data

            else

                -- default condition
                mst_llrd_sm_state   <= LLRD_IDLE;
                mst_llrd_sm_dst_rdy <= '0';  -- not ready to read data

                -- state transition
                case mst_llrd_sm_state is

                    when LLRD_IDLE =>
                        if (mst_cmd_sm_start_rd_llink = '1') then  -- if we got start signal from master FSM
                            mst_llrd_sm_state <= LLRD_GO;    -- go to GO state
                        else
                            mst_llrd_sm_state <= LLRD_IDLE;  -- otherwise stay here and keep waiting
                        end if;

                    when LLRD_GO =>
                        -- done, end of packet
                        if (mst_llrd_sm_dst_rdy = '1' and  -- if we are ready to receive
                             Bus2IP_MstRd_src_rdy_n = '0' and  -- the sender is ready to send
                             Bus2IP_MstRd_eof_n = '0') then  -- and the sender is done sending
                            mst_llrd_sm_state <= LLRD_IDLE;  -- we're done
                            -- not done yet, continue receiving data
                        else            -- otherwise
                            mst_llrd_sm_state   <= LLRD_GO;  -- stay in this state
                            mst_llrd_sm_dst_rdy <= '1';  -- and be ready to receive
                        end if;

                        -- default catchall
                    when others =>
                        mst_llrd_sm_state <= LLRD_IDLE;

                end case;

            end if;
        else
            null;
        end if;

    end process LLINK_RD_SM_PROCESS;


-- user logic master write locallink interface assignments
    IP2Bus_MstWr_src_rdy_n <= not(mst_llwr_sm_src_rdy);
    IP2Bus_MstWr_src_dsc_n <= '1';              -- do not throttle data
    IP2Bus_MstWr_rem       <= (others => '0');  -- no remainder mask
    IP2Bus_MstWr_sof_n     <= not(mst_llwr_sm_sof);
    IP2Bus_MstWr_eof_n     <= not(mst_llwr_sm_eof);

-- implement a simple state machine to enable the
-- write locallink interface to transfer data
    LLINK_WR_SM_PROC : process(Bus2IP_Clk) is
    begin

        if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Bus2IP_Reset = '1') then

                -- reset condition
                mst_llwr_sm_state   <= LLWR_IDLE;
                mst_llwr_sm_src_rdy <= '0';
                mst_llwr_sm_sof     <= '0';
                mst_llwr_sm_eof     <= '0';
                mst_llwr_byte_cnt   <= 0;

            else

                -- default condition
                mst_llwr_sm_state   <= LLWR_IDLE;
                mst_llwr_sm_src_rdy <= '0';
                mst_llwr_sm_sof     <= '0';
                mst_llwr_sm_eof     <= '0';
                mst_llwr_byte_cnt   <= 0;

                -- state transition
                case mst_llwr_sm_state is

                    -- wait for start of transfer
                    when LLWR_IDLE =>
                        if (mst_cmd_sm_start_wr_llink = '1' and mst_cntl_burst = '0') then  -- single write request?
                            mst_llwr_sm_state <= LLWR_SNGL_INIT;
                        elsif (mst_cmd_sm_start_wr_llink = '1' and mst_cntl_burst = '1') then  -- burst write request?
                            mst_llwr_sm_state <= LLWR_BRST_INIT;
                        else
                            mst_llwr_sm_state <= LLWR_IDLE;
                        end if;

                        -- init single transfer
                    when LLWR_SNGL_INIT =>
                        mst_llwr_sm_state   <= LLWR_SNGL;
                        mst_llwr_sm_src_rdy <= '1';  -- ready to send
                        mst_llwr_sm_sof     <= '1';  -- signal single transfer by asserting both SOF and EOF
                        mst_llwr_sm_eof     <= '1';

                        -- do single transfer
                    when LLWR_SNGL =>
                        -- destination discontinue write
                        if (Bus2IP_MstWr_dst_dsc_n = '0' and Bus2IP_MstWr_dst_rdy_n = '0') then  -- if discontinue from target
                            mst_llwr_sm_state   <= LLWR_IDLE;  -- reset back to IDLE state
                            mst_llwr_sm_src_rdy <= '0';
                            mst_llwr_sm_eof     <= '0';
                            -- single data beat transfer complete
                        elsif (mst_fifo_valid_read_xfer = '1') then  -- if local memory read has been completed
                            mst_llwr_sm_state   <= LLWR_IDLE;  -- go back to IDLE state
                            mst_llwr_sm_src_rdy <= '0';
                            mst_llwr_sm_sof     <= '0';
                            mst_llwr_sm_eof     <= '0';
                            -- wait on destination
                        else
                            mst_llwr_sm_state   <= LLWR_SNGL;  -- otherwise keep trying to transfer single word
                            mst_llwr_sm_src_rdy <= '1';
                            mst_llwr_sm_sof     <= '1';
                            mst_llwr_sm_eof     <= '1';
                        end if;

                        -- init burst transfer
                    when LLWR_BRST_INIT =>
                        mst_llwr_sm_state   <= LLWR_BRST;
                        mst_llwr_sm_src_rdy <= '1';
                        mst_llwr_sm_sof     <= '1';
                        mst_llwr_byte_cnt   <= CONV_INTEGER(mst_xfer_length);

                        -- do burst transfer
                    when LLWR_BRST =>
                        if (mst_fifo_valid_read_xfer = '1') then  -- if a word has been transferred (i.e. we are actively writing)
                            mst_llwr_sm_sof <= '0';      -- deassert SOF signal
                        else
                            mst_llwr_sm_sof <= mst_llwr_sm_sof;
                        end if;
                        -- destination discontinue write
                        if (Bus2IP_MstWr_dst_dsc_n = '0' and  -- if discontinue from target
                             Bus2IP_MstWr_dst_rdy_n = '0') then
                            mst_llwr_sm_state   <= LLWR_IDLE;  -- reset to IDLE state
                            mst_llwr_sm_src_rdy <= '1';  -- and properly terminate transfer
                            mst_llwr_sm_eof     <= '1';
                            -- last data beat write
                        elsif (mst_fifo_valid_read_xfer = '1' and  -- if this was the second to last beat to transfer
                                (mst_llwr_byte_cnt-BYTES_PER_BEAT) <= BYTES_PER_BEAT) then
                            mst_llwr_sm_state   <= LLWR_BRST_LAST_BEAT;  -- go to LAST_BEAT state
                            mst_llwr_sm_src_rdy <= '1';  -- and signal termination of transfer
                            mst_llwr_sm_eof     <= '1';
                            -- wait on destination
                        else
                            mst_llwr_sm_state   <= LLWR_BRST;  -- otherwise keep writing data
                            mst_llwr_sm_src_rdy <= '1';
                            -- decrement write transfer counter if it's a valid write
                            if (mst_fifo_valid_read_xfer = '1') then
                                mst_llwr_byte_cnt <= mst_llwr_byte_cnt - BYTES_PER_BEAT;
                            else
                                mst_llwr_byte_cnt <= mst_llwr_byte_cnt;
                            end if;
                        end if;

                        -- do last beat of write burst
                    when LLWR_BRST_LAST_BEAT =>
                        -- destination discontinue write
                        if (Bus2IP_MstWr_dst_dsc_n = '0' and  -- if discontinue from target
                             Bus2IP_MstWr_dst_rdy_n = '0') then
                            mst_llwr_sm_state   <= LLWR_IDLE;  -- reset to IDLE state
                            mst_llwr_sm_src_rdy <= '0';  -- and mark ourselves as not ready (?)
                            -- last data beat done
                        elsif (mst_fifo_valid_read_xfer = '1') then  -- if this transfer was successful
                            mst_llwr_sm_state   <= LLWR_IDLE;  -- reset to IDLE state
                            mst_llwr_sm_src_rdy <= '0';
                            -- wait on destination
                        else
                            mst_llwr_sm_state   <= LLWR_BRST_LAST_BEAT;  -- otherwise keep trying to send
                            mst_llwr_sm_src_rdy <= '1';
                            mst_llwr_sm_eof     <= '1';
                        end if;

                        -- default catchall
                    when others =>
                        mst_llwr_sm_state <= LLWR_IDLE;

                end case;

            end if;
        else
            null;
        end if;

    end process LLINK_WR_SM_PROC;

-- determine whether a data beat was successfully written
    mst_fifo_valid_write_xfer <= not(Bus2IP_MstRd_src_rdy_n) and mst_llrd_sm_dst_rdy;
    mst_fifo_valid_read_xfer  <= not(Bus2IP_MstWr_dst_rdy_n) and mst_llwr_sm_src_rdy;

-- connect burst ram
    o_burstAddr <= i_localAddr(C_AWIDTH-C_BURST_AWIDTH to C_AWIDTH-1) + bram_offset;
    o_burstData <= Bus2IP_MstRd_d;
    o_burstWE   <= mst_cntl_rd_req and mst_cntl_burst and mst_fifo_valid_write_xfer;
    o_burstBE   <= (others => '1');

    -- delay read enable for edge detection and prefetch
    mst_fifo_valid_read_xfer_d1 <= mst_fifo_valid_read_xfer when rising_edge(clk) else mst_fifo_valid_read_xfer_d1;

    -- prefetch data from burst ram for contiguous writes
    prefetch : process(clk, reset)
    begin
        if reset = '1' then
            prefetch_data <= (others => '0');
        elsif rising_edge(clk) then
            if mst_fifo_valid_read_xfer_d1 = '1' or save_first = '1' then
                prefetch_data <= i_burstData;
            end if;
        end if;
    end process;

    -- on the first beat of a back-to-back transfer, use the prefetched data, otherwise use the RAM output
    burstData_current <= prefetch_data when mst_fifo_valid_read_xfer_d1 = '0' and mst_fifo_valid_read_xfer = '1' else i_burstData;

    -- generate address signals for burst ram
        burst_addr : process(clk, reset)
        begin
            if reset = '1' then
                bram_offset <= 0;
                save_first <= '0';
                prefetch_first <= '0';
            elsif rising_edge(clk) then
                save_first <= '0';
                if i_burstRdReq = '1' then        -- new burst request
                    bram_offset <= 0;
                elsif i_burstWrReq = '1' then        -- new burst request
                    bram_offset <= 0;
                    prefetch_first <= '1';
                elsif prefetch_first = '1' then
                    bram_offset <= bram_offset + BYTES_PER_BEAT;
                    prefetch_first <= '0';
                    save_first <= '1';
                elsif mst_fifo_valid_write_xfer = '1' or mst_fifo_valid_read_xfer = '1' then
                    bram_offset <= bram_offset + BYTES_PER_BEAT;
                end if;
            end if;
        end process;

-- multiplex burst ram and single data register to bus (possibly shifted)
    IP2Bus_MstWr_d <= burstData_current when mst_cntl_burst = '1' else
                      std_logic_vector(ieee.numeric_std.unsigned(i_singleData & X"00000000") ror be_offset*8);


-- implement single data register
    rolled_MstRd_d       <= std_logic_vector(ieee.numeric_std.unsigned(Bus2IP_MstRd_d) rol be_offset*8);
    rolled_mst_ip2bus_be <= std_logic_vector(ieee.numeric_std.unsigned(mst_ip2bus_be) rol be_offset);
    single_reg : process(Bus2IP_Clk, Bus2IP_Reset, mst_ip2bus_be)
        variable bit_enable     : std_logic_vector(0 to C_DWIDTH-1);
        variable assembled_data : std_logic_vector(0 to C_DWIDTH-1);
    begin
        for i in 0 to 3 loop
            bit_enable(i*8 to i*8+7) := (others => rolled_mst_ip2bus_be(i));
        end loop;
        if Bus2IP_Reset = '1' then
            assembled_data := (others => '0');
        elsif rising_edge(Bus2IP_Clk) then
            if (mst_cntl_rd_req = '1' and mst_cntl_burst = '0' and mst_fifo_valid_write_xfer = '1') then
                assembled_data := (assembled_data and (not bit_enable)) or (rolled_MstRd_d(0 to C_DWIDTH-1) and bit_enable);
            end if;
        end if;
        o_singleData <= assembled_data;
    end process;
    

end arch;
