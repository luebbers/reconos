-----------------------------------------------------
--
--  Reconfigurable PLB Peripheral Demo
--
--
--  Tobias Becker
--
--  Imperial College London
--
--  25 Aug 2006
--
-----------------------------------------------------

--
-- This file is modified version of the auto-generated
-- system.vhd file.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity top is
  port (
    fpga_0_RS232_Uart_1_RX_pin : in std_logic;
    fpga_0_RS232_Uart_1_TX_pin : out std_logic;
    fpga_0_SysACE_CompactFlash_SysACE_CLK_pin : in std_logic;
    fpga_0_SysACE_CompactFlash_SysACE_MPA_pin : out std_logic_vector(6 downto 0);
    fpga_0_SysACE_CompactFlash_SysACE_MPD_pin : inout std_logic_vector(15 downto 0);
    fpga_0_SysACE_CompactFlash_SysACE_CEN_pin : out std_logic;
    fpga_0_SysACE_CompactFlash_SysACE_OEN_pin : out std_logic;
    fpga_0_SysACE_CompactFlash_SysACE_WEN_pin : out std_logic;
    fpga_0_SysACE_CompactFlash_SysACE_MPIRQ_pin : in std_logic;
    fpga_0_LEDs_4Bit_GPIO_IO_pin : inout std_logic_vector(0 to 3);
    fpga_0_PushButtons_5Bit_GPIO_IO_pin : inout std_logic_vector(0 to 4);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk_pin : out std_logic_vector(0 to 2);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn_pin : out std_logic_vector(0 to 2);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin : out std_logic_vector(0 to 12);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_BankAddr_pin : out std_logic_vector(0 to 1);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CASn_pin : out std_logic;
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_RASn_pin : out std_logic;
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_WEn_pin : out std_logic;
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin : out std_logic_vector(0 to 7);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin : inout std_logic_vector(0 to 7);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin : inout std_logic_vector(0 to 63);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CKE_pin : out std_logic_vector(0 to 1);
    fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CSn_pin : out std_logic_vector(0 to 1);
    fpga_0_net_gnd_pin : out std_logic;
    fpga_0_net_gnd_1_pin : out std_logic;
    fpga_0_net_gnd_2_pin : out std_logic;
    fpga_0_net_gnd_3_pin : out std_logic;
    fpga_0_net_gnd_4_pin : out std_logic;
    fpga_0_net_gnd_5_pin : out std_logic;
    fpga_0_net_gnd_6_pin : out std_logic;
    fpga_0_DDR_CLK_FB : in std_logic;
    fpga_0_DDR_CLK_FB_OUT : out std_logic;
    sys_clk_pin : in std_logic;
    sys_rst_pin : in std_logic
  );
end top;

architecture STRUCTURE of top is

  attribute box_type : STRING;

  component ppc405_0_wrapper is
    port (
      C405CPMCORESLEEPREQ : out std_logic;
      C405CPMMSRCE : out std_logic;
      C405CPMMSREE : out std_logic;
      C405CPMTIMERIRQ : out std_logic;
      C405CPMTIMERRESETREQ : out std_logic;
      C405XXXMACHINECHECK : out std_logic;
      CPMC405CLOCK : in std_logic;
      CPMC405CORECLKINACTIVE : in std_logic;
      CPMC405CPUCLKEN : in std_logic;
      CPMC405JTAGCLKEN : in std_logic;
      CPMC405TIMERCLKEN : in std_logic;
      CPMC405TIMERTICK : in std_logic;
      MCBCPUCLKEN : in std_logic;
      MCBTIMEREN : in std_logic;
      MCPPCRST : in std_logic;
      PLBCLK : in std_logic;
      DCRCLK : in std_logic;
      C405RSTCHIPRESETREQ : out std_logic;
      C405RSTCORERESETREQ : out std_logic;
      C405RSTSYSRESETREQ : out std_logic;
      RSTC405RESETCHIP : in std_logic;
      RSTC405RESETCORE : in std_logic;
      RSTC405RESETSYS : in std_logic;
      C405PLBICUABUS : out std_logic_vector(0 to 31);
      C405PLBICUBE : out std_logic_vector(0 to 7);
      C405PLBICURNW : out std_logic;
      C405PLBICUABORT : out std_logic;
      C405PLBICUBUSLOCK : out std_logic;
      C405PLBICUU0ATTR : out std_logic;
      C405PLBICUGUARDED : out std_logic;
      C405PLBICULOCKERR : out std_logic;
      C405PLBICUMSIZE : out std_logic_vector(0 to 1);
      C405PLBICUORDERED : out std_logic;
      C405PLBICUPRIORITY : out std_logic_vector(0 to 1);
      C405PLBICURDBURST : out std_logic;
      C405PLBICUREQUEST : out std_logic;
      C405PLBICUSIZE : out std_logic_vector(0 to 3);
      C405PLBICUTYPE : out std_logic_vector(0 to 2);
      C405PLBICUWRBURST : out std_logic;
      C405PLBICUWRDBUS : out std_logic_vector(0 to 63);
      C405PLBICUCACHEABLE : out std_logic;
      PLBC405ICUADDRACK : in std_logic;
      PLBC405ICUBUSY : in std_logic;
      PLBC405ICUERR : in std_logic;
      PLBC405ICURDBTERM : in std_logic;
      PLBC405ICURDDACK : in std_logic;
      PLBC405ICURDDBUS : in std_logic_vector(0 to 63);
      PLBC405ICURDWDADDR : in std_logic_vector(0 to 3);
      PLBC405ICUREARBITRATE : in std_logic;
      PLBC405ICUWRBTERM : in std_logic;
      PLBC405ICUWRDACK : in std_logic;
      PLBC405ICUSSIZE : in std_logic_vector(0 to 1);
      PLBC405ICUSERR : in std_logic;
      PLBC405ICUSBUSYS : in std_logic;
      C405PLBDCUABUS : out std_logic_vector(0 to 31);
      C405PLBDCUBE : out std_logic_vector(0 to 7);
      C405PLBDCURNW : out std_logic;
      C405PLBDCUABORT : out std_logic;
      C405PLBDCUBUSLOCK : out std_logic;
      C405PLBDCUU0ATTR : out std_logic;
      C405PLBDCUGUARDED : out std_logic;
      C405PLBDCULOCKERR : out std_logic;
      C405PLBDCUMSIZE : out std_logic_vector(0 to 1);
      C405PLBDCUORDERED : out std_logic;
      C405PLBDCUPRIORITY : out std_logic_vector(0 to 1);
      C405PLBDCURDBURST : out std_logic;
      C405PLBDCUREQUEST : out std_logic;
      C405PLBDCUSIZE : out std_logic_vector(0 to 3);
      C405PLBDCUTYPE : out std_logic_vector(0 to 2);
      C405PLBDCUWRBURST : out std_logic;
      C405PLBDCUWRDBUS : out std_logic_vector(0 to 63);
      C405PLBDCUCACHEABLE : out std_logic;
      C405PLBDCUWRITETHRU : out std_logic;
      PLBC405DCUADDRACK : in std_logic;
      PLBC405DCUBUSY : in std_logic;
      PLBC405DCUERR : in std_logic;
      PLBC405DCURDBTERM : in std_logic;
      PLBC405DCURDDACK : in std_logic;
      PLBC405DCURDDBUS : in std_logic_vector(0 to 63);
      PLBC405DCURDWDADDR : in std_logic_vector(0 to 3);
      PLBC405DCUREARBITRATE : in std_logic;
      PLBC405DCUWRBTERM : in std_logic;
      PLBC405DCUWRDACK : in std_logic;
      PLBC405DCUSSIZE : in std_logic_vector(0 to 1);
      PLBC405DCUSERR : in std_logic;
      PLBC405DCUSBUSYS : in std_logic;
      BRAMDSOCMCLK : in std_logic;
      BRAMDSOCMRDDBUS : in std_logic_vector(0 to 31);
      DSARCVALUE : in std_logic_vector(0 to 7);
      DSCNTLVALUE : in std_logic_vector(0 to 7);
      DSOCMBRAMABUS : out std_logic_vector(8 to 29);
      DSOCMBRAMBYTEWRITE : out std_logic_vector(0 to 3);
      DSOCMBRAMEN : out std_logic;
      DSOCMBRAMWRDBUS : out std_logic_vector(0 to 31);
      DSOCMBUSY : out std_logic;
      BRAMISOCMCLK : in std_logic;
      BRAMISOCMRDDBUS : in std_logic_vector(0 to 63);
      ISARCVALUE : in std_logic_vector(0 to 7);
      ISCNTLVALUE : in std_logic_vector(0 to 7);
      ISOCMBRAMEN : out std_logic;
      ISOCMBRAMEVENWRITEEN : out std_logic;
      ISOCMBRAMODDWRITEEN : out std_logic;
      ISOCMBRAMRDABUS : out std_logic_vector(8 to 28);
      ISOCMBRAMWRABUS : out std_logic_vector(8 to 28);
      ISOCMBRAMWRDBUS : out std_logic_vector(0 to 31);
      C405DCRABUS : out std_logic_vector(0 to 9);
      C405DCRDBUSOUT : out std_logic_vector(0 to 31);
      C405DCRREAD : out std_logic;
      C405DCRWRITE : out std_logic;
      DCRC405ACK : in std_logic;
      DCRC405DBUSIN : in std_logic_vector(0 to 31);
      EICC405CRITINPUTIRQ : in std_logic;
      EICC405EXTINPUTIRQ : in std_logic;
      C405JTGCAPTUREDR : out std_logic;
      C405JTGEXTEST : out std_logic;
      C405JTGPGMOUT : out std_logic;
      C405JTGSHIFTDR : out std_logic;
      C405JTGTDO : out std_logic;
      C405JTGTDOEN : out std_logic;
      C405JTGUPDATEDR : out std_logic;
      MCBJTAGEN : in std_logic;
      JTGC405BNDSCANTDO : in std_logic;
      JTGC405TCK : in std_logic;
      JTGC405TDI : in std_logic;
      JTGC405TMS : in std_logic;
      JTGC405TRSTNEG : in std_logic;
      C405DBGMSRWE : out std_logic;
      C405DBGSTOPACK : out std_logic;
      C405DBGWBCOMPLETE : out std_logic;
      C405DBGWBFULL : out std_logic;
      C405DBGWBIAR : out std_logic_vector(0 to 29);
      DBGC405DEBUGHALT : in std_logic;
      DBGC405EXTBUSHOLDACK : in std_logic;
      DBGC405UNCONDDEBUGEVENT : in std_logic;
      C405TRCCYCLE : out std_logic;
      C405TRCEVENEXECUTIONSTATUS : out std_logic_vector(0 to 1);
      C405TRCODDEXECUTIONSTATUS : out std_logic_vector(0 to 1);
      C405TRCTRACESTATUS : out std_logic_vector(0 to 3);
      C405TRCTRIGGEREVENTOUT : out std_logic;
      C405TRCTRIGGEREVENTTYPE : out std_logic_vector(0 to 10);
      TRCC405TRACEDISABLE : in std_logic;
      TRCC405TRIGGEREVENTIN : in std_logic
    );
  end component;

  attribute box_type of ppc405_0_wrapper: component is "black_box";

  component ppc405_1_wrapper is
    port (
      C405CPMCORESLEEPREQ : out std_logic;
      C405CPMMSRCE : out std_logic;
      C405CPMMSREE : out std_logic;
      C405CPMTIMERIRQ : out std_logic;
      C405CPMTIMERRESETREQ : out std_logic;
      C405XXXMACHINECHECK : out std_logic;
      CPMC405CLOCK : in std_logic;
      CPMC405CORECLKINACTIVE : in std_logic;
      CPMC405CPUCLKEN : in std_logic;
      CPMC405JTAGCLKEN : in std_logic;
      CPMC405TIMERCLKEN : in std_logic;
      CPMC405TIMERTICK : in std_logic;
      MCBCPUCLKEN : in std_logic;
      MCBTIMEREN : in std_logic;
      MCPPCRST : in std_logic;
      PLBCLK : in std_logic;
      DCRCLK : in std_logic;
      C405RSTCHIPRESETREQ : out std_logic;
      C405RSTCORERESETREQ : out std_logic;
      C405RSTSYSRESETREQ : out std_logic;
      RSTC405RESETCHIP : in std_logic;
      RSTC405RESETCORE : in std_logic;
      RSTC405RESETSYS : in std_logic;
      C405PLBICUABUS : out std_logic_vector(0 to 31);
      C405PLBICUBE : out std_logic_vector(0 to 7);
      C405PLBICURNW : out std_logic;
      C405PLBICUABORT : out std_logic;
      C405PLBICUBUSLOCK : out std_logic;
      C405PLBICUU0ATTR : out std_logic;
      C405PLBICUGUARDED : out std_logic;
      C405PLBICULOCKERR : out std_logic;
      C405PLBICUMSIZE : out std_logic_vector(0 to 1);
      C405PLBICUORDERED : out std_logic;
      C405PLBICUPRIORITY : out std_logic_vector(0 to 1);
      C405PLBICURDBURST : out std_logic;
      C405PLBICUREQUEST : out std_logic;
      C405PLBICUSIZE : out std_logic_vector(0 to 3);
      C405PLBICUTYPE : out std_logic_vector(0 to 2);
      C405PLBICUWRBURST : out std_logic;
      C405PLBICUWRDBUS : out std_logic_vector(0 to 63);
      C405PLBICUCACHEABLE : out std_logic;
      PLBC405ICUADDRACK : in std_logic;
      PLBC405ICUBUSY : in std_logic;
      PLBC405ICUERR : in std_logic;
      PLBC405ICURDBTERM : in std_logic;
      PLBC405ICURDDACK : in std_logic;
      PLBC405ICURDDBUS : in std_logic_vector(0 to 63);
      PLBC405ICURDWDADDR : in std_logic_vector(0 to 3);
      PLBC405ICUREARBITRATE : in std_logic;
      PLBC405ICUWRBTERM : in std_logic;
      PLBC405ICUWRDACK : in std_logic;
      PLBC405ICUSSIZE : in std_logic_vector(0 to 1);
      PLBC405ICUSERR : in std_logic;
      PLBC405ICUSBUSYS : in std_logic;
      C405PLBDCUABUS : out std_logic_vector(0 to 31);
      C405PLBDCUBE : out std_logic_vector(0 to 7);
      C405PLBDCURNW : out std_logic;
      C405PLBDCUABORT : out std_logic;
      C405PLBDCUBUSLOCK : out std_logic;
      C405PLBDCUU0ATTR : out std_logic;
      C405PLBDCUGUARDED : out std_logic;
      C405PLBDCULOCKERR : out std_logic;
      C405PLBDCUMSIZE : out std_logic_vector(0 to 1);
      C405PLBDCUORDERED : out std_logic;
      C405PLBDCUPRIORITY : out std_logic_vector(0 to 1);
      C405PLBDCURDBURST : out std_logic;
      C405PLBDCUREQUEST : out std_logic;
      C405PLBDCUSIZE : out std_logic_vector(0 to 3);
      C405PLBDCUTYPE : out std_logic_vector(0 to 2);
      C405PLBDCUWRBURST : out std_logic;
      C405PLBDCUWRDBUS : out std_logic_vector(0 to 63);
      C405PLBDCUCACHEABLE : out std_logic;
      C405PLBDCUWRITETHRU : out std_logic;
      PLBC405DCUADDRACK : in std_logic;
      PLBC405DCUBUSY : in std_logic;
      PLBC405DCUERR : in std_logic;
      PLBC405DCURDBTERM : in std_logic;
      PLBC405DCURDDACK : in std_logic;
      PLBC405DCURDDBUS : in std_logic_vector(0 to 63);
      PLBC405DCURDWDADDR : in std_logic_vector(0 to 3);
      PLBC405DCUREARBITRATE : in std_logic;
      PLBC405DCUWRBTERM : in std_logic;
      PLBC405DCUWRDACK : in std_logic;
      PLBC405DCUSSIZE : in std_logic_vector(0 to 1);
      PLBC405DCUSERR : in std_logic;
      PLBC405DCUSBUSYS : in std_logic;
      BRAMDSOCMCLK : in std_logic;
      BRAMDSOCMRDDBUS : in std_logic_vector(0 to 31);
      DSARCVALUE : in std_logic_vector(0 to 7);
      DSCNTLVALUE : in std_logic_vector(0 to 7);
      DSOCMBRAMABUS : out std_logic_vector(8 to 29);
      DSOCMBRAMBYTEWRITE : out std_logic_vector(0 to 3);
      DSOCMBRAMEN : out std_logic;
      DSOCMBRAMWRDBUS : out std_logic_vector(0 to 31);
      DSOCMBUSY : out std_logic;
      BRAMISOCMCLK : in std_logic;
      BRAMISOCMRDDBUS : in std_logic_vector(0 to 63);
      ISARCVALUE : in std_logic_vector(0 to 7);
      ISCNTLVALUE : in std_logic_vector(0 to 7);
      ISOCMBRAMEN : out std_logic;
      ISOCMBRAMEVENWRITEEN : out std_logic;
      ISOCMBRAMODDWRITEEN : out std_logic;
      ISOCMBRAMRDABUS : out std_logic_vector(8 to 28);
      ISOCMBRAMWRABUS : out std_logic_vector(8 to 28);
      ISOCMBRAMWRDBUS : out std_logic_vector(0 to 31);
      C405DCRABUS : out std_logic_vector(0 to 9);
      C405DCRDBUSOUT : out std_logic_vector(0 to 31);
      C405DCRREAD : out std_logic;
      C405DCRWRITE : out std_logic;
      DCRC405ACK : in std_logic;
      DCRC405DBUSIN : in std_logic_vector(0 to 31);
      EICC405CRITINPUTIRQ : in std_logic;
      EICC405EXTINPUTIRQ : in std_logic;
      C405JTGCAPTUREDR : out std_logic;
      C405JTGEXTEST : out std_logic;
      C405JTGPGMOUT : out std_logic;
      C405JTGSHIFTDR : out std_logic;
      C405JTGTDO : out std_logic;
      C405JTGTDOEN : out std_logic;
      C405JTGUPDATEDR : out std_logic;
      MCBJTAGEN : in std_logic;
      JTGC405BNDSCANTDO : in std_logic;
      JTGC405TCK : in std_logic;
      JTGC405TDI : in std_logic;
      JTGC405TMS : in std_logic;
      JTGC405TRSTNEG : in std_logic;
      C405DBGMSRWE : out std_logic;
      C405DBGSTOPACK : out std_logic;
      C405DBGWBCOMPLETE : out std_logic;
      C405DBGWBFULL : out std_logic;
      C405DBGWBIAR : out std_logic_vector(0 to 29);
      DBGC405DEBUGHALT : in std_logic;
      DBGC405EXTBUSHOLDACK : in std_logic;
      DBGC405UNCONDDEBUGEVENT : in std_logic;
      C405TRCCYCLE : out std_logic;
      C405TRCEVENEXECUTIONSTATUS : out std_logic_vector(0 to 1);
      C405TRCODDEXECUTIONSTATUS : out std_logic_vector(0 to 1);
      C405TRCTRACESTATUS : out std_logic_vector(0 to 3);
      C405TRCTRIGGEREVENTOUT : out std_logic;
      C405TRCTRIGGEREVENTTYPE : out std_logic_vector(0 to 10);
      TRCC405TRACEDISABLE : in std_logic;
      TRCC405TRIGGEREVENTIN : in std_logic
    );
  end component;

  attribute box_type of ppc405_1_wrapper: component is "black_box";

  component jtagppc_0_wrapper is
    port (
      TRSTNEG : in std_logic;
      HALTNEG0 : in std_logic;
      DBGC405DEBUGHALT0 : out std_logic;
      HALTNEG1 : in std_logic;
      DBGC405DEBUGHALT1 : out std_logic;
      C405JTGTDO0 : in std_logic;
      C405JTGTDOEN0 : in std_logic;
      JTGC405TCK0 : out std_logic;
      JTGC405TDI0 : out std_logic;
      JTGC405TMS0 : out std_logic;
      JTGC405TRSTNEG0 : out std_logic;
      C405JTGTDO1 : in std_logic;
      C405JTGTDOEN1 : in std_logic;
      JTGC405TCK1 : out std_logic;
      JTGC405TDI1 : out std_logic;
      JTGC405TMS1 : out std_logic;
      JTGC405TRSTNEG1 : out std_logic
    );
  end component;

  attribute box_type of jtagppc_0_wrapper: component is "black_box";

  component reset_block_wrapper is
    port (
      Slowest_sync_clk : in std_logic;
      Ext_Reset_In : in std_logic;
      Aux_Reset_In : in std_logic;
      Core_Reset_Req : in std_logic;
      Chip_Reset_Req : in std_logic;
      System_Reset_Req : in std_logic;
      Dcm_locked : in std_logic;
      Rstc405resetcore : out std_logic;
      Rstc405resetchip : out std_logic;
      Rstc405resetsys : out std_logic;
      Bus_Struct_Reset : out std_logic_vector(0 to 0);
      Peripheral_Reset : out std_logic_vector(0 to 0)
    );
  end component;

  attribute box_type of reset_block_wrapper: component is "black_box";

  component plb_wrapper is
    port (
      PLB_Clk : in std_logic;
      SYS_Rst : in std_logic;
      PLB_Rst : out std_logic;
      PLB_dcrAck : out std_logic;
      PLB_dcrDBus : out std_logic_vector(0 to 31);
      DCR_ABus : in std_logic_vector(0 to 9);
      DCR_DBus : in std_logic_vector(0 to 31);
      DCR_Read : in std_logic;
      DCR_Write : in std_logic;
      M_ABus : in std_logic_vector(0 to 63);
      M_BE : in std_logic_vector(0 to 15);
      M_RNW : in std_logic_vector(0 to 1);
      M_abort : in std_logic_vector(0 to 1);
      M_busLock : in std_logic_vector(0 to 1);
      M_compress : in std_logic_vector(0 to 1);
      M_guarded : in std_logic_vector(0 to 1);
      M_lockErr : in std_logic_vector(0 to 1);
      M_MSize : in std_logic_vector(0 to 3);
      M_ordered : in std_logic_vector(0 to 1);
      M_priority : in std_logic_vector(0 to 3);
      M_rdBurst : in std_logic_vector(0 to 1);
      M_request : in std_logic_vector(0 to 1);
      M_size : in std_logic_vector(0 to 7);
      M_type : in std_logic_vector(0 to 5);
      M_wrBurst : in std_logic_vector(0 to 1);
      M_wrDBus : in std_logic_vector(0 to 127);
      Sl_addrAck : in std_logic_vector(0 to 3);
      Sl_MErr : in std_logic_vector(0 to 7);
      Sl_MBusy : in std_logic_vector(0 to 7);
      Sl_rdBTerm : in std_logic_vector(0 to 3);
      Sl_rdComp : in std_logic_vector(0 to 3);
      Sl_rdDAck : in std_logic_vector(0 to 3);
      Sl_rdDBus : in std_logic_vector(0 to 255);
      Sl_rdWdAddr : in std_logic_vector(0 to 15);
      Sl_rearbitrate : in std_logic_vector(0 to 3);
      Sl_SSize : in std_logic_vector(0 to 7);
      Sl_wait : in std_logic_vector(0 to 3);
      Sl_wrBTerm : in std_logic_vector(0 to 3);
      Sl_wrComp : in std_logic_vector(0 to 3);
      Sl_wrDAck : in std_logic_vector(0 to 3);
      PLB_ABus : out std_logic_vector(0 to 31);
      PLB_BE : out std_logic_vector(0 to 7);
      PLB_MAddrAck : out std_logic_vector(0 to 1);
      PLB_MBusy : out std_logic_vector(0 to 1);
      PLB_MErr : out std_logic_vector(0 to 1);
      PLB_MRdBTerm : out std_logic_vector(0 to 1);
      PLB_MRdDAck : out std_logic_vector(0 to 1);
      PLB_MRdDBus : out std_logic_vector(0 to 127);
      PLB_MRdWdAddr : out std_logic_vector(0 to 7);
      PLB_MRearbitrate : out std_logic_vector(0 to 1);
      PLB_MWrBTerm : out std_logic_vector(0 to 1);
      PLB_MWrDAck : out std_logic_vector(0 to 1);
      PLB_MSSize : out std_logic_vector(0 to 3);
      PLB_PAValid : out std_logic;
      PLB_RNW : out std_logic;
      PLB_SAValid : out std_logic;
      PLB_abort : out std_logic;
      PLB_busLock : out std_logic;
      PLB_compress : out std_logic;
      PLB_guarded : out std_logic;
      PLB_lockErr : out std_logic;
      PLB_masterID : out std_logic_vector(0 to 0);
      PLB_MSize : out std_logic_vector(0 to 1);
      PLB_ordered : out std_logic;
      PLB_pendPri : out std_logic_vector(0 to 1);
      PLB_pendReq : out std_logic;
      PLB_rdBurst : out std_logic;
      PLB_rdPrim : out std_logic;
      PLB_reqPri : out std_logic_vector(0 to 1);
      PLB_size : out std_logic_vector(0 to 3);
      PLB_type : out std_logic_vector(0 to 2);
      PLB_wrBurst : out std_logic;
      PLB_wrDBus : out std_logic_vector(0 to 63);
      PLB_wrPrim : out std_logic;
      PLB_SaddrAck : out std_logic;
      PLB_SMErr : out std_logic_vector(0 to 1);
      PLB_SMBusy : out std_logic_vector(0 to 1);
      PLB_SrdBTerm : out std_logic;
      PLB_SrdComp : out std_logic;
      PLB_SrdDAck : out std_logic;
      PLB_SrdDBus : out std_logic_vector(0 to 63);
      PLB_SrdWdAddr : out std_logic_vector(0 to 3);
      PLB_Srearbitrate : out std_logic;
      PLB_Sssize : out std_logic_vector(0 to 1);
      PLB_Swait : out std_logic;
      PLB_SwrBTerm : out std_logic;
      PLB_SwrComp : out std_logic;
      PLB_SwrDAck : out std_logic;
      PLB2OPB_rearb : in std_logic_vector(0 to 3);
      ArbAddrVldReg : out std_logic;
      Bus_Error_Det : out std_logic
    );
  end component;

  attribute box_type of plb_wrapper: component is "black_box";

  component opb_wrapper is
    port (
      OPB_Clk : in std_logic;
      OPB_Rst : out std_logic;
      SYS_Rst : in std_logic;
      Debug_SYS_Rst : in std_logic;
      WDT_Rst : in std_logic;
      M_ABus : in std_logic_vector(0 to 31);
      M_BE : in std_logic_vector(0 to 3);
      M_beXfer : in std_logic_vector(0 to 0);
      M_busLock : in std_logic_vector(0 to 0);
      M_DBus : in std_logic_vector(0 to 31);
      M_DBusEn : in std_logic_vector(0 to 0);
      M_DBusEn32_63 : in std_logic_vector(0 to 0);
      M_dwXfer : in std_logic_vector(0 to 0);
      M_fwXfer : in std_logic_vector(0 to 0);
      M_hwXfer : in std_logic_vector(0 to 0);
      M_request : in std_logic_vector(0 to 0);
      M_RNW : in std_logic_vector(0 to 0);
      M_select : in std_logic_vector(0 to 0);
      M_seqAddr : in std_logic_vector(0 to 0);
      Sl_beAck : in std_logic_vector(0 to 5);
      Sl_DBus : in std_logic_vector(0 to 191);
      Sl_DBusEn : in std_logic_vector(0 to 5);
      Sl_DBusEn32_63 : in std_logic_vector(0 to 5);
      Sl_errAck : in std_logic_vector(0 to 5);
      Sl_dwAck : in std_logic_vector(0 to 5);
      Sl_fwAck : in std_logic_vector(0 to 5);
      Sl_hwAck : in std_logic_vector(0 to 5);
      Sl_retry : in std_logic_vector(0 to 5);
      Sl_toutSup : in std_logic_vector(0 to 5);
      Sl_xferAck : in std_logic_vector(0 to 5);
      OPB_MRequest : out std_logic_vector(0 to 0);
      OPB_ABus : out std_logic_vector(0 to 31);
      OPB_BE : out std_logic_vector(0 to 3);
      OPB_beXfer : out std_logic;
      OPB_beAck : out std_logic;
      OPB_busLock : out std_logic;
      OPB_rdDBus : out std_logic_vector(0 to 31);
      OPB_wrDBus : out std_logic_vector(0 to 31);
      OPB_DBus : out std_logic_vector(0 to 31);
      OPB_errAck : out std_logic;
      OPB_dwAck : out std_logic;
      OPB_dwXfer : out std_logic;
      OPB_fwAck : out std_logic;
      OPB_fwXfer : out std_logic;
      OPB_hwAck : out std_logic;
      OPB_hwXfer : out std_logic;
      OPB_MGrant : out std_logic_vector(0 to 0);
      OPB_pendReq : out std_logic_vector(0 to 0);
      OPB_retry : out std_logic;
      OPB_RNW : out std_logic;
      OPB_select : out std_logic;
      OPB_seqAddr : out std_logic;
      OPB_timeout : out std_logic;
      OPB_toutSup : out std_logic;
      OPB_xferAck : out std_logic
    );
  end component;

  attribute box_type of opb_wrapper: component is "black_box";

  component plb2opb_wrapper is
    port (
      PLB_Clk : in std_logic;
      OPB_Clk : in std_logic;
      PLB_Rst : in std_logic;
      OPB_Rst : in std_logic;
      Bus_Error_Det : out std_logic;
      BGI_Trans_Abort : out std_logic;
      BGO_dcrAck : out std_logic;
      BGO_dcrDBus : out std_logic_vector(0 to 31);
      DCR_ABus : in std_logic_vector(0 to 9);
      DCR_DBus : in std_logic_vector(0 to 31);
      DCR_Read : in std_logic;
      DCR_Write : in std_logic;
      BGO_addrAck : out std_logic;
      BGO_MErr : out std_logic_vector(0 to 1);
      BGO_MBusy : out std_logic_vector(0 to 1);
      BGO_rdBTerm : out std_logic;
      BGO_rdComp : out std_logic;
      BGO_rdDAck : out std_logic;
      BGO_rdDBus : out std_logic_vector(0 to 63);
      BGO_rdWdAddr : out std_logic_vector(0 to 3);
      BGO_rearbitrate : out std_logic;
      BGO_SSize : out std_logic_vector(0 to 1);
      BGO_wait : out std_logic;
      BGO_wrBTerm : out std_logic;
      BGO_wrComp : out std_logic;
      BGO_wrDAck : out std_logic;
      PLB_abort : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_busLock : in std_logic;
      PLB_compress : in std_logic;
      PLB_guarded : in std_logic;
      PLB_lockErr : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 0);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_ordered : in std_logic;
      PLB_PAValid : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_RNW : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_wrBurst : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrPrim : in std_logic;
      PLB2OPB_rearb : out std_logic;
      BGO_ABus : out std_logic_vector(0 to 31);
      BGO_BE : out std_logic_vector(0 to 3);
      BGO_busLock : out std_logic;
      BGO_DBus : out std_logic_vector(0 to 31);
      BGO_request : out std_logic;
      BGO_RNW : out std_logic;
      BGO_select : out std_logic;
      BGO_seqAddr : out std_logic;
      OPB_DBus : in std_logic_vector(0 to 31);
      OPB_errAck : in std_logic;
      OPB_MnGrant : in std_logic;
      OPB_retry : in std_logic;
      OPB_timeout : in std_logic;
      OPB_xferAck : in std_logic
    );
  end component;

  attribute box_type of plb2opb_wrapper: component is "black_box";

  component rs232_uart_1_wrapper is
    port (
      OPB_Clk : in std_logic;
      OPB_Rst : in std_logic;
      Interrupt : out std_logic;
      OPB_ABus : in std_logic_vector(0 to 31);
      OPB_BE : in std_logic_vector(0 to 3);
      OPB_RNW : in std_logic;
      OPB_select : in std_logic;
      OPB_seqAddr : in std_logic;
      OPB_DBus : in std_logic_vector(0 to 31);
      UART_DBus : out std_logic_vector(0 to 31);
      UART_errAck : out std_logic;
      UART_retry : out std_logic;
      UART_toutSup : out std_logic;
      UART_xferAck : out std_logic;
      RX : in std_logic;
      TX : out std_logic
    );
  end component;

  attribute box_type of rs232_uart_1_wrapper: component is "black_box";

  component sysace_compactflash_wrapper is
    port (
      OPB_Clk : in std_logic;
      OPB_Rst : in std_logic;
      OPB_ABus : in std_logic_vector(0 to 31);
      OPB_DBus : in std_logic_vector(0 to 31);
      Sln_DBus : out std_logic_vector(0 to 31);
      OPB_select : in std_logic;
      OPB_RNW : in std_logic;
      OPB_seqAddr : in std_logic;
      OPB_BE : in std_logic_vector(0 to 3);
      Sln_xferAck : out std_logic;
      Sln_errAck : out std_logic;
      Sln_toutSup : out std_logic;
      Sln_retry : out std_logic;
      SysACE_MPA : out std_logic_vector(6 downto 0);
      SysACE_CLK : in std_logic;
      SysACE_MPIRQ : in std_logic;
      SysACE_MPD_I : in std_logic_vector(15 downto 0);
      SysACE_MPD_O : out std_logic_vector(15 downto 0);
      SysACE_MPD_T : out std_logic_vector(15 downto 0);
      SysACE_CEN : out std_logic;
      SysACE_OEN : out std_logic;
      SysACE_WEN : out std_logic;
      SysACE_IRQ : out std_logic
    );
  end component;

  attribute box_type of sysace_compactflash_wrapper: component is "black_box";

  component leds_4bit_wrapper is
    port (
      OPB_ABus : in std_logic_vector(0 to 31);
      OPB_BE : in std_logic_vector(0 to 3);
      OPB_Clk : in std_logic;
      OPB_DBus : in std_logic_vector(0 to 31);
      OPB_RNW : in std_logic;
      OPB_Rst : in std_logic;
      OPB_select : in std_logic;
      OPB_seqAddr : in std_logic;
      Sln_DBus : out std_logic_vector(0 to 31);
      Sln_errAck : out std_logic;
      Sln_retry : out std_logic;
      Sln_toutSup : out std_logic;
      Sln_xferAck : out std_logic;
      IP2INTC_Irpt : out std_logic;
      GPIO_in : in std_logic_vector(0 to 3);
      GPIO_d_out : out std_logic_vector(0 to 3);
      GPIO_t_out : out std_logic_vector(0 to 3);
      GPIO2_in : in std_logic_vector(0 to 3);
      GPIO2_d_out : out std_logic_vector(0 to 3);
      GPIO2_t_out : out std_logic_vector(0 to 3);
      GPIO_IO_I : in std_logic_vector(0 to 3);
      GPIO_IO_O : out std_logic_vector(0 to 3);
      GPIO_IO_T : out std_logic_vector(0 to 3);
      GPIO2_IO_I : in std_logic_vector(0 to 3);
      GPIO2_IO_O : out std_logic_vector(0 to 3);
      GPIO2_IO_T : out std_logic_vector(0 to 3)
    );
  end component;

  attribute box_type of leds_4bit_wrapper: component is "black_box";

  component pushbuttons_5bit_wrapper is
    port (
      OPB_ABus : in std_logic_vector(0 to 31);
      OPB_BE : in std_logic_vector(0 to 3);
      OPB_Clk : in std_logic;
      OPB_DBus : in std_logic_vector(0 to 31);
      OPB_RNW : in std_logic;
      OPB_Rst : in std_logic;
      OPB_select : in std_logic;
      OPB_seqAddr : in std_logic;
      Sln_DBus : out std_logic_vector(0 to 31);
      Sln_errAck : out std_logic;
      Sln_retry : out std_logic;
      Sln_toutSup : out std_logic;
      Sln_xferAck : out std_logic;
      IP2INTC_Irpt : out std_logic;
      GPIO_in : in std_logic_vector(0 to 4);
      GPIO_d_out : out std_logic_vector(0 to 4);
      GPIO_t_out : out std_logic_vector(0 to 4);
      GPIO2_in : in std_logic_vector(0 to 4);
      GPIO2_d_out : out std_logic_vector(0 to 4);
      GPIO2_t_out : out std_logic_vector(0 to 4);
      GPIO_IO_I : in std_logic_vector(0 to 4);
      GPIO_IO_O : out std_logic_vector(0 to 4);
      GPIO_IO_T : out std_logic_vector(0 to 4);
      GPIO2_IO_I : in std_logic_vector(0 to 4);
      GPIO2_IO_O : out std_logic_vector(0 to 4);
      GPIO2_IO_T : out std_logic_vector(0 to 4)
    );
  end component;

  attribute box_type of pushbuttons_5bit_wrapper: component is "black_box";
  
  component ddr_512mb_64mx64_rank2_row13_col10_cl2_5_wrapper is
    port (
      PLB_Clk : in std_logic;
      PLB_Clk_n : in std_logic;
      Clk90_in : in std_logic;
      Clk90_in_n : in std_logic;
      DDR_Clk90_in : in std_logic;
      DDR_Clk90_in_n : in std_logic;
      PLB_Rst : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 0);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_compress : in std_logic;
      PLB_guarded : in std_logic;
      PLB_ordered : in std_logic;
      PLB_lockErr : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_pendReq : in std_logic;
      PLB_pendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      Sl_addrAck : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 1);
      Sl_MErr : out std_logic_vector(0 to 1);
      IP2INTC_Irpt : out std_logic;
      DDR_Clk : out std_logic_vector(0 to 3);
      DDR_Clkn : out std_logic_vector(0 to 3);
      DDR_CKE : out std_logic_vector(0 to 1);
      DDR_CSn : out std_logic_vector(0 to 1);
      DDR_RASn : out std_logic;
      DDR_CASn : out std_logic;
      DDR_WEn : out std_logic;
      DDR_DM : out std_logic_vector(0 to 7);
      DDR_BankAddr : out std_logic_vector(0 to 1);
      DDR_Addr : out std_logic_vector(0 to 12);
      DDR_DM_ECC : out std_logic;
      DDR_Init_done : out std_logic;
      DDR_DQ_I : in std_logic_vector(0 to 63);
      DDR_DQ_O : out std_logic_vector(0 to 63);
      DDR_DQ_T : out std_logic_vector(0 to 63);
      DDR_DQS_I : in std_logic_vector(0 to 7);
      DDR_DQS_O : out std_logic_vector(0 to 7);
      DDR_DQS_T : out std_logic_vector(0 to 7);
      DDR_DQ_ECC_I : in std_logic_vector(0 to 6);
      DDR_DQ_ECC_O : out std_logic_vector(0 to 6);
      DDR_DQ_ECC_T : out std_logic_vector(0 to 6);
      DDR_DQS_ECC_I : in std_logic;
      DDR_DQS_ECC_O : out std_logic;
      DDR_DQS_ECC_T : out std_logic
    );
  end component;

  attribute box_type of ddr_512mb_64mx64_rank2_row13_col10_cl2_5_wrapper: component is "black_box";

  component plb_bram_if_cntlr_1_wrapper is
    port (
      plb_clk : in std_logic;
      plb_rst : in std_logic;
      plb_abort : in std_logic;
      plb_abus : in std_logic_vector(0 to 31);
      plb_be : in std_logic_vector(0 to 7);
      plb_buslock : in std_logic;
      plb_compress : in std_logic;
      plb_guarded : in std_logic;
      plb_lockerr : in std_logic;
      plb_masterid : in std_logic_vector(0 to 0);
      plb_msize : in std_logic_vector(0 to 1);
      plb_ordered : in std_logic;
      plb_pavalid : in std_logic;
      plb_rnw : in std_logic;
      plb_size : in std_logic_vector(0 to 3);
      plb_type : in std_logic_vector(0 to 2);
      sl_addrack : out std_logic;
      sl_mbusy : out std_logic_vector(0 to 1);
      sl_merr : out std_logic_vector(0 to 1);
      sl_rearbitrate : out std_logic;
      sl_ssize : out std_logic_vector(0 to 1);
      sl_wait : out std_logic;
      plb_rdprim : in std_logic;
      plb_savalid : in std_logic;
      plb_wrprim : in std_logic;
      plb_wrburst : in std_logic;
      plb_wrdbus : in std_logic_vector(0 to 63);
      sl_wrbterm : out std_logic;
      sl_wrcomp : out std_logic;
      sl_wrdack : out std_logic;
      plb_rdburst : in std_logic;
      sl_rdbterm : out std_logic;
      sl_rdcomp : out std_logic;
      sl_rddack : out std_logic;
      sl_rddbus : out std_logic_vector(0 to 63);
      sl_rdwdaddr : out std_logic_vector(0 to 3);
      plb_pendreq : in std_logic;
      plb_pendpri : in std_logic_vector(0 to 1);
      plb_reqpri : in std_logic_vector(0 to 1);
      bram_rst : out std_logic;
      bram_clk : out std_logic;
      bram_en : out std_logic;
      bram_wen : out std_logic_vector(0 to 7);
      bram_addr : out std_logic_vector(0 to 31);
      bram_din : in std_logic_vector(0 to 63);
      bram_dout : out std_logic_vector(0 to 63)
    );
  end component;

  attribute box_type of plb_bram_if_cntlr_1_wrapper: component is "black_box";

  component plb_bram_if_cntlr_1_bram_wrapper is
    port (
      BRAM_Rst_A : in std_logic;
      BRAM_Clk_A : in std_logic;
      BRAM_EN_A : in std_logic;
      BRAM_WEN_A : in std_logic_vector(0 to 7);
      BRAM_Addr_A : in std_logic_vector(0 to 31);
      BRAM_Din_A : out std_logic_vector(0 to 63);
      BRAM_Dout_A : in std_logic_vector(0 to 63);
      BRAM_Rst_B : in std_logic;
      BRAM_Clk_B : in std_logic;
      BRAM_EN_B : in std_logic;
      BRAM_WEN_B : in std_logic_vector(0 to 7);
      BRAM_Addr_B : in std_logic_vector(0 to 31);
      BRAM_Din_B : out std_logic_vector(0 to 63);
      BRAM_Dout_B : in std_logic_vector(0 to 63)
    );
  end component;

  attribute box_type of plb_bram_if_cntlr_1_bram_wrapper: component is "black_box";

  component sysclk_inv_wrapper is
    port (
      Op1 : in std_logic_vector(0 to 0);
      Op2 : in std_logic_vector(0 to 0);
      Res : out std_logic_vector(0 to 0)
    );
  end component;

  attribute box_type of sysclk_inv_wrapper: component is "black_box";

  component clk90_inv_wrapper is
    port (
      Op1 : in std_logic_vector(0 to 0);
      Op2 : in std_logic_vector(0 to 0);
      Res : out std_logic_vector(0 to 0)
    );
  end component;

  attribute box_type of clk90_inv_wrapper: component is "black_box";

  component ddr_clk90_inv_wrapper is
    port (
      Op1 : in std_logic_vector(0 to 0);
      Op2 : in std_logic_vector(0 to 0);
      Res : out std_logic_vector(0 to 0)
    );
  end component;

  attribute box_type of ddr_clk90_inv_wrapper: component is "black_box";

  component dcm_0_wrapper is
    port (
      RST : in std_logic;
      CLKIN : in std_logic;
      CLKFB : in std_logic;
      PSEN : in std_logic;
      PSINCDEC : in std_logic;
      PSCLK : in std_logic;
      DSSEN : in std_logic;
      CLK0 : out std_logic;
      CLK90 : out std_logic;
      CLK180 : out std_logic;
      CLK270 : out std_logic;
      CLKDV : out std_logic;
      CLK2X : out std_logic;
      CLK2X180 : out std_logic;
      CLKFX : out std_logic;
      CLKFX180 : out std_logic;
      STATUS : out std_logic_vector(7 downto 0);
      LOCKED : out std_logic;
      PSDONE : out std_logic
    );
  end component;
  
  attribute box_type of dcm_0_wrapper: component is "black_box";
  
  component dcm_1_wrapper is
    port (
      RST : in std_logic;
      CLKIN : in std_logic;
      CLKFB : in std_logic;
      PSEN : in std_logic;
      PSINCDEC : in std_logic;
      PSCLK : in std_logic;
      DSSEN : in std_logic;
      CLK0 : out std_logic;
      CLK90 : out std_logic;
      CLK180 : out std_logic;
      CLK270 : out std_logic;
      CLKDV : out std_logic;
      CLK2X : out std_logic;
      CLK2X180 : out std_logic;
      CLKFX : out std_logic;
      CLKFX180 : out std_logic;
      STATUS : out std_logic_vector(7 downto 0);
      LOCKED : out std_logic;
      PSDONE : out std_logic
    );
  end component;

  attribute box_type of dcm_1_wrapper: component is "black_box";

  component opb_hwicap_0_wrapper is
    port (
      OPB_Clk : in std_logic;
      OPB_Rst : in std_logic;
      OPB_ABus : in std_logic_vector(0 to 31);
      OPB_DBus : in std_logic_vector(0 to 31);
      Sln_DBus : out std_logic_vector(0 to 31);
      OPB_BE : in std_logic_vector(0 to 3);
      OPB_select : in std_logic;
      OPB_RNW : in std_logic;
      OPB_seqAddr : in std_logic;
      Sln_xferAck : out std_logic;
      Sln_errAck : out std_logic;
      Sln_toutSup : out std_logic;
      Sln_retry : out std_logic
    );
  end component;

  attribute box_type of opb_hwicap_0_wrapper: component is "black_box";

  component opb_gpio_0_wrapper is
    port (
      OPB_ABus : in std_logic_vector(0 to 31);
      OPB_BE : in std_logic_vector(0 to 3);
      OPB_Clk : in std_logic;
      OPB_DBus : in std_logic_vector(0 to 31);
      OPB_RNW : in std_logic;
      OPB_Rst : in std_logic;
      OPB_select : in std_logic;
      OPB_seqAddr : in std_logic;
      Sln_DBus : out std_logic_vector(0 to 31);
      Sln_errAck : out std_logic;
      Sln_retry : out std_logic;
      Sln_toutSup : out std_logic;
      Sln_xferAck : out std_logic;
      IP2INTC_Irpt : out std_logic;
      GPIO_in : in std_logic_vector(0 to 7);
      GPIO_d_out : out std_logic_vector(0 to 7);
      GPIO_t_out : out std_logic_vector(0 to 7);
      GPIO2_in : in std_logic_vector(0 to 7);
      GPIO2_d_out : out std_logic_vector(0 to 7);
      GPIO2_t_out : out std_logic_vector(0 to 7);
      GPIO_IO_I : in std_logic_vector(0 to 7);
      GPIO_IO_O : out std_logic_vector(0 to 7);
      GPIO_IO_T : out std_logic_vector(0 to 7);
      GPIO2_IO_I : in std_logic_vector(0 to 7);
      GPIO2_IO_O : out std_logic_vector(0 to 7);
      GPIO2_IO_T : out std_logic_vector(0 to 7)
    );
  end component;

  attribute box_type of opb_gpio_0_wrapper: component is "black_box";
  
  component math_0_wrapper is
    port (
      PLB_Clk : in std_logic;
      PLB_Rst : in std_logic;
      Sl_addrAck : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 1);
      Sl_MErr : out std_logic_vector(0 to 1);
      Sl_rdBTerm : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdDAck : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 63);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rearbitrate : out std_logic;
      Sl_SSize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrDAck : out std_logic;
      PLB_abort : in std_logic;
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_BE : in std_logic_vector(0 to 7);
      PLB_busLock : in std_logic;
      PLB_compress : in std_logic;
      PLB_guarded : in std_logic;
      PLB_lockErr : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 0);
      PLB_MSize : in std_logic_vector(0 to 1);
      PLB_ordered : in std_logic;
      PLB_PAValid : in std_logic;
      PLB_pendPri : in std_logic_vector(0 to 1);
      PLB_pendReq : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_reqPri : in std_logic_vector(0 to 1);
      PLB_RNW : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_wrBurst : in std_logic;
      PLB_wrDBus : in std_logic_vector(0 to 63);
      PLB_wrPrim : in std_logic
    );
  end component;

  attribute box_type of math_0_wrapper: component is "black_box";
  
  
-----------------------------------------------------
-- added busmacro declaration
-----------------------------------------------------

-- For connection from bus to peripheral use async macro.

  component busmacro_vector8_xc2vp_l2r_async_narrow is
    port (
	macro_in  : in  std_logic_vector(7 downto 0);
	macro_out : out std_logic_vector(7 downto 0)
    );
  end component;
  
-- For connection from peripheral to bus use async macro with 
-- enable. The macro should be disabled during reconfiguration 
-- to avoid invalid signals on the bus.

  component busmacro_vector8_xc2vp_r2l_async_enable_narrow is
    port (
	macro_in  : in  std_logic_vector(7 downto 0);
	enable : in  std_logic_vector(7 downto 0);
	macro_out : out std_logic_vector(7 downto 0)
    );
  end component;
  
-----------------------------------------------------

  component IBUF is
    port (
      I : in std_logic;
      O : out std_logic
    );
  end component;

  component OBUF is
    port (
      I : in std_logic;
      O : out std_logic
    );
  end component;

  component IOBUF is
    port (
      I : in std_logic;
      IO : inout std_logic;
      O : out std_logic;
      T : in std_logic
    );
  end component;

  component IBUFG is
    port (
      I : in std_logic;
      O : out std_logic
    );
  end component;
  
  component BUFG is
    port (
      I : in std_logic;
      O : out std_logic
    );
  end component;

  -- Internal signals

  signal C405RSTCHIPRESETREQ : std_logic;
  signal C405RSTCORERESETREQ : std_logic;
  signal C405RSTSYSRESETREQ : std_logic;
  signal RSTC405RESETCHIP : std_logic;
  signal RSTC405RESETCORE : std_logic;
  signal RSTC405RESETSYS : std_logic;
  signal clk_90_n_s : std_logic_vector(0 to 0);
  signal clk_90_s : std_logic_vector(0 to 0);
  signal dcm_0_lock : std_logic;
  signal dcm_1_FB : std_logic;
  signal dcm_1_lock : std_logic;
  signal dcm_clk_s : std_logic;
  signal ddr_clk_90_n_s : std_logic_vector(0 to 0);
  signal ddr_clk_90_s : std_logic_vector(0 to 0);
  signal ddr_clk_feedback_out_s : std_logic;
  signal ddr_feedback_s : std_logic;
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr : std_logic_vector(0 to 12);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_BankAddr : std_logic_vector(0 to 1);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CASn : std_logic;
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CKE : std_logic_vector(0 to 1);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CSn : std_logic_vector(0 to 1);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk : std_logic_vector(0 to 2);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn : std_logic_vector(0 to 2);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM : std_logic_vector(0 to 7);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I : std_logic_vector(0 to 7);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O : std_logic_vector(0 to 7);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T : std_logic_vector(0 to 7);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I : std_logic_vector(0 to 63);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O : std_logic_vector(0 to 63);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T : std_logic_vector(0 to 63);
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_RASn : std_logic;
  signal fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_WEn : std_logic;
  signal fpga_0_LEDs_4Bit_GPIO_IO_I : std_logic_vector(0 to 3);
  signal fpga_0_LEDs_4Bit_GPIO_IO_O : std_logic_vector(0 to 3);
  signal fpga_0_LEDs_4Bit_GPIO_IO_T : std_logic_vector(0 to 3);
  signal fpga_0_PushButtons_5Bit_GPIO_IO_I : std_logic_vector(0 to 4);
  signal fpga_0_PushButtons_5Bit_GPIO_IO_O : std_logic_vector(0 to 4);
  signal fpga_0_PushButtons_5Bit_GPIO_IO_T : std_logic_vector(0 to 4);
  signal fpga_0_RS232_Uart_1_RX : std_logic;
  signal fpga_0_RS232_Uart_1_TX : std_logic;
  signal fpga_0_SysACE_CompactFlash_SysACE_CEN : std_logic;
  signal fpga_0_SysACE_CompactFlash_SysACE_CLK : std_logic;
  signal fpga_0_SysACE_CompactFlash_SysACE_MPA : std_logic_vector(6 downto 0);
  signal fpga_0_SysACE_CompactFlash_SysACE_MPD_I : std_logic_vector(15 downto 0);
  signal fpga_0_SysACE_CompactFlash_SysACE_MPD_O : std_logic_vector(15 downto 0);
  signal fpga_0_SysACE_CompactFlash_SysACE_MPD_T : std_logic_vector(15 downto 0);
  signal fpga_0_SysACE_CompactFlash_SysACE_MPIRQ : std_logic;
  signal fpga_0_SysACE_CompactFlash_SysACE_OEN : std_logic;
  signal fpga_0_SysACE_CompactFlash_SysACE_WEN : std_logic;
  signal jtagppc_0_0_C405JTGTDO : std_logic;
  signal jtagppc_0_0_C405JTGTDOEN : std_logic;
  signal jtagppc_0_0_JTGC405TCK : std_logic;
  signal jtagppc_0_0_JTGC405TDI : std_logic;
  signal jtagppc_0_0_JTGC405TMS : std_logic;
  signal jtagppc_0_0_JTGC405TRSTNEG : std_logic;
  signal jtagppc_0_1_C405JTGTDO : std_logic;
  signal jtagppc_0_1_C405JTGTDOEN : std_logic;
  signal jtagppc_0_1_JTGC405TCK : std_logic;
  signal jtagppc_0_1_JTGC405TDI : std_logic;
  signal jtagppc_0_1_JTGC405TMS : std_logic;
  signal jtagppc_0_1_JTGC405TRSTNEG : std_logic;
  signal net_gnd0 : std_logic;
  signal net_gnd1 : std_logic_vector(0 to 0);
  signal net_gnd10 : std_logic_vector(0 to 9);
  signal net_gnd2 : std_logic_vector(0 to 1);
  signal net_gnd32 : std_logic_vector(0 to 31);
  signal net_gnd4 : std_logic_vector(0 to 3);
  signal net_gnd5 : std_logic_vector(0 to 4);
  signal net_gnd6 : std_logic_vector(0 to 5);
  signal net_gnd64 : std_logic_vector(0 to 63);
  signal net_gnd7 : std_logic_vector(0 to 6);
  signal net_gnd8 : std_logic_vector(0 to 7);
  signal net_vcc0 : std_logic;
  signal net_vcc1 : std_logic_vector(0 to 0);
  signal net_vcc6 : std_logic_vector(0 to 5);
  signal opb_M_ABus : std_logic_vector(0 to 31);
  signal opb_M_BE : std_logic_vector(0 to 3);
  signal opb_M_DBus : std_logic_vector(0 to 31);
  signal opb_M_RNW : std_logic_vector(0 to 0);
  signal opb_M_busLock : std_logic_vector(0 to 0);
  signal opb_M_request : std_logic_vector(0 to 0);
  signal opb_M_select : std_logic_vector(0 to 0);
  signal opb_M_seqAddr : std_logic_vector(0 to 0);
  signal opb_OPB_ABus : std_logic_vector(0 to 31);
  signal opb_OPB_BE : std_logic_vector(0 to 3);
  signal opb_OPB_DBus : std_logic_vector(0 to 31);
  signal opb_OPB_MGrant : std_logic_vector(0 to 0);
  signal opb_OPB_RNW : std_logic;
  signal opb_OPB_Rst : std_logic;
  signal opb_OPB_errAck : std_logic;
  signal opb_OPB_retry : std_logic;
  signal opb_OPB_select : std_logic;
  signal opb_OPB_seqAddr : std_logic;
  signal opb_OPB_timeout : std_logic;
  signal opb_OPB_xferAck : std_logic;
  signal opb_Sl_DBus : std_logic_vector(0 to 191);
  signal opb_Sl_errAck : std_logic_vector(0 to 5);
  signal opb_Sl_retry : std_logic_vector(0 to 5);
  signal opb_Sl_toutSup : std_logic_vector(0 to 5);
  signal opb_Sl_xferAck : std_logic_vector(0 to 5);
  signal pgassign1 : std_logic_vector(0 to 3);
  signal pgassign2 : std_logic_vector(0 to 3);
  signal pgassign3 : std_logic_vector(0 to 0);
  signal plb_M_ABus : std_logic_vector(0 to 63);
  signal plb_M_BE : std_logic_vector(0 to 15);
  signal plb_M_MSize : std_logic_vector(0 to 3);
  signal plb_M_RNW : std_logic_vector(0 to 1);
  signal plb_M_abort : std_logic_vector(0 to 1);
  signal plb_M_busLock : std_logic_vector(0 to 1);
  signal plb_M_compress : std_logic_vector(0 to 1);
  signal plb_M_guarded : std_logic_vector(0 to 1);
  signal plb_M_lockErr : std_logic_vector(0 to 1);
  signal plb_M_ordered : std_logic_vector(0 to 1);
  signal plb_M_priority : std_logic_vector(0 to 3);
  signal plb_M_rdBurst : std_logic_vector(0 to 1);
  signal plb_M_request : std_logic_vector(0 to 1);
  signal plb_M_size : std_logic_vector(0 to 7);
  signal plb_M_type : std_logic_vector(0 to 5);
  signal plb_M_wrBurst : std_logic_vector(0 to 1);
  signal plb_M_wrDBus : std_logic_vector(0 to 127);
  signal plb_PLB2OPB_rearb : std_logic_vector(0 to 3);
  signal plb_PLB_ABus : std_logic_vector(0 to 31);
  signal plb_PLB_BE : std_logic_vector(0 to 7);
  signal plb_PLB_MAddrAck : std_logic_vector(0 to 1);
  signal plb_PLB_MBusy : std_logic_vector(0 to 1);
  signal plb_PLB_MErr : std_logic_vector(0 to 1);
  signal plb_PLB_MRdBTerm : std_logic_vector(0 to 1);
  signal plb_PLB_MRdDAck : std_logic_vector(0 to 1);
  signal plb_PLB_MRdDBus : std_logic_vector(0 to 127);
  signal plb_PLB_MRdWdAddr : std_logic_vector(0 to 7);
  signal plb_PLB_MRearbitrate : std_logic_vector(0 to 1);
  signal plb_PLB_MSSize : std_logic_vector(0 to 3);
  signal plb_PLB_MSize : std_logic_vector(0 to 1);
  signal plb_PLB_MWrBTerm : std_logic_vector(0 to 1);
  signal plb_PLB_MWrDAck : std_logic_vector(0 to 1);
  signal plb_PLB_PAValid : std_logic;
  signal plb_PLB_RNW : std_logic;
  signal plb_PLB_Rst : std_logic;
  signal plb_PLB_SAValid : std_logic;
  signal plb_PLB_SMBusy : std_logic_vector(0 to 1);
  signal plb_PLB_SMErr : std_logic_vector(0 to 1);
  signal plb_PLB_abort : std_logic;
  signal plb_PLB_busLock : std_logic;
  signal plb_PLB_compress : std_logic;
  signal plb_PLB_guarded : std_logic;
  signal plb_PLB_lockErr : std_logic;
  signal plb_PLB_masterID : std_logic_vector(0 to 0);
  signal plb_PLB_ordered : std_logic;
  signal plb_PLB_pendPri : std_logic_vector(0 to 1);
  signal plb_PLB_pendReq : std_logic;
  signal plb_PLB_rdBurst : std_logic;
  signal plb_PLB_rdPrim : std_logic;
  signal plb_PLB_reqPri : std_logic_vector(0 to 1);
  signal plb_PLB_size : std_logic_vector(0 to 3);
  signal plb_PLB_type : std_logic_vector(0 to 2);
  signal plb_PLB_wrBurst : std_logic;
  signal plb_PLB_wrDBus : std_logic_vector(0 to 63);
  signal plb_PLB_wrPrim : std_logic;
  signal plb_Sl_MBusy : std_logic_vector(0 to 7);
  signal plb_Sl_MErr : std_logic_vector(0 to 7);
  signal plb_Sl_SSize : std_logic_vector(0 to 7);
  signal plb_Sl_addrAck : std_logic_vector(0 to 3);
  signal plb_Sl_rdBTerm : std_logic_vector(0 to 3);
  signal plb_Sl_rdComp : std_logic_vector(0 to 3);
  signal plb_Sl_rdDAck : std_logic_vector(0 to 3);
  signal plb_Sl_rdDBus : std_logic_vector(0 to 255);
  signal plb_Sl_rdWdAddr : std_logic_vector(0 to 15);
  signal plb_Sl_rearbitrate : std_logic_vector(0 to 3);
  signal plb_Sl_wait : std_logic_vector(0 to 3);
  signal plb_Sl_wrBTerm : std_logic_vector(0 to 3);
  signal plb_Sl_wrComp : std_logic_vector(0 to 3);
  signal plb_Sl_wrDAck : std_logic_vector(0 to 3);
  signal plb_bram_if_cntlr_1_port_BRAM_Addr : std_logic_vector(0 to 31);
  signal plb_bram_if_cntlr_1_port_BRAM_Clk : std_logic;
  signal plb_bram_if_cntlr_1_port_BRAM_Din : std_logic_vector(0 to 63);
  signal plb_bram_if_cntlr_1_port_BRAM_Dout : std_logic_vector(0 to 63);
  signal plb_bram_if_cntlr_1_port_BRAM_EN : std_logic;
  signal plb_bram_if_cntlr_1_port_BRAM_Rst : std_logic;
  signal plb_bram_if_cntlr_1_port_BRAM_WEN : std_logic_vector(0 to 7);
  signal proc_clk_s : std_logic;
  signal sys_bus_reset : std_logic_vector(0 to 0);
  signal sys_clk_n_s : std_logic_vector(0 to 0);
  signal sys_clk_s : std_logic_vector(0 to 0);
  signal sys_rst_s : std_logic;

-----------------------------------------------------
-- Signals to connect peripheral to macro. The original
-- signals are used to connect the bus to the macros.
-----------------------------------------------------

  signal plb_PLB_Rst_module : std_logic;
  signal plb_Sl_addrAck_module : std_logic_vector(3 to 3);
  signal plb_Sl_MBusy_module : std_logic_vector(6 to 7);
  signal plb_Sl_MErr_module : std_logic_vector(6 to 7);
  signal plb_Sl_rdBTerm_module : std_logic_vector(3 to 3);
  signal plb_Sl_rdComp_module : std_logic_vector(3 to 3);
  signal plb_Sl_rdDAck_module : std_logic_vector(3 to 3);
  signal plb_Sl_rdDBus_module : std_logic_vector(192 to 255);
  signal plb_Sl_rdWdAddr_module : std_logic_vector(12 to 15);
  signal plb_Sl_rearbitrate_module : std_logic_vector(3 to 3);
  signal plb_Sl_SSize_module : std_logic_vector(6 to 7);
  signal plb_Sl_wait_module : std_logic_vector(3 to 3);
  signal plb_Sl_wrBTerm_module : std_logic_vector(3 to 3);
  signal plb_Sl_wrComp_module : std_logic_vector(3 to 3);
  signal plb_Sl_wrDAck_module : std_logic_vector(3 to 3);
  signal plb_PLB_abort_module : std_logic;
  signal plb_PLB_ABus_module : std_logic_vector(0 to 31);
  signal plb_PLB_BE_module : std_logic_vector(0 to 7);
  signal plb_PLB_busLock_module : std_logic;
  signal plb_PLB_compress_module : std_logic;
  signal plb_PLB_guarded_module : std_logic;
  signal plb_PLB_lockErr_module : std_logic;
  signal plb_PLB_masterID_module : std_logic_vector(0 to 0);
  signal plb_PLB_MSize_module : std_logic_vector(0 to 1);
  signal plb_PLB_ordered_module : std_logic;
  signal plb_PLB_PAValid_module : std_logic;
  signal plb_PLB_pendPri_module : std_logic_vector(0 to 1);
  signal plb_PLB_pendReq_module : std_logic;
  signal plb_PLB_rdBurst_module : std_logic;
  signal plb_PLB_rdPrim_module : std_logic;
  signal plb_PLB_reqPri_module : std_logic_vector(0 to 1);
  signal plb_PLB_RNW_module : std_logic;
  signal plb_PLB_SAValid_module : std_logic;
  signal plb_PLB_size_module : std_logic_vector(0 to 3);
  signal plb_PLB_type_module : std_logic_vector(0 to 2);
  signal plb_PLB_wrBurst_module : std_logic;
  signal plb_PLB_wrDBus_module : std_logic_vector(0 to 63);
  signal plb_PLB_wrPrim_module : std_logic;

-----------------------------------------------------

  -- additional signals for macro enable

  signal gpio_out : std_logic_vector(0 to 7);
  signal macro_enable : std_logic_vector(0 to 7);
  
  -- clock signal for additional buffer after DCM	
 
  signal dcm_out_clk :std_logic;
-----------------------------------------------------


begin

  -- Internal assignments

  plb_PLB2OPB_rearb(1 to 1) <= B"0";
  plb_PLB2OPB_rearb(2 to 2) <= B"0";
  plb_PLB2OPB_rearb(3 to 3) <= B"0";
  pgassign3(0 to 0) <= B"0";
  fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk(0 to 2) <= pgassign1(0 to 2);
  ddr_clk_feedback_out_s <= pgassign1(3);
  fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn(0 to 2) <= pgassign2(0 to 2);
  net_gnd0 <= '0';
  net_gnd1(0 to 0) <= B"0";
  net_gnd10(0 to 9) <= B"0000000000";
  net_gnd2(0 to 1) <= B"00";
  net_gnd32(0 to 31) <= B"00000000000000000000000000000000";
  net_gnd4(0 to 3) <= B"0000";
  net_gnd5(0 to 4) <= B"00000";
  net_gnd6(0 to 5) <= B"000000";
  net_gnd64(0 to 63) <= B"0000000000000000000000000000000000000000000000000000000000000000";
  net_gnd7(0 to 6) <= B"0000000";
  net_gnd8(0 to 7) <= B"00000000";
  net_vcc0 <= '1';
  net_vcc1(0 to 0) <= B"1";
  net_vcc6(0 to 5) <= B"111111";
  
  macro_enable(0) <= gpio_out(0);
  macro_enable(1) <= gpio_out(0);
  macro_enable(2) <= gpio_out(0);
  macro_enable(3) <= gpio_out(0);
  macro_enable(4) <= gpio_out(0);
  macro_enable(5) <= gpio_out(0);
  macro_enable(6) <= gpio_out(0);
  macro_enable(7) <= gpio_out(0);
  
  ppc405_0 : ppc405_0_wrapper
    port map (
      C405CPMCORESLEEPREQ => open,
      C405CPMMSRCE => open,
      C405CPMMSREE => open,
      C405CPMTIMERIRQ => open,
      C405CPMTIMERRESETREQ => open,
      C405XXXMACHINECHECK => open,
      CPMC405CLOCK => proc_clk_s,
      CPMC405CORECLKINACTIVE => net_gnd0,
      CPMC405CPUCLKEN => net_vcc0,
      CPMC405JTAGCLKEN => net_vcc0,
      CPMC405TIMERCLKEN => net_vcc0,
      CPMC405TIMERTICK => net_vcc0,
      MCBCPUCLKEN => net_vcc0,
      MCBTIMEREN => net_vcc0,
      MCPPCRST => net_vcc0,
      PLBCLK => sys_clk_s(0),
      DCRCLK => net_gnd0,
      C405RSTCHIPRESETREQ => C405RSTCHIPRESETREQ,
      C405RSTCORERESETREQ => C405RSTCORERESETREQ,
      C405RSTSYSRESETREQ => C405RSTSYSRESETREQ,
      RSTC405RESETCHIP => RSTC405RESETCHIP,
      RSTC405RESETCORE => RSTC405RESETCORE,
      RSTC405RESETSYS => RSTC405RESETSYS,
      C405PLBICUABUS => plb_M_ABus(32 to 63),
      C405PLBICUBE => plb_M_BE(8 to 15),
      C405PLBICURNW => plb_M_RNW(1),
      C405PLBICUABORT => plb_M_abort(1),
      C405PLBICUBUSLOCK => plb_M_busLock(1),
      C405PLBICUU0ATTR => plb_M_compress(1),
      C405PLBICUGUARDED => plb_M_guarded(1),
      C405PLBICULOCKERR => plb_M_lockErr(1),
      C405PLBICUMSIZE => plb_M_MSize(2 to 3),
      C405PLBICUORDERED => plb_M_ordered(1),
      C405PLBICUPRIORITY => plb_M_priority(2 to 3),
      C405PLBICURDBURST => plb_M_rdBurst(1),
      C405PLBICUREQUEST => plb_M_request(1),
      C405PLBICUSIZE => plb_M_size(4 to 7),
      C405PLBICUTYPE => plb_M_type(3 to 5),
      C405PLBICUWRBURST => plb_M_wrBurst(1),
      C405PLBICUWRDBUS => plb_M_wrDBus(64 to 127),
      C405PLBICUCACHEABLE => open,
      PLBC405ICUADDRACK => plb_PLB_MAddrAck(1),
      PLBC405ICUBUSY => plb_PLB_MBusy(1),
      PLBC405ICUERR => plb_PLB_MErr(1),
      PLBC405ICURDBTERM => plb_PLB_MRdBTerm(1),
      PLBC405ICURDDACK => plb_PLB_MRdDAck(1),
      PLBC405ICURDDBUS => plb_PLB_MRdDBus(64 to 127),
      PLBC405ICURDWDADDR => plb_PLB_MRdWdAddr(4 to 7),
      PLBC405ICUREARBITRATE => plb_PLB_MRearbitrate(1),
      PLBC405ICUWRBTERM => plb_PLB_MWrBTerm(1),
      PLBC405ICUWRDACK => plb_PLB_MWrDAck(1),
      PLBC405ICUSSIZE => plb_PLB_MSSize(2 to 3),
      PLBC405ICUSERR => plb_PLB_SMErr(1),
      PLBC405ICUSBUSYS => plb_PLB_SMBusy(1),
      C405PLBDCUABUS => plb_M_ABus(0 to 31),
      C405PLBDCUBE => plb_M_BE(0 to 7),
      C405PLBDCURNW => plb_M_RNW(0),
      C405PLBDCUABORT => plb_M_abort(0),
      C405PLBDCUBUSLOCK => plb_M_busLock(0),
      C405PLBDCUU0ATTR => plb_M_compress(0),
      C405PLBDCUGUARDED => plb_M_guarded(0),
      C405PLBDCULOCKERR => plb_M_lockErr(0),
      C405PLBDCUMSIZE => plb_M_MSize(0 to 1),
      C405PLBDCUORDERED => plb_M_ordered(0),
      C405PLBDCUPRIORITY => plb_M_priority(0 to 1),
      C405PLBDCURDBURST => plb_M_rdBurst(0),
      C405PLBDCUREQUEST => plb_M_request(0),
      C405PLBDCUSIZE => plb_M_size(0 to 3),
      C405PLBDCUTYPE => plb_M_type(0 to 2),
      C405PLBDCUWRBURST => plb_M_wrBurst(0),
      C405PLBDCUWRDBUS => plb_M_wrDBus(0 to 63),
      C405PLBDCUCACHEABLE => open,
      C405PLBDCUWRITETHRU => open,
      PLBC405DCUADDRACK => plb_PLB_MAddrAck(0),
      PLBC405DCUBUSY => plb_PLB_MBusy(0),
      PLBC405DCUERR => plb_PLB_MErr(0),
      PLBC405DCURDBTERM => plb_PLB_MRdBTerm(0),
      PLBC405DCURDDACK => plb_PLB_MRdDAck(0),
      PLBC405DCURDDBUS => plb_PLB_MRdDBus(0 to 63),
      PLBC405DCURDWDADDR => plb_PLB_MRdWdAddr(0 to 3),
      PLBC405DCUREARBITRATE => plb_PLB_MRearbitrate(0),
      PLBC405DCUWRBTERM => plb_PLB_MWrBTerm(0),
      PLBC405DCUWRDACK => plb_PLB_MWrDAck(0),
      PLBC405DCUSSIZE => plb_PLB_MSSize(0 to 1),
      PLBC405DCUSERR => plb_PLB_SMErr(0),
      PLBC405DCUSBUSYS => plb_PLB_SMBusy(0),
      BRAMDSOCMCLK => net_gnd0,
      BRAMDSOCMRDDBUS => net_gnd32,
      DSARCVALUE => net_gnd8,
      DSCNTLVALUE => net_gnd8,
      DSOCMBRAMABUS => open,
      DSOCMBRAMBYTEWRITE => open,
      DSOCMBRAMEN => open,
      DSOCMBRAMWRDBUS => open,
      DSOCMBUSY => open,
      BRAMISOCMCLK => net_gnd0,
      BRAMISOCMRDDBUS => net_gnd64,
      ISARCVALUE => net_gnd8,
      ISCNTLVALUE => net_gnd8,
      ISOCMBRAMEN => open,
      ISOCMBRAMEVENWRITEEN => open,
      ISOCMBRAMODDWRITEEN => open,
      ISOCMBRAMRDABUS => open,
      ISOCMBRAMWRABUS => open,
      ISOCMBRAMWRDBUS => open,
      C405DCRABUS => open,
      C405DCRDBUSOUT => open,
      C405DCRREAD => open,
      C405DCRWRITE => open,
      DCRC405ACK => net_gnd0,
      DCRC405DBUSIN => net_gnd32,
      EICC405CRITINPUTIRQ => net_gnd0,
      EICC405EXTINPUTIRQ => net_gnd0,
      C405JTGCAPTUREDR => open,
      C405JTGEXTEST => open,
      C405JTGPGMOUT => open,
      C405JTGSHIFTDR => open,
      C405JTGTDO => jtagppc_0_0_C405JTGTDO,
      C405JTGTDOEN => jtagppc_0_0_C405JTGTDOEN,
      C405JTGUPDATEDR => open,
      MCBJTAGEN => net_vcc0,
      JTGC405BNDSCANTDO => net_gnd0,
      JTGC405TCK => jtagppc_0_0_JTGC405TCK,
      JTGC405TDI => jtagppc_0_0_JTGC405TDI,
      JTGC405TMS => jtagppc_0_0_JTGC405TMS,
      JTGC405TRSTNEG => jtagppc_0_0_JTGC405TRSTNEG,
      C405DBGMSRWE => open,
      C405DBGSTOPACK => open,
      C405DBGWBCOMPLETE => open,
      C405DBGWBFULL => open,
      C405DBGWBIAR => open,
      DBGC405DEBUGHALT => net_gnd0,
      DBGC405EXTBUSHOLDACK => net_gnd0,
      DBGC405UNCONDDEBUGEVENT => net_gnd0,
      C405TRCCYCLE => open,
      C405TRCEVENEXECUTIONSTATUS => open,
      C405TRCODDEXECUTIONSTATUS => open,
      C405TRCTRACESTATUS => open,
      C405TRCTRIGGEREVENTOUT => open,
      C405TRCTRIGGEREVENTTYPE => open,
      TRCC405TRACEDISABLE => net_gnd0,
      TRCC405TRIGGEREVENTIN => net_gnd0
    );

  ppc405_1 : ppc405_1_wrapper
    port map (
      C405CPMCORESLEEPREQ => open,
      C405CPMMSRCE => open,
      C405CPMMSREE => open,
      C405CPMTIMERIRQ => open,
      C405CPMTIMERRESETREQ => open,
      C405XXXMACHINECHECK => open,
      CPMC405CLOCK => net_gnd0,
      CPMC405CORECLKINACTIVE => net_gnd0,
      CPMC405CPUCLKEN => net_vcc0,
      CPMC405JTAGCLKEN => net_vcc0,
      CPMC405TIMERCLKEN => net_vcc0,
      CPMC405TIMERTICK => net_vcc0,
      MCBCPUCLKEN => net_vcc0,
      MCBTIMEREN => net_vcc0,
      MCPPCRST => net_vcc0,
      PLBCLK => net_gnd0,
      DCRCLK => net_gnd0,
      C405RSTCHIPRESETREQ => open,
      C405RSTCORERESETREQ => open,
      C405RSTSYSRESETREQ => open,
      RSTC405RESETCHIP => net_gnd0,
      RSTC405RESETCORE => net_gnd0,
      RSTC405RESETSYS => net_gnd0,
      C405PLBICUABUS => open,
      C405PLBICUBE => open,
      C405PLBICURNW => open,
      C405PLBICUABORT => open,
      C405PLBICUBUSLOCK => open,
      C405PLBICUU0ATTR => open,
      C405PLBICUGUARDED => open,
      C405PLBICULOCKERR => open,
      C405PLBICUMSIZE => open,
      C405PLBICUORDERED => open,
      C405PLBICUPRIORITY => open,
      C405PLBICURDBURST => open,
      C405PLBICUREQUEST => open,
      C405PLBICUSIZE => open,
      C405PLBICUTYPE => open,
      C405PLBICUWRBURST => open,
      C405PLBICUWRDBUS => open,
      C405PLBICUCACHEABLE => open,
      PLBC405ICUADDRACK => net_gnd0,
      PLBC405ICUBUSY => net_gnd0,
      PLBC405ICUERR => net_gnd0,
      PLBC405ICURDBTERM => net_gnd0,
      PLBC405ICURDDACK => net_gnd0,
      PLBC405ICURDDBUS => net_gnd64,
      PLBC405ICURDWDADDR => net_gnd4,
      PLBC405ICUREARBITRATE => net_gnd0,
      PLBC405ICUWRBTERM => net_gnd0,
      PLBC405ICUWRDACK => net_gnd0,
      PLBC405ICUSSIZE => net_gnd2,
      PLBC405ICUSERR => net_gnd0,
      PLBC405ICUSBUSYS => net_gnd0,
      C405PLBDCUABUS => open,
      C405PLBDCUBE => open,
      C405PLBDCURNW => open,
      C405PLBDCUABORT => open,
      C405PLBDCUBUSLOCK => open,
      C405PLBDCUU0ATTR => open,
      C405PLBDCUGUARDED => open,
      C405PLBDCULOCKERR => open,
      C405PLBDCUMSIZE => open,
      C405PLBDCUORDERED => open,
      C405PLBDCUPRIORITY => open,
      C405PLBDCURDBURST => open,
      C405PLBDCUREQUEST => open,
      C405PLBDCUSIZE => open,
      C405PLBDCUTYPE => open,
      C405PLBDCUWRBURST => open,
      C405PLBDCUWRDBUS => open,
      C405PLBDCUCACHEABLE => open,
      C405PLBDCUWRITETHRU => open,
      PLBC405DCUADDRACK => net_gnd0,
      PLBC405DCUBUSY => net_gnd0,
      PLBC405DCUERR => net_gnd0,
      PLBC405DCURDBTERM => net_gnd0,
      PLBC405DCURDDACK => net_gnd0,
      PLBC405DCURDDBUS => net_gnd64,
      PLBC405DCURDWDADDR => net_gnd4,
      PLBC405DCUREARBITRATE => net_gnd0,
      PLBC405DCUWRBTERM => net_gnd0,
      PLBC405DCUWRDACK => net_gnd0,
      PLBC405DCUSSIZE => net_gnd2,
      PLBC405DCUSERR => net_gnd0,
      PLBC405DCUSBUSYS => net_gnd0,
      BRAMDSOCMCLK => net_gnd0,
      BRAMDSOCMRDDBUS => net_gnd32,
      DSARCVALUE => net_gnd8,
      DSCNTLVALUE => net_gnd8,
      DSOCMBRAMABUS => open,
      DSOCMBRAMBYTEWRITE => open,
      DSOCMBRAMEN => open,
      DSOCMBRAMWRDBUS => open,
      DSOCMBUSY => open,
      BRAMISOCMCLK => net_gnd0,
      BRAMISOCMRDDBUS => net_gnd64,
      ISARCVALUE => net_gnd8,
      ISCNTLVALUE => net_gnd8,
      ISOCMBRAMEN => open,
      ISOCMBRAMEVENWRITEEN => open,
      ISOCMBRAMODDWRITEEN => open,
      ISOCMBRAMRDABUS => open,
      ISOCMBRAMWRABUS => open,
      ISOCMBRAMWRDBUS => open,
      C405DCRABUS => open,
      C405DCRDBUSOUT => open,
      C405DCRREAD => open,
      C405DCRWRITE => open,
      DCRC405ACK => net_gnd0,
      DCRC405DBUSIN => net_gnd32,
      EICC405CRITINPUTIRQ => net_gnd0,
      EICC405EXTINPUTIRQ => net_gnd0,
      C405JTGCAPTUREDR => open,
      C405JTGEXTEST => open,
      C405JTGPGMOUT => open,
      C405JTGSHIFTDR => open,
      C405JTGTDO => jtagppc_0_1_C405JTGTDO,
      C405JTGTDOEN => jtagppc_0_1_C405JTGTDOEN,
      C405JTGUPDATEDR => open,
      MCBJTAGEN => net_vcc0,
      JTGC405BNDSCANTDO => net_gnd0,
      JTGC405TCK => jtagppc_0_1_JTGC405TCK,
      JTGC405TDI => jtagppc_0_1_JTGC405TDI,
      JTGC405TMS => jtagppc_0_1_JTGC405TMS,
      JTGC405TRSTNEG => jtagppc_0_1_JTGC405TRSTNEG,
      C405DBGMSRWE => open,
      C405DBGSTOPACK => open,
      C405DBGWBCOMPLETE => open,
      C405DBGWBFULL => open,
      C405DBGWBIAR => open,
      DBGC405DEBUGHALT => net_gnd0,
      DBGC405EXTBUSHOLDACK => net_gnd0,
      DBGC405UNCONDDEBUGEVENT => net_gnd0,
      C405TRCCYCLE => open,
      C405TRCEVENEXECUTIONSTATUS => open,
      C405TRCODDEXECUTIONSTATUS => open,
      C405TRCTRACESTATUS => open,
      C405TRCTRIGGEREVENTOUT => open,
      C405TRCTRIGGEREVENTTYPE => open,
      TRCC405TRACEDISABLE => net_gnd0,
      TRCC405TRIGGEREVENTIN => net_gnd0
    );

  jtagppc_0 : jtagppc_0_wrapper
    port map (
      TRSTNEG => net_vcc0,
      HALTNEG0 => net_vcc0,
      DBGC405DEBUGHALT0 => open,
      HALTNEG1 => net_vcc0,
      DBGC405DEBUGHALT1 => open,
      C405JTGTDO0 => jtagppc_0_0_C405JTGTDO,
      C405JTGTDOEN0 => jtagppc_0_0_C405JTGTDOEN,
      JTGC405TCK0 => jtagppc_0_0_JTGC405TCK,
      JTGC405TDI0 => jtagppc_0_0_JTGC405TDI,
      JTGC405TMS0 => jtagppc_0_0_JTGC405TMS,
      JTGC405TRSTNEG0 => jtagppc_0_0_JTGC405TRSTNEG,
      C405JTGTDO1 => jtagppc_0_1_C405JTGTDO,
      C405JTGTDOEN1 => jtagppc_0_1_C405JTGTDOEN,
      JTGC405TCK1 => jtagppc_0_1_JTGC405TCK,
      JTGC405TDI1 => jtagppc_0_1_JTGC405TDI,
      JTGC405TMS1 => jtagppc_0_1_JTGC405TMS,
      JTGC405TRSTNEG1 => jtagppc_0_1_JTGC405TRSTNEG
    );

  reset_block : reset_block_wrapper
    port map (
      Slowest_sync_clk => sys_clk_s(0),
      Ext_Reset_In => sys_rst_s,
      Aux_Reset_In => net_gnd0,
      Core_Reset_Req => C405RSTCORERESETREQ,
      Chip_Reset_Req => C405RSTCHIPRESETREQ,
      System_Reset_Req => C405RSTSYSRESETREQ,
      Dcm_locked => dcm_1_lock,
      Rstc405resetcore => RSTC405RESETCORE,
      Rstc405resetchip => RSTC405RESETCHIP,
      Rstc405resetsys => RSTC405RESETSYS,
      Bus_Struct_Reset => sys_bus_reset(0 to 0),
      Peripheral_Reset => open
    );

  plb : plb_wrapper
    port map (
      PLB_Clk => sys_clk_s(0),
      SYS_Rst => sys_bus_reset(0),
      PLB_Rst => plb_PLB_Rst,
      PLB_dcrAck => open,
      PLB_dcrDBus => open,
      DCR_ABus => net_gnd10,
      DCR_DBus => net_gnd32,
      DCR_Read => net_gnd0,
      DCR_Write => net_gnd0,
      M_ABus => plb_M_ABus,
      M_BE => plb_M_BE,
      M_RNW => plb_M_RNW,
      M_abort => plb_M_abort,
      M_busLock => plb_M_busLock,
      M_compress => plb_M_compress,
      M_guarded => plb_M_guarded,
      M_lockErr => plb_M_lockErr,
      M_MSize => plb_M_MSize,
      M_ordered => plb_M_ordered,
      M_priority => plb_M_priority,
      M_rdBurst => plb_M_rdBurst,
      M_request => plb_M_request,
      M_size => plb_M_size,
      M_type => plb_M_type,
      M_wrBurst => plb_M_wrBurst,
      M_wrDBus => plb_M_wrDBus,
      Sl_addrAck => plb_Sl_addrAck,
      Sl_MErr => plb_Sl_MErr,
      Sl_MBusy => plb_Sl_MBusy,
      Sl_rdBTerm => plb_Sl_rdBTerm,
      Sl_rdComp => plb_Sl_rdComp,
      Sl_rdDAck => plb_Sl_rdDAck,
      Sl_rdDBus => plb_Sl_rdDBus,
      Sl_rdWdAddr => plb_Sl_rdWdAddr,
      Sl_rearbitrate => plb_Sl_rearbitrate,
      Sl_SSize => plb_Sl_SSize,
      Sl_wait => plb_Sl_wait,
      Sl_wrBTerm => plb_Sl_wrBTerm,
      Sl_wrComp => plb_Sl_wrComp,
      Sl_wrDAck => plb_Sl_wrDAck,
      PLB_ABus => plb_PLB_ABus,
      PLB_BE => plb_PLB_BE,
      PLB_MAddrAck => plb_PLB_MAddrAck,
      PLB_MBusy => plb_PLB_MBusy,
      PLB_MErr => plb_PLB_MErr,
      PLB_MRdBTerm => plb_PLB_MRdBTerm,
      PLB_MRdDAck => plb_PLB_MRdDAck,
      PLB_MRdDBus => plb_PLB_MRdDBus,
      PLB_MRdWdAddr => plb_PLB_MRdWdAddr,
      PLB_MRearbitrate => plb_PLB_MRearbitrate,
      PLB_MWrBTerm => plb_PLB_MWrBTerm,
      PLB_MWrDAck => plb_PLB_MWrDAck,
      PLB_MSSize => plb_PLB_MSSize,
      PLB_PAValid => plb_PLB_PAValid,
      PLB_RNW => plb_PLB_RNW,
      PLB_SAValid => plb_PLB_SAValid,
      PLB_abort => plb_PLB_abort,
      PLB_busLock => plb_PLB_busLock,
      PLB_compress => plb_PLB_compress,
      PLB_guarded => plb_PLB_guarded,
      PLB_lockErr => plb_PLB_lockErr,
      PLB_masterID => plb_PLB_masterID(0 to 0),
      PLB_MSize => plb_PLB_MSize,
      PLB_ordered => plb_PLB_ordered,
      PLB_pendPri => plb_PLB_pendPri,
      PLB_pendReq => plb_PLB_pendReq,
      PLB_rdBurst => plb_PLB_rdBurst,
      PLB_rdPrim => plb_PLB_rdPrim,
      PLB_reqPri => plb_PLB_reqPri,
      PLB_size => plb_PLB_size,
      PLB_type => plb_PLB_type,
      PLB_wrBurst => plb_PLB_wrBurst,
      PLB_wrDBus => plb_PLB_wrDBus,
      PLB_wrPrim => plb_PLB_wrPrim,
      PLB_SaddrAck => open,
      PLB_SMErr => plb_PLB_SMErr,
      PLB_SMBusy => plb_PLB_SMBusy,
      PLB_SrdBTerm => open,
      PLB_SrdComp => open,
      PLB_SrdDAck => open,
      PLB_SrdDBus => open,
      PLB_SrdWdAddr => open,
      PLB_Srearbitrate => open,
      PLB_Sssize => open,
      PLB_Swait => open,
      PLB_SwrBTerm => open,
      PLB_SwrComp => open,
      PLB_SwrDAck => open,
      PLB2OPB_rearb => plb_PLB2OPB_rearb,
      ArbAddrVldReg => open,
      Bus_Error_Det => open
    );

  opb : opb_wrapper
    port map (
      OPB_Clk => sys_clk_s(0),
      OPB_Rst => opb_OPB_Rst,
      SYS_Rst => sys_bus_reset(0),
      Debug_SYS_Rst => net_gnd0,
      WDT_Rst => net_gnd0,
      M_ABus => opb_M_ABus,
      M_BE => opb_M_BE,
      M_beXfer => net_gnd1(0 to 0),
      M_busLock => opb_M_busLock(0 to 0),
      M_DBus => opb_M_DBus,
      M_DBusEn => net_gnd1(0 to 0),
      M_DBusEn32_63 => net_vcc1(0 to 0),
      M_dwXfer => net_gnd1(0 to 0),
      M_fwXfer => net_gnd1(0 to 0),
      M_hwXfer => net_gnd1(0 to 0),
      M_request => opb_M_request(0 to 0),
      M_RNW => opb_M_RNW(0 to 0),
      M_select => opb_M_select(0 to 0),
      M_seqAddr => opb_M_seqAddr(0 to 0),
      Sl_beAck => net_gnd6,
      Sl_DBus => opb_Sl_DBus,
      Sl_DBusEn => net_vcc6,
      Sl_DBusEn32_63 => net_vcc6,
      Sl_errAck => opb_Sl_errAck,
      Sl_dwAck => net_gnd6,
      Sl_fwAck => net_gnd6,
      Sl_hwAck => net_gnd6,
      Sl_retry => opb_Sl_retry,
      Sl_toutSup => opb_Sl_toutSup,
      Sl_xferAck => opb_Sl_xferAck,
      OPB_MRequest => open,
      OPB_ABus => opb_OPB_ABus,
      OPB_BE => opb_OPB_BE,
      OPB_beXfer => open,
      OPB_beAck => open,
      OPB_busLock => open,
      OPB_rdDBus => open,
      OPB_wrDBus => open,
      OPB_DBus => opb_OPB_DBus,
      OPB_errAck => opb_OPB_errAck,
      OPB_dwAck => open,
      OPB_dwXfer => open,
      OPB_fwAck => open,
      OPB_fwXfer => open,
      OPB_hwAck => open,
      OPB_hwXfer => open,
      OPB_MGrant => opb_OPB_MGrant(0 to 0),
      OPB_pendReq => open,
      OPB_retry => opb_OPB_retry,
      OPB_RNW => opb_OPB_RNW,
      OPB_select => opb_OPB_select,
      OPB_seqAddr => opb_OPB_seqAddr,
      OPB_timeout => opb_OPB_timeout,
      OPB_toutSup => open,
      OPB_xferAck => opb_OPB_xferAck
    );

  plb2opb : plb2opb_wrapper
    port map (
      PLB_Clk => sys_clk_s(0),
      OPB_Clk => sys_clk_s(0),
      PLB_Rst => plb_PLB_Rst,
      OPB_Rst => opb_OPB_Rst,
      Bus_Error_Det => open,
      BGI_Trans_Abort => open,
      BGO_dcrAck => open,
      BGO_dcrDBus => open,
      DCR_ABus => net_gnd10,
      DCR_DBus => net_gnd32,
      DCR_Read => net_gnd0,
      DCR_Write => net_gnd0,
      BGO_addrAck => plb_Sl_addrAck(0),
      BGO_MErr => plb_Sl_MErr(0 to 1),
      BGO_MBusy => plb_Sl_MBusy(0 to 1),
      BGO_rdBTerm => plb_Sl_rdBTerm(0),
      BGO_rdComp => plb_Sl_rdComp(0),
      BGO_rdDAck => plb_Sl_rdDAck(0),
      BGO_rdDBus => plb_Sl_rdDBus(0 to 63),
      BGO_rdWdAddr => plb_Sl_rdWdAddr(0 to 3),
      BGO_rearbitrate => plb_Sl_rearbitrate(0),
      BGO_SSize => plb_Sl_SSize(0 to 1),
      BGO_wait => plb_Sl_wait(0),
      BGO_wrBTerm => plb_Sl_wrBTerm(0),
      BGO_wrComp => plb_Sl_wrComp(0),
      BGO_wrDAck => plb_Sl_wrDAck(0),
      PLB_abort => plb_PLB_abort,
      PLB_ABus => plb_PLB_ABus,
      PLB_BE => plb_PLB_BE,
      PLB_busLock => plb_PLB_busLock,
      PLB_compress => plb_PLB_compress,
      PLB_guarded => plb_PLB_guarded,
      PLB_lockErr => plb_PLB_lockErr,
      PLB_masterID => plb_PLB_masterID(0 to 0),
      PLB_MSize => plb_PLB_MSize,
      PLB_ordered => plb_PLB_ordered,
      PLB_PAValid => plb_PLB_PAValid,
      PLB_rdBurst => plb_PLB_rdBurst,
      PLB_rdPrim => plb_PLB_rdPrim,
      PLB_RNW => plb_PLB_RNW,
      PLB_SAValid => plb_PLB_SAValid,
      PLB_size => plb_PLB_size,
      PLB_type => plb_PLB_type,
      PLB_wrBurst => plb_PLB_wrBurst,
      PLB_wrDBus => plb_PLB_wrDBus,
      PLB_wrPrim => plb_PLB_wrPrim,
      PLB2OPB_rearb => plb_PLB2OPB_rearb(0),
      BGO_ABus => opb_M_ABus,
      BGO_BE => opb_M_BE,
      BGO_busLock => opb_M_busLock(0),
      BGO_DBus => opb_M_DBus,
      BGO_request => opb_M_request(0),
      BGO_RNW => opb_M_RNW(0),
      BGO_select => opb_M_select(0),
      BGO_seqAddr => opb_M_seqAddr(0),
      OPB_DBus => opb_OPB_DBus,
      OPB_errAck => opb_OPB_errAck,
      OPB_MnGrant => opb_OPB_MGrant(0),
      OPB_retry => opb_OPB_retry,
      OPB_timeout => opb_OPB_timeout,
      OPB_xferAck => opb_OPB_xferAck
    );

  rs232_uart_1 : rs232_uart_1_wrapper
    port map (
      OPB_Clk => sys_clk_s(0),
      OPB_Rst => opb_OPB_Rst,
      Interrupt => open,
      OPB_ABus => opb_OPB_ABus,
      OPB_BE => opb_OPB_BE,
      OPB_RNW => opb_OPB_RNW,
      OPB_select => opb_OPB_select,
      OPB_seqAddr => opb_OPB_seqAddr,
      OPB_DBus => opb_OPB_DBus,
      UART_DBus => opb_Sl_DBus(0 to 31),
      UART_errAck => opb_Sl_errAck(0),
      UART_retry => opb_Sl_retry(0),
      UART_toutSup => opb_Sl_toutSup(0),
      UART_xferAck => opb_Sl_xferAck(0),
      RX => fpga_0_RS232_Uart_1_RX,
      TX => fpga_0_RS232_Uart_1_TX
    );

  sysace_compactflash : sysace_compactflash_wrapper
    port map (
      OPB_Clk => sys_clk_s(0),
      OPB_Rst => opb_OPB_Rst,
      OPB_ABus => opb_OPB_ABus,
      OPB_DBus => opb_OPB_DBus,
      Sln_DBus => opb_Sl_DBus(32 to 63),
      OPB_select => opb_OPB_select,
      OPB_RNW => opb_OPB_RNW,
      OPB_seqAddr => opb_OPB_seqAddr,
      OPB_BE => opb_OPB_BE,
      Sln_xferAck => opb_Sl_xferAck(1),
      Sln_errAck => opb_Sl_errAck(1),
      Sln_toutSup => opb_Sl_toutSup(1),
      Sln_retry => opb_Sl_retry(1),
      SysACE_MPA => fpga_0_SysACE_CompactFlash_SysACE_MPA,
      SysACE_CLK => fpga_0_SysACE_CompactFlash_SysACE_CLK,
      SysACE_MPIRQ => fpga_0_SysACE_CompactFlash_SysACE_MPIRQ,
      SysACE_MPD_I => fpga_0_SysACE_CompactFlash_SysACE_MPD_I,
      SysACE_MPD_O => fpga_0_SysACE_CompactFlash_SysACE_MPD_O,
      SysACE_MPD_T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T,
      SysACE_CEN => fpga_0_SysACE_CompactFlash_SysACE_CEN,
      SysACE_OEN => fpga_0_SysACE_CompactFlash_SysACE_OEN,
      SysACE_WEN => fpga_0_SysACE_CompactFlash_SysACE_WEN,
      SysACE_IRQ => open
    );

  leds_4bit : leds_4bit_wrapper
    port map (
      OPB_ABus => opb_OPB_ABus,
      OPB_BE => opb_OPB_BE,
      OPB_Clk => sys_clk_s(0),
      OPB_DBus => opb_OPB_DBus,
      OPB_RNW => opb_OPB_RNW,
      OPB_Rst => opb_OPB_Rst,
      OPB_select => opb_OPB_select,
      OPB_seqAddr => opb_OPB_seqAddr,
      Sln_DBus => opb_Sl_DBus(64 to 95),
      Sln_errAck => opb_Sl_errAck(2),
      Sln_retry => opb_Sl_retry(2),
      Sln_toutSup => opb_Sl_toutSup(2),
      Sln_xferAck => opb_Sl_xferAck(2),
      IP2INTC_Irpt => open,
      GPIO_in => net_gnd4,
      GPIO_d_out => open,
      GPIO_t_out => open,
      GPIO2_in => net_gnd4,
      GPIO2_d_out => open,
      GPIO2_t_out => open,
      GPIO_IO_I => fpga_0_LEDs_4Bit_GPIO_IO_I,
      GPIO_IO_O => fpga_0_LEDs_4Bit_GPIO_IO_O,
      GPIO_IO_T => fpga_0_LEDs_4Bit_GPIO_IO_T,
      GPIO2_IO_I => net_gnd4,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open
    );

  pushbuttons_5bit : pushbuttons_5bit_wrapper
    port map (
      OPB_ABus => opb_OPB_ABus,
      OPB_BE => opb_OPB_BE,
      OPB_Clk => sys_clk_s(0),
      OPB_DBus => opb_OPB_DBus,
      OPB_RNW => opb_OPB_RNW,
      OPB_Rst => opb_OPB_Rst,
      OPB_select => opb_OPB_select,
      OPB_seqAddr => opb_OPB_seqAddr,
      Sln_DBus => opb_Sl_DBus(96 to 127),
      Sln_errAck => opb_Sl_errAck(3),
      Sln_retry => opb_Sl_retry(3),
      Sln_toutSup => opb_Sl_toutSup(3),
      Sln_xferAck => opb_Sl_xferAck(3),
      IP2INTC_Irpt => open,
      GPIO_in => net_gnd5,
      GPIO_d_out => open,
      GPIO_t_out => open,
      GPIO2_in => net_gnd5,
      GPIO2_d_out => open,
      GPIO2_t_out => open,
      GPIO_IO_I => fpga_0_PushButtons_5Bit_GPIO_IO_I,
      GPIO_IO_O => fpga_0_PushButtons_5Bit_GPIO_IO_O,
      GPIO_IO_T => fpga_0_PushButtons_5Bit_GPIO_IO_T,
      GPIO2_IO_I => net_gnd5,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open
    );

  ddr_512mb_64mx64_rank2_row13_col10_cl2_5 : ddr_512mb_64mx64_rank2_row13_col10_cl2_5_wrapper
    port map (
      PLB_Clk => sys_clk_s(0),
      PLB_Clk_n => sys_clk_n_s(0),
      Clk90_in => clk_90_s(0),
      Clk90_in_n => clk_90_n_s(0),
      DDR_Clk90_in => ddr_clk_90_s(0),
      DDR_Clk90_in_n => ddr_clk_90_n_s(0),
      PLB_Rst => plb_PLB_Rst,
      PLB_ABus => plb_PLB_ABus,
      PLB_PAValid => plb_PLB_PAValid,
      PLB_SAValid => plb_PLB_SAValid,
      PLB_rdPrim => plb_PLB_rdPrim,
      PLB_wrPrim => plb_PLB_wrPrim,
      PLB_masterID => plb_PLB_masterID(0 to 0),
      PLB_abort => plb_PLB_abort,
      PLB_busLock => plb_PLB_busLock,
      PLB_RNW => plb_PLB_RNW,
      PLB_BE => plb_PLB_BE,
      PLB_MSize => plb_PLB_MSize,
      PLB_size => plb_PLB_size,
      PLB_type => plb_PLB_type,
      PLB_compress => plb_PLB_compress,
      PLB_guarded => plb_PLB_guarded,
      PLB_ordered => plb_PLB_ordered,
      PLB_lockErr => plb_PLB_lockErr,
      PLB_wrDBus => plb_PLB_wrDBus,
      PLB_wrBurst => plb_PLB_wrBurst,
      PLB_rdBurst => plb_PLB_rdBurst,
      PLB_pendReq => plb_PLB_pendReq,
      PLB_pendPri => plb_PLB_pendPri,
      PLB_reqPri => plb_PLB_reqPri,
      Sl_addrAck => plb_Sl_addrAck(1),
      Sl_SSize => plb_Sl_SSize(2 to 3),
      Sl_wait => plb_Sl_wait(1),
      Sl_rearbitrate => plb_Sl_rearbitrate(1),
      Sl_wrDAck => plb_Sl_wrDAck(1),
      Sl_wrComp => plb_Sl_wrComp(1),
      Sl_wrBTerm => plb_Sl_wrBTerm(1),
      Sl_rdDBus => plb_Sl_rdDBus(64 to 127),
      Sl_rdWdAddr => plb_Sl_rdWdAddr(4 to 7),
      Sl_rdDAck => plb_Sl_rdDAck(1),
      Sl_rdComp => plb_Sl_rdComp(1),
      Sl_rdBTerm => plb_Sl_rdBTerm(1),
      Sl_MBusy => plb_Sl_MBusy(2 to 3),
      Sl_MErr => plb_Sl_MErr(2 to 3),
      IP2INTC_Irpt => open,
      DDR_Clk => pgassign1,
      DDR_Clkn => pgassign2,
      DDR_CKE => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CKE,
      DDR_CSn => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CSn,
      DDR_RASn => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_RASn,
      DDR_CASn => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CASn,
      DDR_WEn => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_WEn,
      DDR_DM => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM,
      DDR_BankAddr => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_BankAddr,
      DDR_Addr => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr,
      DDR_DM_ECC => open,
      DDR_Init_done => open,
      DDR_DQ_I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I,
      DDR_DQ_O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O,
      DDR_DQ_T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T,
      DDR_DQS_I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I,
      DDR_DQS_O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O,
      DDR_DQS_T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T,
      DDR_DQ_ECC_I => net_gnd7,
      DDR_DQ_ECC_O => open,
      DDR_DQ_ECC_T => open,
      DDR_DQS_ECC_I => net_gnd0,
      DDR_DQS_ECC_O => open,
      DDR_DQS_ECC_T => open
    );

  plb_bram_if_cntlr_1 : plb_bram_if_cntlr_1_wrapper
    port map (
      plb_clk => sys_clk_s(0),
      plb_rst => plb_PLB_Rst,
      plb_abort => plb_PLB_abort,
      plb_abus => plb_PLB_ABus,
      plb_be => plb_PLB_BE,
      plb_buslock => plb_PLB_busLock,
      plb_compress => plb_PLB_compress,
      plb_guarded => plb_PLB_guarded,
      plb_lockerr => plb_PLB_lockErr,
      plb_masterid => plb_PLB_masterID(0 to 0),
      plb_msize => plb_PLB_MSize,
      plb_ordered => plb_PLB_ordered,
      plb_pavalid => plb_PLB_PAValid,
      plb_rnw => plb_PLB_RNW,
      plb_size => plb_PLB_size,
      plb_type => plb_PLB_type,
      sl_addrack => plb_Sl_addrAck(2),
      sl_mbusy => plb_Sl_MBusy(4 to 5),
      sl_merr => plb_Sl_MErr(4 to 5),
      sl_rearbitrate => plb_Sl_rearbitrate(2),
      sl_ssize => plb_Sl_SSize(4 to 5),
      sl_wait => plb_Sl_wait(2),
      plb_rdprim => plb_PLB_rdPrim,
      plb_savalid => plb_PLB_SAValid,
      plb_wrprim => plb_PLB_wrPrim,
      plb_wrburst => plb_PLB_wrBurst,
      plb_wrdbus => plb_PLB_wrDBus,
      sl_wrbterm => plb_Sl_wrBTerm(2),
      sl_wrcomp => plb_Sl_wrComp(2),
      sl_wrdack => plb_Sl_wrDAck(2),
      plb_rdburst => plb_PLB_rdBurst,
      sl_rdbterm => plb_Sl_rdBTerm(2),
      sl_rdcomp => plb_Sl_rdComp(2),
      sl_rddack => plb_Sl_rdDAck(2),
      sl_rddbus => plb_Sl_rdDBus(128 to 191),
      sl_rdwdaddr => plb_Sl_rdWdAddr(8 to 11),
      plb_pendreq => plb_PLB_pendReq,
      plb_pendpri => plb_PLB_pendPri,
      plb_reqpri => plb_PLB_reqPri,
      bram_rst => plb_bram_if_cntlr_1_port_BRAM_Rst,
      bram_clk => plb_bram_if_cntlr_1_port_BRAM_Clk,
      bram_en => plb_bram_if_cntlr_1_port_BRAM_EN,
      bram_wen => plb_bram_if_cntlr_1_port_BRAM_WEN,
      bram_addr => plb_bram_if_cntlr_1_port_BRAM_Addr,
      bram_din => plb_bram_if_cntlr_1_port_BRAM_Din,
      bram_dout => plb_bram_if_cntlr_1_port_BRAM_Dout
    );

  plb_bram_if_cntlr_1_bram : plb_bram_if_cntlr_1_bram_wrapper
    port map (
      BRAM_Rst_A => plb_bram_if_cntlr_1_port_BRAM_Rst,
      BRAM_Clk_A => plb_bram_if_cntlr_1_port_BRAM_Clk,
      BRAM_EN_A => plb_bram_if_cntlr_1_port_BRAM_EN,
      BRAM_WEN_A => plb_bram_if_cntlr_1_port_BRAM_WEN,
      BRAM_Addr_A => plb_bram_if_cntlr_1_port_BRAM_Addr,
      BRAM_Din_A => plb_bram_if_cntlr_1_port_BRAM_Din,
      BRAM_Dout_A => plb_bram_if_cntlr_1_port_BRAM_Dout,
      BRAM_Rst_B => net_gnd0,
      BRAM_Clk_B => net_gnd0,
      BRAM_EN_B => net_gnd0,
      BRAM_WEN_B => net_gnd8,
      BRAM_Addr_B => net_gnd32,
      BRAM_Din_B => open,
      BRAM_Dout_B => net_gnd64
    );

  sysclk_inv : sysclk_inv_wrapper
    port map (
      Op1 => sys_clk_s(0 to 0),
      Op2 => net_gnd1(0 to 0),
      Res => sys_clk_n_s(0 to 0)
    );

  clk90_inv : clk90_inv_wrapper
    port map (
      Op1 => clk_90_s(0 to 0),
      Op2 => net_gnd1(0 to 0),
      Res => clk_90_n_s(0 to 0)
    );

  ddr_clk90_inv : ddr_clk90_inv_wrapper
    port map (
      Op1 => ddr_clk_90_s(0 to 0),
      Op2 => net_gnd1(0 to 0),
      Res => ddr_clk_90_n_s(0 to 0)
    );

  dcm_0 : dcm_0_wrapper
    port map (
      RST => net_gnd0,
      CLKIN => dcm_clk_s,
      CLKFB => sys_clk_s(0),
      PSEN => net_gnd0,
      PSINCDEC => net_gnd0,
      PSCLK => net_gnd0,
      DSSEN => net_gnd0,
      CLK0 => dcm_out_clk,
      CLK90 => clk_90_s(0),
      CLK180 => open,
      CLK270 => open,
      CLKDV => open,
      CLK2X => open,
      CLK2X180 => open,
      CLKFX => proc_clk_s,
      CLKFX180 => open,
      STATUS => open,
      LOCKED => dcm_0_lock,
      PSDONE => open
    );

  dcm_1 : dcm_1_wrapper
    port map (
      RST => dcm_0_lock,
      CLKIN => ddr_feedback_s,
      CLKFB => dcm_1_FB,
      PSEN => net_gnd0,
      PSINCDEC => net_gnd0,
      PSCLK => net_gnd0,
      DSSEN => net_gnd0,
      CLK0 => dcm_1_FB,
      CLK90 => ddr_clk_90_s(0),
      CLK180 => open,
      CLK270 => open,
      CLKDV => open,
      CLK2X => open,
      CLK2X180 => open,
      CLKFX => open,
      CLKFX180 => open,
      STATUS => open,
      LOCKED => dcm_1_lock,
      PSDONE => open
    );

  opb_hwicap_0 : opb_hwicap_0_wrapper
    port map (
      OPB_Clk => sys_clk_s(0),
      OPB_Rst => opb_OPB_Rst,
      OPB_ABus => opb_OPB_ABus,
      OPB_DBus => opb_OPB_DBus,
      Sln_DBus => opb_Sl_DBus(128 to 159),
      OPB_BE => opb_OPB_BE,
      OPB_select => opb_OPB_select,
      OPB_RNW => opb_OPB_RNW,
      OPB_seqAddr => opb_OPB_seqAddr,
      Sln_xferAck => opb_Sl_xferAck(4),
      Sln_errAck => opb_Sl_errAck(4),
      Sln_toutSup => opb_Sl_toutSup(4),
      Sln_retry => opb_Sl_retry(4)
    );

  opb_gpio_0 : opb_gpio_0_wrapper
    port map (
      OPB_ABus => opb_OPB_ABus,
      OPB_BE => opb_OPB_BE,
      OPB_Clk => sys_clk_s(0),
      OPB_DBus => opb_OPB_DBus,
      OPB_RNW => opb_OPB_RNW,
      OPB_Rst => opb_OPB_Rst,
      OPB_select => opb_OPB_select,
      OPB_seqAddr => opb_OPB_seqAddr,
      Sln_DBus => opb_Sl_DBus(160 to 191),
      Sln_errAck => opb_Sl_errAck(5),
      Sln_retry => opb_Sl_retry(5),
      Sln_toutSup => opb_Sl_toutSup(5),
      Sln_xferAck => opb_Sl_xferAck(5),
      IP2INTC_Irpt => open,
      GPIO_in => net_gnd8,
      GPIO_d_out => gpio_out,
      GPIO_t_out => open,
      GPIO2_in => net_gnd8,
      GPIO2_d_out => open,
      GPIO2_t_out => open,
      GPIO_IO_I => net_gnd8,
      GPIO_IO_O => open,
      GPIO_IO_T => open,
      GPIO2_IO_I => net_gnd8,
      GPIO2_IO_O => open,
      GPIO2_IO_T => open
    );

-----------------------------------------------------
--  Connect peripheral to macro signals. The signals are
--  internal to module and have "_module" appended to the
--  original name.
-----------------------------------------------------

--  old instantiation:

--  math_0 : math_0_wrapper
--    port map (
--      PLB_Clk => sys_clk_s(0),
--      PLB_Rst => plb_PLB_Rst,
--      Sl_addrAck => plb_Sl_addrAck(3),
--      Sl_MBusy => plb_Sl_MBusy(6 to 7),
--      Sl_MErr => plb_Sl_MErr(6 to 7),
--      Sl_rdBTerm => plb_Sl_rdBTerm(3),
--      Sl_rdComp => plb_Sl_rdComp(3),
--      Sl_rdDAck => plb_Sl_rdDAck(3),
--      Sl_rdDBus => plb_Sl_rdDBus(192 to 255),
--      Sl_rdWdAddr => plb_Sl_rdWdAddr(12 to 15),
--      Sl_rearbitrate => plb_Sl_rearbitrate(3),
--      Sl_SSize => plb_Sl_SSize(6 to 7),
--      Sl_wait => plb_Sl_wait(3),
--      Sl_wrBTerm => plb_Sl_wrBTerm(3),
--      Sl_wrComp => plb_Sl_wrComp(3),
--      Sl_wrDAck => plb_Sl_wrDAck(3),
--      PLB_abort => plb_PLB_abort,
--      PLB_ABus => plb_PLB_ABus,
--      PLB_BE => plb_PLB_BE,
--      PLB_busLock => plb_PLB_busLock,
--      PLB_compress => plb_PLB_compress,
--      PLB_guarded => plb_PLB_guarded,
--      PLB_lockErr => plb_PLB_lockErr,
--      PLB_masterID => plb_PLB_masterID(0 to 0),
--      PLB_MSize => plb_PLB_MSize,
--      PLB_ordered => plb_PLB_ordered,
--      PLB_PAValid => plb_PLB_PAValid,
--      PLB_pendPri => plb_PLB_pendPri,
--      PLB_pendReq => plb_PLB_pendReq,
--      PLB_rdBurst => plb_PLB_rdBurst,
--      PLB_rdPrim => plb_PLB_rdPrim,
--      PLB_reqPri => plb_PLB_reqPri,
--      PLB_RNW => plb_PLB_RNW,
--      PLB_SAValid => plb_PLB_SAValid,
--      PLB_size => plb_PLB_size,
--      PLB_type => plb_PLB_type,
--      PLB_wrBurst => plb_PLB_wrBurst,
--      PLB_wrDBus => plb_PLB_wrDBus,
--      PLB_wrPrim => plb_PLB_wrPrim
--    );

-- new instantiation:
    
  math_0 : math_0_wrapper
    port map (
      PLB_Clk => sys_clk_s(0),
      PLB_Rst => plb_PLB_Rst_module,
      Sl_addrAck => plb_Sl_addrAck_module(3),
      Sl_MBusy => plb_Sl_MBusy_module(6 to 7),
      Sl_MErr => plb_Sl_MErr_module(6 to 7),
      Sl_rdBTerm => plb_Sl_rdBTerm_module(3),
      Sl_rdComp => plb_Sl_rdComp_module(3),
      Sl_rdDAck => plb_Sl_rdDAck_module(3),
      Sl_rdDBus => plb_Sl_rdDBus_module(192 to 255),
      Sl_rdWdAddr => plb_Sl_rdWdAddr_module(12 to 15),
      Sl_rearbitrate => plb_Sl_rearbitrate_module(3),
      Sl_SSize => plb_Sl_SSize_module(6 to 7),
      Sl_wait => plb_Sl_wait_module(3),
      Sl_wrBTerm => plb_Sl_wrBTerm_module(3),
      Sl_wrComp => plb_Sl_wrComp_module(3),
      Sl_wrDAck => plb_Sl_wrDAck_module(3),
      PLB_abort => plb_PLB_abort_module,
      PLB_ABus => plb_PLB_ABus_module,
      PLB_BE => plb_PLB_BE_module,
      PLB_busLock => plb_PLB_busLock_module,
      PLB_compress => plb_PLB_compress_module,
      PLB_guarded => plb_PLB_guarded_module,
      PLB_lockErr => plb_PLB_lockErr_module,
      PLB_masterID => plb_PLB_masterID_module(0 to 0),
      PLB_MSize => plb_PLB_MSize_module,
      PLB_ordered => plb_PLB_ordered_module,
      PLB_PAValid => plb_PLB_PAValid_module,
      PLB_pendPri => plb_PLB_pendPri_module,
      PLB_pendReq => plb_PLB_pendReq_module,
      PLB_rdBurst => plb_PLB_rdBurst_module,
      PLB_rdPrim => plb_PLB_rdPrim_module,
      PLB_reqPri => plb_PLB_reqPri_module,
      PLB_RNW => plb_PLB_RNW_module,
      PLB_SAValid => plb_PLB_SAValid_module,
      PLB_size => plb_PLB_size_module,
      PLB_type => plb_PLB_type_module,
      PLB_wrBurst => plb_PLB_wrBurst_module,
      PLB_wrDBus => plb_PLB_wrDBus_module,
      PLB_wrPrim => plb_PLB_wrPrim_module
    );
    
-----------------------------------------------------
-- added busmacro instances
-----------------------------------------------------

-- signals from bus to peripheral

  macro_00 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(0 to 7),
	macro_out => plb_PLB_wrDBus_module(0 to 7)
    );
    
  macro_01 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(8 to 15),
	macro_out => plb_PLB_wrDBus_module(8 to 15)
    );
    
  macro_02 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(16 to 23),
	macro_out => plb_PLB_wrDBus_module(16 to 23)
    );

  macro_03 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(24 to 31),
	macro_out => plb_PLB_wrDBus_module(24 to 31)
    );
    
  macro_04 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(32 to 39),
	macro_out => plb_PLB_wrDBus_module(32 to 39)
    );
    
  macro_05 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(40 to 47),
	macro_out => plb_PLB_wrDBus_module(40 to 47)
    );
    
  macro_06 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(48 to 55),
	macro_out => plb_PLB_wrDBus_module(48 to 55)
    );

  macro_07 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_wrDBus(56 to 63),
	macro_out => plb_PLB_wrDBus_module(56 to 63)
    );
    
  macro_08 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_ABus(0 to 7),
	macro_out => plb_PLB_ABus_module(0 to 7)
    );
    
  macro_09 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_ABus(8 to 15),
	macro_out => plb_PLB_ABus_module(8 to 15)
    );
    
  macro_10 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_ABus(16 to 23),
	macro_out => plb_PLB_ABus_module(16 to 23)
    );

  macro_11 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_ABus(24 to 31),
	macro_out => plb_PLB_ABus_module(24 to 31)
    );
    
  macro_12 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in  => plb_PLB_BE(0 to 7),
	macro_out => plb_PLB_BE_module(0 to 7)
    );
    
  macro_13 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in(0)  => plb_PLB_Rst,
	macro_in(1)  => plb_PLB_busLock,
	macro_in(2)  => plb_PLB_compress,
	macro_in(3)  => plb_PLB_guarded,
	macro_in(4)  => plb_PLB_lockErr,
	macro_in(5)  => plb_PLB_masterID(0),
	macro_in(6) => plb_PLB_MSize(0),
	macro_in(7) => plb_PLB_MSize(1),
	macro_out(0) => plb_PLB_Rst_module,
	macro_out(1) => plb_PLB_busLock_module,
	macro_out(2) => plb_PLB_compress_module,
	macro_out(3) => plb_PLB_guarded_module,
	macro_out(4) => plb_PLB_lockErr_module,
	macro_out(5) => plb_PLB_masterID_module(0),
	macro_out(6) => plb_PLB_MSize_module(0),
	macro_out(7) => plb_PLB_MSize_module(1)
    );
    
  macro_14 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in(0)  => plb_PLB_ordered,
	macro_in(1)  => plb_PLB_PAValid,
	macro_in(2) => plb_PLB_pendPri(0),
	macro_in(3) => plb_PLB_pendPri(1),
	macro_in(4)  => plb_PLB_pendReq,
	macro_in(5)  => plb_PLB_rdBurst,
	macro_in(6)  => plb_PLB_rdPrim,
	macro_in(7)  => plb_PLB_RNW,
	macro_out(0) => plb_PLB_ordered_module,
	macro_out(1) => plb_PLB_PAValid_module,
	macro_out(2) => plb_PLB_pendPri_module(0),
	macro_out(3) => plb_PLB_pendPri_module(1),
	macro_out(4) => plb_PLB_pendReq_module,
	macro_out(5) => plb_PLB_rdBurst_module,
	macro_out(6) => plb_PLB_rdPrim_module,
	macro_out(7) => plb_PLB_RNW_module
    );
    
  macro_15 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in(0)  => plb_PLB_reqPri(0),
	macro_in(1)  => plb_PLB_reqPri(1),
	macro_in(2)  => plb_PLB_SAValid,
	macro_in(3)  => plb_PLB_size(0),
	macro_in(4)  => plb_PLB_size(1),
	macro_in(5)  => plb_PLB_size(2),
	macro_in(6)  => plb_PLB_size(3),
	macro_in(7)  => plb_PLB_wrBurst,
	macro_out(0) => plb_PLB_reqPri_module(0),
	macro_out(1) => plb_PLB_reqPri_module(1),
	macro_out(2) => plb_PLB_SAValid_module,
	macro_out(3) => plb_PLB_size_module(0),
	macro_out(4) => plb_PLB_size_module(1),
	macro_out(5) => plb_PLB_size_module(2),
	macro_out(6) => plb_PLB_size_module(3),
	macro_out(7) => plb_PLB_wrBurst_module
    );
    
  macro_16 : busmacro_vector8_xc2vp_l2r_async_narrow
    port map(
	macro_in(0)  => plb_PLB_type(0),
	macro_in(1)  => plb_PLB_type(1),
	macro_in(2)  => plb_PLB_type(2),
	macro_in(3)  => plb_PLB_wrPrim,
	macro_in(4)  => plb_PLB_abort,
	macro_in(5)  => '0',
	macro_in(6)  => '0',
	macro_in(7)  => '0',
	macro_out(0) => plb_PLB_type_module(0),
	macro_out(1) => plb_PLB_type_module(1),
	macro_out(2) => plb_PLB_type_module(2),
	macro_out(3) => plb_PLB_wrPrim_module,
	macro_out(4) => plb_PLB_abort_module,
	macro_out(5) => open,
	macro_out(6) => open,
	macro_out(7) => open
    );
    
-- signals from peripheral to bus

  macro_17 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(192 to 199),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(192 to 199)
    );

  macro_18 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(200 to 207),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(200 to 207)
    );
    
  macro_19 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(208 to 215),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(208 to 215)
    );
    
  macro_20 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(216 to 223),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(216 to 223)
    );
    
  macro_21 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(224 to 231),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(224 to 231)
    );

  macro_22 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(232 to 239),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(232 to 239)
    );
    
  macro_23 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(240 to 247),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(240 to 247)
    );
	
  macro_24 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in  => plb_Sl_rdDBus_module(248 to 255),
	enable => macro_enable,
	macro_out => plb_Sl_rdDBus(248 to 255)
    );
    
  macro_25 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in(0)  => plb_Sl_rdWdAddr_module(12),
	macro_in(1)  => plb_Sl_rdWdAddr_module(13),
	macro_in(2)  => plb_Sl_rdWdAddr_module(14),
	macro_in(3)  => plb_Sl_rdWdAddr_module(15),
	macro_in(4)  => plb_Sl_rearbitrate_module(3),
	macro_in(5)  => plb_Sl_SSize_module(6),
	macro_in(6)  => plb_Sl_SSize_module(7),
	macro_in(7)  => plb_Sl_wait_module(3),
	enable => macro_enable,
	macro_out(0) => plb_Sl_rdWdAddr(12),
	macro_out(1) => plb_Sl_rdWdAddr(13),
	macro_out(2) => plb_Sl_rdWdAddr(14),
	macro_out(3) => plb_Sl_rdWdAddr(15),
	macro_out(4) => plb_Sl_rearbitrate(3),
	macro_out(5) => plb_Sl_SSize(6),
	macro_out(6) => plb_Sl_SSize(7),
	macro_out(7) => plb_Sl_wait(3)
    );
    
  macro_26 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in(0)  => plb_Sl_addrAck_module(3),
	macro_in(1)  => plb_Sl_MBusy_module(6),
	macro_in(2)  => plb_Sl_MBusy_module(7),
	macro_in(3)  => plb_Sl_MErr_module(6),
	macro_in(4)  => plb_Sl_MErr_module(7),
	macro_in(5)  => plb_Sl_rdBTerm_module(3),
	macro_in(6)  => plb_Sl_rdComp_module(3),
	macro_in(7)  => plb_Sl_rdDAck_module(3),
	enable => macro_enable,
	macro_out(0) => plb_Sl_addrAck(3),
	macro_out(1) => plb_Sl_MBusy(6),
	macro_out(2) => plb_Sl_MBusy(7),
	macro_out(3) => plb_Sl_MErr(6),
	macro_out(4) => plb_Sl_MErr(7),
	macro_out(5) => plb_Sl_rdBTerm(3),
	macro_out(6) => plb_Sl_rdComp(3),
	macro_out(7) => plb_Sl_rdDAck(3)
    );

  macro_27 : busmacro_vector8_xc2vp_r2l_async_enable_narrow
    port map(
	macro_in(0)  => plb_Sl_wrBTerm_module(3),
	macro_in(1)  => plb_Sl_wrComp_module(3),
	macro_in(2)  => plb_Sl_wrDAck_module(3),
	macro_in(3)  => '0',
	macro_in(4)  => '0',
	macro_in(5)  => '0',
	macro_in(6)  => '0',
	macro_in(7)  => '0',
	enable => macro_enable,
	macro_out(0) => plb_Sl_wrBTerm(3),
	macro_out(1) => plb_Sl_wrComp(3),
	macro_out(2) => plb_Sl_wrDAck(3),
	macro_out(3) => open,
	macro_out(4) => open,
	macro_out(5) => open,
	macro_out(6) => open,
	macro_out(7) => open
    );

-----------------------------------------------------

-- additional clock buffer

  bufg_clk : BUFG
    port map (
      I => dcm_out_clk,
      O => sys_clk_s(0)
    );
    
-----------------------------------------------------
    



  ibuf_0 : IBUF
    port map (
      I => fpga_0_RS232_Uart_1_RX_pin,
      O => fpga_0_RS232_Uart_1_RX
    );

  obuf_1 : OBUF
    port map (
      I => fpga_0_RS232_Uart_1_TX,
      O => fpga_0_RS232_Uart_1_TX_pin
    );

  ibuf_2 : IBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_CLK_pin,
      O => fpga_0_SysACE_CompactFlash_SysACE_CLK
    );

  obuf_3 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPA(6),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPA_pin(6)
    );

  obuf_4 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPA(5),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPA_pin(5)
    );

  obuf_5 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPA(4),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPA_pin(4)
    );

  obuf_6 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPA(3),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPA_pin(3)
    );

  obuf_7 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPA(2),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPA_pin(2)
    );

  obuf_8 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPA(1),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPA_pin(1)
    );

  obuf_9 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPA(0),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPA_pin(0)
    );

  iobuf_10 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(15),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(15),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(15),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(15)
    );

  iobuf_11 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(14),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(14),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(14),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(14)
    );

  iobuf_12 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(13),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(13),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(13),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(13)
    );

  iobuf_13 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(12),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(12),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(12),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(12)
    );

  iobuf_14 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(11),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(11),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(11),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(11)
    );

  iobuf_15 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(10),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(10),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(10),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(10)
    );

  iobuf_16 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(9),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(9),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(9),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(9)
    );

  iobuf_17 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(8),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(8),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(8),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(8)
    );

  iobuf_18 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(7),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(7),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(7),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(7)
    );

  iobuf_19 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(6),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(6),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(6),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(6)
    );

  iobuf_20 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(5),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(5),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(5),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(5)
    );

  iobuf_21 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(4),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(4),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(4),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(4)
    );

  iobuf_22 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(3),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(3),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(3),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(3)
    );

  iobuf_23 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(2),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(2),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(2),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(2)
    );

  iobuf_24 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(1),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(1),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(1),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(1)
    );

  iobuf_25 : IOBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPD_O(0),
      IO => fpga_0_SysACE_CompactFlash_SysACE_MPD_pin(0),
      O => fpga_0_SysACE_CompactFlash_SysACE_MPD_I(0),
      T => fpga_0_SysACE_CompactFlash_SysACE_MPD_T(0)
    );

  obuf_26 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_CEN,
      O => fpga_0_SysACE_CompactFlash_SysACE_CEN_pin
    );

  obuf_27 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_OEN,
      O => fpga_0_SysACE_CompactFlash_SysACE_OEN_pin
    );

  obuf_28 : OBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_WEN,
      O => fpga_0_SysACE_CompactFlash_SysACE_WEN_pin
    );

  ibuf_29 : IBUF
    port map (
      I => fpga_0_SysACE_CompactFlash_SysACE_MPIRQ_pin,
      O => fpga_0_SysACE_CompactFlash_SysACE_MPIRQ
    );

  iobuf_30 : IOBUF
    port map (
      I => fpga_0_LEDs_4Bit_GPIO_IO_O(0),
      IO => fpga_0_LEDs_4Bit_GPIO_IO_pin(0),
      O => fpga_0_LEDs_4Bit_GPIO_IO_I(0),
      T => fpga_0_LEDs_4Bit_GPIO_IO_T(0)
    );

  iobuf_31 : IOBUF
    port map (
      I => fpga_0_LEDs_4Bit_GPIO_IO_O(1),
      IO => fpga_0_LEDs_4Bit_GPIO_IO_pin(1),
      O => fpga_0_LEDs_4Bit_GPIO_IO_I(1),
      T => fpga_0_LEDs_4Bit_GPIO_IO_T(1)
    );

  iobuf_32 : IOBUF
    port map (
      I => fpga_0_LEDs_4Bit_GPIO_IO_O(2),
      IO => fpga_0_LEDs_4Bit_GPIO_IO_pin(2),
      O => fpga_0_LEDs_4Bit_GPIO_IO_I(2),
      T => fpga_0_LEDs_4Bit_GPIO_IO_T(2)
    );

  iobuf_33 : IOBUF
    port map (
      I => fpga_0_LEDs_4Bit_GPIO_IO_O(3),
      IO => fpga_0_LEDs_4Bit_GPIO_IO_pin(3),
      O => fpga_0_LEDs_4Bit_GPIO_IO_I(3),
      T => fpga_0_LEDs_4Bit_GPIO_IO_T(3)
    );

  iobuf_34 : IOBUF
    port map (
      I => fpga_0_PushButtons_5Bit_GPIO_IO_O(0),
      IO => fpga_0_PushButtons_5Bit_GPIO_IO_pin(0),
      O => fpga_0_PushButtons_5Bit_GPIO_IO_I(0),
      T => fpga_0_PushButtons_5Bit_GPIO_IO_T(0)
    );

  iobuf_35 : IOBUF
    port map (
      I => fpga_0_PushButtons_5Bit_GPIO_IO_O(1),
      IO => fpga_0_PushButtons_5Bit_GPIO_IO_pin(1),
      O => fpga_0_PushButtons_5Bit_GPIO_IO_I(1),
      T => fpga_0_PushButtons_5Bit_GPIO_IO_T(1)
    );

  iobuf_36 : IOBUF
    port map (
      I => fpga_0_PushButtons_5Bit_GPIO_IO_O(2),
      IO => fpga_0_PushButtons_5Bit_GPIO_IO_pin(2),
      O => fpga_0_PushButtons_5Bit_GPIO_IO_I(2),
      T => fpga_0_PushButtons_5Bit_GPIO_IO_T(2)
    );

  iobuf_37 : IOBUF
    port map (
      I => fpga_0_PushButtons_5Bit_GPIO_IO_O(3),
      IO => fpga_0_PushButtons_5Bit_GPIO_IO_pin(3),
      O => fpga_0_PushButtons_5Bit_GPIO_IO_I(3),
      T => fpga_0_PushButtons_5Bit_GPIO_IO_T(3)
    );

  iobuf_38 : IOBUF
    port map (
      I => fpga_0_PushButtons_5Bit_GPIO_IO_O(4),
      IO => fpga_0_PushButtons_5Bit_GPIO_IO_pin(4),
      O => fpga_0_PushButtons_5Bit_GPIO_IO_I(4),
      T => fpga_0_PushButtons_5Bit_GPIO_IO_T(4)
    );

  obuf_39 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk_pin(0)
    );

  obuf_40 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk_pin(1)
    );

  obuf_41 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk(2),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clk_pin(2)
    );

  obuf_42 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn_pin(0)
    );

  obuf_43 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn_pin(1)
    );

  obuf_44 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn(2),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Clkn_pin(2)
    );

  obuf_45 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(0)
    );

  obuf_46 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(1)
    );

  obuf_47 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(2),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(2)
    );

  obuf_48 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(3),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(3)
    );

  obuf_49 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(4),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(4)
    );

  obuf_50 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(5),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(5)
    );

  obuf_51 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(6),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(6)
    );

  obuf_52 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(7),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(7)
    );

  obuf_53 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(8),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(8)
    );

  obuf_54 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(9),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(9)
    );

  obuf_55 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(10),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(10)
    );

  obuf_56 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(11),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(11)
    );

  obuf_57 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr(12),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_Addr_pin(12)
    );

  obuf_58 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_BankAddr(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_BankAddr_pin(0)
    );

  obuf_59 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_BankAddr(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_BankAddr_pin(1)
    );

  obuf_60 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CASn,
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CASn_pin
    );

  obuf_61 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_RASn,
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_RASn_pin
    );

  obuf_62 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_WEn,
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_WEn_pin
    );

  obuf_63 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(0)
    );

  obuf_64 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(1)
    );

  obuf_65 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(2),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(2)
    );

  obuf_66 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(3),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(3)
    );

  obuf_67 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(4),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(4)
    );

  obuf_68 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(5),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(5)
    );

  obuf_69 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(6),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(6)
    );

  obuf_70 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM(7),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DM_pin(7)
    );

  iobuf_71 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(0),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(0),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(0)
    );

  iobuf_72 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(1),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(1),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(1)
    );

  iobuf_73 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(2),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(2),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(2),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(2)
    );

  iobuf_74 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(3),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(3),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(3),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(3)
    );

  iobuf_75 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(4),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(4),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(4),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(4)
    );

  iobuf_76 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(5),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(5),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(5),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(5)
    );

  iobuf_77 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(6),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(6),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(6),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(6)
    );

  iobuf_78 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_O(7),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_pin(7),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_I(7),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQS_T(7)
    );

  iobuf_79 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(0),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(0),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(0)
    );

  iobuf_80 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(1),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(1),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(1)
    );

  iobuf_81 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(2),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(2),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(2),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(2)
    );

  iobuf_82 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(3),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(3),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(3),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(3)
    );

  iobuf_83 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(4),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(4),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(4),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(4)
    );

  iobuf_84 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(5),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(5),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(5),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(5)
    );

  iobuf_85 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(6),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(6),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(6),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(6)
    );

  iobuf_86 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(7),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(7),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(7),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(7)
    );

  iobuf_87 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(8),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(8),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(8),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(8)
    );

  iobuf_88 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(9),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(9),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(9),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(9)
    );

  iobuf_89 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(10),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(10),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(10),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(10)
    );

  iobuf_90 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(11),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(11),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(11),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(11)
    );

  iobuf_91 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(12),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(12),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(12),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(12)
    );

  iobuf_92 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(13),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(13),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(13),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(13)
    );

  iobuf_93 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(14),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(14),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(14),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(14)
    );

  iobuf_94 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(15),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(15),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(15),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(15)
    );

  iobuf_95 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(16),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(16),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(16),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(16)
    );

  iobuf_96 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(17),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(17),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(17),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(17)
    );

  iobuf_97 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(18),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(18),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(18),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(18)
    );

  iobuf_98 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(19),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(19),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(19),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(19)
    );

  iobuf_99 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(20),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(20),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(20),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(20)
    );

  iobuf_100 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(21),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(21),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(21),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(21)
    );

  iobuf_101 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(22),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(22),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(22),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(22)
    );

  iobuf_102 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(23),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(23),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(23),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(23)
    );

  iobuf_103 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(24),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(24),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(24),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(24)
    );

  iobuf_104 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(25),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(25),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(25),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(25)
    );

  iobuf_105 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(26),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(26),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(26),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(26)
    );

  iobuf_106 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(27),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(27),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(27),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(27)
    );

  iobuf_107 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(28),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(28),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(28),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(28)
    );

  iobuf_108 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(29),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(29),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(29),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(29)
    );

  iobuf_109 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(30),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(30),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(30),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(30)
    );

  iobuf_110 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(31),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(31),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(31),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(31)
    );

  iobuf_111 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(32),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(32),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(32),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(32)
    );

  iobuf_112 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(33),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(33),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(33),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(33)
    );

  iobuf_113 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(34),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(34),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(34),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(34)
    );

  iobuf_114 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(35),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(35),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(35),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(35)
    );

  iobuf_115 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(36),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(36),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(36),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(36)
    );

  iobuf_116 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(37),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(37),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(37),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(37)
    );

  iobuf_117 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(38),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(38),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(38),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(38)
    );

  iobuf_118 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(39),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(39),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(39),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(39)
    );

  iobuf_119 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(40),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(40),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(40),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(40)
    );

  iobuf_120 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(41),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(41),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(41),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(41)
    );

  iobuf_121 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(42),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(42),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(42),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(42)
    );

  iobuf_122 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(43),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(43),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(43),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(43)
    );

  iobuf_123 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(44),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(44),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(44),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(44)
    );

  iobuf_124 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(45),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(45),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(45),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(45)
    );

  iobuf_125 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(46),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(46),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(46),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(46)
    );

  iobuf_126 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(47),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(47),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(47),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(47)
    );

  iobuf_127 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(48),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(48),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(48),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(48)
    );

  iobuf_128 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(49),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(49),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(49),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(49)
    );

  iobuf_129 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(50),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(50),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(50),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(50)
    );

  iobuf_130 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(51),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(51),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(51),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(51)
    );

  iobuf_131 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(52),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(52),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(52),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(52)
    );

  iobuf_132 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(53),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(53),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(53),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(53)
    );

  iobuf_133 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(54),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(54),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(54),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(54)
    );

  iobuf_134 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(55),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(55),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(55),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(55)
    );

  iobuf_135 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(56),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(56),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(56),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(56)
    );

  iobuf_136 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(57),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(57),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(57),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(57)
    );

  iobuf_137 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(58),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(58),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(58),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(58)
    );

  iobuf_138 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(59),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(59),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(59),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(59)
    );

  iobuf_139 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(60),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(60),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(60),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(60)
    );

  iobuf_140 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(61),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(61),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(61),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(61)
    );

  iobuf_141 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(62),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(62),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(62),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(62)
    );

  iobuf_142 : IOBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_O(63),
      IO => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_pin(63),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_I(63),
      T => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_DQ_T(63)
    );

  obuf_143 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CKE(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CKE_pin(0)
    );

  obuf_144 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CKE(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CKE_pin(1)
    );

  obuf_145 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CSn(0),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CSn_pin(0)
    );

  obuf_146 : OBUF
    port map (
      I => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CSn(1),
      O => fpga_0_DDR_512MB_64Mx64_rank2_row13_col10_cl2_5_DDR_CSn_pin(1)
    );

  obuf_147 : OBUF
    port map (
      I => net_gnd0,
      O => fpga_0_net_gnd_pin
    );

  obuf_148 : OBUF
    port map (
      I => net_gnd0,
      O => fpga_0_net_gnd_1_pin
    );

  obuf_149 : OBUF
    port map (
      I => net_gnd0,
      O => fpga_0_net_gnd_2_pin
    );

  obuf_150 : OBUF
    port map (
      I => net_gnd0,
      O => fpga_0_net_gnd_3_pin
    );

  obuf_151 : OBUF
    port map (
      I => net_gnd0,
      O => fpga_0_net_gnd_4_pin
    );

  obuf_152 : OBUF
    port map (
      I => net_gnd0,
      O => fpga_0_net_gnd_5_pin
    );

  obuf_153 : OBUF
    port map (
      I => net_gnd0,
      O => fpga_0_net_gnd_6_pin
    );

  ibufg_154 : IBUFG
    port map (
      I => fpga_0_DDR_CLK_FB,
      O => ddr_feedback_s
    );

  obuf_155 : OBUF
    port map (
      I => ddr_clk_feedback_out_s,
      O => fpga_0_DDR_CLK_FB_OUT
    );

  ibufg_156 : IBUFG
    port map (
      I => sys_clk_pin,
      O => dcm_clk_s
    );

  ibuf_157 : IBUF
    port map (
      I => sys_rst_pin,
      O => sys_rst_s
    );
    



end architecture STRUCTURE;



