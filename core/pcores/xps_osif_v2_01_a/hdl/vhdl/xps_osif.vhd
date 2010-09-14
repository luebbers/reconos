------------------------------------------------------------------------------
--
-- \file xps_osif.vhd
--
-- Wrapper to connect OSIF to PLBv46
--
-- Mostly generated using Xilinx tools.
--
-- \author     Enno Luebbers <luebbers@reconos.de>
-- \date       11.08.2009
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
-- Original Xilinx header follows:
--
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.            **
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
-- Filename:          xps_osif.vhd
-- Version:           2.01.a
-- Description:       Top level design, instantiates library components and user logic.
-- Date:              Wed May 27 14:11:08 2009 (by Create and Import Peripheral Wizard)
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

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;
use proc_common_v2_00_a.ipif_pkg.all;

library plbv46_master_burst_v1_00_a;
use plbv46_master_burst_v1_00_a.plbv46_master_burst;

library osif_core_v2_01_a;
use osif_core_v2_01_a.all;

library xps_osif_v2_01_a;
use xps_osif_v2_01_a.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;
------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_BASEADDR                   -- PLBv46 slave: base address
--   C_HIGHADDR                   -- PLBv46 slave: high address
--   C_SPLB_AWIDTH                -- PLBv46 slave: address bus width
--   C_SPLB_DWIDTH                -- PLBv46 slave: data bus width
--   C_SPLB_NUM_MASTERS           -- PLBv46 slave: Number of masters
--   C_SPLB_MID_WIDTH             -- PLBv46 slave: master ID bus width
--   C_SPLB_NATIVE_DWIDTH         -- PLBv46 slave: internal native data bus width
--   C_SPLB_P2P                   -- PLBv46 slave: point to point interconnect scheme
--   C_SPLB_SUPPORT_BURSTS        -- PLBv46 slave: support bursts
--   C_SPLB_SMALLEST_MASTER       -- PLBv46 slave: width of the smallest master
--   C_SPLB_CLK_PERIOD_PS         -- PLBv46 slave: bus clock in picoseconds
--   C_INCLUDE_DPHASE_TIMER       -- PLBv46 slave: Data Phase Timer configuration; 0 = exclude timer, 1 = include timer
--   C_FAMILY                     -- Xilinx FPGA family
--   C_MPLB_AWIDTH                -- PLBv46 master: address bus width
--   C_MPLB_DWIDTH                -- PLBv46 master: data bus width
--   C_MPLB_NATIVE_DWIDTH         -- PLBv46 master: internal native data width
--   C_MPLB_P2P                   -- PLBv46 master: point to point interconnect scheme
--   C_MPLB_SMALLEST_SLAVE        -- PLBv46 master: width of the smallest slave
--   C_MPLB_CLK_PERIOD_PS         -- PLBv46 master: bus clock in picoseconds
--   C_MEM0_BASEADDR              -- User memory space 0 base address
--   C_MEM0_HIGHADDR              -- User memory space 0 high address
--   C_MEM1_BASEADDR              -- User memory space 1 base address
--   C_MEM1_HIGHADDR              -- User memory space 1 high address
--
-- Definition of Ports:
--   SPLB_Clk                     -- PLB main bus clock
--   SPLB_Rst                     -- PLB main bus reset
--   PLB_ABus                     -- PLB address bus
--   PLB_UABus                    -- PLB upper address bus
--   PLB_PAValid                  -- PLB primary address valid indicator
--   PLB_SAValid                  -- PLB secondary address valid indicator
--   PLB_rdPrim                   -- PLB secondary to primary read request indicator
--   PLB_wrPrim                   -- PLB secondary to primary write request indicator
--   PLB_masterID                 -- PLB current master identifier
--   PLB_abort                    -- PLB abort request indicator
--   PLB_busLock                  -- PLB bus lock
--   PLB_RNW                      -- PLB read/not write
--   PLB_BE                       -- PLB byte enables
--   PLB_MSize                    -- PLB master data bus size
--   PLB_size                     -- PLB transfer size
--   PLB_type                     -- PLB transfer type
--   PLB_lockErr                  -- PLB lock error indicator
--   PLB_wrDBus                   -- PLB write data bus
--   PLB_wrBurst                  -- PLB burst write transfer indicator
--   PLB_rdBurst                  -- PLB burst read transfer indicator
--   PLB_wrPendReq                -- PLB write pending bus request indicator
--   PLB_rdPendReq                -- PLB read pending bus request indicator
--   PLB_wrPendPri                -- PLB write pending request priority
--   PLB_rdPendPri                -- PLB read pending request priority
--   PLB_reqPri                   -- PLB current request priority
--   PLB_TAttribute               -- PLB transfer attribute
--   Sl_addrAck                   -- Slave address acknowledge
--   Sl_SSize                     -- Slave data bus size
--   Sl_wait                      -- Slave wait indicator
--   Sl_rearbitrate               -- Slave re-arbitrate bus indicator
--   Sl_wrDAck                    -- Slave write data acknowledge
--   Sl_wrComp                    -- Slave write transfer complete indicator
--   Sl_wrBTerm                   -- Slave terminate write burst transfer
--   Sl_rdDBus                    -- Slave read data bus
--   Sl_rdWdAddr                  -- Slave read word address
--   Sl_rdDAck                    -- Slave read data acknowledge
--   Sl_rdComp                    -- Slave read transfer complete indicator
--   Sl_rdBTerm                   -- Slave terminate read burst transfer
--   Sl_MBusy                     -- Slave busy indicator
--   Sl_MWrErr                    -- Slave write error indicator
--   Sl_MRdErr                    -- Slave read error indicator
--   Sl_MIRQ                      -- Slave interrupt indicator
--   MPLB_Clk                     -- PLB main bus Clock
--   MPLB_Rst                     -- PLB main bus Reset
--   MD_error                     -- Master detected error status output
--   M_request                    -- Master request
--   M_priority                   -- Master request priority
--   M_busLock                    -- Master buslock
--   M_RNW                        -- Master read/nor write
--   M_BE                         -- Master byte enables
--   M_MSize                      -- Master data bus size
--   M_size                       -- Master transfer size
--   M_type                       -- Master transfer type
--   M_TAttribute                 -- Master transfer attribute
--   M_lockErr                    -- Master lock error indicator
--   M_abort                      -- Master abort bus request indicator
--   M_UABus                      -- Master upper address bus
--   M_ABus                       -- Master address bus
--   M_wrDBus                     -- Master write data bus
--   M_wrBurst                    -- Master burst write transfer indicator
--   M_rdBurst                    -- Master burst read transfer indicator
--   PLB_MAddrAck                 -- PLB reply to master for address acknowledge
--   PLB_MSSize                   -- PLB reply to master for slave data bus size
--   PLB_MRearbitrate             -- PLB reply to master for bus re-arbitrate indicator
--   PLB_MTimeout                 -- PLB reply to master for bus time out indicator
--   PLB_MBusy                    -- PLB reply to master for slave busy indicator
--   PLB_MRdErr                   -- PLB reply to master for slave read error indicator
--   PLB_MWrErr                   -- PLB reply to master for slave write error indicator
--   PLB_MIRQ                     -- PLB reply to master for slave interrupt indicator
--   PLB_MRdDBus                  -- PLB reply to master for read data bus
--   PLB_MRdWdAddr                -- PLB reply to master for read word address
--   PLB_MRdDAck                  -- PLB reply to master for read data acknowledge
--   PLB_MRdBTerm                 -- PLB reply to master for terminate read burst indicator
--   PLB_MWrDAck                  -- PLB reply to master for write data acknowledge
--   PLB_MWrBTerm                 -- PLB reply to master for terminate write burst indicator
------------------------------------------------------------------------------

entity xps_osif is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------
    C_BURST_AWIDTH    :     integer          := 13;  -- 1024 x 64 Bit = 8192 Bytes = 2^13 Bytes
    C_FIFO_DWIDTH     :     integer          := 32;
    C_DCR_BASEADDR    :     std_logic_vector := "1111111111";
    C_DCR_HIGHADDR    :     std_logic_vector := "0000000000";
    C_DCR_AWIDTH      :     integer          := 10;
    C_DCR_DWIDTH      :     integer          := 32;
    C_DCR_ILA         :     integer          := 0; 
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
--    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
--    C_HIGHADDR                     : std_logic_vector     := X"00000000";
--    C_SPLB_AWIDTH                  : integer              := 32;
--    C_SPLB_DWIDTH                  : integer              := 128;
--    C_SPLB_NUM_MASTERS             : integer              := 8;
--    C_SPLB_MID_WIDTH               : integer              := 3;
--    C_SPLB_NATIVE_DWIDTH           : integer              := 32;
--    C_SPLB_P2P                     : integer              := 0;
--    C_SPLB_SUPPORT_BURSTS          : integer              := 0;
--    C_SPLB_SMALLEST_MASTER         : integer              := 32;
--    C_SPLB_CLK_PERIOD_PS           : integer              := 10000;
--    C_INCLUDE_DPHASE_TIMER         : integer              := 0;
    C_FAMILY                       : string               := "virtex5";
    C_MPLB_AWIDTH                  : integer              := 32;
    C_MPLB_DWIDTH                  : integer              := 128;
    C_MPLB_NATIVE_DWIDTH           : integer              := 64;
    C_MPLB_P2P                     : integer              := 0;
    C_MPLB_SMALLEST_SLAVE          : integer              := 32;
    C_MPLB_CLK_PERIOD_PS           : integer              := 10000
--    C_MEM0_BASEADDR                : std_logic_vector     := X"FFFFFFFF";
--    C_MEM0_HIGHADDR                : std_logic_vector     := X"00000000";
--    C_MEM1_BASEADDR                : std_logic_vector     := X"FFFFFFFF";
--    C_MEM1_HIGHADDR                : std_logic_vector     := X"00000000"
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
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
    burstWrData       : out std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
    burstRdData       : in  std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
    burstWE           : out std_logic;
    burstBE           : out std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
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
    -- ADD USER PORTS ABOVE THIS LINE  ------------------

    -- DCR Bus protocol ports
    o_dcrAck   : out std_logic;
    o_dcrDBus  : out std_logic_vector(0 to C_DCR_DWIDTH-1);
    i_dcrABus  : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
    i_dcrDBus  : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
    i_dcrRead  : in  std_logic;
    i_dcrWrite : in  std_logic;
    i_dcrICON  : in  std_logic_vector(35 downto 0);  -- chipscope

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
--    sys_clk                        : in  std_logic;
--    sys_reset                      : in  std_logic;
--    SPLB_Clk                       : in  std_logic;
--    SPLB_Rst                       : in  std_logic;
--    PLB_ABus                       : in  std_logic_vector(0 to 31);
--    PLB_UABus                      : in  std_logic_vector(0 to 31);
--    PLB_PAValid                    : in  std_logic;
--    PLB_SAValid                    : in  std_logic;
--    PLB_rdPrim                     : in  std_logic;
--    PLB_wrPrim                     : in  std_logic;
--    PLB_masterID                   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
--    PLB_abort                      : in  std_logic;
--    PLB_busLock                    : in  std_logic;
--    PLB_RNW                        : in  std_logic;
--    PLB_BE                         : in  std_logic_vector(0 to C_SPLB_DWIDTH/8-1);
--    PLB_MSize                      : in  std_logic_vector(0 to 1);
--    PLB_size                       : in  std_logic_vector(0 to 3);
--    PLB_type                       : in  std_logic_vector(0 to 2);
--    PLB_lockErr                    : in  std_logic;
--    PLB_wrDBus                     : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
--    PLB_wrBurst                    : in  std_logic;
--    PLB_rdBurst                    : in  std_logic;
--    PLB_wrPendReq                  : in  std_logic;
--    PLB_rdPendReq                  : in  std_logic;
--    PLB_wrPendPri                  : in  std_logic_vector(0 to 1);
--    PLB_rdPendPri                  : in  std_logic_vector(0 to 1);
--    PLB_reqPri                     : in  std_logic_vector(0 to 1);
--    PLB_TAttribute                 : in  std_logic_vector(0 to 15);
--    Sl_addrAck                     : out std_logic;
--    Sl_SSize                       : out std_logic_vector(0 to 1);
--    Sl_wait                        : out std_logic;
--    Sl_rearbitrate                 : out std_logic;
--    Sl_wrDAck                      : out std_logic;
--    Sl_wrComp                      : out std_logic;
--    Sl_wrBTerm                     : out std_logic;
--    Sl_rdDBus                      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
--    Sl_rdWdAddr                    : out std_logic_vector(0 to 3);
--    Sl_rdDAck                      : out std_logic;
--    Sl_rdComp                      : out std_logic;
--    Sl_rdBTerm                     : out std_logic;
--    Sl_MBusy                       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
--    Sl_MWrErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
--    Sl_MRdErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
--    Sl_MIRQ                        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    MPLB_Clk                       : in  std_logic;
    MPLB_Rst                       : in  std_logic;
    MD_error                       : out std_logic;
    M_request                      : out std_logic;
    M_priority                     : out std_logic_vector(0 to 1);
    M_busLock                      : out std_logic;
    M_RNW                          : out std_logic;
    M_BE                           : out std_logic_vector(0 to C_MPLB_DWIDTH/8-1);
    M_MSize                        : out std_logic_vector(0 to 1);
    M_size                         : out std_logic_vector(0 to 3);
    M_type                         : out std_logic_vector(0 to 2);
    M_TAttribute                   : out std_logic_vector(0 to 15);
    M_lockErr                      : out std_logic;
    M_abort                        : out std_logic;
    M_UABus                        : out std_logic_vector(0 to 31);
    M_ABus                         : out std_logic_vector(0 to 31);
    M_wrDBus                       : out std_logic_vector(0 to C_MPLB_DWIDTH-1);
    M_wrBurst                      : out std_logic;
    M_rdBurst                      : out std_logic;
    PLB_MAddrAck                   : in  std_logic;
    PLB_MSSize                     : in  std_logic_vector(0 to 1);
    PLB_MRearbitrate               : in  std_logic;
    PLB_MTimeout                   : in  std_logic;
    PLB_MBusy                      : in  std_logic;
    PLB_MRdErr                     : in  std_logic;
    PLB_MWrErr                     : in  std_logic;
    PLB_MIRQ                       : in  std_logic;
    PLB_MRdDBus                    : in  std_logic_vector(0 to (C_MPLB_DWIDTH-1));
    PLB_MRdWdAddr                  : in  std_logic_vector(0 to 3);
    PLB_MRdDAck                    : in  std_logic;
    PLB_MRdBTerm                   : in  std_logic;
    PLB_MWrDAck                    : in  std_logic;
    PLB_MWrBTerm                   : in  std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute SIGIS : string;
--  attribute SIGIS of SPLB_Clk      : signal is "CLK";
  attribute SIGIS of MPLB_Clk      : signal is "CLK";
--  attribute SIGIS of SPLB_Rst      : signal is "RST";
  attribute SIGIS of MPLB_Rst      : signal is "RST";

end entity xps_osif;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of xps_osif is

  ------------------------------------------
  -- Array of base/high address pairs for each address range
  ------------------------------------------
  --constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');
  --constant USER_MST_BASEADDR              : std_logic_vector     := C_BASEADDR or X"00000000";
  --constant USER_MST_HIGHADDR              : std_logic_vector     := C_BASEADDR or X"000000FF";
  
  --USER_LOGIC needs this parameter
  --constant BURST_BASEADDR : std_logic_vector := C_BASEADDR or X"00004000";
  --constant BURST_HIGHADDR : std_logic_vector := C_BASEADDR or X"00007FFF";
     
  --constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     := 
    --(
      --ZERO_ADDR_PAD & USER_MST_BASEADDR,  -- user logic master space base address
      --ZERO_ADDR_PAD & USER_MST_HIGHADDR,  -- user logic master space high address
      --ZERO_ADDR_PAD & BURST_BASEADDR,    -- user logic memory space 0 base address
      --ZERO_ADDR_PAD & BURST_HIGHADDR    -- user logic memory space 0 high address
      --ZERO_ADDR_PAD & C_MEM1_BASEADDR,    -- user logic memory space 1 base address
      --ZERO_ADDR_PAD & C_MEM1_HIGHADDR     -- user logic memory space 1 high address
   -- );

  ------------------------------------------
  -- Array of desired number of chip enables for each address range
  ------------------------------------------
--  constant USER_MST_NUM_REG               : integer              := 1;
--  constant USER_NUM_REG                   : integer              := USER_MST_NUM_REG;
--  constant USER_NUM_MEM                   : integer              := 1;

--  constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
--    (
      --0  => pad_power2(USER_MST_NUM_REG), -- number of ce for user logic master space
--		0 => 1
      --1  => 1,                            -- number of ce for user logic memory space 0 (always 1 chip enable)
      --2  => 1                             -- number of ce for user logic memory space 1 (always 1 chip enable)
--    );

  ------------------------------------------
  -- Ratio of bus clock to core clock (for use in dual clock systems)
  -- 1 = ratio is 1:1
  -- 2 = ratio is 2:1
  ------------------------------------------
  constant IPIF_BUS2CORE_CLK_RATIO        : integer              := 1;

  ------------------------------------------
  -- Width of the slave data bus (32 only)
  ------------------------------------------
  --constant USER_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  --constant IPIF_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Width of the master data bus (32, 64, or 128)
  ------------------------------------------
  constant USER_MST_DWIDTH                : integer              := C_MPLB_DWIDTH;

  constant IPIF_MST_DWIDTH                : integer              := C_MPLB_DWIDTH;
  
  ------------------------------------------
  -- Inhibit the automatic inculsion of the Conversion Cycle and Burst Length Expansion logic
  -- 0 = allow automatic inclusion of the CC and BLE logic
  -- 1 = inhibit automatic inclusion of the CC and BLE logic
  ------------------------------------------
  constant IPIF_INHIBIT_CC_BLE_INCLUSION  : integer              := 0;

  ------------------------------------------
  -- Width of the slave address bus (32 only)
  ------------------------------------------
  --constant USER_SLV_AWIDTH                : integer              := C_SPLB_AWIDTH;

  ------------------------------------------
  -- Width of the master address bus (32 only)
  ------------------------------------------
  constant USER_MST_AWIDTH                : integer              := C_MPLB_AWIDTH;

  ------------------------------------------
  -- Index for CS/CE
  ------------------------------------------
  --constant USER_MST_CS_INDEX              : integer              := 0;
  --constant USER_MST_CE_INDEX              : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_MST_CS_INDEX);
  --constant USER_MEM0_CS_INDEX             : integer              := 1;
  --constant USER_MEM0_CS_INDEX             : integer              := 0;
  --constant USER_CS_INDEX                  : integer              := USER_MEM0_CS_INDEX;

  --constant USER_CE_INDEX                  : integer              := USER_MST_CE_INDEX;
  --constant USER_CE_INDEX                  : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_CS_INDEX);

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations
  ------------------------------------------
--  signal ipif_Bus2IP_Clk                : std_logic;
--  signal ipif_Bus2IP_Reset              : std_logic;
--  signal ipif_IP2Bus_Data               : std_logic_vector(0 to IPIF_MST_DWIDTH-1);
--  signal ipif_IP2Bus_WrAck              : std_logic;
--  signal ipif_IP2Bus_RdAck              : std_logic;
--  signal ipif_IP2Bus_AddrAck            : std_logic;
--  signal ipif_IP2Bus_Error              : std_logic;
--  signal ipif_Bus2IP_Addr               : std_logic_vector(0 to C_MPLB_AWIDTH-1);
--  signal ipif_Bus2IP_Data               : std_logic_vector(0 to IPIF_MST_DWIDTH-1);
--  signal ipif_Bus2IP_RNW                : std_logic;
--  signal ipif_Bus2IP_BE                 : std_logic_vector(0 to IPIF_SLV_DWIDTH/8-1);
--  signal ipif_Bus2IP_Burst              : std_logic;
--  signal ipif_Bus2IP_BurstLength        : std_logic_vector(0 to log2(16*(C_SPLB_DWIDTH/8)));
--  signal ipif_Bus2IP_WrReq              : std_logic;
--  signal ipif_Bus2IP_RdReq              : std_logic;
--  signal ipif_Bus2IP_CS                 : std_logic_vector(0 to ((IPIF_ARD_ADDR_RANGE_ARRAY'length)/2)-1);
--  signal ipif_Bus2IP_RdCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
--  signal ipif_Bus2IP_WrCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_IP2Bus_MstRd_Req          : std_logic;
  signal ipif_IP2Bus_MstWr_Req          : std_logic;
  signal ipif_IP2Bus_Mst_Addr           : std_logic_vector(0 to C_MPLB_AWIDTH-1);
  signal ipif_IP2Bus_Mst_Length         : std_logic_vector(0 to 11);
  signal ipif_IP2Bus_Mst_BE             : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_IP2Bus_Mst_Type           : std_logic;
  signal ipif_IP2Bus_Mst_Lock           : std_logic;
  signal ipif_IP2Bus_Mst_Reset          : std_logic;
  signal ipif_Bus2IP_Mst_CmdAck         : std_logic;
  signal ipif_Bus2IP_Mst_Cmplt          : std_logic;
  signal ipif_Bus2IP_Mst_Error          : std_logic;
  signal ipif_Bus2IP_Mst_Rearbitrate    : std_logic;
  signal ipif_Bus2IP_Mst_Cmd_Timeout    : std_logic;
  signal ipif_Bus2IP_MstRd_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_Bus2IP_MstRd_rem          : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_Bus2IP_MstRd_sof_n        : std_logic;
  signal ipif_Bus2IP_MstRd_eof_n        : std_logic;
  signal ipif_Bus2IP_MstRd_src_rdy_n    : std_logic;
  signal ipif_Bus2IP_MstRd_src_dsc_n    : std_logic;
  signal ipif_IP2Bus_MstRd_dst_rdy_n    : std_logic;
  signal ipif_IP2Bus_MstRd_dst_dsc_n    : std_logic;
  signal ipif_IP2Bus_MstWr_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_IP2Bus_MstWr_rem          : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_IP2Bus_MstWr_sof_n        : std_logic;
  signal ipif_IP2Bus_MstWr_eof_n        : std_logic;
  signal ipif_IP2Bus_MstWr_src_rdy_n    : std_logic;
  signal ipif_IP2Bus_MstWr_src_dsc_n    : std_logic;
  signal ipif_Bus2IP_MstWr_dst_rdy_n    : std_logic;
  signal ipif_Bus2IP_MstWr_dst_dsc_n    : std_logic;
--  signal user_Bus2IP_RdCE               : std_logic_vector(0 to USER_NUM_REG-1);
--  signal user_Bus2IP_WrCE               : std_logic_vector(0 to USER_NUM_REG-1);
--  signal user_Bus2IP_BurstLength        : std_logic_vector(0 to 8)   := (others => '0');
--  signal user_Bus2IP_Data					 : std_logic_vector(0 to USER_MST_DWIDTH-1);
--  signal user_Bus2IP_DataX					 : std_logic_vector(0 to USER_MST_DWIDTH-1);
--  signal user_IP2Bus_Data               : std_logic_vector(0 to USER_MST_DWIDTH-1);
--  signal user_IP2Bus_DataX              : std_logic_vector(0 to USER_MST_DWIDTH-1);
--  signal user_IP2Bus_RdAck              : std_logic;
--  signal user_IP2Bus_WrAck              : std_logic;
--  signal user_IP2Bus_Error              : std_logic;
  
  signal task_clk_internal   : std_logic;
  signal task_reset_internal : std_logic;
  
  
  -- single word data input/output
  signal mem2osif_singleData : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
  signal osif2mem_singleData : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1);
  
  -- addresses for master transfers
  signal mem_localAddr       : std_logic_vector(0 to USER_MST_AWIDTH-1);
  signal mem_targetAddr      : std_logic_vector(0 to USER_MST_AWIDTH-1);

  -- single word transfer requests
  signal mem_singleRdReq : std_logic;
  signal mem_singleWrReq : std_logic;

  -- burst transfer requests
  signal mem_burstRdReq : std_logic;
  signal mem_burstWrReq : std_logic;
  signal mem_burstLen   : std_logic_vector(0 to 11);
  
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

---------
-- set task clock/reset
---------   
task_clk <= task_clk_internal;
task_reset <= task_reset_internal;

 		--------------------------------------
        -- memory bus controller core
        --
        -- PLBv46
        ---------------------------------------
    mem_plb46_i : entity xps_osif_v2_01_a.mem_plb46
        generic map
        (
            -- Bus protocol parameters
            C_AWIDTH         => C_MPLB_AWIDTH,
            C_DWIDTH         => 32,
            C_PLB_AWIDTH     => C_MPLB_AWIDTH,
            C_PLB_DWIDTH     => C_MPLB_NATIVE_DWIDTH,
            --C_NUM_CE         => USER_MST_NUM_REG,
            C_BURST_AWIDTH   => C_BURST_AWIDTH
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


            -- PLBv46 bus interface -----------------------------------------

            -- Bus protocol ports, do not add to or delete
            Bus2IP_Clk        => MPLB_Clk,
            Bus2IP_Reset      => MPLB_Rst,
            Bus2IP_MstError   => ipif_Bus2IP_Mst_Error,
            Bus2IP_MstLastAck => ipif_Bus2IP_Mst_Cmplt,
            Bus2IP_MstRdAck   => PLB_MRdDAck,
            Bus2IP_MstWrAck   => PLB_MWrDAck,
            Bus2IP_MstRetry   => ipif_Bus2IP_Mst_Rearbitrate,
            Bus2IP_MstTimeOut => ipif_Bus2IP_Mst_Cmd_Timeout,
            Bus2IP_Mst_CmdAck => ipif_Bus2IP_Mst_CmdAck,
            Bus2IP_Mst_Cmplt  => ipif_Bus2IP_Mst_Cmplt,
            Bus2IP_Mst_Error  => ipif_Bus2IP_Mst_Error,
            Bus2IP_Mst_Cmd_Timeout => ipif_Bus2IP_Mst_Cmd_Timeout,
            IP2Bus_Addr       => ipif_IP2Bus_Mst_Addr,
            IP2Bus_MstBE      => ipif_IP2Bus_Mst_BE,
            IP2Bus_MstBurst   => ipif_IP2Bus_Mst_Type,
            IP2Bus_MstBusReset => ipif_IP2Bus_Mst_Reset,
            IP2Bus_MstBusLock => ipif_IP2Bus_Mst_Lock,
            IP2Bus_MstNum     => ipif_IP2Bus_Mst_Length,
            IP2Bus_MstRdReq   => ipif_IP2Bus_MstRd_Req,
            IP2Bus_MstWrReq   => ipif_IP2Bus_MstWr_Req,
            -- Ports for Local Link
            Bus2IP_MstRd_d                 => ipif_Bus2IP_MstRd_d,
            Bus2IP_MstRd_rem               => ipif_Bus2IP_MstRd_rem,
            Bus2IP_MstRd_sof_n             => ipif_Bus2IP_MstRd_sof_n,
            Bus2IP_MstRd_eof_n             => ipif_Bus2IP_MstRd_eof_n,
            Bus2IP_MstRd_src_rdy_n         => ipif_Bus2IP_MstRd_src_rdy_n,
            Bus2IP_MstRd_src_dsc_n         => ipif_Bus2IP_MstRd_src_dsc_n,
            IP2Bus_MstRd_dst_rdy_n         => ipif_IP2Bus_MstRd_dst_rdy_n,
            IP2Bus_MstRd_dst_dsc_n         => ipif_IP2Bus_MstRd_dst_dsc_n,
            IP2Bus_MstWr_d                 => ipif_IP2Bus_MstWr_d,
            IP2Bus_MstWr_rem               => ipif_IP2Bus_MstWr_rem,
            IP2Bus_MstWr_sof_n             => ipif_IP2Bus_MstWr_sof_n,
            IP2Bus_MstWr_eof_n             => ipif_IP2Bus_MstWr_eof_n,
            IP2Bus_MstWr_src_rdy_n         => ipif_IP2Bus_MstWr_src_rdy_n,
            IP2Bus_MstWr_src_dsc_n         => ipif_IP2Bus_MstWr_src_dsc_n,
            Bus2IP_MstWr_dst_rdy_n         => ipif_Bus2IP_MstWr_dst_rdy_n,
            Bus2IP_MstWr_dst_dsc_n         => ipif_Bus2IP_MstWr_dst_dsc_n
            );

  ------------------------------------------
  -- instantiate plbv46_master_burst
  ------------------------------------------
  PLBV46_MASTER_BURST_I : entity plbv46_master_burst_v1_00_a.plbv46_master_burst
    generic map
    (
      C_MPLB_AWIDTH                  => C_MPLB_AWIDTH,
      C_MPLB_DWIDTH                  => C_MPLB_DWIDTH,
      C_MPLB_NATIVE_DWIDTH           => C_MPLB_NATIVE_DWIDTH,
      C_MPLB_SMALLEST_SLAVE          => C_MPLB_SMALLEST_SLAVE,
      C_INHIBIT_CC_BLE_INCLUSION     => IPIF_INHIBIT_CC_BLE_INCLUSION,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      MPLB_Clk                       => MPLB_Clk,
      MPLB_Rst                       => MPLB_Rst,
      MD_error                       => MD_error,
      M_request                      => M_request,
      M_priority                     => M_priority,
      M_busLock                      => M_busLock,
      M_RNW                          => M_RNW,
      M_BE                           => M_BE,
      M_MSize                        => M_MSize,
      M_size                         => M_size,
      M_type                         => M_type,
      M_TAttribute                   => M_TAttribute,
      M_lockErr                      => M_lockErr,
      M_abort                        => M_abort,
      M_UABus                        => M_UABus,
      M_ABus                         => M_ABus,
      M_wrDBus                       => M_wrDBus,
      M_wrBurst                      => M_wrBurst,
      M_rdBurst                      => M_rdBurst,
      PLB_MAddrAck                   => PLB_MAddrAck,
      PLB_MSSize                     => PLB_MSSize,
      PLB_MRearbitrate               => PLB_MRearbitrate,
      PLB_MTimeout                   => PLB_MTimeout,
      PLB_MBusy                      => PLB_MBusy,
      PLB_MRdErr                     => PLB_MRdErr,
      PLB_MWrErr                     => PLB_MWrErr,
      PLB_MIRQ                       => PLB_MIRQ,
      PLB_MRdDBus                    => PLB_MRdDBus,
      PLB_MRdWdAddr                  => PLB_MRdWdAddr,
      PLB_MRdDAck                    => PLB_MRdDAck,
      PLB_MRdBTerm                   => PLB_MRdBTerm,
      PLB_MWrDAck                    => PLB_MWrDAck,
      PLB_MWrBTerm                   => PLB_MWrBTerm,
      IP2Bus_MstRd_Req               => ipif_IP2Bus_MstRd_Req,
      IP2Bus_MstWr_Req               => ipif_IP2Bus_MstWr_Req,
      IP2Bus_Mst_Addr                => ipif_IP2Bus_Mst_Addr,
      IP2Bus_Mst_Length              => ipif_IP2Bus_Mst_Length,
      IP2Bus_Mst_BE                  => ipif_IP2Bus_Mst_BE,
      IP2Bus_Mst_Type                => ipif_IP2Bus_Mst_Type,
      IP2Bus_Mst_Lock                => ipif_IP2Bus_Mst_Lock,
      IP2Bus_Mst_Reset               => ipif_IP2Bus_Mst_Reset,
      Bus2IP_Mst_CmdAck              => ipif_Bus2IP_Mst_CmdAck,
      Bus2IP_Mst_Cmplt               => ipif_Bus2IP_Mst_Cmplt,
      Bus2IP_Mst_Error               => ipif_Bus2IP_Mst_Error,
      Bus2IP_Mst_Rearbitrate         => ipif_Bus2IP_Mst_Rearbitrate,
      Bus2IP_Mst_Cmd_Timeout         => ipif_Bus2IP_Mst_Cmd_Timeout,
      Bus2IP_MstRd_d                 => ipif_Bus2IP_MstRd_d,
      Bus2IP_MstRd_rem               => ipif_Bus2IP_MstRd_rem,
      Bus2IP_MstRd_sof_n             => ipif_Bus2IP_MstRd_sof_n,
      Bus2IP_MstRd_eof_n             => ipif_Bus2IP_MstRd_eof_n,
      Bus2IP_MstRd_src_rdy_n         => ipif_Bus2IP_MstRd_src_rdy_n,
      Bus2IP_MstRd_src_dsc_n         => ipif_Bus2IP_MstRd_src_dsc_n,
      IP2Bus_MstRd_dst_rdy_n         => ipif_IP2Bus_MstRd_dst_rdy_n,
      IP2Bus_MstRd_dst_dsc_n         => ipif_IP2Bus_MstRd_dst_dsc_n,
      IP2Bus_MstWr_d                 => ipif_IP2Bus_MstWr_d,
      IP2Bus_MstWr_rem               => ipif_IP2Bus_MstWr_rem,
      IP2Bus_MstWr_sof_n             => ipif_IP2Bus_MstWr_sof_n,
      IP2Bus_MstWr_eof_n             => ipif_IP2Bus_MstWr_eof_n,
      IP2Bus_MstWr_src_rdy_n         => ipif_IP2Bus_MstWr_src_rdy_n,
      IP2Bus_MstWr_src_dsc_n         => ipif_IP2Bus_MstWr_src_dsc_n,
      Bus2IP_MstWr_dst_rdy_n         => ipif_Bus2IP_MstWr_dst_rdy_n,
      Bus2IP_MstWr_dst_dsc_n         => ipif_Bus2IP_MstWr_dst_dsc_n
    );

   -- instantiate the User Logic
    ------------------------------------------   
USER_LOGIC_I : entity osif_core_v2_01_a.osif_core
        generic map
        (
            -- MAP USER GENERICS BELOW THIS LINE  ---------------
            C_BURST_AWIDTH   => C_BURST_AWIDTH,
            C_FIFO_DWIDTH    => C_FIFO_DWIDTH,
            C_BURSTLEN_WIDTH => 12,

            -- MAP USER GENERICS ABOVE THIS LINE  ---------------

            C_AWIDTH     => C_MPLB_AWIDTH,
            C_DWIDTH     => 32,
            C_PLB_DWIDTH => C_MPLB_NATIVE_DWIDTH,
            C_NUM_CE     => 2, --isnt used in USER_LOGIC

            C_DCR_BASEADDR => C_DCR_BASEADDR,
            C_DCR_HIGHADDR => C_DCR_HIGHADDR,
            C_DCR_AWIDTH   => C_DCR_AWIDTH,
            C_DCR_DWIDTH   => C_DCR_DWIDTH,
            C_DCR_ILA      => C_DCR_ILA

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
            -- MAP USER PORTS ABOVE THIS LINE  ------------------

            sys_clk   => MPLB_Clk,--sys_clk,
            sys_reset => MPLB_Rst,--sys_reset,

            -- DCR Bus protocol ports
            o_dcrAck   => o_dcrAck,
            o_dcrDBus  => o_dcrDBus,
            i_dcrABus  => i_dcrABus,
            i_dcrDBus  => i_dcrDBus,
            i_dcrRead  => i_dcrRead,
            i_dcrWrite => i_dcrWrite,
            i_dcrICON  => i_dcrICON

            );
            
    -----------------------------------------------------------------------
    -- fifo_mgr_inst: FIFO manager instantiation
    --
    -- The FIFO manager handles incoming push/pop requests to the two
    -- hardware FIFOs attached to the OSIF. It arbitrates between
    -- local hardware-thread-initiated requests and indirect bus accesses
    -- by other hardware threads.
    -----------------------------------------------------------------------

    fifo_mgr_inst : entity xps_osif_v2_01_a.fifo_mgr
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
            );


    --------
    -- set FIFO clock/reset
    --------
    o_fifo_clk <= sys_clk;
    o_fifo_reset <= sys_reset;
  ------------------------------------------
  -- connect internal signals
  ------------------------------------------
--  IP2BUS_DATA_MUX_PROC : process( ipif_Bus2IP_CS, user_IP2Bus_Data, user_IP2Bus_DataX ) is
--  begin

--    case ipif_Bus2IP_CS is
--      when "1" => ipif_IP2Bus_Data <= user_IP2Bus_Data & user_IP2Bus_DataX;
--      when "010" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
--      when "001" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
--      when others => ipif_IP2Bus_Data <= (others => '0');
--    end case;

--  end process IP2BUS_DATA_MUX_PROC;

--  user_Bus2IP_Data                     <= ipif_Bus2IP_Data(0 to USER_MST_DWIDTH-1);
--  user_Bus2IP_DataX                    <= iBus2IP_Data(USER_MST_DWIDTH to C_MPLB_DWIDTH-1);

--  ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck;
--  ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck;
--  ipif_IP2Bus_Error <= user_IP2Bus_Error;

--  user_Bus2IP_RdCE <= ipif_Bus2IP_RdCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);
--  user_Bus2IP_WrCE <= ipif_Bus2IP_WrCE(USER_CE_INDEX to USER_CE_INDEX+USER_NUM_REG-1);

end IMP;
