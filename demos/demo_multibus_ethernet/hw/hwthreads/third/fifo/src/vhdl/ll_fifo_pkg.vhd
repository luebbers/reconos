-------------------------------------------------------------------------------
--                                                                           
--  Module      : ll_fifo_pkg.vhd          
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--                                                                           
--  Project     : Parameterizable LocalLink FIFO                             
--                                                                           
--  Description : Top Level Package File for LocalLink FIFO                  
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

package ll_fifo_pkg is

   component ll_fifo is
   generic (
        MEM_TYPE        :       integer := 0;           -- 0 choose BRAM, 
                                                        -- 1 choose DRAM
        BRAM_MACRO_NUM  :       integer := 2;           -- For BRAM only
        DRAM_DEPTH      :       integer := 16;          -- For DRAM only                  
        WR_DWIDTH       :       integer := 32;          -- FIFO write data 
                                                        -- width, allowable 
                                                        -- values are
                                                        -- 8, 16, 32, 64, 128.
        RD_DWIDTH       :       integer := 32;          -- FIFO read data 
                                                        -- width, allowable 
                                                        -- values are
                                                        -- 8, 16, 32, 64, 128.
        RD_REM_WIDTH    :       integer := 2;           -- Width of remaining 
                                                        -- data to receiving 
        WR_REM_WIDTH    :       integer := 2;           -- Width of remaining 
                                                        -- data to transmitting 
        USE_LENGTH      :       boolean := true;        -- length fifo option
        glbtm           :       time    := 1 ns);       -- global timing delay for simulation
   port (
        -- Reset
        areset_in:              in std_logic;
         
        -- clocks
        write_clock_in:         in std_logic;
        read_clock_in:          in std_logic;
         
        -- Interface to downstream user application
        data_out:               out std_logic_vector(0 to RD_DWIDTH-1);
        rem_out:                out std_logic_vector(0 to RD_REM_WIDTH-1);
        sof_out_n:              out std_logic;
        eof_out_n:              out std_logic;
        src_rdy_out_n:          out std_logic;
        dst_rdy_in_n:           in std_logic;

        -- Interface to upstream user application        
        data_in:                in std_logic_vector(0 to WR_DWIDTH-1);
        rem_in:                 in std_logic_vector(0 to WR_REM_WIDTH-1);
        sof_in_n:               in std_logic;
        eof_in_n:               in std_logic;
        src_rdy_in_n:           in std_logic;
        dst_rdy_out_n:          out std_logic;
 
        -- FIFO status signals   
        fifostatus_out:         out std_logic_vector(0 to 3);
        
        -- Length Status
        len_rdy_out:            out std_logic;
        len_out:                out std_logic_vector(0 to 15);
        len_err_out:            out std_logic);
   end component;


   component ll_fifo_BRAM is
   generic (
        BRAM_MACRO_NUM  :       integer:=1;         --Number of BRAMs.  Values Allowed: 1, 2, 4, 8, 16
        WR_DWIDTH       :       integer:= 8;            --FIFO write data width, allowable values are
                                                                                                --8, 16, 32, 64, 128.
        RD_DWIDTH       :       integer:= 8;            --FIFO read data width, allowable values are
                                                                                                --8, 16, 32, 64, 128.           

        WR_REM_WIDTH    :       integer:= 1;            --Width of remaining data to transmitting side
        RD_REM_WIDTH    :       integer:= 1;        --Width of remaining data to receiving side         
          
        USE_LENGTH:             boolean :=true;
        
        glbtm           :       time:= 1 ns);
   port (
        -- Reset
         reset:                 in std_logic;
         
        -- clocks
         write_clock_in:        in std_logic;
         read_clock_in:         in std_logic;

        -- interface to upstream user application
         data_in:               in std_logic_vector(WR_DWIDTH-1 downto 0);
         rem_in:                in std_logic_vector(WR_REM_WIDTH-1 downto 0);
         sof_in_n:              in std_logic;
         eof_in_n:              in std_logic;
         src_rdy_in_n:          in std_logic;
         dst_rdy_out_n:         out std_logic;

        -- interface to downstream user application
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

   end component;

   component ll_fifo_DRAM is
   generic (
        DRAM_DEPTH      :       integer:= 16;           --FIFO depth, default is 
                                                        --16,allowable values are
                                                        --16, 32, 64, 128.
        WR_DWIDTH       :       integer:= 8;            --FIFO write data width, 
                                                        --allowable values are
                                                        --8, 16, 32, 64, 128.
        RD_DWIDTH       :       integer:= 8;            --FIFO read data width, 
                                                        --allowable values are
                                                        --8, 16, 32, 64, 128.           
        RD_REM_WIDTH    :       integer:= 1;            --Width of remaining data 
                                                        --to receiving side
        WR_REM_WIDTH    :       integer:= 1;            --Width of remaining data 
                                                        --to transmitting side
                
        USE_LENGTH      :       boolean := true;
        glbtm           :       time:= 1 ns );
   port (
        -- Reset
         reset:                 in std_logic;
         
        -- clocks
         write_clock_in:        in std_logic;
         read_clock_in:         in std_logic;
         
        -- interface to upstream user application
         data_in:               in std_logic_vector(WR_DWIDTH-1 downto 0);
         rem_in:                in std_logic_vector(WR_REM_WIDTH-1 downto 0);
         sof_in_n:              in std_logic;
         eof_in_n:              in std_logic;
         src_rdy_in_n:          in std_logic;
         dst_rdy_out_n:         out std_logic;
        
        -- interface to downstream user application
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
         
   end component;


end ll_fifo_pkg;
