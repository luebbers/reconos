--------------------------------------------------------------------------------
-- Company: Lehrstuhl Integrierte Systeme - TUM
-- Engineer: Johannes Zeppenfeld
-- 
-- Project Name:   LIS-IPIF
-- Module Name:    lipif_slv_read
-- Architectures:  lipif_slv_read_rtl
-- Description:
--
-- Dependencies:
--    lipif_mst_pipeliner
--
-- Notes:
--   When Sl_rdBTerm is asserted at the end of a primary transfer,
--     M_rdBurst must be set according to the secondary transfer in
--     the following cycle.
--   M_rdBurst may not be set until after AddrAck!!!
--
-- Revision:
--    11.4.2006 - File Created
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library lisipif_master_v1_00_c;
use lisipif_master_v1_00_c.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lipif_mst_read is
   generic (
      C_NUM_WIDTH       : integer := 5;
      C_EN_SRL16        : boolean := true;
      C_EN_FAST_ABORT   : boolean := false
   );
   port (
      clk            : in std_logic;
      reset          : in std_logic;

      -- Control Signals to/from Arbiter
      xfer_rdy_o     : out std_logic;
      xfer_init_i    : in std_logic;
      xfer_ack_i     : in std_logic;
      xfer_rearb_i   : in std_logic;
      xfer_retry_o   : out std_logic;
      xfer_abort_o   : out std_logic;

      -- LIS-IPIC Transfer Signals
      M_rdNum_i      : in std_logic_vector(C_NUM_WIDTH-1 downto 0);
      M_rdRearb_o    : out std_logic;
      M_rdAbort_i    : in std_logic;
      M_rdError_o    : out std_logic;

      M_rdData_o     : out std_logic_vector(63 downto 0);
      M_rdAck_o      : out std_logic;
      M_rdComp_o     : out std_logic;

      -- PLB Signals
      PLB_MRdDAck    : in  std_logic;
      PLB_MRdBTerm   : in  std_logic;
      PLB_MRdWdAddr  : in  std_logic_vector(0 to 3);
      M_rdBurst      : out std_logic;
      PLB_MRdDBus    : in  std_logic_vector(0 to 63)
   );
end lipif_mst_read;

architecture lipif_mst_read_rtl of lipif_mst_read is
   -- Pipebuf primary control signals
   signal prim_valid : std_logic;
   signal prim_last  : std_logic;
   signal prim_ack   : std_logic;
   signal prim_ack_p : std_logic;
   signal prim_comp  : std_logic;

   -- Transfer termination requests from IP/PLB
   signal mst_term   : std_logic;
   signal mst_term_r : std_logic; -- Track until transfer complete
   signal plb_term   : std_logic;

   -- Burst will continue through next cycle
   signal prim_burst_nxt : std_logic;
   signal pipe_burst_nxt : std_logic;
begin
   -- Generate PLB read burst signal (M_rdBurst)
   -- TIMING(18%) M_rdBurst is a register, so no problem
   -- TODO: When C_EN_FAST_ABORT, M_rdBurst must respond with M_rdAbort
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            M_rdBurst <= '0';
         else
            -- Burst must display pipelined value in response to PLB terminate
            if(PLB_MRdBTerm='1') then
               M_rdBurst <= pipe_burst_nxt;
            -- Burst must go low in response to IP abort
            elsif(M_rdAbort_i='1') then
               M_rdBurst <= '0';
            -- Update burst signal at start of transfer, or with each data ack
            -- TODO: M_rdBurst may not be asserted until xfer_ack_i
            elsif(xfer_init_i='1' or PLB_MRdDAck='1') then
               M_rdBurst <= prim_burst_nxt;
            end if;
         end if;
      end if;
   end process;
--   process(plb_term, mst_term_r, prim_last, pipe_burst, pipe_valid) begin
--      if(plb_term='1') then
--         M_rdBurst <= pipe_burst and pipe_valid;
--      else
--         M_rdBurst <= not mst_term_r and not prim_last;
--      end if;
--   end process;

   -- Assert prim_comp to complete transfer:
   -- * with last d-ack of transfer
   -- * with next d-ack when plb_term or mst_term are asserted
   -- * with mst_term when primary transfer not acknowledged
   process(PLB_MRdDAck, prim_last, plb_term, mst_term, prim_ack) begin
      if(PLB_MRdDAck='1') then
         prim_comp <= prim_last or plb_term or mst_term;
      else
         prim_comp <= mst_term and not prim_ack;
      end if;
   end process;

   -- Latch IP termination request until completion of transfer
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            mst_term_r <= '0';
         else
            if(prim_comp='1') then
               mst_term_r <= '0';
            elsif(M_rdAbort_i='1') then
               mst_term_r <= '1';
            end if;
         end if;
      end if;
   end process;

   -- When not C_EN_FAST_ABORT, assert terminate signal immediately only if rearbitrating
   NEN_FAST_ABORT: if(not C_EN_FAST_ABORT) generate
      mst_term <= M_rdAbort_i when(xfer_rearb_i='1' and prim_ack_p='0') else mst_term_r;
   end generate NEN_FAST_ABORT;

   -- When C_EN_FAST_ABORT, always pass M_rdAbort_i through
   EN_FAST_ABORT: if(C_EN_FAST_ABORT) generate
      mst_term <= '1' when(mst_term_r='1') else M_rdAbort_i;
   end generate EN_FAST_ABORT;

   -- Wait until one cycle after prim_ack goes low before rearbitrating
   M_rdRearb_o  <= xfer_rearb_i and not prim_ack_p;
   -- Control signals to arbiter (Affect arbiter only!)
   xfer_retry_o <= xfer_rearb_i and not prim_ack_p;
   xfer_abort_o <= mst_term and prim_valid and not prim_ack;

   -- Various registers
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            M_rdData_o  <= (others=>'0');
            M_rdAck_o   <= '0';

            M_rdComp_o  <= '0';
            M_rdError_o <= '0';
            plb_term    <= '0';
         else
            M_rdAck_o <= PLB_MRdDAck;
            if(PLB_MRdDAck='1') then
               M_rdData_o <= PLB_MRdDBus;
            end if;
            -- Generate delayed prim_ack for rearbitration signal generation
            prim_ack_p <= prim_ack;
            -- IPIC's complete signal is pipeliner's complete signal delayed
            M_rdComp_o <= prim_comp;
            -- Error occurred if transfer completes before all data was transferred,
            --   or if transfer was never acknowledged
            M_rdError_o <= prim_comp and (not prim_last or not prim_ack);
            -- Keep track of previous termination request by slave
            -- Since PLB_MRdBTerm may already be asserted for a following transfer
            --   with the last data item, give priority to asserting plb_term
            if(PLB_MRdBTerm='1') then
               plb_term <= '1';
            elsif(prim_comp='1') then
               plb_term <= '0';
            end if;
         end if;
      end if;
   end process;

   -- Instantiate the request pipeliner
   pipeliner_0: entity lisipif_master_v1_00_c.lipif_mst_pipeliner
      generic map (
         C_NUM_WIDTH    => C_NUM_WIDTH
      )
      port map (
         clk            => clk,
         reset          => reset,

         xfer_num_i     => M_rdNum_i,
         xfer_adv_i     => PLB_MRdDAck,
         xfer_nxt_i     => prim_comp,
      
         xfer_req_i     => xfer_init_i,
         xfer_ack_i     => xfer_ack_i,
         xfer_rdy_o     => xfer_rdy_o,
      
         prim_valid_o   => prim_valid,
         prim_last_o    => prim_last,
         prim_ack_o     => prim_ack,

         prim_nburst_o  => prim_burst_nxt,
         pipe_nburst_o  => pipe_burst_nxt
      );
end lipif_mst_read_rtl;
