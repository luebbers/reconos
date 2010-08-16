--------------------------------------------------------------------------------
-- Company: Lehrstuhl Integrierte Systeme - TUM
-- Engineer: Johannes Zeppenfeld
-- 
-- Project Name:   LIS-IPIF
-- Module Name:    lisipif_master
-- Architectures:  lisipif_master_rtl
-- Description:
--    The master attachment of the LIS-IPIF may be used by an IP to provide
--    a simplifed interface to the Processor Local Bus (PLB).
--    See the LIS-IPIF specification for details.
--
-- Dependencies:
--
-- Revision:
--     7.3.2006 - File Created
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library lisipif_master_v1_00_c;
use lisipif_master_v1_00_c.all;

--------------------------------------------------------------------------------
-- LIS-IPIF Master Entity Declaration
--------------------------------------------------------------------------------
entity lisipif_master is
   generic (
      C_NUM_WIDTH       : integer := 5;
      C_ARBITRATION     : integer := 0;
      C_EN_SRL16        : boolean := true;
      C_EN_RECALC_ADDR  : boolean := false;  -- Not Implemented
      C_EN_PIPELINING   : boolean := true;   -- Not Implemented
      C_EN_FAST_ABORT   : boolean := false   -- Not Implemented
   );
   port (
      PLB_Clk           : in std_logic;
      PLB_Rst           : in std_logic;

      -- Read Transfer Signals
      M_rdReq           : in std_logic;
      M_rdAccept        : out std_logic;
      M_rdAddr          : in std_logic_vector(31 downto 0);
      M_rdNum           : in std_logic_vector(C_NUM_WIDTH-1 downto 0);
      M_rdBE            : in std_logic_vector(7 downto 0);
      M_rdData          : out std_logic_vector(63 downto 0);
      M_rdAck           : out std_logic;
      M_rdComp          : out std_logic;

      M_rdPriority      : in std_logic_vector(1 downto 0);
      M_rdType          : in std_logic_vector(2 downto 0);
      M_rdCompress      : in std_logic;
      M_rdGuarded       : in std_logic;
      M_rdLockErr       : in std_logic;
      M_rdRearb         : out std_logic;
      M_rdAbort         : in std_logic;
      M_rdError         : out std_logic;

      -- Write Transfer Signals
      M_wrReq           : in std_logic;
      M_wrAccept        : out std_logic;
      M_wrAddr          : in std_logic_vector(31 downto 0);
      M_wrNum           : in std_logic_vector(C_NUM_WIDTH-1 downto 0);
      M_wrBE            : in std_logic_vector(7 downto 0);
      M_wrData          : in std_logic_vector(63 downto 0);
      M_wrRdy           : out std_logic;
      M_wrAck           : out std_logic;
      M_wrComp          : out std_logic;

      M_wrPriority      : in std_logic_vector(1 downto 0);
      M_wrType          : in std_logic_vector(2 downto 0);
      M_wrCompress      : in std_logic;
      M_wrGuarded       : in std_logic;
      M_wrOrdered       : in std_logic;
      M_wrLockErr       : in std_logic;
      M_wrRearb         : out std_logic;
      M_wrAbort         : in std_logic;
      M_wrError         : out std_logic;

      -- Shared Transfer Signals
      M_Error           : out std_logic;
      M_Lock            : in std_logic;
      
      -- PLB Signals
      PLB_MAddrAck      : in  std_logic;
      PLB_MRearbitrate  : in  std_logic;
      PLB_MSSize        : in  std_logic_vector(0 to 1);
      PLB_MBusy         : in  std_logic;
      PLB_MErr          : in  std_logic;
      PLB_pendReq       : in  std_logic;
      PLB_pendPri       : in  std_logic_vector(0 to 1);
      PLB_reqPri        : in  std_logic_vector(0 to 1);

      M_request         : out std_logic;                 -- A
      M_priority        : out std_logic_vector(0 to 1);  -- I
      M_busLock         : out std_logic;                 -- I
      M_RNW             : out std_logic;                 -- A
      M_BE              : out std_logic_vector(0 to 7);  -- A
      M_size            : out std_logic_vector(0 to 3);  -- A
      M_type            : out std_logic_vector(0 to 2);  -- I
      M_MSize           : out std_logic_vector(0 to 1);  -- C
      M_compress        : out std_logic;                 -- I
      M_guarded         : out std_logic;                 -- I
      M_ordered         : out std_logic;                 -- I
      M_lockErr         : out std_logic;                 -- I
      M_abort           : out std_logic;                 -- A
      M_ABus            : out std_logic_vector(0 to 31); -- A

      PLB_MWrDAck       : in  std_logic;
      PLB_MWrBTerm      : in  std_logic;
      M_wrBurst         : out std_logic;                 -- W
      M_wrDBus          : out std_logic_vector(0 to 63); -- W

      PLB_MRdDAck       : in  std_logic;
      PLB_MRdBTerm      : in  std_logic;
      PLB_MRdWdAddr     : in  std_logic_vector(0 to 3);
      M_rdBurst         : out std_logic;                 -- R
      PLB_MRdDBus       : in  std_logic_vector(0 to 63)
   );
end lisipif_master;

--------------------------------------------------------------------------------
-- LIS-IPIF Master RT Level Architecture
--------------------------------------------------------------------------------
architecture lisipif_master_rtl of lisipif_master is
   -- Control Signals between Arbiter and Read/Write Controller
   signal rd_rdy   : std_logic; -- To arb: Ready for new transfer
   signal rd_init  : std_logic; -- From arb: Latch new transfer
   signal rd_ack   : std_logic; -- From arb: Transfer ack'd by slave
   signal rd_rearb : std_logic; -- From arb: Rearbitrate transfer
   signal rd_retry : std_logic; -- To arb: Repeat the transfer
   signal rd_abort : std_logic; -- To arb: Abort the transfer

   signal wr_rdy   : std_logic; -- To arb: Ready for new transfer
   signal wr_init  : std_logic; -- From arb: Latch new transfer
   signal wr_ack   : std_logic; -- From arb: Transfer ack'd by slave
   signal wr_rearb : std_logic; -- From arb: Rearbitrate transfer
   signal wr_retry : std_logic; -- To arb: Repeat the transfer
   signal wr_abort : std_logic; -- To arb: Abort the transfer
begin
   M_MSize <= "01";

   -- Arbiter
   arbiter_0: entity lisipif_master_v1_00_c.lipif_mst_arbiter
		generic map (
         C_NUM_WIDTH       => C_NUM_WIDTH,
         C_ARBITRATION     => C_ARBITRATION,
         C_EN_SRL16        => C_EN_SRL16
		)
      port map (
         clk               => PLB_Clk,
         reset             => PLB_Rst,

         -- Control Signals to Read and Write Controller
         rd_rdy_i          => rd_rdy,
         rd_init_o         => rd_init,
         rd_ack_o          => rd_ack,
         rd_rearb_o        => rd_rearb,
         rd_retry_i        => rd_retry,
         rd_abort_i        => rd_abort,

         wr_rdy_i          => wr_rdy,
         wr_init_o         => wr_init,
         wr_ack_o          => wr_ack,
         wr_rearb_o        => wr_rearb,
         wr_retry_i        => wr_retry,
         wr_abort_i        => wr_abort,

         -- LIS-IPIC Read Qualifiers
         M_rdReq_i         => M_rdReq,
         M_rdAccept_o      => M_rdAccept,
         M_rdAddr_i        => M_rdAddr,
         M_rdNum_i         => M_rdNum,
         M_rdBE_i          => M_rdBE,

         M_rdPriority_i    => M_rdPriority,
         M_rdType_i        => M_rdType,
         M_rdCompress_i    => M_rdCompress,
         M_rdGuarded_i     => M_rdGuarded,
         M_rdLockErr_i     => M_rdLockErr,

         -- LIS-IPIC Write Qualifiers
         M_wrReq_i         => M_wrReq,
         M_wrAccept_o      => M_wrAccept,
         M_wrAddr_i        => M_wrAddr,
         M_wrNum_i         => M_wrNum,
         M_wrBE_i          => M_wrBE,

         M_wrPriority_i    => M_wrPriority,
         M_wrType_i        => M_wrType,
         M_wrCompress_i    => M_wrCompress,
         M_wrGuarded_i     => M_wrGuarded,
         M_wrOrdered_i     => M_wrOrdered,
         M_wrLockErr_i     => M_wrLockErr,

         -- LIS-IPIC Shared Qualifiers
         M_Error_o         => M_Error,
         M_Lock_i          => M_Lock,

         -- PLB Signals
         PLB_MAddrAck      => PLB_MAddrAck,
         PLB_MRearbitrate  => PLB_MRearbitrate,
         PLB_MErr          => PLB_MErr,

         M_request         => M_request,
         M_priority        => M_priority,
         M_busLock         => M_busLock,
         M_RNW             => M_RNW,
         M_BE              => M_BE,
         M_size            => M_size,
         M_type            => M_type,
         M_compress        => M_compress,
         M_guarded         => M_guarded,
         M_ordered         => M_ordered,
         M_lockErr         => M_lockErr,
         M_abort           => M_abort,
         M_ABus            => M_ABus
      );

   -- Read Controller
   read_ctrl_0: entity lisipif_master_v1_00_c.lipif_mst_read
		generic map (
         C_NUM_WIDTH       => C_NUM_WIDTH,
         C_EN_SRL16        => C_EN_SRL16,
         C_EN_FAST_ABORT   => C_EN_FAST_ABORT
		)
      port map (
         clk            => PLB_Clk,
         reset          => PLB_Rst,

         -- Control Signals to/from Arbiter
         xfer_rdy_o     => rd_rdy,
         xfer_init_i    => rd_init,
         xfer_ack_i     => rd_ack,
         xfer_rearb_i   => rd_rearb,
         xfer_retry_o   => rd_retry,
         xfer_abort_o   => rd_abort,

         -- LIS-IPIC Transfer Signals
         M_rdNum_i      => M_rdNum,
         M_rdRearb_o    => M_rdRearb,
         M_rdAbort_i    => M_rdAbort,
         M_rdError_o    => M_rdError,

         M_rdData_o     => M_rdData,
         M_rdAck_o      => M_rdAck,
         M_rdComp_o     => M_rdComp,

         -- PLB Signals
         PLB_MRdDAck    => PLB_MRdDAck,
         PLB_MRdBTerm   => PLB_MRdBTerm,
         PLB_MRdWdAddr  => PLB_MRdWdAddr,
         M_rdBurst      => M_rdBurst,
         PLB_MRdDBus    => PLB_MRdDBus
      );

   -- Write Controller
   write_ctrl_0: entity lisipif_master_v1_00_c.lipif_mst_write
		generic map (
         C_NUM_WIDTH       => C_NUM_WIDTH,
         C_EN_SRL16        => C_EN_SRL16,
         C_EN_FAST_ABORT   => C_EN_FAST_ABORT
		)
      port map (
         clk            => PLB_Clk,
         reset          => PLB_Rst,

         -- Control Signals to/from Arbiter
         xfer_rdy_o     => wr_rdy,
         xfer_init_i    => wr_init,
         xfer_ack_i     => wr_ack,
         xfer_rearb_i   => wr_rearb,
         xfer_retry_o   => wr_retry,
         xfer_abort_o   => wr_abort,

         -- LIS-IPIC Transfer Signals
         M_wrNum_i      => M_wrNum,
         M_wrRearb_o    => M_wrRearb,
         M_wrAbort_i    => M_wrAbort,
         M_wrError_o    => M_wrError,

         M_wrData_i     => M_wrData,
         M_wrRdy_o      => M_wrRdy,
         M_wrAck_o      => M_wrAck,
         M_wrComp_o     => M_wrComp,

         -- PLB Signals
         PLB_MWrDAck    => PLB_MWrDAck,
         PLB_MWrBTerm   => PLB_MWrBTerm,
         M_wrBurst      => M_WrBurst,
         M_wrDBus       => M_wrDBus
      );

end lisipif_master_rtl;
