-------------------------------------------------------------------------------
-- bfm_system.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity bfm_system is
  port (
    sys_reset : in std_logic;
    sys_clk : in std_logic
  );
end bfm_system;

architecture STRUCTURE of bfm_system is

  component bfm_processor_wrapper is
    port (
      PLB_CLK : in std_logic;
      PLB_RESET : in std_logic;
      SYNCH_OUT : out std_logic_vector(0 to 31);
      SYNCH_IN : in std_logic_vector(0 to 31);
      PLB_MAddrAck : in std_logic;
      PLB_MSsize : in std_logic_vector(0 to 1);
      PLB_MRearbitrate : in std_logic;
      PLB_MTimeout : in std_logic;
      PLB_MBusy : in std_logic;
      PLB_MRdErr : in std_logic;
      PLB_MWrErr : in std_logic;
      PLB_MIRQ : in std_logic;
      PLB_MWrDAck : in std_logic;
      PLB_MRdDBus : in std_logic_vector(0 to 127);
      PLB_MRdWdAddr : in std_logic_vector(0 to 3);
      PLB_MRdDAck : in std_logic;
      PLB_MRdBTerm : in std_logic;
      PLB_MWrBTerm : in std_logic;
      M_request : out std_logic;
      M_priority : out std_logic_vector(0 to 1);
      M_buslock : out std_logic;
      M_RNW : out std_logic;
      M_BE : out std_logic_vector(0 to 15);
      M_msize : out std_logic_vector(0 to 1);
      M_size : out std_logic_vector(0 to 3);
      M_type : out std_logic_vector(0 to 2);
      M_TAttribute : out std_logic_vector(0 to 15);
      M_lockErr : out std_logic;
      M_abort : out std_logic;
      M_UABus : out std_logic_vector(0 to 31);
      M_ABus : out std_logic_vector(0 to 31);
      M_wrDBus : out std_logic_vector(0 to 127);
      M_wrBurst : out std_logic;
      M_rdBurst : out std_logic
    );
  end component;

  component bfm_memory_wrapper is
    port (
      PLB_CLK : in std_logic;
      PLB_RESET : in std_logic;
      SYNCH_OUT : out std_logic_vector(0 to 31);
      SYNCH_IN : in std_logic_vector(0 to 31);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic;
      PLB_wrPrim : in std_logic;
      PLB_masterID : in std_logic_vector(0 to 0);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 15);
      PLB_msize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      PLB_lockErr : in std_logic;
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_wrDBus : in std_logic_vector(0 to 127);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_rdpendReq : in std_logic;
      PLB_wrpendReq : in std_logic;
      PLB_rdpendPri : in std_logic_vector(0 to 1);
      PLB_wrpendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      Sl_addrAck : out std_logic;
      Sl_ssize : out std_logic_vector(0 to 1);
      Sl_wait : out std_logic;
      Sl_rearbitrate : out std_logic;
      Sl_wrDAck : out std_logic;
      Sl_wrComp : out std_logic;
      Sl_wrBTerm : out std_logic;
      Sl_rdDBus : out std_logic_vector(0 to 127);
      Sl_rdWdAddr : out std_logic_vector(0 to 3);
      Sl_rdDAck : out std_logic;
      Sl_rdComp : out std_logic;
      Sl_rdBTerm : out std_logic;
      Sl_MBusy : out std_logic_vector(0 to 1);
      Sl_MRdErr : out std_logic_vector(0 to 1);
      Sl_MWrErr : out std_logic_vector(0 to 1);
      Sl_MIRQ : out std_logic_vector(0 to 1)
    );
  end component;

  component bfm_monitor_wrapper is
    port (
      PLB_CLK : in std_logic;
      PLB_RESET : in std_logic;
      SYNCH_OUT : out std_logic_vector(0 to 31);
      SYNCH_IN : in std_logic_vector(0 to 31);
      M_request : in std_logic_vector(0 to 1);
      M_priority : in std_logic_vector(0 to 3);
      M_buslock : in std_logic_vector(0 to 1);
      M_RNW : in std_logic_vector(0 to 1);
      M_BE : in std_logic_vector(0 to 31);
      M_msize : in std_logic_vector(0 to 3);
      M_size : in std_logic_vector(0 to 7);
      M_type : in std_logic_vector(0 to 5);
      M_TAttribute : in std_logic_vector(0 to 31);
      M_lockErr : in std_logic_vector(0 to 1);
      M_abort : in std_logic_vector(0 to 1);
      M_UABus : in std_logic_vector(0 to 63);
      M_ABus : in std_logic_vector(0 to 63);
      M_wrDBus : in std_logic_vector(0 to 255);
      M_wrBurst : in std_logic_vector(0 to 1);
      M_rdBurst : in std_logic_vector(0 to 1);
      PLB_MAddrAck : in std_logic_vector(0 to 1);
      PLB_MRearbitrate : in std_logic_vector(0 to 1);
      PLB_MTimeout : in std_logic_vector(0 to 1);
      PLB_MBusy : in std_logic_vector(0 to 1);
      PLB_MRdErr : in std_logic_vector(0 to 1);
      PLB_MWrErr : in std_logic_vector(0 to 1);
      PLB_MIRQ : in std_logic_vector(0 to 1);
      PLB_MWrDAck : in std_logic_vector(0 to 1);
      PLB_MRdDBus : in std_logic_vector(0 to 255);
      PLB_MRdWdAddr : in std_logic_vector(0 to 7);
      PLB_MRdDAck : in std_logic_vector(0 to 1);
      PLB_MRdBTerm : in std_logic_vector(0 to 1);
      PLB_MWrBTerm : in std_logic_vector(0 to 1);
      PLB_Mssize : in std_logic_vector(0 to 3);
      PLB_PAValid : in std_logic;
      PLB_SAValid : in std_logic;
      PLB_rdPrim : in std_logic_vector(0 to 0);
      PLB_wrPrim : in std_logic_vector(0 to 0);
      PLB_MasterID : in std_logic_vector(0 to 0);
      PLB_abort : in std_logic;
      PLB_busLock : in std_logic;
      PLB_RNW : in std_logic;
      PLB_BE : in std_logic_vector(0 to 15);
      PLB_msize : in std_logic_vector(0 to 1);
      PLB_size : in std_logic_vector(0 to 3);
      PLB_type : in std_logic_vector(0 to 2);
      PLB_TAttribute : in std_logic_vector(0 to 15);
      PLB_lockErr : in std_logic;
      PLB_UABus : in std_logic_vector(0 to 31);
      PLB_ABus : in std_logic_vector(0 to 31);
      PLB_wrDBus : in std_logic_vector(0 to 127);
      PLB_wrBurst : in std_logic;
      PLB_rdBurst : in std_logic;
      PLB_rdpendReq : in std_logic;
      PLB_wrpendReq : in std_logic;
      PLB_rdpendPri : in std_logic_vector(0 to 1);
      PLB_wrpendPri : in std_logic_vector(0 to 1);
      PLB_reqPri : in std_logic_vector(0 to 1);
      Sl_addrAck : in std_logic_vector(0 to 0);
      Sl_wait : in std_logic_vector(0 to 0);
      Sl_rearbitrate : in std_logic_vector(0 to 0);
      Sl_wrDAck : in std_logic_vector(0 to 0);
      Sl_wrComp : in std_logic_vector(0 to 0);
      Sl_wrBTerm : in std_logic_vector(0 to 0);
      Sl_rdDBus : in std_logic_vector(0 to 127);
      Sl_rdWdAddr : in std_logic_vector(0 to 3);
      Sl_rdDAck : in std_logic_vector(0 to 0);
      Sl_rdComp : in std_logic_vector(0 to 0);
      Sl_rdBTerm : in std_logic_vector(0 to 0);
      Sl_MBusy : in std_logic_vector(0 to 1);
      Sl_MRdErr : in std_logic_vector(0 to 1);
      Sl_MWrErr : in std_logic_vector(0 to 1);
      Sl_MIRQ : in std_logic_vector(0 to 1);
      Sl_ssize : in std_logic_vector(0 to 1);
      PLB_SaddrAck : in std_logic;
      PLB_Swait : in std_logic;
      PLB_Srearbitrate : in std_logic;
      PLB_SwrDAck : in std_logic;
      PLB_SwrComp : in std_logic;
      PLB_SwrBTerm : in std_logic;
      PLB_SrdDBus : in std_logic_vector(0 to 127);
      PLB_SrdWdAddr : in std_logic_vector(0 to 3);
      PLB_SrdDAck : in std_logic;
      PLB_SrdComp : in std_logic;
      PLB_SrdBTerm : in std_logic;
      PLB_SMBusy : in std_logic_vector(0 to 1);
      PLB_SMRdErr : in std_logic_vector(0 to 1);
      PLB_SMWrErr : in std_logic_vector(0 to 1);
      PLB_SMIRQ : in std_logic_vector(0 to 1);
      PLB_Sssize : in std_logic_vector(0 to 1)
    );
  end component;

  component synch_bus_wrapper is
    port (
      FROM_SYNCH_OUT : in std_logic_vector(0 to 127);
      TO_SYNCH_IN : out std_logic_vector(0 to 31)
    );
  end component;

  component plb_bus_wrapper is
    port (
      PLB_Clk : in std_logic;
      SYS_Rst : in std_logic;
      PLB_Rst : out std_logic;
      SPLB_Rst : out std_logic_vector(0 to 0);
      MPLB_Rst : out std_logic_vector(0 to 1);
      PLB_dcrAck : out std_logic;
      PLB_dcrDBus : out std_logic_vector(0 to 31);
      DCR_ABus : in std_logic_vector(0 to 9);
      DCR_DBus : in std_logic_vector(0 to 31);
      DCR_Read : in std_logic;
      DCR_Write : in std_logic;
      M_ABus : in std_logic_vector(0 to 63);
      M_UABus : in std_logic_vector(0 to 63);
      M_BE : in std_logic_vector(0 to 31);
      M_RNW : in std_logic_vector(0 to 1);
      M_abort : in std_logic_vector(0 to 1);
      M_busLock : in std_logic_vector(0 to 1);
      M_TAttribute : in std_logic_vector(0 to 31);
      M_lockErr : in std_logic_vector(0 to 1);
      M_MSize : in std_logic_vector(0 to 3);
      M_priority : in std_logic_vector(0 to 3);
      M_rdBurst : in std_logic_vector(0 to 1);
      M_request : in std_logic_vector(0 to 1);
      M_size : in std_logic_vector(0 to 7);
      M_type : in std_logic_vector(0 to 5);
      M_wrBurst : in std_logic_vector(0 to 1);
      M_wrDBus : in std_logic_vector(0 to 255);
      Sl_addrAck : in std_logic_vector(0 to 0);
      Sl_MRdErr : in std_logic_vector(0 to 1);
      Sl_MWrErr : in std_logic_vector(0 to 1);
      Sl_MBusy : in std_logic_vector(0 to 1);
      Sl_rdBTerm : in std_logic_vector(0 to 0);
      Sl_rdComp : in std_logic_vector(0 to 0);
      Sl_rdDAck : in std_logic_vector(0 to 0);
      Sl_rdDBus : in std_logic_vector(0 to 127);
      Sl_rdWdAddr : in std_logic_vector(0 to 3);
      Sl_rearbitrate : in std_logic_vector(0 to 0);
      Sl_SSize : in std_logic_vector(0 to 1);
      Sl_wait : in std_logic_vector(0 to 0);
      Sl_wrBTerm : in std_logic_vector(0 to 0);
      Sl_wrComp : in std_logic_vector(0 to 0);
      Sl_wrDAck : in std_logic_vector(0 to 0);
      Sl_MIRQ : in std_logic_vector(0 to 1);
      PLB_MIRQ : out std_logic_vector(0 to 1);
      PLB_ABus : out std_logic_vector(0 to 31);
      PLB_UABus : out std_logic_vector(0 to 31);
      PLB_BE : out std_logic_vector(0 to 15);
      PLB_MAddrAck : out std_logic_vector(0 to 1);
      PLB_MTimeout : out std_logic_vector(0 to 1);
      PLB_MBusy : out std_logic_vector(0 to 1);
      PLB_MRdErr : out std_logic_vector(0 to 1);
      PLB_MWrErr : out std_logic_vector(0 to 1);
      PLB_MRdBTerm : out std_logic_vector(0 to 1);
      PLB_MRdDAck : out std_logic_vector(0 to 1);
      PLB_MRdDBus : out std_logic_vector(0 to 255);
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
      PLB_TAttribute : out std_logic_vector(0 to 15);
      PLB_lockErr : out std_logic;
      PLB_masterID : out std_logic_vector(0 to 0);
      PLB_MSize : out std_logic_vector(0 to 1);
      PLB_rdPendPri : out std_logic_vector(0 to 1);
      PLB_wrPendPri : out std_logic_vector(0 to 1);
      PLB_rdPendReq : out std_logic;
      PLB_wrPendReq : out std_logic;
      PLB_rdBurst : out std_logic;
      PLB_rdPrim : out std_logic_vector(0 to 0);
      PLB_reqPri : out std_logic_vector(0 to 1);
      PLB_size : out std_logic_vector(0 to 3);
      PLB_type : out std_logic_vector(0 to 2);
      PLB_wrBurst : out std_logic;
      PLB_wrDBus : out std_logic_vector(0 to 127);
      PLB_wrPrim : out std_logic_vector(0 to 0);
      PLB_SaddrAck : out std_logic;
      PLB_SMRdErr : out std_logic_vector(0 to 1);
      PLB_SMWrErr : out std_logic_vector(0 to 1);
      PLB_SMBusy : out std_logic_vector(0 to 1);
      PLB_SrdBTerm : out std_logic;
      PLB_SrdComp : out std_logic;
      PLB_SrdDAck : out std_logic;
      PLB_SrdDBus : out std_logic_vector(0 to 127);
      PLB_SrdWdAddr : out std_logic_vector(0 to 3);
      PLB_Srearbitrate : out std_logic;
      PLB_Sssize : out std_logic_vector(0 to 1);
      PLB_Swait : out std_logic;
      PLB_SwrBTerm : out std_logic;
      PLB_SwrComp : out std_logic;
      PLB_SwrDAck : out std_logic;
      PLB2OPB_rearb : in std_logic_vector(0 to 0);
      Bus_Error_Det : out std_logic
    );
  end component;

  component my_core_wrapper is
    port (
      MPLB_Clk : in std_logic;
      MPLB_Rst : in std_logic;
      M_request : out std_logic;
      M_priority : out std_logic_vector(0 to 1);
      M_busLock : out std_logic;
      M_RNW : out std_logic;
      M_BE : out std_logic_vector(0 to 15);
      M_MSize : out std_logic_vector(0 to 1);
      M_size : out std_logic_vector(0 to 3);
      M_type : out std_logic_vector(0 to 2);
      M_TAttribute : out std_logic_vector(0 to 15);
      M_lockErr : out std_logic;
      M_abort : out std_logic;
      M_UABus : out std_logic_vector(0 to 31);
      M_ABus : out std_logic_vector(0 to 31);
      M_wrDBus : out std_logic_vector(0 to 127);
      M_wrBurst : out std_logic;
      M_rdBurst : out std_logic;
      PLB_MAddrAck : in std_logic;
      PLB_MSSize : in std_logic_vector(0 to 1);
      PLB_MRearbitrate : in std_logic;
      PLB_MTimeout : in std_logic;
      PLB_MBusy : in std_logic;
      PLB_MRdErr : in std_logic;
      PLB_MWrErr : in std_logic;
      PLB_MIRQ : in std_logic;
      PLB_MRdDBus : in std_logic_vector(0 to 127);
      PLB_MRdWdAddr : in std_logic_vector(0 to 3);
      PLB_MRdDAck : in std_logic;
      PLB_MRdBTerm : in std_logic;
      PLB_MWrDAck : in std_logic;
      PLB_MWrBTerm : in std_logic;
      SYNCH_IN : in std_logic_vector(0 to 31);
      SYNCH_OUT : out std_logic_vector(0 to 31)
    );
  end component;

  -- Internal signals

  signal net_gnd0 : std_logic;
  signal net_gnd1 : std_logic_vector(0 to 0);
  signal net_gnd2 : std_logic_vector(0 to 1);
  signal net_gnd10 : std_logic_vector(0 to 9);
  signal net_gnd32 : std_logic_vector(0 to 31);
  signal pgassign1 : std_logic_vector(0 to 127);
  signal plb_bus_MPLB_Rst : std_logic_vector(0 to 1);
  signal plb_bus_M_ABus : std_logic_vector(0 to 63);
  signal plb_bus_M_BE : std_logic_vector(0 to 31);
  signal plb_bus_M_MSize : std_logic_vector(0 to 3);
  signal plb_bus_M_RNW : std_logic_vector(0 to 1);
  signal plb_bus_M_TAttribute : std_logic_vector(0 to 31);
  signal plb_bus_M_UABus : std_logic_vector(0 to 63);
  signal plb_bus_M_abort : std_logic_vector(0 to 1);
  signal plb_bus_M_busLock : std_logic_vector(0 to 1);
  signal plb_bus_M_lockErr : std_logic_vector(0 to 1);
  signal plb_bus_M_priority : std_logic_vector(0 to 3);
  signal plb_bus_M_rdBurst : std_logic_vector(0 to 1);
  signal plb_bus_M_request : std_logic_vector(0 to 1);
  signal plb_bus_M_size : std_logic_vector(0 to 7);
  signal plb_bus_M_type : std_logic_vector(0 to 5);
  signal plb_bus_M_wrBurst : std_logic_vector(0 to 1);
  signal plb_bus_M_wrDBus : std_logic_vector(0 to 255);
  signal plb_bus_PLB_ABus : std_logic_vector(0 to 31);
  signal plb_bus_PLB_BE : std_logic_vector(0 to 15);
  signal plb_bus_PLB_MAddrAck : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MBusy : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MIRQ : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MRdBTerm : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MRdDAck : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MRdDBus : std_logic_vector(0 to 255);
  signal plb_bus_PLB_MRdErr : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MRdWdAddr : std_logic_vector(0 to 7);
  signal plb_bus_PLB_MRearbitrate : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MSSize : std_logic_vector(0 to 3);
  signal plb_bus_PLB_MSize : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MTimeout : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MWrBTerm : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MWrDAck : std_logic_vector(0 to 1);
  signal plb_bus_PLB_MWrErr : std_logic_vector(0 to 1);
  signal plb_bus_PLB_PAValid : std_logic;
  signal plb_bus_PLB_RNW : std_logic;
  signal plb_bus_PLB_Rst : std_logic;
  signal plb_bus_PLB_SAValid : std_logic;
  signal plb_bus_PLB_SMBusy : std_logic_vector(0 to 1);
  signal plb_bus_PLB_SMRdErr : std_logic_vector(0 to 1);
  signal plb_bus_PLB_SMWrErr : std_logic_vector(0 to 1);
  signal plb_bus_PLB_SaddrAck : std_logic;
  signal plb_bus_PLB_SrdBTerm : std_logic;
  signal plb_bus_PLB_SrdComp : std_logic;
  signal plb_bus_PLB_SrdDAck : std_logic;
  signal plb_bus_PLB_SrdDBus : std_logic_vector(0 to 127);
  signal plb_bus_PLB_SrdWdAddr : std_logic_vector(0 to 3);
  signal plb_bus_PLB_Srearbitrate : std_logic;
  signal plb_bus_PLB_Sssize : std_logic_vector(0 to 1);
  signal plb_bus_PLB_Swait : std_logic;
  signal plb_bus_PLB_SwrBTerm : std_logic;
  signal plb_bus_PLB_SwrComp : std_logic;
  signal plb_bus_PLB_SwrDAck : std_logic;
  signal plb_bus_PLB_TAttribute : std_logic_vector(0 to 15);
  signal plb_bus_PLB_UABus : std_logic_vector(0 to 31);
  signal plb_bus_PLB_abort : std_logic;
  signal plb_bus_PLB_busLock : std_logic;
  signal plb_bus_PLB_lockErr : std_logic;
  signal plb_bus_PLB_masterID : std_logic_vector(0 to 0);
  signal plb_bus_PLB_rdBurst : std_logic;
  signal plb_bus_PLB_rdPrim : std_logic_vector(0 to 0);
  signal plb_bus_PLB_rdpendPri : std_logic_vector(0 to 1);
  signal plb_bus_PLB_rdpendReq : std_logic;
  signal plb_bus_PLB_reqPri : std_logic_vector(0 to 1);
  signal plb_bus_PLB_size : std_logic_vector(0 to 3);
  signal plb_bus_PLB_type : std_logic_vector(0 to 2);
  signal plb_bus_PLB_wrBurst : std_logic;
  signal plb_bus_PLB_wrDBus : std_logic_vector(0 to 127);
  signal plb_bus_PLB_wrPrim : std_logic_vector(0 to 0);
  signal plb_bus_PLB_wrpendPri : std_logic_vector(0 to 1);
  signal plb_bus_PLB_wrpendReq : std_logic;
  signal plb_bus_Sl_MBusy : std_logic_vector(0 to 1);
  signal plb_bus_Sl_MIRQ : std_logic_vector(0 to 1);
  signal plb_bus_Sl_MRdErr : std_logic_vector(0 to 1);
  signal plb_bus_Sl_MWrErr : std_logic_vector(0 to 1);
  signal plb_bus_Sl_SSize : std_logic_vector(0 to 1);
  signal plb_bus_Sl_addrAck : std_logic_vector(0 to 0);
  signal plb_bus_Sl_rdBTerm : std_logic_vector(0 to 0);
  signal plb_bus_Sl_rdComp : std_logic_vector(0 to 0);
  signal plb_bus_Sl_rdDAck : std_logic_vector(0 to 0);
  signal plb_bus_Sl_rdDBus : std_logic_vector(0 to 127);
  signal plb_bus_Sl_rdWdAddr : std_logic_vector(0 to 3);
  signal plb_bus_Sl_rearbitrate : std_logic_vector(0 to 0);
  signal plb_bus_Sl_wait : std_logic_vector(0 to 0);
  signal plb_bus_Sl_wrBTerm : std_logic_vector(0 to 0);
  signal plb_bus_Sl_wrComp : std_logic_vector(0 to 0);
  signal plb_bus_Sl_wrDAck : std_logic_vector(0 to 0);
  signal synch : std_logic_vector(0 to 31);
  signal synch0 : std_logic_vector(0 to 31);
  signal synch1 : std_logic_vector(0 to 31);
  signal synch2 : std_logic_vector(0 to 31);
  signal synch3 : std_logic_vector(0 to 31);

begin

  -- Internal assignments

  pgassign1(0 to 31) <= synch0(0 to 31);
  pgassign1(32 to 63) <= synch1(0 to 31);
  pgassign1(64 to 95) <= synch2(0 to 31);
  pgassign1(96 to 127) <= synch3(0 to 31);
  net_gnd0 <= '0';
  net_gnd1(0 to 0) <= B"0";
  net_gnd10(0 to 9) <= B"0000000000";
  net_gnd2(0 to 1) <= B"00";
  net_gnd32(0 to 31) <= B"00000000000000000000000000000000";

  bfm_processor : bfm_processor_wrapper
    port map (
      PLB_CLK => sys_clk,
      PLB_RESET => plb_bus_PLB_Rst,
      SYNCH_OUT => synch0,
      SYNCH_IN => synch,
      PLB_MAddrAck => plb_bus_PLB_MAddrAck(0),
      PLB_MSsize => plb_bus_PLB_MSSize(0 to 1),
      PLB_MRearbitrate => plb_bus_PLB_MRearbitrate(0),
      PLB_MTimeout => plb_bus_PLB_MTimeout(0),
      PLB_MBusy => plb_bus_PLB_MBusy(0),
      PLB_MRdErr => plb_bus_PLB_MRdErr(0),
      PLB_MWrErr => plb_bus_PLB_MWrErr(0),
      PLB_MIRQ => plb_bus_PLB_MIRQ(0),
      PLB_MWrDAck => plb_bus_PLB_MWrDAck(0),
      PLB_MRdDBus => plb_bus_PLB_MRdDBus(0 to 127),
      PLB_MRdWdAddr => plb_bus_PLB_MRdWdAddr(0 to 3),
      PLB_MRdDAck => plb_bus_PLB_MRdDAck(0),
      PLB_MRdBTerm => plb_bus_PLB_MRdBTerm(0),
      PLB_MWrBTerm => plb_bus_PLB_MWrBTerm(0),
      M_request => plb_bus_M_request(0),
      M_priority => plb_bus_M_priority(0 to 1),
      M_buslock => plb_bus_M_busLock(0),
      M_RNW => plb_bus_M_RNW(0),
      M_BE => plb_bus_M_BE(0 to 15),
      M_msize => plb_bus_M_MSize(0 to 1),
      M_size => plb_bus_M_size(0 to 3),
      M_type => plb_bus_M_type(0 to 2),
      M_TAttribute => plb_bus_M_TAttribute(0 to 15),
      M_lockErr => plb_bus_M_lockErr(0),
      M_abort => plb_bus_M_abort(0),
      M_UABus => plb_bus_M_UABus(0 to 31),
      M_ABus => plb_bus_M_ABus(0 to 31),
      M_wrDBus => plb_bus_M_wrDBus(0 to 127),
      M_wrBurst => plb_bus_M_wrBurst(0),
      M_rdBurst => plb_bus_M_rdBurst(0)
    );

  bfm_memory : bfm_memory_wrapper
    port map (
      PLB_CLK => sys_clk,
      PLB_RESET => plb_bus_PLB_Rst,
      SYNCH_OUT => synch1,
      SYNCH_IN => synch,
      PLB_PAValid => plb_bus_PLB_PAValid,
      PLB_SAValid => plb_bus_PLB_SAValid,
      PLB_rdPrim => plb_bus_PLB_rdPrim(0),
      PLB_wrPrim => plb_bus_PLB_wrPrim(0),
      PLB_masterID => plb_bus_PLB_masterID(0 to 0),
      PLB_abort => plb_bus_PLB_abort,
      PLB_busLock => plb_bus_PLB_busLock,
      PLB_RNW => plb_bus_PLB_RNW,
      PLB_BE => plb_bus_PLB_BE,
      PLB_msize => plb_bus_PLB_MSize,
      PLB_size => plb_bus_PLB_size,
      PLB_type => plb_bus_PLB_type,
      PLB_TAttribute => plb_bus_PLB_TAttribute,
      PLB_lockErr => plb_bus_PLB_lockErr,
      PLB_UABus => plb_bus_PLB_UABus,
      PLB_ABus => plb_bus_PLB_ABus,
      PLB_wrDBus => plb_bus_PLB_wrDBus,
      PLB_wrBurst => plb_bus_PLB_wrBurst,
      PLB_rdBurst => plb_bus_PLB_rdBurst,
      PLB_rdpendReq => plb_bus_PLB_rdpendReq,
      PLB_wrpendReq => plb_bus_PLB_wrpendReq,
      PLB_rdpendPri => plb_bus_PLB_rdpendPri,
      PLB_wrpendPri => plb_bus_PLB_wrpendPri,
      PLB_reqPri => plb_bus_PLB_reqPri,
      Sl_addrAck => plb_bus_Sl_addrAck(0),
      Sl_ssize => plb_bus_Sl_SSize,
      Sl_wait => plb_bus_Sl_wait(0),
      Sl_rearbitrate => plb_bus_Sl_rearbitrate(0),
      Sl_wrDAck => plb_bus_Sl_wrDAck(0),
      Sl_wrComp => plb_bus_Sl_wrComp(0),
      Sl_wrBTerm => plb_bus_Sl_wrBTerm(0),
      Sl_rdDBus => plb_bus_Sl_rdDBus,
      Sl_rdWdAddr => plb_bus_Sl_rdWdAddr,
      Sl_rdDAck => plb_bus_Sl_rdDAck(0),
      Sl_rdComp => plb_bus_Sl_rdComp(0),
      Sl_rdBTerm => plb_bus_Sl_rdBTerm(0),
      Sl_MBusy => plb_bus_Sl_MBusy,
      Sl_MRdErr => plb_bus_Sl_MRdErr,
      Sl_MWrErr => plb_bus_Sl_MWrErr,
      Sl_MIRQ => plb_bus_Sl_MIRQ
    );

  bfm_monitor : bfm_monitor_wrapper
    port map (
      PLB_CLK => sys_clk,
      PLB_RESET => plb_bus_PLB_Rst,
      SYNCH_OUT => synch2,
      SYNCH_IN => synch,
      M_request => plb_bus_M_request,
      M_priority => plb_bus_M_priority,
      M_buslock => plb_bus_M_busLock,
      M_RNW => plb_bus_M_RNW,
      M_BE => plb_bus_M_BE,
      M_msize => plb_bus_M_MSize,
      M_size => plb_bus_M_size,
      M_type => plb_bus_M_type,
      M_TAttribute => plb_bus_M_TAttribute,
      M_lockErr => plb_bus_M_lockErr,
      M_abort => plb_bus_M_abort,
      M_UABus => plb_bus_M_UABus,
      M_ABus => plb_bus_M_ABus,
      M_wrDBus => plb_bus_M_wrDBus,
      M_wrBurst => plb_bus_M_wrBurst,
      M_rdBurst => plb_bus_M_rdBurst,
      PLB_MAddrAck => plb_bus_PLB_MAddrAck,
      PLB_MRearbitrate => plb_bus_PLB_MRearbitrate,
      PLB_MTimeout => plb_bus_PLB_MTimeout,
      PLB_MBusy => plb_bus_PLB_MBusy,
      PLB_MRdErr => plb_bus_PLB_MRdErr,
      PLB_MWrErr => plb_bus_PLB_MWrErr,
      PLB_MIRQ => plb_bus_PLB_MIRQ,
      PLB_MWrDAck => plb_bus_PLB_MWrDAck,
      PLB_MRdDBus => plb_bus_PLB_MRdDBus,
      PLB_MRdWdAddr => plb_bus_PLB_MRdWdAddr,
      PLB_MRdDAck => plb_bus_PLB_MRdDAck,
      PLB_MRdBTerm => plb_bus_PLB_MRdBTerm,
      PLB_MWrBTerm => plb_bus_PLB_MWrBTerm,
      PLB_Mssize => plb_bus_PLB_MSSize,
      PLB_PAValid => plb_bus_PLB_PAValid,
      PLB_SAValid => plb_bus_PLB_SAValid,
      PLB_rdPrim => plb_bus_PLB_rdPrim(0 to 0),
      PLB_wrPrim => plb_bus_PLB_wrPrim(0 to 0),
      PLB_MasterID => plb_bus_PLB_masterID(0 to 0),
      PLB_abort => plb_bus_PLB_abort,
      PLB_busLock => plb_bus_PLB_busLock,
      PLB_RNW => plb_bus_PLB_RNW,
      PLB_BE => plb_bus_PLB_BE,
      PLB_msize => plb_bus_PLB_MSize,
      PLB_size => plb_bus_PLB_size,
      PLB_type => plb_bus_PLB_type,
      PLB_TAttribute => plb_bus_PLB_TAttribute,
      PLB_lockErr => plb_bus_PLB_lockErr,
      PLB_UABus => plb_bus_PLB_UABus,
      PLB_ABus => plb_bus_PLB_ABus,
      PLB_wrDBus => plb_bus_PLB_wrDBus,
      PLB_wrBurst => plb_bus_PLB_wrBurst,
      PLB_rdBurst => plb_bus_PLB_rdBurst,
      PLB_rdpendReq => plb_bus_PLB_rdpendReq,
      PLB_wrpendReq => plb_bus_PLB_wrpendReq,
      PLB_rdpendPri => plb_bus_PLB_rdpendPri,
      PLB_wrpendPri => plb_bus_PLB_wrpendPri,
      PLB_reqPri => plb_bus_PLB_reqPri,
      Sl_addrAck => plb_bus_Sl_addrAck(0 to 0),
      Sl_wait => plb_bus_Sl_wait(0 to 0),
      Sl_rearbitrate => plb_bus_Sl_rearbitrate(0 to 0),
      Sl_wrDAck => plb_bus_Sl_wrDAck(0 to 0),
      Sl_wrComp => plb_bus_Sl_wrComp(0 to 0),
      Sl_wrBTerm => plb_bus_Sl_wrBTerm(0 to 0),
      Sl_rdDBus => plb_bus_Sl_rdDBus,
      Sl_rdWdAddr => plb_bus_Sl_rdWdAddr,
      Sl_rdDAck => plb_bus_Sl_rdDAck(0 to 0),
      Sl_rdComp => plb_bus_Sl_rdComp(0 to 0),
      Sl_rdBTerm => plb_bus_Sl_rdBTerm(0 to 0),
      Sl_MBusy => plb_bus_Sl_MBusy,
      Sl_MRdErr => plb_bus_Sl_MRdErr,
      Sl_MWrErr => plb_bus_Sl_MWrErr,
      Sl_MIRQ => plb_bus_Sl_MIRQ,
      Sl_ssize => plb_bus_Sl_SSize,
      PLB_SaddrAck => plb_bus_PLB_SaddrAck,
      PLB_Swait => plb_bus_PLB_Swait,
      PLB_Srearbitrate => plb_bus_PLB_Srearbitrate,
      PLB_SwrDAck => plb_bus_PLB_SwrDAck,
      PLB_SwrComp => plb_bus_PLB_SwrComp,
      PLB_SwrBTerm => plb_bus_PLB_SwrBTerm,
      PLB_SrdDBus => plb_bus_PLB_SrdDBus,
      PLB_SrdWdAddr => plb_bus_PLB_SrdWdAddr,
      PLB_SrdDAck => plb_bus_PLB_SrdDAck,
      PLB_SrdComp => plb_bus_PLB_SrdComp,
      PLB_SrdBTerm => plb_bus_PLB_SrdBTerm,
      PLB_SMBusy => plb_bus_PLB_SMBusy,
      PLB_SMRdErr => plb_bus_PLB_SMRdErr,
      PLB_SMWrErr => plb_bus_PLB_SMWrErr,
      PLB_SMIRQ => net_gnd2,
      PLB_Sssize => plb_bus_PLB_Sssize
    );

  synch_bus : synch_bus_wrapper
    port map (
      FROM_SYNCH_OUT => pgassign1,
      TO_SYNCH_IN => synch
    );

  plb_bus : plb_bus_wrapper
    port map (
      PLB_Clk => sys_clk,
      SYS_Rst => sys_reset,
      PLB_Rst => plb_bus_PLB_Rst,
      SPLB_Rst => open,
      MPLB_Rst => plb_bus_MPLB_Rst,
      PLB_dcrAck => open,
      PLB_dcrDBus => open,
      DCR_ABus => net_gnd10,
      DCR_DBus => net_gnd32,
      DCR_Read => net_gnd0,
      DCR_Write => net_gnd0,
      M_ABus => plb_bus_M_ABus,
      M_UABus => plb_bus_M_UABus,
      M_BE => plb_bus_M_BE,
      M_RNW => plb_bus_M_RNW,
      M_abort => plb_bus_M_abort,
      M_busLock => plb_bus_M_busLock,
      M_TAttribute => plb_bus_M_TAttribute,
      M_lockErr => plb_bus_M_lockErr,
      M_MSize => plb_bus_M_MSize,
      M_priority => plb_bus_M_priority,
      M_rdBurst => plb_bus_M_rdBurst,
      M_request => plb_bus_M_request,
      M_size => plb_bus_M_size,
      M_type => plb_bus_M_type,
      M_wrBurst => plb_bus_M_wrBurst,
      M_wrDBus => plb_bus_M_wrDBus,
      Sl_addrAck => plb_bus_Sl_addrAck(0 to 0),
      Sl_MRdErr => plb_bus_Sl_MRdErr,
      Sl_MWrErr => plb_bus_Sl_MWrErr,
      Sl_MBusy => plb_bus_Sl_MBusy,
      Sl_rdBTerm => plb_bus_Sl_rdBTerm(0 to 0),
      Sl_rdComp => plb_bus_Sl_rdComp(0 to 0),
      Sl_rdDAck => plb_bus_Sl_rdDAck(0 to 0),
      Sl_rdDBus => plb_bus_Sl_rdDBus,
      Sl_rdWdAddr => plb_bus_Sl_rdWdAddr,
      Sl_rearbitrate => plb_bus_Sl_rearbitrate(0 to 0),
      Sl_SSize => plb_bus_Sl_SSize,
      Sl_wait => plb_bus_Sl_wait(0 to 0),
      Sl_wrBTerm => plb_bus_Sl_wrBTerm(0 to 0),
      Sl_wrComp => plb_bus_Sl_wrComp(0 to 0),
      Sl_wrDAck => plb_bus_Sl_wrDAck(0 to 0),
      Sl_MIRQ => plb_bus_Sl_MIRQ,
      PLB_MIRQ => plb_bus_PLB_MIRQ,
      PLB_ABus => plb_bus_PLB_ABus,
      PLB_UABus => plb_bus_PLB_UABus,
      PLB_BE => plb_bus_PLB_BE,
      PLB_MAddrAck => plb_bus_PLB_MAddrAck,
      PLB_MTimeout => plb_bus_PLB_MTimeout,
      PLB_MBusy => plb_bus_PLB_MBusy,
      PLB_MRdErr => plb_bus_PLB_MRdErr,
      PLB_MWrErr => plb_bus_PLB_MWrErr,
      PLB_MRdBTerm => plb_bus_PLB_MRdBTerm,
      PLB_MRdDAck => plb_bus_PLB_MRdDAck,
      PLB_MRdDBus => plb_bus_PLB_MRdDBus,
      PLB_MRdWdAddr => plb_bus_PLB_MRdWdAddr,
      PLB_MRearbitrate => plb_bus_PLB_MRearbitrate,
      PLB_MWrBTerm => plb_bus_PLB_MWrBTerm,
      PLB_MWrDAck => plb_bus_PLB_MWrDAck,
      PLB_MSSize => plb_bus_PLB_MSSize,
      PLB_PAValid => plb_bus_PLB_PAValid,
      PLB_RNW => plb_bus_PLB_RNW,
      PLB_SAValid => plb_bus_PLB_SAValid,
      PLB_abort => plb_bus_PLB_abort,
      PLB_busLock => plb_bus_PLB_busLock,
      PLB_TAttribute => plb_bus_PLB_TAttribute,
      PLB_lockErr => plb_bus_PLB_lockErr,
      PLB_masterID => plb_bus_PLB_masterID(0 to 0),
      PLB_MSize => plb_bus_PLB_MSize,
      PLB_rdPendPri => plb_bus_PLB_rdpendPri,
      PLB_wrPendPri => plb_bus_PLB_wrpendPri,
      PLB_rdPendReq => plb_bus_PLB_rdpendReq,
      PLB_wrPendReq => plb_bus_PLB_wrpendReq,
      PLB_rdBurst => plb_bus_PLB_rdBurst,
      PLB_rdPrim => plb_bus_PLB_rdPrim(0 to 0),
      PLB_reqPri => plb_bus_PLB_reqPri,
      PLB_size => plb_bus_PLB_size,
      PLB_type => plb_bus_PLB_type,
      PLB_wrBurst => plb_bus_PLB_wrBurst,
      PLB_wrDBus => plb_bus_PLB_wrDBus,
      PLB_wrPrim => plb_bus_PLB_wrPrim(0 to 0),
      PLB_SaddrAck => plb_bus_PLB_SaddrAck,
      PLB_SMRdErr => plb_bus_PLB_SMRdErr,
      PLB_SMWrErr => plb_bus_PLB_SMWrErr,
      PLB_SMBusy => plb_bus_PLB_SMBusy,
      PLB_SrdBTerm => plb_bus_PLB_SrdBTerm,
      PLB_SrdComp => plb_bus_PLB_SrdComp,
      PLB_SrdDAck => plb_bus_PLB_SrdDAck,
      PLB_SrdDBus => plb_bus_PLB_SrdDBus,
      PLB_SrdWdAddr => plb_bus_PLB_SrdWdAddr,
      PLB_Srearbitrate => plb_bus_PLB_Srearbitrate,
      PLB_Sssize => plb_bus_PLB_Sssize,
      PLB_Swait => plb_bus_PLB_Swait,
      PLB_SwrBTerm => plb_bus_PLB_SwrBTerm,
      PLB_SwrComp => plb_bus_PLB_SwrComp,
      PLB_SwrDAck => plb_bus_PLB_SwrDAck,
      PLB2OPB_rearb => net_gnd1(0 to 0),
      Bus_Error_Det => open
    );

  my_core : my_core_wrapper
    port map (
      MPLB_Clk => sys_clk,
      MPLB_Rst => plb_bus_MPLB_Rst(1),
      M_request => plb_bus_M_request(1),
      M_priority => plb_bus_M_priority(2 to 3),
      M_busLock => plb_bus_M_busLock(1),
      M_RNW => plb_bus_M_RNW(1),
      M_BE => plb_bus_M_BE(16 to 31),
      M_MSize => plb_bus_M_MSize(2 to 3),
      M_size => plb_bus_M_size(4 to 7),
      M_type => plb_bus_M_type(3 to 5),
      M_TAttribute => plb_bus_M_TAttribute(16 to 31),
      M_lockErr => plb_bus_M_lockErr(1),
      M_abort => plb_bus_M_abort(1),
      M_UABus => plb_bus_M_UABus(32 to 63),
      M_ABus => plb_bus_M_ABus(32 to 63),
      M_wrDBus => plb_bus_M_wrDBus(128 to 255),
      M_wrBurst => plb_bus_M_wrBurst(1),
      M_rdBurst => plb_bus_M_rdBurst(1),
      PLB_MAddrAck => plb_bus_PLB_MAddrAck(1),
      PLB_MSSize => plb_bus_PLB_MSSize(2 to 3),
      PLB_MRearbitrate => plb_bus_PLB_MRearbitrate(1),
      PLB_MTimeout => plb_bus_PLB_MTimeout(1),
      PLB_MBusy => plb_bus_PLB_MBusy(1),
      PLB_MRdErr => plb_bus_PLB_MRdErr(1),
      PLB_MWrErr => plb_bus_PLB_MWrErr(1),
      PLB_MIRQ => plb_bus_PLB_MIRQ(1),
      PLB_MRdDBus => plb_bus_PLB_MRdDBus(128 to 255),
      PLB_MRdWdAddr => plb_bus_PLB_MRdWdAddr(4 to 7),
      PLB_MRdDAck => plb_bus_PLB_MRdDAck(1),
      PLB_MRdBTerm => plb_bus_PLB_MRdBTerm(1),
      PLB_MWrDAck => plb_bus_PLB_MWrDAck(1),
      PLB_MWrBTerm => plb_bus_PLB_MWrBTerm(1),
      SYNCH_IN => synch,
      SYNCH_OUT => synch3
    );

end architecture STRUCTURE;

