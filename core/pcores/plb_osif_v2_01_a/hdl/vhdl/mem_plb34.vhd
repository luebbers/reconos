--!
--! \file mem_plb34.vhd
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

library plb_osif_v2_01_a;
use plb_osif_v2_01_a.all;



entity mem_plb34 is
    generic
        (
            C_SLAVE_BASEADDR :    std_logic_vector := X"FFFFFFFF";
            -- Bus protocol parameters
            C_AWIDTH         :    integer          := 32;
            C_DWIDTH         :    integer          := 32;
            C_PLB_AWIDTH     :    integer          := 32;
            C_PLB_DWIDTH     :    integer          := 64;
            C_NUM_CE         :    integer          := 2;
            C_BURST_AWIDTH   :    integer          := 13;  -- 1024 x 64 Bit = 8192 Bytes = 2^13 Bytes
            C_BURST_BASEADDR :    std_logic_vector := X"00004000";  -- system memory base address for burst ram access
            C_BURSTLEN_WIDTH :    integer          := 5
            );
    port
        (
            clk              : in std_logic;
            reset            : in std_logic;

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
            i_burstLen   : in std_logic_vector(0 to C_BURSTLEN_WIDTH-1);  -- number of burst beats (n x 64 bits)

            -- status outputs
            o_busy   : out std_logic;
            o_rdDone : out std_logic;
            o_wrDone : out std_logic;


            -- PLBv34 bus interface     -----------------------------------------

            -- Bus protocol ports, do not add to or delete
            Bus2IP_Clk        : in  std_logic;
            Bus2IP_Reset      : in  std_logic;
            Bus2IP_Addr       : in  std_logic_vector(0 to C_AWIDTH - 1);
            Bus2IP_Data       : in  std_logic_vector(0 to C_DWIDTH-1);
            Bus2IP_DataX      : in  std_logic_vector(C_DWIDTH to C_PLB_DWIDTH-1);
            Bus2IP_BE         : in  std_logic_vector(0 to C_PLB_DWIDTH/8-1);
            Bus2IP_Burst      : in  std_logic;
            Bus2IP_RdCE       : in  std_logic_vector(0 to C_NUM_CE-1);
            Bus2IP_WrCE       : in  std_logic_vector(0 to C_NUM_CE-1);
            Bus2IP_RdReq      : in  std_logic;
            Bus2IP_WrReq      : in  std_logic;
            IP2Bus_Data       : out std_logic_vector(0 to C_DWIDTH-1);
            IP2Bus_DataX      : out std_logic_vector(C_DWIDTH to C_PLB_DWIDTH-1);
            IP2Bus_Retry      : out std_logic;
            IP2Bus_Error      : out std_logic;
            IP2Bus_ToutSup    : out std_logic;
            IP2Bus_RdAck      : out std_logic;
            IP2Bus_WrAck      : out std_logic;
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
            IP2IP_Addr        : out std_logic_vector(0 to C_AWIDTH-1)
            );
end entity mem_plb34;


architecture arch of mem_plb34 is

    ---------
    -- read/write acknowledge
    ---------
    signal ram_IP2Bus_RdAck : std_logic;
    signal ram_IP2Bus_WrAck : std_logic;
    signal slv_IP2Bus_RdAck : std_logic;
    signal slv_IP2Bus_WrAck : std_logic;

    signal slv_rddata : std_logic_vector(0 to C_DWIDTH-1);
begin

    -----------------------------------------------------------------------
    -- bus_master_inst: bus master instantiation
    --
    -- The bus_master module is responsible for initiating a bus read or
    -- write transaction through the IPIF master services. The actual
    -- transaction will appear like a bus initiated slave request at the
    -- IPIF slave attachment and is therefore handled by bus_slave_regs
    -- or the bus2burst process.
    -----------------------------------------------------------------------
    bus_master_inst : entity plb_osif_v2_01_a.bus_master
        generic map (
            C_AWIDTH          => C_AWIDTH,
            C_DWIDTH          => C_DWIDTH,
            C_PLB_DWIDTH      => C_PLB_DWIDTH,
            C_SLAVE_BASEADDR  => C_SLAVE_BASEADDR,
            C_BURST_BASEADDR  => C_BURST_BASEADDR,
            C_BURSTLEN_WIDTH  => C_BURSTLEN_WIDTH
            )
        port map (
            clk               => clk,
            reset             => reset,
            -- PLB bus master signals
            Bus2IP_MstError   => Bus2IP_MstError,
            Bus2IP_MstLastAck => Bus2IP_MstLastAck,
            Bus2IP_MstRdAck   => Bus2IP_MstRdAck,
            Bus2IP_MstWrAck   => Bus2IP_MstWrAck,
            Bus2IP_MstRetry   => Bus2IP_MstRetry,
            Bus2IP_MstTimeOut => Bus2IP_MstTimeOut,
            IP2Bus_Addr       => IP2Bus_Addr,
            IP2Bus_MstBE      => IP2Bus_MstBE,
            IP2Bus_MstBurst   => IP2Bus_MstBurst,
            IP2Bus_MstBusLock => IP2Bus_MstBusLock,
            IP2Bus_MstNum     => IP2Bus_MstNum,
            IP2Bus_MstRdReq   => IP2Bus_MstRdReq,
            IP2Bus_MstWrReq   => IP2Bus_MstWrReq,
            IP2IP_Addr        => IP2IP_Addr,
            -- user interface
            i_target_addr     => i_targetAddr,
            i_my_addr         => i_localAddr,
            i_read_req        => i_singleRdReq,
            i_write_req       => i_singleWrReq,
            i_burst_read_req  => i_burstRdReq,
            i_burst_write_req => i_burstWrReq,
            i_burst_length    => i_burstLen,
            o_busy            => o_busy,
            o_read_done       => o_rdDone,
            o_write_done      => o_wrDone
            );

    -----------------------------------------------------------------------
    -- bus_slave_regs_inst: PLB bus slave instatiation
    --
    -- Handles access to the shared memory register
    -- Used for single word memory accesses
    -- (e.g. reconos_read() and reconos_write())
    -----------------------------------------------------------------------
    bus_slave_regs_inst : entity plb_osif_v2_01_a.bus_slave_regs
        generic map (
            C_DWIDTH         => C_DWIDTH,
            C_NUM_REGS       => C_NUM_CE-1
            )
        port map (
            clk              => Bus2IP_Clk,
            reset            => Bus2IP_Reset,
            -- bus slave signals
            Bus2IP_Data      => Bus2IP_Data,
            Bus2IP_BE        => Bus2IP_BE(0 to (C_DWIDTH/8)-1),
            Bus2IP_RdCE      => Bus2IP_RdCE(0 to C_NUM_CE-2),
            Bus2IP_WrCE      => Bus2IP_WrCE(0 to C_NUM_CE-2),
            IP2Bus_Data      => slv_RdData,
            IP2Bus_RdAck     => slv_IP2Bus_RdAck,
            IP2Bus_WrAck     => slv_IP2Bus_WrAck,
            -- user registers
            slv_osif2bus_shm => i_singleData,
            slv_bus2osif_shm => o_singleData
            );

    -- read/write acknowledge
    IP2Bus_RdAck <= slv_IP2Bus_RdAck or ram_IP2Bus_RdAck;
    IP2Bus_WrAck <= slv_IP2Bus_WrAck or ram_IP2Bus_WrAck;

    -- no error handling / retry / timeout
    IP2Bus_Error   <= '0';
    IP2Bus_Retry   <= '0';
    IP2Bus_ToutSup <= '0';

    -- multiplex data, if PLB connected
    IP2Bus_Data  <= i_burstData(0 to C_DWIDTH-1) when ram_IP2Bus_RdAck = '1' else slv_RdData;
    IP2Bus_DataX <= i_burstData(C_DWIDTH to C_PLB_DWIDTH-1);
    o_burstData  <= Bus2IP_Data & Bus2IP_DataX;
    --    burstWE      <= ram_IP2Bus_WrAck and Bus2IP_WrReq;
    o_burstBE    <= Bus2IP_BE;


    -------------------------------------------------------------------
    -- bus2burst: handles bus accesses to burst memory
    --
    -- supports both single and burst accesses
    -------------------------------------------------------------------
    bus2burst : process(Bus2IP_Clk, Bus2IP_Reset)

        type ram_state_t is (IDLE, BURST_READ, BURST_WRITE, SINGLE_READ);

        variable ram_state  : ram_state_t;
        variable start_addr : std_logic_vector(0 to C_BURST_AWIDTH-1);
        variable counter    : natural := 0;

    begin
        if Bus2IP_Reset = '1' then
            ram_state  := IDLE;
            start_addr := (others => '0');
            counter    := 0;

            ram_IP2Bus_RdAck <= '0';
            ram_IP2Bus_WrAck <= '0';
            o_burstAddr      <= (others => '0');
            o_burstWE        <= '0';
        elsif rising_edge(Bus2IP_Clk) then

            case ram_state is
                when IDLE =>
                    counter := 0;
                    o_burstWE        <= '0';
                    ram_IP2Bus_RdAck <= '0';
                    ram_IP2Bus_WrAck <= '0';

-- if Bus2IP_RdReq = '1' then
                    if Bus2IP_RdCE(1) = '1' and Bus2IP_RdReq = '1' then
                        if Bus2IP_Burst = '1' then
                            start_addr := Bus2IP_Addr(C_PLB_AWIDTH-C_BURST_AWIDTH to C_PLB_AWIDTH-1);  -- get burst start address
                            o_burstAddr      <= start_addr + counter*8;
                            ram_state  := BURST_READ;
                        else
                            o_burstAddr      <= Bus2IP_Addr(C_PLB_AWIDTH-C_BURST_AWIDTH to C_PLB_AWIDTH-1);
                            ram_state  := SINGLE_READ;
                        end if;
-- elsif Bus2IP_WrReq = '1' then
                    elsif Bus2IP_WrCE(1) = '1'and Bus2IP_WrReq = '1' then
                        if Bus2IP_Burst = '1' then
                            start_addr := Bus2IP_Addr(C_PLB_AWIDTH-C_BURST_AWIDTH to C_PLB_AWIDTH-1);  -- get burst start address
                            o_burstAddr      <= start_addr + counter*8;
                            ram_IP2Bus_WrAck <= '1';
                            o_burstWE        <= '1';
                            ram_state := BURST_WRITE;
                        else
                            o_burstAddr <= Bus2IP_Addr(C_PLB_AWIDTH-C_BURST_AWIDTH to C_PLB_AWIDTH-1);
                            ram_IP2Bus_WrAck <= '1';
                            o_burstWE <= '1';
                            ram_state := IDLE;
                        end if;
                    end if;

                when BURST_READ =>
                    ram_IP2Bus_RdAck   <= '1';
                    counter     := counter + 1;
                    if Bus2IP_Burst = '0' then    -- Bus2IP_Burst is deasserted at the second to last data beat
                        ram_IP2Bus_RdAck <= '0';
                        ram_state := IDLE;
                    end if;
                    o_burstAddr            <= start_addr + counter*8;

                when BURST_WRITE =>
                    counter     := counter + 1;
                    if Bus2IP_Burst = '0' then    -- Bus2IP_Burst is deasserted at the second to last data beat
                        ram_IP2Bus_WrAck <= '0';
                        o_burstWE <= '0';
                        ram_state := IDLE;
                    end if;
                    o_burstAddr            <= start_addr + counter*8;

                when SINGLE_READ =>
                    ram_IP2Bus_RdAck   <= '1';
                    ram_state := IDLE;

            end case;
        end if;
    end process;

end arch;
