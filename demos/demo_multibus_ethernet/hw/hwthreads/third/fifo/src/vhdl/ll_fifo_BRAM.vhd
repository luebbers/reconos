-------------------------------------------------------------------------------
--                                                                           
--  Module      : ll_fifo_BRAM.vhd          
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--                                                                           
--  Project     : Parameterizable LocalLink FIFO                             
--                                                                           
--  Description : Top Level of LocalLink FIFO in BRAM implementation
--                                                                           
--  Designer    : Wen Ying Wei, Davy Huang
--                                            
--  Company     : Xilinx, Inc.                
--                                            
--  Disclaimer  : XILINX IS PROVIDING THIS DESIGN, CODE, OR    
--                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
--                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
--                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
--                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
--                APPLICATION OR STANDARD, XILINX IS MAKING NO
--                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
--                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
--                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
--                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
--                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
--                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
--                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
--                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
--                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
--                PURPOSE.
--                
--                (c) Copyright 2005 Xilinx, Inc.
--                All rights reserved.
--                                            
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.BRAM_fifo_pkg.all;


entity ll_fifo_BRAM is
   generic (
        BRAM_MACRO_NUM  :       integer:=1;         --Number of BRAMs.  Values Allowed: 1, 2, 4, 8, 16
        WR_DWIDTH       :       integer:= 8;        --FIFO write data width, allowable values are
                                                    --8, 16, 32, 64, 128.
        RD_DWIDTH       :       integer:= 8;        --FIFO read data width, allowable values are
                                                    --8, 16, 32, 64, 128.           

        WR_REM_WIDTH    :       integer:= 1;        --Width of remaining data to transmitting side
        RD_REM_WIDTH    :       integer:= 1;        --Width of remaining data to receiving side         
          
        USE_LENGTH:             boolean :=true;
        
        glbtm           :       time:= 1 ns);
   port (
        -- Reset
         reset:                 in std_logic;
         
        -- clocks
         write_clock_in:        in std_logic;
         read_clock_in:         in std_logic;

        -- signals tranceiving from User Application using standardized specification
        -- for FIFO interface
         data_in:               in std_logic_vector(WR_DWIDTH-1 downto 0);
         rem_in:                in std_logic_vector(WR_REM_WIDTH-1 downto 0);
         sof_in_n:              in std_logic;
         eof_in_n:              in std_logic;
         src_rdy_in_n:          in std_logic;
         dst_rdy_out_n:         out std_logic;

        -- signals trasceiving from Aurora         
         data_out:              out std_logic_vector(RD_DWIDTH-1 downto 0);
         rem_out:               out std_logic_vector(RD_REM_WIDTH-1 downto 0);
         sof_out_n:             out std_logic;
         eof_out_n:             out std_logic;
         src_rdy_out_n:         out std_logic;
         dst_rdy_in_n:          in std_logic;
          
        -- FIFO status signals
         fifostatus_out:        out std_logic_vector(3 downto 0);
         
         -- Length Status
         len_rdy_out:           out std_logic;
         len_out:               out std_logic_vector(15 downto 0);
         len_err_out:           out std_logic);

end ll_fifo_BRAM;

architecture ll_fifo_BRAM_rtl of ll_fifo_BRAM is
   signal gsr:                  std_logic;
   signal gnd:                  std_logic := '0';
   signal pwr:                  std_logic := '1';
   signal rd_clk:               std_logic;
   signal wr_clk:               std_logic;
   signal rd_data:              std_logic_vector(RD_DWIDTH-1 downto 0) := (others => '0');
   signal wr_data:              std_logic_vector(WR_DWIDTH-1 downto 0) := (others => '0');
   signal rd_rem:               std_logic_vector(RD_REM_WIDTH-1 downto 0) := (others => '0');
   signal wr_rem:               std_logic_vector(WR_REM_WIDTH-1 downto 0) := (others => '0');
   signal rd_sof_n:             std_logic;
   signal rd_eof_n:             std_logic;
   signal wr_sof_n:             std_logic;
   signal wr_eof_n:             std_logic;
   signal src_rdy_i:            std_logic;
   signal full:                 std_logic;
   signal empty:                std_logic;
   signal dst_rdy_i:            std_logic;
   signal empty_p:              std_logic;
   signal prefetch:             std_logic;
   signal fifostatus:           std_logic_vector(3 downto 0);
   signal data_valid:           std_logic;
   signal len:                  std_logic_vector(15 downto 0);
   signal len_rdy:              std_logic;
   signal len_err:              std_logic;
   signal empty_falling_edge:   std_logic;
   signal prefetch_allow:       std_logic;
   
begin   

   gsr <= reset;

   rd_clk <= read_clock_in;
   wr_clk <= write_clock_in;  
---------------------------------------
   wr_data <= data_in;          
   wr_rem <= rem_in;
   wr_sof_n <= sof_in_n;
   wr_eof_n <= eof_in_n;   
   src_rdy_i <= not src_rdy_in_n;
   dst_rdy_out_n <= full;
   
-----  From User  ---------------------  
   data_out <= rd_data;
   rem_out <= rd_rem;
   sof_out_n <= rd_sof_n;
   eof_out_n <= rd_eof_n;
   dst_rdy_i <= (not dst_rdy_in_n) or prefetch;
   src_rdy_out_n <= not data_valid;
-----  Flow control signals -----------
   fifostatus_out <= fifostatus;
   len_rdy_out <= len_rdy;
   len_out <= len;
   len_err_out <= len_err;

-----------------------------------------------------------------------------   
   B_RAM_FIFO: BRAM_fifo 
       generic map (
                BRAM_MACRO_NUM  => BRAM_MACRO_NUM,                       
                WR_DWIDTH       => WR_DWIDTH,
                RD_DWIDTH       => RD_DWIDTH,
                RD_REM_WIDTH    => RD_REM_WIDTH,
                WR_REM_WIDTH    => WR_REM_WIDTH,
                USE_LENGTH      => USE_LENGTH,
                glbtm           => glbtm)
       port map
            (   
                fifo_gsr_in     => gsr,
                write_clock_in  => wr_clk,
                read_clock_in   => rd_clk,
                read_data_out   => rd_data,
                read_rem_out    => rd_rem,
                read_sof_out_n  => rd_sof_n,
                read_eof_out_n  => rd_eof_n,
                read_enable_in  => dst_rdy_i,    
                write_data_in   => wr_data,
                write_rem_in    => wr_rem,
                write_sof_in_n  => wr_sof_n,
                write_eof_in_n  => wr_eof_n,
                write_enable_in => src_rdy_i,
                fifostatus_out  => fifostatus,
                full_out        => full,
                empty_out       => empty,
                data_valid_out  => data_valid,
                len_out         => len,
                len_rdy_out     => len_rdy,
                len_err_out     => len_err);
                
--------------------------------------------------------------------
-- Generate PREFETCH
--------------------------------------------------------------------


prefetch_proc: process (gsr, rd_clk)
begin
  if (gsr = '1') then
     prefetch_allow <= '1' after glbtm;
  elsif (rd_clk'EVENT and rd_clk = '1') then
    if dst_rdy_in_n = '0'  and empty = '1' then
       prefetch_allow <= '1' after glbtm;
    elsif dst_rdy_in_n = '1' and empty_falling_edge = '1' then
       prefetch_allow <= '0' after glbtm;
    elsif dst_rdy_in_n = '0' and empty = '0' then
       prefetch_allow <= '0' after glbtm;
    end if;
  end if;
end process prefetch_proc;

empty_falling_edge <= (empty_p and (not empty));
prefetch <= empty_falling_edge and prefetch_allow;

empty_p_proc: process (gsr, rd_clk)     -- Delayed empty signal
begin
   if (gsr = '1') then
      empty_p <= '1';
   elsif (rd_clk'EVENT and rd_clk ='1') then
      empty_p <= empty after glbtm;
   end if;
end process empty_p_proc;

   
end ll_fifo_BRAM_rtl;
