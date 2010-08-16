--!
--! \file dcr_slave_regs.vhd
--!
--! DCR bus slave logic for ReconOS OSIF (user_logic)
--!
--! Contains the bus access logic for the two register sets of the OSIF:
--!
--! bus2osif registers (writeable by the bus, readable by OSIF logic):
--!   slv_bus2osif_command     command register           C_DCR_BASEADDR + 0x00
--!   slv_bus2osif_data        data register              C_DCR_BASEADDR + 0x01
--!   slv_bus2osif_done        s/w-access handshake reg   C_DCR_BASEADDR + 0x02
--!   UNUSED                                              C_DCR_BASEADDR + 0x03
--!
--! osif2bus registers (readable by the bus, writeable by OSIF logic):
--!   slv_osif2bus_command     command register           C_DCR_BASEADDR + 0x00
--!   slv_osif2bus_data        data register              C_DCR_BASEADDR + 0x01
--!   slv_osif2bus_datax       extended data register     C_DCR_BASEADDR + 0x02
--!   slv_osif2bus_signature   hardware thread signature  C_DCR_BASEADDR + 0x03
--!
--!
--! The i_post signal is set on a OS request which needs to be handled in
--! software.
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
-- 23.11.2007  Enno Luebbers     moved to DCR interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
--use IEEE.STD_LOGIC_ARITH.all;
--use IEEE.STD_LOGIC_UNSIGNED.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity dcr_slave_regs is
    generic (
        C_DCR_BASEADDR :     std_logic_vector := "1111111111";
        C_DCR_HIGHADDR :     std_logic_vector := "0000000000";
        C_DCR_AWIDTH   :     integer          := 10;
        C_DCR_DWIDTH   :     integer          := 32;
        C_NUM_REGS     :     integer          := 4;
        C_INCLUDE_ILA  :     integer          := 0  -- 0: no ILA, 1: ILA
                                                    -- for DCR debug
        );
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;             -- high active synchronous
        o_dcrAck       : out std_logic;
        o_dcrDBus      : out std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrABus      : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
        i_dcrDBus      : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrRead      : in  std_logic;
        i_dcrWrite     : in  std_logic;
        i_dcrICON      : in  std_logic_vector(35 downto 0);

        -- user registers
        slv_osif2bus_command : in std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);
        slv_osif2bus_flags   : in std_logic_vector(0 to C_OSIF_FLAGS_WIDTH-1);
        slv_osif2bus_saved_state_enc : in std_logic_vector(0 to C_OSIF_STATE_ENC_WIDTH-1);
        slv_osif2bus_saved_step_enc : in std_logic_vector(0 to C_OSIF_STEP_ENC_WIDTH-1);
        slv_osif2bus_data    : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        slv_osif2bus_datax   : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        slv_osif2bus_signature : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);

        slv_bus2osif_command : out std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);
        slv_bus2osif_data    : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        slv_bus2osif_done    : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        -- additional user interface
        o_newcmd             : out std_logic;
        i_post               : in  std_logic;
        o_busy               : out std_logic;
        o_interrupt          : out std_logic
        );
end dcr_slave_regs;

architecture behavioral of dcr_slave_regs is

    -- chipscope DCR ILA component
    component dcr_ila
        port
            (
                control : in std_logic_vector(35 downto 0);
                clk     : in std_logic;
                data    : in std_logic_vector(76 downto 0);
                trig0   : in std_logic_vector(2 downto 0)
                );
    end component;

    -- Bus signalling helper signals
    signal dcrAddrHit : std_logic;
    signal dcrAck     : std_logic;
    signal regAddr    : std_logic_vector(0 to 1);  -- FIXME: hardcoded
    signal readCE     : std_logic_vector(0 to C_NUM_REGS-1);
    signal writeCE    : std_logic_vector(0 to C_NUM_REGS-1);

    -- Bus signalling helper signals
    signal slv_ip2bus_data      : std_logic_vector(0 to C_DCR_DWIDTH-1);
    signal slv_reg_write_select : std_logic_vector(0 to C_NUM_REGS-1);
    signal slv_reg_read_select  : std_logic_vector(0 to C_NUM_REGS-1);

    -- Actual bus2osif registers
    signal slv_bus2osif_command_reg : std_logic_vector(0 to C_DCR_DWIDTH-1) := (others => '0');
    signal slv_bus2osif_data_reg    : std_logic_vector(0 to C_DCR_DWIDTH-1) := (others => '0');
    signal slv_bus2osif_done_reg    : std_logic_vector(0 to C_DCR_DWIDTH-1) := (others => '0');

    -- new command arrived  
    signal newcmd             : std_logic;
    -- signals indicating unread data in bus-readable registers
    signal osif2bus_reg_dirty : std_logic_vector(0 to 2) := "000";

    -- DCR debug ILA signals
    signal ila_data  : std_logic_vector(76 downto 0);
    signal ila_trig0 : std_logic_vector(2 downto 0);



begin

---------------------------------------------------
-- CHIPSCOPE

    gen_dcr_ila : if C_INCLUDE_ILA = 1 generate

        dcr_ila_inst : dcr_ila
            port map
            (
                control => i_dcrICON,
                clk     => clk,
                data    => ila_data,
                trig0   => ila_trig0
                );

-- bits 76 75 74-65 64-33 32 31-0
--ila_data <= i_dcrRead & i_dcrWrite & i_dcrABus & i_dcrDBus & dcrAck & slv_ip2bus_data;
        ila_data  <= i_dcrRead & i_dcrWrite & i_dcrABus & i_dcrDBus & newcmd & slv_ip2bus_data;
        ila_trig0 <= i_dcrRead & i_dcrWrite & dcrAck;

    end generate;
---------------------------------------------------

----------------------------------------------------------------------------------------------------------
-- DCR "IPIF"
----------------------------------------------------------------------------------------------------------

    -- 4 registers = 2 LSBs FIXME: hardcoded. Use log2 instead!
    dcrAddrHit <= '1' when i_dcrABus(0 to C_DCR_AWIDTH-3) = C_DCR_BASEADDR(0 to C_DCR_AWIDTH-3)
                  else '0';
    regAddr    <= i_dcrABus(C_DCR_AWIDTH-2 to C_DCR_AWIDTH-1);

    --
    -- decode read and write accesses into chip enable signals
    -- ASYNCHRONOUS
    --
    ce_gen : process(dcrAddrHit, i_dcrRead, i_dcrWrite,
                     regAddr)
    begin
        -- clear all chip enables by default
        for i in 0 to C_NUM_REGS-1 loop
            readCE(i)  <= '0';
            writeCE(i) <= '0';
        end loop;

        -- decode register address and set
        -- corresponding chip enable signal
        if dcrAddrHit = '1' then
            if i_dcrRead = '1' then
                readCE(TO_INTEGER(unsigned(regAddr)))  <= '1';
            elsif i_dcrWrite = '1' then
                writeCE(TO_INTEGER(unsigned(regAddr))) <= '1';
            end if;
        end if;
    end process;

    --
    -- generate DCR slave acknowledge signal
    -- SYNCHRONOUS
    --
    gen_ack_proc : process(clk, reset)
    begin
        if reset = '1' then
            dcrAck <= '0';
        elsif rising_edge(clk) then
            dcrAck <= ( i_dcrRead or i_dcrWrite ) and
                      dcrAddrHit;
        end if;
    end process;

    o_dcrAck <= dcrAck;

--  --
--      -- update slave registers on write access
--      -- SYNCHRONOUS
--      --
--      reg_write_proc: process(i_clk, i_reset)
--      begin
--              if i_reset = '1' then
--                      slv_reg0 <= (others => '0');
--                      slv_reg1 <= (others => '0');
--                      slv_reg2 <= (others => '0');
--                      slv_reg3 <= (others => '0');
--              elsif rising_edge(i_clk) then
--                      case writeCE is
--                              when "0001" =>
--                                      slv_reg0 <= i_dcrDBus;
--                              when "0010" =>
--                                      slv_reg1 <= i_dcrDBus;
--                              when "0100" =>
--                                      slv_reg2 <= i_dcrDBus;
--                              when "1000" =>
--                                      slv_reg3 <= i_dcrDBus;
--                              when others => null;
--                      end case;
--              end if;
--      end process;

--  --
--      -- output slave registers on data bus on read access
--      -- ASYNCHRONOUS
--      --
--      reg_read_proc: process(readCE, slv_reg0, slv_reg1, slv_reg2,
--      slv_reg3, i_dcrDBus)
--      begin
--              o_dcrDBus <= i_dcrDBus;
--              case readCE is
--                      when "0001" =>
--                              o_dcrDBus <= slv_reg0;
--                      when "0010" =>
--                              o_dcrDBus <= slv_reg1;
--                      when "0100" =>
--                              o_dcrDBus <= slv_reg2;
--                      when "1000" =>
--                              o_dcrDBus <= slv_reg3;
--                      when others =>
--                              o_dcrDBus <= i_dcrDBus;
--              end case;
--      end process;


----------------------------------------------------------------------------------------------------------
-- DCR "IPIF" END
----------------------------------------------------------------------------------------------------------

    -- ######################### CONCURRENT ASSIGNMENTS #######################

    -- connect registers to outputs
    slv_bus2osif_command <= slv_bus2osif_command_reg(0 to C_OSIF_CMD_WIDTH-1);
    slv_bus2osif_data    <= slv_bus2osif_data_reg;
    slv_bus2osif_done    <= slv_bus2osif_done_reg;
-- slv_bus2osif_shm <= slv_bus2osif_shm_reg;

    -- new command from OS if write_reg2 is all ones. FIXME: 0000_0001 sufficient?
    -- this is here to prevent incomplete command transmission if CPU uses byte accesses
    -- will be cleared on cycle after assertion (see slave_reg_write_proc)
    newcmd   <= '1' when slv_bus2osif_done_reg = X"FFFF_FFFF" else '0';
    o_newcmd <= newcmd;

    -- we are busy as long as a pending request has not been retrieved by the CPU
    o_busy <= osif2bus_reg_dirty(0) or osif2bus_reg_dirty(1) or osif2bus_reg_dirty(2) or i_post;

    -- posting generates an interrupt
    o_interrupt <= i_post;

    -- drive IP to DCR Bus signals
    o_dcrDBus <= slv_ip2bus_data;

    -- connect bus signalling
    slv_reg_write_select <= writeCE;
    slv_reg_read_select  <= readCE;

    -- ############################### PROCESSES ############################

    -------------------------------------------------------------
    -- slave_reg_write_proc: implement bus write access to slave
    -- registers
    -------------------------------------------------------------
    slave_reg_write_proc : process(clk) is
    begin

        if clk'event and clk = '1' then
            if reset = '1' then
                slv_bus2osif_command_reg             <= (others => '0');
                slv_bus2osif_data_reg                <= (others => '0');
                slv_bus2osif_done_reg                <= (others => '0');
            else
                if dcrAck = '0' then    -- register values only ONCE per write select
                    case slv_reg_write_select(0 to 3) is
                        when "1000"                             =>
                            slv_bus2osif_command_reg <= i_dcrDBus;
                        when "0100"                             =>
                            slv_bus2osif_data_reg    <= i_dcrDBus;
                        when "0010"                             =>
                            slv_bus2osif_done_reg    <= i_dcrDBus;
                        when "0001"                             => null;
                        when others                             => null;
                    end case;
                end if;

                if newcmd = '1' then
                    slv_bus2osif_done_reg <= (others => '0');
                end if;

            end if;
        end if;

    end process SLAVE_REG_WRITE_PROC;

    -------------------------------------------------------------
    -- slave_reg_read_proc: implement bus read access to slave
    -- registers
    -------------------------------------------------------------
    slave_reg_read_proc : process(slv_reg_read_select, slv_osif2bus_command, slv_osif2bus_data, slv_osif2bus_datax, i_dcrDBus) is
    begin

        slv_ip2bus_data <= i_dcrDBus;

        case slv_reg_read_select(0 to 3) is
            when "1000" => slv_ip2bus_data <= slv_osif2bus_command & slv_osif2bus_flags & slv_osif2bus_saved_state_enc & slv_osif2bus_saved_step_enc & "000000";
            when "0100" => slv_ip2bus_data <= slv_osif2bus_data;
            when "0010" => slv_ip2bus_data <= slv_osif2bus_datax;
            when "0001" => slv_ip2bus_data <= slv_osif2bus_signature;
-- when others => slv_ip2bus_data <= (others => '0');
            when others => null;
        end case;

    end process SLAVE_REG_READ_PROC;


    -----------------------------------------------------------------------
    -- dirty_flags: sets and clears osif2bus_reg_dirty bits
    --
    -- This allows to block the user task in a busy state while waiting
    -- for OS to fetch the new commands.
    -- The signature register does not need to be read to clear the dirty
    -- flags.
    -- The dirty flags are (obviously) only set on software-handled requests.
    -----------------------------------------------------------------------
    dirty_flags : process(reset, clk)     --, i_post, slv_reg_read_select)
    begin
        if reset = '1' then
            osif2bus_reg_dirty <= "000";
            -- request only pollutes the read registers, if request is to be handled by software
        elsif rising_edge(clk) then

            if i_post = '1' then
                osif2bus_reg_dirty        <= "111";
            else
                case slv_reg_read_select(0 to 3) is
                    when "1000" =>
                        osif2bus_reg_dirty(0) <= '0';
                    when "0100" =>
                        osif2bus_reg_dirty(1) <= '0';
                    when "0010" =>
                        osif2bus_reg_dirty(2) <= '0';
                    when others => null;
                end case;
            end if;
            
        end if;
    end process;


end behavioral;

