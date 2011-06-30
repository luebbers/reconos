-------------------------------------------------------------------------------
--                                                                       
--  Module      : BRAM_fifo.vhd        
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--    
--  Project     : Parameterizable LocalLink FIFO
--
--  Description : Asynchronous FIFO implemented in Block SelectRAM.  
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.fifo_u.all;
use work.BRAM_fifo_pkg.all;
 
entity BRAM_fifo is
   generic (
        BRAM_MACRO_NUM  :       integer := 1;     --Number of BRAM Blocks. 
                                                  --Allowed: 1, 2, 4, 8, 16
        WR_DWIDTH       :       integer := 32;    --FIFO write data width. 
                                                  --Allowed: 8, 16, 32, 64
        RD_DWIDTH       :       integer := 32;    --FIFO read data width.
                                                  --Allowed: 8, 16, 32, 64
        WR_REM_WIDTH    :       integer := 2;     --log2(WR_DWIDTH/8)
        RD_REM_WIDTH    :       integer := 2;     --log2(RD_DWIDTH/8)
        USE_LENGTH      :       boolean := true;

        glbtm           :       time := 1 ns
   );
   port (
         -- Reset
         fifo_gsr_in:           in std_logic;
         
         -- clocks
         write_clock_in:        in std_logic;
         read_clock_in:         in std_logic;
                  
         read_data_out:         out std_logic_vector(RD_DWIDTH-1 downto 0);
         read_rem_out:          out std_logic_vector(RD_REM_WIDTH-1 downto 0);
         read_sof_out_n:        out std_logic;
         read_eof_out_n:        out std_logic;
         read_enable_in:        in std_logic;
                  
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
          
         -- Length Control
         len_out:               out std_logic_vector(15 downto 0);
         len_rdy_out:           out std_logic;
         len_err_out:           out std_logic);
         
end BRAM_fifo;

architecture BRAM_fifo_hdl of BRAM_fifo is

constant MEM_IDX : integer := SQUARE2(BRAM_MACRO_NUM);
constant RD_ADDR_WIDTH : integer := GET_ADDR_MAJOR_WIDTH(
                                               RD_DWIDTH,WR_DWIDTH,0) +MEM_IDX;                                 
constant WR_ADDR_WIDTH : integer := GET_ADDR_MAJOR_WIDTH(
                                               RD_DWIDTH,WR_DWIDTH,1) +MEM_IDX;                                 
constant ADDR_MINOR_WIDTH : integer := GET_ADDR_MINOR_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);                                         
constant RD_ADDR_FULL_WIDTH : integer := GET_ADDR_FULL_B(RD_DWIDTH, 
                                               WR_DWIDTH, 0) + MEM_IDX;
constant WR_ADDR_FULL_WIDTH : integer := GET_ADDR_FULL_B(RD_DWIDTH, 
                                               WR_DWIDTH, 1) + MEM_IDX;
constant RD_REM_WIDTH_P : integer := GET_REM_WIDTH(RD_REM_WIDTH);
constant WR_REM_WIDTH_P : integer := GET_REM_WIDTH(WR_REM_WIDTH);
constant WR_PAR_WIDTH : integer := GET_PAR_WIDTH(WR_DWIDTH);
constant RD_PAR_WIDTH : integer := GET_PAR_WIDTH(RD_DWIDTH);
constant RD_MINOR_HIGH: integer := POWER2(ADDR_MINOR_WIDTH);
constant REM_SEL_HIGH_VALUE : integer := GET_HIGH_VALUE(
                                               RD_REM_WIDTH,WR_REM_WIDTH);  
constant REM_SEL_HIGH1 : integer := POWER2(REM_SEL_HIGH_VALUE);
constant WR_SOF_EOF_WIDTH : integer := GET_WR_SOF_EOF_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant RD_SOF_EOF_WIDTH : integer := GET_RD_SOF_EOF_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant WR_CTRL_REM_WIDTH : integer := GET_WR_CTRL_REM_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant RD_CTRL_REM_WIDTH : integer := GET_RD_CTRL_REM_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant C_WR_ADDR_WIDTH : integer := GET_C_WR_ADDR_WIDTH(RD_DWIDTH, 
                                               WR_DWIDTH, BRAM_MACRO_NUM);
constant C_RD_ADDR_WIDTH : integer := GET_C_RD_ADDR_WIDTH(RD_DWIDTH, 
                                               WR_DWIDTH, BRAM_MACRO_NUM);
constant ratio1 : integer := GET_RATIO(RD_DWIDTH, WR_DWIDTH, 
                                               WR_SOF_EOF_WIDTH);
constant WR_PAD_WIDTH : integer := GET_WR_PAD_WIDTH(RD_DWIDTH, WR_DWIDTH, 
                                               C_WR_ADDR_WIDTH, 
                                               WR_ADDR_FULL_WIDTH, WR_ADDR_WIDTH);
constant RD_PAD_WIDTH : integer := GET_RD_PAD_WIDTH(C_RD_ADDR_WIDTH, 
                                               RD_ADDR_FULL_WIDTH);
constant C_RD_TEMP_WIDTH : integer := GET_C_RD_TEMP_WIDTH(RD_DWIDTH, WR_DWIDTH);
constant C_WR_TEMP_WIDTH : integer := GET_C_WR_TEMP_WIDTH(RD_DWIDTH, WR_DWIDTH);
constant NUM_DIV : integer := GET_NUM_DIV(RD_DWIDTH, WR_DWIDTH);
constant WR_EN_FACTOR : integer := GET_WR_EN_FACTOR(NUM_DIV, BRAM_MACRO_NUM);
constant RDDWdivWRDW : integer := GET_RDDWdivWRDW(RD_DWIDTH, WR_DWIDTH);
constant LEN_BYTE_RATIO : integer := WR_DWIDTH/8; --number of bytes in the write word
constant LEN_IFACE_SIZE : integer := 16;        
constant LEN_COUNT_SIZE : integer := 14;

type rd_data_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(RD_DWIDTH-1 downto 0);
type rd_sof_eof_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(RD_SOF_EOF_WIDTH-1 downto 0);
type rd_ctrl_rem_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(RD_CTRL_REM_WIDTH-1 downto 0);
type rd_ctrl_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(C_RD_TEMP_WIDTH-1 downto 0);

signal rd_clk:              std_logic;
signal wr_clk:              std_logic; 
signal rd_en:               std_logic;  
signal wr_en:               std_logic;  
signal fifo_gsr:            std_logic;  
signal rd_data:             std_logic_vector(RD_DWIDTH-1 downto 0);  
signal wr_data:             std_logic_vector(WR_DWIDTH-1 downto 0);  


signal wr_rem:              std_logic_vector(WR_REM_WIDTH_P-1 downto 0);
signal wr_rem_plus_one:     std_logic_vector(WR_REM_WIDTH_P downto 0);
signal wr_sof_n:            std_logic;
signal wr_eof_n:            std_logic;
signal rd_rem:              std_logic_vector(RD_REM_WIDTH_P-1 downto 0);
signal rd_sof_n:            std_logic;   
signal rd_eof_n:            std_logic;
signal min_addr1:           integer := 0;
signal min_addr2:           integer := 0;
signal rem_sel1:            integer := 0;
signal rem_sel2:            integer := 0;
signal full:                std_logic;
signal empty:               std_logic;
signal rd_addr_full:        std_logic_vector(RD_PAD_WIDTH+RD_ADDR_FULL_WIDTH-1 downto 0);
signal rd_addr:             std_logic_vector(RD_PAD_WIDTH + RD_ADDR_WIDTH -1 downto 0);
signal rd_addr_minor:       std_logic_vector(ADDR_MINOR_WIDTH-1 downto 0);
signal read_addrgray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
signal read_nextgray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
signal read_lastgray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
signal wr_addr:             std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal wr_addr_full:        std_logic_vector(WR_PAD_WIDTH + WR_ADDR_FULL_WIDTH-1 downto 0);  
signal wr_addr_minor:       std_logic_vector(ADDR_MINOR_WIDTH-1 downto 0);
signal wr_addrgray:         std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal write_nextgray:      std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal fifostatus:          std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal rd_allow:            std_logic;
signal rd_allow_minor:      std_logic;
signal wr_allow:            std_logic;
signal wr_allow_minor:      std_logic;
signal full_allow:          std_logic;
signal empty_allow:         std_logic;
signal emptyg:              std_logic;
signal fullg:               std_logic;
signal ecomp:               std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal fcomp:               std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal emuxcyo:             std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal fmuxcyo:             std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
signal read_truegray:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
signal rag_writesync:       std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
signal ra_writesync:        std_logic_vector(RD_ADDR_WIDTH-1 downto 0);
signal wr_addrr:            std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);

signal data_valid:          std_logic;


-- Length Control FIFO --
signal wr_len:                  std_logic_vector(LEN_IFACE_SIZE-1 downto 0);
signal wr_len_p:                std_logic_vector(LEN_IFACE_SIZE-1 downto 0);
signal wr_len_r:                std_logic_vector(LEN_IFACE_SIZE-1 downto 0);
signal len_byte_cnt:            std_logic_vector(LEN_COUNT_SIZE+3 downto 0); 
signal len_byte_cnt_plus_rem:   std_logic_vector(LEN_COUNT_SIZE+3 downto 0);
signal rd_len:                  std_logic_vector(LEN_IFACE_SIZE-1 downto 0);
signal len_word_cnt:            std_logic_vector(LEN_COUNT_SIZE-1 downto 0);

signal len_byte_cnt_plus_rem_with_carry:  std_logic_vector(LEN_COUNT_SIZE+4 downto 0);
signal total_len_byte_cnt_with_carry:       std_logic_vector(LEN_COUNT_SIZE+4 downto 0);
signal len_word_cnt_with_carry:  std_logic_vector(LEN_COUNT_SIZE downto 0);
signal len_byte_cnt_with_carry: std_logic_vector(LEN_COUNT_SIZE+4 downto 0); 
signal carry1, carry2, carry3, carry4 : std_logic;
signal len_counter_overflow:    std_logic;

signal rd_len_rdy_2:            std_logic_vector(1 downto 0);
signal rd_len_rdy:              std_logic;
signal rd_len_rdy_p:            std_logic;
signal rd_len_rdy_p_p:          std_logic;
--  we only use wr_len_rdy(0).  
signal wr_len_rdy:              std_logic_vector(1 downto 0);
signal wr_len_rdy_r:            std_logic_vector(1 downto 0);
signal wr_len_rdy_p:            std_logic_vector(1 downto 0);
signal len_wr_allow:            std_logic;
signal len_wr_allow_r:          std_logic;
signal len_wr_allow_p:          std_logic;
signal len_rd_allow:            std_logic;
signal len_rd_allow_temp:       std_logic;
signal len_wr_addr:             std_logic_vector(9 downto 0);
signal len_rd_addr:             std_logic_vector(9 downto 0);
signal len_err:                 std_logic;


--  Inframe signals
signal inframe:                 std_logic;
signal inframe_i:               std_logic;

signal fifo_gsr_n:              std_logic;

signal gnd_bus:             std_logic_vector(128 downto 0);
signal gnd:                 std_logic;
signal pwr:                 std_logic;
    
    
component MUXCY_L
 port (
   DI:  in std_logic;
   CI:  in std_logic;
   S:   in std_logic;
   LO: out std_logic);
end component;

begin

    ---------------------------------------------------------------------------
    --  FIFO clk and enable signals                                          --
    ---------------------------------------------------------------------------
    rd_clk <= read_clock_in;
    wr_clk <= write_clock_in;
    fifo_gsr <= fifo_gsr_in;
    wr_en <= write_enable_in;                    
    rd_en <= read_enable_in;                                     

    wr_rem <= write_rem_in;
    wr_sof_n <= write_sof_in_n;
    wr_eof_n <= write_eof_in_n;  
    

    read_rem_out <= rd_rem;
    read_sof_out_n <= rd_sof_n;
    read_eof_out_n <= rd_eof_n;
    data_valid_out <= data_valid;


    wr_data <= revByteOrder(write_data_in);
    read_data_out <= revByteOrder(rd_data);    

    min_addr1 <= slv2int(rd_addr_minor);


    ---------------------------------------------------------------------------
    --  FIFO Status signals                                                  --
    ---------------------------------------------------------------------------
    empty_out <= empty;
    full_out <= full;
    fifostatus_out <= fifostatus(WR_ADDR_WIDTH-1 downto WR_ADDR_WIDTH-4);
        
    ---------------------------------------------------------------------------
    -- Misellainous                                                          --  
    ---------------------------------------------------------------------------
    gnd <= '0';
    gnd_bus <= (others => '0');
    pwr <= '1';         
    
    ---------------------------------------------------------------------------
    --------------------------INFRAME signal generation------------------------
    --  This signal is used as a flag to indicate whether the  incoming data --
    --  are part of a frame.  Since LL_FIFO is a packet FIFO so it will only --
    --  store packets, not random data without frame delimiter. If the data  --
    --  is not part of the frame, it will be dropped. The inframe_i signal   --
    --  will be assert the cycle after the sof_n asserts. If the frame is    --
    --  only a cycle long then inframe_i signal won't be asserted for that   --
    --  particular frame to prevent misleading information. However, the     --
    --  inframe signal will include wr_sof_n to give the accurate status of  --
    --  the frame, and which will be used for wr_allow.                      --
    ---------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
---------------------------ALLOW SIGNALS GENERATION----------------------------
--  Allow flags determine whether FifO control logic can operate.  If rd_en  --
--  is driven high, and the FifO is not empty, then Reads are allowed.       --
--  Similarly, if the wr_en signal is high, and the FifO is not full_out,    --
--  then Writes are allowed. We need to extend the enable signals of reading --
--  for one clock cycle, so that we won't miss the last data.                --
--  The data_valid Signal is used to indicate whether the data coming up     -- 
--  with valid.  It's used to accomodate different data width problem and    --
--  also used for src_ready signal.                                          --
-------------------------------------------------------------------------------

GEN1: if RD_DWIDTH < WR_DWIDTH generate

    
    ---------------------------------------------------------------------------
    -- Address and enable for RAM assignment (GEN1)                          --
    ---------------------------------------------------------------------------
    rd_addr_full <= rd_addr & rd_addr_minor;   
    wr_addr_full <= wr_addr;
    
    rd_allow_minor <= (rd_en and not empty);
    rd_allow <= rd_allow_minor and (boolean_to_std_logic(allOnes(rd_addr_minor)));
    
    wr_allow <= (wr_en and not full) and inframe;
    full_allow <= (full or wr_en);
    empty_allow <= rd_allow or empty;
    
     
    ---------------------------------------------------------------------------
    -- Data Valid Signal generation (GEN1)                                   -- 
    ---------------------------------------------------------------------------
    data_valid_proc1: process(rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            data_valid <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
            if (rd_allow_minor = '1') then
                if (min_addr1 /= 0 and rd_eof_n = '0') then  
                    data_valid  <= '0' after glbtm;
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
end generate GEN1;

GEN2: if RD_DWIDTH > WR_DWIDTH generate

    ---------------------------------------------------------------------------
    -- Address and enable for RAM assignment (GEN2)                          --
    ---------------------------------------------------------------------------
    wr_addr_full <= wr_addr & wr_addr_minor;
    rd_addr_full <= rd_addr;
    wr_allow_minor <= (wr_en and not full) and inframe;
    wr_allow <= wr_allow_minor and (boolean_to_std_logic(allOnes(wr_addr_minor)) or not wr_eof_n);
    rd_allow <= (rd_en and not empty);
       
    empty_allow <= (empty or rd_en);
    full_allow <= wr_allow or full;


    ---------------------------------------------------------------------------
    -- Data Valid Signal generation (GEN2)                                   -- 
    ---------------------------------------------------------------------------
    data_valid_proc2: process(rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            data_valid <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
            if rd_en = '0' and data_valid = '1' then --should extend data_valid 
                                                     --when user halts read, 
                                                     --so data won't get lost.
                data_valid <= '1' after glbtm;
            else
                data_valid <= rd_allow after glbtm;
            end if;
        end if;
    end process data_valid_proc2;         
end generate GEN2;


GEN3: if RD_DWIDTH = WR_DWIDTH generate

    ---------------------------------------------------------------------------
    -- Address and enable for RAM assignment (GEN3)                          --
    ---------------------------------------------------------------------------
    wr_allow <= (wr_en and not full) and inframe;

    rd_allow <= (rd_en and not empty);
    
    
    empty_allow <= (empty or rd_en);  
    full_allow <= wr_en or full;   


    ---------------------------------------------------------------------------
    -- Data Valid Signal generation (GEN3)                                   -- 
    ---------------------------------------------------------------------------
    
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
end generate GEN3;


--------------------------------------------------------------------------
--   Data and Control FIFO (BRAM Macros)
--------------------------------------------------------------------------

  BRAM_macro_inst: BRAM_macro
     generic map (
          BRAM_MACRO_NUM => BRAM_MACRO_NUM,
          WR_DWIDTH      => WR_DWIDTH, 
          RD_DWIDTH      => RD_DWIDTH,
          WR_REM_WIDTH   => WR_REM_WIDTH,
          RD_REM_WIDTH   => RD_REM_WIDTH,
          RD_PAD_WIDTH   => RD_PAD_WIDTH,
          RD_ADDR_FULL_WIDTH => RD_ADDR_FULL_WIDTH,
          RD_ADDR_WIDTH  => RD_ADDR_WIDTH,
          ADDR_MINOR_WIDTH => ADDR_MINOR_WIDTH,
          
          WR_PAD_WIDTH   => WR_PAD_WIDTH,
          WR_ADDR_FULL_WIDTH => WR_ADDR_FULL_WIDTH,
          WR_ADDR_WIDTH   => WR_ADDR_WIDTH,
          glbtm           => glbtm )
          
     port map (
           fifo_gsr        =>  fifo_gsr,      
                                
           wr_clk          =>  wr_clk,        
           rd_clk          =>  rd_clk,        
                                        
           rd_allow        =>  rd_allow,      
           rd_allow_minor  =>  rd_allow_minor,
           rd_addr_full    =>  rd_addr_full,  
           rd_addr_minor   =>  rd_addr_minor, 
           rd_addr         =>  rd_addr,       
           rd_data         =>  rd_data,       
           rd_rem          =>  rd_rem,        
           rd_sof_n        =>  rd_sof_n,      
           rd_eof_n        =>  rd_eof_n,      
                                        
           wr_allow        =>  wr_allow,      
           wr_allow_minor  =>  wr_allow_minor,
           wr_addr         =>  wr_addr,       
           wr_addr_minor   =>  wr_addr_minor, 
           wr_addr_full    =>  wr_addr_full,  
           wr_data         =>  wr_data,       
           wr_rem          =>  wr_rem,        
           wr_sof_n        =>  wr_sof_n,      
           wr_eof_n        =>  wr_eof_n);      
           


--------------------------------------------------------------------------
--   Length FIFO                                                        --
--------------------------------------------------------------------------
use_length_gen1: if USE_LENGTH = false generate 
    ---------------------------------------------------------------------------
    --  When the user does not want to use the Length FIFO, the output of    --
    --  the length count will always be zero and the len_rdy signal will     --
    --  always be asserted.                                                  --
    ---------------------------------------------------------------------------
    len_out <= (others => '0');
    len_rdy_out <= '0';  
    len_err_out <= '0';
end generate use_length_gen1;
fifo_gsr_n <= not fifo_gsr;

use_length_gen2: if USE_LENGTH = true generate   

    ---------------------------------------------------------------------------
    --  The BlockRAM that is used to store length information of the data    --
    --  Note that the read side of the BRAM is clocked but is always enabled.--
    --  This is because the length ready signal (rd_len_rdy) and the         --        
    --  corresponding length information must be seen as soon as the wr_eof_n--
    --  enables the wr_len_rdy signal.  
    --  To save space, the length FIFO only used 14 bits to store the number --
    --  of bytes.  This is sufficient enough even for the largest frame      --
    --  (Jumbo Frame) possible. 
    ---------------------------------------------------------------------------
    len_bram: RAMB16_S18_S18 
        port map (
        ADDRA => len_rd_addr, ADDRB => len_wr_addr,
        DIA => gnd_bus(17 downto 2), DIPA => gnd_bus(1 downto 0),
        DIB => wr_len_r, DIPB => wr_len_rdy_r,
        WEA => rd_len_rdy, WEB => len_wr_allow_r, CLKA => rd_clk, 
        CLKB => wr_clk, SSRA => fifo_gsr, SSRB => fifo_gsr, 
        ENA => pwr, ENB => fifo_gsr_n, 
        DOA => rd_len, DOPA => rd_len_rdy_2);     
    ---------------------------------------------------------------------------
    --  Read length section of the Length FIFO                               --
    ---------------------------------------------------------------------------
    len_out <= gnd & gnd & rd_len(13 downto 0);
    len_rdy_out <= rd_len_rdy;
    len_err_out <= len_err;
    
    len_err_proc: process (rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            len_err <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
            -- if (len_rd_addr = len_wr_addr) and (len_rd_flag = '1' or len_wr_flag = '1') then
            if (len_rd_addr -1 = len_wr_addr)  then
                len_err <= '1' after glbtm;
            end if;
        end if;
    end process len_err_proc;
    
          
    ---------------------------------------------------------------------------
    --  The rd_len_rdy signal is pipelined for two cycles to allow clearing  --
    --  of the rd_len_rdy signal in the FIFO after it is being read so in the--
    --  next wrap around, there will not be any residue value that sends the --
    --  wrong rd_len_rdy signal.                                             --
    ---------------------------------------------------------------------------
    rd_len_rdy <= not rd_len_rdy_p_p and (rd_len_rdy_p);
    
    len_rdy_pipeline_proc1: process(rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            rd_len_rdy_p <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
            if rd_len_rdy_2(0) = '1' then
                rd_len_rdy_p <= '1' after glbtm;
            else
                rd_len_rdy_p <= '0' after glbtm;
            end if;
        end if;
    end process len_rdy_pipeline_proc1;
    
    len_rdy_pipeline_proc2: process(rd_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            rd_len_rdy_p_p <= '0';
        elsif (rd_clk'EVENT and rd_clk = '1') then
            rd_len_rdy_p_p <= rd_len_rdy_p after glbtm;
        end if;
    end process len_rdy_pipeline_proc2;
   
    ---------------------------------------------------------------------------
    --  The enable signals for Length FIFO.  The len_rd_allow signal is      --
    --  independent from the enable signals for reading data (read_enable)   --
    --  because user may need to read the len_rdy signal before assertes     --
    --  the data read enables.  However, the write side of the length FIFO   --
    --  will need to depend on the write enable signal to ensure the validity--
    --  of the data being written.                                           --
    ---------------------------------------------------------------------------
    len_allow_gen1: if (WR_DWIDTH >= RD_DWIDTH) generate    
        len_rd_allow <= rd_len_rdy;
        len_wr_allow <=  (not wr_eof_n) and wr_allow;
    end generate len_allow_gen1;
  
    len_allow_gen2: if (WR_DWIDTH < RD_DWIDTH) generate
        len_rd_allow <= rd_len_rdy;
        len_wr_allow <= (not wr_eof_n) and wr_allow_minor;
    end generate len_allow_gen2;
 
 
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
    -- calculate data bytes in the remainder 
    wr_rem_plus_one <= '0' & wr_rem + '1';  
    
    -- add remainder into the length byte count
    len_byte_cnt_plus_rem_with_carry <= '0' & len_byte_cnt + wr_rem_plus_one;
    len_byte_cnt_plus_rem <= len_byte_cnt_plus_rem_with_carry(LEN_COUNT_SIZE+3 downto 0);
    carry2      <= len_byte_cnt_plus_rem_with_carry(LEN_COUNT_SIZE+4);
    
    -- calculate the total length byte count by adding one more data beat
    -- to count for SOF under certain condition
    total_len_byte_cnt_with_carry <= '0' & len_byte_cnt_plus_rem when wr_sof_n = '0' and len_wr_allow = '1' else 
                 '0' & len_byte_cnt_plus_rem + conv_std_logic_vector(LEN_BYTE_RATIO, 5) 
                 when wr_sof_n = '1' and len_wr_allow = '1' else
                 (others => '0');
                 
    wr_len <= total_len_byte_cnt_with_carry(LEN_IFACE_SIZE-1 downto 0);
    carry1 <= not boolean_to_std_logic(allZeroes(total_len_byte_cnt_with_carry(LEN_COUNT_SIZE+4 downto LEN_IFACE_SIZE)));
    
    wr_len_rdy <= gnd & (not wr_eof_n); 
    ---------------------------------------------------------------------------
    --  Pipeline the wr_len and wr_len_rdy, and detect counter overflow
    ---------------------------------------------------------------------------
    len_pipeline_proc: process(wr_clk, fifo_gsr)
    begin
       if (fifo_gsr = '1') then
           len_counter_overflow <= '0' after glbtm;
           len_wr_allow_r <= '0' after glbtm;
           wr_len_rdy_r   <= "00" after glbtm;
           wr_len_r       <= (others => '0') after glbtm;
       elsif (wr_clk'EVENT and wr_clk = '1') then

         len_wr_allow_r <= len_wr_allow_p after glbtm;
         wr_len_r       <= bit_duplicate(len_counter_overflow ,LEN_IFACE_SIZE) or wr_len_p after glbtm;
         wr_len_rdy_r <= wr_len_rdy_p after glbtm;
         
         if (wr_sof_n = '0') then 
             len_counter_overflow <= '0' after glbtm;
         elsif (carry1 = '1' or carry2 = '1' or carry3 = '1' or carry4 = '1') then
             len_counter_overflow <= '1' after glbtm;
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
            wr_len_rdy_p <= "00"; 
            len_wr_allow_p <= '0';
        elsif (wr_clk'EVENT and wr_clk = '1') then
            wr_len_p <= wr_len after glbtm;
            wr_len_rdy_p <= wr_len_rdy after glbtm;
            len_wr_allow_p <= len_wr_allow after glbtm;
        end if;
    end process wr_len_pipline_proc;
            
    ---------------------------------------------------------------------------
    
    len_word_cnt <= len_word_cnt_with_carry(LEN_COUNT_SIZE-1 downto 0);
    carry4      <= len_word_cnt_with_carry(LEN_COUNT_SIZE);
    
    len_byte_cnt <= len_byte_cnt_with_carry(LEN_COUNT_SIZE+3 downto 0); 
    carry3      <= len_byte_cnt_with_carry(LEN_COUNT_SIZE+4); 
    
    -- only count data beats between SOF and EOF
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
                            (slv2int(len_word_cnt)*LEN_BYTE_RATIO, LEN_COUNT_SIZE + 5 ) + 
                            conv_std_logic_vector(LEN_BYTE_RATIO, 5) 
                            after glbtm;  
                    end if;
                end if;
            elsif (WR_DWIDTH < RD_DWIDTH) then
                if (wr_allow_minor = '1') then
                    if (wr_sof_n = '0' or wr_eof_n = '0') then
                        len_word_cnt_with_carry <= (others => '0') after glbtm;
                        len_byte_cnt_with_carry <= (others => '0') after glbtm;
                    else
                        len_word_cnt_with_carry <= '0' & len_word_cnt + '1' after glbtm;
                        len_byte_cnt_with_carry <= conv_std_logic_vector
                            (slv2int(len_word_cnt)* LEN_BYTE_RATIO, LEN_COUNT_SIZE + 5 ) + 
                            conv_std_logic_vector(LEN_BYTE_RATIO, 5) 
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
            if (len_wr_allow_r = '1') then
                len_wr_addr <= len_wr_addr + '1' after glbtm;
            end if;
        end if;
    end process inc_len_wr_proc;
    ---------------------------------------------------------------------------  
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
-------------------------------------------------------------------------------
empty_proc: process (rd_clk, fifo_gsr)
begin
   if (fifo_gsr = '1') then
      empty <= '1';
   elsif (rd_clk'EVENT and rd_clk = '1') then
      if (empty_allow = '1') then
         empty <= emptyg after glbtm;
      end if;
   end if;
end process empty_proc;


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
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
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
      if (WR_DWIDTH > RD_DWIDTH) then
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
      if (WR_DWIDTH > RD_DWIDTH) then
         if (wr_allow_minor = '1') then
            wr_addr_minor <= wr_addr_minor + '1' after glbtm;
         end if;
      end if;

      if (WR_DWIDTH < RD_DWIDTH) then
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
----------------------------------------------------------
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

end BRAM_fifo_hdl;
