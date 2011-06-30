-------------------------------------------------------------------------------
--                                                                           
--  Module      : ll_fifo.vhd          
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--                                                                           
--  Project     : Parameterizable LocalLink FIFO                             
--                                                                           
--  Description : Top Level of LocalLink FIFO                  
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
use work.ll_fifo_pkg.all;


entity ll_fifo is
   generic (
        MEM_TYPE        :       integer := 0;           -- 0 choose BRAM, 
                                                        -- 1 choose Distributed RAM
        BRAM_MACRO_NUM  :       integer := 16;          -- Memory Depth. For BRAM only (square nr only)
        DRAM_DEPTH      :       integer := 16;          -- Memory Depth. For DRAM only                  
        WR_DWIDTH       :       integer := 32;          -- FIFO write data width,
                                                        -- Acceptable values are
                                                        -- 8, 16, 32, 64, 128.
        RD_DWIDTH       :       integer := 8;          -- FIFO read data width,
                                                        -- Acceptable values are
                                                        -- 8, 16, 32, 64, 128.
        RD_REM_WIDTH    :       integer := 1;           -- Remainder width of read data
        WR_REM_WIDTH    :       integer := 2;           -- Remainder width of write data
        USE_LENGTH      :       boolean := false;        -- Length FIFO option
        glbtm           :       time    := 1 ns);       -- Global timing delay for simulation
        
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
end ll_fifo;

architecture LL_FIFO_rtl of ll_fifo is

begin   


BRAM_GEN: if MEM_TYPE = 0 generate
    BRAMFIFO:  ll_fifo_BRAM
    generic map (
    BRAM_MACRO_NUM      =>      BRAM_MACRO_NUM,
    WR_DWIDTH           =>      WR_DWIDTH,
    RD_DWIDTH           =>      RD_DWIDTH,
    RD_REM_WIDTH        =>      RD_REM_WIDTH,
    WR_REM_WIDTH        =>      WR_REM_WIDTH,
    USE_LENGTH          =>      USE_LENGTH,
    glbtm               =>      glbtm )
    port map (
    -- Reset
    reset               =>      areset_in,
                 
    -- clocks
    write_clock_in      =>      write_clock_in,
    read_clock_in       =>      read_clock_in,
                 
    -- interface to upstream user application
    data_in             =>      data_in,        
    rem_in              =>      rem_in, 
    sof_in_n            =>      sof_in_n,
    eof_in_n            =>      eof_in_n,
    src_rdy_in_n        =>      src_rdy_in_n,
    dst_rdy_out_n       =>      dst_rdy_out_n,
                              
    -- interface to downstream user application
    data_out            =>      data_out,
    rem_out             =>      rem_out,
    sof_out_n           =>      sof_out_n,
    eof_out_n           =>      eof_out_n,
    src_rdy_out_n       =>      src_rdy_out_n,  
    dst_rdy_in_n        =>      dst_rdy_in_n,   
              
    -- FIFO status signals                          
    fifostatus_out      =>      fifostatus_out,
    
    -- Length signals
    len_rdy_out         =>      len_rdy_out,
    len_out             =>      len_out,
    len_err_out         =>      len_err_out);
end generate BRAM_GEN;

DRAM_GEN: if MEM_TYPE = 1 generate
    DRAMFIFO:  ll_fifo_DRAM
    generic map (
    DRAM_DEPTH          =>      DRAM_DEPTH,
    WR_DWIDTH           =>      WR_DWIDTH,
    RD_DWIDTH           =>      RD_DWIDTH,
    RD_REM_WIDTH        =>      RD_REM_WIDTH,
    WR_REM_WIDTH        =>      WR_REM_WIDTH,
    USE_LENGTH          =>      USE_LENGTH,        
    glbtm               =>      glbtm
    )
    port map (
    -- Reset
    reset               =>      areset_in,
     
    -- clocks
    write_clock_in      =>      write_clock_in,
    read_clock_in       =>      read_clock_in,
     
    -- interface to upstream user application
    data_in             =>      data_in,       
    rem_in              =>      rem_in,        
    sof_in_n            =>      sof_in_n,
    eof_in_n            =>      eof_in_n,
    src_rdy_in_n        =>      src_rdy_in_n,
    dst_rdy_out_n       =>      dst_rdy_out_n,
    
        
    -- interface to downstream user application
    data_out            =>      data_out,
    rem_out             =>      rem_out,
    sof_out_n           =>      sof_out_n,
    eof_out_n           =>      eof_out_n,
    src_rdy_out_n       =>      src_rdy_out_n,  
    dst_rdy_in_n        =>      dst_rdy_in_n,            
              
    -- FIFO status signals         
    fifostatus_out      =>      fifostatus_out,
    len_rdy_out         =>      len_rdy_out,
    len_out             =>      len_out,
    len_err_out         =>      len_err_out);
end generate DRAM_GEN;

end LL_FIFO_rtl;
