---------------------------------------------------------------------------
--                                                                       
--  Module      : DRAM_fifo.vhd        
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--    
--  Project     : Parameterizable LocalLink FIFO
--
--  Description : Asynchronous FIFO implemented in Distributed RAM  
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
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_bit.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.fifo_u.all;
use work.DRAM_fifo_pkg.all;
 
entity DRAM_fifo is
generic (
    DRAM_DEPTH      : integer := 16;    -- FIFO depth, default is 16,
                                        -- allowable values are 16, 32, 
                                        -- 64, 128.
    WR_DWIDTH       : integer := 32;    -- FIFO write data width, 
                                        -- allowable values are 8, 16, 
                                        -- 32, 64, 128.
    RD_DWIDTH       : integer := 32;    -- FIFO read data width, 
                                        -- allowable values are 8, 16,
                                        -- 32, 64, 128.
    WR_REM_WIDTH    : integer := 2;     -- log2(WR_DWIDTH/8)
    RD_REM_WIDTH    : integer := 2;     -- log2(RD_DWIDTH/8)
    USE_LENGTH      : boolean := true;
                                                        
    glbtm           : time := 1 ns      -- Assignment delay for simulation
);
port (
    -- Reset
    FIFO_GSR_IN         : in std_logic;
         
    -- Clocks
    WRITE_CLOCK_IN      : in std_logic;
    READ_CLOCK_IN       : in std_logic;
         
    -- Sink Interface: standard signals for reading data from a FIFO
    READ_DATA_OUT       : out std_logic_vector(RD_DWIDTH-1 downto 0);
    READ_REM_OUT        : out std_logic_vector(RD_REM_WIDTH-1 downto 0);
    READ_SOF_OUT_N      : out std_logic;
    READ_EOF_OUT_N      : out std_logic;
    DATA_VALID_OUT      : out std_logic;
    READ_ENABLE_IN      : in std_logic;
         
    -- Source Interface: standard signals for writing data to a FIFO
    WRITE_DATA_IN       : in std_logic_vector(WR_DWIDTH-1 downto 0);
    WRITE_REM_IN        : in std_logic_vector(WR_REM_WIDTH-1 downto 0);
    WRITE_SOF_IN_N      : in std_logic;
    WRITE_EOF_IN_N      : in std_logic;
    WRITE_ENABLE_IN     : in std_logic;
        
    -- FIFO status signals
    FIFOSTATUS_OUT      : out std_logic_vector(3 downto 0);
    FULL_OUT            : out std_logic;
    EMPTY_OUT           : out std_logic;
    
        
    -- Length Control 
    LEN_OUT             : out std_logic_vector(15 downto 0);
    LEN_RDY_OUT         : out std_logic;
    LEN_ERR_OUT         : out std_logic); 
end DRAM_fifo;

architecture DRAM_fifo_hdl of DRAM_fifo is

    -- Constants Related to FIFO Width parameters for Data
    constant MEM_IDX : integer := SQUARE2(DRAM_DEPTH);
    constant RD_ADDR_WIDTH : integer := GET_WIDTH(MEM_IDX,RD_DWIDTH,WR_DWIDTH,1,0);
    constant WR_ADDR_WIDTH : integer := GET_WIDTH(MEM_IDX,RD_DWIDTH,WR_DWIDTH,1,1);
    constant RD_ADDR_MINOR_WIDTH : integer := GET_WIDTH(MEM_IDX, RD_DWIDTH, WR_DWIDTH, 2, 0);
    constant WR_ADDR_MINOR_WIDTH : integer := GET_WIDTH(MEM_IDX, RD_DWIDTH, WR_DWIDTH, 2, 1);
    constant MAX_WIDTH: integer := GET_MAX_WIDTH(RD_DWIDTH, WR_DWIDTH);
    constant WRDW_div_RDDW: integer := GET_WRDW_div_RDDW(RD_DWIDTH, WR_DWIDTH);

    --Constants Related to FIFO Width parameters for Control
    constant CTRL_WIDTH: integer := GET_CTRL_WIDTH(RD_REM_WIDTH, WR_REM_WIDTH, RD_DWIDTH, WR_DWIDTH);
    constant REM_SEL_HIGH_VALUE : integer := GET_HIGH_VALUE(RD_REM_WIDTH,WR_REM_WIDTH);  
    type rd_data_vec_type is array(0 to 2**RD_ADDR_MINOR_WIDTH-1) of std_logic_vector(RD_DWIDTH-1 downto 0);
    type rd_rem_vec_type is array(0 to 2**RD_ADDR_MINOR_WIDTH-1) of std_logic_vector(RD_REM_WIDTH-1 downto 0);
    constant RD_MINOR_HIGH : integer := POWER2(RD_ADDR_MINOR_WIDTH);
    constant REM_SEL_HIGH1 : integer := POWER2(REM_SEL_HIGH_VALUE);
    constant WR_MINOR_HIGH : integer := POWER2(WR_ADDR_MINOR_WIDTH);
    constant LEN_IFACE_SIZE: integer := 16;         -- Length count is a std_logic_vec
                                        -- of 16 bits by default.       
                                        -- User may change size. 

    constant LEN_COUNT_SIZE: integer := 14;

    -- length control constants
    constant BYTE_NUM_PER_WORD: integer := WR_DWIDTH/8;

    signal rd_clk:              std_logic;
    signal wr_clk:              std_logic;
    signal rd_en:               std_logic;
    signal wr_en:               std_logic;
    signal fifo_gsr:            std_logic;
    signal rd_data:             std_logic_vector(RD_DWIDTH-1 downto 0);
    signal wr_data:             std_logic_vector(WR_DWIDTH-1 downto 0);
    -- Control RAM signals --
    signal rd_rem:              std_logic_vector(RD_REM_WIDTH-1 downto 0);
    signal wr_rem:              std_logic_vector(WR_REM_WIDTH-1 downto 0);
    signal wr_sof_n:            std_logic;
    signal wr_eof_n:            std_logic;
    signal wr_sof_n_p:          std_logic;
    signal wr_eof_n_p:          std_logic;
    signal rd_sof_n:            std_logic;
    signal rd_eof_n:            std_logic;
    signal ctrl_wr_buf:         std_logic_vector(CTRL_WIDTH-1 downto 0);
    -------------------------
    signal full:                std_logic;
    signal empty:               std_logic;
    signal rd_addr:             std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal rd_addr_minor:       std_logic_vector(RD_ADDR_MINOR_WIDTH-1 downto 0);
    signal read_addrgray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal read_nextgray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal read_lastgray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal wr_addr:             std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal wr_addr_i:           std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal wr_addr_minor:       std_logic_vector(WR_ADDR_MINOR_WIDTH-1 downto 0);
    signal wr_addr_minor_p:     std_logic_vector(WR_ADDR_MINOR_WIDTH-1 downto 0);
    signal wr_addrgray:         std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal wr_addrgray_i:       std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal write_nextgray:      std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal write_nextgray_i:    std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal fifostatus:          std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal rd_allow:            std_logic;
    signal rd_allow_minor:      std_logic;
    signal wr_allow:            std_logic;
    signal wr_allow_i:          std_logic;
    signal wr_allow_p:          std_logic;
    signal wr_allow_minor:      std_logic;
    signal wr_allow_minor_p:    std_logic;
    signal wr_allow_flag:       std_logic;
    signal full_allow:          std_logic;
    signal empty_allow:         std_logic;
    signal emptyg:              std_logic;
    signal fullg:               std_logic;
    signal ecomp:               std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal fcomp:               std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal emuxcyo:             std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal fmuxcyo:             std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal read_truegray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal rag_writesync:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal ra_writesync:        std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal wr_addrr:            std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal gnd:                 std_logic;
    signal pwr:                 std_logic;
    signal data_valid:          std_logic;
    --  Temp signals  --
    signal rd_temp:             std_logic_vector(MAX_WIDTH-1 downto 0);
    signal rd_buf:              std_logic_vector(MAX_WIDTH-1 downto 0);
    signal rd_data_p:           rd_data_vec_type;
    signal wr_buf:              std_logic_vector(MAX_WIDTH-1 downto 0);
    signal min_addr1:           integer := 0;
    signal rem_sel1 :           integer := 0;
    signal rem_sel2:            integer := 0;
    
    -- Length Control FIFO --
    signal wr_len:              std_logic_vector(LEN_IFACE_SIZE downto 0);
    signal wr_len_r:            std_logic_vector(LEN_IFACE_SIZE downto 0);
    signal wr_len_p:            std_logic_vector(LEN_IFACE_SIZE downto 0);
    signal rd_len:              std_logic_vector(LEN_IFACE_SIZE downto 0);
    signal rd_len_temp:         std_logic_vector(LEN_IFACE_SIZE downto 0);
    signal len_byte_cnt:        std_logic_vector(LEN_COUNT_SIZE+3 downto 0); 
    signal len_byte_cnt_plus_rem: std_logic_vector(LEN_COUNT_SIZE+3 downto 0);
    signal len_word_cnt:        std_logic_vector(LEN_COUNT_SIZE-1 downto 0);
    signal len_wr_allow:        std_logic;
    signal len_wr_allow_r:      std_logic;
    signal len_wr_allow_p:      std_logic;
    signal len_rd_allow:        std_logic;
    signal len_wr_addr:         std_logic_vector(WR_ADDR_WIDTH-1 downto 0);
    signal len_rd_addr:         std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
    signal rd_len_rdy:          std_logic;
    signal wr_rem_plus_one:     std_logic_vector(WR_REM_WIDTH downto 0);

    signal len_byte_cnt_plus_rem_with_carry : std_logic_vector(LEN_COUNT_SIZE+4 downto 0);
    signal total_len_byte_cnt_with_carry : std_logic_vector(LEN_COUNT_SIZE+4 downto 0);
    signal len_word_cnt_with_carry : std_logic_vector(LEN_COUNT_SIZE downto 0);
    signal len_byte_cnt_with_carry: std_logic_vector(LEN_COUNT_SIZE+4 downto 0); 
    signal carry1, carry2, carry3, carry4 : std_logic;
    signal len_counter_overflow : std_logic;


    signal inframe:             std_logic;
    signal inframe_i:           std_logic;

    component MUXCY_L
    port (
        DI:  in std_logic;
        CI:  in std_logic;
        S:   in std_logic;
        LO: out std_logic);
    end component;
 
 
begin
    rd_clk <= READ_CLOCK_IN;
    wr_clk <= WRITE_CLOCK_IN;
    fifo_gsr <= FIFO_GSR_IN;
    wr_en <= WRITE_ENABLE_IN;                    
    wr_data <= revByteOrder(WRITE_DATA_IN);    
    wr_rem <= WRITE_REM_IN;
    wr_sof_n <= WRITE_SOF_IN_N;
    wr_eof_n <= WRITE_EOF_IN_N;  
    rd_en <= READ_ENABLE_IN;      
    
    READ_DATA_OUT <= revByteOrder(rd_data);
    READ_REM_OUT <= rd_rem;
    READ_SOF_OUT_N <= rd_sof_n;
    READ_EOF_OUT_N <= rd_eof_n;
    
    EMPTY_OUT <= empty;
    FULL_OUT <= full;
    FIFOSTATUS_OUT <= fifostatus(WR_ADDR_WIDTH-1 downto WR_ADDR_WIDTH-4);
    DATA_VALID_OUT <= data_valid;
   
    min_addr1 <= slv2int(rd_addr_minor);
  
    gnd <= '0';
    pwr <= '1';

-------------------------------------------------------------------------------
------------------------------INFRAME signal generation------------------------
--  This signal is used as a flag to indicate whether the  incoming data are --
--  part of a frame.  Since LL_FIFO is a packet FIFO so it will only store   --
--  packets, not random data without frame delimiter. If the data is not     --
--  part   of the frame, it will be dropped. The inframe_i signal will be    --
--  assert the cycle after the sof_n asserts. If the frame is only a cycle   --
--  long then inframe_i signal won't be asserted for that particular frame to--
--  prevent misleading information. However, the inframe signal will include --
--  wr_sof_n to give the accurate status of the frame, and which will be used--
--  for wr_allow.                                                            --
-------------------------------------------------------------------------------
    inframe_i_proc: process (wr_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            inframe_i <= '0';
        elsif (wr_clk'EVENT and wr_clk = '1') then
            if WR_DWIDTH >= RD_DWIDTH then
                if inframe_i = '0' then
                    inframe_i <= wr_allow and not wr_sof_n and wr_eof_n after glbtm;
                elsif (inframe_i = '1' and wr_allow = '1' and wr_eof_n = '0') then
                    inframe_i <= '0' after glbtm;
                end if;
            else
                 if inframe_i = '0' then
                    inframe_i <= wr_allow_minor and not wr_sof_n and wr_eof_n after glbtm;
                elsif (inframe_i = '1' and wr_allow_minor = '1' and wr_eof_n = '0') then
                    inframe_i <= '0' after glbtm;
                end if;
            end if;
        end if;
    end process inframe_i_proc;  
    
    inframe <= not wr_sof_n or inframe_i;

----------------------------------------------------------------
------------------ALLOW signal generation-----------------------
--  Allow flags determine whether FifO control logic can      --
--  operate.  If rd_en is driven high, and the FifO is        --
--  not empty, then Reads are allowed.  Similarly, if the     --
--  wr_en signal is high, and the FifO is not FULL_OUT,       --
--  then Writes are allowed.                                  --
--                                                            --
----------------------------------------------------------------


gen1: if RD_DWIDTH < WR_DWIDTH generate
begin
    rd_allow_minor <= (rd_en and not empty);
    rd_allow <= rd_allow_minor when allOnes(rd_addr_minor) else '0';
    wr_allow <= (wr_en and not full) and inframe;
    full_allow <= (full or wr_en);
    empty_allow <= rd_en or empty when allOnes(rd_addr_minor) else empty ;
 
end generate gen1;
   

gen2: if RD_DWIDTH > WR_DWIDTH generate
    rd_allow <= (rd_en and not empty);
    empty_allow <= (empty or rd_en);
    wr_allow_minor <= (wr_en and not full) and inframe;
    wr_allow_i <= wr_allow_minor and (boolean_to_std_logic(allOnes(wr_addr_minor)) or not wr_eof_n);
    full_allow <= wr_allow or full;
    
    
-------------------------------------------------------------------------------
-----------------------------WR_ALLOW GENERATION-------------------------------
--  The wr_allow_flag signal is use to assert wr_allow when fifo is not full --
--  when wr_allow was high during fifo was full.  When the fifo is           -- 
--  full, we must stop writing into the FIFO, so wr_allow must deasserts     -- 
--  immediately so that the address won't increment until the fifo is not    --   
--  full. If we don't  have the wr_allow_flag signal, the write address will -- 
--  not increment when fifo is not full anymore but will when new data is    --
--  coming in, which cause data drop.                                        --
-------------------------------------------------------------------------------
    
    
    proc: process (wr_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            wr_allow_p <= '0';
            wr_allow_flag <= '0';
            wr_sof_n_p <= '0';
            wr_eof_n_p <= '0';
            wr_allow_minor_p <= '0';
        elsif (wr_clk'EVENT and wr_clk = '1') then
            wr_allow_p <= wr_allow_i after glbtm;
            wr_sof_n_p <= wr_sof_n after glbtm;
            wr_eof_n_p <= wr_eof_n after glbtm;
            wr_allow_minor_p <= wr_allow_minor after glbtm;

            if full = '1' then
                if wr_allow_p = '1' then
                    wr_allow_flag <= wr_allow_p after glbtm;
                else 
                    wr_allow_flag <= wr_allow_flag after glbtm;
                end if;
            else 
                wr_allow_flag <= '0' after glbtm;
            end if;
        end if;
    end process proc;  
    
    wr_allow <= (wr_allow_p or wr_allow_flag) and not full;
    
end generate gen2;


gen3: if RD_DWIDTH = WR_DWIDTH generate
    wr_allow <= (wr_en and not full) and inframe;
    rd_allow <= (rd_en and not empty);
    empty_allow <= (empty or rd_en);  
    full_allow <= wr_en or full;   
   
    
end generate gen3;

-------------------------------------------------------------------------------
--_____________________________The Data Valid Signal___________________________
-- The data valid signal is asserted when the data coming out of the FIFO is   
-- data that was put there by the source, and not just garbage from the FIFO's 
-- memory. Moreover, when sink and source datawidths are different, the data   
-- valid signal must tell what part of data is valid and what is not depending 
-- on the frame delimiter.  Therefore, the src_rdy_n signal greatly depend on  
-- this.                                                                       
-------------------------------------------------------------------------------
data_valid_gen1: if RD_DWIDTH < WR_DWIDTH generate
    data_valid_proc1: process(rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            data_valid <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
            if (rd_allow_minor = '1') then
                if (min_addr1 /= 0 and rd_eof_n = '0') then --RD_MINOR_HIGH-1 
                    data_valid <= '0' after glbtm;
                else
                    if data_valid = '0' and min_addr1 /= 0 then
                        data_valid <= '0' after glbtm;
                    else 
                        data_valid <= '1' after glbtm;
                    end if;
                end if;
            --should extend data_valid when user halts read, do this when FIFO still contains data
            elsif data_valid = '1' and (empty = '0' or rd_eof_n = '0') then  
                  data_valid <= '1' after glbtm;                          
            else
                  data_valid <= '0' after glbtm;
            end if;
        end if;
    end process data_valid_proc1;
end generate data_valid_gen1;

data_valid_gen2: if RD_DWIDTH > WR_DWIDTH generate
    data_valid_proc2: process(rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            data_valid <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
           if rd_en = '0' and data_valid = '1' then -- should extend data_valid when user halts read,
                                                    -- so data won't get lost.
            data_valid <= '1' after glbtm;
           else
            data_valid <= rd_allow after glbtm;
           end if;
        end if;
    end process data_valid_proc2;
end generate data_valid_gen2;

data_valid_gen3: if RD_DWIDTH = WR_DWIDTH generate
    data_valid_proc3: process(rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            data_valid <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
          if rd_en = '0' and data_valid = '1' then
            data_valid <= '1' after glbtm;
          else
            data_valid <= rd_allow after glbtm;
          end if;
           
        end if;
    end process data_valid_proc3;     
end generate data_valid_gen3;




 DRAM_macro_inst: DRAM_macro
   generic map (
        DRAM_DEPTH   => DRAM_DEPTH,
                                                  -- allowable values are 16, 32, 
                                                  -- 64, 128.
   
        WR_DWIDTH    => WR_DWIDTH,
                                                  --Allowed: 8, 16, 32, 64
        RD_DWIDTH    => RD_DWIDTH,
                                                  --Allowed: 8, 16, 32, 64
        WR_REM_WIDTH => WR_REM_WIDTH,
        RD_REM_WIDTH => RD_REM_WIDTH,
        
        RD_ADDR_MINOR_WIDTH => RD_ADDR_MINOR_WIDTH,
        RD_ADDR_WIDTH       => RD_ADDR_WIDTH,
        
        WR_ADDR_MINOR_WIDTH => WR_ADDR_MINOR_WIDTH,
        WR_ADDR_WIDTH       => WR_ADDR_WIDTH,

        CTRL_WIDTH   => CTRL_WIDTH,
        
        glbtm               => glbtm )
        
   port map(
         -- Reset
         fifo_gsr           => fifo_gsr,
                                
         -- clocks             -- clocks
         wr_clk             => wr_clk,        
         rd_clk             => rd_clk,        
                                        
         rd_allow           => rd_allow,      
         rd_allow_minor     => rd_allow_minor,
         rd_addr_minor      => rd_addr_minor, 
         rd_addr            => rd_addr,       
         rd_data            => rd_data,       
         rd_rem             => rd_rem,        
         rd_sof_n           => rd_sof_n,      
         rd_eof_n           => rd_eof_n,      
         
                                        
         wr_allow           => wr_allow,      
         wr_allow_minor     => wr_allow_minor,
         wr_allow_minor_p   => wr_allow_minor_p,
         wr_addr            => wr_addr,       
         wr_addr_minor      => wr_addr_minor, 
         wr_data            => wr_data,       
         wr_rem             => wr_rem,        
         wr_sof_n           => wr_sof_n,      
         wr_eof_n           => wr_eof_n,
         wr_sof_n_p         => wr_sof_n_p,      
         wr_eof_n_p         => wr_eof_n_p,
         ctrl_wr_buf        => ctrl_wr_buf  );
         
   

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--  Length Control FIFO                                                 --
--------------------------------------------------------------------------
-------------------------------------------------------------------------------
----------------------Distributed SelectRAM port mapping-----------------------  
--  It uses up to 512 deep RAM, in which 64 and lower are horizontally       --
--  cascaded primitives and 128 and up are macro of 64 deep RAM.             --
-------------------------------------------------------------------------------

DRAMgen1: if DRAM_DEPTH = 16 generate
begin

    -- Length Control RAM --
    len_gen1: if USE_LENGTH = true generate     
        len_DRAM_gen1: for i in 0 to LEN_IFACE_SIZE generate
            D_RAM1: RAM16X1D port map (
                D       =>      wr_len(i),
                WE      =>      pwr,
                WCLK    =>      wr_clk,
                A0      =>      len_wr_addr(0),
                A1      =>      len_wr_addr(1),
                A2      =>      len_wr_addr(2),
                A3      =>      len_wr_addr(3),
                DPRA0   =>      len_rd_addr(0),
                DPRA1   =>      len_rd_addr(1),
                DPRA2   =>      len_rd_addr(2),
                DPRA3   =>      len_rd_addr(3),     
                DPO     =>      rd_len(i),
                SPO     =>      rd_len_temp(i));
        end generate len_DRAM_gen1;  
    end generate len_gen1;
end generate DRAMgen1;

DRAMgen2: if DRAM_DEPTH = 32 generate
begin
         
    -- Length Control RAM --
    len_gen11: if USE_LENGTH = true generate    

        len_DRAM_gen2: for i in 0 to LEN_IFACE_SIZE generate
            D_RAM1: RAM32X1D port map (
                D       =>      wr_len(i),
                WE      =>      pwr,
                WCLK    =>      wr_clk,
                A0      =>      len_wr_addr(0),
                A1      =>      len_wr_addr(1),
                A2      =>      len_wr_addr(2),
                A3      =>      len_wr_addr(3),
                A4      =>      len_wr_addr(4),
                DPRA0   =>      len_rd_addr(0),
                DPRA1   =>      len_rd_addr(1),
                DPRA2   =>      len_rd_addr(2),
                DPRA3   =>      len_rd_addr(3),     
                DPRA4   =>      len_rd_addr(4),     
                DPO     =>      rd_len(i),
                SPO     =>      rd_len_temp(i));
        end generate len_DRAM_gen2;    
    end generate len_gen11;
end generate DRAMgen2;

DRAMgen3: if DRAM_DEPTH = 64 generate
begin

    -- Length Control RAM --
    len_gen2: if USE_LENGTH = true generate     
        len_DRAM_gen3: for i in 0 to LEN_IFACE_SIZE generate
            D_RAM1: RAM64X1D port map (
                D       =>      wr_len(i),
                WE      =>      pwr,
                WCLK    =>      wr_clk,
                A0      =>      len_wr_addr(0),
                A1      =>      len_wr_addr(1),
                A2      =>      len_wr_addr(2),
                A3      =>      len_wr_addr(3),
                A4      =>      len_wr_addr(4),
                A5      =>      len_wr_addr(5),
                DPRA0   =>      len_rd_addr(0),
                DPRA1   =>      len_rd_addr(1),
                DPRA2   =>      len_rd_addr(2),
                DPRA3   =>      len_rd_addr(3),     
                DPRA4   =>      len_rd_addr(4),     
                DPRA5   =>      len_rd_addr(5),
                DPO     =>      rd_len(i),
                SPO     =>      rd_len_temp(i));
        end generate len_DRAM_gen3;     
    end generate len_gen2;
end generate DRAMgen3;

DRAMgen4: if DRAM_DEPTH = 128 generate
begin

    -- Length Control RAM --
    len_gen4: if USE_LENGTH = true generate     
        len_DRAM_gen4: for i in 0 to LEN_IFACE_SIZE generate
            D_RAM1: RAM_64nX1 
            generic map(2, 7)
            port map (
                DI      =>      wr_len(i),
                WEn     =>      pwr,
                WCLK    =>      wr_clk,
                Ad      =>      len_wr_addr(6 downto 0),
                DRA     =>      len_rd_addr(6 downto 0),
                DO      =>      rd_len(i),
                SO      =>      open);
        end generate len_DRAM_gen4;  
    end generate len_gen4;
end generate DRAMgen4;

DRAMgen5: if DRAM_DEPTH = 256 generate
begin
    -- Length Control RAM --
    len_gen5: if USE_LENGTH = true generate     
        len_DRAM_gen5: for i in 0 to LEN_IFACE_SIZE generate
            D_RAM1: RAM_64nX1 
            generic map(4, 8)
            port map (
                DI      =>      wr_len(i),
                WEn     =>      pwr,
                WCLK    =>      wr_clk,
                Ad      =>      len_wr_addr(7 downto 0),
                DRA     =>      len_rd_addr(7 downto 0),
                DO      =>      rd_len(i));
        end generate len_DRAM_gen5;    
    end generate len_gen5;
end generate DRAMgen5;

DRAMgen6: if DRAM_DEPTH = 512 generate
begin
    -- Length Control RAM --        
    len_gen6: if USE_LENGTH = true generate     
        len_DRAM_gen6: for i in 0 to LEN_IFACE_SIZE generate
            D_RAM1: RAM_64nX1 
            generic map(8, 9)
            port map (
                DI      =>      wr_len(i),
                WEn     =>      pwr,
                WCLK    =>      wr_clk,
                Ad      =>      len_wr_addr(8 downto 0),
                DRA     =>      len_rd_addr(8 downto 0),
                DO      =>      rd_len(i));
        end generate len_DRAM_gen6; 
    end generate len_gen6;
end generate DRAMgen6;


use_length_gen1: if USE_LENGTH = false generate 
    ---------------------------------------------------------------------------
    --  When the user does not want to use the Length FIFO, the output of    --
    --  the length count will always be zero and the len_rdy signal will     --
    --  always be asserted.                                                  --
    ---------------------------------------------------------------------------
    LEN_OUT <= (others => '0');
    LEN_RDY_OUT <= '0';  
    LEN_ERR_OUT <= '0';
end generate use_length_gen1;

use_length_gen2 : if USE_LENGTH = true generate

    ---------------------------------------------------------------------------
    --  Calculating the number of bytes being written into the FIFO (wr_len) --
    --  the length counter (len_count) is incremented every cycle when a     --
    --  valid data is received and when it's not the end of the frame, that  --
    --  is, wr_eof_n is not equal to '0'.  However, since the length count   --
    --  is always a cycle late and we are writing the length into the length --
    --  FIFO at the same cycle as when wr_eof_n asserts.  So the             --
    --  combinatorial logic that finalize the counting of byte length will   --
    --  add one more word to the calculation to make up for it.              --
    ---------------------------------------------------------------------------
    
    LEN_A_GEN: if WR_DWIDTH >= RD_DWIDTH generate
     
        len_wr_allow_r <= wr_allow and (not wr_eof_n);
        len_rd_allow <= rd_len_rdy;

        -- calculate data bytes in remainder
        wr_rem_plus_one <= '0' & wr_rem + '1';  

        -- add data bytes in remainder into length byte count
        len_byte_cnt_plus_rem_with_carry <= '0' & len_byte_cnt + wr_rem_plus_one;
        len_byte_cnt_plus_rem <= len_byte_cnt_plus_rem_with_carry(LEN_COUNT_SIZE+3 downto 0);
        carry2      <= len_byte_cnt_plus_rem_with_carry(LEN_COUNT_SIZE+4);
        
        -- calculate total length byte count by adding one more data beats at certain condition
        -- to compensate for SOF data bytes,
        total_len_byte_cnt_with_carry <= '0' & len_byte_cnt_plus_rem when wr_sof_n = '0' and len_wr_allow_r = '1' else 
                     '0' & len_byte_cnt_plus_rem + conv_std_logic_vector(BYTE_NUM_PER_WORD, 5) 
                     when wr_sof_n = '1' and len_wr_allow_r = '1' else
                     (others => '0');

        -- Prepare the data to write into Length FIFO
        wr_len_r(LEN_IFACE_SIZE) <= not wr_eof_n when wr_allow = '1' else '0'; 
        wr_len_r(LEN_IFACE_SIZE-1 downto 0) <= total_len_byte_cnt_with_carry(LEN_IFACE_SIZE-1 downto 0);
        carry1 <= not boolean_to_std_logic(allZeroes(total_len_byte_cnt_with_carry(LEN_COUNT_SIZE+4 downto LEN_IFACE_SIZE)));
        
    end generate LEN_A_GEN;
       
    LEN_B_GEN: if WR_DWIDTH < RD_DWIDTH generate
    
        len_wr_allow_r <= wr_allow_minor_p and (not wr_eof_n_p);
        len_rd_allow <= rd_len_rdy;
        
        -- calculate data bytes in remainder
        wr_rem_gen0: if WR_DWIDTH /= 8 generate
        wr_rem_plus_one <= '0' & ctrl_wr_buf(WR_REM_WIDTH-1 downto 0) + '1';  
        end generate;

        wr_rem_gen1: if WR_DWIDTH = 8 generate
        wr_rem_plus_one <= conv_std_logic_vector(1, WR_REM_WIDTH+1);  
        end generate;

        -- add data bytes in remainder into length byte count
        len_byte_cnt_plus_rem_with_carry <= '0' & len_byte_cnt + wr_rem_plus_one;
        len_byte_cnt_plus_rem <= len_byte_cnt_plus_rem_with_carry(LEN_COUNT_SIZE+3 downto 0);
        carry2      <= len_byte_cnt_plus_rem_with_carry(LEN_COUNT_SIZE+4);
        
        -- calculate total length byte count by adding one more data beats at certain condition
        -- to compensate for SOF data bytes,
        total_len_byte_cnt_with_carry <= '0' & len_byte_cnt_plus_rem when wr_sof_n_p = '0' and len_wr_allow_r = '1' 
                      else   '0' & len_byte_cnt_plus_rem + conv_std_logic_vector(BYTE_NUM_PER_WORD, 5) 
                     when wr_sof_n_p = '1' and len_wr_allow_r = '1' else
                     (others => '0');


        -- Prepare the data to write into Length FIFO
        wr_len_r(LEN_IFACE_SIZE)<=not wr_eof_n_p when wr_allow_minor_p='1' else '0'; 
        wr_len_r(LEN_IFACE_SIZE-1 downto 0) <= total_len_byte_cnt_with_carry(LEN_IFACE_SIZE-1 downto 0);
        carry1 <= not boolean_to_std_logic(allZeroes(total_len_byte_cnt_with_carry(LEN_COUNT_SIZE+4 downto LEN_IFACE_SIZE)));    
        
    end generate LEN_B_GEN;
    
    process (rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            LEN_OUT <= (others => '0');
            LEN_RDY_OUT <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
            LEN_OUT <= rd_len(LEN_IFACE_SIZE-1 downto 0) after glbtm;
            LEN_RDY_OUT <= rd_len_rdy after glbtm;
        end if;
    end process;
    LEN_ERR_OUT <= '0';

    rd_len_rdy <= rd_len(LEN_IFACE_SIZE);
    ---------------------------------------------------------------------------
    --  Pipeline the wr_len and wr_len_rdy, and detect counter overflow
    ---------------------------------------------------------------------------
    len_pipeline_proc: process(wr_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            len_counter_overflow <= '0' after glbtm;
            len_wr_allow <= '0' after glbtm;
            wr_len       <= (others => '0') after glbtm;
        elsif (wr_clk'EVENT and wr_clk = '1') then
            len_wr_allow <= len_wr_allow_p after glbtm;
            
            wr_len(LEN_IFACE_SIZE-1 downto 0) <= 
                        bit_duplicate(len_counter_overflow ,LEN_IFACE_SIZE) or 
                        wr_len_p(LEN_IFACE_SIZE-1 downto 0) after glbtm;
                        
            wr_len(LEN_IFACE_SIZE) <= wr_len_p(LEN_IFACE_SIZE) after glbtm; 
         
            if (WR_DWIDTH >= RD_DWIDTH) then
                if (wr_sof_n = '0') then 
                    len_counter_overflow <= '0' after glbtm;
                elsif (carry1 = '1' or carry2 = '1' or carry3 = '1' or carry4 = '1') then
                    len_counter_overflow <= '1' after glbtm;
                end if;
            else
                if (wr_sof_n = '0') then 
                    len_counter_overflow <= '0' after glbtm;
                elsif (carry1 = '1' or carry2 = '1' or carry3 = '1' or carry4 = '1') then
                    len_counter_overflow <= '1' after glbtm;
                end if;
            end if;
        end if;    
    end process;   
    
    ---------------------------------------------------------------------------
    --  Need to pipeline the stage so it can align with the counter overflow --
    --  signal.                                                              --
    ---------------------------------------------------------------------------
    wr_len_pipline_proc: process(wr_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            wr_len_p <= (others => '0');
            len_wr_allow_p <= '0';
        elsif (wr_clk'EVENT and wr_clk = '1') then
            wr_len_p <= wr_len_r after glbtm;
            len_wr_allow_p <= len_wr_allow_r after glbtm;
        end if;
    end process wr_len_pipline_proc;
            

    ---------------------------------------------------------------------------    
    len_word_cnt <= len_word_cnt_with_carry(LEN_COUNT_SIZE-1 downto 0);
    carry4      <= len_word_cnt_with_carry(LEN_COUNT_SIZE);
    
    len_byte_cnt <= len_byte_cnt_with_carry(LEN_COUNT_SIZE+3 downto 0); 
    carry3      <= len_byte_cnt_with_carry(LEN_COUNT_SIZE+4); 
    
    -- only counts data beats between SOF/EOF
    len_counter_proc: process(wr_clk, fifo_gsr) 
    begin
        if (fifo_gsr = '1') then
            len_word_cnt_with_carry <= (others => '0');  -- unit is words
            len_byte_cnt_with_carry <= (others => '0');
        elsif (wr_clk'EVENT and wr_clk = '1') then

            if (WR_DWIDTH >= RD_DWIDTH) then
                if (wr_allow = '1') then
                    if (wr_sof_n = '0' or wr_eof_n = '0') then
                        len_word_cnt_with_carry <= (others => '0') after glbtm;
                        len_byte_cnt_with_carry <= (others => '0') after glbtm;
                    else
                        len_word_cnt_with_carry <= '0' & len_word_cnt + '1' after glbtm;
                        len_byte_cnt_with_carry <= conv_std_logic_vector
                            (slv2int(len_word_cnt)*BYTE_NUM_PER_WORD, LEN_COUNT_SIZE + 5 ) + 
                            conv_std_logic_vector(BYTE_NUM_PER_WORD, 5) 
                            after glbtm;  

                    end if;
                end if;
            elsif (WR_DWIDTH < RD_DWIDTH) then
                if (wr_allow_minor_p = '1') then
                    if (wr_sof_n_p = '0' or wr_eof_n_p = '0') then
                        len_word_cnt_with_carry <= (others => '0') after glbtm;
                        len_byte_cnt_with_carry <= (others => '0') after glbtm;
                    else
                        len_word_cnt_with_carry <= '0' & len_word_cnt + '1' after glbtm;
                        len_byte_cnt_with_carry <= conv_std_logic_vector
                            (slv2int(len_word_cnt)* BYTE_NUM_PER_WORD, LEN_COUNT_SIZE + 5 ) + 
                            conv_std_logic_vector(BYTE_NUM_PER_WORD, 5) 
                            after glbtm;                 
                    end if;
                end if;
            end if;
        end if;
    end process len_counter_proc;
    ---------------------------------------------------------------------------

    inc_len_wr_proc: process (wr_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            len_wr_addr <= (others => '0');
        elsif (wr_clk'EVENT and wr_clk = '1') then
            if (len_wr_allow = '1') then
                len_wr_addr <= len_wr_addr + '1' after glbtm;
            end if;
        end if;
    end process inc_len_wr_proc;

    inc_len_rd_addr_proc: process (rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            len_rd_addr <= (others => '0');
        elsif (rd_clk'EVENT and rd_clk = '1') then
            if (len_rd_allow = '1') then
                len_rd_addr <= len_rd_addr + '1' after glbtm;
            end if;
        end if;
    end process inc_len_rd_addr_proc;
end generate use_length_gen2;
--------------------------------------------------------------------------
empty_proc: process (rd_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        empty <= '1';
    elsif (rd_clk'EVENT and rd_clk = '1') then
        if (empty_allow = '1') then
            empty <= emptyg after glbtm;
        end if;
    end if;
end  process empty_proc;


full_proc: process (wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        full <= '0';
    elsif (wr_clk'EVENT and wr_clk = '1') then
        if (full_allow = '1') then
            full <= fullg after glbtm;
        end if;
    end if; 
end process full_proc;
------------------------------------------------------------------------------------
inc_rd_addr_proc: process (rd_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        rd_addr <= (others => '0');
    elsif (rd_clk'EVENT and rd_clk = '1') then
        if (rd_allow = '1') then
            rd_addr <= rd_addr + '1' after glbtm;
        end if;
    end if;
end process inc_rd_addr_proc;

gray_conv_proc: process (rd_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then  
        read_nextgray(RD_ADDR_WIDTH-1) <= '1';
        read_nextgray(RD_ADDR_WIDTH-2 downto 0) <= (others => '0');
    elsif (rd_clk'EVENT and rd_clk = '1') then
        if (rd_allow = '1') then
            read_nextgray(RD_ADDR_WIDTH-1) <= rd_addr(RD_ADDR_WIDTH-1) after glbtm;
            for i in RD_ADDR_WIDTH-2 downto 0 loop
                read_nextgray(i) <= rd_addr(i+1) xor rd_addr(i) after glbtm;
            end loop;
        end if;
    end if;
end process gray_conv_proc;

pip_proc1: process (rd_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        read_addrgray(RD_ADDR_WIDTH-1) <= '1';
        read_addrgray(0) <= '1';
        read_addrgray(RD_ADDR_WIDTH-2 downto 1) <= (others => '0');
    elsif (rd_clk'EVENT and rd_clk = '1') then
        if (rd_allow = '1') then
            read_addrgray <= read_nextgray after glbtm;
        end if;
    end if;
end process pip_proc1;

pip_proc2: process (rd_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        read_lastgray(RD_ADDR_WIDTH-1) <= '1';
        read_lastgray(0) <= '1';
        read_lastgray(1) <= '1';
        read_lastgray(RD_ADDR_WIDTH-2 downto 2) <= (others => '0');
    elsif (rd_clk'EVENT and rd_clk = '1') then
        if (rd_allow = '1') then
            read_lastgray <= read_addrgray after glbtm;
        end if;
    end if;
end process pip_proc2;
-------------------------------------------------------------------------------
inc_wr_proc: process (wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        wr_addr <= (others => '0');
    elsif (wr_clk'EVENT and wr_clk = '1') then
        if (wr_allow = '1') then
            wr_addr <= wr_addr + '1' after glbtm;                
        end if;
    end if;
end process inc_wr_proc;



wr_nextgray_proc: process (wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        write_nextgray(WR_ADDR_WIDTH-1) <= '1';
        write_nextgray(WR_ADDR_WIDTH-2 downto 0) <= (others => '0');
    elsif (wr_clk'EVENT and wr_clk = '1') then
        if (wr_allow = '1') then
            write_nextgray(WR_ADDR_WIDTH-1) <= wr_addr(WR_ADDR_WIDTH-1) after glbtm;
            for i in WR_ADDR_WIDTH-2 downto 0 loop
                write_nextgray(i) <= wr_addr(i+1) xor wr_addr(i) after glbtm;
            end loop;
        end if;
    end if;
end process wr_nextgray_proc;

wr_addrgray_proc: process (wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        wr_addrgray(WR_ADDR_WIDTH-1) <= '1';
        wr_addrgray(0) <= '1';
        wr_addrgray(WR_ADDR_WIDTH-2 downto 1) <= (others => '0');
    elsif (wr_clk'EVENT and wr_clk = '1') then
        if (wr_allow = '1') then
            wr_addrgray <= write_nextgray after glbtm;
        end if;
    end if;
end process wr_addrgray_proc;
------------------------------------------------------------------------------
rd_minor_proc: process(rd_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        rd_addr_minor <= (others => '0');
    elsif (rd_clk'EVENT and rd_clk = '1') then
        if (WR_DWIDTH /= RD_DWIDTH) then
            if (rd_allow_minor = '1') then
                rd_addr_minor <= rd_addr_minor + '1' after glbtm;
            end if;
        end if;
    end if;
end process rd_minor_proc;

wr_minor_proc: process(wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        wr_addr_minor <= (others => '0');
    elsif (wr_clk'EVENT and wr_clk = '1') then
        if (WR_DWIDTH < RD_DWIDTH) then
--              if (wr_eof_n = '0') then 
--                 wr_addr_minor <= (others => '0') after glbtm;
--              elsif (wr_allow_minor = '1') then
--                wr_addr_minor <= wr_addr_minor + '1' after glbtm;
--              end if;
                 if (wr_allow_minor = '1') then
                   if (wr_eof_n = '0') then 
                      wr_addr_minor <= (others => '0') after glbtm;
                   else
                      wr_addr_minor <= wr_addr_minor + '1' after glbtm;
                   end if; 
                 end if;
        end if;
    end if;
end process wr_minor_proc;
------------------------------------------------------------------------------   

truegray_proc: process (rd_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        read_truegray <= (others => '0');
    elsif (rd_clk'EVENT and rd_clk = '1') then
        read_truegray(RD_ADDR_WIDTH-1) <= rd_addr(RD_ADDR_WIDTH-1);
        for i in RD_ADDR_WIDTH-2 downto 0 loop
            read_truegray(i) <= rd_addr(i+1) xor rd_addr(i) after glbtm;
        end loop;
    end if;
end process truegray_proc;

rag_wr_proc: process (wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        rag_writesync <= (others => '0');
    elsif (wr_clk'EVENT and wr_clk = '1') then
        rag_writesync <= read_truegray after glbtm;
    end if;
end process rag_wr_proc;
----------------------------------------------------------
--                                                      --
--  Gray to binary Conversion.                          --
--                                                      --
----------------------------------------------------------
ra_writesync <= gray_to_bin(rag_writesync);
----------------------------------------------------------

wr_addrr_proc: process (wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        wr_addrr <= (others => '0');
    elsif (wr_clk'EVENT and wr_clk = '1') then
        wr_addrr <= wr_addr after glbtm;
    end if;
end process wr_addrr_proc;
------------------------------------------------------------------------------------------------------
status_proc: process (wr_clk, fifo_gsr)
begin
    if (fifo_gsr = '1') then
        fifostatus <= (others => '0');
    elsif (wr_clk'EVENT and wr_clk = '1') then
        if (full = '0') then
            fifostatus <= (wr_addrr - ra_writesync) after glbtm;
        end if;
    end if;
end process status_proc;

--------------------------------------------------------------------------------------------------------
ecompgen: for i in 0 to WR_ADDR_WIDTH-1 generate
begin 
    ecomp(i) <= (not (wr_addrgray(i) xor read_addrgray(i)) and empty) or
                    (not (wr_addrgray(i) xor read_nextgray(i)) and not empty);
end generate ecompgen;

----------------------------------------------------------------------------------------------------------
emuxcy0: MUXCY_L port map (DI=>gnd,CI=>pwr,S=>ecomp(0),LO=>emuxcyo(0));
emuxcygen1: for i in 1 to WR_ADDR_WIDTH-2 generate
    emuxcyx: MUXCY_L port map (DI=>gnd,CI=>emuxcyo(i-1),S=>ecomp(i),LO=>emuxcyo(i));
end generate emuxcygen1;
emuxcylast: MUXCY_L port map (DI=>gnd,CI=>emuxcyo(WR_ADDR_WIDTH-2),S=>ecomp(WR_ADDR_WIDTH-1),LO=>emptyg);

----------------------------------------------------------------------------------------------------------
fcompgen: for j in 0 to WR_ADDR_WIDTH-1 generate
begin 
    fcomp(j) <= (not (read_lastgray(j) xor wr_addrgray(j)) and full) or
                (not (read_lastgray(j) xor write_nextgray(j)) and not full);
end generate fcompgen;

----------------------------------------------------------------------------------------------------
fmuxcy0: MUXCY_L port map (DI=>gnd,CI=>pwr, S=>fcomp(0),LO=>fmuxcyo(0));
fmuxcygen2: for i in 1 to WR_ADDR_WIDTH-2 generate
    fmuxcyx: MUXCY_L port map (DI=>gnd,CI=>fmuxcyo(i-1),S=>fcomp(i),LO=>fmuxcyo(i));
end generate fmuxcygen2;
fmuxcylast: MUXCY_L port map (DI=>gnd,CI=>fmuxcyo(WR_ADDR_WIDTH-2),S=>fcomp(WR_ADDR_WIDTH-1),LO=>fullg);

end DRAM_fifo_hdl;
