-------------------------------------------------------------------------------
-- bfm_processor_wrapper.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library plbv46_master_bfm_v1_00_a;
use plbv46_master_bfm_v1_00_a.all;

entity bfm_processor_wrapper is
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
end bfm_processor_wrapper;

architecture STRUCTURE of bfm_processor_wrapper is

  component plbv46_master_bfm is
    generic (
      PLB_MASTER_SIZE : std_logic_vector(0 to 1);
      PLB_MASTER_NUM : std_logic_vector(0 to 3);
      PLB_MASTER_ADDR_LO_0 : std_logic_vector(0 to 31);
      PLB_MASTER_ADDR_HI_0 : std_logic_vector(0 to 31);
      PLB_MASTER_ADDR_LO_1 : std_logic_vector(0 to 31);
      PLB_MASTER_ADDR_HI_1 : std_logic_vector(0 to 31);
      C_MPLB_DWIDTH : integer
    );
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
      PLB_MRdDBus : in std_logic_vector(0 to (C_MPLB_DWIDTH-1));
      PLB_MRdWdAddr : in std_logic_vector(0 to 3);
      PLB_MRdDAck : in std_logic;
      PLB_MRdBTerm : in std_logic;
      PLB_MWrBTerm : in std_logic;
      M_request : out std_logic;
      M_priority : out std_logic_vector(0 to 1);
      M_buslock : out std_logic;
      M_RNW : out std_logic;
      M_BE : out std_logic_vector(0 to ((C_MPLB_DWIDTH/8)-1));
      M_msize : out std_logic_vector(0 to 1);
      M_size : out std_logic_vector(0 to 3);
      M_type : out std_logic_vector(0 to 2);
      M_TAttribute : out std_logic_vector(0 to 15);
      M_lockErr : out std_logic;
      M_abort : out std_logic;
      M_UABus : out std_logic_vector(0 to 31);
      M_ABus : out std_logic_vector(0 to 31);
      M_wrDBus : out std_logic_vector(0 to (C_MPLB_DWIDTH-1));
      M_wrBurst : out std_logic;
      M_rdBurst : out std_logic
    );
  end component;

begin

  bfm_processor : plbv46_master_bfm
    generic map (
      PLB_MASTER_SIZE => B"10",
      PLB_MASTER_NUM => B"0000",
      PLB_MASTER_ADDR_LO_0 => X"00000000",
      PLB_MASTER_ADDR_HI_0 => X"00000000",
      PLB_MASTER_ADDR_LO_1 => X"00000000",
      PLB_MASTER_ADDR_HI_1 => X"00000000",
      C_MPLB_DWIDTH => 128
    )
    port map (
      PLB_CLK => PLB_CLK,
      PLB_RESET => PLB_RESET,
      SYNCH_OUT => SYNCH_OUT,
      SYNCH_IN => SYNCH_IN,
      PLB_MAddrAck => PLB_MAddrAck,
      PLB_MSsize => PLB_MSsize,
      PLB_MRearbitrate => PLB_MRearbitrate,
      PLB_MTimeout => PLB_MTimeout,
      PLB_MBusy => PLB_MBusy,
      PLB_MRdErr => PLB_MRdErr,
      PLB_MWrErr => PLB_MWrErr,
      PLB_MIRQ => PLB_MIRQ,
      PLB_MWrDAck => PLB_MWrDAck,
      PLB_MRdDBus => PLB_MRdDBus,
      PLB_MRdWdAddr => PLB_MRdWdAddr,
      PLB_MRdDAck => PLB_MRdDAck,
      PLB_MRdBTerm => PLB_MRdBTerm,
      PLB_MWrBTerm => PLB_MWrBTerm,
      M_request => M_request,
      M_priority => M_priority,
      M_buslock => M_buslock,
      M_RNW => M_RNW,
      M_BE => M_BE,
      M_msize => M_msize,
      M_size => M_size,
      M_type => M_type,
      M_TAttribute => M_TAttribute,
      M_lockErr => M_lockErr,
      M_abort => M_abort,
      M_UABus => M_UABus,
      M_ABus => M_ABus,
      M_wrDBus => M_wrDBus,
      M_wrBurst => M_wrBurst,
      M_rdBurst => M_rdBurst
    );

end architecture STRUCTURE;

