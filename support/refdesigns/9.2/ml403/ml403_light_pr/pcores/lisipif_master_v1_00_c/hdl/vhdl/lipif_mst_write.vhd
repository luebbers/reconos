--------------------------------------------------------------------------------
-- Company: Lehrstuhl Integrierte Systeme - TUM
-- Engineer: Johannes Zeppenfeld
-- 
-- Project Name:   LIS-IPIF
-- Module Name:    lipif_slv_write
-- Architectures:  lipif_slv_write_rtl
-- Description:
--
-- Dependencies:
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

entity lipif_mst_write is
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
      M_wrNum_i      : in std_logic_vector(C_NUM_WIDTH-1 downto 0);
      M_wrRearb_o    : out std_logic;
      M_wrAbort_i    : in std_logic;
      M_wrError_o    : out std_logic;

      M_wrData_i     : in std_logic_vector(63 downto 0);
      M_wrRdy_o      : out std_logic;
      M_wrAck_o      : out std_logic;
      M_wrComp_o     : out std_logic;

      -- PLB Signals
      PLB_MWrDAck    : in std_logic;
      PLB_MWrBTerm   : in std_logic;
      M_wrBurst      : out std_logic;
      M_wrDBus       : out std_logic_vector(0 to 63)
   );
end lipif_mst_write;

architecture lipif_mst_write_rtl of lipif_mst_write is
   signal prim_valid  : std_logic;
   signal prim_ack    : std_logic;
   signal prim_num    : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal prim_num_n  : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal prim_comp   : std_logic;
   signal prim_last   : std_logic;
   signal prim_last_n : std_logic;

   -- Transfer termination requests from IP/PLB
   signal mst_term    : std_logic;
   signal mst_term_r  : std_logic; -- Track until transfer complete
   signal plb_term    : std_logic;

   signal data_num    : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal data_num_n  : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal data_done   : std_logic;
   signal data_req    : std_logic;
   signal data_rdy    : std_logic;
   signal data_flush  : std_logic;
begin
   -- Signals to load new data into data buffer
   data_done    <= '1' when (data_num=0) else '0';
   data_req     <= data_rdy and (not data_done or xfer_init_i);
   M_wrRdy_o    <= data_req;

   -- Flush data buffer if transfer aborted prematurely
   data_flush   <= reset or (prim_comp and not prim_last);

   -- Pipelining not possible due to the inability of inserting a
   --    latency after a slave-initiated transfer termination.
   xfer_rdy_o   <= not prim_valid;

   -- Pass rearbitration signal to IP
   M_wrRearb_o  <= xfer_rearb_i and not prim_ack;
   -- Control signals to arbiter (Affect arbiter only!)
   xfer_retry_o <= xfer_rearb_i and not prim_ack;
   xfer_abort_o <= mst_term and prim_valid and not prim_ack;

   -- Next IP data count, subtraction and ce occur below
   data_num_n   <= M_wrNum_i when (xfer_init_i='1') else data_num;

   -- Assert prim_comp to complete transfer:
   -- * with last d-ack of transfer
   -- * with next d-ack when plb_term or mst_term are asserted
   -- * with mst_term when primary transfer not acknowledged
   process(PLB_MWrDAck, prim_last, plb_term, mst_term, prim_ack) begin
      if(PLB_MWrDAck='1') then
         prim_comp <= prim_last or plb_term or mst_term;
      else
         prim_comp <= mst_term and not prim_ack;
      end if;
   end process;

   -- Generate PLB remaining transfer counter signals (M_wrBurst, prim_num, prim_last)
   -- TIMING(18%) M_wrBurst is a register, so no problem
   -- TODO: When C_EN_FAST_ABORT, M_wrBurst must respond with M_wrAbort
   prim_num_n <= M_wrNum_i when(xfer_init_i='1') else prim_num - 1;
   prim_last_n <= '1' when (prim_num_n(C_NUM_WIDTH-1 downto 1)=0) else '0';

   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            M_wrBurst <= '0';
            prim_last <= '0';
            prim_num  <= (others=>'0');
         else
            -- Burst must go low in response to PLB/IP abort
            if(PLB_MWrBTerm='1' or M_wrAbort_i='1') then
               M_wrBurst <= '0';
            -- Update burst signal at start of transfer, or with each data ack
            elsif(xfer_init_i='1' or PLB_MWrDAck='1') then
               M_wrBurst <= not prim_last_n;
            end if;
            
            -- Update transfer counter at start of transfer, or with each data ack
            if(xfer_init_i='1' or PLB_MWrDAck='1') then
               prim_last <= prim_last_n;
               prim_num <= prim_num_n;
            end if;
         end if;
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
            elsif(M_wrAbort_i='1') then
               mst_term_r <= '1';
            end if;
         end if;
      end if;
   end process;

   -- When not C_EN_FAST_ABORT, assert terminate signal immediately only if rearbitrating
   -- TODO: Remove resulting combinatorial dependance of M_abort on M_wrAbort_i
   NEN_FAST_ABORT: if(not C_EN_FAST_ABORT) generate
      mst_term <= M_wrAbort_i when(xfer_rearb_i='1') else mst_term_r;
   end generate NEN_FAST_ABORT;

   -- When C_EN_FAST_ABORT, always pass M_wrAbort_i through
   EN_FAST_ABORT: if(C_EN_FAST_ABORT) generate
      mst_term <= '1' when(mst_term_r='1') else M_wrAbort_i;
   end generate EN_FAST_ABORT;

   -- Various registers
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            prim_valid <= '0';
            prim_ack   <= '0';
            data_num   <= (others=>'0');

            M_wrError_o <= '0';
            M_wrComp_o  <= '0';
            M_wrAck_o   <= '0';
            
            plb_term    <= '0';
         else
            -- Primary transfer valid
            if(xfer_init_i='1') then
               prim_valid <= '1';
            elsif(prim_comp='1') then
               prim_valid <= '0';
            end if;
            
            -- Primary transfer acknowledged by slave
            if(xfer_ack_i='1') then
               prim_ack <= '1';
            elsif(prim_comp='1') then
               prim_ack <= '0';
            end if;

            -- Remaining IP required data count
            if(prim_comp='1') then
               data_num <= (others=>'0');
            elsif(data_req='1') then
               data_num <= data_num_n - 1;
            else
               data_num <= data_num_n;
            end if;
            
            -- Error occurred if transfer completes before all data was transferred,
            --   or if transfer was never acknowledged
            M_wrError_o   <= prim_comp and (not prim_last or (not prim_ack and not xfer_ack_i));

            -- IPIC's complete signal is pipeliner's complete signal delayed
            M_wrComp_o    <= prim_comp;

            -- Data acknowledge to IP
            M_wrAck_o     <= PLB_MWrDAck;
            
            -- Previous termination request by slave
            if(prim_comp='1') then
               plb_term <= '0';
            elsif(PLB_MWrBTerm='1') then
               plb_term <= '1';
            end if;

         end if;
      end if;
   end process;

   -- Instantiate data buffer
   pipebuf_0: entity lisipif_master_v1_00_c.lipif_mst_pipebuf
      generic map (
         C_DATA_WIDTH => 64,
         -- Since SRL outputs are slow (>3ns after clk), must use registers
         -- to meet PLB timings.
         C_EN_SRL16   => false
      )
      port map (
         clk         => clk,
         reset       => data_flush,

         -- Previous (input) stage I/O
         prevReq_i   => data_req,
         prevRdy_o   => data_rdy,
         prevData_i  => M_wrData_i,

         -- Next (output) stage I/O
         nextReq_o   => open,
         nextRdy_i   => PLB_MWrDAck,
         nextData_o  => M_wrDBus
      );

end lipif_mst_write_rtl;
