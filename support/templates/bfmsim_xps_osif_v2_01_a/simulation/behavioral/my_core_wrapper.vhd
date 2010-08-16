-------------------------------------------------------------------------------
-- my_core_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library xps_osif_tb_v2_01_a;
use xps_osif_tb_v2_01_a.all;

entity my_core_wrapper is
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
end my_core_wrapper;

architecture STRUCTURE of my_core_wrapper is

  component xps_osif_tb is
    generic (
      C_FAMILY : string;
      C_MPLB_AWIDTH : integer;
      C_MPLB_DWIDTH : integer;
      C_MPLB_NATIVE_DWIDTH : integer;
      C_MPLB_P2P : integer;
      C_MPLB_SMALLEST_SLAVE : integer;
      C_MPLB_CLK_PERIOD_PS : integer
    );
    port (
      MPLB_Clk : in std_logic;
      MPLB_Rst : in std_logic;
      M_request : out std_logic;
      M_priority : out std_logic_vector(0 to (1));
      M_busLock : out std_logic;
      M_RNW : out std_logic;
      M_BE : out std_logic_vector(0 to (C_MPLB_DWIDTH/8-1));
      M_MSize : out std_logic_vector(0 to (1));
      M_size : out std_logic_vector(0 to (3));
      M_type : out std_logic_vector(0 to (2));
      M_TAttribute : out std_logic_vector(0 to (15));
      M_lockErr : out std_logic;
      M_abort : out std_logic;
      M_UABus : out std_logic_vector(0 to (31));
      M_ABus : out std_logic_vector(0 to (31));
      M_wrDBus : out std_logic_vector(0 to (C_MPLB_DWIDTH-1));
      M_wrBurst : out std_logic;
      M_rdBurst : out std_logic;
      PLB_MAddrAck : in std_logic;
      PLB_MSSize : in std_logic_vector(0 to (1));
      PLB_MRearbitrate : in std_logic;
      PLB_MTimeout : in std_logic;
      PLB_MBusy : in std_logic;
      PLB_MRdErr : in std_logic;
      PLB_MWrErr : in std_logic;
      PLB_MIRQ : in std_logic;
      PLB_MRdDBus : in std_logic_vector(0 to ((C_MPLB_DWIDTH-1)));
      PLB_MRdWdAddr : in std_logic_vector(0 to (3));
      PLB_MRdDAck : in std_logic;
      PLB_MRdBTerm : in std_logic;
      PLB_MWrDAck : in std_logic;
      PLB_MWrBTerm : in std_logic;
      SYNCH_IN : in std_logic_vector(0 to 31);
      SYNCH_OUT : out std_logic_vector(0 to 31)
    );
  end component;

begin

  my_core : xps_osif_tb
    generic map (
      C_FAMILY => "virtex5",
      C_MPLB_AWIDTH => 32,
      C_MPLB_DWIDTH => 128,
      C_MPLB_NATIVE_DWIDTH => 64,
      C_MPLB_P2P => 0,
      C_MPLB_SMALLEST_SLAVE => 128,
      C_MPLB_CLK_PERIOD_PS => 10000
    )
    port map (
      MPLB_Clk => MPLB_Clk,
      MPLB_Rst => MPLB_Rst,
      M_request => M_request,
      M_priority => M_priority,
      M_busLock => M_busLock,
      M_RNW => M_RNW,
      M_BE => M_BE,
      M_MSize => M_MSize,
      M_size => M_size,
      M_type => M_type,
      M_TAttribute => M_TAttribute,
      M_lockErr => M_lockErr,
      M_abort => M_abort,
      M_UABus => M_UABus,
      M_ABus => M_ABus,
      M_wrDBus => M_wrDBus,
      M_wrBurst => M_wrBurst,
      M_rdBurst => M_rdBurst,
      PLB_MAddrAck => PLB_MAddrAck,
      PLB_MSSize => PLB_MSSize,
      PLB_MRearbitrate => PLB_MRearbitrate,
      PLB_MTimeout => PLB_MTimeout,
      PLB_MBusy => PLB_MBusy,
      PLB_MRdErr => PLB_MRdErr,
      PLB_MWrErr => PLB_MWrErr,
      PLB_MIRQ => PLB_MIRQ,
      PLB_MRdDBus => PLB_MRdDBus,
      PLB_MRdWdAddr => PLB_MRdWdAddr,
      PLB_MRdDAck => PLB_MRdDAck,
      PLB_MRdBTerm => PLB_MRdBTerm,
      PLB_MWrDAck => PLB_MWrDAck,
      PLB_MWrBTerm => PLB_MWrBTerm,
      SYNCH_IN => SYNCH_IN,
      SYNCH_OUT => SYNCH_OUT
    );

end architecture STRUCTURE;

