-------------------------------------------------------------------------------
--                                                                       
--  Module      : DRAM_fifo_pkg.vhd        
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--    
--  Project     : Parameterizable LocalLink FIFO
--
--  Description : Package of Distributed RAM FIFO components
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

package DRAM_fifo_pkg is
    component DRAM_fifo
       generic (
            DRAM_DEPTH:         integer;          
                                                  
            WR_DWIDTH:          integer;          
                                                  
            RD_DWIDTH:          integer;          
                                                  
            RD_REM_WIDTH:       integer;          
            WR_REM_WIDTH:       integer;        
            USE_LENGTH:         boolean;
            glbtm:              time
       );
       port (
            -- Reset
            FIFO_GSR_IN:        in std_logic;

            -- clocks
            WRITE_CLOCK_IN:     in std_logic;
            READ_CLOCK_IN:      in std_logic;

            -- signals tranceiving from User Application using standardized 
            -- specification for FifO interface         
            READ_DATA_OUT:      out std_logic_vector(RD_DWIDTH-1 downto 0);
            READ_REM_OUT:       out std_logic_vector(RD_REM_WIDTH-1 downto 0);
            READ_SOF_OUT_N:     out std_logic;
            READ_EOF_OUT_N:     out std_logic;
            READ_ENABLE_IN:     in std_logic;

            -- signals trasceiving from Aurora        
            WRITE_DATA_IN:      in std_logic_vector(WR_DWIDTH-1 downto 0);
            WRITE_REM_IN:       in std_logic_vector(WR_REM_WIDTH-1 downto 0);
            WRITE_SOF_IN_N:     in std_logic;
            WRITE_EOF_IN_N:     in std_logic;
            WRITE_ENABLE_IN:    in std_logic;

            -- FifO status signals
            FIFOSTATUS_OUT:     out std_logic_vector(3 downto 0);
            FULL_OUT:           out std_logic;
            EMPTY_OUT:          out std_logic;
            DATA_VALID_OUT:     out std_logic;
             
            LEN_OUT:            out std_logic_vector(15 downto 0);
            LEN_RDY_OUT:        out std_logic;
            LEN_ERR_OUT:        out std_logic);          
        end component;


  component DRAM_macro is
   generic (
        DRAM_DEPTH      :       integer := 16;    -- FIFO depth, default is 16,
                                                  -- allowable values are 16, 32, 
                                                  -- 64, 128.
   
        WR_DWIDTH       :       integer := 32;    --FIFO write data width. 
                                                  --Allowed: 8, 16, 32, 64
        RD_DWIDTH       :       integer := 32;    --FIFO read data width.
                                                  --Allowed: 8, 16, 32, 64
        WR_REM_WIDTH    :       integer := 2;     --log2(WR_DWIDTH/8)
        RD_REM_WIDTH    :       integer := 2;     --log2(RD_DWIDTH/8)
        
        RD_ADDR_MINOR_WIDTH :   integer := 1;
        RD_ADDR_WIDTH   :       integer := 9;
        
        WR_ADDR_MINOR_WIDTH  :  integer := 1;
        WR_ADDR_WIDTH   :       integer := 9;

        CTRL_WIDTH:             integer := 3;
        
        glbtm           :       time := 1 ns );
        
   port (
         -- Reset
         fifo_gsr:           in  std_logic;
          
         -- clocks
         wr_clk:             in  std_logic;
         rd_clk:             in  std_logic;
                  
         rd_allow:           in  std_logic;
         rd_allow_minor:     in  std_logic;
         rd_addr_minor:      in  std_logic_vector(RD_ADDR_MINOR_WIDTH-1 downto 0);
         rd_addr:            in  std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
         rd_data:            out std_logic_vector(RD_DWIDTH -1 downto 0);
         rd_rem:             out std_logic_vector(RD_REM_WIDTH-1 downto 0);
         rd_sof_n:           out std_logic;
         rd_eof_n:           out std_logic;
         
                  
         wr_allow:           in std_logic;
         wr_allow_minor:     in std_logic;
         wr_allow_minor_p:   in std_logic;         
         wr_addr:            in std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
         wr_addr_minor:      in std_logic_vector(WR_ADDR_MINOR_WIDTH-1 downto 0);
         wr_data:            in std_logic_vector(WR_DWIDTH-1 downto 0);
         wr_rem:             in std_logic_vector(WR_REM_WIDTH-1 downto 0);
         wr_sof_n:           in std_logic;
         wr_eof_n:           in std_logic;
         wr_sof_n_p:         in std_logic;
         wr_eof_n_p:         in std_logic;
         ctrl_wr_buf:        out std_logic_vector(CTRL_WIDTH-1 downto 0)
         
         );
         
   end component;

    
    component RAM_64nX1 
        generic (
            RAM_NUM     :       integer;  -- 4, 8
            ADDR_WIDTH  :       integer   -- equal to ceiling[log2(RAM_NUM * 64)] 
            );
        port (
            DI      :       in std_logic;
            WEn     :       in std_logic;
            WCLK    :       in std_logic;
            Ad      :       in std_logic_vector(ADDR_WIDTH-1 downto 0);
            DRA     :       in std_logic_vector(ADDR_WIDTH-1 downto 0);
            DO      :       out std_logic;
            SO      :       out std_logic); 
        end component;
end DRAM_fifo_pkg;
