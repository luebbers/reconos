--!
--! \file dcr_slave_regs.vhd
--!
--! DCR bus slave logic for ReconOS OSIF (user_logic)
--!
--! Contains the bus access logic for the two register sets of the OSIF:
--!
--! bus2osif registers (writeable by the bus, readable by OSIF logic):
--!   o_bus2osif_command     command register           C_DCR_BASEADDR + 0x00
--!   o_bus2osif_data        data register              C_DCR_BASEADDR + 0x01
--!   o_bus2osif_done        s/w-access handshake reg   C_DCR_BASEADDR + 0x02
--!   UNUSED                                              C_DCR_BASEADDR + 0x03
--!
--! osif2bus registers (readable by the bus, writeable by OSIF logic):
--!   i_osif2bus_command     command register           C_DCR_BASEADDR + 0x00
--!   i_osif2bus_data        data register              C_DCR_BASEADDR + 0x01
--!   i_osif2bus_datax       extended data register     C_DCR_BASEADDR + 0x02
--!   i_osif2bus_signature   hardware thread signature  C_DCR_BASEADDR + 0x03
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
-- 25.09.2007  Enno Luebbers     added i_osif2bus_datax
-- 23.11.2007  Enno Luebbers     moved to DCR interface
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
--use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity dcr_slave_regs is
    generic (
        C_DCR_BASEADDR :     std_logic_vector := "1111111111";
        C_DCR_HIGHADDR :     std_logic_vector := "0000000000";
        C_DCR_AWIDTH   :     integer          := 10;
        C_DCR_DWIDTH   :     integer          := 32;
        C_NUM_REGS     :     integer          := 8;
        C_ENABLE_MMU   :     boolean          := true;
        C_INCLUDE_ILA  :     integer          := 0  -- 0: no ILA, 1: ILA
    );
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;             -- high active synchronous
        
        -- DCR interface
        o_dcrAck       : out std_logic;
        o_dcrDBus      : out std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrABus      : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
        i_dcrDBus      : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrRead      : in  std_logic;
        i_dcrWrite     : in  std_logic;
        i_dcrICON      : in  std_logic_vector(35 downto 0);
        
        -- mmu diagnosis registers
        i_tlb_miss_count   : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
        i_tlb_hit_count    : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
        i_page_fault_count : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);

        -- user registers
        i_osif2bus_command : in std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);
        i_osif2bus_flags   : in std_logic_vector(0 to C_OSIF_FLAGS_WIDTH-1);
        i_osif2bus_saved_state_enc : in std_logic_vector(0 to C_OSIF_STATE_ENC_WIDTH-1);
        i_osif2bus_saved_step_enc : in std_logic_vector(0 to C_OSIF_STEP_ENC_WIDTH-1);
        i_osif2bus_data    : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        i_osif2bus_datax   : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        i_osif2bus_signature : in std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);

        o_bus2osif_command : out std_logic_vector(0 to C_OSIF_CMD_WIDTH-1);
        o_bus2osif_data    : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        o_bus2osif_done    : out std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
        -- additional user interface
        o_newcmd             : out std_logic;
        i_post               : in  std_logic;
        o_busy               : out std_logic
        --o_interrupt          : out std_logic
    );
end dcr_slave_regs;

architecture behavioral of dcr_slave_regs is

    -- chipscope DCR ILA component
    component dcr_ila
        port (
            control : in std_logic_vector(35 downto 0);
            clk     : in std_logic;
            data    : in std_logic_vector(76 downto 0);
            trig0   : in std_logic_vector(2 downto 0)
        );
    end component;
    
    constant C_OSIF_DCR_AWIDTH  : natural := 3;

    type reg_select_t is (
        C_SELECT_NONE,
        C_SELECT_COMMAND,
        C_SELECT_DATA,
        C_SELECT_DONE,
        C_SELECT_SIGNATURE,
        C_SELECT_TLB_MISS,
        C_SELECT_TLB_HIT,
        C_SELECT_PGFAULT
    );
    
    -- Bus signalling helper signals
    signal dcrAddrHit : std_logic;
    signal dcrAck     : std_logic;

    -- Bus signalling helper signals
    signal ip2bus_data      : std_logic_vector(0 to C_DCR_DWIDTH-1);
    signal reg_write_select : reg_select_t;
    signal reg_read_select : reg_select_t;

    -- Actual bus2osif registers
    signal bus2osif_command_reg : std_logic_vector(0 to C_DCR_DWIDTH-1) := (others => '0');
    signal bus2osif_data_reg    : std_logic_vector(0 to C_DCR_DWIDTH-1) := (others => '0');
    signal bus2osif_done_reg    : std_logic_vector(0 to C_DCR_DWIDTH-1) := (others => '0');

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
        port map (
            control => i_dcrICON,
            clk     => clk,
            data    => ila_data,
            trig0   => ila_trig0
        );

-- bits 76 75 74-65 64-33 32 31-0
--ila_data <= i_dcrRead & i_dcrWrite & i_dcrABus & i_dcrDBus & dcrAck & ip2bus_data;
        ila_data  <= i_dcrRead & i_dcrWrite & i_dcrABus & i_dcrDBus & newcmd & ip2bus_data;
        ila_trig0 <= i_dcrRead & i_dcrWrite & dcrAck;

    end generate;
---------------------------------------------------

----------------------------------------------------------------------------------------------------------
-- DCR "IPIF"
----------------------------------------------------------------------------------------------------------

    -- 4 registers = 2 LSBs FIXME: hardcoded. Use log2 instead!
    --dcrAddrHit <= '1' when i_dcrABus(0 to C_DCR_AWIDTH-C_OSIF_DCR_AWIDTH) = C_DCR_BASEADDR(0 to C_DCR_AWIDTH-C_OSIF_DCR_AWIDTH)
    --              else '0';
    --regAddr    <= i_dcrABus(C_DCR_AWIDTH-C_OSIF_DCR_AWIDTH+1 to C_DCR_AWIDTH-1);

    --
    -- decode read and write accesses into chip enable signals
    -- ASYNCHRONOUS
    --
    ce_gen : process(dcrAddrHit, i_dcrRead, i_dcrWrite, i_dcrABus)
        variable tmp : reg_select_t;
    begin
        -- decode register address and set
        -- corresponding chip enable signal
        dcrAddrHit <= '1';
        if    i_dcrABus = C_DCR_BASEADDR + 0 then tmp := C_SELECT_COMMAND;
        elsif i_dcrABus = C_DCR_BASEADDR + 1 then tmp := C_SELECT_DATA;
        elsif i_dcrABus = C_DCR_BASEADDR + 2 then tmp := C_SELECT_DONE;
        elsif i_dcrABus = C_DCR_BASEADDR + 3 then tmp := C_SELECT_SIGNATURE;
        elsif C_ENABLE_MMU and i_dcrABus = C_DCR_BASEADDR + 4 then tmp := C_SELECT_TLB_MISS;
        elsif C_ENABLE_MMU and i_dcrABus = C_DCR_BASEADDR + 5 then tmp := C_SELECT_TLB_HIT;
        elsif C_ENABLE_MMU and i_dcrABus = C_DCR_BASEADDR + 6 then tmp := C_SELECT_PGFAULT;
        else
            tmp := C_SELECT_NONE;
            dcrAddrHit <= '0';
        end if;
        
        if    i_dcrRead  = '1' then
            reg_read_select <= tmp;
            reg_write_select <= C_SELECT_NONE;
        elsif i_dcrWrite = '1' then
            reg_read_select <= C_SELECT_NONE;
            reg_write_select <= tmp;
        else
            reg_read_select <= C_SELECT_NONE;
            reg_write_select <= C_SELECT_NONE;
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
            dcrAck <= ( i_dcrRead or i_dcrWrite ) and dcrAddrHit;
        end if;
    end process;

    o_dcrAck <= dcrAck;

    -- connect registers to outputs
    o_bus2osif_command <= bus2osif_command_reg(0 to C_OSIF_CMD_WIDTH-1);
    o_bus2osif_data    <= bus2osif_data_reg;
    o_bus2osif_done    <= bus2osif_done_reg;

    -- new command from OS if write_reg2 is all ones. FIXME: 0000_0001 sufficient?
    -- this is here to prevent incomplete command transmission if CPU uses byte accesses
    -- will be cleared on cycle after assertion (see slave_reg_write_proc)
    newcmd   <= '1' when bus2osif_done_reg = X"FFFF_FFFF" else '0';
    o_newcmd <= newcmd;

    -- we are busy as long as a pending request has not been retrieved by the CPU
    o_busy <= osif2bus_reg_dirty(0) or osif2bus_reg_dirty(1) or osif2bus_reg_dirty(2) or i_post;

    -- posting generates an interrupt
--	o_interrupt <= i_post;

    -- drive IP to DCR Bus signals
    o_dcrDBus <= ip2bus_data;

    -- connect bus signalling
    --reg_write_select <= writeCE;
    --reg_read_select  <= readCE;

    -------------------------------------------------------------
    -- slave_reg_write_proc: implement bus write access to slave
    -- registers
    -------------------------------------------------------------
    slave_reg_write_proc : process(clk) is
    begin

        if clk'event and clk = '1' then
            if reset = '1' then
                bus2osif_command_reg             <= (others => '0');
                bus2osif_data_reg                <= (others => '0');
                bus2osif_done_reg                <= (others => '0');
            else
                if dcrAck = '0' then    -- register values only ONCE per write select
                    case reg_write_select is
                        when C_SELECT_COMMAND   =>
                            bus2osif_command_reg <= i_dcrDBus;
                        when C_SELECT_DATA      =>
                            bus2osif_data_reg    <= i_dcrDBus;
                        when C_SELECT_DONE      =>
                            bus2osif_done_reg    <= i_dcrDBus;
                        --when C_SELECT_SIGNATURE => null;
                        when others             => null;
                    end case;
                end if;

                if newcmd = '1' then
                    bus2osif_done_reg <= (others => '0');
                end if;

            end if;
        end if;

    end process SLAVE_REG_WRITE_PROC;

    -------------------------------------------------------------
    -- slave_reg_read_proc: implement bus read access to slave
    -- registers
    -------------------------------------------------------------
    slave_reg_read_proc : process(reg_read_select, i_osif2bus_command, i_osif2bus_data, i_osif2bus_datax, i_dcrDBus,
            i_osif2bus_flags, i_osif2bus_saved_state_enc, i_osif2bus_saved_step_enc, i_osif2bus_signature, i_tlb_miss_count, i_tlb_hit_count, i_page_fault_count) is
    begin

        ip2bus_data <= i_dcrDBus;

        case reg_read_select is
            when C_SELECT_COMMAND   => ip2bus_data <= i_osif2bus_command & i_osif2bus_flags & i_osif2bus_saved_state_enc & i_osif2bus_saved_step_enc & "000000";
            when C_SELECT_DATA      => ip2bus_data <= i_osif2bus_data;
            when C_SELECT_DONE      => ip2bus_data <= i_osif2bus_datax;
            when C_SELECT_SIGNATURE => ip2bus_data <= i_osif2bus_signature;
            when C_SELECT_TLB_MISS  => ip2bus_data <= i_tlb_miss_count;
            when C_SELECT_TLB_HIT   => ip2bus_data <= i_tlb_hit_count;
            when C_SELECT_PGFAULT   => ip2bus_data <= i_page_fault_count;
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
    dirty_flags : process(reset, clk)     --, i_post, reg_read_select)
    begin
        if reset = '1' then
            osif2bus_reg_dirty <= (others => '0');
            -- request only pollutes the read registers, if request is to be handled by software
        elsif rising_edge(clk) then

            if i_post = '1' then
                osif2bus_reg_dirty        <= (others => '1');
            else
                if reg_read_select = C_SELECT_COMMAND then osif2bus_reg_dirty(0) <= '0'; end if;
                if reg_read_select = C_SELECT_DATA    then osif2bus_reg_dirty(1) <= '0'; end if;
                if reg_read_select = C_SELECT_DONE    then osif2bus_reg_dirty(2) <= '0'; end if;
            end if;
        end if;
    end process;


end behavioral;

