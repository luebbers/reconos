-------------------------------------------------------------------------------
--                                                                       
--  Module      : BRAM_fifo_pkg.vhd        
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--    
--  Project     : Parameterizable LocalLink FIFO
--
--  Description : Package of Block SelectRAM FIFO components
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

package BRAM_fifo_pkg is

    component BRAM_fifo
        generic (
            BRAM_MACRO_NUM:     integer := 1;    
                                                 
            WR_DWIDTH:          integer := 32;   
                                                 
            RD_DWIDTH:          integer := 32;   
                                                 
            RD_REM_WIDTH:       integer:=2;      
            WR_REM_WIDTH:       integer:=2;      
            USE_LENGTH:         boolean := false;
            glbtm:              time:=2 ns
       );
       port (
            -- Reset
            fifo_gsr_in:           in std_logic;

            -- clocks
            write_clock_in:        in std_logic;
            read_clock_in:         in std_logic;

            -- signals tranceiving from User Application using standardized 
            -- specification for FifO interface         
            read_data_out:         out std_logic_vector(RD_DWIDTH-1 downto 0);
            read_rem_out:          out std_logic_vector(RD_REM_WIDTH-1 downto 0);
            read_sof_out_n:        out std_logic;
            read_eof_out_n:        out std_logic;
            read_enable_in:        in std_logic;

            -- signals trasceiving from Aurora        
            write_data_in:         in std_logic_vector(WR_DWIDTH-1 downto 0);
            write_rem_in:          in std_logic_vector(WR_REM_WIDTH-1 downto 0);
            write_sof_in_n:        in std_logic;
            write_eof_in_n:        in std_logic;
            write_enable_in:       in std_logic;

            -- FifO status signals
            fifostatus_out:        out std_logic_vector(3 downto 0);
            full_out:              out std_logic;
            empty_out:             out std_logic;
            data_valid_out:        out std_logic;
            len_out:               out std_logic_vector(15 downto 0);
            len_rdy_out:           out std_logic;
            len_err_out:           out std_logic);         
        end component;  
  
  
    component BRAM_macro is
     generic (
          BRAM_MACRO_NUM  :       integer := 1;     --Number of BRAM Blocks. 
                                                    --Allowed: 1, 2, 4, 8, 16
          WR_DWIDTH       :       integer := 32;    --FIFO write data width. 
                                                    --Allowed: 8, 16, 32, 64
          RD_DWIDTH       :       integer := 32;    --FIFO read data width.
                                                    --Allowed: 8, 16, 32, 64
          WR_REM_WIDTH    :       integer := 2;     --log2(WR_DWIDTH/8)
          RD_REM_WIDTH    :       integer := 2;     --log2(RD_DWIDTH/8)
          RD_PAD_WIDTH    :       integer := 1;
          RD_ADDR_FULL_WIDTH:     integer := 10;
          RD_ADDR_WIDTH   :       integer := 9;
          ADDR_MINOR_WIDTH:       integer := 1;
          
          WR_PAD_WIDTH    :       integer := 1;
          WR_ADDR_FULL_WIDTH:     integer := 10;
          WR_ADDR_WIDTH   :       integer := 9;
  
          glbtm           :       time := 1 ns );
          
     port (
           -- Reset
           fifo_gsr:           in  std_logic;
            
           -- clocks
           wr_clk:             in  std_logic;
           rd_clk:             in  std_logic;
                    
           rd_allow:           in  std_logic;
           rd_allow_minor:     in  std_logic;
           rd_addr_full:       in  std_logic_vector(RD_PAD_WIDTH+RD_ADDR_FULL_WIDTH-1 downto 0);
           rd_addr_minor:      in  std_logic_vector(ADDR_MINOR_WIDTH-1 downto 0);
           rd_addr:            in  std_logic_vector(RD_PAD_WIDTH + RD_ADDR_WIDTH -1 downto 0);
           rd_data:            out std_logic_vector(RD_DWIDTH -1 downto 0);
           rd_rem:             out std_logic_vector(RD_REM_WIDTH-1 downto 0);
           rd_sof_n:           out std_logic;
           rd_eof_n:           out std_logic;
           
                    
           wr_allow:           in std_logic;
           wr_allow_minor:     in std_logic;
           wr_addr:            in std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
           wr_addr_minor:      in std_logic_vector(ADDR_MINOR_WIDTH-1 downto 0);
           wr_addr_full:       in std_logic_vector(WR_PAD_WIDTH + WR_ADDR_FULL_WIDTH-1 downto 0);
           wr_data:            in std_logic_vector(WR_DWIDTH-1 downto 0);
           wr_rem:             in std_logic_vector(WR_REM_WIDTH-1 downto 0);
           wr_sof_n:           in std_logic;
           wr_eof_n:           in std_logic
           
           );
           
    end component;

  
    component BRAM_S8_S72 
        port (ADDRA  : in std_logic_vector (11 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (7 downto 0);
            DIB    : in std_logic_vector (63 downto 0);
            DIPB : in std_logic_vector (7 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (7 downto 0);
            DOB    : out std_logic_vector (63 downto 0);
            DOPB         : out std_logic_vector(7 downto 0));
    end component;
  
    component BRAM_S18_S72 
        port (ADDRA  : in std_logic_vector (10 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (15 downto 0);
            DIPA : in std_logic_vector (1 downto 0);
            DIB    : in std_logic_vector (63 downto 0);
            DIPB : in std_logic_vector (7 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (15 downto 0);
            DOPA         : out std_logic_vector(1 downto 0);
            DOB    : out std_logic_vector (63 downto 0);
            DOPB         : out std_logic_vector(7 downto 0));
    end component;
  
    component BRAM_S36_S72 
        port (ADDRA  : in std_logic_vector (9 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (31 downto 0);
            DIPA : in std_logic_vector (3 downto 0);
            DIB    : in std_logic_vector (63 downto 0);
            DIPB : in std_logic_vector (7 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (31 downto 0);
            DOPA : out std_logic_vector (3 downto 0);
            DOB    : out std_logic_vector (63 downto 0);
            DOPB         : out std_logic_vector(7 downto 0));
    end component;
  
    component  BRAM_S72_S72 
        port (ADDRA  : in std_logic_vector (8 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (63 downto 0);
            DIPA : in std_logic_vector (7 downto 0);
            DIB    : in std_logic_vector (63 downto 0);
            DIPB : in std_logic_vector (7 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (63 downto 0);
            DOPA         : out std_logic_vector(7 downto 0);
            DOB    : out std_logic_vector (63 downto 0);
            DOPB         : out std_logic_vector(7 downto 0));
    end component;
  
    component BRAM_S8_S144 
        port (ADDRA  : in std_logic_vector (12 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (7 downto 0);
            DIB    : in std_logic_vector (127 downto 0);
            DIPB : in std_logic_vector (15 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (7 downto 0);
            DOB    : out std_logic_vector (127 downto 0);
            DOPB         : out std_logic_vector(15 downto 0));
    end component;
  
    component BRAM_S16_S144 
       port (ADDRA  : in std_logic_vector (11 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (15 downto 0);
            DIB    : in std_logic_vector (127 downto 0);
            DIPB : in std_logic_vector (15 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (15 downto 0);
            DOB    : out std_logic_vector (127 downto 0);
            DOPB         : out std_logic_vector(15 downto 0));
    end component;
  
    component BRAM_S36_S144 
        port (ADDRA  : in std_logic_vector (10 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (31 downto 0);
            DIPA : in std_logic_vector (3 downto 0);
            DIB    : in std_logic_vector (127 downto 0);
            DIPB : in std_logic_vector (15 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (31 downto 0);
            DOPA : out std_logic_vector (3 downto 0);
            DOB    : out std_logic_vector (127 downto 0);
            DOPB         : out std_logic_vector(15 downto 0));
    end component;
  
    component BRAM_S72_S144 
        port (ADDRA  : in std_logic_vector (9 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (63 downto 0);
            DIPA : in std_logic_vector (7 downto 0);
            DIB    : in std_logic_vector (127 downto 0);
            DIPB : in std_logic_vector (15 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (63 downto 0);
            DOPA : out std_logic_vector (7 downto 0);
            DOB    : out std_logic_vector (127 downto 0);
            DOPB         : out std_logic_vector(15 downto 0));
    end component;
    
    component  BRAM_S144_S144 
       port (ADDRA  : in std_logic_vector (8 downto 0);
            ADDRB  : in std_logic_vector (8 downto 0);         
            DIA    : in std_logic_vector (127 downto 0);
            DIPA : in std_logic_vector (15 downto 0);
            DIB    : in std_logic_vector (127 downto 0);
            DIPB : in std_logic_vector (15 downto 0);
            WEA    : in std_logic;
            WEB    : in std_logic;         
            CLKA   : in std_logic;
            CLKB   : in std_logic;
            SSRA : in std_logic;
            SSRB : in std_logic;         
            ENA    : in std_logic;
            ENB    : in std_logic;
            DOA    : out std_logic_vector (127 downto 0);
            DOPA         : out std_logic_vector(15 downto 0);
            DOB    : out std_logic_vector (127 downto 0);
            DOPB         : out std_logic_vector(15 downto 0));
    end component;
  
end BRAM_fifo_pkg;
