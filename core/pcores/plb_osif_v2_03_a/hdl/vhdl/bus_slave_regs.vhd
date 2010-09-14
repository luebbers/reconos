--!
--! \file bus_slave_regs.vhd
--!
--! PLB bus slave logic for ReconOS OSIF (user_logic)
--!
--! Contains the bus access logic for the single memory access register.
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       07.08.2006
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
-- Major changes
-- 07.08.2006  Enno Luebbers     File created
-- 25.09.2007  Enno Luebbers     added slv_osif2bus_datax
-- 04.07.2008  Enno Luebbers     trimmed deprecated PLB registers
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity bus_slave_regs is
    generic (
        C_DWIDTH         :     integer := 32;
        C_NUM_REGS       :     integer := 1  -- number of standard osif registers
        );
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;  -- high active synchronous
        -- bus slave signals
        Bus2IP_Data      : in  std_logic_vector(0 to C_DWIDTH-1);
        Bus2IP_BE        : in  std_logic_vector(0 to C_DWIDTH/8-1);
        Bus2IP_RdCE      : in  std_logic_vector(0 to C_NUM_REGS-1);
        Bus2IP_WrCE      : in  std_logic_vector(0 to C_NUM_REGS-1);
        IP2Bus_Data      : out std_logic_vector(0 to C_DWIDTH-1);
        IP2Bus_RdAck     : out std_logic;
        IP2Bus_WrAck     : out std_logic;
        -- user registers
        slv_osif2bus_shm : in  std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        slv_bus2osif_shm : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1)
        );
end bus_slave_regs;

architecture behavioral of bus_slave_regs is

    constant C_NUM_CE_TOTAL : integer := C_NUM_REGS;

    -- Bus signalling helper signals
    signal slv_reg_write_select : std_logic_vector(0 to C_NUM_REGS-1);
    signal slv_reg_read_select  : std_logic_vector(0 to C_NUM_REGS-1);
    signal slv_ip2bus_data      : std_logic_vector(0 to C_DWIDTH-1);
    signal slv_read_ack         : std_logic;
    signal slv_write_ack        : std_logic;

    -- Actual bus2osif registers
    signal slv_bus2osif_shm_reg : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');

begin

    -- ### CHECK GENERICS ###
    assert C_NUM_REGS = 1
        report "bus_slave_regs does not support more than one register (shm)."
        severity failure;

    -- ######################### CONCURRENT ASSIGNMENTS #######################

    -- connect registers to outputs
    slv_bus2osif_shm <= slv_bus2osif_shm_reg;

    -- drive IP to Bus signals
    IP2Bus_Data  <= slv_ip2bus_data;
    IP2Bus_RdAck <= slv_read_ack;
    IP2Bus_WrAck <= slv_write_ack;

    -- connect bus signalling
    slv_reg_write_select <= Bus2IP_WrCE(0 to C_NUM_REGS-1);
    slv_reg_read_select  <= Bus2IP_RdCE(0 to C_NUM_REGS-1);
    slv_write_ack        <= Bus2IP_WrCE(0);
    slv_read_ack         <= Bus2IP_RdCE(0);
                                        -- FIXME: reduce_or?

    -- ############################### PROCESSES ############################

    -------------------------------------------------------------
    -- slave_reg_write_proc: implement bus write access to slave
    -- registers
    -------------------------------------------------------------
    slave_reg_write_proc : process(clk) is
    begin

        if clk'event and clk = '1' then
            if reset = '1' then
                slv_bus2osif_shm_reg                                                 <= (others => '0');
            else
                case slv_reg_write_select(0 to 0) is
                    when "1"                                                                    =>
                        for byte_index in 0 to (C_DWIDTH/8)-1 loop
                            if (Bus2IP_BE(byte_index) = '1') then
                                slv_bus2osif_shm_reg(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
                            end if;
                        end loop;
                    when others                                                                 => null;
                end case;
            end if;
        end if;

    end process SLAVE_REG_WRITE_PROC;

    -------------------------------------------------------------
    -- slave_reg_read_proc: implement bus read access to slave
    -- registers
    -------------------------------------------------------------
    slave_reg_read_proc : process(slv_reg_read_select, slv_osif2bus_shm) is
    begin

        slv_ip2bus_data <= (others => '0');

        case slv_reg_read_select(0 to 0) is
            when "1" => slv_ip2bus_data <= slv_osif2bus_shm;
-- when others => slv_ip2bus_data <= (others => '0');
            when others =>
        end case;

    end process SLAVE_REG_READ_PROC;

end behavioral;

