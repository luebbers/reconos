--!
--! \file osif.vhd
--!
--! OSIF logic and interface to IPIF
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       01.08.2006
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
-- 01.08.2006   Enno Luebbers   File created (from opb_reconos_slot_v1_00_c)
-- 03.08.2006   Enno Luebbers   Added PLB bus master (moved to v1.01.a),
--                              removed BRAM interface
-- 23.11.2007   Enno Luebbers   Moved OS communications to DCR
-- 07.12.2008   Enno Luebbers   Moved memory bus interface to separate module
--
------------------------------------------------------------------------------
--
-- Original Xilinx header follows
--
------------------------------------------------------------------------------
-- osif.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR                           --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2006 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          osif.vhd
-- Version:           1.01.a
-- Description:       Top level design, instantiates IPIF and user logic.
-- Date:              Tue Aug  1 12:51:51 2006 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v1_00_b;
use proc_common_v1_00_b.proc_common_pkg.all;

library ipif_common_v1_00_e;
use ipif_common_v1_00_e.ipif_pkg.all;
library plb_ipif_v2_01_a;
use plb_ipif_v2_01_a.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

library plb_osif_v2_03_a;
use plb_osif_v2_03_a.all;

library osif_core_v2_03_a;
use osif_core_v2_03_a.all;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
-- C_BASEADDR                           -- User logic base address
--   C_HIGHADDR                         -- User logic high address
--   C_PLB_AWIDTH                       -- PLB address bus width
--   C_PLB_DWIDTH                       -- PLB address data width
--   C_PLB_NUM_MASTERS                  -- Number of PLB masters
--   C_PLB_MID_WIDTH                    -- log2(C_PLB_NUM_MASTERS)
--   C_FAMILY                           -- Target FPGA architecture
--
-- Definition of Ports:
--   PLB_Clk                            -- PLB Clock
--   PLB_Rst                            -- PLB Reset
--   Sl_addrAck                         -- Slave address acknowledge
--   Sl_MBusy                           -- Slave busy indicator
--   Sl_MErr                            -- Slave error indicator
--   Sl_rdBTerm                         -- Slave terminate read burst transfer
--   Sl_rdComp                          -- Slave read transfer complete indicator
--   Sl_rdDAck                          -- Slave read data acknowledge
--   Sl_rdDBus                          -- Slave read data bus
--   Sl_rdWdAddr                        -- Slave read word address
--   Sl_rearbitrate                     -- Slave re-arbitrate bus indicator
--   Sl_SSize                           -- Slave data bus size
--   Sl_wait                            -- Slave wait indicator
--   Sl_wrBTerm                         -- Slave terminate write burst transfer
--   Sl_wrComp                          -- Slave write transfer complete indicator
--   Sl_wrDAck                          -- Slave write data acknowledge
--   PLB_abort                          -- PLB abort request indicator
--   PLB_ABus                           -- PLB address bus
--   PLB_BE                             -- PLB byte enables
--   PLB_busLock                        -- PLB bus lock
--   PLB_compress                       -- PLB compressed data transfer indicator
--   PLB_guarded                        -- PLB guarded transfer indicator
--   PLB_lockErr                        -- PLB lock error indicator
--   PLB_masterID                       -- PLB current master identifier
--   PLB_MSize                          -- PLB master data bus size
--   PLB_ordered                        -- PLB synchronize transfer indicator
--   PLB_PAValid                        -- PLB primary address valid indicator
--   PLB_pendPri                        -- PLB pending request priority
--   PLB_pendReq                        -- PLB pending bus request indicator
--   PLB_rdBurst                        -- PLB burst read transfer indicator
--   PLB_rdPrim                         -- PLB secondary to primary read request indicator
--   PLB_reqPri                         -- PLB current request priority
--   PLB_RNW                            -- PLB read/not write
--   PLB_SAValid                        -- PLB secondary address valid indicator
--   PLB_size                           -- PLB transfer size
--   PLB_type                           -- PLB transfer type
--   PLB_wrBurst                        -- PLB burst write transfer indicator
--   PLB_wrDBus                         -- PLB write data bus
--   PLB_wrPrim                         -- PLB secondary to primary write request indicator
--   M_abort                            -- Master abort bus request indicator
--   M_ABus                             -- Master address bus
--   M_BE                               -- Master byte enables
--   M_busLock                          -- Master buslock
--   M_compress                         -- Master compressed data transfer indicator
--   M_guarded                          -- Master guarded transfer indicator
--   M_lockErr                          -- Master lock error indicator
--   M_MSize                            -- Master data bus size
--   M_ordered                          -- Master synchronize transfer indicator
--   M_priority                         -- Master request priority
--   M_rdBurst                          -- Master burst read transfer indicator
--   M_request                          -- Master request
--   M_RNW                              -- Master read/nor write
--   M_size                             -- Master transfer size
--   M_type                             -- Master transfer type
--   M_wrBurst                          -- Master burst write transfer indicator
--   M_wrDBus                           -- Master write data bus
--   PLB_MBusy                          -- PLB master slave busy indicator
--   PLB_MErr                           -- PLB master slave error indicator
--   PLB_MWrBTerm                       -- PLB master terminate write burst indicator
--   PLB_MWrDAck                        -- PLB master write data acknowledge
--   PLB_MAddrAck                       -- PLB master address acknowledge
--   PLB_MRdBTerm                       -- PLB master terminate read burst indicator
--   PLB_MRdDAck                        -- PLB master read data acknowledge
--   PLB_MRdDBus                        -- PLB master read data bus
--   PLB_MRdWdAddr                      -- PLB master read word address
--   PLB_MRearbitrate                   -- PLB master bus re-arbitrate indicator
--   PLB_MSSize                         -- PLB slave data bus size
------------------------------------------------------------------------------

entity plb_osif is
    generic
    (
        C_BURST_AWIDTH    :     integer          := 13;  -- 1024 x 64 Bit = 8192 Bytes = 2^13 Bytes
        C_FIFO_DWIDTH     :     integer          := 32;
        C_BASEADDR        :     std_logic_vector := X"FFFFFFFF";
        C_HIGHADDR        :     std_logic_vector := X"00000000";
        C_PLB_AWIDTH      :     integer          := 32;
        C_PLB_DWIDTH      :     integer          := 64;
        C_PLB_NUM_MASTERS :     integer          := 8;
        C_PLB_MID_WIDTH   :     integer          := 3;
        C_BURSTLEN_WIDTH  :     integer          := 5;
        C_FAMILY          :     string           := "virtex2p";
        C_DCR_BASEADDR    :     std_logic_vector := "1111111111";
        C_DCR_HIGHADDR    :     std_logic_vector := "0000000000";
        C_DCR_AWIDTH      :     integer          := 10;
        C_DCR_DWIDTH      :     integer          := 32;
        C_DCR_ILA         :     integer          := 0;  -- 0: no debug ILA, 1: include debug chipscope ILA for DCR debugging
        C_ENABLE_MMU      :     boolean          := true;
        C_MMU_STAT_REGS   :     boolean          := false;
        C_TLB_DATA_WIDTH  :     integer          := 21;
        C_TLB_TAG_WIDTH   :     integer          := 20
    );
    port
    (
        -- ADD USER PORTS BELOW THIS LINE  ------------------
        sys_clk           : in  std_logic;
        sys_reset         : in  std_logic;
        interrupt         : out std_logic;
        busy              : out std_logic;
        blocking          : out std_logic;
        -- task interface
        task_clk          : out std_logic;
        task_reset        : out std_logic;
        osif_os2task_vec  : out std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
        osif_task2os_vec  : in  std_logic_vector(0 to C_OSIF_TASK2OS_REC_WIDTH-1);
        -- burst mem interface
        burstAddr         : out std_logic_vector(0 to C_BURST_AWIDTH-1);
        burstWrData       : out std_logic_vector(0 to C_PLB_DWIDTH-1);
        burstRdData       : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
        burstWE           : out std_logic;
        burstBE           : out std_logic_vector(0 to C_PLB_DWIDTH/8-1);
        -- FIFO access signals
        o_fifo_clk          : out std_logic;
        o_fifo_reset        : out std_logic;
        -- left (read) FIFO
        o_fifo_read_en      : out std_logic;
        i_fifo_read_data    : in  std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifo_read_ready   : in  std_logic;
        -- right (write) FIFO
        o_fifo_write_en     : out std_logic;
        o_fifo_write_data   : out std_logic_vector(0 to C_FIFO_DWIDTH-1);
        i_fifo_write_ready  : in  std_logic;
        -- bus macro control
        bmEnable          : out std_logic;
        
        -- tlb interface
        i_tlb_rdata    : in  std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
        o_tlb_wdata    : out std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
        o_tlb_tag      : out std_logic_vector(C_TLB_TAG_WIDTH - 1 downto 0);
        i_tlb_match    : in  std_logic;
        o_tlb_we       : out std_logic;
        i_tlb_busy     : in  std_logic;
        o_tlb_request  : out std_logic;
        --i_tlb_wdone    : in  std_logic;
        
        -- ADD USER PORTS ABOVE THIS LINE  ------------------
        
        -- DCR Bus protocol ports
        o_dcrAck   : out std_logic;
        o_dcrDBus  : out std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrABus  : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
        i_dcrDBus  : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrRead  : in  std_logic;
        i_dcrWrite : in  std_logic;
        i_dcrICON  : in  std_logic_vector(35 downto 0);  -- chipscope
        
        
        -- PLB Bus protocol ports, do not add to or delete
        PLB_Clk          : in  std_logic;
        PLB_Rst          : in  std_logic;
        Sl_addrAck       : out std_logic;
        Sl_MBusy         : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
        Sl_MErr          : out std_logic_vector(0 to C_PLB_NUM_MASTERS-1);
        Sl_rdBTerm       : out std_logic;
        Sl_rdComp        : out std_logic;
        Sl_rdDAck        : out std_logic;
        Sl_rdDBus        : out std_logic_vector(0 to C_PLB_DWIDTH-1);
        Sl_rdWdAddr      : out std_logic_vector(0 to 3);
        Sl_rearbitrate   : out std_logic;
        Sl_SSize         : out std_logic_vector(0 to 1);
        Sl_wait          : out std_logic;
        Sl_wrBTerm       : out std_logic;
        Sl_wrComp        : out std_logic;
        Sl_wrDAck        : out std_logic;
        PLB_abort        : in  std_logic;
        PLB_ABus         : in  std_logic_vector(0 to C_PLB_AWIDTH-1);
        PLB_BE           : in  std_logic_vector(0 to C_PLB_DWIDTH/8-1);
        PLB_busLock      : in  std_logic;
        PLB_compress     : in  std_logic;
        PLB_guarded      : in  std_logic;
        PLB_lockErr      : in  std_logic;
        PLB_masterID     : in  std_logic_vector(0 to C_PLB_MID_WIDTH-1);
        PLB_MSize        : in  std_logic_vector(0 to 1);
        PLB_ordered      : in  std_logic;
        PLB_PAValid      : in  std_logic;
        PLB_pendPri      : in  std_logic_vector(0 to 1);
        PLB_pendReq      : in  std_logic;
        PLB_rdBurst      : in  std_logic;
        PLB_rdPrim       : in  std_logic;
        PLB_reqPri       : in  std_logic_vector(0 to 1);
        PLB_RNW          : in  std_logic;
        PLB_SAValid      : in  std_logic;
        PLB_size         : in  std_logic_vector(0 to 3);
        PLB_type         : in  std_logic_vector(0 to 2);
        PLB_wrBurst      : in  std_logic;
        PLB_wrDBus       : in  std_logic_vector(0 to C_PLB_DWIDTH-1);
        PLB_wrPrim       : in  std_logic;
        M_abort          : out std_logic;
        M_ABus           : out std_logic_vector(0 to C_PLB_AWIDTH-1);
        M_BE             : out std_logic_vector(0 to C_PLB_DWIDTH/8-1);
        M_busLock        : out std_logic;
        M_compress       : out std_logic;
        M_guarded        : out std_logic;
        M_lockErr        : out std_logic;
        M_MSize          : out std_logic_vector(0 to 1);
        M_ordered        : out std_logic;
        M_priority       : out std_logic_vector(0 to 1);
        M_rdBurst        : out std_logic;
        M_request        : out std_logic;
        M_RNW            : out std_logic;
        M_size           : out std_logic_vector(0 to 3);
        M_type           : out std_logic_vector(0 to 2);
        M_wrBurst        : out std_logic;
        M_wrDBus         : out std_logic_vector(0 to C_PLB_DWIDTH-1);
        PLB_MBusy        : in  std_logic;
        PLB_MErr         : in  std_logic;
        PLB_MWrBTerm     : in  std_logic;
        PLB_MWrDAck      : in  std_logic;
        PLB_MAddrAck     : in  std_logic;
        PLB_MRdBTerm     : in  std_logic;
        PLB_MRdDAck      : in  std_logic;
        PLB_MRdDBus      : in  std_logic_vector(0 to (C_PLB_DWIDTH-1));
        PLB_MRdWdAddr    : in  std_logic_vector(0 to 3);
        PLB_MRearbitrate : in  std_logic;
        PLB_MSSize       : in  std_logic_vector(0 to 1)
        -- DO NOT EDIT ABOVE THIS LINE  ---------------------
    );
    
    attribute SIGIS              : string;
    attribute SIGIS of PLB_Clk   : signal   is "Clk";
    attribute SIGIS of PLB_Rst   : signal   is "Rst";
    attribute SIGIS of interrupt : signal is "INTR_LEVEL_HIGH";

end entity plb_osif;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of plb_osif is
    
    ------------------------------------------
    -- constants : generated by wizard for instantiation - do not change
    ------------------------------------------
    -- specify address range definition identifier value, each entry with
    -- predefined identifier indicates inclusion of corresponding ipif
    -- service, following ipif mandatory service identifiers are predefined:
    --   IPIF_INTR
    --   IPIF_RST
    --   IPIF_SEST_SEAR
    --   IPIF_DMA_SG
    --   IPIF_WRFIFO_REG
    --   IPIF_WRFIFO_DATA
    --   IPIF_RDFIFO_REG
    --   IPIF_RDFIFO_DATA
    constant USER_SLAVE    : integer := USER_00;
    constant RECONOS_BURST : integer := USER_01;  -- shared memory burst transfers
    
    constant ARD_ID_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0 => USER_SLAVE,            -- user logic slave space (s/w addressable constrol/status registers)
        1 => RECONOS_BURST          -- memory burst access range
    );
    
    -- specify actual address range (defined by a pair of base address and
    -- high address) for each address space, which are byte relative.
    constant ZERO_ADDR_PAD : std_logic_vector(0 to 31) := (others => '0');
    
    constant SLAVE_BASEADDR : std_logic_vector := C_BASEADDR or X"00000000";
    constant SLAVE_HIGHADDR : std_logic_vector := C_BASEADDR or X"000000FF";
    
    constant BURST_BASEADDR : std_logic_vector := C_BASEADDR or X"00004000";
    constant BURST_HIGHADDR : std_logic_vector := C_BASEADDR or X"00007FFF";
    
    constant ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
    (
        ZERO_ADDR_PAD & SLAVE_BASEADDR,  -- user logic slave space base address
        ZERO_ADDR_PAD & SLAVE_HIGHADDR,  -- user logic slave space high address
        ZERO_ADDR_PAD & BURST_BASEADDR,  -- burst range base addresss
        ZERO_ADDR_PAD & BURST_HIGHADDR  -- burst range high addresss
    );
    
    -- specify data width for each target address range.
    constant USER_DWIDTH          : integer := 32;
    constant RECONOS_BURST_DWIDTH : integer := 64;
    
    constant ARD_DWIDTH_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0 => USER_DWIDTH,           -- user logic slave space data width
        1 => RECONOS_BURST_DWIDTH
    );
    
    -- specify desired number of chip enables for each address range,
    -- typically one ce per register and each ipif service has its
    -- predefined value.
    constant USER_NUM_SLAVE_CE    : integer := 1;
    constant RECONOS_BURST_NUM_CE : integer := 1;
    
    constant USER_NUM_CE : integer := USER_NUM_SLAVE_CE+RECONOS_BURST_NUM_CE;
    
    constant ARD_NUM_CE_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        -- 0 => pad_power2(USER_NUM_SLAVE_CE),  -- number of chip enableds for user logic slave space (one per register)
        --      1 => pad_power2(RECONOS_BURST_NUM_CE)
        0 => USER_NUM_SLAVE_CE,     -- number of chip enableds for user logic slave space (one per register)
        1 => RECONOS_BURST_NUM_CE
    );
    
    -- specify unique properties for each address range, currently
    -- only used for packet fifo data spaces.
    constant ARD_DEPENDENT_PROPS_ARRAY : DEPENDENT_PROPS_ARRAY_TYPE :=
    (
        0 => (others => 0),         -- user logic slave space dependent properties (none defined)
        1 => (others => 0)          -- reconos burst range properties (none defined)
    );
    
    -- specify determinate timing parameters to be used during read
    -- accesses for each address range, these values are used to optimize
    -- data beat timing response for burst reads from addresses sources such
    -- as ddr and sdram memory, each address space requires three integer
    -- entries for mode [0-2], latency [0-31] and wait states [0-31].
    constant ARD_DTIME_READ_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0, 0, 0,                    -- user logic slave space determinate read parameters
        0, 0, 0
    );
    
    -- specify determinate timing parameters to be used during write
    -- accesses for each address range, they not used currently, so
    -- all entries should be set to zeros.
    constant ARD_DTIME_WRITE_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0, 0, 0,                    -- user logic slave space determinate write parameters
        0, 0, 0
    );
    
    -- specify user defined device block id, which is used to uniquely
    -- identify a device within a system.
    constant DEV_BLK_ID : integer := 0;
    
    -- specify inclusion/omission of module information register to be
    -- read via the plb bus.
    constant DEV_MIR_ENABLE : integer := 0;
    
    -- specify inclusion/omission of additional logic needed to support
    -- plb fixed burst transfers and optimized cacahline transfers.
    constant DEV_BURST_ENABLE : integer := 1;
    
    -- specify the maximum number of bytes that are allowed to be
    -- transferred in a single burst operation, currently this needs
    -- to be fixed at 128.
    constant DEV_MAX_BURST_SIZE : integer := 128;
    
    -- specify size of the largest target burstable memory space (in
    -- bytes and a power of 2), this is to optimize the size of the
    -- internal burst address counters.
    constant DEV_BURST_PAGE_SIZE : integer := 1024;
    
    -- specify number of plb clock cycles are allowed before a
    -- data phase transfer timeout, this feature is useful during
    -- system integration and debug.
    constant DEV_DPHASE_TIMEOUT : integer := 64;
    
    -- specify inclusion/omission of device interrupt source
    -- controller for internal ipif generated interrupts.
    constant INCLUDE_DEV_ISC : integer := 0;
    
    -- specify inclusion/omission of device interrupt priority
    -- encoder, this is useful in aiding the user interrupt service
    -- routine to resolve the source of an interrupt within a plb
    -- device incorporating an ipif.
    constant INCLUDE_DEV_PENCODER : integer := 0;
    
    -- specify number and capture mode of interrupt events from the
    -- user logic to the ip isc located in the ipif interrupt service,
    -- user logic interrupt event capture mode [1-6]:
    --   1 = Level Pass through (non-inverted)
    --   2 = Level Pass through (invert input)
    --   3 = Registered Event (non-inverted)
    --   4 = Registered Event (inverted input)
    --   5 = Rising Edge Detect
    --   6 = Falling Edge Detect
    constant IP_INTR_MODE_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0 => 0                      -- not used
    );
    
    -- specify inclusion/omission of plb master service for user logic.
    constant IP_MASTER_PRESENT : integer := 1;
    
    -- specify dma type for each channel (currently only 2 channels
    -- supported), use following number:
    --   0 - simple dma
    --   1 - simple scatter gather
    --   2 - tx scatter gather with packet mode support
    --   3 - rx scatter gather with packet mode support
    constant DMA_CHAN_TYPE_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0 => 0                      -- not used
    );
    
    -- specify maximum width in bits for dma transfer byte counters.
    constant DMA_LENGTH_WIDTH_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0 => 0                      -- not used
    );
    
    -- specify address assigement for the length fifos used in
    -- scatter gather operation.
    constant DMA_PKT_LEN_FIFO_ADDR_ARRAY : SLV64_ARRAY_TYPE :=
    (
        0 => X"00000000_00000000"   -- not used
    );
    
    -- specify address assigement for the status fifos used in
    -- scatter gather operation.
    constant DMA_PKT_STAT_FIFO_ADDR_ARRAY : SLV64_ARRAY_TYPE :=
    (
        0 => X"00000000_00000000"   -- not used
    );
    
    -- specify interrupt coalescing value (number of interrupts to
    -- accrue before issuing interrupt to system) for each dma
    -- channel, apply to software design consideration.
    constant DMA_INTR_COALESCE_ARRAY : INTEGER_ARRAY_TYPE :=
    (
        0 => 0                      -- not used
    );
    
    -- specify allowing dma busrt mode transactions or not.
    constant DMA_ALLOW_BURST : integer := 0;
    
    -- specify maximum allowed time period (in ns) a packet may wait
    -- before transfer by the scatter gather dma, apply to software
    -- design consideration.
    constant DMA_PACKET_WAIT_UNIT_NS : integer := 1000;
    
    -- specify period of the plb clock in picoseconds, which is used
    --  by the dma/sg service for timing funtions.
    constant PLB_CLK_PERIOD_PS : integer := 10000;
    
    -- specify ipif data bus size, used for future ipif optimization,
    -- should be set equal to the plb data bus width.
    constant IPIF_DWIDTH : integer := C_PLB_DWIDTH;
    
    -- specify ipif address bus size, used for future ipif optimization,
    -- should be set equal to the plb address bus width.
    constant IPIF_AWIDTH : integer := C_PLB_AWIDTH;
    
    -- specify user logic address bus width, must be same as the target bus.
    constant USER_AWIDTH : integer := C_PLB_AWIDTH;
    
    -- specify index for user logic slave/master spaces chip enable.
    constant USER_SLAVE_CE_INDEX : integer := calc_start_ce_index(ARD_NUM_CE_ARRAY, get_id_index(ARD_ID_ARRAY, USER_SLAVE));
    
    ------------------------------------------
    -- IP Interconnect (IPIC) signal declarations  -- do not delete
    -- prefix 'i' stands for IPIF while prefix 'u' stands for user logic
    -- typically user logic will be hooked up to IPIF directly via i<sig>
    -- unless signal slicing and muxing are needed via u<sig>
    ------------------------------------------
    signal iBus2IP_Clk           : std_logic;
    signal iBus2IP_Reset         : std_logic;
    signal ZERO_IP2Bus_IntrEvent : std_logic_vector(0 to IP_INTR_MODE_ARRAY'length - 1)                                          := (others => '0');  -- work around for XST not taking (others => '0') in port mapping
    signal iIP2Bus_Data          : std_logic_vector(0 to C_PLB_DWIDTH-1)                                                         := (others => '0');
    signal iIP2Bus_WrAck         : std_logic                                                                                     := '0';
    signal iIP2Bus_RdAck         : std_logic                                                                                     := '0';
    signal iIP2Bus_Retry         : std_logic                                                                                     := '0';
    signal iIP2Bus_Error         : std_logic                                                                                     := '0';
    signal iIP2Bus_ToutSup       : std_logic                                                                                     := '0';
    signal iBus2IP_Addr          : std_logic_vector(0 to C_PLB_AWIDTH - 1);
    signal iBus2IP_Data          : std_logic_vector(0 to C_PLB_DWIDTH - 1);
    signal iBus2IP_BE            : std_logic_vector(0 to (C_PLB_DWIDTH/8) - 1);
    signal iBus2IP_Burst         : std_logic;
    signal iBus2IP_WrReq         : std_logic;
    signal iBus2IP_RdReq         : std_logic;
    signal iBus2IP_RdCE          : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
    signal iBus2IP_WrCE          : std_logic_vector(0 to calc_num_ce(ARD_NUM_CE_ARRAY)-1);
    signal iIP2Bus_Addr          : std_logic_vector(0 to IPIF_AWIDTH - 1)                                                        := (others => '0');
    signal iIP2Bus_MstBE         : std_logic_vector(0 to (IPIF_DWIDTH/8) - 1)                                                    := (others => '0');
    signal iIP2IP_Addr           : std_logic_vector(0 to IPIF_AWIDTH - 1)                                                        := (others => '0');
    signal iIP2Bus_MstWrReq      : std_logic                                                                                     := '0';
    signal iIP2Bus_MstRdReq      : std_logic                                                                                     := '0';
    signal iIP2Bus_MstBurst      : std_logic                                                                                     := '0';
    signal iIP2Bus_MstBusLock    : std_logic                                                                                     := '0';
    signal iIP2Bus_MstNum        : std_logic_vector(0 to log2(DEV_MAX_BURST_SIZE/(C_PLB_DWIDTH/8)))                              := (others => '0');
    signal iBus2IP_MstWrAck      : std_logic;
    signal iBus2IP_MstRdAck      : std_logic;
    signal iBus2IP_MstRetry      : std_logic;
    signal iBus2IP_MstError      : std_logic;
    signal iBus2IP_MstTimeOut    : std_logic;
    signal iBus2IP_MstLastAck    : std_logic;
    signal ZERO_IP2RFIFO_Data    : std_logic_vector(0 to find_id_dwidth(ARD_ID_ARRAY, ARD_DWIDTH_ARRAY, IPIF_RDFIFO_DATA, 32)-1) := (others => '0');  -- work around for XST not taking (others => '0') in port mapping
    signal uBus2IP_Data          : std_logic_vector(0 to USER_DWIDTH-1);
    signal uBus2IP_DataX         : std_logic_vector(USER_DWIDTH to C_PLB_DWIDTH-1);
    signal uBus2IP_BE            : std_logic_vector(0 to (RECONOS_BURST_DWIDTH/8)-1);
    signal uBus2IP_RdCE          : std_logic_vector(0 to USER_NUM_CE-1);
    signal uBus2IP_WrCE          : std_logic_vector(0 to USER_NUM_CE-1);
    signal uIP2Bus_Data          : std_logic_vector(0 to USER_DWIDTH-1);
    signal uIP2Bus_DataX         : std_logic_vector(USER_DWIDTH to C_PLB_DWIDTH-1);  -- extended data
    signal uIP2Bus_MstBE         : std_logic_vector(0 to USER_DWIDTH/8-1);
    
    signal task_clk_internal   : std_logic;
    signal task_reset_internal : std_logic;
    
    -- single word data input/output
    signal mem2osif_singleData : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    signal osif2mem_singleData : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
    -- addresses for master transfers
    signal mem_localAddr       : std_logic_vector(0 to USER_AWIDTH-1);
    signal mem_targetAddr      : std_logic_vector(0 to USER_AWIDTH-1);
    
    -- single word transfer requests
    signal mem_singleRdReq : std_logic;
    signal mem_singleWrReq : std_logic;
    
    -- burst transfer requests
    signal mem_burstRdReq : std_logic;
    signal mem_burstWrReq : std_logic;
    signal mem_burstLen   : std_logic_vector(0 to C_BURSTLEN_WIDTH-1);
    
    -- status outputs
    signal mem_busy   : std_logic;
    signal mem_rdDone : std_logic;
    signal mem_wrDone : std_logic;
    
    ---------
    -- local FIFO control and data lines
    ---------
    signal fifomgr_read_remove : std_logic;
    signal fifomgr_read_data   : std_logic_vector(0 to C_FIFO_DWIDTH-1);
    signal fifomgr_read_wait   : std_logic;
    signal fifomgr_write_add   : std_logic;
    signal fifomgr_write_data  : std_logic_vector(0 to C_FIFO_DWIDTH-1);
    signal fifomgr_write_wait  : std_logic;
    
    
begin
    
    ------------------------------------------
    -- instantiate the PLB IPIF, if necessary
    ------------------------------------------
    PLB_IPIF_I : entity plb_ipif_v2_01_a.plb_ipif
    generic map
    (
        C_ARD_ID_ARRAY                 => ARD_ID_ARRAY,
        C_ARD_ADDR_RANGE_ARRAY         => ARD_ADDR_RANGE_ARRAY,
        C_ARD_DWIDTH_ARRAY             => ARD_DWIDTH_ARRAY,
        C_ARD_NUM_CE_ARRAY             => ARD_NUM_CE_ARRAY,
        C_ARD_DEPENDENT_PROPS_ARRAY    => ARD_DEPENDENT_PROPS_ARRAY,
        C_ARD_DTIME_READ_ARRAY         => ARD_DTIME_READ_ARRAY,
        C_ARD_DTIME_WRITE_ARRAY        => ARD_DTIME_WRITE_ARRAY,
        C_DEV_BLK_ID                   => DEV_BLK_ID,
        C_DEV_MIR_ENABLE               => DEV_MIR_ENABLE,
        C_DEV_BURST_ENABLE             => DEV_BURST_ENABLE,
        C_DEV_MAX_BURST_SIZE           => DEV_MAX_BURST_SIZE,
        C_DEV_BURST_PAGE_SIZE          => DEV_BURST_PAGE_SIZE,
        C_DEV_DPHASE_TIMEOUT           => DEV_DPHASE_TIMEOUT,
        C_INCLUDE_DEV_ISC              => INCLUDE_DEV_ISC,
        C_INCLUDE_DEV_PENCODER         => INCLUDE_DEV_PENCODER,
        C_IP_INTR_MODE_ARRAY           => IP_INTR_MODE_ARRAY,
        C_IP_MASTER_PRESENT            => IP_MASTER_PRESENT,
        C_DMA_CHAN_TYPE_ARRAY          => DMA_CHAN_TYPE_ARRAY,
        C_DMA_LENGTH_WIDTH_ARRAY       => DMA_LENGTH_WIDTH_ARRAY,
        C_DMA_PKT_LEN_FIFO_ADDR_ARRAY  => DMA_PKT_LEN_FIFO_ADDR_ARRAY,
        C_DMA_PKT_STAT_FIFO_ADDR_ARRAY => DMA_PKT_STAT_FIFO_ADDR_ARRAY,
        C_DMA_INTR_COALESCE_ARRAY      => DMA_INTR_COALESCE_ARRAY,
        C_DMA_ALLOW_BURST              => DMA_ALLOW_BURST,
        C_DMA_PACKET_WAIT_UNIT_NS      => DMA_PACKET_WAIT_UNIT_NS,
        C_PLB_MID_WIDTH                => C_PLB_MID_WIDTH,
        C_PLB_NUM_MASTERS              => C_PLB_NUM_MASTERS,
        C_PLB_AWIDTH                   => C_PLB_AWIDTH,
        C_PLB_DWIDTH                   => C_PLB_DWIDTH,
        C_PLB_CLK_PERIOD_PS            => PLB_CLK_PERIOD_PS,
        C_IPIF_DWIDTH                  => IPIF_DWIDTH,
        C_IPIF_AWIDTH                  => IPIF_AWIDTH,
        C_FAMILY                       => C_FAMILY
    )
    port map
    (
        PLB_clk                        => PLB_Clk,
        Reset                          => PLB_Rst,
        Freeze                         => '0',
        IP2INTC_Irpt                   => open,
        PLB_ABus                       => PLB_ABus,
        PLB_PAValid                    => PLB_PAValid,
        PLB_SAValid                    => PLB_SAValid,
        PLB_rdPrim                     => PLB_rdPrim,
        PLB_wrPrim                     => PLB_wrPrim,
        PLB_masterID                   => PLB_masterID,
        PLB_abort                      => PLB_abort,
        PLB_busLock                    => PLB_busLock,
        PLB_RNW                        => PLB_RNW,
        PLB_BE                         => PLB_BE,
        PLB_MSize                      => PLB_MSize,
        PLB_size                       => PLB_size,
        PLB_type                       => PLB_type,
        PLB_compress                   => PLB_compress,
        PLB_guarded                    => PLB_guarded,
        PLB_ordered                    => PLB_ordered,
        PLB_lockErr                    => PLB_lockErr,
        PLB_wrDBus                     => PLB_wrDBus,
        PLB_wrBurst                    => PLB_wrBurst,
        PLB_rdBurst                    => PLB_rdBurst,
        PLB_pendReq                    => PLB_pendReq,
        PLB_pendPri                    => PLB_pendPri,
        PLB_reqPri                     => PLB_reqPri,
        Sl_addrAck                     => Sl_addrAck,
        Sl_SSize                       => Sl_SSize,
        Sl_wait                        => Sl_wait,
        Sl_rearbitrate                 => Sl_rearbitrate,
        Sl_wrDAck                      => Sl_wrDAck,
        Sl_wrComp                      => Sl_wrComp,
        Sl_wrBTerm                     => Sl_wrBTerm,
        Sl_rdDBus                      => Sl_rdDBus,
        Sl_rdWdAddr                    => Sl_rdWdAddr,
        Sl_rdDAck                      => Sl_rdDAck,
        Sl_rdComp                      => Sl_rdComp,
        Sl_rdBTerm                     => Sl_rdBTerm,
        Sl_MBusy                       => Sl_MBusy,
        Sl_MErr                        => Sl_MErr,
        PLB_MAddrAck                   => PLB_MAddrAck,
        PLB_MSSize                     => PLB_MSSize,
        PLB_MRearbitrate               => PLB_MRearbitrate,
        PLB_MBusy                      => PLB_MBusy,
        PLB_MErr                       => PLB_MErr,
        PLB_MWrDAck                    => PLB_MWrDAck,
        PLB_MRdDBus                    => PLB_MRdDBus,
        PLB_MRdWdAddr                  => PLB_MRdWdAddr,
        PLB_MRdDAck                    => PLB_MRdDAck,
        PLB_MRdBTerm                   => PLB_MRdBTerm,
        PLB_MWrBTerm                   => PLB_MWrBTerm,
        M_request                      => M_request,
        M_priority                     => M_priority,
        M_busLock                      => M_busLock,
        M_RNW                          => M_RNW,
        M_BE                           => M_BE,
        M_MSize                        => M_MSize,
        M_size                         => M_size,
        M_type                         => M_type,
        M_compress                     => M_compress,
        M_guarded                      => M_guarded,
        M_ordered                      => M_ordered,
        M_lockErr                      => M_lockErr,
        M_abort                        => M_abort,
        M_ABus                         => M_ABus,
        M_wrDBus                       => M_wrDBus,
        M_wrBurst                      => M_wrBurst,
        M_rdBurst                      => M_rdBurst,
        IP2Bus_Clk                     => '0',
        Bus2IP_Clk                     => iBus2IP_Clk,
        Bus2IP_Reset                   => iBus2IP_Reset,
        Bus2IP_Freeze                  => open,
        IP2Bus_IntrEvent               => ZERO_IP2Bus_IntrEvent,
        IP2Bus_Data                    => iIP2Bus_Data,
        IP2Bus_WrAck                   => iIP2Bus_WrAck,
        IP2Bus_RdAck                   => iIP2Bus_RdAck,
        IP2Bus_Retry                   => iIP2Bus_Retry,
        IP2Bus_Error                   => iIP2Bus_Error,
        IP2Bus_ToutSup                 => iIP2Bus_ToutSup,
        IP2Bus_PostedWrInh             => '0',
        Bus2IP_Addr                    => iBus2IP_Addr,
        Bus2IP_Data                    => iBus2IP_Data,
        Bus2IP_RNW                     => open,
        Bus2IP_BE                      => iBus2IP_BE,
        Bus2IP_Burst                   => iBus2IP_Burst,
        Bus2IP_WrReq                   => iBus2IP_WrReq,
        Bus2IP_RdReq                   => iBus2IP_RdReq,
        Bus2IP_CS                      => open,
        Bus2IP_CE                      => open,
        Bus2IP_RdCE                    => iBus2IP_RdCE,
        Bus2IP_WrCE                    => iBus2IP_WrCE,
        IP2DMA_RxLength_Empty          => '0',
        IP2DMA_RxStatus_Empty          => '0',
        IP2DMA_TxLength_Full           => '0',
        IP2DMA_TxStatus_Empty          => '0',
        IP2Bus_Addr                    => iIP2Bus_Addr,
        IP2Bus_MstBE                   => iIP2Bus_MstBE,
        IP2IP_Addr                     => iIP2IP_Addr,
        IP2Bus_MstWrReq                => iIP2Bus_MstWrReq,
        IP2Bus_MstRdReq                => iIP2Bus_MstRdReq,
        IP2Bus_MstBurst                => iIP2Bus_MstBurst,
        IP2Bus_MstBusLock              => iIP2Bus_MstBusLock,
        IP2Bus_MstNum                  => iIP2Bus_MstNum,
        Bus2IP_MstWrAck                => iBus2IP_MstWrAck,
        Bus2IP_MstRdAck                => iBus2IP_MstRdAck,
        Bus2IP_MstRetry                => iBus2IP_MstRetry,
        Bus2IP_MstError                => iBus2IP_MstError,
        Bus2IP_MstTimeOut              => iBus2IP_MstTimeOut,
        Bus2IP_MstLastAck              => iBus2IP_MstLastAck,
        Bus2IP_IPMstTrans              => open,
        IP2RFIFO_WrReq                 => '0',
        IP2RFIFO_Data                  => ZERO_IP2RFIFO_Data,
        IP2RFIFO_WrMark                => '0',
        IP2RFIFO_WrRelease             => '0',
        IP2RFIFO_WrRestore             => '0',
        RFIFO2IP_WrAck                 => open,
        RFIFO2IP_AlmostFull            => open,
        RFIFO2IP_Full                  => open,
        RFIFO2IP_Vacancy               => open,
        IP2WFIFO_RdReq                 => '0',
        IP2WFIFO_RdMark                => '0',
        IP2WFIFO_RdRelease             => '0',
        IP2WFIFO_RdRestore             => '0',
        WFIFO2IP_Data                  => open,
        WFIFO2IP_RdAck                 => open,
        WFIFO2IP_AlmostEmpty           => open,
        WFIFO2IP_Empty                 => open,
        WFIFO2IP_Occupancy             => open,
        IP2Bus_DMA_Req                 => '0',
        Bus2IP_DMA_Ack                 => open
    );
    
    
    ------------------------------------------
    -- instantiate the OSIF core
    ------------------------------------------
    USER_LOGIC_I : entity osif_core_v2_03_a.osif_core
    generic map
    (
        -- MAP USER GENERICS BELOW THIS LINE  ---------------
        C_BURST_AWIDTH   => C_BURST_AWIDTH,
        C_FIFO_DWIDTH    => C_FIFO_DWIDTH,
        C_BURSTLEN_WIDTH => C_BURSTLEN_WIDTH,
        
        -- MAP USER GENERICS ABOVE THIS LINE  ---------------
        
        C_AWIDTH     => USER_AWIDTH,
        C_DWIDTH     => USER_DWIDTH,
        C_PLB_DWIDTH => C_PLB_DWIDTH,
        C_NUM_CE     => USER_NUM_CE,
        
        C_DCR_BASEADDR  => C_DCR_BASEADDR,
        C_DCR_HIGHADDR  => C_DCR_HIGHADDR,
        C_DCR_AWIDTH    => C_DCR_AWIDTH,
        C_DCR_DWIDTH    => C_DCR_DWIDTH,
        C_ENABLE_MMU    => C_ENABLE_MMU,
        C_MMU_STAT_REGS => C_MMU_STAT_REGS,
        C_DCR_ILA       => C_DCR_ILA
        
    )
    port map
    (
        -- MAP USER PORTS BELOW THIS LINE  ------------------
        interrupt          => interrupt,
        busy               => busy,
        blocking           => blocking,
        -- task interface
        task_clk           => task_clk_internal,
        task_reset         => task_reset_internal,
        osif_os2task_vec   => osif_os2task_vec,
        osif_task2os_vec   => osif_task2os_vec,
        -- FIFO manager access signals
        o_fifomgr_read_remove => fifomgr_read_remove,
        i_fifomgr_read_data   => fifomgr_read_data,
        i_fifomgr_read_wait   => fifomgr_read_wait,
        o_fifomgr_write_add   => fifomgr_write_add,
        o_fifomgr_write_data  => fifomgr_write_data,
        i_fifomgr_write_wait  => fifomgr_write_wait,
        -- memory access signals
        o_mem_singleData   => osif2mem_singleData,
        i_mem_singleData   => mem2osif_singleData,
        o_mem_localAddr    => mem_localAddr,
        o_mem_targetAddr   => mem_targetAddr,
        o_mem_singleRdReq  => mem_singleRdReq,
        o_mem_singleWrReq  => mem_singleWrReq,
        o_mem_burstRdReq   => mem_burstRdReq,
        o_mem_burstWrReq   => mem_burstWrReq,
        o_mem_burstLen     => mem_burstLen,
        i_mem_busy         => mem_busy,
        i_mem_rdDone       => mem_rdDone,
        i_mem_wrDone       => mem_wrDone,
        -- bus macro control
        o_bm_enable        => bmEnable,
        
        -- tlb interface
        i_tlb_rdata    => i_tlb_rdata,
        o_tlb_wdata    => o_tlb_wdata,
        o_tlb_tag      => o_tlb_tag,
        i_tlb_match    => i_tlb_match,
        o_tlb_we       => o_tlb_we,
        i_tlb_busy     => i_tlb_busy,
        o_tlb_request  => o_tlb_request,
        
        -- MAP USER PORTS ABOVE THIS LINE  ------------------
        
        sys_clk   => sys_clk,
        sys_reset => sys_reset,
        
        -- DCR Bus protocol ports
        o_dcrAck   => o_dcrAck,
        o_dcrDBus  => o_dcrDBus,
        i_dcrABus  => i_dcrABus,
        i_dcrDBus  => i_dcrDBus,
        i_dcrRead  => i_dcrRead,
        i_dcrWrite => i_dcrWrite,
        i_dcrICON  => i_dcrICON
        
    );
    
    ---------------------------------------
    -- memory bus controller core
    --
    -- PLBv34
    ---------------------------------------
    mem_plb34_i : entity plb_osif_v2_03_a.mem_plb34
    generic map
    (
        C_SLAVE_BASEADDR => SLAVE_BASEADDR,
        -- Bus protocol parameters
        C_AWIDTH         => USER_AWIDTH,
        C_DWIDTH         => USER_DWIDTH,
        C_PLB_AWIDTH     => C_PLB_AWIDTH,
        C_PLB_DWIDTH     => C_PLB_DWIDTH,
        C_NUM_CE         => USER_NUM_CE,
        C_BURST_AWIDTH   => C_BURST_AWIDTH,
        C_BURST_BASEADDR => BURST_BASEADDR
    )
    port map
    (
        clk              => task_clk_internal,
        reset            => task_reset_internal,
        
        -- data interface           ---------------------------
        
        -- burst mem interface
        o_burstAddr => burstAddr,
        o_burstData => burstWrData,
        i_burstData => burstRdData,
        o_burstWE   => burstWE,
        o_burstBE   => burstBE,
        
        -- single word data input/output
        i_singleData => osif2mem_singleData,
        o_singleData => mem2osif_singleData,
        
        -- control interface        ------------------------
        
        -- addresses for master transfers
        i_localAddr  => mem_localAddr,
        i_targetAddr => mem_targetAddr,
        
        -- single word transfer requests
        i_singleRdReq  => mem_singleRdReq,
        i_singleWrReq  => mem_singleWrReq,
        
        -- burst transfer requests
        i_burstRdReq  => mem_burstRdReq,
        i_burstWrReq  => mem_burstWrReq,
        i_burstLen    => mem_burstLen,
        
        -- status outputs
        o_busy        => mem_busy,
        o_rdDone      => mem_rdDone,
        o_wrDone      => mem_wrDone,
        
        
        -- PLBv34 bus interface -----------------------------------------
        
        -- Bus protocol ports, do not add to or delete
        Bus2IP_Clk        => iBus2IP_Clk,
        Bus2IP_Reset      => iBus2IP_Reset,
        Bus2IP_Addr       => iBus2IP_Addr,
        Bus2IP_Data       => uBus2IP_Data,
        Bus2IP_DataX      => uBus2IP_DataX,
        Bus2IP_BE         => uBus2IP_BE,
        Bus2IP_Burst      => iBus2IP_Burst,
        Bus2IP_RdCE       => uBus2IP_RdCE,
        Bus2IP_WrCE       => uBus2IP_WrCE,
        Bus2IP_RdReq      => iBus2IP_RdReq,
        Bus2IP_WrReq      => iBus2IP_WrReq,
        IP2Bus_Data       => uIP2Bus_Data,
        IP2Bus_DataX      => uIP2Bus_DataX,
        IP2Bus_Retry      => iIP2Bus_Retry,
        IP2Bus_Error      => iIP2Bus_Error,
        IP2Bus_ToutSup    => iIP2Bus_ToutSup,
        IP2Bus_RdAck      => iIP2Bus_RdAck,
        IP2Bus_WrAck      => iIP2Bus_WrAck,
        Bus2IP_MstError   => iBus2IP_MstError,
        Bus2IP_MstLastAck => iBus2IP_MstLastAck,
        Bus2IP_MstRdAck   => iBus2IP_MstRdAck,
        Bus2IP_MstWrAck   => iBus2IP_MstWrAck,
        Bus2IP_MstRetry   => iBus2IP_MstRetry,
        Bus2IP_MstTimeOut => iBus2IP_MstTimeOut,
        IP2Bus_Addr       => iIP2Bus_Addr,
        IP2Bus_MstBE      => iIP2Bus_MstBE,
        IP2Bus_MstBurst   => iIP2Bus_MstBurst,
        IP2Bus_MstBusLock => iIP2Bus_MstBusLock,
        IP2Bus_MstNum     => iIP2Bus_MstNum,
        IP2Bus_MstRdReq   => iIP2Bus_MstRdReq,
        IP2Bus_MstWrReq   => iIP2Bus_MstWrReq,
        IP2IP_Addr        => iIP2IP_Addr
    );
    
    
    -----------------------------------------------------------------------
    -- fifo_mgr_inst: FIFO manager instantiation
    --
    -- The FIFO manager handles incoming push/pop requests to the two
    -- hardware FIFOs attached to the OSIF. It arbitrates between
    -- local hardware-thread-initiated requests and indirect bus accesses
    -- by other hardware threads.
    -----------------------------------------------------------------------
    
    fifo_mgr_inst : entity plb_osif_v2_03_a.fifo_mgr
    generic map (
        C_FIFO_DWIDTH       => C_FIFO_DWIDTH
    )
    port map (
        clk                 => sys_clk,
        reset               => sys_reset,  -- we don't want a thread reset command to flush
        -- the FIFOs, therefore no thread_reset_i!
        -- local FIFO access signals
        i_local_read_remove => fifomgr_read_remove,
        o_local_read_data   => fifomgr_read_data,
        o_local_read_wait   => fifomgr_read_wait,
        i_local_write_add   => fifomgr_write_add,
        i_local_write_data  => fifomgr_write_data,
        o_local_write_wait  => fifomgr_write_wait,
        -- "real" FIFO access signals
        o_fifo_read_en      => o_fifo_read_en,
        i_fifo_read_data    => i_fifo_read_data,
        i_fifo_read_ready   => i_fifo_read_ready,
        o_fifo_write_en     => o_fifo_write_en,
        o_fifo_write_data   => o_fifo_write_data,
        i_fifo_write_ready  => i_fifo_write_ready
        -- TODO: signal to communicate with the bus_slave_regs module
    );
    
    --------
    -- set FIFO clock/reset
    --------
    o_fifo_clk <= sys_clk;
    o_fifo_reset <= sys_reset;
    
    ---------
    -- set task clock/reset
    ---------
    task_clk <= task_clk_internal;
    task_reset <= task_reset_internal;
    
    ------------------------------------------
    -- hooking up signal slicing
    ------------------------------------------
    uBus2IP_Data                     <= iBus2IP_Data(0 to USER_DWIDTH-1);
    uBus2IP_DataX                    <= iBus2IP_Data(USER_DWIDTH to C_PLB_DWIDTH-1);
    uBus2IP_BE                       <= iBus2IP_BE; --(0 to USER_DWIDTH/8-1);
    -- uBus2IP_RdCE(0 to USER_NUM_SLAVE_CE-1) <= iBus2IP_RdCE(USER_SLAVE_CE_INDEX to USER_SLAVE_CE_INDEX+USER_NUM_SLAVE_CE-1);
    -- uBus2IP_WrCE(0 to USER_NUM_SLAVE_CE-1) <= iBus2IP_WrCE(USER_SLAVE_CE_INDEX to USER_SLAVE_CE_INDEX+USER_NUM_SLAVE_CE-1);
    uBus2IP_RdCE(0 to USER_NUM_CE-1) <= iBus2IP_RdCE(USER_SLAVE_CE_INDEX to USER_SLAVE_CE_INDEX+USER_NUM_CE-1);
    uBus2IP_WrCE(0 to USER_NUM_CE-1) <= iBus2IP_WrCE(USER_SLAVE_CE_INDEX to USER_SLAVE_CE_INDEX+USER_NUM_CE-1);
    
    iIP2Bus_Data(0 to USER_DWIDTH-1)            <= uIP2Bus_Data;
    iIP2Bus_Data(USER_DWIDTH to C_PLB_DWIDTH-1) <= uIP2Bus_DataX;

end IMP;
