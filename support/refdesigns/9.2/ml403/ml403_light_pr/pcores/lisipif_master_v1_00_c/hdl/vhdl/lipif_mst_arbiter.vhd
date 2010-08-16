--------------------------------------------------------------------------------
-- Company: Lehrstuhl Integrierte Systeme - TUM
-- Engineer: Johannes Zeppenfeld
-- 
-- Project Name:   LIS-IPIF
-- Module Name:    lipif_mst_arbiter
-- Architectures:  lipif_mst_arbiter_rtl
-- Description:
--
-- Dependencies:
--
-- Revision:
--    10.4.2006 - File Created
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library lisipif_master_v1_00_c;
use lisipif_master_v1_00_c.all;

library UNISIM;
use UNISIM.VComponents.all;

entity lipif_mst_arbiter is
   generic(
      C_NUM_WIDTH       : integer := 5;
      C_ARBITRATION     : integer := 0;
      C_EN_SRL16        : boolean := true
   );
   port(
      clk               : in std_logic;
      reset             : in std_logic;

      -- Control Signals to/from Read and Write Controllers
      rd_rdy_i          : in std_logic;
      rd_init_o         : out std_logic;
      rd_ack_o          : out std_logic;
      rd_rearb_o        : out std_logic;
      rd_retry_i        : in std_logic;
      rd_abort_i        : in std_logic;

      wr_rdy_i          : in std_logic;
      wr_init_o         : out std_logic;
      wr_ack_o          : out std_logic;
      wr_rearb_o        : out std_logic;
      wr_retry_i        : in std_logic;
      wr_abort_i        : in std_logic;

      -- LIS-IPIC Read Qualifiers
      M_rdReq_i         : in std_logic;
      M_rdAccept_o      : out std_logic;
      M_rdAddr_i        : in std_logic_vector(31 downto 0);
      M_rdNum_i         : in std_logic_vector(C_NUM_WIDTH-1 downto 0);
      M_rdBE_i          : in std_logic_vector(7 downto 0);

      M_rdPriority_i    : in std_logic_vector(1 downto 0);
      M_rdType_i        : in std_logic_vector(2 downto 0);
      M_rdCompress_i    : in std_logic;
      M_rdGuarded_i     : in std_logic;
      M_rdLockErr_i     : in std_logic;

      -- LIS-IPIC Write Qualifiers
      M_wrReq_i         : in std_logic;
      M_wrAccept_o      : out std_logic;
      M_wrAddr_i        : in std_logic_vector(31 downto 0);
      M_wrNum_i         : in std_logic_vector(C_NUM_WIDTH-1 downto 0);
      M_wrBE_i          : in std_logic_vector(7 downto 0);

      M_wrPriority_i    : in std_logic_vector(1 downto 0);
      M_wrType_i        : in std_logic_vector(2 downto 0);
      M_wrCompress_i    : in std_logic;
      M_wrGuarded_i     : in std_logic;
      M_wrOrdered_i     : in std_logic;
      M_wrLockErr_i     : in std_logic;

      -- LIS-IPIC Shared Qualifiers
      M_Error_o         : out std_logic;
      M_Lock_i          : in std_logic;

      -- PLB Signals
      PLB_MAddrAck      : in  std_logic;
      PLB_MRearbitrate  : in  std_logic;
      PLB_MErr          : in  std_logic;

      M_request         : out std_logic;
      M_priority        : out std_logic_vector(0 to 1);
      M_busLock         : out std_logic;
      M_RNW             : out std_logic;
      M_BE              : out std_logic_vector(0 to 7);
      M_size            : out std_logic_vector(0 to 3);
      M_type            : out std_logic_vector(0 to 2);
      M_compress        : out std_logic;
      M_guarded         : out std_logic;
      M_ordered         : out std_logic;
      M_lockErr         : out std_logic;
      M_abort           : out std_logic;
      M_ABus            : out std_logic_vector(0 to 31)
   );
end lipif_mst_arbiter;

architecture lipif_mst_arbiter_rtl of lipif_mst_arbiter is
   constant C_QUAL_WIDTH : integer := 54;
   signal arb_qual      : std_logic_vector(C_QUAL_WIDTH-1 downto 0);
   signal arb_qual_req  : std_logic;
   signal arb_qual_rdy  : std_logic;
   signal plb_qual      : std_logic_vector(C_QUAL_WIDTH-1 downto 0);
   signal plb_qual_req  : std_logic;
   signal plb_qual_rdy  : std_logic;

   signal arb_nxt_rnw   : std_logic;   -- Transfer direction priority for next request
   signal xfer_rnw      : std_logic;   -- Last transfer direction
   signal arb_ini_rd    : std_logic;   -- Latch read qualifiers and launch request
   signal arb_ini_wr    : std_logic;   -- Latch write qualifiers and launch request
   signal plb_rearb     : std_logic;   -- Current request needs rearbitration
   signal plb_rnw       : std_logic;   -- Current request direction
begin
   -- TODO: Error, Bus Locking
   M_Error_o   <= '0';       -- PLB_MErr
   -- TIMING(18%): TODO
   M_busLock   <= M_Lock_i;

   -- Generate control signals to control unit.
   -- Ignore AddrAck when aborting
   rd_ack_o    <= PLB_MAddrAck and plb_rnw and not rd_abort_i;
   rd_rearb_o  <= plb_rearb and plb_rnw;

   wr_ack_o    <= PLB_MAddrAck and not plb_rnw and not wr_abort_i;
   wr_rearb_o  <= plb_rearb and not plb_rnw;

   -- Mask PLB request signal with the transfer's rearbitration status.
   -- TIMING(8%): Both plb_qual_req and plb_rearb are register outputs, which should
   --    give enough time for one LUT to combine them.
   M_request    <= plb_qual_req and not plb_rearb;
   -- Discard request when the control unit asserts an abort.
   -- The unit is responsible for ensuring that it has the arbiter's focus.
   plb_qual_rdy <= PLB_MAddrAck or rd_abort_i or wr_abort_i;
   -- Assert abort signal to PLB when aborting a transfer prior to address ack
   -- TIMING(43%): plb_rearb is direct register output, xx_abort generated by rd/wr
   --    controller with 3-input AND gate ("mst_term and prim_valid and not prim_ack")
   M_abort     <= (rd_abort_i or wr_abort_i) and not plb_rearb;

   -- Calculate next read/write priority based on arbitration scheme
   arb_nxt_rnw  <= '1' when (C_ARBITRATION=1 or (C_ARBITRATION=0 and xfer_rnw='0')) else '0';

   -- Arbitrate between read and write units
   arb_ini_rd <= M_rdReq_i and rd_rdy_i and arb_qual_rdy and (arb_nxt_rnw or not M_wrReq_i or not wr_rdy_i);
   arb_ini_wr <= M_wrReq_i and wr_rdy_i and arb_qual_rdy and (not arb_nxt_rnw or not M_rdReq_i or not rd_rdy_i);
   arb_qual_req <= arb_ini_rd or arb_ini_wr;

   -- Pass accept signals to output
   M_rdAccept_o <= arb_ini_rd;
   rd_init_o    <= arb_ini_rd;
   M_wrAccept_o <= arb_ini_wr;
   wr_init_o    <= arb_ini_wr;

   -- Keep track of current transfer direction
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            xfer_rnw <= '0';
         else
            if(arb_ini_rd='1') then
               xfer_rnw <= '1';
            elsif(arb_ini_wr='1') then
               xfer_rnw <= '0';
            end if;
         end if;
      end if;
   end process;

   -- Keep track of the rearbitration state of the current request
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            plb_rearb <= '0';
         else
            -- plb_rearb is set when slave requests rearbitration
            if(PLB_MRearbitrate='1' and PLB_MAddrAck='0') then
               plb_rearb <= '1';
            -- plb_rearb is negated when the associated control unit
            -- aborts the transfer or signals a retry
            elsif((plb_rnw='1' and (rd_retry_i='1' or rd_abort_i='1')) or
                  (plb_rnw='0' and (wr_retry_i='1' or wr_abort_i='1'))) then
               plb_rearb <= '0';
            end if;
         end if;
      end if;
   end process;

   -- Generate request qualifiers and merge onto single bus for pipebuf
   process(arb_ini_rd, M_rdAddr_i, M_rdNum_i, M_rdBE_i, M_rdPriority_i, M_rdType_i,
              M_rdCompress_i, M_rdGuarded_i, M_rdLockErr_i,
           arb_ini_wr, M_wrAddr_i, M_wrNum_i, M_wrBE_i, M_wrPriority_i, M_wrType_i,
              M_wrCompress_i, M_wrGuarded_i, M_wrOrdered_i, M_wrLockErr_i)
      variable be_cnt   : std_logic_vector(3 downto 0);
   begin
      if(arb_ini_rd='1') then
         -- TODO: C_EN_RECALC_ADDR
         arb_qual(31 downto 0)     <= M_rdAddr_i;  -- M_ABus(0 to 31)
         -- TODO: Can BE be optimized? Maybe by calculating after muxing?
         -- size and BE dependant on requested transfer length
         if(CONV_INTEGER(UNSIGNED(M_rdNum_i))<=1) then
            arb_qual(39 downto 32) <= M_rdBE_i;    -- M_BE(0 to 7)
            arb_qual(43 downto 40) <= "0000";      -- M_size(0 to 3)
         else
            -- Check for transfer longer than 16 dwords
            if(CONV_INTEGER(UNSIGNED(M_rdNum_i))>16) then
               arb_qual(39 downto 32) <= (others=>'0'); -- M_BE(0 to 7)
            else
               be_cnt := CONV_STD_LOGIC_VECTOR(CONV_INTEGER(UNSIGNED(M_rdNum_i))-1, 4);
               arb_qual(39 downto 36) <= be_cnt;   -- M_BE(0 to 3)
               arb_qual(35 downto 32) <= "0000";   -- M_BE(4 to 7)
            end if;
            arb_qual(43 downto 40) <= "1011";      -- M_size(0 to 3)
         end if;

         arb_qual(45 downto 44) <= M_rdPriority_i; -- M_priority(0 to 1)
         arb_qual(46)           <= '1';            -- M_RNW
         arb_qual(49 downto 47) <= M_rdType_i;     -- M_type(0 to 2);
         arb_qual(50)           <= M_rdCompress_i; -- M_compress
         arb_qual(51)           <= M_rdGuarded_i;  -- M_guarded
         arb_qual(52)           <= '0';            -- M_ordered
         arb_qual(53)           <= M_rdLockErr_i;  -- M_lockErr
      else
         -- TODO: C_EN_RECALC_ADDR
         arb_qual(31 downto 0)     <= M_wrAddr_i;  -- M_ABus(0 to 31)
         -- TODO: Can BE be optimized? Maybe by calculating after muxing?
         -- size and BE dependant on requested transfer length
         if(CONV_INTEGER(UNSIGNED(M_wrNum_i))<=1) then
            arb_qual(39 downto 32) <= M_wrBE_i;    -- M_BE(0 to 7)
            arb_qual(43 downto 40) <= "0000";      -- M_size(0 to 3)
         else
            -- Check for transfer longer than 16 dwords
            if(CONV_INTEGER(UNSIGNED(M_wrNum_i))>16) then
               arb_qual(39 downto 32) <= (others=>'0'); -- M_BE(0 to 7)
            else
               be_cnt := CONV_STD_LOGIC_VECTOR(CONV_INTEGER(UNSIGNED(M_wrNum_i))-1, 4);
               arb_qual(39 downto 36) <= be_cnt;   -- M_BE(0 to 3)
               arb_qual(35 downto 32) <= "0000";   -- M_BE(4 to 7)
            end if;
            arb_qual(43 downto 40) <= "1011";      -- M_size(0 to 3)
         end if;

         arb_qual(45 downto 44) <= M_wrPriority_i; -- M_priority(0 to 1)
         arb_qual(46)           <= '0';            -- M_RNW
         arb_qual(49 downto 47) <= M_wrType_i;     -- M_type(0 to 2);
         arb_qual(50)           <= M_wrCompress_i; -- M_compress
         arb_qual(51)           <= M_wrGuarded_i;  -- M_guarded
         arb_qual(52)           <= M_wrOrdered_i;  -- M_ordered
         arb_qual(53)           <= M_wrLockErr_i;  -- M_lockErr
      end if;
   end process;

   -- Instantiate pipeline buffer
   arb_pipebuf_0: entity lisipif_master_v1_00_c.lipif_mst_pipebuf
      generic map (
         C_DATA_WIDTH => C_QUAL_WIDTH,
         -- Since SRL outputs are slow (>3ns after clk), must use registers
         -- to meet PLB timings.
         -- The good news: Even takes up fewer slices when using registers!
         C_EN_SRL16   => false
      )
      port map (
         clk         => clk,
         reset       => reset,

         -- Previous (input) stage I/O
         prevReq_i   => arb_qual_req,
         prevRdy_o   => arb_qual_rdy,
         prevData_i  => arb_qual,

         -- Next (output) stage I/O
         nextReq_o   => plb_qual_req,
         nextRdy_i   => plb_qual_rdy,
         nextData_o  => plb_qual
      );

   -- Forward request qualifiers to PLB
   -- TIMING(18%): Direct register outputs
   M_ABus      <= plb_qual(31 downto 0);
   M_BE        <= plb_qual(39 downto 32);
   M_size      <= plb_qual(43 downto 40);
   M_type      <= plb_qual(49 downto 47);
   M_compress  <= plb_qual(50);
   M_guarded   <= plb_qual(51);
   M_ordered   <= plb_qual(52);
   M_lockErr   <= plb_qual(53);
   -- TIMING(8%): Direct register outputs
   M_priority  <= plb_qual(45 downto 44);
   M_RNW       <= plb_qual(46);

   -- Transfer direction of current request for local use
   plb_rnw     <= plb_qual(46);

end lipif_mst_arbiter_rtl;
