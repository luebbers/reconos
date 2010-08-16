--------------------------------------------------------------------------------
-- Company: Lehrstuhl Integrierte Systeme - TUM
-- Engineer: Johannes Zeppenfeld
-- 
-- Project Name:   LIS-IPIF
-- Module Name:    lipif_mst_pipeliner
-- Architectures:  lipif_mst_pipeliner_rtl
-- Description:
--
-- Dependencies:
--
-- Revision:
--    25.4.2006 - File Created
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity lipif_mst_pipeliner is
   generic (
      C_NUM_WIDTH    : integer := 5
   );
   port(
      clk            : in std_logic;
      reset          : in std_logic;

      xfer_num_i     : in std_logic_vector(C_NUM_WIDTH-1 downto 0);
      xfer_adv_i     : in std_logic;
      xfer_nxt_i     : in std_logic;
      
      xfer_req_i     : in std_logic;
      xfer_ack_i     : in std_logic;
      xfer_rdy_o     : out std_logic;
      
      prim_valid_o   : out std_logic;
      prim_last_o    : out std_logic;
      prim_ack_o     : out std_logic;

      prim_nburst_o  : out std_logic;
      pipe_nburst_o  : out std_logic
   );
end lipif_mst_pipeliner;

architecture lipif_mst_pipeliner_rtl of lipif_mst_pipeliner is
   signal num_prim      : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal num_prim_n    : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal num_sec       : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal num_sec_n     : std_logic_vector(C_NUM_WIDTH-1 downto 0);
   signal num_tri       : std_logic_vector(C_NUM_WIDTH-1 downto 0);

   signal xfer_last     : std_logic;
   signal xfer_last_n   : std_logic;
   signal xfer_comp     : std_logic;

   signal valid_prim    : std_logic;
   signal valid_sec     : std_logic;
   signal valid_tri     : std_logic;
   
   signal ack_prim      : std_logic;
   signal ack_sec       : std_logic;
begin
   -- Connect ports to internal signals
   xfer_rdy_o  <= not valid_tri;
   xfer_comp   <= xfer_nxt_i;

   prim_valid_o <= valid_prim;
   prim_last_o  <= xfer_last;
   prim_ack_o   <= ack_prim;

   -- Next xfer last state calculated from next value of primary burst counter
   xfer_last_n <= '1' when (num_prim_n(C_NUM_WIDTH-1 downto 1)=0) else '0';

   -- Pipelined next burst signal should only be asserted if a transfer is actually pipelined
   -- Don't need to check for a new transfer being pipelined this cycle: it can't have been
   -- acknowledged yet!
   pipe_nburst_o <= '0' when (num_sec_n(C_NUM_WIDTH-1 downto 1)=0) else valid_sec;
   prim_nburst_o <= not xfer_last_n;

   -- Generate next counts for primary and secondary stages
   process(xfer_comp, valid_prim, valid_sec, valid_tri, xfer_adv_i, xfer_num_i, num_prim, num_sec, num_tri) begin
      -- Primary Stage
      if(xfer_comp='1' or valid_prim='0') then
         if(valid_sec='0') then
            num_prim_n <= xfer_num_i;
         else
            num_prim_n <= num_sec;
         end if;
      elsif(xfer_adv_i='1') then
         -- NOTE: This is synthesized into both a subtractor and down-counter.
         --       May save a few slices if the down-counter is removed.
         num_prim_n <= num_prim - 1;
      else
         num_prim_n <= num_prim;
      end if;
      
      -- Secondary Stage
      if(xfer_comp='1' or valid_sec='0') then
         if(valid_tri='0') then
            num_sec_n <= xfer_num_i;
         else
            num_sec_n <= num_tri;
         end if;
      else
         num_sec_n <= num_sec;
      end if;
   end process;

   -- Latch next counter values for all three stages
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            num_prim <= (others=>'0');
            num_sec  <= (others=>'0');
            num_tri  <= (others=>'0');
         else
            -- Primary and secondary stages have next value calculated externally
            num_prim <= num_prim_n;
            num_sec  <= num_sec_n;

            -- Trinary Stage
            if(xfer_comp='1' or valid_tri='0') then
               num_tri <= xfer_num_i;
            end if;

            -- Last indicator can also be latched
            xfer_last <= xfer_last_n;
         end if;
      end if;
   end process;

   -- Generate ack state signals for first two pipeline stages
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            ack_prim   <= '0';
            ack_sec    <= '0';
         else
            -- Primary Stage
            if(xfer_comp='1' or ack_prim='0') then
               ack_prim <= ack_sec or xfer_ack_i;
            end if;

            -- Secondary Stage
            if(xfer_comp='1' or ack_sec='0') then
               ack_sec <= xfer_ack_i and ack_prim and (not xfer_comp or ack_sec);
            end if;
         end if;
      end if;
   end process;

   -- Generate valid signals for each pipeline stage
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            valid_prim <= '0';
            valid_sec  <= '0';
            valid_tri  <= '0';
         else
            -- Primary Stage
            if(xfer_comp='1' or valid_prim='0') then
               valid_prim <= valid_sec or xfer_req_i;
            end if;
            
            -- Secondary Stage
            if(xfer_comp='1' or valid_sec='0') then
               valid_sec <= valid_tri or (xfer_req_i and valid_prim and (valid_sec or not xfer_comp));
            end if;

            -- Trinary Stage
            if(xfer_comp='1' or valid_tri='0') then
               valid_tri <= xfer_req_i and valid_sec and not xfer_comp;
            end if;
         end if;
      end if;
   end process;
end lipif_mst_pipeliner_rtl;
