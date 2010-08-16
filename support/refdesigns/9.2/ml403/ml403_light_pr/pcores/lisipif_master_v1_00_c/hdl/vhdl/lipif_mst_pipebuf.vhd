--------------------------------------------------------------------------------
-- Company: Lehrstuhl Integrierte Systeme - TUM
-- Engineer: Johannes Zeppenfeld
-- 
-- Project Name:   LIS-IPIF
-- Module Name:    lipif_pipebuf
-- Architectures:  lipif_pipebuf_rtl
-- Description:
--    This module provides a buffer for the acknowledge-request flow within
--    a pipeline. In effect it is a FIFO with a fixed depth of two.
--
-- Dependencies:
--
-- Revision:
--    13.3.2006 - File Created
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity lipif_mst_pipebuf is
   generic (
      C_DATA_WIDTH   : integer := 64;
      C_EN_SRL16     : boolean := true
   );
   port (
      clk            : in std_logic;
      reset          : in std_logic;

      -- Previous (input) stage I/O
      prevReq_i      : in std_logic;
      prevRdy_o      : out std_logic;
      prevData_i     : in std_logic_vector(C_DATA_WIDTH-1 downto 0);

      -- Next (output) stage I/O
      nextReq_o      : out std_logic;
      nextRdy_i      : in std_logic;
      nextData_o     : out std_logic_vector(C_DATA_WIDTH-1 downto 0)
   );
end lipif_mst_pipebuf;

architecture lipif_mst_pipebuf_rtl of lipif_mst_pipebuf is
   -- Primary and secondary valid signals indicate if data is valid
   signal valid_prim    : std_logic;
   signal valid_sec     : std_logic;
begin
   prevRdy_o <= not valid_sec;
   nextReq_o <= valid_prim;

   EN_SRL16: if(C_EN_SRL16) generate
      signal srl_ce     : std_logic;
   begin
      srl_ce <= prevReq_i and not valid_sec;
      
      SRL_FIFO: for i in 0 to C_DATA_WIDTH-1 generate
         SRL16E_I: SRL16E
            generic map (
               INIT => X"0000"
            )
            port map (
               CLK => clk,
               CE => srl_ce,
               D => prevData_i(i),
               Q => nextData_o(i),
               A0 => valid_sec,
               A1 => '0',
               A2 => '0',
               A3 => '0'
            );
      end generate SRL_FIFO;
   end generate EN_SRL16;

   NEN_SRL16: if(not C_EN_SRL16) generate
      -- Registers for primary and secondary data
      signal data_prim     : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      signal data_prim_nxt : std_logic_vector(C_DATA_WIDTH-1 downto 0);
      signal data_sec      : std_logic_vector(C_DATA_WIDTH-1 downto 0);
   begin
      nextData_o <= data_prim;
      data_prim_nxt <= data_sec when(valid_sec='1') else prevData_i;

      process(clk) begin
         if(clk='1' and clk'event) then
            if(reset='1') then
               data_prim <= (others=>'0');
               data_sec <= (others=>'0');
            else
               -- Handle Primary Stage
               if(nextRdy_i='1' or valid_prim='0') then
                  data_prim <= data_prim_nxt;
               end if;
               
               -- Handle Secondary Stage
               if(nextRdy_i='1' or valid_sec='0') then
                  data_sec <= prevData_i;
               end if;
            end if;
         end if;
      end process;
   end generate NEN_SRL16;

   -- Generate valid signals
   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            valid_prim <= '0';
            valid_sec <= '0';
         else
            -- Handle Primary Stage
            if(nextRdy_i='1' or valid_prim='0') then
               valid_prim <= valid_sec or prevReq_i;
            end if;
            
            -- Handle Secondary Stage
            if(nextRdy_i='1' or valid_sec='0') then
               valid_sec <= valid_prim and prevReq_i and not nextRdy_i;
            end if;
         end if;
      end if;
   end process;
end lipif_mst_pipebuf_rtl;
