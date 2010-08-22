--!
--! \file bus_master.vhd
--! 
--! PLB bus master logic for ReconOS OSIF (user_logic)
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       07.08.2006
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- Copyright (c) 2008, Computer Engineering Group, University of
-- Paderborn. 
-- 
-- For details regarding licensing and redistribution, see COPYING.  If
-- you did not receive a COPYING file as part of the distribution package
-- containing this file, you can get it at http://www.reconos.de/COPYING.
-- 
-- This software is provided "as is" without express or implied warranty,
-- and with no claim as to its suitability for any particular purpose.
-- The copyright owner or the contributors shall not be liable for any
-- damages arising out of the use of this software.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major changes
-- 07.08.2006  Enno Luebbers     File created

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity bus_master is
    generic (
-- C_BASEADDR : std_logic_vector := X"FFFFFFFF";
-- C_OFFSET : std_logic_vector := X"0000000C";
-- C_BURST_OFFSET : std_logic_vector := X"00001000";
        C_AWIDTH          :     integer := 32;
        C_DWIDTH          :     integer := 32;
        C_PLB_DWIDTH      :     integer := 64
        );
    port (
        clk               : in  std_logic;
        reset             : in  std_logic;  -- high active synchronous
        -- PLB bus master signals
        Bus2IP_MstError   : in  std_logic;
        Bus2IP_MstLastAck : in  std_logic;
        Bus2IP_MstRdAck   : in  std_logic;
        Bus2IP_MstWrAck   : in  std_logic;
        Bus2IP_MstRetry   : in  std_logic;
        Bus2IP_MstTimeOut : in  std_logic;
        IP2Bus_Addr       : out std_logic_vector(0 to C_AWIDTH-1);
        IP2Bus_MstBE      : out std_logic_vector(0 to C_PLB_DWIDTH/8-1);
        IP2Bus_MstBurst   : out std_logic;
        IP2Bus_MstBusLock : out std_logic;
        IP2Bus_MstNum     : out std_logic_vector(0 to 4);
        IP2Bus_MstRdReq   : out std_logic;
        IP2Bus_MstWrReq   : out std_logic;
        IP2IP_Addr        : out std_logic_vector(0 to C_AWIDTH-1);
        -- user interface
        i_my_addr         : in  std_logic_vector(0 to C_AWIDTH-1);
        i_target_addr     : in  std_logic_vector(0 to C_AWIDTH-1);
        i_read_req        : in  std_logic;  -- single word
        i_write_req       : in  std_logic;  -- single word
        i_burst_read_req  : in  std_logic;  -- 128x64Bit burst
        i_burst_write_req : in  std_logic;  -- 128x64Bit burst
        i_burst_length    : in  std_logic_vector(0 to 4);  -- number of burst beats (n x 64 bits)
        o_busy            : out std_logic;
        o_read_done       : out std_logic;
        o_write_done      : out std_logic
        );
end bus_master;

architecture behavioral of bus_master is

    -- signals for master control state machine
    type plb_master_state_t is (IDLE, READ, WRITE);
    signal plb_master_state : plb_master_state_t := IDLE;
    signal mst_sm_rd_req    : std_logic;
    signal mst_sm_wr_req    : std_logic;


begin

    -- connect common bus signalling
    IP2Bus_Addr       <= i_target_addr;
    IP2IP_Addr        <= i_my_addr;
    IP2Bus_MstBusLock <= '0';           -- FIXME: no atomic (locked) transactions
    IP2Bus_MstRdReq   <= mst_sm_rd_req;
    IP2Bus_MstWrReq   <= mst_sm_wr_req;


    -- we are busy, when there are no pending and no running requests.
    -- NOTE: incoming requests while non-idle are ignored.
    o_busy <= '0' when (
        (plb_master_state = IDLE) and
        ((i_read_req or i_write_req or i_burst_read_req or i_burst_write_req) = '0')
        )
              else '1';


-------------------------------------------------------------------
-- PLB master state machine
--
-- FIXME: are the mst_sm_*_req signals set right, or does this
-- cause too complicated logic?
-------------------------------------------------------------------
    plb_master : process(clk, reset)

    begin
        if reset = '1' then
            plb_master_state <= IDLE;
            mst_sm_rd_req    <= '0';
            mst_sm_wr_req    <= '0';
            o_read_done      <= '0';
            o_write_done     <= '0';
            IP2Bus_MstBE     <= "00000000";  -- 0 Bit
            IP2Bus_MstBurst  <= '0';         -- no burst
            IP2Bus_MstNum    <= "00001";     -- single beat transaction

        elsif rising_edge(clk) then

            o_read_done  <= '0';
            o_write_done <= '0';

            case plb_master_state is
                when IDLE =>
                    if i_read_req = '1' then
                        plb_master_state <= READ;
                        mst_sm_rd_req    <= '1';
                        -- single
                        if i_target_addr(29) = '0' then  -- align word access
                            IP2Bus_MstBE <= "11110000";  -- 32 Bit
                        else
                            IP2Bus_MstBE <= "00001111";  -- 32 Bit
                        end if;
                        IP2Bus_MstBurst  <= '0';  -- no burst
                        IP2Bus_MstNum    <= "00001";  -- single beat transaction
                    elsif i_write_req = '1' then
                        plb_master_state <= WRITE;
                        mst_sm_wr_req    <= '1';
                        -- single
                        if i_target_addr(29) = '0' then  -- align word access
                            IP2Bus_MstBE <= "11110000";  -- 32 Bit
                        else
                            IP2Bus_MstBE <= "00001111";  -- 32 Bit
                        end if;
                        IP2Bus_MstBurst  <= '0';  -- no burst
                        IP2Bus_MstNum    <= "00001";  -- single beat transaction
                    elsif i_burst_read_req = '1' then
                        plb_master_state <= READ;
                        mst_sm_rd_req    <= '1';
                        -- burst
                        IP2Bus_MstBE     <= "11111111";  -- 64 Bit
                        IP2Bus_MstBurst  <= '1';  -- burst
--            IP2Bus_MstNum    <= "11111";  -- 16x64 Bit burst
                        IP2Bus_MstNum    <= i_burst_length;  -- n x 64 Bit burst, max 16
                    elsif i_burst_write_req = '1' then
                        plb_master_state <= WRITE;
                        mst_sm_wr_req    <= '1';
                        -- burst
                        IP2Bus_MstBE     <= "11111111";  -- 64 Bit
                        IP2Bus_MstBurst  <= '1';  -- burst
--            IP2Bus_MstNum    <= "11111";  -- 16x64 Bit burst
                        IP2Bus_MstNum    <= i_burst_length;  -- n x 64 Bit burst, max 16
                    end if;

                when READ =>
                    if Bus2IP_MstLastAck = '1' or           -- on completion or
                                Bus2IP_MstTimeout = '1' or  -- on timeout or
                                Bus2IP_MstError = '1' then  -- on error
                        o_read_done      <= '1';                      -- finish transaction
                        mst_sm_rd_req    <= '0';
                        plb_master_state <= IDLE;
                    end if;

                when WRITE =>
                    if Bus2IP_MstLastAck = '1' or                     -- on completion or
                                Bus2IP_MstTimeout = '1' or  -- on timeout or
                                Bus2IP_MstError = '1' then		-- on error
                        o_write_done     <= '1';
                        mst_sm_wr_req    <= '0';			-- finish transaction
                        plb_master_state <= IDLE;
                    end if;
                    
                when others =>
                    plb_master_state <= IDLE;
                    
            end case;
        end if;
    end process;




end behavioral;

