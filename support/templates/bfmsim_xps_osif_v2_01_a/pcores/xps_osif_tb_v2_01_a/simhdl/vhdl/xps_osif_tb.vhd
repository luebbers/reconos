------------------------------------------------------------------------------
--
--   This vhdl module is a template for creating IP testbenches using the IBM
--   BFM toolkits. It provides a fixed interface to the subsystem testbench.
--
--   DO NOT CHANGE THE entity name, architecture name, generic parameter
--   declaration or port declaration of this file. You may add components,
--   instances, constants, signals, etc. as you wish.
--
--   See IBM Bus Functional Model Toolkit User's Manual for more information
--   on the BFMs.
--
------------------------------------------------------------------------------
-- xps_osif_tb.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2007 Xilinx, Inc.  All rights reserved.            **
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
-- Filename:          xps_osif_tb.vhd
-- Version:           2.01.a
-- Description:       IP testbench
-- Date:              Thu Jul 23 14:47:35 2009 (by Create and Import Peripheral Wizard)
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

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

library xps_osif_v2_01_a;
library burst_ram_v2_01_a;

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------

entity xps_osif_tb is

  ------------------------------------------
  -- DO NOT CHANGE THIS GENERIC DECLARATION
  ------------------------------------------
  generic
  (
    C_FIFO_DWIDTH                  : natural := 32;
    C_DCR_BASEADDR		   : std_logic_vector := "0000000000";
    C_DCR_HIGHADDR		   : std_logic_vector := "0000000011";
    C_DCR_AWIDTH		   : integer := 10;
    C_DCR_DWIDTH		   : integer := 32;
    C_REGISTER_OSIF_PORTS          : integer := 1;      -- route OSIF ports through registers
    C_DCR_ILA			   : integer := 0;	-- 0: no debug ILA, 1: include debug chipscope ILA for DCR debugging
  
    -- Bus protocol parameters, do not add to or delete
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000";
    C_FAMILY                       : string               := "virtex5";
    C_MPLB_AWIDTH                  : integer              := 32;
    C_MPLB_DWIDTH                  : integer              := 128;
    C_MPLB_NATIVE_DWIDTH           : integer              := 64;
    C_MPLB_P2P                     : integer              := 0;
    C_MPLB_SMALLEST_SLAVE          : integer              := 32;
    C_MPLB_CLK_PERIOD_PS           : integer              := 10000
  );

  ------------------------------------------
  -- DO NOT CHANGE THIS PORT DECLARATION
  ------------------------------------------
  port
  (
    -- PLB (v4.6) bus interface, do not add or delete
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
    PLB_MWrBTerm                   : in  std_logic;
    -- BFM synchronization bus interface
    SYNCH_IN                       : in  std_logic_vector(0 to 31) := (others => '0');
    SYNCH_OUT                      : out std_logic_vector(0 to 31) := (others => '0')
  );

end entity xps_osif_tb;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture testbench of xps_osif_tb is

  --USER testbench signal declarations added here as you wish

  ------------------------------------------
  -- Signal to hook up master detected error and synch bus
  ------------------------------------------
  signal sig_dev_mderr                  : std_logic;

  ------------------------------------------
  -- Standard constants for bfl/vhdl communication
  ------------------------------------------
  constant NOP        : integer := 0;
  constant START      : integer := 1;
  constant STOP       : integer := 2;
  constant WAIT_IN    : integer := 3;
  constant WAIT_OUT   : integer := 4;
  constant ASSERT_IN  : integer := 5;
  constant ASSERT_OUT : integer := 6;
  constant ASSIGN_IN  : integer := 7;
  constant ASSIGN_OUT : integer := 8;
  constant RESET_WDT  : integer := 9;
  constant MST_ERROR  : integer := 30;
  constant INTERRUPT  : integer := 31;
  
  signal PLB_Clk : std_logic;
  signal PLB_Rst : std_logic;
  
  signal busy_local : std_logic;

  signal task_interrupt : std_logic;
  signal task_busy      : std_logic;
  signal task_blocking  : std_logic;
  signal task_clk       : std_logic;
  signal task_reset     : std_logic;
	signal task_os2task_vec    : std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
	signal task_os2task_vec_i    : std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
	signal task_task2os_vec    : std_logic_vector(0 to C_OSIF_TASK2OS_REC_WIDTH-1);
	signal task_os2task    : osif_os2task_t;
	signal task_task2os    : osif_task2os_t;
	
	signal burstAddr : std_logic_vector(0 to 13);
	signal burstWrData : std_logic_vector(0 to 63);
	signal burstRdData  : std_logic_vector(0 to 63);
	signal burstWE : std_logic;
	signal burstBE : std_logic_vector(0 to 7);

	signal task2burst_Addr : std_logic_vector(0 to 11);
	signal task2burst_Data : std_logic_vector(0 to 31);
	signal burst2task_Data : std_logic_vector(0 to 31);
	signal task2burst_WE   : std_logic;
	
	signal VDEC_YCrCb : std_logic_vector(9 downto 2);
	signal VDEC_LLC   : std_logic;
	signal VDEC_Rst   : std_logic;
	signal VDEC_OE    : std_logic;
	signal VDEC_PwrDn : std_logic;

  ---------
  -- FIFO control and data lines
  ---------
  signal fifo_clk         : std_logic;
  signal fifo_reset       : std_logic;
  signal fifo_read_remove : std_logic;
  signal fifo_read_data   : std_logic_vector(0 to C_FIFO_DWIDTH-1);
  signal fifo_read_ready  : std_logic;
  signal fifo_write_add   : std_logic;
  signal fifo_write_data  : std_logic_vector(0 to C_FIFO_DWIDTH-1);
  signal fifo_write_ready  : std_logic;

  -- for simulation
  signal fifo_read_add : std_logic;
  signal fifo_read_datain   : std_logic_vector(0 to C_FIFO_DWIDTH-1);
  signal fifo_read_empty  : std_logic;
  signal fifo_read_full  : std_logic;
  signal fifo_read_valid  : std_logic;

  signal fifo_write_remove   : std_logic;
  signal fifo_write_dataout  : std_logic_vector(0 to C_FIFO_DWIDTH-1);
  signal fifo_write_empty    : std_logic;
  signal fifo_write_full     : std_logic;
  signal fifo_write_valid  : std_logic;

  
  ---------
  -- DCR stimuli
  ---------
  signal dcrAck   : std_logic;
  signal dcrDBus_in  : std_logic_vector(0 to C_DCR_DWIDTH-1);
  signal dcrABus  : std_logic_vector(0 to C_DCR_AWIDTH-1);
  signal dcrDBus_out  : std_logic_vector(0 to C_DCR_DWIDTH-1);
  signal dcrRead  : std_logic;
  signal dcrWrite : std_logic;
  signal dcrICON  : std_logic_vector(35 downto 0);		-- chipscope

  constant C_GND_TASK_DATA : std_logic_vector(0 to 31) := (others => '0');
  constant C_GND_TASK_ADDR : std_logic_vector(0 to 11) := (others => '0');



begin

      ------------------------------------------
      -- Instance of IP under test.
      -- Communication with the BFL is by using SYNCH_IN/SYNCH_OUT signals.
      ------------------------------------------
      UUT : entity xps_osif_v2_01_a.xps_osif
        generic map
        (
          -- MAP USER GENERICS BELOW THIS LINE ---------------
          --USER generics mapped here
          C_BURST_AWIDTH    => 14,
          -- MAP USER GENERICS ABOVE THIS LINE ---------------

          C_BASEADDR        => C_BASEADDR,
          C_HIGHADDR        => C_HIGHADDR,
          C_FAMILY          => C_FAMILY,
          C_DCR_BASEADDR    => C_DCR_BASEADDR,
          C_DCR_HIGHADDR    => C_DCR_HIGHADDR,
          C_DCR_AWIDTH      => C_DCR_AWIDTH,
          C_DCR_DWIDTH      => C_DCR_DWIDTH,
          C_DCR_ILA         => C_DCR_ILA,
        C_MPLB_AWIDTH          =>C_MPLB_AWIDTH,
        C_MPLB_DWIDTH          =>C_MPLB_DWIDTH,
        C_MPLB_NATIVE_DWIDTH   =>C_MPLB_NATIVE_DWIDTH,
        C_MPLB_P2P             =>C_MPLB_P2P,
        C_MPLB_SMALLEST_SLAVE  =>C_MPLB_SMALLEST_SLAVE,
        C_MPLB_CLK_PERIOD_PS   =>C_MPLB_CLK_PERIOD_PS
        )
        port map
        (
          -- MAP USER PORTS BELOW THIS LINE ------------------

          interrupt => task_interrupt,
          busy      => task_busy,
          blocking  => task_blocking,
          -- task interface
          task_clk         => task_clk,
          task_reset       => task_reset,
          osif_os2task_vec => task_os2task_vec,
          osif_task2os_vec => task_task2os_vec,
          -- burst mem interface
          burstAddr   => burstAddr,
          burstWrData => burstWrData,
          burstRdData => burstRdData,
          burstWE     => burstWE,
          burstBE     => burstBE,
          -- "real" FIFO access signals
          fifo_clk         => fifo_clk,
          fifo_reset       => fifo_reset,
          fifo_read_en     => fifo_read_remove,
          fifo_read_data   => fifo_read_data,
          fifo_read_ready  => fifo_read_ready,
          fifo_write_en    => fifo_write_add,
          fifo_write_data  => fifo_write_data,
          fifo_write_ready => fifo_write_ready,

          -- MAP USER PORTS ABOVE THIS LINE ------------------

          o_dcrAck         => dcrAck,
          o_dcrDBus        => dcrDBus_in,
          i_dcrABus        => dcrABus,
          i_dcrDBus        => dcrDBus_out,
          i_dcrRead        => dcrRead,
          i_dcrWrite       => dcrWrite,
          i_dcrICON        => dcrICON,
    --      sys_clk          => PLB_Clk,
    --      sys_reset        => PLB_Rst,
    --      SPLB_Clk         => SPLB_Clk,
    --      SPLB_Rst         => SPLB_Rst ,
    --      PLB_ABus         => PLB_ABus,
    --      PLB_UABus        => PLB_UABus,
    --      PLB_PAValid      => PLB_PAValid,
    --      PLB_SAValid      => PLB_SAValid,
    --      PLB_rdPrim       => PLB_rdPrim,
    --      PLB_wrPrim       => PLB_wrPrim,
    --      PLB_masterID     => PLB_masterID,
    --      PLB_abort        => PLB_abort,
    --      PLB_busLock      => PLB_busLock,
    --      PLB_RNW          => PLB_RNW,
    --      PLB_BE           => PLB_BE,
    --      PLB_MSize        => PLB_MSize,
    --      PLB_size         => PLB_size ,
    --      PLB_type         => PLB_type,
    --      PLB_lockErr      => PLB_lockErr,
    --      PLB_wrDBus       => PLB_wrDBus,
    --      PLB_wrBurst      => PLB_wrBurst,
    --      PLB_rdBurst      => PLB_rdBurst,
    --      PLB_wrPendReq    => PLB_wrPendReq,
    --      PLB_rdPendReq    => PLB_rdPendReq,
    --      PLB_wrPendPri    => PLB_wrPendPri,
    --      PLB_rdPendPri    => PLB_rdPendPri,
    --      PLB_reqPri       => PLB_reqPri,
    --      PLB_TAttribute   => PLB_TAttribute,
    --      Sl_addrAck       => Sl_addrAck,
    --      Sl_SSize         => Sl_SSize,
    --      Sl_wait          => Sl_wait,
    --      Sl_rearbitrate   => Sl_rearbitrate,
    --      Sl_wrDAck        => Sl_wrDAck,
    --      Sl_wrComp        => Sl_wrComp,
    --      Sl_wrBTerm       => Sl_wrBTerm,
    --      Sl_rdDBus        => Sl_rdDBus,
    --      Sl_rdWdAddr      => Sl_rdWdAddr,
    --      Sl_rdDAck        => Sl_rdDAck,
    --      Sl_rdComp        => Sl_rdComp,
    --      Sl_rdBTerm       => Sl_rdBTerm ,
    --      Sl_MBusy         => Sl_MBusy,
    --      Sl_MWrErr        => Sl_MWrErr,
    --      Sl_MRdErr        => Sl_MRdErr,
    --      Sl_MIRQ          => Sl_MIRQ,
          MPLB_Clk         => MPLB_Clk,
          MPLB_Rst         => MPLB_Rst,
          MD_error         => MD_error,
          M_request        => M_request,
          M_priority      => M_priority,
          M_busLock       => M_busLock ,
          M_RNW           => M_RNW,
          M_BE            => M_BE,
          M_MSize         => M_MSize,
          M_size          => M_size,
          M_type          => M_type,
          M_TAttribute    => M_TAttribute,
          M_lockErr       => M_lockErr,
          M_abort         => M_abort,
          M_UABus         => M_UABus,
          M_ABus          => M_ABus,
          M_wrDBus        => M_wrDBus,
          M_wrBurst       => M_wrBurst,
          M_rdBurst       =>M_rdBurst,
          PLB_MAddrAck    => PLB_MAddrAck,
          PLB_MSSize       => PLB_MSSize,
          PLB_MRearbitrate => PLB_MRearbitrate,
          PLB_MTimeout     => PLB_MTimeout,
          PLB_MBusy        => PLB_MBusy,
          PLB_MRdErr       => PLB_MRdErr,
          PLB_MWrErr       => PLB_MWrErr,
          PLB_MIRQ         => PLB_MIRQ,
          PLB_MRdDBus      => PLB_MRdDBus,
          PLB_MRdWdAddr    => PLB_MRdWdAddr,
          PLB_MRdDAck      => PLB_MRdDAck,
          PLB_MRdBTerm     => PLB_MRdBTerm,
          PLB_MWrDAck      => PLB_MWrDAck,
          PLB_MWrBTerm    => PLB_MWrBTerm
        );


       PLB_Clk <= MPLB_Clk;
       PLB_Rst <= MPLB_Rst;
       
       ------------------------------------------
       -- user task
       ------------------------------------------
       dont_register_osif_ports : if C_REGISTER_OSIF_PORTS = 0 generate
           task_os2task_vec_i <= task_os2task_vec;
           task_task2os_vec <= to_std_logic_vector(task_task2os);
       end generate;

       register_osif_ports : if C_REGISTER_OSIF_PORTS /= 0 generate
           register_osif_ports_proc: process(task_clk)
           begin
               if rising_edge(task_clk) then
                   task_os2task_vec_i <= task_os2task_vec;
                   task_task2os_vec <= to_std_logic_vector(task_task2os);
               end if;
           end process;
       end generate;

       task_os2task <= to_osif_os2task_t(task_os2task_vec_i or (X"0000000000" & busy_local & "000000"));       
       
-- task_inst: User task instatiation
-- %%%USER_TASK%%%
       
       
       
       
       
  ------------------------------------------
  -- Hook up UUT MD_error to synch_out bit for Master Detected Error status monitor
  ------------------------------------------
  SYNCH_OUT(MST_ERROR) <= sig_dev_mderr;

  ------------------------------------------
  -- Zero out the unused synch_out bits
  ------------------------------------------
  SYNCH_OUT(10 to 31)  <= (others => '0');

  ------------------------------------------
  -- Test bench code itself
  --
  -- The test bench itself can be arbitrarily complex and may include
  -- hierarchy as the designer sees fit
  ------------------------------------------
  TEST_PROCESS : process
  begin

    SYNCH_OUT(NOP)        <= '0';
    SYNCH_OUT(START)      <= '0';
    SYNCH_OUT(STOP)       <= '0';
    SYNCH_OUT(WAIT_IN)    <= '0';
    SYNCH_OUT(WAIT_OUT)   <= '0';
    SYNCH_OUT(ASSERT_IN)  <= '0';
    SYNCH_OUT(ASSERT_OUT) <= '0';
    SYNCH_OUT(ASSIGN_IN)  <= '0';
    SYNCH_OUT(ASSIGN_OUT) <= '0';
    SYNCH_OUT(RESET_WDT)  <= '0';

    -- initializations
    -- wait for reset to stabalize after power-up
    wait for 200 ns;
    -- wait for end of reset
    wait until (SPLB_Rst'EVENT and SPLB_Rst = '0');
    assert FALSE report "*** Real simulation starts here ***" severity NOTE;
    -- wait for reset to be completed
    wait for 200 ns;

    ------------------------------------------
    -- Test User Logic IP Master
    ------------------------------------------
    -- send out start signal to begin testing ...
    wait until (SPLB_Clk'EVENT and SPLB_Clk = '1');
    SYNCH_OUT(START) <= '1';
--    assert FALSE report "*** Start User Logic IP Master Read Test ***" severity NOTE;
    wait until (SPLB_Clk'EVENT and SPLB_Clk = '1');
    SYNCH_OUT(START) <= '0';

    -- wait for awhile for wait_out signal to let user logic master complete master read ...
    wait until (SYNCH_IN(WAIT_OUT)'EVENT and SYNCH_IN(WAIT_OUT) = '1');
--    assert FALSE report "*** User Logic is doing master read transaction now ***" severity NOTE;
    wait for 1 us;

    -- send out wait_in signal to continue testing ...
    wait until (SPLB_Clk'EVENT and SPLB_Clk = '1');
    SYNCH_OUT(WAIT_IN) <= '1';
--    assert FALSE report "*** Continue User Logic IP Master Write Test ***" severity NOTE;
    wait until (SPLB_Clk'EVENT and SPLB_Clk = '1');
    SYNCH_OUT(WAIT_IN) <= '0';

    -- wait for awhile for wait_out signal to let user logic master complete master write ...
    wait until (SYNCH_IN(WAIT_OUT)'EVENT and SYNCH_IN(WAIT_OUT) = '1');
--    assert FALSE report "*** User Logic is doing master write transaction now ***" severity NOTE;
    wait for 1 us;

    -- send out wait_in signal to continue testing ...
    wait until (SPLB_Clk'EVENT and SPLB_Clk = '1');
    SYNCH_OUT(WAIT_IN) <= '1';
--    assert FALSE report "*** Continue the rest of User Logic IP Master Test ***" severity NOTE;
    wait until (SPLB_Clk'EVENT and SPLB_Clk = '1');
    SYNCH_OUT(WAIT_IN) <= '0';

    -- wait stop signal for end of testing ...
    wait until (SYNCH_IN(STOP)'EVENT and SYNCH_IN(STOP) = '1');
--    assert FALSE report "*** User Logic IP Master Test Complete ***" severity NOTE;
    wait for 1 us;

    ------------------------------------------
    -- Test User I/Os and other features
    ------------------------------------------
    --USER code added here to stimulate any user I/Os

    wait;

  end process TEST_PROCESS;


    dcr_sim : process is

      procedure OSIF_WRITE( where : in std_logic_vector(0 to 1);
                            what  : in std_logic_vector(0 to C_DCR_DWIDTH-1) ) is
      begin
  	dcrABus(C_DCR_AWIDTH-2 to C_DCR_AWIDTH-1) <= where;
  	dcrDBus_out <= what;
  	wait until rising_edge(PLB_Clk);
  	dcrWrite <= '1';
  	wait until rising_edge(PLB_Clk) and dcrAck = '1';
  	dcrWrite <= '0';
      end procedure;

      procedure OSIF_READ( where : in std_logic_vector(0 to 1);
                           variable what  : out std_logic_vector(0 to C_DCR_DWIDTH-1) ) is
      begin
  	dcrABus(C_DCR_AWIDTH-2 to C_DCR_AWIDTH-1) <= where;
  	wait until rising_edge(PLB_Clk);
  	dcrRead <= '1';
  	wait until rising_edge(PLB_Clk) and dcrAck = '1';
  	what := dcrDBus_in;
  	dcrRead <= '0';
      end procedure;

      constant OSIF_REG_COMMAND : std_logic_vector(0 to 1) := "00";
      constant OSIF_REG_DATA    : std_logic_vector(0 to 1) := "01";
      constant OSIF_REG_DONE    : std_logic_vector(0 to 1) := "10";
      constant OSIF_REG_DATAX   : std_logic_vector(0 to 1) := "10";
      constant OSIF_REG_SIGNATURE : std_logic_vector(0 to 1) := "11";
      constant OSIF_CMDNEW      : std_logic_vector(0 to C_DCR_DWIDTH-1) := X"FFFFFFFF";

      variable dummy : std_logic_vector(0 to C_DCR_DWIDTH-1);

      begin
  	-- initializations
  	-- wait for reset to stabalize after power-up
  	wait for 200 ns;
  	-- wait for end of reset
  	wait until (PLB_Rst'EVENT and PLB_Rst = '0');

  	dcrABus <= C_DCR_BASEADDR;
  	dcrDBus_out <= (others => '0');
  	dcrICON <= (others => '0');
  	dcrRead <= '0';
  	dcrWrite <= '0';

          -- sst-generated code starts here
-- %%%SST_TESTBENCH_START%%%
-- %%%SST_TESTBENCH_END%%%
  	-- end of sst-generated code

  	wait for 1 us;
  	wait;

      end process;
    -- simulate RAM
          burst_ram_i : entity burst_ram_v2_01_a.burst_ram
                  generic map (
                          G_PORTA_AWIDTH => 12,
                          G_PORTA_DWIDTH => 32,
                          G_PORTA_PORTS  => 1,
                          G_PORTB_AWIDTH => 11,
                          G_PORTB_DWIDTH => 64,
                          G_PORTB_USE_BE => 1
                  )
                  port map (

                          addra => task2burst_Addr,
                          addrax => C_GND_TASK_ADDR,
                          addrb => burstAddr(0 to 10),             -- RAM is addressing 64Bit values
                          clka => task_clk,
                          clkax => '0',
                          clkb => task_clk,
                          dina => task2burst_Data,
                          dinax => C_GND_TASK_DATA,
                          dinb => burstWrData,
                          douta => burst2task_Data,
                          doutax => open,
                          doutb => burstRdData,
                          wea => task2burst_WE,
                          weax => '0',
                          web => burstWE,
                          ena => '1',
                          enax => '0',
                          enb => '1',
                          beb => burstBE
                  );

    -- simulate FIFOs
    fifo_left : entity work.fifo
                  port map (
                          clk => fifo_clk,
                          din => fifo_read_datain,
                          rd_en => fifo_read_remove,
                          rst => fifo_reset,
                          wr_en => fifo_read_add,
                          dout => fifo_read_data,
                          empty => fifo_read_empty,
                          full => fifo_read_full,
  								valid => fifo_read_valid);
  	fifo_read_ready <= (not fifo_read_empty) or fifo_read_valid ;

    fifo_right : entity work.fifo
                  port map (
                          clk => fifo_clk,
                          din => fifo_write_data,
                          rd_en => fifo_write_remove,
                          rst => fifo_reset,
                          wr_en => fifo_write_add,
                          dout => fifo_write_dataout,
                          empty => fifo_write_empty,
                          full => fifo_write_full,
  								valid => fifo_write_valid);
  	fifo_write_ready <= not(fifo_write_full);

     fifo_fill : process(fifo_clk, fifo_reset)
  		variable counter : std_logic_vector(0 to C_FIFO_DWIDTH-1);
  	begin
  		if fifo_reset = '1' then
  			counter := (others => '0');
  			fifo_read_add <= '0';
  			fifo_read_datain <= (others => '0');
  		elsif rising_edge(fifo_clk) then
  			fifo_read_add <= '0';
  			-- only write on every second clock
  			if fifo_read_full = '0' and fifo_read_add = '0' and counter < 16 then
  				fifo_read_datain <= counter;
  				counter := counter + 1;
  				fifo_read_add <= '1';
  			end if;
  		end if;
  	end process;

          -- infer latch for local busy signal
          -- needed for asynchronous communication between thread and OSIF
          busy_local_gen : process(task_reset, task_task2os.request, task_os2task.ack)
          begin
              if task_reset = '1' then
                  busy_local <= '0';
              elsif task_task2os.request = '1' then
                  busy_local <= '1';
              elsif task_os2task.ack = '1' then
                  busy_local <= '0';
              end if;
          end process;

end architecture testbench;
