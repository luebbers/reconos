--!
--! \file fifo_mgr.vhd
--!
--! Protocol converter between FIFO channels, command decoder, and memory
--! interface (TODO).
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       04.10.2007
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
-- 04.10.2007  Enno Luebbers        File created

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo_mgr is
    generic (
        C_FIFO_DWIDTH :    integer := 32
        );
    port (
        clk           : in std_logic;
        reset         : in std_logic;

        -- local FIFO access signals
        i_local_read_remove : in  std_logic;
        o_local_read_data   : out std_logic_vector(0 to C_FIFO_DWIDTH-1);
        o_local_read_wait   : out std_logic;  -- either empty or busy
        i_local_write_add   : in  std_logic;
        i_local_write_data  : in  std_logic_vector(0 to C_FIFO_DWIDTH-1);
        o_local_write_wait  : out std_logic;  -- either full or busy

        -- "real" FIFO access signals
        -- left (read) FIFO
        o_fifo_read_en    : out std_logic;
        i_fifo_read_data  : in  std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifo_read_ready : in  std_logic;

        -- right (write) FIFO
        o_fifo_write_en    : out std_logic;
        o_fifo_write_data  : out std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifo_write_ready : in  std_logic

        -- TODO: signal to communicate with the bus_slave_regs module
        );
end fifo_mgr;

architecture behavioral of fifo_mgr is

    signal local_read_remove_d1 : std_logic := '0';

begin

    -- delay read_remove for 1 clock cycle
    process(clk, reset)
    begin
        if reset = '1' then
            local_read_remove_d1 <= '0';
        elsif rising_edge(clk) then
            local_read_remove_d1 <= i_local_read_remove;
        end if;
    end process;

    -- for now, the FIFO manager only services local accesses.
    -- so we just need to pass the local access signals straight
    -- through to the "real" FIFOs

    o_fifo_read_en    <= local_read_remove_d1;  -- hack to fit slow OSIF request/busy handshake
                                        -- this will be obsoleted once we connect the HW
                                        -- FIFO to the burst RAM interface (mq)
    o_local_read_data <= i_fifo_read_data;
    o_local_read_wait <= not i_fifo_read_ready;

    o_fifo_write_en   <= i_local_write_add;
    o_fifo_write_data <= i_local_write_data;
    o_local_write_wait <= not i_fifo_write_ready;
    
end behavioral;

